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
    Asset("ANIM", "anim/hammer_mjolnir.zip"),
    Asset("ANIM", "anim/swap_hammer_mjolnir.zip"),
}
local assets_crackle = {
    Asset("ANIM", "anim/lavaarena_hammer_attack_fx.zip"),
}
local prefabs = {
    "forginghammer_crackle_fx",
    "forgeelectricute_fx",
    "reticuleaoe",
    "reticuleaoeping",
    "reticuleaoehostiletarget",
    "weaponsparks_fx",
}
local prefabs_crackle = {
    "forginghammer_cracklebase_fx",
}
local tuning_values = TUNING.FORGE.FORGINGHAMMER
--------------------------------------------------------------------------
-- Ability Functions
--------------------------------------------------------------------------
local function AnvilStrike(inst, caster, pos)
	caster:PushEvent("combat_leap", {targetpos = pos, weapon = inst})
end

local function OnLeap(inst, leaper, starting_pos, target_pos)
    COMMON_FNS.CreateFX("forginghammer_crackle_fx", leaper)
	inst.components.rechargeable:StartRecharge()
	inst.components.aoespell:OnSpellCast(leaper)
end
--------------------------------------------------------------------------
-- Attack Functions
--------------------------------------------------------------------------
local function OnAttack(inst, attacker, target)
	if not inst.components.weapon.isaltattacking then
        COMMON_FNS.CreateFX("weaponsparks_fx", target, attacker)
		COMMON_FNS.EQUIPMENT.ApplyArmorBreak(attacker, target)
	else
        COMMON_FNS.CreateFX("forge_electrocute_fx", target, attacker)
	end
end
--------------------------------------------------------------------------
-- Pristine Functions
--------------------------------------------------------------------------
local function PristineFN(inst)
	-- aoeweapon_leap (from aoeweapon_leap component) added to pristine state for optimization
	COMMON_FNS.AddTags(inst, "hammer", "aoeweapon_leap")
end
--------------------------------------------------------------------------
local weapon_values = {
	name_override = "hammer_mjolnir",
	swap_strings  = {"swap_hammer_mjolnir"},
	OnAttack      = OnAttack,
	AOESpell      = AnvilStrike,
	pristine_fn   = PristineFN,
}
--------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.EQUIPMENT.CommonWeaponFN("hammer_mjolnir", nil, weapon_values, tuning_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	COMMON_FNS.EQUIPMENT.AOEWeaponLeapInit(inst, tuning_values.ALT_STIMULI, OnLeap)
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
local function cracklefn()
    local inst = COMMON_FNS.FXEntityInit("lavaarena_hammer_attack_fx", "lavaarena_hammer_attack_fx", "crackle_hit", {pristine_fn = function(inst)
	    inst.entity:AddSoundEmitter()
	    ------------------------------------------
	    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	    inst.AnimState:SetFinalOffset(1)
	end})
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
    inst.SetTarget = function(inst, target)
		local target_pos = target:GetPosition()
		inst.Transform:SetPosition(target_pos:Get())
		inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/hammer")
		SpawnPrefab("forginghammer_cracklebase_fx").Transform:SetPosition(target_pos:Get())
	end
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
local function cracklebasefn()
    local inst = COMMON_FNS.FXEntityInit("lavaarena_hammer_attack_fx", "lavaarena_hammer_attack_fx", "crackle_projection", {pristine_fn = function(inst)
	    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	    inst.AnimState:SetLayer(LAYER_BACKGROUND)
	    inst.AnimState:SetSortOrder(3)
	    inst.AnimState:SetScale(1.5, 1.5)
	end})
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
local function electric_fn()
	local inst = COMMON_FNS.FXEntityInit("lavaarena_hammer_attack_fx", "lavaarena_hammer_attack_fx", "crackle_loop", {noanimover = true, pristine_fn = function(inst)
		inst.entity:AddSoundEmitter()
		------------------------------------------
		inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
		inst.AnimState:SetFinalOffset(1)
		inst.AnimState:SetScale(1.5, 1.5)
	end})
	------------------------------------------
	if not TheWorld.ismastersim then
		return inst
	end
	------------------------------------------
	inst.SetTarget = function(inst, target, sound)
		inst.Transform:SetPosition(target:GetPosition():Get())
		if sound then
			inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/electric")
		end
		if target:HasTag("largecreature") or target:HasTag("epic") then
			inst.AnimState:SetScale(2, 2)
		end
	end
	------------------------------------------
	inst:ListenForEvent("animover", function(inst)
		if inst.AnimState:IsCurrentAnimation("crackle_loop") then
			inst.AnimState:PlayAnimation("crackle_pst")
		else
			inst:Remove()
		end
	end)
	------------------------------------------
	return inst
end
--------------------------------------------------------------------------
return ForgePrefab("forginghammer", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/inventoryimages.xml", "hammer_mjolnir.tex", "swap_hammer_mjolnir", "common_hand")--,
    --Prefab("forginghammer_crackle_fx", cracklefn, assets_crackle, prefabs_crackle),
    --Prefab("forginghammer_cracklebase_fx", cracklebasefn, assets_crackle),
	--Prefab("forgeelectricute_fx", electric_fn, assets_crackle)
