VictoryPose_Forge = Class(BehaviourNode, function(self, inst)
    BehaviourNode._ctor(self, "VictoryPose_Forge")
    self.inst = inst
end)

function VictoryPose_Forge:__tostring()
    return string.format("target %s", tostring(self.inst.components.combat.target))
end

function VictoryPose_Forge:OnStop()
    
end

function VictoryPose_Forge:Visit()
    if self.status == READY then
        if TheWorld.components.lavaarenaevent.victory ~= nil and TheWorld.components.lavaarenaevent.victory == false then
            self.status = RUNNING
        else
            self.status = FAILED
        end
    end

    if self.status == RUNNING then
		if TheWorld.components.lavaarenaevent.victory then
			self.status = FAILED
			self.inst.components.locomotor:Stop()
		elseif TheWorld.components.lavaarenaevent.victory == false and not (self.inst.sg:HasStateTag("attack") or self.inst.sg:HasStateTag("frozen") or self.inst.sg:HasStateTag("sleeping") or self.inst.sg:HasStateTag("busy")) then
			self.status = SUCCESS
			self.inst:PushEvent("victorypose")
		else
			self:Sleep(.125)
		end			
    end
end
