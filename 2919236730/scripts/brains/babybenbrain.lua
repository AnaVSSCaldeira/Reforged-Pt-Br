require "behaviours/follow"
require "behaviours/wander"

local BabyBenBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local MIN_FOLLOW = 4
local MAX_FOLLOW = 11
local MED_FOLLOW = 6

function BabyBenBrain:OnStart()
    local root = PriorityNode({
        Follow(self.inst, function() return self.inst.components.follower.leader end, MIN_FOLLOW, MED_FOLLOW, MAX_FOLLOW, true),
        Wander(self.inst),
    }, .5)

    self.bt = BT(self.inst, root)
end

return BabyBenBrain
