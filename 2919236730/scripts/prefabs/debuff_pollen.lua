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
local assets = {}
local prefabs = {
    "pollen_debuff_fx",
}
local tuning_values = TUNING.FORGE.COOKPOT
------------------------------------------------------------------------------
local pollenpool = { 1, 2, 3, 4, 5 }
for i = #pollenpool, 1, -1 do
    --randomize in place
    table.insert(pollenpool, table.remove(pollenpool, math.random(i)))
end
local function RandomPollen()
    --randomize, favoring ones that haven't been used recently
    local rnd = math.random()
    rnd = table.remove(pollenpool, math.clamp(math.ceil(rnd * rnd * #pollenpool), 1, #pollenpool))
    table.insert(pollenpool, rnd)
    return rnd
end

local function OnAttached(inst, target)
    inst:DoTaskInTime(0, function() -- Delay so duration and attack mult debuff can be set
        inst.entity:SetParent(target.entity)
        -- Remove debuff when target dies
        inst:ListenForEvent("death", function()
            inst.components.debuff:Stop()
        end, target)
        -- Attach buff
        if target.components.combat then
            target.components.combat:AddDamageBuff("passive_bloom", inst.attack_mult_debuff)
        end
        target.pollen_debuff_timer = target:DoTaskInTime(inst.duration, function()
            inst.components.debuff:Stop()
        end)
    end)
end

local function OnExtended(inst, target)

end

local function OnDetached(inst, target)
    if target.components.combat then
        target.components.combat:RemoveDamageBuff("passive_bloom")
    end
    RemoveTask(target.pollen_debuff_timer)
	inst:Remove()
end
------------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.BasicEntityInit("wormwood_pollen_fx", nil, "pollen"..tostring(RandomPollen()), {anim_loop = false, pristine_fn = function(inst)
        inst.AnimState:SetFinalOffset(2)
        ------------------------------------------
        inst.Transform:SetScale(2,2,2)
        ------------------------------------------
        COMMON_FNS.AddTags(inst, "FX", "NOCLICK")
    end})
	------------------------------------------
	if not TheWorld.ismastersim then
		return inst
	end
    ------------------------------------------
    inst.source = nil
    inst.duration = 10
    inst.attack_mult_debuff = 1
    ------------------------------------------
	inst:AddComponent("debuff")
	inst.components.debuff:SetAttachedFn(OnAttached)
    --inst.components.debuff:SetExtendedFn(OnExtended) -- TODO should there be a reset if triggered by a second wormwood? or should it just ignore that? If extended then technically 2 wormwoods could keep pollen activated forever if timed correctly.
	inst.components.debuff:SetDetachedFn(OnDetached)
    ------------------------------------------
    inst:ListenForEvent("animover", function(inst)
        inst.AnimState:PlayAnimation("pollen" .. tostring(RandomPollen()))
    end)
    ------------------------------------------
	return inst
end
------------------------------------------------------------------------------
return Prefab("debuff_pollen", fn, assets, prefabs)
