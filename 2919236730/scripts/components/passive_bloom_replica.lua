local PassiveBloom = Class(function(self, inst)
    self.inst = inst
    self._currentstage = net_smallbyte(inst.GUID, "passive_bloom._currentstage")
    self._pollenduration = net_smallbyte(inst.GUID, "passive_bloom._pollenduration") -- TODO should this be larger?
end)

function PassiveBloom:GetCurrentStage()
    return self._currentstage:value()
end

function PassiveBloom:SetCurrentStage(val)
    self._currentstage:set(val)
end

function PassiveBloom:GetPollenDebuffDuration()
    return self._currentstage:value()
end

function PassiveBloom:SetPollenDebuffDuration(val)
    self._pollenduration:set(val)
end

return PassiveBloom
