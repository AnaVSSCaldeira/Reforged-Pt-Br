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
    Wave 2 - Pitpig (2) + Crocommander (1) [when first Boarilla hits 40% health or when cumulative Boarilla health hits 120%]
    Wave 3 - Pitpig (2) + Crocommander (1) + Snortoise (2) + Scorpeon (2) [when first Boarilla dies or when cumulative Boarilla health hits 40%]
    Wave 4 - Boarrior (1) [when cumulative Boarilla health hits 20%]
        Special - Pitpig (12) [when Boarrior hits half health]
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
local waveset_data = deepcopy(require("wavesets/boarillas"))

----------------
-- MOB SPAWNS --
----------------
local mob_spawns = {
	[5] = {
		[4] = {{{"boarrior"},}}, -- 4-2
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
local function AddGolem(item_set, waves, item_count)
    if item_count == 1 then
        -- Round 4 Wave 1 or 2
        table.insert(item_set, "bacontome")
        table.insert(waves, {4,1})
        table.insert(waves, {4,2})
    end
end
local function ApplyRandomItemDropSpread(item_drops)
    -- RANDOM: Round 1 Wave 2-4 - 3 | Round 2 Wave 1-2 - 2
    _W.SpreadItemSetOverWaves(item_drops, {"barbedhelm", "crystaltiara", "jaggedarmor", "silkenarmor", "featheredwreath"}, {{1,2},{1,3},{1,4},{2,1},{2,2}}, "random_mob", 1)
    -- RANDOM: Round 2 Wave 1-2
    _W.SpreadItemSetOverWaves(item_drops, {"splintmail"}, {{2,1},{2,2}}, "random_mob", 1)
    -- RANDOM: Round 3 | Round 4 (1 item per round/wave)
    _W.SpreadItemSetOverWaves(item_drops, {"flowerheadband", "wovengarland"}, {{3,1}}, "random_mob", 1, AddGolem)
end

waveset_data.item_drops[5] = {
    [2] = {
        final_mob = {_W.ChooseRandomItem("resplendentnoxhelm", "blossomedwreath")}
    }
}

----------------
-- CUSTOM FNS --
----------------
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
table.insert(waveset_data[5].waves, _W.SetSpawn({_W.CreateSpawn(mob_spawns[5][4]), {2}})) -- Wave 4
waveset_data[5].wavemanager.dialogue[4] = {pre_delay = 3.5, speech = "BOARLORD_ROUND5_BOARRIOR_INTRO"}

local _oldOnSpawningFinished1 = waveset_data[5].wavemanager.onspawningfinished[1]
waveset_data[5].wavemanager.onspawningfinished[1] = function(self, spawnedmobs)
    _oldOnSpawningFinished1(self, spawnedmobs)
    -- Health Triggers
    self.health_triggers.boarillas[3] = {total_percent = 0.2, fn = function() self:QueueWave(4) end}
    local boarillas = _W.OrganizeAllMobs(spawnedmobs).boarilla
    _W.AddHealthTriggers(self.health_triggers.boarillas, unpack(boarillas))
end
local _oldOnSpawningFinished3 = waveset_data[5].wavemanager.onspawningfinished[3]
waveset_data[5].wavemanager.onspawningfinished[3] = function(self, spawnedmobs)
    _oldOnSpawningFinished3(self, spawnedmobs)
    -- Restart 5 min timer to queue next wave
    self.timers.queue_next_wave = self.inst:DoTaskInTime(300, function()
        NextWaveTimerFN(self, 4)
    end)
end
waveset_data[5].wavemanager.onspawningfinished[4] = function(self, spawnedmobs)
    -- Remove 5 min timer since no longer needed
    RemoveTask(self.timers.queue_next_wave)
end

waveset_data[5].wavemanager.onallmobsdied = function(self) -- All waves are health or timer based except for the last wave since that is the end of the round.
    return self.current_wave == 4
end

waveset_data.item_drop_options.random_item_spread_fn = ApplyRandomItemDropSpread

waveset_data.endgame_speech.victory.speech = "BOARLORD_ROUND7_PLAYER_VICTORY"

return waveset_data
