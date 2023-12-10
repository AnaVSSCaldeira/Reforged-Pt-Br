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

local assets = {
    Asset("ANIM", "anim/lavaarena_hits_variety.zip"),
}

local function fn()
    local inst = CreateEntity()
	
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	
    inst:AddTag("FX")
	
	inst.AnimState:SetBank("lavaarena_hits_variety")
	inst.AnimState:SetBuild("lavaarena_hits_variety")
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	inst.AnimState:SetFinalOffset(1)
	------------------------------------------
    inst.entity:SetPristine()
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	
	inst.SetTarget = function(inst, target)
		inst.Transform:SetPosition(target:GetPosition():Get())
		inst.AnimState:PlayAnimation("hit_"..(target:HasTag("minion") and 1 or (target:HasTag("largecreature") and 3 or 2)))
		inst.AnimState:SetScale(target:HasTag("minion") and 1 or -1, 1)
	end
	
	inst:ListenForEvent("animover", inst.Remove)
	
    return inst
end

return Prefab("forgespear_fx", fn, assets)
