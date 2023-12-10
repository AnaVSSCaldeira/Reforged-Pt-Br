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
Round 6:
    Wave 1 - Rhinocebro (2)
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
local waveset_data = deepcopy(require("wavesets/classic"))

----------------
-- MOB SPAWNS --
----------------
local mob_spawns = {
	[6] = {
		{{{"rhinocebro"},}}, -- 1-1,3
		{{{"rhinocebro2"},}},
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
--[[
TODO remove this when confirmed
1:
pet    - 2-2 Final mob, croc (7:37)
silk   - 3-1 second snortoise (8:50)
garland - 3-1 ???
golem  - 4-1 first scorp? (13:01)
flower - 4-1 Final mob (14:19)
jagged - 4-2 second to last snortoise, scorps were dead (16:09)
2:
flower - 3-1 first snortoise (33:25)
golem  - 4-1 second scorp (36:38)
jagged - 4-1 second to last scorp (38:48)
garland - 4-2 second mob, scorp (last scorp) (39:45)
3:
flower - 3-1 third snortoise (1:06:05)
garland - 4-1 second scorp??? (1:08:48)
golem  - 4-1 Final mob, scorp (1:10:13)
jagged - 4-2 ???? (1:10:45) offscreen sometime
--]]
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

waveset_data.item_drops[2][1] = {final_mob = {"firebomb"}}
waveset_data.item_drops[3][1].random_mob = {"noxhelm", "silkenarmor"}
waveset_data.item_drops[4].round_end = {"steadfastgrandarmor", "clairvoyantcrown"}
waveset_data.item_drops[5] = {round_end = {"jaggedgrandarmor", "silkenarmor"}}

------------------
-- WAVESET DATA --
------------------
-- Round 6
waveset_data[6] = {
    waves = {
        _W.SetSpawn({_W.CreateSpawn(mob_spawns[6][1]), {1}}, {_W.CreateSpawn(mob_spawns[6][2]), {3}}),  -- Wave 1
    },
    wavemanager = {
        dialogue = {
            [1] = {pre_delay = 3.5, speech = "BOARLORD_ROUND6_START"},
        },
        onspawningfinished = {
            [1] = function(self, spawnedmobs)
                local organized_mobs = _W.OrganizeAllMobs(spawnedmobs)
                -- Link Rhinocebros
                for i,rhinocebro in pairs(organized_mobs.rhinocebro) do
                    local rhinocebro2 = organized_mobs.rhinocebro2[i]
                    if rhinocebro2 then
                        rhinocebro.bro = rhinocebro2
                        rhinocebro2.bro = rhinocebro
                    end
                end
            end,
        },
    },
}

waveset_data.item_drop_options.random_item_spread_fn = ApplyRandomItemDropSpread

waveset_data.endgame_speech.victory.speech = "BOARLORD_ROUND6_PLAYER_VICTORY"

return waveset_data
