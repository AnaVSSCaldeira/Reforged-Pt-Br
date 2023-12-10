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
		_W.CreateMobSpawnFromPreset("line", _W.CreateMobList(_W.RepeatMob("pitpig", 2))),
		_W.CreateMobSpawnFromPreset("square", _W.CreateMobList(_W.RepeatMob("pitpig", 4))),
		_W.CreateMobSpawnFromPreset("circle", _W.CreateMobList(_W.RepeatMob("pitpig", 6))),
		_W.CreateMobSpawnFromPreset("circle", _W.CreateMobList(_W.RepeatMob("pitpig", 8))),
	}, [2] = {
		_W.CombineMobSpawns(_W.CreateMobSpawnFromPreset("triangle", _W.CreateMobList(_W.RepeatMob("pitpig", 3))), {{{"crocommander"},}}), -- 1&2-1,3
		--_W.CombineMobSpawns(_W.CreateMobSpawnFromPreset("triangle", _W.CreateMobList(_W.RepeatMob("pitpig", 6))), {{{"crocommander"},{"crocommander"},}})
		_W.CreateMobSpawnFromPreset("circle", {"pitpig", "pitpig", "pitpig", "pitpig", "pitpig", "pitpig", "crocommander", "crocommander",}), -- 1-1,3
	}, [3] = {
		_W.CreateMobSpawnFromPreset("square", _W.CreateMobList(_W.RepeatMob("snortoise", 4))), 	-- 1-1,3
		_W.CreateMobSpawnFromPreset("circle", _W.CreateMobList(_W.RepeatMob("snortoise", 6))),
	}, [4] = {
		_W.CreateMobSpawnFromPreset("square", _W.CreateMobList(_W.RepeatMob("scorpeon", 4))),	-- 1-1,3
		_W.CreateMobSpawnFromPreset("circle", _W.CreateMobList(_W.RepeatMob("scorpeon", 6))),
		_W.CreateMobSpawnFromPreset("square", {"snortoise", "snortoise", "scorpeon", "scorpeon"}), -- 2-1,3
		{{{"boarilla"},}}, -- 3-2
	}, [5] = {
		{{{"boarilla"},}}, -- 1-1,3
		 -- Forge has pitpigs spawn in slots 1 and 3 (1 in back and 1 in the front right), I changed it to 2 in front since that makes more sense. TODO should I change it to what forge had or keep it this way?
		{{{"crocommander"},{"pitpig", 1, 1},{"pitpig", 1, 2}},{{2, 3},}}, -- 2&3-2 is rotated 180 degrees
		_W.CreateMobSpawnFromPreset("circle", {"snortoise", "snortoise", "scorpeon", "scorpeon", "snortoise", "snortoise", "scorpeon", "scorpeon"}), -- 3-1,3
		{{{"boarrior"},}}, -- 4-2
		_W.CreateMobSpawnFromPreset("square", _W.CreateMobList(_W.RepeatMob("pitpig", 4))), -- 5-all
		_W.CreateMobSpawnFromPreset("line", _W.CreateMobList(_W.RepeatMob("boarilla", 2))),
	}, [6] = {
		_W.CreateMobSpawnFromPreset("line", {"rhinocebro", "rhinocebro2"}), -- 1-1,3
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
            final_mob = {"firebomb", "firebomb"}
        },
        [2] = {
            final_mob = {"moltendarts", "whisperinggrandarmor", "moltendarts", "whisperinggrandarmor"}
        },
    },
    [3] = {
        [1] = {
            random_mob = {"noxhelm", "silkengrandarmor", "noxhelm", "silkengrandarmor"},
            final_mob = {"steadfastarmor", "infernalstaff", "steadfastarmor", "infernalstaff"},
        },
    },
    [4] = {
        round_end = {"steadfastgrandarmor", "clairvoyantcrown", "blacksmithsedge", "steadfastgrandarmor", "clairvoyantcrown", "blacksmithsedge"},
    },
    [5] = {
		[2] = {
			final_mob = {"resplendentnoxhelm", "blossomedwreath"},
		},
		[4] = {
			final_mob = {"jaggedgrandarmor", "silkengrandarmor", "resplendentnoxhelm", "blossomedwreath"}, --TODO: roundend drops doesn't seem to work if it ends with the 2nd wave of pitpigs, so setting it to drop after the last boarrior dies.
		},
    },
}
-- RANDOM: Round 1 Wave 2-4 - 3 | Round 2 Wave 1-2 - 2
_W.SpreadItemSetOverWaves(item_drops, {"barbedhelm", "crystaltiara", "jaggedarmor", "silkenarmor", "featheredwreath"}, {{1,2},{1,3},{1,4},{2,1},{2,2}}, "random_mob", 1)
_W.SpreadItemSetOverWaves(item_drops, {"barbedhelm", "crystaltiara", "jaggedarmor", "silkenarmor", "featheredwreath"}, {{1,2},{1,3},{1,4},{2,1},{2,2}}, "random_mob", 1)
-- RANDOM: Round 2 Wave 1-2
_W.SpreadItemSetOverWaves(item_drops, {"splintmail"}, {{2,1},{2,2}}, "random_mob", 1)
_W.SpreadItemSetOverWaves(item_drops, {"splintmail"}, {{2,1},{2,2}}, "random_mob", 1)
-- RANDOM: Round 3 | Round 4 (1 item per round/wave)
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
_W.SpreadItemSetOverWaves(item_drops, {"flowerheadband", "wovengarland"}, {{3,1}}, "random_mob", 1, AddGolemOrJagged)
_W.SpreadItemSetOverWaves(item_drops, {"flowerheadband", "wovengarland"}, {{3,1}}, "random_mob", 1, AddGolemOrJagged)

local tier_opts = {
    [1] = {round = 2},
    [2] = {round = 3},
    [3] = {round = 4, force_items = {"moltendarts"}},
}

local heal_opts = {
	heal = {round = 1, wave = 3, type = "final_mob", force_items = {"livingstaff"}},
}
_W.AddCharacterItemDropsToItemSet(item_drops, tier_opts)
_W.AddCharacterItemDropsToItemSet(item_drops, tier_opts)

_W.AddCharacterItemDropsToItemSet(item_drops, heal_opts)

----------------
-- CUSTOM FNS --
----------------
-- Leashes all pitpigs to the first croc on each spawner
local function LeashPitpigsToCrocs(spawnedmobs)
	for i,mob_list in pairs(spawnedmobs) do
		local mobs = _W.OrganizeMobs(mob_list)
        if mobs and mobs.pitpig and mobs.crocommander then
            local croc_count = #mobs.crocommander or 0
            local croc_pig_link = {}
            local count = 0
            -- Organize Pitpigs into tables that will be linked to each Crocommander.
            for index,pitpig in pairs(mobs.pitpig) do
                local croc_index = index % croc_count + 1
                if not croc_pig_link[croc_index] then croc_pig_link[croc_index] = {} end
                table.insert(croc_pig_link[croc_index], pitpig)
            end
            -- Leash the organized Pitpigs to their Crocommander.
            for index,pitpigs in pairs(croc_pig_link) do
                _W.LeashMobs(mobs.crocommander[index], pitpigs)
            end
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
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[1][1]), {1,2,3}}), -- Wave 1
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[1][2]), {1,2,3}}), -- Wave 2
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[1][3]), {1,2,3}}), -- Wave 3
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[1][4]), {1,2,3}}), -- Wave 4
        },
		wavemanager = {
			dialogue = {
				[1] = {speech = STRINGS.BOARLORD_ROUND1_START},
				[4] = {speech = STRINGS.BOARLORD_ROUND1_FIGHT_BANTER, is_banter = true},
			},
		},
    },{ -- Round 2
        waves = {
            _W.SetSpawn({_W.CreateSpawn(mob_spawns[2][1]), {1,3}}, {_W.CreateSpawn(mob_spawns[2][2], 180), {2}} ), -- Wave 1
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[2][1]), {1,3}},{_W.CreateSpawn(mob_spawns[2][2], 180), {2}} ), -- Wave 2
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
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[4][4]), {1}}, {_W.CreateSpawn(mob_spawns[4][4]), {3}}), 	-- Wave 3
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
					local organized_mobs = _W.OrganizeAllMobs(spawnedmobs)
					local boarilla = organized_mobs.boarilla[1]
					local boarilla2 = organized_mobs.boarilla[2]
					SetBoarillaVariance(boarilla)
					SetBoarillaVariance(boarilla2, nil, 2)
				end,
			},
        },
    },{ -- Round 5
        waves = {
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[5][1]), {1,3}}, {_W.CreateSpawn(mob_spawns[5][6], 90), {2}}), 	-- Wave 1
            _W.SetSpawn({_W.CreateSpawn(mob_spawns[5][2]), {1,3}}), 		-- Wave 2
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[5][3]), {2}}, {_W.CreateSpawn(mob_spawns[5][2], 180), {1,3}}), 	-- Wave 3
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[5][4]), {1,3}}), 		-- Wave 4
        },
        wavemanager = {
			dialogue = {
				[1] = {pre_delay = 3.5, speech = STRINGS.BOARLORD_ROUND5_START},
				[2] = {pre_delay = 0.5, speech = STRINGS.BOARLORD_ROUND5_FIGHT_BANTER1, is_banter = true},
				[3] = {pre_delay = 0.5, speech = STRINGS.BOARLORD_ROUND5_FIGHT_BANTER2, is_banter = true},
				[4] = {pre_delay = 3.5, speech = STRINGS.BOARLORD_ROUND5_BOARRIOR_INTRO},
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

					local boarilla_pairs = {_W.OrganizeAllMobs(spawnedmobs).boarilla[1], _W.OrganizeAllMobs(spawnedmobs).boarilla[4]}
					local boarilla_pairs2 = {_W.OrganizeAllMobs(spawnedmobs).boarilla[2], _W.OrganizeAllMobs(spawnedmobs).boarilla[3]}

					for i, v in pairs(boarilla_pairs) do
						SetBoarillaVariance(v, i)
					end
					for i, v in pairs(boarilla_pairs2) do
						SetBoarillaVariance(v, i, 2)
					end
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
					local boarriors = _W.OrganizeAllMobs(spawnedmobs).boarrior

					RemoveTask(self.timers.queue_next_wave)

					boarriors[2].AnimState:SetBuild("lavaarena_boarrior_alt1")
				end,
			},
			onallmobsdied = function(self) -- All waves are health or timer based except for the last wave since that is the end of the round.
				return self.current_wave >= 4
			end,
        },
    },{ -- Round 6
        waves = {
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[6][1], 90), {1}}, {_W.CreateSpawn(mob_spawns[6][1], 90), {3}}), 	-- Wave 1
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
					local rhinocebro3 = organized_mobs.rhinocebro[2]
					local rhinocebro4 = organized_mobs.rhinocebro2[2]


					rhinocebro.bro = rhinocebro2
					rhinocebro2.bro = rhinocebro

					rhinocebro3.bro = rhinocebro4
					rhinocebro4.bro = rhinocebro3

					local rhinocebros_alt = {rhinocebro3, rhinocebro4}
					for i, v in pairs(rhinocebros_alt) do
						v.AnimState:SetBuild("lavaarena_rhinodrill_alt1")
						v.damagedtype = "_alt1"
						if i == 2 then
							v.AnimState:AddOverrideBuild("lavaarena_rhinodrill_clothed_alt1")
						end
					end
				end,
			},
        },
    },{ -- Round 7
        waves = {
			_W.SetSpawn({_W.CreateSpawn(mob_spawns[7][1]), {1,3}}),
        },
        wavemanager = {
			dialogue = {
				[1] = {pre_delay = 3.5, speech = STRINGS.BOARLORD_ROUND7_START},
			},
			onspawningfinished = {
				[1] = function(self, spawnedmobs)
					local swineclops = _W.OrganizeAllMobs(spawnedmobs).swineclops
					swineclops[2].AnimState:SetBuild("lavaarena_beetletaur_alt1")
				end,
			},
        },

    },
	item_drops = item_drops,
	endgame_speech = {
		victory = STRINGS.BOARLORD_ROUND7_PLAYER_VICTORY,
		defeat = STRINGS.BOARLORD_PLAYERS_DEFEATED_BATTLECRY,
	}
}

return waveset_data
