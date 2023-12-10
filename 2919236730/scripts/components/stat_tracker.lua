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
--------------------------------------------------------------------------
-- Common Stat Tracking Event Functions
--------------------------------------------------------------------------
local function GetPlayer(inst)
	if inst == nil then return false end
	local is_player = inst.userid ~= nil
	local is_players_pet = inst.components.follower and inst.components.follower.leader and inst.components.follower.leader.userid ~= nil
	local stat_tracker = TheWorld.components.stat_tracker
	local is_owned_by_player = inst.owner and inst.owner.userid ~= nil
	local is_casted_by_player = inst.caster and inst.caster.userid ~= nil
	local is_forced_follower = inst.forced_leader and inst.forced_leader.userid ~= nil
	local is_equip = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner and inst.components.inventoryitem.owner.userid ~= nil
	return is_player and inst or is_players_pet and inst.components.follower.leader or is_owned_by_player and inst.owner or is_casted_by_player and inst.caster or is_forced_follower and inst.forced_leader or is_equip and inst.components.inventoryitem.owner or nil
end
--------------------------------------------------------------------------
-- Player Stat Tracking Event Functions
--------------------------------------------------------------------------
local function PlayerAttacked(inst, data)
	local stat_tracker = TheWorld.components.stat_tracker
	if stat_tracker then
		stat_tracker:AdjustStat("player_damagetaken", inst, data.damageresolved) -- TODO move to healthdelta?
		stat_tracker:AdjustStat("total_damagetaken", inst, data.damageresolved)
		if inst.sg:HasStateTag("parrying") and data.redirected then
			stat_tracker:AdjustStat("parry", inst, data.true_damage)
		end
		if data.attacker and data.attacker.userid then
			stat_tracker:AdjustStat("total_friendly_fire_damage_taken", inst, data.damageresolved)
			stat_tracker:AdjustStat("total_friendly_fire_damage_dealt", data.attacker, data.damageresolved)
		end
	end
end

local function PlayerDeath(inst, data)
	local stat_tracker = TheWorld.components.stat_tracker
	if stat_tracker and data and data.cause ~= "file_load" then
		stat_tracker:AdjustStat("deaths", inst, 1)
	end
end

local function PlayerAltAttack(inst, data)
	local stat_tracker = TheWorld.components.stat_tracker
	if stat_tracker and data.weapon and (data.weapon.components.aoespell == nil or data.weapon.components.aoespell and #data.weapon.components.aoespell.spell_types > 0) then
		stat_tracker:AdjustStat("altattacks", inst, 1)
	end
end

local function PlayerSpellComplete(inst, data)
	local stat_tracker = TheWorld.components.stat_tracker
	if stat_tracker then
		if data.is_spell then
			stat_tracker:AdjustStat("spellscast", inst, 1)
		else
			stat_tracker:AdjustStat("altattacks", inst, 1)
		end
	end
end

local function PlayerHealthDelta(inst, data)
	local stat_tracker = TheWorld.components.stat_tracker
	if stat_tracker and data.oldpercent > 0  and data.amount > 0 then -- player was not rez'd
		stat_tracker:AdjustStat("healingreceived", inst, data.amount)
		if data.afflicter then
			stat_tracker:AdjustStat("healingdone", data.afflicter, data.amount)
		end
	end
end

local function PlayerOnHitOther(inst, data)
	local stat_tracker = TheWorld.components.stat_tracker
	if stat_tracker then
		-- Update Dart Stat
		if data.projectile and data.projectile:HasTag("dart") then -- TODO add tag dart to weapons so custom dart weapons track? maybe track if ammo then track ammo type?
			stat_tracker:AdjustStat("blowdarts", inst, 1)
		-- Update Attack Stat
		elseif not data.is_alt then
			stat_tracker:AdjustStat("attacks", inst, 1)
		end
	end
end

local function PlayerRespawnFromCorpse(inst, data)
	local stat_tracker = TheWorld.components.stat_tracker
	local player = GetPlayer(data.source)
	if stat_tracker and player then
		stat_tracker:AdjustStat("corpsesrevived", player, 1)
	end
end

-- TODO this may or may not be accurate
-- ex. what if they never stop moving, not an issue right?
local function PlayerLocomote(inst, data) -- TODO there is a step event?
	if inst.sg:HasStateTag("busy") then return end
    local stat_tracker = TheWorld.components.stat_tracker
    local is_moving = inst.sg:HasStateTag("moving")
    local should_move = inst.components.locomotor:WantsToMoveForward()
	if stat_tracker and is_moving and not should_move then
		stat_tracker:AdjustStat("stepcounter", inst, inst.sg.mem.footsteps)
	end
end
--------------------------------------------------------------------------
-- Pet Stat Tracking Event Functions
--------------------------------------------------------------------------
local function AdjustPetStat(pet, stat, amount)
	local stat_tracker = TheWorld.components.stat_tracker
	if stat_tracker then
		local userid = stat_tracker.pet_owner_overrides[pet]
		local player = GetPlayer(pet)
		if userid == nil and player and player:HasTag("player") then
			userid = player.userid
		end
		if userid ~= nil then
			stat_tracker:AdjustStat(stat, player, amount, userid)
		end
	end
end

-- combat
--[[
pet:ListenForEvent("onhitother", function(inst, data)
	local stat_tracker = TheWorld.components.stat_tracker
	if stat_tracker then
		AdjustPetStat("pet_damagedealt", data.damageresolved)
		AdjustPetStat("total_damagedealt", data.damageresolved)
	end
end)--]]

local function PetAttacked(inst, data)
	local stat_tracker = TheWorld.components.stat_tracker
	if stat_tracker then
		AdjustPetStat(inst, "pet_damagetaken", data.damageresolved)
		AdjustPetStat(inst, "total_damagetaken", data.damageresolved)
		if data.attacker and data.attacker.userid then
			stat_tracker:AdjustStat("total_friendly_fire_damage_dealt", data.attacker, data.damageresolved)
		end
	end
end

local function PetDeath(inst, data)
	local stat_tracker = TheWorld.components.stat_tracker
	if stat_tracker then
		AdjustPetStat(inst, "petdeaths", 1)
	end
end

local function PetTrueDeath(inst, data) -- TODO only mobs push this event currently, need to make it so all ents do?
	local stat_tracker = TheWorld.components.stat_tracker
	if stat_tracker then
		stat_tracker:StopTrackingPetStats(inst)
	end
end
--------------------------------------------------------------------------
-- Mob Stat Tracking Event Functions
--------------------------------------------------------------------------
local function MobHealthDelta(inst, data)
	local stat_tracker = TheWorld.components.stat_tracker
	if stat_tracker and data.oldpercent > 0 and data.afflicter ~= nil then
		local is_pet = data.afflicter.components.follower ~= nil or data.afflicter.owner ~= nil
		local player = GetPlayer(data.afflicter)
		if player ~= nil then
			-- Pet Damage
			if is_pet then
				stat_tracker:AdjustStat("pet_damagedealt", player, math.abs(data.amount))
			-- Player Damage
			else
				stat_tracker:AdjustStat("player_damagedealt", player, math.abs(data.amount))
			end
			stat_tracker:AdjustStat("total_damagedealt", player, math.abs(data.amount))
		end
	end
end
--------------------------------------------------------------------------
-- Structure Stat Tracking Event Functions
--------------------------------------------------------------------------
local battlestandards = {battlestandard_damager = true, battlestandard_shield = true, battlestandard_heal = true} -- TODO edit battlestandards to use common structure fn, add stat tracking to it
local function StructureDeath(inst, data)
	local stat_tracker = TheWorld.components.stat_tracker
	local player = GetPlayer(data.afflicter)
	if stat_tracker and player then
		if battlestandards[inst.prefab] then
			stat_tracker:AdjustStat("standards", player, 1)
		end
	end
end
--------------------------------------------------------------------------
-- Stat Tracker
--------------------------------------------------------------------------
local StatTracker = Class(function(self, inst)
	self.inst = inst
	self:InitialSetup()

	inst:ListenForEvent("ms_playerspawn", function(inst, player)
		if self.started then
			inst:DoTaskInTime(0, function()
				if REFORGED_SETTINGS.other.spectators_only and not self.stats[player.userid] and player.prefab ~= "spectator" and player.userid ~= nil and player.userid ~= "" and string.sub(tostring(player.userid),1,2) ~= "AI" then
					Debug:Print("Player (" .. tostring(player.userid) .. ") attempted to join midmatch as a player and not a spectator.", "warning")
					TheNet:DeleteUserSession(player.userid)
					TheNet:BanForTime(player.userid, 60)
				elseif self.stats[player.userid] or player.prefab and player.prefab ~= "spectator" then
					-- Start Tracking AI
					if player.userid == nil or player.userid == "" then
						Debug:Print("SPAWNED " .. tostring(player.prefab) .. " (AI)", "log")
						self:AddNonUserPlayer(player)
					else
						Debug:Print("SPAWNED " .. tostring(player.prefab) .. " (" .. tostring(player.userid) .. ")", "log")
						-- Update join time for new valid player
						if not self.join_times[player.userid] then
							self.join_times[player.userid] = GetTime()
						end
						-- Setup new player
						if not self.stats[player.userid] then
							self:InitializePlayer(player)
						end
					end
					self:StartTrackingPlayerStats(player)
				end
			end)
		end
	end)
	inst:ListenForEvent("ms_forge_allplayersspawned", function(inst)
		if not self.started then
			self:PlayerSetup()
			self.started = true
		end
	end)
	-- TODO need to add field order? then have the values saved at the corresponding indexes so you can return the stats in the correct format for match results

	inst:ListenForEvent("ms_requestedlobbycharacter", function(inst, data)
		self.random_characters[data.userid] = data.prefab_name == "random"
	end)
end)

-- Initialize
function StatTracker:InitialSetup()
	self.debug_mode = false
	self.debug_type = "StatTracker"
	self.stat_list = {} -- in order
	self.stat_order = {} -- quick lookup for stat index
	self.stats = {}
	self.debug_string_list = {} -- is there a way to update this string when adjusting stats and then have GetDebugString just return this? would this work? or same issue?
	self.debug_key_to_index = {}
	self.stat_count = 0
	self.debug_string = ""
	self.active_player_count = 0
	self.nonuser_count = 0
	self.started = false
	self.mob_kills = {}
	self.random_characters = {}
	self.friend_count = {}
	self.join_times = {}
	self.pet_owner_overrides = {}
	self.event_functions = {
		player = {
			attacked            = PlayerAttacked,
			death               = PlayerDeath,
			alt_attack_complete = PlayerAltAttack,
			spell_complete      = PlayerSpellComplete,
			healthdelta         = PlayerHealthDelta,
			onhitother          = PlayerOnHitOther,
			respawnfromcorpse   = PlayerRespawnFromCorpse,
			locomote            = PlayerLocomote,
		},
		pet = {
			attacked  = PetAttacked,
			death     = PetDeath,
			truedeath = PetTrueDeath,
		},
		mob = {
			healthdelta = MobHealthDelta,
		},
		structure = {
			death = StructureDeath,
		},
	}

	self:InitializeForgeStats()
	--self:PlayerSetup()
end

-- Setup each player to start tracking stats
function StatTracker:PlayerSetup()
	self:GetAllPlayersData()
	for i, player in pairs(AllPlayers) do
		if player.prefab ~= "spectator" then
			if player.userid == nil or player.userid == "" then
				self.nonuser_count = self.nonuser_count + 1
				player.userid = "AI-" .. tostring(self.nonuser_count)
			end
			self.join_times[player.userid] = self.inst.components.lavaarenaevent.start_time
			self:StartTrackingPlayerStats(player)
		end
	end
end

-- Get all players user info on game start
function StatTracker:GetAllPlayersData()
	for _,player in pairs(GetPlayersClientTable()) do
		self:InitializePlayer(player)
	end
end

function StatTracker:InitializePlayer(player)
	if player.prefab ~= "spectator" then
		local base, clothing, portrait = GetSkinsDataFromClientTableData(player)
		self.stats[player.userid] = {
			stat_values = {},
			user_data = {
				user = {
					name = player.name,
					prefab = player.prefab,
					userid = player.userid,
					netid = player.netid,
					base = base,
					body = clothing.body,
					hands = clothing.hands,
					legs = clothing.legs,
					feet = clothing.feet,
					colour = player.colour,
					performance = player.performance,
					portrait = portrait,
				},
				beststat = {"none", nil},
				participation = true,
			},
		}
		self.active_player_count = self.active_player_count + 1
	end
end

function StatTracker:GetActivePlayerCount()
	return self.active_player_count
end

function StatTracker:GetNonUserCount()
	return self.nonuser_count
end

function StatTracker:GetTotalActivePlayerCount()
	return self.active_player_count + self.nonuser_count
end

-- Resets everything and reinitializes
function StatTracker:Reset()
	self:InitialSetup()
end

function StatTracker:HasStat(stat)
	return self.stat_order[stat] ~= nil
end

-- Adds the given stat to the tracker
function StatTracker:AddStat(stat)
	if not self:HasStat(stat) then
		self.stat_count = self.stat_count + 1
		self.stat_order[stat] = self.stat_count
		table.insert(self.stat_list, stat)
	end
end

-- Adjust given stat by given number, if given stat is not already tracked then it is created and set to given value.
function StatTracker:AdjustStat(stat, player, inc_value, userid_override)
	if self.inst.components.lavaarenaevent.victory ~= nil then return end
	local userid_override = userid_override or self.pet_owner_overrides[player]
	local player = GetPlayer(player)
	local userid = userid_override or player and player.userid
	if userid == nil or userid == false then
		Debug:Print("tried to update " .. tostring(stat) .. " by " .. tostring(inc_value) .. " for " .. tostring(player) .. " but userid is nil.", "error", self.debug_type)
		return
	elseif userid == "" and player ~= nil then
		print("AI found, adding to player list...", "note", self.debug_type)
		self:AddNonUserPlayer(player)
		userid = player.userid -- update userid for ai
	elseif self.stats[userid] == nil then
		print("tried to update stats for User " .. tostring(userid) .. ", but user did not initiate correctly.", "error", self.debug_type)
		return
	end
	if self.stats[userid].stat_values == nil then
		self.stats[userid].stat_values = {}
	end
	if self.stat_order[stat] == nil then
		print("tried to adjust " .. tostring(stat) .. " a nil stat", "error", self.debug_type)
	else
		--print("[StatTracker] Adjusting '" .. tostring(stat) .. "' by " .. tostring(inc_value) .. " for " .. tostring(player) .. " (" .. tostring(userid) ..")")
		self.stats[userid].stat_values[self.stat_order[stat]] = (self.stats[userid].stat_values[self.stat_order[stat]] or 0) + (inc_value or 0)
	end
end

--
function StatTracker:UpdateMobKills(mob)
	self.mob_kills[mob.prefab] = (self.mob_kills[mob.prefab] or 0) + 1
	if mob.killer then -- TODO check this
		self:AdjustStat("kills", mob.killer, 1)
	end
end

--
function StatTracker:UpdateFriendCount(userid, val)
	self.friend_count[userid] = val
end

--[[
Returns the value of the given stat.
If stat does not exist for the given user or in general then returns 0.
If userid is nil then it will return the total stat count among all players.
--]]
function StatTracker:GetStatTotal(stat, userid)
	if userid == nil and self.stat_order[stat] ~= nil then
		local stat_total = 0
		for id, _ in pairs(self.stats) do
			stat_total = stat_total + (self.stats[id].stat_values[self.stat_order[stat]] or 0)
		end
		return stat_total
	else
		return self.stat_order[stat] and (userid and (self.stats[userid].stat_values[self.stat_order[stat]] or 0)) or 0
	end
end

-- Adds all the default forge stats and custom forge stats to the stat tracker, sets them to 0, and sets up their triggers
--[[
Notes:
numcc, cctime, ccbroken
	sleep adjusted in healingcircle
		ccbroken down below
	petrification adjusted in fossilizable
turtillusflips, ccbroken
	SGsnortoise
]]
function StatTracker:InitializeForgeStats()
	for i,stat in pairs(TUNING.FORGE.DEFAULT_FORGE_STATS) do
		self.stat_count = self.stat_count + 1
		self.stat_order[stat] = self.stat_count
		table.insert(self.stat_list, stat)
	end
	for i,stat in pairs(TUNING.FORGE.CUSTOM_STATS) do
		self.stat_count = self.stat_count + 1
		self.stat_order[stat] = self.stat_count
		table.insert(self.stat_list, stat)
	end
end

-- TODO change player name here?
-- Adds stat tracker to players who are not controlled by users aka AI.
function StatTracker:AddNonUserPlayer(player)
	if player.userid == nil or player.userid == "" then
		Debug:Print("Adding nonuser " .. tostring(player.prefab), "note", self.debug_type)
		self.nonuser_count = self.nonuser_count + 1
		player.userid = "AI-" .. tostring(self.nonuser_count)
		local clothing = player.components.skinner.clothing
		self.stats[player.userid] = {
			stat_values = {},
			user_data = {
				user = {
					name = "AI", -- TODO randomize names?
					prefab = player.prefab,
					userid = player.userid,
					netid = 100,
					base = player.components.skinner.skin_name, -- could force it/randomize it?
					body = clothing.body,
					hands = clothing.hands,
					legs = clothing.legs,
					feet = clothing.feet,
					colour = {0.5, 0.5, 0.5, 1}, -- TODO What colour? currently gray
					performance = 0,
					portrait = "playerportrait_bg_flames",
				},
				beststat = {"none", nil},
				participation = true,
			},
		}
		-- This is needed because player.prefab is not set on spawn
		-- TODO base is not updating until it changes aka mighty/death
		player:DoTaskInTime(1, function(inst)
			self.stats[player.userid].user_data.user.prefab = inst.prefab
			self.stats[player.userid].user_data.user.base = inst.prefab .. "_none" -- TODO force it?
		end)
		self.join_times[player.userid] = GetTime()
		--self:StartTrackingPlayerStats(player)
	end
end

function StatTracker:StartTrackingStats(ent, type)
	local event_functions = self.event_functions[type]
	if ent and ent:IsValid() and event_functions ~= nil then
		for event,fn in pairs(event_functions) do
			ent:ListenForEvent(event, fn)
		end
		return true
	end
	return false
end

function StatTracker:StopTrackingStats(ent, type)
	local event_functions = self.event_functions[type]
	if ent and ent:IsValid() and event_functions ~= nil then
		for event,fn in pairs(event_functions) do
			ent:RemoveEventCallback(event, fn)
		end
	end
end

function StatTracker:StartTrackingPlayerStats(player)
	self:StartTrackingStats(player, "player")
	--print("Adding stat tracker to " .. tostring(player).. " id: " .. tostring(player.userid))
	-- combat
	--[[
	player:ListenForEvent("killed", function(inst, data)
		if data.victim.prefab == "battlestandard_damager" or data.victim.prefab == "battlestandard_shield" or data.victim.prefab == "battlestandard_heal" then
			self:AdjustStat("standards", player.userid, 1)
		else
			self:AdjustStat("kills", player, 1)
			--self:AdjustStat(tostring(data.victim.prefab) .. "_kills", 1) -- TODO track specific mob kills
		end
	end)--]]

	--self.player:ListenForEvent("", function(inst,data) end)
end

function StatTracker:StopTrackingPlayerStats(player)
	self:StopTrackingStats(player, "player")
end

--[[ TODO
	Possible bug on reconnect with webber, need further testing
	golem work?
		do we give golem the follower component?
]]
-- Initialize all stats and start tracking stats for the given pet and link those stats to the pets leader. Note if the pets leader changes then the link will automatically change to the new leader and track stats unless new leader is not a player.
function StatTracker:StartTrackingPetStats(pet, userid_override)
	local success = self:StartTrackingStats(pet, "pet")
	self.pet_owner_overrides[pet] = success and userid_override or nil
end

function StatTracker:StopTrackingPetStats(pet)
	self:StopTrackingStats(pet, "pet")
	self.pet_owner_overrides[pet] = nil
end

-- TODO mob regen stats? damage absorbed stats (damage when in bunker)?
-- Track stats for the given mob
function StatTracker:StartTrackingMobStats(mob)
	self:StartTrackingStats(mob, "mob")
end

function StatTracker:StopTrackingMobStats(mob)
	self:StopTrackingStats(mob, "mob")
end

function StatTracker:StartTrackingStructureStats(structure)
	self:StartTrackingStats(structure, "structure")
end

function StatTracker:StopTrackingStructureStats(structure)
	self:StopTrackingStats(structure, "structure")
end

-- Returns all the stat values for the given user
function StatTracker:GetPlayerStats(userid)
	return self.stats[userid].stat_values
end

-- Returns the saved users data
function StatTracker:GetUserData(userid)
	return self.stats[userid].user_data
end

-- Returns the field order of the stats -- TODO might need to change this when adding custom stats since I use a default table
function StatTracker:GetStatFieldOrder()
	--local default_stats = deepcopy(TUNING.FORGE.DEFAULT_FORGE_STATS)
	--local reforged_stats = deepcopy(TUNING.FORGE.CUSTOM_STATS)
	--TableConcat(default_stats, reforged_stats)
	return self.stat_list
end

local function EnsureUserData(self, userid)
	if self.stats[userid].user_data then return end
	for i,player in pairs(GetPlayersClientTable()) do
		if player.userid == userid then
			local base, clothing, portrait = GetSkinsDataFromClientTableData(player)
			self.stats[player.userid] = {
				stat_values = {},
				user_data = {
					user = {
						name = player.name,
						prefab = player.prefab,
						userid = player.userid,
						netid = player.netid,
						base = base,
						body = clothing.body,
						hands = clothing.hands,
						legs = clothing.legs,
						feet = clothing.feet,
						colour = player.colour,
						performance = player.performance,
						portrait = portrait,
					},
					beststat = {"none", nil},
					participation = true,
				},
			}
			return
		end
	end
end

-- Returns the best stat for each user
function StatTracker:FindBestStats()
	local function GetStatTier(stat, value)
		return TUNING.FORGE.DEFAULT_FORGE_TITLES[stat] and TUNING.FORGE.DEFAULT_FORGE_TITLES[stat].tier2 and (TUNING.FORGE.DEFAULT_FORGE_TITLES[stat].tier2 <= (value or 0)) and 2 or 1
	end

	-- Rank all players for each stat based on their value
	local stat_ranks = {}
	--print("Ranking Stats...")
	for stat,title_info in pairs(TUNING.FORGE.DEFAULT_FORGE_TITLES) do
		--print("- " .. tostring(stat))
		local current_stat_ranks = {}
		for userid,user_info in pairs(self.stats) do
			--print("- - userid: " .. tostring(userid) .. ", value: " .. tostring((user_info.stat_values[self.stat_order[stat]] or 0)))
			table.insert(current_stat_ranks, {userid = userid, value = (user_info.stat_values[self.stat_order[stat]] or 0)})
		end
		table.sort(current_stat_ranks, function(a, b) return a.value > b.value end)
		stat_ranks[stat] = current_stat_ranks
	end

	-- userid: stat, tier, place, value
	-- Find the best stat for each player
	local best_stat = {}
	for stat, values in pairs(stat_ranks) do
		--print("[BestStats] stat: " .. tostring(stat))
		for place, val in ipairs(values) do
			--print(tostring(place) .. ": " .. tostring(val.userid) .. " - " .. tostring(val.value) .. " (" .. tostring(GetStatTier(stat, val.value)) .. ")")
			if (val.value or 0) > 0 and (best_stat[val.userid] == nil or (best_stat[val.userid].place > place or ((best_stat[val.userid].place == place) and ((best_stat[val.userid].tier < GetStatTier(stat, val.value)) or (TUNING.FORGE.DEFAULT_FORGE_TITLES[best_stat[val.userid].stat].priority > TUNING.FORGE.DEFAULT_FORGE_TITLES[stat].priority))))) then
				best_stat[val.userid] = {stat = stat, tier = GetStatTier(stat, val.value), place = place, value = (val.value or 0)}
				EnsureUserData(self, val.userid)
				self.stats[val.userid].user_data.participation = place > 1
				local stat_str = stat .. (not self.stats[val.userid].user_data.participation and (GetStatTier(stat, val.value) == 2) and "2" or "")
				self.stats[val.userid].user_data.beststat = {stat_str, math.floor((val.value) or 0)}
				--print(tostring(stat) .. " is the new best stat for " .. tostring(val.userid))
			end
		end
	end
	-- best_stat should have the stat that should be displayed
	return best_stat
end

function StatTracker:GetDebugString()
	local STAT_LIMIT_PER_ROW = 3
	local stat_str = "Stats: "
	local count = 1
	--[[
	for stat, value in pairs(self.stats) do
		stat_str = stat_str .. string.format("%s: %d, ", tostring(stat), math.floor(value + 0.5))
		--stat_str = stat_str .. tostring(stat) .. ": " .. tostring(value) .. ", "
		count = count + 1
		if count > STAT_LIMIT_PER_ROW then
			count = 1
			stat_str = stat_str .. "\n"
		end
	end
	--stat_str = string.sub(stat_str,1,-3)
	--]]
    --return stat_str--string.format("%s", stat_str)
	return self.debug_string
end

return StatTracker
