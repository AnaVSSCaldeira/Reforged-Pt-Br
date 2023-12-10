--[[
Copyright (C) 2018 Forged Forge

This file is part of Forged Forge.

The source code of this program is shared under the RECEX
SHARED SOURCE LICENSE (version 1.0).
The source code is shared for referrence and academic purposes
with the hope that people can read and learn from it. This is not
Free and Open Source software, and code is not redistributable
without permission of the author. Read the RECEX SHARED
SOURCE LICENSE for details
The source codes does not come with any warranty including
the implied warranty of merchandise.
You should have received a copy of the RECEX SHARED SOURCE
LICENSE in the form of a LICENSE file in the root of the source
directory. If not, please refer to
<https://raw.githubusercontent.com/Recex/Licenses/master/SharedSourceLicense/LICENSE.txt>
]]
-- Drops all loot that the mob should drop on death
local function DropLoot(mob, round, wave)
	local function DropItems(items)
		for _,item in pairs(items) do
			if type(item) == "string" then
				COMMON_FNS.DropItem(mob:GetPosition(), item)
			end
		end
	end
	local lavaarenaevent = TheWorld.components.lavaarenaevent
	if lavaarenaevent.total_rounds_completed < #lavaarenaevent.waveset_data then
		local self = TheWorld.components.forgemobtracker
		local live_mob_count = #self:GetLiveMobs(round, wave) -- For given wave
		local live_mob_type_count = live_mob_count > 0 and #self:GetLiveMobs(round, wave, nil, mob.prefab) or 0

		-- Check random item drops
		local random_item_drops = CheckTable(self.item_drops, round, wave, live_mob_count) or {}
		DropItems(random_item_drops)

		-- Check random item drops for mob type
		local random_item_drops = CheckTable(self.item_drops, round, wave, mob.prefab, live_mob_type_count) or {}
		DropItems(random_item_drops)

		-- Check final item drops for wave.
		if live_mob_count == 0 then
			local final_item_drops = CheckTable(self.item_drops, round, wave, "final_mob") or {}
			DropItems(final_item_drops)
		end
		-- Check final item drops for specific mob
		if live_mob_type_count == 0 then
			local final_mob_type_item_drops = CheckTable(self.item_drops, round, wave, "final_mob", mob.prefab) or {}
			DropItems(final_mob_type_item_drops)
		end


		local round_data = CheckTable(lavaarenaevent, "waveset_data", round) or 0
		-- Check final item drops for round
		-- Extra check for if the round somehow increments before the mobs are killed
		if #self:GetAllLiveMobs(round) == 0 and (round < self.current_round or self.current_wave >= #round_data.waves and not lavaarenaevent:IsWaveSpawning()) then
			local round_final_item_drops = CheckTable(self.item_drops, round, "round_end") or {}
			DropItems(round_final_item_drops)
		end
	end
end

--[[
TODO
set random item drops to drop on any random mob except the last mob? need proof that a random item can drop on last mob
--]]
local ForgeMobTracker = Class(function(self, inst)
	self.inst = inst
    self.current_round = 1
    self.current_wave = 1
    self.current_spawn_portal = 0
	self.item_drops = nil
	self.mob_drops = nil
	self.live_mobs = {}
	self._registermob = function(mob, round, wave, spawner)
		local round = round or self.current_round
		local wave = wave or TheWorld.components.lavaarenaevent.custom_wave and TheWorld.components.lavaarenaevent.custom_wave.name or self.current_wave
		local spawn_portal = spawner or self.current_spawn_portal
		mob.spawn_info = {round = round, wave = wave, spawn_portal = spawn_portal}
		EnsureTable(self.live_mobs, round, wave, spawn_portal)[mob] = true
		mob:ListenForEvent("death", function(inst, data)
			mob:DoTaskInTime(0, function() -- Delay one frame to ensure that mobs are dead.
				mob.killer = data.afflicter
				-- Check if mob is really dead
				if not mob.IsTrueDeath or not mob._is_truly_dead and mob:IsTrueDeath() then
					mob:PushEvent("truedeath", data)
				end
				TheWorld:PushEvent("mob_death", {mob = mob})
			end)
		end)
		mob:ListenForEvent("truedeath", function(inst, data)
			if self.live_mobs[round][wave][spawn_portal][mob] then
				self._unregistermob(mob, round, wave, spawn_portal)
				DropLoot(inst, round, wave)
				TheWorld:PushEvent("mob_truedeath", {mob = mob})
				if #self:GetAllLiveMobs() == 0 then
					TheWorld:PushEvent("ms_forge_allmobsdied")
				end
			end
		end)
		-- Start tracking mobs stats
		if TheWorld.components.stat_tracker then
			TheWorld.components.stat_tracker:StartTrackingMobStats(mob)
		end
		mob._registered = true
	end
	self._unregistermob = function(mob, round, wave, spawn_portal)
        self.live_mobs[round][wave][spawn_portal][mob] = nil
        if TheWorld.components.stat_tracker then
        	TheWorld.components.stat_tracker:UpdateMobKills(mob)
        end
        mob._registered = nil
	end
end)

function ForgeMobTracker:StartTracking(mob, round, wave, spawner)
	if not mob:HasTag("companion") and not mob:HasTag("ally") then -- TODO why is this check needed? --Leo: For ally spawns, allys shouldn't be tracked.
		self._registermob(mob, round, wave, spawner)
		mob:ListenForEvent("forceunregister", self._unregistermob)
	end
end

-- Returns the mobs alive for the current round of the given wave
-- Optional:
--    Can specify mobs that spawn at a specific spawn portal
--    Can specify mob prefab
function ForgeMobTracker:GetLiveMobs(round, wave, spawn_portal, mob_prefab)
    local mobs = {}
	local live_mobs = self.live_mobs[round][wave] or {}
    for mob_1,spawn_portals in pairs(spawn_portal and live_mobs[spawn_portal] or live_mobs or {}) do
        if spawn_portal and (not mob_prefab or mob_1.prefab == mob_prefab) then
			table.insert(mobs, mob_1)
		else
			for mob_2,_ in pairs(spawn_portals) do
				if  not mob_prefab or mob_2.prefab == mob_prefab then
					table.insert(mobs, mob_2)
				end
			end
		end
    end
    return mobs
end

-- Returns all mobs that are alive for the current round
-- Optional:
--    Can specify round
function ForgeMobTracker:GetAllLiveMobs(round)
    local mobs = {}
    for _,waves in pairs(self.live_mobs[round or self.current_round] or {}) do
        for __,spawners in pairs(waves) do
			for mob,is_alive in pairs(spawners) do
				if is_alive then
					table.insert(mobs, mob)
				end
			end
        end
    end
    return mobs
end

local function GetNonDuplicateRandomNumber(dupes, lower, upper, max_dupes)
	local rand = math.random(lower, upper)
	local max_dupes = max_dupes or 1
	local count = 0
	local valid_count = 0
    while valid_count < rand do
    	count = count + 1
    	if dupes[count] and #dupes[count] < max_dupes or not dupes[count] then
    		valid_count = valid_count + 1
        end
    end
	return count
end

-- TODO remove prints after item drops are complete, need data collection from forge to confirm the item drop sets, might need to edit this so leaving them in for now
-- Assigns each item a unique number that refers to how many mobs are still alive which is used to determine if the item should be dropped whenever a mob dies. Currently does not assign item drops to the last mob of a round.
function ForgeMobTracker:AssignRandomItemDrops(mob_prefab)
	--print("Assigning Random Items for round " .. tostring(self.current_round) .. " wave " .. tostring(self.current_wave))
	local current_item_drops = CheckTable(self.item_drops, self.current_round, self.current_wave, "random_mob", mob_prefab) or {}
	--print("- " .. tostring(#current_item_drops) .. " item drops available")
	local starting_mob_count = #(self:GetLiveMobs(self.current_round, self.current_wave, nil, mob_prefab))
	local current_mob_count = starting_mob_count
	local only_one_mob = starting_mob_count == 1
	local max_dupes = 1
	for i,item in pairs(current_item_drops) do
		if type(item) == "table" then
			self:AssignRandomItemDrops(i)
		else
			if only_one_mob then
				table.insert(EnsureTable(self.item_drops, self.current_round, self.current_wave, mob_prefab or 0, mob_prefab and 0 or nil), item)
			elseif current_mob_count > 1 then -- TODO don't drop random loot on final mob?
				local rand_mob = GetNonDuplicateRandomNumber(EnsureTable(self.item_drops, self.current_round, self.current_wave, mob_prefab), 1, current_mob_count - 1, max_dupes)
				table.insert(EnsureTable(self.item_drops, self.current_round, self.current_wave, mob_prefab or rand_mob, mob_prefab and rand_mob or nil), item)
				current_mob_count = current_mob_count - 1
				--print("- " .. tostring(item) .. " will drop when " .. tostring(rand_mob) .. " mobs are alive")
			-- All mobs have a drop, reset and increase dupe count
			else
				current_mob_count = starting_mob_count
				max_dupes = max_dupes + 1
				--print("WARNING - Unable to add " .. tostring(item) .. " as an item drop because all mobs have an item drop already. Limit of 1 random item drop per mob.")
			end
		end
	end
end

function ForgeMobTracker:ForEachMob(cb, params)
    for _,ent in pairs(self:GetAllLiveMobs()) do
        cb(ent, params)
    end
end

function ForgeMobTracker:SetRound(round)
    self.current_round = round
end

function ForgeMobTracker:SetWave(wave)
    self.current_wave = wave
end

function ForgeMobTracker:SetSpawnPortal(spawn_portal)
    self.current_spawn_portal = spawn_portal
end

function ForgeMobTracker:SetItemDrops(item_drops, opts)
	self.item_drops = item_drops
	if opts and opts.generate_item_drop_list_fn then
		opts.generate_item_drop_list_fn(self.item_drops, opts.character_tier_opts, opts.heal_opts, opts.random_item_spread_fn)
	end
	Debug:PrintTable(self.item_drops, 5)
end

return ForgeMobTracker
