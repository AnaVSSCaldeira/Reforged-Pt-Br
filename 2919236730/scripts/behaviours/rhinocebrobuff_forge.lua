RhinocebroBuff_Forge = Class(BehaviourNode, function(self, inst, distance, isvictory)
    BehaviourNode._ctor(self, "RhinocebroBuff_Forge")
    self.inst = inst
    self.distance = distance or 6
	self.isvictory = isvictory or nil
end)

function RhinocebroBuff_Forge:__tostring()
    return string.format("target %s", tostring(self.inst.components.combat.target))
end

function RhinocebroBuff_Forge:OnStop()

end

function RhinocebroBuff_Forge:Visit()
    local combat = self.inst.components.combat
    if self.status == READY then
        if self.inst.bro ~= nil then
            self.status = RUNNING
        else
            self.status = FAILED
        end
    end

-- TODO movement ideas
-- Create a behavior for the movement alone?
-- Maybe give the behavior a completion function parameter that runs when the mob is successfully within the given parameters?
-- turn rhino around and tell him to move forward?
-- then when greater than min range stop?
    -- what if far away? is there a max range?
--self.inst.components.locomotor:GoToPoint(hp, nil, self.running)

    if self.status == RUNNING then
        if self.inst.bro == nil or self.inst.bro.components.health:IsDead() then
            self.status = FAILED
            self.inst.components.locomotor:Stop()
        elseif self.inst.bro and self.inst:IsNear(self.inst.bro, self.distance) and not (self.inst.sg:HasStateTag("attack") or self.inst.sg:HasStateTag("frozen") or self.inst.sg:HasStateTag("sleeping")) then
            -- Victory Pose
            if self.isvictory then
                self.status = SUCCESS
                self.inst:PushEvent("victorypose")
            -- Cheer
            elseif self.inst.components.combat:IsAttackReady("cheer") then
                self.status = SUCCESS
                self.inst:PushEvent("startcheer")
            else
                self:Sleep(.125)
            end
        end
    end
end
