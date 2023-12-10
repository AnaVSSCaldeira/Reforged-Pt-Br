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
	 Asset("ANIM", "anim/forge_woby_buff_fx.zip"),
}
local prefabs = {

}
------------------------------------------------------------------------------
local function OnAttached(inst, target)
	local hands = target.components.inventory and target.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil
	if target.components.buffable then
		target.components.buffable:AddBuff("woby_buff", {{name = "cooldown", val = TUNING.FORGE.WOBY.BUFF_MULT, type = "mult"}})
	end
	if hands and hands.components.rechargeable then
		hands.components.rechargeable:RecalculateRate()
	end
	inst.buff_timer = inst:DoTaskInTime(inst.duration, function(inst)
        inst.components.debuff:Stop()
        inst.buff_timer = nil
    end)
	local fx = SpawnPrefab("buff_woby_head_fx")
	fx.entity:SetParent(target.entity)
    fx.entity:AddFollower()
    fx.Follower:FollowSymbol(target.GUID, target.components.debuffable.followsymbol, 0, -200, 0)

	local fx2 = SpawnPrefab("buff_woby_fx")
	fx2.entity:SetParent(target.entity)
	inst.fx = fx2
end

local function OnExtended(inst, target)
	inst.buff_timer:Cancel()
	inst.buff_timer = inst:DoTaskInTime(inst.duration, function(inst)
        inst.components.debuff:Stop()
        inst.buff_timer = nil
    end)
end

local function OnDetached(inst, target)
    if target.components.buffable then
		target.components.buffable:RemoveBuff("woby_buff")
	end
	if inst.fx then
		inst.fx:Remove()
	end
	inst:Remove()
end
------------------------------------------------------------------------------
local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
    ------------------------------------------
	inst.entity:SetPristine()
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    inst.duration = TUNING.FORGE.WOBY.BUFF_DURATION
    ------------------------------------------
	inst:AddComponent("debuff")
	inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetExtendedFn(OnExtended)
	inst.components.debuff:SetDetachedFn(OnDetached)
    ------------------------------------------
	inst.persists = false
	return inst
end
------------------------------------------------------------------------------
local function MakeFx(name, isidle)
	local function fxfn()
		local inst = CreateEntity()
		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddNetwork()
		inst.AnimState:SetBank("forge_woby_buff_fx")
		inst.AnimState:SetBuild("forge_woby_buff_fx")
		inst.AnimState:PlayAnimation(isidle and "idle" or "spawn", isidle)
		inst.Transform:SetScale(2, 2, 2)
		------------------------------------------
		inst.entity:SetPristine()
		------------------------------------------
		if not TheWorld.ismastersim then
			return inst
		end
		------------------------------------------
		inst.persists = false
		------------------------------------------
		if not isidle then
			inst:ListenForEvent("animqueueover", inst.Remove)
		end
		------------------------------------------
		return inst
	end
	return Prefab(name, fxfn, assets, prefabs)
end
------------------------------------------------------------------------------
return Prefab("buff_woby", fn, assets, prefabs),
	MakeFx("buff_woby_head_fx", false),
	MakeFx("buff_woby_fx", true)
