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
require "behaviours/meleerangeswap"

require "behaviours/chaseandattack"
require "behaviours/chaseandattack_forge"
require "behaviours/faceentity"
require "behaviours/follow"
require "behaviours/wander"

local tuning_values = TUNING.FORGE.CROCOMMANDER

local CrocommanderBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)
local MOB_MAX_CHASE_TIME = 8
local MAX_WANDER_DISTANCE = 5
local DEFAULT_MOB_PERIOD = 0.25
local function GetWanderPoint(inst)
    return TheWorld.components.lavaarenaevent and TheWorld.components.lavaarenaevent:GetArenaCenterPoint() or nil
end
function CrocommanderBrain:OnStart()
	local nodes = {
        MeleeRangeSwap(self.inst, tuning_values.SWAP_ATTACK_MODE_RANGE, self.inst.weapon, tuning_values.SPIT_ATTACK_RANGE, tuning_values.SPIT_HIT_RANGE, tuning_values.ATTACK_RANGE, tuning_values.HIT_RANGE, tuning_values.ATTACK_PERIOD)
    }
    self.bt = BT(self.inst, common_brain.CreateMobBehaviorRoot(self.inst, nil, nil, nodes))
end

return CrocommanderBrain
