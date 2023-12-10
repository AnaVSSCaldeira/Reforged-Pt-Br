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
    Asset("ANIM", "anim/spear_lance.zip"),
    Asset("ANIM", "anim/swap_spear_lance.zip"),
}
local prefabs = {
    "reticuleaoesmall",
    "reticuleaoesmallping",
    "reticuleaoesmallhostiletarget",
    "weaponsparks_fx",
    "forgespear_fx",
    "superjump_fx",
}
local tuning_values = TUNING.FORGE.SPIRALSPEAR
--------------------------------------------------------------------------
-- Ability Functions
--------------------------------------------------------------------------
local function SkyLunge(inst, caster, pos)
	caster:PushEvent("combat_superjump", {
		targetpos = pos,
		weapon = inst
	})
end

local function OnLeap(inst, leaper)
	local jump_fx = COMMON_FNS.CreateFX("superjump_fx", nil, leaper)
    jump_fx:SetTarget(inst)
	inst.components.rechargeable:StartRecharge()
	inst.components.aoespell:OnSpellCast(leaper)
end
--------------------------------------------------------------------------
-- Attack Functions
--------------------------------------------------------------------------
local function OnAttack(inst, attacker, target)
	if not inst.components.weapon.isaltattacking then
        COMMON_FNS.CreateFX("weaponsparks_fx", target, attacker)
	else
        COMMON_FNS.CreateFX("forgespear_fx", target, attacker)
	end
end
--------------------------------------------------------------------------
-- Pristine Functions
--------------------------------------------------------------------------
local function PristineFN(inst)
	--aoeweapon_leap (from aoeweapon_leap component) added to pristine state for optimization
	COMMON_FNS.AddTags(inst, "sharp", "pointy", "superjump", "aoeweapon_leap")
end
--------------------------------------------------------------------------
local weapon_values = {
	name_override = "spear_lance",
	swap_strings  = {"swap_spear_lance"},
	OnAttack      = OnAttack,
	AOESpell      = SkyLunge,
	pristine_fn   = PristineFN,
}
--------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.EQUIPMENT.CommonWeaponFN("spear_lance", nil, weapon_values, tuning_values)
	------------------------------------------
	inst.components.aoetargeting:SetRange(tuning_values.ALT_RANGE) -- TODO is this only in this file? should I put in common fn? need to check default values and if others that have alt range use this
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	COMMON_FNS.EQUIPMENT.AOEWeaponLeapInit(inst, tuning_values.ALT_STIMULI, OnLeap)
	------------------------------------------
	inst:AddComponent("multithruster")
	------------------------------------------
	return inst
end
--------------------------------------------------------------------------
return ForgePrefab("spiralspear", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/inventoryimages.xml", "spear_lance.tex", "swap_spear_lance", "common_hand")
