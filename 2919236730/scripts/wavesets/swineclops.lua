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
local waveset_data = deepcopy(require("wavesets/rhinocebros"))

----------------
-- MOB SPAWNS --
----------------
local mob_spawns = {
	[7] = {
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
waveset_data.item_drops[2][2].final_mob = {"moltendarts", "whisperinggrandarmor"}
waveset_data.item_drops[3][1].random_mob = {"noxhelm", "silkengrandarmor"}
table.insert(waveset_data.item_drops[4].round_end, "blacksmithsedge")
waveset_data.item_drops[5].round_end = {"jaggedgrandarmor", "silkengrandarmor"}

------------------
-- WAVESET DATA --
------------------
-- Round 7
waveset_data[7] =  {
    waves = {
        _W.SetSpawn({_W.CreateSpawn(mob_spawns[7][1]), {2}}),
    },
    wavemanager = {
        dialogue = {
            [1] = {pre_delay = 3.5, speech = "BOARLORD_ROUND7_START"},
        },
    },
}

waveset_data.endgame_speech.victory.speech = "BOARLORD_ROUND7_PLAYER_VICTORY"

return waveset_data
