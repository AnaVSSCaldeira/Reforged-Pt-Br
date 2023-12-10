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
    Asset("ANIM", "anim/lavaarena_firestaff_meteor.zip"),
}
local assets_splash = {
    Asset("ANIM", "anim/lavaarena_fire_fx.zip"),
}
local prefabs = {
    "infernalstaff_meteor_splash",
    "infernalstaff_meteor_splashhit",
}
local prefabs_splash = {
    "infernalstaff_meteor_splashbase",
}
--------------------------------------------------------------------------
-- Attack Functions
--------------------------------------------------------------------------
local function ShakeIfClose(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, .5, .03, .25, inst, 30)
end

local function OnImpact(inst) -- TODO one instance of a pitpig not getting hit in the middle of 2 other pitpigs, but the other pitpigs got hit
	inst:DoTaskInTime(FRAMES*3, function(inst)
        local scale = inst.Transform:GetScale()
		local splash_fx = COMMON_FNS.CreateFX("infernalstaff_meteor_splash", nil, inst.attacker)
        splash_fx:Init(inst:GetPosition(), splash_fx)
		local targets = COMMON_FNS.EQUIPMENT.GetAOETargets(inst.attacker, inst:GetPosition(), TUNING.FORGE.INFERNALSTAFF.ALT_RADIUS*scale, inst.tags.inc, inst.tags.ex)
        if inst.owner then
		    inst.owner.components.weapon:DoAltAttack(inst.attacker, targets, inst, TUNING.FORGE.INFERNALSTAFF.ALT_STIMULI, nil, nil, TUNING.FORGE.INFERNALSTAFF.ALT_DAMAGE_TYPE)
		    inst.owner.components.aoespell:OnSpellCast(inst.attacker, targets)
        end
		COMMON_FNS.LaunchItems(inst, TUNING.FORGE.INFERNALSTAFF.ALT_RADIUS)
		ShakeIfClose(inst)
		inst:Remove()
	end)
end
--------------------------------------------------------------------------
local function fn()
    local inst = COMMON_FNS.FXEntityInit("lavaarena_firestaff_meteor", "lavaarena_firestaff_meteor", "crash", {remove_fn = OnImpact, pristine_fn = function(inst)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        ------------------------------------------
        inst:AddTag("notarget") -- TODO should all FX have this?
    end})
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
    inst.tags = {}
	inst.AttackArea = function(inst, attacker, weapon, pos, tags_inc, tags_ex)
		if weapon then weapon.meteor = inst end
		inst.attacker = attacker
		inst.owner = weapon
		inst.Transform:SetPosition(pos:Get())
		inst.tags = {inc = tags_inc or {}, ex = tags_ex or {}}
        inst.components.scaler:SetSource(inst.attacker)
	end
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
local function splashfn()
    local inst = COMMON_FNS.FXEntityInit("lavaarena_fire_fx", "lavaarena_fire_fx", "firestaff_ult", {pristine_fn = function(inst)
        inst.entity:AddSoundEmitter()
        ------------------------------------------
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetFinalOffset(1) -- TODO why 1?
    end})
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
    inst.Init = function(inst, pos, source)
		inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/meteor_strike")
		inst.Transform:SetPosition(pos:Get())
		local base_fx = COMMON_FNS.CreateFX("infernalstaff_meteor_splashbase", nil, source)
        base_fx.Transform:SetPosition(pos:Get())
	end
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
local function splashbasefn()
    local inst = COMMON_FNS.FXEntityInit("lavaarena_fire_fx", "lavaarena_fire_fx", "firestaff_ult_projection", {pristine_fn = function(inst)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        inst.AnimState:SetLayer(LAYER_BACKGROUND)
        inst.AnimState:SetSortOrder(3) -- TODO why 3?
    end})
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
local function splashhitfn()
    local inst = COMMON_FNS.FXEntityInit("lavaarena_fire_fx", "lavaarena_fire_fx", "firestaff_ult_hit", {pristine_fn = function(inst)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetFinalOffset(1) -- TODO why 1?
    end})
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
    inst.SetTarget = function(inst, target)
		inst.Transform:SetPosition(target:GetPosition():Get())
		local scale = target:HasTag("minion") and .5 or (target:HasTag("largecreature") and 1.3 or .8) -- TODO use radius of mob???
		inst.AnimState:SetScale(scale, scale)
	end
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
return Prefab("infernalstaff_meteor", fn, assets, prefabs),
    Prefab("infernalstaff_meteor_splash", splashfn, assets_splash, prefabs_splash),
    Prefab("infernalstaff_meteor_splashbase", splashbasefn, assets_splash),
    Prefab("infernalstaff_meteor_splashhit", splashhitfn, assets_splash)
