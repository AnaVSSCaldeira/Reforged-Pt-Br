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
    Wave 1 - Pitpig (2)
    Wave 2 - Pitpig (3)
    Wave 3 - Pitpig (5)
    Wave 4 - Pitpig (6)
Round 2:
    Wave 1 - Pitpig (3) + Crocommander (1)
    Wave 2 - Pitpig (3) + Crocommander (1)
Round 3:
    Wave 1 - Snortoise (4)
Round 4:
    Wave 1 - Scorpeon (4)
    Wave 2 - Snortoise (1) + Scorpeon (1)
    Wave 3 - Boarilla (1) [15 seconds after previous wave or death]
Round 5:
    Wave 1 - Boarilla (1)
    Wave 2 - Pitpig (1) + Crocommander (1) [when first Boarilla hits 40% health or when cumulative Boarilla health hits 120%]
    Wave 3 - Pitpig (1) + Crocommander (1) + Snortoise (1) + Scorpeon (1) [when first Boarilla dies or when cumulative Boarilla health hits 40%]
    Wave 4 - Boarrior (1) [when cumulative Boarilla health hits 20%]
        Special - Pitpig (6) [when Boarrior hits half health]
Round 6:
    Wave 1 - Rhinocebro (1)
Round 7:
    Wave 1 - Swineclops (1)

Round 1:
    Wave 1 - Pitpig (1)
    Wave 2 - Pitpig (2)
    Wave 3 - Pitpig (4)
    Wave 4 - Pitpig (8)
Round 2:
    Wave 1 - Pitpig (3) + Crocommander (1)
    Wave 2 - Pitpig (3) + Crocommander (1)
Round 3:
    Wave 1 - Snortoise (4)
Round 4:
    Wave 1 - Scorpeon (4)
    Wave 2 - Snortoise (1) + Scorpeon (1)
    Wave 3 - Boarilla (1) [15 seconds after previous wave or death]
Round 5:
    Wave 1 - Boarilla (2)
    Wave 2 - Pitpig (2) [when first Boarilla hits 40% health or when cumulative Boarilla health hits 120%]
    Wave 3 - Crocommander (1) + Snortoise (1) + Scorpeon (1) [when first Boarilla dies or when cumulative Boarilla health hits 40%]
    Wave 4 - Boarrior (1) [when cumulative Boarilla health hits 20%]
        Special - Pitpig (12) [when Boarrior hits half health]
Round 6:
    Wave 1 - Rhinocebro (2)
Round 7:
    Wave 1 - Swineclops (1)
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
		_W.CreateMobSpawnFromPreset("line", _W.CreateMobList(_W.RepeatMob("pitpig", 2)), {rotation = 90}), 		-- 2-all
		_W.CreateMobSpawnFromPreset("triangle", _W.CreateMobList(_W.RepeatMob("pitpig", 3))), 	-- 3-1,3;2 is rotated 180 degrees
		_W.CreateMobSpawnFromPreset("square", _W.CreateMobList(_W.RepeatMob("pitpig", 4))), 	-- 4-all
	}, [2] = {
		_W.CombineMobSpawns(_W.CreateMobSpawnFromPreset("triangle", _W.CreateMobList(_W.RepeatMob("pitpig", 3))), {{{"crocommander"},}}) -- 1&2-1,3
	}, [3] = {
		{{{"snortoise"},}}, 	-- 1-1,3
		_W.CreateMobSpawnFromPreset("line", _W.CreateMobList(_W.RepeatMob("snortoise", 2)), {rotation = 90}),-- 1-2
	}, [4] = {
		{{{"scorpeon"},}},
		_W.CreateMobSpawnFromPreset("line", _W.CreateMobList(_W.RepeatMob("scorpeon", 2)), {rotation = 90}), -- 1-2
		_W.CreateMobSpawnFromPreset("line", {"snortoise", "scorpeon"}), -- 2-1,3
		{{{"boarilla"},}}, -- 3-2
	}, [5] = {
		{{{"boarilla"},}}, -- 1-1,3
		 -- Forge has pitpigs spawn in slots 1 and 3 (1 in back and 1 in the front right), I changed it to 2 in front since that makes more sense. TODO should I change it to what forge had or keep it this way?
		_W.CreateMobSpawnFromPreset("line", _W.CreateMobList(_W.RepeatMob("pitpig", 2)), {rotation = 90}),
		_W.CreateMobSpawnFromPreset("line", {"snortoise", "scorpeon"}), -- 3-1,3
		{{{"boarrior"},}}, -- 4-2
		_W.CreateMobSpawnFromPreset("line", _W.CreateMobList(_W.RepeatMob("pitpig", 2))), -- 5-all
		{{{"crocommander"},}},
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
            --final_mob = {"livingstaff"}
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
        round_end = {"steadfastgrandarmor", "clairvoyantcrown", "blacksmithsedge"},
    },
    [5] = {
		round_end = {"jaggedgrandarmor", "silkengrandarmor"},
    },
}

local function AddGolemOrJagged(item_set, waves, item_count)
    if item_count == 1 then
        -- Round 4 Wave 1 or 2
        table.insert(item_set, "bacontome")
        table.insert(item_set, "jaggedgrandarmor")
        table.insert(waves, {4,1})
        table.insert(waves, {4,1}) -- 2 items drop on Round 4 Wave 1
        table.insert(waves, {4,2})
    end
end
local function ApplyRandomItemDropSpread(item_drops)
    -- RANDOM: Round 1 Wave 2-4 - 3 | Round 2 Wave 1-2 - 2
    _W.SpreadItemSetOverWaves(item_drops, {"barbedhelm", "crystaltiara", "jaggedarmor", "silkenarmor", "featheredwreath"}, {{1,2},{1,3},{1,4},{2,1},{2,2}}, "random_mob", 1)
    -- RANDOM: Round 2 Wave 1-2
    _W.SpreadItemSetOverWaves(item_drops, {"splintmail"}, {{2,1},{2,2}}, "random_mob", 1)
    -- RANDOM: Round 3 | Round 4 (1 item per round/wave)
    _W.SpreadItemSetOverWaves(item_drops, {"flowerheadband", "wovengarland"}, {{3,1}}, "random_mob", 1, AddGolemOrJagged)
    -- RANDOM: Round 5 Wave 2 and Round end
    _W.SpreadItemSetOverWaves(item_drops, {"resplendentnoxhelm", "blossomedwreath"}, {{5,2},{5}}, "final_mob", 1)
end

local character_tier_opts = {
    [1] = {round = 2},
    [2] = {round = 3},
    [3] = {round = 4, force_items = {"moltendarts"}},

}
local heal_opts = {
    dupe_rate = 0.2,
    drops = {
        heal = {round = 1, wave = 3, type = "final_mob", force_items = {"livingstaff"}}
    },
}
----------------
-- CUSTOM FNS --
----------------
local function Smallify(target, health, damage, size, speedmult)
    if target then
        if target.components.health and health then
            target.components.health:SetMaxHealth(target.components.health.maxhealth*health)
        end

        if target.components.combat and damage then
            target.components.combat:SetDefaultDamage(target.components.combat.defaultdamage*damage)
        end

        if size then
            target.Transform:SetScale(size, size, size)
        end

        if target.components.locomotor and speedmult then
            target.components.locomotor.runspeed = target.components.locomotor.runspeed * speedmult
            target.components.locomotor.walkspeed = target.components.locomotor.walkspeed * speedmult
        end
    end
end

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
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[1][1]), {2}}), -- Wave 1
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[1][1]), {1,3}}), -- Wave 2
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[1][2]), {1,3}}), -- Wave 3
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[1][4]), {1,3}}), -- Wave 4
        },
		wavemanager = {
			dialogue = {
				[1] = {speech = "BOARLORD_ROUND1_START"},
				[4] = {speech = "BOARLORD_ROUND1_FIGHT_BANTER", is_banter = true},
			},
		},
    },{ -- Round 2
        waves = {
            _W.SetSpawn({_W.CreateSpawn(mob_spawns[2][1], 180), {2}}), -- Wave 1
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[2][1], 180), {2}}), -- Wave 2
        },
		wavemanager = {
			dialogue = {
				[1] = {speech = "BOARLORD_ROUND2_START"},
				[2] = {speech = "BOARLORD_ROUND2_FIGHT_BANTER", is_banter = true},
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
				[1] = {speech = "BOARLORD_ROUND3_START"},
			},
		},
    },{ -- Round 4
        waves = {
            _W.SetSpawn({_W.CreateSpawn(mob_spawns[4][1]), {1,3}}, {_W.CreateSpawn(mob_spawns[4][2]), {2}}), -- Wave 1
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[4][1]), {1}}, {_W.CreateSpawn(mob_spawns[3][1]), {3}}), -- Wave 2
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[4][4]), {2}}), 	-- Wave 3
        },
        wavemanager = {
			dialogue = {
				[1] = {speech = "BOARLORD_ROUND4_START"},
				[2] = {speech = "BOARLORD_ROUND4_FIGHT_BANTER", is_banter = true},
				[3] = {pre_delay = 0, speech = "BOARLORD_ROUND4_TRAILS_INTRO"},
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
					local boarillas = _W.OrganizeAllMobs(spawnedmobs).boarilla[1]
					SetBoarillaVariance(boarillas, 3)
					Smallify(boarillas, 0.75, 0.75, 0.9, 1.2)
				end,
			},
        },
    },{ -- Round 5
        waves = {
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[5][1]), {1,3}}), 	-- Wave 1
            _W.SetSpawn({_W.CreateSpawn(mob_spawns[5][2]), {2}}), 		-- Wave 2
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[3][1]), {1}}, {_W.CreateSpawn(mob_spawns[5][6]), {2}},{_W.CreateSpawn(mob_spawns[4][1]), {3}} ), 	-- Wave 3
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[5][4]), {2}}), 		-- Wave 4
        },
        wavemanager = {
			dialogue = {
				[1] = {pre_delay = 3.5, speech = "BOARLORD_ROUND5_START"},
				[2] = {pre_delay = 0.5, speech = "BOARLORD_ROUND5_FIGHT_BANTER1", is_banter = true},
				[3] = {pre_delay = 0.5, speech = "BOARLORD_ROUND5_FIGHT_BANTER2", is_banter = true},
				[4] = {pre_delay = 3.5, speech = "BOARLORD_ROUND5_BOARRIOR_INTRO"},
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

					for i, v in ipairs(boarillas) do
						Smallify(v, 0.75, 0.75, 0.9, 1.2)
						SetBoarillaVariance(v, i)
					end
				end,
				[2] = function(self, spawnedmobs)
					-- Restart 5 min timer to queue next wave
					RemoveTask(self.timers.queue_next_wave)
					self.timers.queue_next_wave = self.inst:DoTaskInTime(300, function()
						NextWaveTimerFN(self, 3)
					end)
				end,
				[3] = function(self, spawnedmobs)
					-- Restart 5 min timer to queue next wave
					RemoveTask(self.timers.queue_next_wave)
					self.timers.queue_next_wave = self.inst:DoTaskInTime(300, function()
						NextWaveTimerFN(self, 4)
					end)
				end,
				[4] = function(self, spawnedmobs)
					-- Remove 5 min timer since no longer needed
					RemoveTask(self.timers.queue_next_wave)
					local boarriors = _W.OrganizeMobs(spawnedmobs[2]).boarrior

					Smallify(boarriors[1], 0.5, 0.75, 0.8, 1.2)

				end,
			},
			onallmobsdied = function(self) -- All waves are health or timer based except for the last wave since that is the end of the round.
				return self.current_wave == 4
			end,
        },
    },{ -- Round 6
        waves = {
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[6][1]), {1}}, {_W.CreateSpawn(mob_spawns[6][2]), {3}}), 	-- Wave 1
        },
        wavemanager = {
			dialogue = {
				[1] = {pre_delay = 3.5, speech = "BOARLORD_ROUND6_START"},
			},
            onspawningfinished = {
				[1] = function(self, spawnedmobs)
					local organized_mobs = _W.OrganizeAllMobs(spawnedmobs)
					local rhinocebro = organized_mobs.rhinocebro[1]
					local rhinocebro2 = organized_mobs.rhinocebro2[1]

					rhinocebro.bro = rhinocebro2
					rhinocebro2.bro = rhinocebro

					Smallify(rhinocebro, 0.5, 0.5, 0.9, 1.2)
					Smallify(rhinocebro2, 0.5, 0.5, 0.9, 1.2)
				end,
			},
        },
    },{ -- Round 7
        waves = {
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[7][1]), {2}}),
        },
        wavemanager = {
			dialogue = {
				[1] = {pre_delay = 3.5, speech = "BOARLORD_ROUND7_START"},
			},
			onspawningfinished = {
				[1] = function(self, spawnedmobs)
					local swineclops = _W.OrganizeAllMobs(spawnedmobs).swineclops[1]
					Smallify(swineclops, 0.5, 0.5, 0.85, 1.2)
				end,
			}
        },
    },
	item_drops = item_drops,
    item_drop_options = {
        character_tier_opts = character_tier_opts,
        heal_opts           = heal_opts,
        generate_item_drop_list_fn = _W.GenerateItemDropList,
        random_item_spread_fn      = ApplyRandomItemDropSpread,
    },
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
