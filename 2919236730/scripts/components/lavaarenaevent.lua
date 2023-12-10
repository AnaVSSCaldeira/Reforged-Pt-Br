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
-- Centerpoint is retrieved from a lavaarena_center prefab, must be set in the arenas static_layout file
local function RegisterCenterpoint(inst, center)
	Debug:Print("REGISTER CENTERPOINT", inst, center, "log")
	inst.center = center
	inst:DoTaskInTime(0, function() -- Delay to ensure the center has the correct position
		local center_pos = inst.center:GetPosition()
		inst.net.center_pos = center_pos
		local center_str = SerializeTable(center_pos)
		inst.net.center_point_str:set(center_str)
	end)
end

local function RegisterForgeLord(inst, forge_lord)
	inst:DoTaskInTime(0, function()
		inst.forge_lord = forge_lord
	end)
end

local function OnPlayerSpawn(world, player)
	local self = world.components.lavaarenaevent
	if REFORGED_SETTINGS.other.reserve_slots and player.prefab ~= "spectator" and player.userid ~= nil and player.userid ~= "" then
		-- Reconnecting player, update current reserved slots remaining.
		if self:IsUserReserved(player.userid) then
			self.reserved_slots_remaining = math.max(self.reserved_slots_remaining - 1, 0)
		-- Only reserve slots if there are empty slots. Only admins can join when there are no free slots left, but they will not reserve their spot in that case.
		elseif TheNet:GetServerMaxPlayers() > lavaareanevent:GetTotalReservedSlots() then
			self.reserved_slots[player.userid] = player.userid
		end
	end
end

local function OnClientConnect(world, data)
	local self = world.components.lavaarenaevent
	self.connected_users[data.userid] = true
end

local function OnPlayerDisconnect(world, data)
	local self = world.components.lavaarenaevent
	if REFORGED_SETTINGS.other.reserve_slots and self:IsUserReserved(data.userid) then
		self.reserved_slots_remaining = self.reserved_slots_remaining + 1
	end
	self.connected_users[data.userid] = nil
end

-- TODO why do we do this? this should be a separate mod
local function RemoveNoClickFromNonMobs(self)
	local pt = self:GetArenaCenterPoint()
    local ents = TheSim:FindEntities(pt.x, 0, pt.z, 300, {"NOCLICK"}, {"LA_mob", "corpse", "specialnoclick"})
    for i, ent in ipairs(ents) do
		if ent.tempnoclick then
			ent:RemoveTag("NOCLICK")
			ent.tempnoclick = nil
		end
    end
end

-- Call onspawningfinished fns from the wavemanager if they exist
local function OnSpawningFinished(self, data)
	if self.wavemanager.onspawningfinished and not self.custom_wave then
		if self.wavemanager.onspawningfinished.all then
			self.wavemanager.onspawningfinished.all(self, TheWorld.components.forgemobtracker.live_mobs[self.current_round][self.current_wave]) -- TODO make function to get live_mobs[round][wave]???
		end
		if self.wavemanager.onspawningfinished[self.current_wave] then
			self.wavemanager.onspawningfinished[self.current_wave](self, TheWorld.components.forgemobtracker.live_mobs[self.current_round][self.current_wave])
		end
	elseif self.custom_wave and self.custom_wave.onspawningfinished then
		self.custom_wave.onspawningfinished(self, TheWorld.components.forgemobtracker.live_mobs[self.current_round][self.custom_wave.name], self.custom_wave.leader)
	end
end

local function RegisterItems(self)
	if not self.custom_wave then
		self.inst.components.forgemobtracker:AssignRandomItemDrops()
	end
end

local LavaarenaEvent = Class(function(self, inst)
	self.inst = inst
	self.enabled = true
	self.start_time = 0
	self.wave_start_time = 0 -- set when mobs are spawned
	self.queued_waves = {}
	self.wave_ready = true
	self.current_round = 0
	self.current_wave = 1
	self.current_round_data = nil
	self.health_triggers = {}
	self.timers = {}
	self.total_rounds_completed = 0
	self.player_attacks = {}
	self.endless = false
	self.endless_fn = nil
	self.command_executed = false
	self.connected_users = {}
	self.reserved_slots = {}
	self.reserved_slots_remaining = 0

    inst:ListenForEvent("ms_register_forgelord", RegisterForgeLord)
	inst:ListenForEvent("ms_register_lavaarenacenter", RegisterCenterpoint)
	inst:ListenForEvent("ms_forge_allplayersspawned", function() self:Start() end)
	inst:ListenForEvent("ms_playerspawn", OnPlayerSpawn)
	inst:ListenForEvent("ms_clientauthenticationcomplete", OnClientConnect)
	inst:ListenForEvent("ms_clientdisconnected", OnPlayerDisconnect)
	inst:ListenForEvent("spawningfinished", function(inst, data)
		OnSpawningFinished(self, data)
		RegisterItems(self)
		-- Wave has completed spawning, check if next wave is queued
		self.wave_ready = true
		self.custom_wave = nil
		self.wave_start_time = GetTime()
		self:UpdateWaveQueue()
	end)
	inst:ListenForEvent("ms_forge_allmobsdied", function()
		RemoveNoClickFromNonMobs(self) -- TODO should be separate mod
		self:EndRoundCheck()
	end)

	if self.inst.ismastersim then
		-- Remove ingame icon from server name
		local server_name = TheNet:GetServerName()
		local ingame_str = STRINGS.REFORGED.INGAME
		local ingame_str_length = string.len(ingame_str)
		if string.sub(server_name,1,ingame_str_length) == ingame_str then
			TheNet:SetDefaultServerName(string.sub(server_name, ingame_str_length + 1))
		end
	end
end)

function LavaarenaEvent:GetForgeLord()
	return self.inst.forge_lord
end

function LavaarenaEvent:GetConnectedUsersCount()
	local count = 0
	for i,j in pairs(self.connected_users) do
		count = count + 1
	end
	return count
end

function LavaarenaEvent:IsUserReserved(userid)
	return self.reserved_slots[userid] ~= nil
end

function LavaarenaEvent:GetReservedSlotsRemaining()
	return self.reserved_slots_remaining
end

function LavaarenaEvent:GetTotalReservedSlots()
	local count = 0
	for i,j in pairs(self.reserved_slots) do
		count = count + 1
	end
	return count
end

function LavaarenaEvent:GetCurrentRound()
	return self.current_round
end

function LavaarenaEvent:GetCurrentWave()
	return self.current_wave
end

function LavaarenaEvent:IsWaveSpawning()
	return not self.wave_ready
end

function LavaarenaEvent:GetArenaCenterPoint()
	return self.inst.center and self.inst.center:GetPosition() or Vector3()
end

-- Sets the wavemanager and adds any missing functions
function LavaarenaEvent:SetWaveManager(wavemanager)
	self.wavemanager = wavemanager or _G.UTIL.WAVESET.defaultwavemanager

	if wavemanager then
		-- Add default wavemanager functions if not found in given wavemanager
		for fn_name,fn in pairs(_G.UTIL.WAVESET.defaultwavemanager) do
			if not self.wavemanager[fn_name] then
				self.wavemanager[fn_name] = fn
			end
		end
	end
end

function LavaarenaEvent:Start()
	if not self.inst.net.components.lavaarenaeventstate.in_progress:value() then
		self.inst.net.components.lavaarenaeventstate.in_progress:set(true)
	    -- Loading waveset data here due to possible character influence (ie. wigfrid adds spiral spear to item drop list in default waveset)
	    self.waveset_data = require("wavesets/" .. REFORGED_SETTINGS.gameplay.waveset)
	    TheWorld.net:SetWavesetData(self.waveset_data)
	    self.inst.components.forgemobtracker:SetItemDrops(self.waveset_data.item_drops, self.waveset_data.item_drop_options)
		self.start_time = GetTime()
		self.endless = _G.REFORGED_SETTINGS.gameplay.mutators.endless
	    self:StartRound(1)
	    -- Allow Players to connect during match.
	    if REFORGED_SETTINGS.other.joinable_midmatch then
		    TheNet:SetAllowIncomingConnections(true)
		    TheNet:SetAllowNewPlayersToConnect(true)
		    if REFORGED_SETTINGS.other.reserve_slots then
		    	for _,player in pairs(GetPlayersClientTable()) do
		    		if player.userid ~= nil then
		    			self.connected_users[player.userid] = true
		    			if player.prefab and player.prefab ~= "spectator" then
		    				self.reserved_slots[player.userid] = true
		    			end
		    		end
		    	end
			end
		end
	    TheNet:SetDefaultServerName(STRINGS.REFORGED.INGAME .. TheNet:GetServerName())
	    -- Check if all players are dead and/or spectators, delay to ensure everything has spawned
	    self.inst:DoTaskInTime(0, function()
	    	if AreAllPlayersDead() then
	    		self:End()
	    	end
		end)
	end
end

-- Starts the given round.
-- Optional: giving a wave will force start that wave using the defaultwavemanager
function LavaarenaEvent:StartRound(round, wave)
	if self.wavemanager and self.wavemanager.onexit then
		self.wavemanager.onexit(self)
	end
    self.inst:StopUpdatingComponent(self)
	self.current_round_data = nil

	-- Apply any additional changes for next set of rounds (endless)
	if round == 1 and self.total_rounds_completed >= #self.waveset_data and self.endless_fn then
		self.endless_fn(math.floor(self.total_rounds_completed / #self.waveset_data))
	end

	-- Update current round data
    self.current_round = round
	self.inst.components.forgemobtracker:SetRound(self.current_round)
    self.current_round_data = self.waveset_data[round]
    if not self.current_round_data then
		Debug:Print("Unable to start round " .. tostring(self.current_round) .. ". No round data found.", "warning") -- TODO need a formal warning/error message that is used throughout the mod to make it easier for modders and users to find and understand possible issues
		return
	end
	if not self.current_round_data.roundend then
		self.current_round_data.roundend = _G.UTIL.WAVESET.defaultroundend
	end
	if not self.current_round_data.banner then
		self.current_round_data.banner = _G.UTIL.WAVESET.defaultbanner()
	end

	-- Force start occurs if wave was given and is greater than 1
	local forced_start = wave and wave > 1
    self:SetWaveManager(not forced_start and self.current_round_data.wavemanager)

	-- Start round
	if not forced_start then
		self.wavemanager.onenter(self)
		if type(self.wavemanager.onupdate) == "function" then
			self.inst:StartUpdatingComponent(self)
		end
	-- Force start the given wave
	else
		self:QueueWave(wave, true)
	end
end

-- Pushes the next wave in the queue
function LavaarenaEvent:UpdateWaveQueue()
	if self.wave_ready and #self.queued_waves > 0 then
		if type(self.queued_waves[1]) == "number" then
			self:PushWave(self.queued_waves[1])
		else
			self.custom_wave = self.queued_waves[1]
			self:PushWave(nil, self.queued_waves[1])
		end
		table.remove(self.queued_waves, 1)
	end
end

-- TODO somehow 4-3 queued twice here, timer and all mobs died both triggered. Added a check to see the the queued wave is not in the middle of spawning. Needs testing to confirm that this fixes it.
-- Adds the given wave to the queue list, starts the wave if ready and there are no other waves in the queue
-- Use this to start waves and not PushWave
-- Can also queue a custom wave with the following format:
-- custom_wave = {
--     name = "",
--     mob_spawns = {}, -- Same format as wavesets
--     dialogue   = {},
--     SpawnSetup = fn(lavaarenaevent_inst, data), -- Used to spawn mobs without using the mob spawners. IMPORTANT NOTE: return true if spawning is complete after this is finished. If there is a delay or anything for spawning your mobs then you need to return false and manually call self:SpawnFinished() when all mobs are spawned
--     data       = {}, -- used to pass information to the SpawnSetup fn.
-- }
-- leader: if a mob owns the spawn, will pass through to the onspawn function where the new spawns can be set as followers to this leader if intended. Only available for custom waves
function LavaarenaEvent:QueueWave(wave, force_queue, custom_wave, leader)
	if self.enabled or force_queue then
		local custom_wave = custom_wave and deepcopy(custom_wave)
		if custom_wave then
			custom_wave.leader = leader
		end
		-- Only queue wave if there are other waves queued or the previous wave has not finished spawning
		if (#self.queued_waves > 0 or not self.wave_ready) and not table.contains(self.queued_waves, wave) and wave ~= self.current_wave then
			table.insert(self.queued_waves, custom_wave or wave)
		-- No waves in queue and no waves are still spawning
		elseif self.wave_ready then
			self.custom_wave = custom_wave
			self:PushWave(wave, custom_wave)
		end
	end
end

-- Attempts to start the given wave
-- Do not use this to start a wave, use QueueWave instead
function LavaarenaEvent:PushWave(wave, wave_info)
    Debug:Print("Starting Round: " .. self.current_round .. " Wave: " .. tostring(wave_info and self.custom_wave and self.custom_wave.name or wave), "log")
    if not self.current_round_data then
		Debug:Print("Attempted to start wave " .. tostring(wave) .. " of round " .. tostring(self.current_round) .. " without round data.", "warning")
		return
	end
	local mob_spawns = wave_info and wave_info.mob_spawns or wave and self.current_round_data.waves[wave]
    if not mob_spawns then
		Debug:Print("Attempted to spawn mobs for wave " .. tostring(wave) .. " of round " .. tostring(self.current_round) .. ", but no mobs to spawn.", "warning")
		return
	end
	self.wave_ready = false
	-- Only update wave if the wave being pushed is part of the current waveset.
	if wave then
		self.current_wave = wave
		self.inst.components.forgemobtracker:SetWave(self.current_wave)
	elseif wave_info then
		-- TODO add custom wave to forgemobtracker?
		local wave_name = self.custom_wave.name
		local count = 1
		-- Find an unused wave name
		while CheckTable(self.inst.components.forgemobtracker.live_mobs, self.current_round, wave_name) do
			wave_name = self.custom_wave.name .. "_" .. tostring(count)
			count = count + 1
		end
		self.custom_wave.name = wave_name
	end

	local function GetLeastUsedSpawner(mob_spawn_info, spawner_options)
		local least_used_spawner = nil
		for _,spawner in pairs(spawner_options) do
			least_used_spawner = (least_used_spawner and mob_spawn_info[spawner].count.total < mob_spawn_info[least_used_spawner].count.total or not least_used_spawner) and spawner or least_used_spawner
		end
		return least_used_spawner
	end
	local function ApplyDuplicatorMutator(mob_spawns)
		local mob_duplicator = _G.REFORGED_SETTINGS.gameplay.mutators.mob_duplicator
		if mob_duplicator < 1 then
			local mob_count = {}
			local mob_spawns_count = {}
			local mob_spawn_list = {}
			-- Organize the spawns based on prefab
			for spawner,spawn in pairs(mob_spawns) do
				mob_spawns_count[spawner] = 0
				mob_spawn_list[spawner] = {mob_weight = 0, count = {total = 0}}
				for i,mob_info in pairs(spawn[1]) do
					local mob_data = EnsureTable(mob_count, mob_info.prefab)
					mob_data.count = (mob_data.count or 0) + 1
					-- Remember the spawner of the mob
					if EnsureTable(mob_data, "spawners") and not mob_data.spawners[spawner] then
						mob_data.spawners[spawner] = {}
						table.insert(EnsureTable(mob_data, "spawner_list"), spawner)
					end
					table.insert(mob_data.spawners[spawner], i)
				end
			end

			-- Sort mobs into their spawner
			for prefab,mob_data in pairs(mob_count) do
				local mob_spawner_count = {}
				for i=1,math.ceil(mob_data.count*mob_duplicator) do
					local spawner = GetLeastUsedSpawner(mob_spawn_list, mob_data.spawner_list)
					--mob_spawns_count[spawner] = mob_spawns_count[spawner] + 1 -- TODO needed?
					--mob_spawner_count[spawner] = (mob_spawner_count[spawner] or 0) + 1
					local spawn_info = mob_spawn_list[spawner]
					spawn_info.mob_weight = spawn_info.mob_weight + COMMON_FNS.GetMobWeight(nil, prefab)
					spawn_info.count[prefab] = (spawn_info.count[prefab] or 0) + 1
					spawn_info.count.total = spawn_info.count.total + 1
				end
			end

			-- Check if any spawners should combine their spawns with another spawner
			local MIN_MOB_WEIGHT = 3
			for i,spawn_info in pairs(mob_spawn_list) do
				if spawn_info.mob_weight < MIN_MOB_WEIGHT then
					-- Combine spawns with valid spawners
					for check_spawner,check_spawn_info in pairs(mob_spawn_list) do
						if (check_spawn_info.mob_weight - MIN_MOB_WEIGHT) >= spawn_info.mob_weight then
							for prefab,count in pairs(spawn_info.count) do
								if prefab ~= "total" and check_spawn_info.count[prefab] then
									check_spawn_info.count[prefab] = check_spawn_info.count[prefab] + count
									check_spawn_info.count.total = spawn_info.count.total + count
									spawn_info.count.count = spawn_info.count[prefab] - count
									spawn_info.count.total = spawn_info.count.total - count
									local mob_weight = COMMON_FNS.GetMobWeight(nil, prefab) * count
									check_spawn_info.mob_weight = check_spawn_info.mob_weight + mob_weight
									spawn_info.mob_weight = spawn_info.mob_weight - mob_weight
								end
							end
						end
					end
				end
			end

			-- Generate new spawn table
			local half_mob_spawns = {}
			for spawner,spawn_info in pairs(mob_spawn_list) do
				if spawn_info.mob_weight > 0 then
					half_mob_spawns[spawner] = {[1] = {}, [2] = mob_spawns[spawner][2]}
					for prefab,count in pairs(spawn_info.count) do
						if prefab ~= "total" then
							for j=1,count do
								local current_spawn_index = mob_count[prefab].spawners[spawner][(j - 1) % #(mob_count[prefab].spawners[spawner]) + 1]
								local mob_spawn = mob_spawns[spawner][1][current_spawn_index]
								table.insert(half_mob_spawns[spawner][1], mob_spawn)
							end
						end
					end
				end
			end

			return half_mob_spawns
		end

		return mob_spawns
	end

	-- Spawn all mobs for the wave
	local function SpawnSetup(delay)
		self.active_spawners = 0
		for i,spawn in pairs(ApplyDuplicatorMutator(mob_spawns)) do
			assert(self.inst.spawners[i] ~= nil, "Spawner '" .. tostring(i) .. "' does not exist!")
			self.inst.spawners[i]:SpawnMobs(spawn, delay, self.current_round, self.custom_wave and self.custom_wave.name or self.current_wave)
			self.active_spawners = self.active_spawners + 1
		end
	end

	-- Dialogue
	local dialogue = wave_info and wave_info.dialogue or wave and self.wavemanager.dialogue and self.wavemanager.dialogue[self.current_wave]
	if dialogue and dialogue.speech and self.total_rounds_completed < #self.waveset_data then
		self.inst:DoTaskInTime(dialogue.pre_delay or 3, function() -- TODO tuning default pre_delay?
			if type(dialogue.speech) == "function" then
				dialogue.speech(self) -- TODO atm this function must push the "dialoguecomplete" event when dialogue is completed, need to figure out a way to make it do it automatically
			else
				self:DoSpeech(dialogue.speech, dialogue.str_id, dialogue.is_banter, dialogue.line_duration, dialogue.no_anim, dialogue.str_par)
			end
			-- TODO should this be a function, it's what remains of QueueBoarlordDoneTalking
			local function spawnafterdialogue()
				SpawnSetup(dialogue.pst_delay or 1) -- TODO default pst_delay?
				self.inst:RemoveEventCallback("dialoguecomplete", spawnafterdialogue)
			end
			self.inst:ListenForEvent("dialoguecomplete", spawnafterdialogue)
		end)
	else
		if wave_info and wave_info.SpawnSetup then
			if wave_info.SpawnSetup(self, wave_info.data) then
				self:SpawnFinished()
			end
		else
			SpawnSetup(self.current_round_data.no_talk_delay and self.current_round_data.no_talk_delay[self.current_wave] or 2.33) -- TODO what is with this random number? tuning default no_talk_delay?
		end
	end
	self.inst:PushEvent("new_wave", {round = self.current_round, wave = self.current_wave, custom_wave = self.custom_wave and self.custom_wave.name})
end

-- The forge lord will say the given dialogue
-- str_tbl: Table of strings that contains the dialogue represented by a string. Assumes it is located in the STRINGS table already.
--	Ex. To use STRINGS.BOARLORD_ROUND5_BOARRIOR_INTRO you would pass "BOARLORD_ROUND5_BOARRIOR_INTRO"
-- str_id: Specify the line of dialogue that the Forge Lord will say. Defaults to 0. 0 will have the Forge Lord say the entire dialogue.
-- is_banter: If true then the forge lord will randomly say one line from the given dialogue.
-- no_anim: The Forge Lord will not animate while saying dialogue.
function LavaarenaEvent:DoSpeech(str_tbl, str_id, is_banter, line_duration, no_anim, str_par, done_talking_fn, ignore_dialogue_complete)
	local forge_lord = self:GetForgeLord()
	if str_tbl and forge_lord then
		local id = str_id or is_banter and COMMON_FNS.GetBanterID(str_tbl) or 0 -- id of 0 will say the entire str_tbl
		forge_lord.components.talker:Chatter(str_tbl, id or 0, line_duration or self.current_round_data.lineduration or 3.983333, no_anim, str_par) -- TODO another random number

		-- TODO this is to force it to work for now, find better way, pushes the dialoguecomplete event which is used to determine when a waves dialogue is complete
		local function spawnafterdialogue()
			forge_lord:RemoveEventCallback("donetalking", spawnafterdialogue)
			if done_talking_fn then
				done_talking_fn(forge_lord)
			end
			if not ignore_dialogue_complete then
				self.inst:PushEvent("dialoguecomplete")
			end
		end
		forge_lord:ListenForEvent("donetalking", spawnafterdialogue)
	end
end

-- Returns true if a wave is currently spawning or if there are queued waves
function LavaarenaEvent:AreWavesSpawning()
	return not self.wave_ready or #self.queued_waves > 0
end

-- Checks if the round has ended and starts the next round. If there are no more rounds then it will end the game.
function LavaarenaEvent:EndRoundCheck()
	-- endcase, if all mobs die before the last wave finishes spawning, wave_ready is true when no waves are in the middle of spawning and make sure no waves are queued to spawn
	local startnextround = self.wavemanager.onallmobsdied(self) and not self:AreWavesSpawning()
	if startnextround then
		self.total_rounds_completed = self.total_rounds_completed + 1
		if self.current_round_data.roundend then
			self.current_round_data.roundend(self)
		end
		-- Start Next Round
		if self.current_round < #self.waveset_data or self.endless then
			self.inst:PushEvent("round_complete", {round = self.current_round, waveset = self.waveset})
			self:StartRound(self.current_round >= #self.waveset_data and 1 or self.current_round + 1)
		-- Victory
		else
			self.inst:DoTaskInTime(self.waveset_data.victory_delay or 3, function() -- TODO tuning default victory wait time? better format for it?
				self:End(true)
			end)
		end
	end
end

function LavaarenaEvent:End(victory)
	if self.victory ~= nil then return end
	local field_order = {"userid","netid","name","random_character","character","cardstat", "current_perk", "original_perk"}
	local function AddExpToPlayer(info, detail)
		detail.val = math.ceil(detail.val)
		--info.new_xp   = info.new_xp + detail.val
		info.match_xp =  info.match_xp + detail.val
		table.insert(info.details, detail)
	end
	local function AddExpToAllPlayers(data, detail)
		for userid,info in pairs(data) do
			AddExpToPlayer(info, detail)
		end
	end
	local function AddExpInfoToPlayer(exp_info, detail, name, userid, mult, add, flat)
		exp_info[userid][name] = {
			mult = mult or 1,
			add = add or 0,
			flat = flat or 0,
			detail = detail,
		}
	end
	local function AddExpInfoToAllPlayers(exp_info, detail, name, mult, add, flat)
		for userid,info in pairs(exp_info) do
			AddExpInfoToPlayer(exp_info, detail, name, userid, mult, add, flat)
		end
	end
	local function GetExp(invalid_player_attacks)
		local exp_data = {}
		local exp_info = {}
		local player_count = 0
		local exp_history = {}

		for userid,info in pairs(TheWorld.components.stat_tracker.stats) do
			player_count = player_count + 1
			exp_data[userid] = {
				earned_boxes = 0,
				new_xp       = TheWorld.net.components.levelmanager:GetUsersExp(userid),
				match_xp     = 0,
				details      = {},
				character    = info.user_data.user.prefab,
			}
			exp_info[userid] = {}
		end

		local total_rounds = self.waveset_data and #self.waveset_data or 10
		local rounds_completed_ratio = (self.total_rounds_completed <= 0 and 1 or self.total_rounds_completed) / total_rounds

		-- Time
		-- exp multiplied by rounds completed ratio, meaning victory rewards better time exp than afking on round 1.
		-- 1 = *4, 2= *3, 3 = *2, 4 = *1.67, 5 = *1.33, >=6 = *1
		local max_time_exp = math.max(TUNING.FORGE.EXP.GENERAL.MAX_TIME, (TUNING.FORGE.EXP.GENERAL.MAX_TIME * (player_count >= 4 and (-player_count + 9)/3 or (-player_count + 5)))) * rounds_completed_ratio
		AddExpInfoToAllPlayers(exp_info, {desc = "LAB_DURATION", val = 0, atlas = "images/lavaarena_quests.xml", tex = "lab_duration.tex"}, "time", nil, nil, math.min(max_time_exp, TheFrontEnd.match_results.outcome.time * 4))

		-- Waveset
		-- Get Exp from last completed round.
		if self.total_rounds_completed > 0 then
			local waveset_info = REFORGED_DATA.wavesets[REFORGED_SETTINGS.gameplay.waveset]
			local round_exp_details = waveset_info.exp_details and waveset_info.exp_details[math.min(self.total_rounds_completed, total_rounds)]
			if round_exp_details then
				AddExpToAllPlayers(exp_data, round_exp_details)
			end
		end

		-- Mob kills
		local mob_exp = 0
		for mob,count in pairs(TheWorld.components.stat_tracker.mob_kills) do
			mob_exp = mob_exp + (TUNING.FORGE.EXP.MOB[mob] or 0) * count
		end
		if mob_exp > 0 then
			AddExpInfoToAllPlayers(exp_info, {desc = "MOB_KILLS", val = 0, atlas = "images/lavaarena_quests.xml", tex = "laq_killingblows_lots.tex"}, "mob_kills", nil, nil, mob_exp)
		end

		-- Experience bonuses on victory only or if endless and at least one set has been completed
		if victory or self.total_rounds_completed >= total_rounds then
			-- General
			-- Characters (unique, same, random)
			local unique_characters = true
			local team_no_deaths    = true
			local team_no_abilities = true
			local team_random_characters = true
			local characters = {}
			local stat_order = TheWorld.components.stat_tracker.stat_order
			for userid,player_info in pairs(TheWorld.components.stat_tracker.stats) do
				-- Character Checks
				local character = player_info.user_data.user.prefab
				characters[character] = (characters[character] or 0) + 1
				unique_characters = unique_characters and characters[character] <= 1
				if TheWorld.components.stat_tracker.random_characters[userid] then
					AddExpInfoToPlayer(exp_info, {desc = "RANDOM_CHARACTER", val = 0, atlas = "images/avatars.xml", tex = "avatar_unknown.tex"}, "random_character", userid, nil, TUNING.FORGE.EXP.GENERAL.RANDOM_CHARACTER) -- TODO dice icon?
				else
					team_random_characters = false
				end
				-- Deaths Checks
				local player_died = player_info.stat_values[stat_order["deaths"]] and player_info.stat_values[stat_order["deaths"]] > 0
				if not player_died then
					AddExpInfoToPlayer(exp_info, {desc = "LAB_NO_DEATHS_PLAYER", val = 0, atlas = "images/lavaarena_quests.xml", tex = "lab_no_deaths_player.tex"}, "no_deaths", userid, nil, TUNING.FORGE.EXP.GENERAL.NO_DEATHS)
				end
				team_no_deaths = team_no_deaths and not player_died
				-- Abilities Checks
				local cast_spells = player_info.stat_values[stat_order["spellscast"]] and player_info.stat_values[stat_order["spellscast"]] > 0
				local used_alt_attacks = player_info.stat_values[stat_order["altattacks"]] and player_info.stat_values[stat_order["altattacks"]] > 0
				if not (cast_spells or used_alt_attacks) then
					AddExpInfoToPlayer(exp_info, {desc = "NO_ABILITIES", val = 0, atlas = "images/reforged.xml", tex = "exp_noabilities.tex"}, "no_abilities", userid, nil, TUNING.FORGE.EXP.GENERAL.NO_ABILITIES) -- TODO icon
				end
				team_no_abilities = team_no_abilities and not (cast_spells or used_alt_attacks)
				-- Consecutive Match
				-- TheNet:IsConsecutiveMatchForPlayer() -- does not work. Not sure how this checks for it.
				local consecutive_match = Settings.match_results and Settings.match_results.wxp_data and Settings.match_results.wxp_data[userid]
				if consecutive_match then
					AddExpInfoToPlayer(exp_info, {desc = "LAB_CONSECUTIVE", val = 0, atlas = "images/reforged.xml", tex = "exp_consecutivegames.tex"}, "consecutive_match", userid, nil, nil, TUNING.FORGE.EXP.GENERAL.CONSECUTIVE_MATCH) -- TODO icon
					if Settings.match_results.outcome and Settings.match_results.outcome.won and not (Settings.match_results.player_stats and Settings.match_results.player_stats.commands) then
						AddExpInfoToPlayer(exp_info, {desc = "CONSECUTIVE_WIN", val = 0, atlas = "images/reforged.xml", tex = "exp_consecutivewins.tex"}, "consecutive_win", userid, nil, nil, TUNING.FORGE.EXP.GENERAL.CONSECUTIVE_WIN) -- TODO icon
					end
				end
			end
			-- General Team
			if unique_characters then
				AddExpInfoToAllPlayers(exp_info, {desc = "LAB_UNIQUE_CHARACTERS", val = 0, atlas = "images/lavaarena_quests.xml", tex = "lab_unique_characters.tex"}, "unique_characters", nil, TUNING.FORGE.EXP.GENERAL.UNIQUE_CHARACTERS)
			end
			local unique_character_count = 0
			local char = "WILSON"
			for character,count in pairs(characters) do
				char = character
				unique_character_count = unique_character_count + 1
			end
			if unique_character_count <= 1 then -- TODO player count > 1
				AddExpInfoToAllPlayers(exp_info, {desc = "SAME_CHARACTERS", val = 0, atlas = "images/avatars.xml", tex = "avatar_mod.tex"}, "same_characters", nil, TUNING.FORGE.EXP.GENERAL.SAME_CHARACTERS[string.upper(char)] or TUNING.FORGE.EXP.GENERAL.SAME_CHARACTERS.UNKNOWN) -- TODO icon and value, self_inspect_mod in hud
			end
			if team_random_characters then
				AddExpInfoToAllPlayers(exp_info, {desc = "RANDOM_CHARACTERS_TEAM", val = 0, atlas = "images/reforged.xml", tex = "exp_teamrandom.tex"}, "team_random_characters", nil, TUNING.FORGE.EXP.GENERAL.RANDOM_CHARACTERS_TEAM)
			end
			if team_no_deaths then
				AddExpInfoToAllPlayers(exp_info, {desc = "LAB_NO_DEATHS_TEAM", val = 0, atlas = "images/lavaarena_quests.xml", tex = "lab_no_deaths_team.tex"}, "team_no_deaths", nil, TUNING.FORGE.EXP.GENERAL.NO_DEATHS_TEAM)
			end
			if team_no_abilities then
				AddExpInfoToAllPlayers(exp_info, {desc = "NO_ABILITIES_TEAM", val = 0, atlas = "images/reforged.xml", tex = "exp_noabilitiesteam.tex"}, "team_no_abilities", nil, TUNING.FORGE.EXP.GENERAL.NO_ABILITIES_TEAM) -- TODO icon
			end

			-- Party Size
			local MAX_PARTY_SIZE = 6
			if player_count < MAX_PARTY_SIZE then
				AddExpInfoToAllPlayers(exp_info, {desc = "PARTY_SIZE", val = 0, atlas = "images/lavaarena_quests.xml", tex = "lab_no_deaths_team.tex"}, "player_count", nil, math.pow(2, -player_count + MAX_PARTY_SIZE)) -- TODO icon
			end

			local function AddExpDetails(name, info, current_val, exp_data) -- TODO better name?
				local exp_details = info and info.exp_details and deepcopy(info.exp_details)
				if exp_details then
					if info.icon then
						exp_details.atlas = info.icon.atlas
						exp_details.tex = info.icon.tex
					end

					local exp = {mult = 1, add = 0, flat = 0}
					if type(exp_details.val) == "function" then
						exp = exp_details.val(current_val)
					elseif type(exp_details.val) == "table" then
						exp.mult = exp_details.val.mult
						exp.add = exp_details.val.add
						exp.flat = exp_details.val.flat
					else
						exp.flat = exp_details.val
					end
					AddExpInfoToAllPlayers(exp_info, exp_details, name, exp.mult, exp.add, exp.flat)
				end
			end

			-- GameType
			local gametype = REFORGED_SETTINGS.gameplay.gametype
			AddExpDetails("gametype", REFORGED_DATA.gametypes[gametype], gametype, exp_data)

			-- Difficulty
			local difficulty = REFORGED_SETTINGS.gameplay.difficulty
			AddExpDetails("difficulty", REFORGED_DATA.difficulties[difficulty], difficulty, exp_data)

			-- Mutators
			for mutator,val in pairs(REFORGED_SETTINGS.gameplay.mutators) do
				if val then
					AddExpDetails(mutator, REFORGED_DATA.mutators[mutator], val, exp_data)
				end
			end
		end
		-- Custom Bonuses
		local commands_executed = self.command_executed
		for userid,info in pairs(exp_data) do
			-- Playing with friends
			local friend_count = TheWorld.components.stat_tracker.friend_count[userid] or 0
			if friend_count > 0 then
				AddExpInfoToPlayer(exp_info, {desc = "LAB_FRIENDS_BONUS", val = 0, atlas = "images/lavaarena_quests.xml", tex = "lab_friends_bonus.tex"}, "friends_bonus", userid, nil, nil, math.min(TUNING.FORGE.EXP.GENERAL.MAX_FRIENDS, TUNING.FORGE.EXP.GENERAL.PER_FRIEND*friend_count*math.min(1, TheFrontEnd.match_results.outcome.time/TUNING.FORGE.EXP.GENERAL.MAX_TIME_FRIENDS)))
			end
			-- Calculate match exp
			local match_exp = info.match_xp
			local mult = 1
			local add = 0
			local flat = 0
			for name,data in pairs(exp_info[userid]) do
				mult = mult * (data.mult or 1)
				add = add + (data.add or 0)
				flat = flat + (data.flat or 0)
				data.detail.mult = data.mult
				data.detail.add = data.add
				data.detail.val = data.flat--match_exp * (data.mult + data.add - 1) + data.flat
				-- Only add non zero flats and adds or non "1" mults
				if data.detail.val ~= 0 or data.mult ~= 1 or data.add ~= 0 then
					AddExpToPlayer(exp_data[userid], data.detail)
				end
			end
			info.match_xp = math.ceil(match_exp * (mult + add) + flat)
			local join_time = TheWorld.components.stat_tracker.join_times[userid]
			-- Users who join after the match has started receive a percent of the exp based on when they joined the match.
			if join_time == nil or join_time > self.start_time then
				AddExpToPlayer(info, {desc = "JOINABLE_MIDMATCH", val = -info.match_xp * (join_time == nil and self.duration or (join_time - self.start_time)) / self.duration, atlas = "images/inventoryimages1.xml", tex = "arrowsign_post_factory.tex"})
			end

			-- Make sure match exp is not negative
			if info.match_xp < 0 then
				info.match_xp = 0
			end

			-- Invalid Game Check
			local valid_run = true
			if commands_executed then
				AddExpToPlayer(info, {desc = "COMMANDS", val = -info.match_xp or 0, atlas = "images/inventoryimages1.xml", tex = "arrowsign_post_factory.tex"})
				valid_run = false
			else
				local invalid_exp_mult = math.min(self.invalid_attack_history[userid] and self.invalid_attack_history[userid].exp_mult > 0 and self.invalid_attack_history[userid].exp_mult or self.group_exp_mult > 0 and self.group_exp_mult / player_count or 0, 1)
				if invalid_exp_mult > 0 then
					AddExpToPlayer(info, {desc = "SCRIPTS", val = math.floor(-info.match_xp * invalid_exp_mult), atlas = "images/inventoryimages1.xml", tex = "blueprint_rare.tex"})
					valid_run = false
				end
			end
			-- Add Achievements if it was a valid run.
			if valid_run then
				for name,tracking_info in pairs(self.inst.components.achievement_tracker:GetUsersTrackedAchievements(userid) or {}) do
					local achievement_data = REFORGED_DATA.achievements[name]
					-- Only Update achievements that satisfy their player count requirement.
					if not achievement_data.requirements.player_count or TheWorld.components.stat_tracker:GetTotalActivePlayerCount() <= achievement_data.requirements.player_count then
						if achievement_data and achievement_data.on_match_complete_fn then
							achievement_data.on_match_complete_fn(self, userid, name)
						end
						local achievement_info = {name = name, val = 0}
						local server_info = tracking_info.server
						if server_info and (server_info.unlocked or server_info.progress and server_info.progress > 0) then
							achievement_info.server = {unlocked = server_info.unlocked, progress = server_info.progress, exp = server_info.unlocked and achievement_data.exp}
						end
						local client_info = tracking_info.client
						if client_info and (client_info.unlocked or client_info.progress and client_info.progress > 0) then
							achievement_info.client = {unlocked = client_info.unlocked, progress = client_info.progress, exp = client_info.unlocked and achievement_data.exp}
						end
						if achievement_info.server or achievement_info.client then
							AddExpToPlayer(info, achievement_info)
						end
					end
				end
			end
			info.new_xp = info.new_xp + info.match_xp
		end

		return exp_data
	end

	local function SetMatchResults()
		--TheFrontEnd.match_results.wxp_data = {}
		--TheFrontEnd.match_results.wxp_data[TheNet:GetUserID()] = { new_xp = 0, match_xp = 0, earned_boxes = 0, details = {}}

		local player_stats = {}
		local users = {}
		local highest_stats = {}
		local players_best_stats = {}
		local death_count = 0
		local field_order_established = false

		TheWorld.components.stat_tracker:FindBestStats()
		for userid,user_info in pairs(TheWorld.components.stat_tracker.stats) do
			local current_player_stats = {}
			table.insert(current_player_stats, userid)
			table.insert(current_player_stats, user_info.user_data.user.netid)
			local username = string.gsub(user_info.user_data.user.name, ",", "_") -- get rid of any commas in the users name, causes issues with the parser for event stats
			table.insert(current_player_stats, username)
			table.insert(current_player_stats, TheWorld.components.stat_tracker.random_characters[userid] or false)
			-- Ensure that the player has a prefab
			if not user_info.user_data.user.prefab or user_info.user_data.user.prefab == "" then
				user_info.user_data.user.prefab = "unknown"
			end
			table.insert(current_player_stats, user_info.user_data.user.prefab)
			table.insert(current_player_stats, user_info.user_data.beststat[1])

			-- Perks
			table.insert(current_player_stats, self.inst.net.components.perk_tracker:GetCurrentPerk(userid))
			table.insert(current_player_stats, self.inst.net.components.perk_tracker:GetCurrentPerk(userid, true))

			for i, stat in pairs (TheWorld.components.stat_tracker:GetStatFieldOrder()) do
				table.insert(current_player_stats, math.floor(user_info.stat_values[i] or 0)) -- TODO round down or up?
				if not field_order_established then
					table.insert(field_order, stat)
				end
			end
			field_order_established = true
			table.insert(player_stats, current_player_stats)

			table.insert(users, user_info.user_data)
			death_count = death_count + TheWorld.components.stat_tracker:GetStatTotal("deaths", userid)
		end

		local users_test = json.encode(users)
		TheFrontEnd.match_results.mvp_cards = json.decode(users_test)
		local gameplay_settings = REFORGED_SETTINGS.gameplay

		local version = KnownModIndex:IsModEnabled("workshop-1938752683") and GetModVersion("workshop-1938752683") or KnownModIndex:IsModEnabled("forge") and "git_" .. tostring(GetModVersion("forge")) or "???"
		local invalid_player_attacks = self:CheckPlayerAttacks()
		TheFrontEnd.match_results.player_stats = {gametype = "ReForged", session = TheWorld.meta.session_identifier, data = player_stats, fields = field_order, commands = self.command_executed, scripts = invalid_player_attacks} -- TODO change gametype
		TheFrontEnd.match_results.outcome = {won = victory, time = self.duration, total_deaths = death_count, preset = gameplay_settings.preset, mode = gameplay_settings.mode, gametype = gameplay_settings.gametype, waveset = gameplay_settings.waveset, map = gameplay_settings.map, difficulty = gameplay_settings.difficulty, mutators = gameplay_settings.mutators, version = version ~= "" and version or "0.1", total_rounds_completed = self.total_rounds_completed}
		TheFrontEnd.match_results.wxp_data = GetExp(invalid_player_attacks)
		TheFrontEnd.match_results.outcome.script_data = self.invalid_attack_history
		if TheWorld.ismastersim then -- TODO is this needed? isn't this component only on the server?
			SaveEventMatchStats(true, TheFrontEnd.match_results)
		end

		-- Reset stat tracker for next game
		TheWorld.components.stat_tracker:Reset()
	end

	self.inst.net.components.lavaarenaeventstate:PushPopup(victory)
	self.victory = victory
	self.inst.net.components.lavaarenaeventstate.is_match_complete:set(true)
	self.duration = math.floor(GetTime() - self.start_time + 0.5)
	if self.waveset_data then
		local endgame_speech = self.waveset_data.endgame_speech
		self.inst:DoTaskInTime(endgame_speech and endgame_speech.delay or 0.5, function() -- TODO tuning default endgame_speech delay???
			-- TODO pobably needed hmmm...
			self:GetForgeLord().components.talker:ShutUp() --Fid: Because RLGL mode, there's a chance he'll be talking
			local endgame_dialogue = endgame_speech and (victory and endgame_speech.victory or endgame_speech.defeat)
			if endgame_dialogue then
				if type(endgame_dialogue) == "function" then -- TODO test this
					endgame_dialogue(self)
				else
					self:DoSpeech(endgame_dialogue.speech, endgame_dialogue.str_id, endgame_dialogue.is_banter, endgame_dialogue.line_duration, endgame_dialogue.no_anim, endgame_dialogue.str_par)
				end
			end
			-- TODO should this be a function, it's what remains of QueueBoarlordDoneTalking
			-- also do we need to remove callback? because reset would nullify it right?
			local function spawnafterdialogue()
				-- Check for any entities that should have been removed
				--[[local ent_count = 0
				for i,ent in pairs(Ents) do
					if not (ent:HasTag("UI") or ent:HasTag("groundtargetblocker")) then
						print(ent:GetDebugString())
						ent_count = ent_count + 1
					end
				end
				print("Total Ents: " .. tostring(ent_count))--]]
				COMMON_FNS.ResetWorld()
				self.inst:RemoveEventCallback("dialoguecomplete", spawnafterdialogue)
			end
			self.inst:ListenForEvent("dialoguecomplete", spawnafterdialogue)
		end)
	end

	TheWorld:PushEvent("ms_lavaarenaended", victory) -- TODO this is pushed

	-- TODO if this delay is longer than the spawnafterdialogue, would that not cause the reset to override these values?
	-- 1 second delay to make sure all stats are updated note without this deaths would not count at the end
	self.inst:DoTaskInTime(1, function()
		SetMatchResults()
	end)
end

-- TODO issues with timers triggering waves, call wavemanager.ondisable prior to starting round?
-- Forces the current round and current wave to restart
function LavaarenaEvent:ForceRestartCurrentRound()
	self:StartRound(self.current_round)
end

-- TODO
-- Resets all players with original equipment and health and despawns all equipment earned and all enemies left on the map and restarts the forge
function LavaarenaEvent:ForceRestart()

end

-- TODO should on enable restart forge or continue? currently continues, might not continue anymore, test this
function LavaarenaEvent:Enable()
	self.enabled = true
end

-- Warning: Disabling a wave in progress might result in possible wave triggers still occurring. No waves can be queued while disabled, but if enabled before a wave trigger occurs could result in a wave being queued. A correctly configured ondisable can solve this issue.
function LavaarenaEvent:Disable()
	self.enabled = false
	if self.wavemanager and self.wavemanager.ondisable then
		self.wavemanager.ondisable(self)
	end
end

-- Checks if all spawners have completed spawning
local spawns_completed = 0
function LavaarenaEvent:SpawnFinishedForPortal(spawn_portal)
    spawns_completed = spawns_completed + 1
    if spawns_completed == self.active_spawners then
    	self:SpawnFinished({spawn_portal = spawn_portal})
    	spawns_completed = 0
    end
end

function LavaarenaEvent:SpawnFinished(data)
    self.inst:PushEvent("spawningfinished", {spawn_portal = data.spawn_portal})
	-- TODO this should be in a separate mod or server option?
	-- Make all non mobs unclickable
    local pt = self:GetArenaCenterPoint()
	local ents = TheSim:FindEntities(pt.x, 0, pt.z, 300, nil, {"NOCLICK", "LA_mob", "corpse", "ALLOWCLICK", "specialnoclick"})
    for i, ent in ipairs(ents) do
		if not ent.components.inventoryitem then
			ent:AddTag("NOCLICK")
			ent.tempnoclick = true
		end
    end
end

function LavaarenaEvent:OnUpdate(dt)
    self.wavemanager.onupdate(self, dt)
end

function LavaarenaEvent:IsIntermission()
	return #TheWorld.components.forgemobtracker:GetAllLiveMobs() == 0
end

function LavaarenaEvent:IsMatchComplete()
	return self.victory ~= nil
end

-- TODO move to a different component
function LavaarenaEvent:AddPlayerAttack(userid, time)
	if not self.player_attacks[userid] then
		self.player_attacks[userid] = {}
	end
	table.insert(self.player_attacks[userid], time)
end

local MAX_ATTACK_VARIATION = FRAMES -- one frame
--local MAX_ATTACK_COUNT = 2000
local CONSECUTIVE_MAX_ATTACK_COUNT = 20
local MAX_VIOLATIONS = 10
function LavaarenaEvent:CheckPlayerAttacks()
	--Debug:PrintTable(self.player_attacks)
	self.invalid_attack_history = {}
	self.group_exp_mult = 0
	for userid,attacks in pairs(self.player_attacks) do
		-- Get attack time differences
		local prev_attack_time
		local attack_differences = {}
		for __,attack_time in pairs(attacks) do
			if prev_attack_time then
				local difference = attack_time - prev_attack_time
				if difference > 0 and difference < 1 then
					table.insert(attack_differences, difference)
				end
			end
			prev_attack_time = attack_time
		end

		-- Compare attack time difference
		local prev_difference
		local consecutive_count = 0
		local most_consecutive = 0
		local over_threshold_count = 0
		for __,difference in pairs(attack_differences) do
			if prev_difference then
				--print("Prev Diff: " .. tostring(prev_difference))
				--print("Diff: " .. tostring(difference))
				--print(" - " .. tostring(math.abs(difference - prev_difference)))
				if math.abs(difference - prev_difference) < MAX_ATTACK_VARIATION then
					consecutive_count = consecutive_count + 1
				else
					--print("Consecutive Attack Count: " .. tostring(consecutive_count))
					most_consecutive = most_consecutive >= consecutive_count and most_consecutive or consecutive_count
					over_threshold_count = over_threshold_count + (consecutive_count > CONSECUTIVE_MAX_ATTACK_COUNT and 1 or 0)
					consecutive_count = 0
				end
			end
			prev_difference = difference--23333334551, 23333334550
		end

		-- Calculate this players exp mult
		local max_mult = most_consecutive/CONSECUTIVE_MAX_ATTACK_COUNT
		local violation_mult = math.min(over_threshold_count/MAX_VIOLATIONS * max_mult, 1)
		local player_exp_mult = over_threshold_count > 0 and violation_mult or TheWorld.net.scripts_list[userid] and 1 or 0
		self.invalid_attack_history[userid] = {most_consecutive = most_consecutive, over_threshold_count = over_threshold_count, exp_mult = player_exp_mult, scripts = TheWorld.net.scripts_list[userid] ~= nil}
		self.group_exp_mult = self.group_exp_mult + player_exp_mult -- Need to divide by total players when using for exp calculations.
	end
	for userid,_ in pairs(TheWorld.net.scripts_list) do
		if not self.invalid_attack_history[userid] then
			self.invalid_attack_history[userid] = {most_consecutive = 0, over_threshold_count = 0, exp_mult = 1, scripts = true}
			self.group_exp_mult = self.group_exp_mult + 1
		end
	end
	Debug:PrintTable(self.invalid_attack_history, 3)
	return self.group_exp_mult > 0
end

return LavaarenaEvent
