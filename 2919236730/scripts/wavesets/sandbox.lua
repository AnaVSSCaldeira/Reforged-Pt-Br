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
Mob Spawn Order
    Round 1: pitpigX3 -> pitpigX6 -> pitpigX9 -> pitpigX12
    Round 2: pitpigX6 + crocommanderX2 -> pitpigX6 + crocommander X2
    Round 3: snortoiseX7 -> scorpeonX7
    Round 4: snortoiseX2 + scorpeonX2 -> boarillaX1 (15 seconds after previous wave or death)
    Round 5: boarillaX2 -> crocommanderX1 + pitpigX2 (when first boarilla hits 40% health or when cumalitive boarilla health hits 120%) -> crocommanderX1 + pitpigX2 + scorpeonX2 + snortoiseX2 (when first boarilla dies or when cumalitive boarilla health hits 40%) -> boarriorX1 (when cumalitive boarilla health hits 20%) -> pigX10 (when boarior hits half health)
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

----------------
-- MOB SPAWNS --
----------------
local mob_spawns = {
	[1] = {
		{{{"pitpig"},}}, 																		-- 1-all
		_W.CreateMobSpawnFromPreset("line", _W.CreateMobList(_W.RepeatMob("pitpig", 2))), 		-- 2-all
		_W.CreateMobSpawnFromPreset("triangle", _W.CreateMobList(_W.RepeatMob("pitpig", 3))), 	-- 3-1,3;2 is rotated 180 degrees
		_W.CreateMobSpawnFromPreset("square", _W.CreateMobList(_W.RepeatMob("pitpig", 4))), 	-- 4-all
	}, [2] = {
		-- TODO I think this should be a triangle spawn with a center mob, needs confirmation
		--_W.CreateMobSpawnFromPreset("flag", _W.CreateMobList("crocommander", _W.RepeatMob("pitpig", 3))),
		_W.CombineMobSpawns(_W.CreateMobSpawnFromPreset("triangle", _W.CreateMobList(_W.RepeatMob("pitpig", 3))), {{{"crocommander"},}}) -- 1&2-1,3
	}, [3] = {
		_W.CreateMobSpawnFromPreset("line", _W.CreateMobList(_W.RepeatMob("snortoise", 2))), 	-- 1-1,3
		_W.CreateMobSpawnFromPreset("triangle", _W.CreateMobList(_W.RepeatMob("snortoise", 3)), {rotation = 180}),-- 1-2
	}, [4] = {
		_W.CreateMobSpawnFromPreset("line", _W.CreateMobList(_W.RepeatMob("scorpeon", 2))),	-- 1-1,3
		_W.CreateMobSpawnFromPreset("triangle", _W.CreateMobList(_W.RepeatMob("scorpeon", 3)), {rotation = 180}), -- 1-2
		_W.CreateMobSpawnFromPreset("line", {"snortoise", "scorpeon"}), -- 2-1,3
		{{{"boarilla"},}}, -- 3-2
	}, [5] = {
		{{{"boarilla"},}}, -- 1-1,3
		 -- Forge has pitpigs spawn in slots 1 and 3 (1 in back and 1 in the front right), I changed it to 2 in front since that makes more sense. TODO should I change it to what forge had or keep it this way?
		{{{"crocommander"},{"pitpig", 1, 1},{"pitpig", 1, 2}},{{2, 3},}}, -- 2&3-2 is rotated 180 degrees
		_W.CreateMobSpawnFromPreset("line", {"snortoise", "scorpeon"}), -- 3-1,3
		{{{"boarrior"},}}, -- 4-2
		_W.CreateMobSpawnFromPreset("square", _W.CreateMobList(_W.RepeatMob("pitpig", 4))), -- 5-all
	}, [6] = {
		{{{"rhinocebro"},}}, -- 1-1,3
		{{{"rhinocebro2"},}},
	}, [7] = {
		{{{"swineclops"},}},
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
local item_drops = {
	[1] = {
        [3] = {
            final_mob = {"livingstaff"}
        },
    },
    [2] = {
		[1] = {
            final_mob = {"firebomb"}
        },
        [2] = {
            final_mob = {"moltendarts", "whisperinggrandarmor"}
        },
    },
    [3] = {
        [1] = {
            random_mob = {"noxhelm", "silkengrandarmor"},
            final_mob = {"steadfastarmor", "infernalstaff"},
        },
    },
    [4] = {
        round_end = {"steadfastgrandarmor", "clairvoyantcrown", HasCharacter("wathgrithr") and "spiralspear" or "moltendarts", "blacksmithsedge"},
    },
    [5] = {
		round_end = {"jaggedgrandarmor", "silkengrandarmor"},
    },
}
-- RANDOM: Round 1 Wave 2-4 - 3 | Round 2 Wave 1-2 - 2
_W.SpreadItemSetOverWaves(item_drops, {"barbedhelm", "crystaltiara", "jaggedarmor", "silkenarmor", "featheredwreath"}, {{1,2},{1,3},{1,4},{2,1},{2,2}}, "random_mob", 1)
-- RANDOM: Round 2 Wave 1-2
_W.SpreadItemSetOverWaves(item_drops, {"splintmail"}, {{2,1},{2,2}}, "random_mob", 1)
-- RANDOM: Round 3 | Round 4 (1 item per round/wave)
local function AddGolem(item_set, waves)
    if #item_set == 1 then
        -- Round 4 Wave 1 or 2
        table.insert(item_set, "bacontome")
		table.insert(item_set, "jaggedgrandarmor")
        table.insert(waves, {4,2})
    end
end
_W.SpreadItemSetOverWaves(item_drops, {"flowerheadband", "wovengarland"}, {{3,1},{4,1}}, "random_mob", 1, AddGolem)
_W.SpreadItemSetOverWaves(item_drops, {"resplendentnoxhelm", "blossomedwreath"}, {{5,2},{5}}, "final_mob", 1)

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

local function SetBoarillaVariance(boarilla, variation, build)
    boarilla:SetVariation(variation, build)
end

local function SetBoarillasVariance(boarillas, total_variations)
    local total_variations = total_variations or 3 -- TODO grab from boarilla somehow
    for i,boarilla in pairs(boarillas) do
        SetBoarillaVariance(boarilla, i%total_variations + 1)
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
local waveset_data = {
    { -- Round 1
        waves = {
        },
		wavemanager = {
			dialogue = {
				[1] = {speech = STRINGS.BOARLORD_ROUND99_START},
				[4] = {speech = STRINGS.BOARLORD_ROUND1_FIGHT_BANTER, is_banter = true},
			},
			onspawningfinished = {
			},
			onallmobsdied = function(self) --makes it not progress
				return self.current_wave == 5
			end
		},
    },{ -- Round 2
        waves = {
            _W.SetSpawn({_W.CreateSpawn(mob_spawns[2][1]), {1,3}}), -- Wave 1
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[2][1]), {1,3}}), -- Wave 2
        },
		wavemanager = {
			dialogue = {
				[1] = {speech = STRINGS.BOARLORD_ROUND2_START},
				[2] = {speech = STRINGS.BOARLORD_ROUND2_FIGHT_BANTER, is_banter = true},
			},
			onspawningfinished = {
				[1] = function(self, spawnedmobs)
					LeashPitpigsToCrocs(spawnedmobs)
				end,
				[2] = function(self, spawnedmobs)
					LeashPitpigsToCrocs(spawnedmobs)
				end,
			},

		},
    },{ -- Round 3
        waves = {
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[3][1]), {1,3}}, {_W.CreateSpawn(mob_spawns[3][2]), {2}}), -- Wave 1
        },
		wavemanager = {
			dialogue = {
				[1] = {speech = STRINGS.BOARLORD_ROUND3_START},
			},
		},
    },{ -- Round 4
        waves = {
            _W.SetSpawn({_W.CreateSpawn(mob_spawns[4][1]), {1,3}}, {_W.CreateSpawn(mob_spawns[4][2]), {2}}), -- Wave 1
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[4][3]), {1,3}}), -- Wave 2
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[4][4]), {2}}), 	-- Wave 3
        },
        wavemanager = {
			dialogue = {
				[1] = {speech = STRINGS.BOARLORD_ROUND4_START},
				[2] = {speech = STRINGS.BOARLORD_ROUND4_FIGHT_BANTER, is_banter = true},
				[3] = {pre_delay = 0, speech = STRINGS.BOARLORD_ROUND4_TRAILS_INTRO},
			},
            onspawningfinished = {
				[2] = function(self, spawnedmobs)
					-- Spawn wave 3 15 seconds after wave 2
					self.timers.queue_next_wave = self.inst:DoTaskInTime(15, function()
						self:QueueWave(3)
					end)
				end,
				[3] = function(self, spawnedmobs)
					-- Remove timer if wave was triggered before timer completed
					RemoveTask(self.timers.queue_next_wave)

					-- Give each boarilla a unique look
					local boarillas = _W.OrganizeAllMobs(spawnedmobs).boarilla
					SetBoarillaVariance(boarillas)
				end,
			},
        },
    },{ -- Round 5
        waves = {
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[5][1]), {1,3}}), 	-- Wave 1
            _W.SetSpawn({_W.CreateSpawn(mob_spawns[5][2], 180), {2}}), 		-- Wave 2
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[5][3]), {1,3}}, {_W.CreateSpawn(mob_spawns[5][2], 180), {2}}), 	-- Wave 3
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[5][4]), {2}}), 		-- Wave 4
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[5][5]), {1,2,3}}), 	-- Wave 5
        },
        wavemanager = {
			dialogue = {
				[1] = {pre_delay = 3.5, speech = STRINGS.BOARLORD_ROUND5_START},
				[2] = {pre_delay = 0.5, speech = STRINGS.BOARLORD_ROUND5_FIGHT_BANTER1, is_banter = true},
				[3] = {pre_delay = 0.5, speech = STRINGS.BOARLORD_ROUND5_FIGHT_BANTER2, is_banter = true},
				[4] = {pre_delay = 3.5, speech = STRINGS.BOARLORD_ROUND5_BOARRIOR_INTRO},
				[5] = {pre_delay = 0.5}, -- TODO there is no speech assigned to 5...so why is there delay...
			},
            onspawningfinished = {
				[1] = function(self, spawnedmobs)
					-- Start 5 min timer to queue next wave
					self.timers.queue_next_wave = self.inst:DoTaskInTime(300, function()
						NextWaveTimerFN(self, 2)
					end)

					-- Health Triggers
					self.health_triggers.boarillas = {
						[1] = {total_percent = 1.2, single_percent = 0.4, fn = function() self:QueueWave(2) end},
						[2] = {single_percent = 0, all_percent = 0.4, fn = function() self:QueueWave(3) end},
						[3] = {total_percent = 0.2, fn = function() self:QueueWave(4) end},
					}
					local boarillas = _W.OrganizeAllMobs(spawnedmobs).boarilla
					_W.AddHealthTriggers(self.health_triggers.boarillas, unpack(boarillas))

					-- Give each boarilla a unique look
					SetBoarillaVariance(boarillas)
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
					self.timers.queue_next_wave = self.inst:DoTaskInTime(300, function()
						NextWaveTimerFN(self, 4)
					end)
					LeashPitpigsToCrocs(spawnedmobs) -- TODO this only occurs on one spawner, do I specify or still loop?
				end,
				[4] = function(self, spawnedmobs)
					-- Remove 5 min timer since no longer needed
					RemoveTask(self.timers.queue_next_wave)
					self.health_triggers.boarrior = {
						[1] = {total_percent = 0.5, fn = function() self:QueueWave(5) end},
					}
					_W.AddHealthTriggers(self.health_triggers.boarrior, unpack(_W.OrganizeMobs(spawnedmobs[2]).boarrior))
				end,
			},
			onallmobsdied = function(self) -- All waves are health or timer based except for the last wave since that is the end of the round.
				return self.current_wave == 5
			end,
        },
    },{ -- Round 6
        waves = {
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[6][1]), {1}}, {_W.CreateSpawn(mob_spawns[6][2]), {3}}), 	-- Wave 1
        },
        wavemanager = {
			dialogue = {
				[1] = {pre_delay = 3.5, speech = STRINGS.BOARLORD_ROUND6_START},
			},
            onspawningfinished = {
				[1] = function(self, spawnedmobs)
					local organized_mobs = _W.OrganizeAllMobs(spawnedmobs)
					local rhinocebro = organized_mobs.rhinocebro[1]
					local rhinocebro2 = organized_mobs.rhinocebro2[1]

					rhinocebro.bro = rhinocebro2
					rhinocebro2.bro = rhinocebro
				end,
			},
            onallmobsdied = function(self) --makes it not progress
                return self.current_wave == 5
            end,
        },
    },{ -- Round 7
        waves = {
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[7][1]), {2}}),
        },
        wavemanager = {
			dialogue = {
				[1] = {pre_delay = 3.5, speech = STRINGS.BOARLORD_ROUND7_START},
			},
        },
    },
	item_drops = item_drops,
	endgame_speech = {
		victory = {
			speech = "BOARLORD_ROUND7_PLAYER_VICTORY",
		},
		defeat = {
			speech = "BOARLORD_PLAYERS_DEFEATED_BATTLECRY",
		},
	}
}

return waveset_data
