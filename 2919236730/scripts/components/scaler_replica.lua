local function OnScale(inst)
    local scaler = inst.replica.scaler
    local reticule = ThePlayer and ThePlayer.components.playercontroller.reticule
    if scaler and reticule and reticule.reticule then -- TODO NOTE: Shouldn't get here with no reticule. Not sure how that is happening.
        -- Apply scaler to any active reticules
        local scale = scaler:GetScale() * (reticule.base_scale or 1.5) -- defaulting to 1.5, if default occurs then another mod is probably conflicting with CreateReticule in the reticule component.
        reticule.reticule.AnimState:SetScale(scale,scale)
    end
end

local Scaler = Class(function(self, inst)
    self.inst   = inst
    self._scale = net_float(inst.GUID, "scaler._scale", "scale")
    if not TheNet:IsDedicated() then
        self.inst:ListenForEvent("scale", OnScale)
    end
end)

function Scaler:GetScale()
    return self._scale:value()
end

function Scaler:SetScale(scale)
    self._scale:set(scale)
end

return Scaler
