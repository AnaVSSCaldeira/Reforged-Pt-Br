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
	Asset("ANIM", "anim/debuff_mfd.zip"),
}
local prefabs = {

}

local SYMBOL_OFFSET = -70
------------------------------------------------------------------------------
local function OnDetached(inst, target)
    if target and target.components.combat and target.components.combat:HasDamageBuff("debuff_mfd", true) then
        target.components.combat:RemoveDamageBuff("debuff_mfd", true)
    end
	inst.AnimState:PushAnimation("despawn", false)
	inst:ListenForEvent("animover", inst.Remove)
end

local function OnAttached(inst, target)
   if target.components.combat and target.components.debuffable then
		target.components.combat:AddDamageBuff("debuff_mfd", TUNING.FORGE.MFD.MULT, true)
		inst.entity:SetParent(target.entity)
		inst.entity:AddFollower()
        inst.Follower:FollowSymbol(target.GUID, target.components.debuffable.followsymbol or "head", 0, SYMBOL_OFFSET, 0)
        inst.Transform:SetPosition(0, 0, 0)
		inst.owner = target
   end
   inst.components.timer:StartTimer("mfdover", inst.duration)
end

local function OnExtended(inst, target)
    inst.components.timer:StopTimer("mfdover")
    inst.components.timer:StartTimer("mfdover", inst.duration)
end

local function OnTimerDone(inst, data)
    if data.name == "mfdover" then
        OnDetached(inst, inst.owner)
    end
end
------------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.BasicEntityInit("debuff_mfd", nil, nil, {noanim = true, pristine_fn = function(inst)
    	inst.entity:AddSoundEmitter()
        ------------------------------------------
        inst.AnimState:PlayAnimation("spawn")
    	inst.AnimState:PushAnimation("idle_loop", true)
    	inst.AnimState:SetScale(1.2, 1.2)
        inst.AnimState:SetFinalOffset(-1)
        ------------------------------------------
        COMMON_FNS.AddTags(inst, "FX", "NOCLICK", "CLASSIFIED")
    end})
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    inst.duration = TUNING.FORGE.MFD.DURATION
    ------------------------------------------
	inst:AddComponent("debuff")
	inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetExtendedFn(OnExtended)
	inst.components.debuff:SetDetachedFn(OnDetached)
    ------------------------------------------
	inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", OnTimerDone)
	------------------------------------------
	return inst
end
------------------------------------------------------------------------------
return Prefab("debuff_mfd", fn, assets, prefabs)
