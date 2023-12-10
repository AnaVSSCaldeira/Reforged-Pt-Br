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
local common_brain = require("brains/common_brain_functions")
require "behaviours/leashandavoid"

local BabySpiderBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

-- TODO this was used as a test function to try to recreate the triangle formation of spiders.
-- Use deergemmedbrain as an example (klaus updates offsets that are used to define their homelocation)
-- Most like used Leash to create the triangle?
-- LeashAndAvoid doesn't quite do what we want.
local function GetOtherBabySpiders(inst)
	local leaders_pets = inst.components.follower.leader.components.leader.followers
	local baby_spiders = {}
	local my_index = 1
	local count = 0
	for follower,_ in pairs(leaders_pets) do
		if follower.prefab == "babyspider" then
			table.insert(baby_spiders, follower)
			count = count + 1
			if follower == inst then
				my_index = count
			end
		end
	end
	return baby_spiders[my_index + 1 > #baby_spiders and 1 or my_index + 1]
end

local function GetLeadersPos(inst)
	return inst.components.follower.leader:GetPosition()
end

function BabySpiderBrain:OnStart()
	local nodes = {
		--LeashAndAvoid(self.inst, GetOtherBabySpiders, 1, GetLeadersPos, 3, 1, true)
    }
	self.bt = BT(self.inst, common_brain.CreatePetBehaviorRoot(self.inst, nil, nodes, 1))
end

return BabySpiderBrain