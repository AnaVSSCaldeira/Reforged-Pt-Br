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
--[[
Round 1:
    Wave 1 - Pitpig (3)
    Wave 2 - Pitpig (6)
    Wave 3 - Pitpig (9)
    Wave 4 - Pitpig (12)
Round 2:
    Wave 1 - Pitpig (6) + Crocommander (2)
    Wave 2 - Pitpig (6) + Crocommander (2)
Round 3:
    Wave 1 - Snortoise (7)
Round 4:
    Wave 1 - Scorpeon (7)
    Wave 2 - Snortoise (2) + Scorpeon (2)
    Wave 3 - Boarilla (1) [15 seconds after previous wave or death]
Round 5:
    Wave 1 - Boarilla (2)
--]]
--[[
TODO
SetSpawn
	need default option of all spawners so you don't need to type {1,2,3} for them or if there are 9 spawners that would be annoying
classic banner was the same banner everytime? was it different every round?
did this years forge change it every wave? can't remember
--]]
-----------
-- SETUP --
-----------
-- TODO should I keep them in a table in global or should I just make them a global function so you just call the function name?
local _W = _G.UTIL.WAVESET
local waveset_data = deepcopy(require("wavesets/boarilla"))

----------------
-- MOB SPAWNS --
----------------
local mob_spawns = {
	[5] = {
		{{{"boarilla"},}}, -- 1-1,3
		 -- Forge has pitpigs spawn in slots 1 and 3 (1 in back and 1 in the front right), I changed it to 2 in front since that makes more sense. TODO should I change it to what forge had or keep it this way?
		{{{"crocommander"},{"pitpig", 1, 1},{"pitpig", 1, 2}},{{2, 3},}}, -- 2&3-2 is rotated 180 degrees
		_W.CreateMobSpawnFromPreset("line", {"snortoise", "scorpeon"}), -- 3-1,3
	},
}

----------------
-- ITEM DROPS --
----------------
--[[
TODO
	if you killed a snortoise last on first boarilla, does the snortoise drop everything? if you kill boarrior before killing a pitpig, does the boarrior drop stuff or the pitpig?
	talk to instant noodles about not killing that boarilla video
--]]
waveset_data.item_drops[4] = {round_end = {"steadfastarmor", "clairvoyantcrown"}}

----------------
-- CUSTOM FNS --
----------------
-- Leashes all pitpigs to the first croc on each spawner
local function LeashPitpigsToCrocs(spawnedmobs)
	for i,mob_list in pairs(spawnedmobs) do
		local mobs = _W.OrganizeMobs(mob_list)
		if mobs then
			_W.LeashMobs(mobs.crocommander and mobs.crocommander[1], mobs.pitpig)
		end
	end
end

-- TODO common fn? should we have a general function for this that passes in a list of any specific mob? maybe make a variance component? controls the variance of the mob and this would call it?
-- Sets the appearance of the boarilla
local function SetBoarillasVariance(boarillas, variation)
    local non_duped_boarilla_count = 0
    for i,boarilla in pairs(boarillas) do
        if not boarilla.duplicator_source then
            non_duped_boarilla_count = non_duped_boarilla_count + 1
            boarilla:SetVariation(variation or non_duped_boarilla_count)
        end
    end
end

-- Round 5, next wave timer fn
local function NextWaveTimerFN(self, wave)
	-- Remove health trigger for given wave
	table.remove(self.health_triggers.boarillas, 1)
	self:QueueWave(wave)
end

------------------
-- WAVESET DATA --
------------------
-- Round 5
waveset_data[5] = {
    waves = {
		_W.SetSpawn({_W.CreateSpawn(mob_spawns[5][1]), {1,3}}),      -- Wave 1
        _W.SetSpawn({_W.CreateSpawn(mob_spawns[5][2], 180), {2}}),   -- Wave 2
		_W.SetSpawn({_W.CreateSpawn(mob_spawns[5][3]), {1,3}}, {_W.CreateSpawn(mob_spawns[5][2], 180), {2}}), -- Wave 3
    },
    wavemanager = {
		dialogue = {
			[1] = {pre_delay = 3.5, speech = "BOARLORD_ROUND5_START"},
			[2] = {pre_delay = 0.5, speech = "BOARLORD_ROUND5_FIGHT_BANTER1", is_banter = true},
			[3] = {pre_delay = 0.5, speech = "BOARLORD_ROUND5_FIGHT_BANTER2", is_banter = true},
		},
        onspawningfinished = {
			[1] = function(self, spawnedmobs)
				-- Start 5 min timer to queue next wave
				self.timers.queue_next_wave = self.inst:DoTaskInTime(300, function()
					NextWaveTimerFN(self, 2)
				end)

                -- Health Triggers
                local boarillas = _W.OrganizeAllMobs(spawnedmobs).boarilla
				self.health_triggers.boarillas = {
					[1] = {total_percent = 0.6*#boarillas , single_percent = 0.4, fn = function() self:QueueWave(2) end},
					[2] = {single_percent = 0, all_percent = 0.4, fn = function() self:QueueWave(3) end},
				}
				_W.AddHealthTriggers(self.health_triggers.boarillas, unpack(boarillas))
				-- Give each Boarilla a unique look
				SetBoarillasVariance(boarillas)
			end,
			[2] = function(self, spawnedmobs)
				-- Restart 5 min timer to queue next wave
				RemoveTask(self.timers.queue_next_wave)
				self.timers.queue_next_wave = self.inst:DoTaskInTime(300, function()
					NextWaveTimerFN(self, 3)
				end)
				LeashPitpigsToCrocs(spawnedmobs) -- TODO this only occurs on one spawner, do I specify or still loop?
			end,
			[3] = function(self, spawnedmobs)
				-- Restart 5 min timer to queue next wave
				RemoveTask(self.timers.queue_next_wave)
				LeashPitpigsToCrocs(spawnedmobs) -- TODO this only occurs on one spawner, do I specify or still loop?
			end,
		},
    },
}
waveset_data.endgame_speech.victory.speech = "BOARLORD_ROUND4_PLAYER_VICTORY"

return waveset_data
