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
require "behaviours/faceentity" -- TODO does bernie need to use this? baby spiders use it
require "behaviours/follow"

local BernieBrain = Class(Brain, function(self, inst)
    Brain._ctor(self,inst)
    self._targets = nil
    self._leader = nil
end)

local MIN_FOLLOW_DIST = 0
local MAX_FOLLOW_DIST = 5
local TARGET_FOLLOW_DIST = 3

local function GetLeader(self) -- TODO common fn?
	local leader = self.inst.components.follower.leader or nil
	return (leader and not leader.components.health:IsDead()) and leader or nil
end

function BernieBrain:OnStart()
    local root = PriorityNode({
		IfNode(function() return self.inst.sg:HasStateTag("inactive") and GetLeader(self) end, "No Leader", ActionNode(function() self.inst.sg:GoToState("activate") end)),
        IfNode(function() return not self.inst.sg:HasStateTag("busy") and not GetLeader(self) end, "No Leader", ActionNode(function() self.inst.sg:GoToState("deactivate") end)),
        Follow(self.inst, function() return GetLeader(self) end, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST), -- TODO need custom follow behaviour. The default behaviour does not stop the entity from moving to point even if within target_follow_dist. Once it's inside the target_follow_dist the location the entity is walking to no longer updates. This means you could run to the opposite side of the entity and the entity will go to where you were not where you are.
    }, 0.5)
    self.bt = BT(self.inst, root)
end

return BernieBrain