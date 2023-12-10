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
    Asset("ANIM", "anim/spear_gungnir.zip"),
    Asset("ANIM", "anim/swap_spear_gungnir.zip"),
}
local assets_fx = {
    Asset("ANIM", "anim/lavaarena_staff_smoke_fx.zip"),
}
local prefabs = {
    "reticuleline",
    "reticulelineping",
    "spear_gungnir_lungefx",
    "weaponsparks_fx",
    "firehit",
}
local tuning_values = TUNING.FORGE.PITHPIKE
--------------------------------------------------------------------------
-- Attack Functions
--------------------------------------------------------------------------
-- TODO targets glow yellow on hit for a few frames, does ours do that? this might apply to other attacks as well
local function OnAttack(inst, attacker, target)
	if not inst.components.weapon.isaltattacking then
        COMMON_FNS.CreateFX("weaponsparks_fx", target, attacker)
	else
		COMMON_FNS.CreateFX("forgespear_fx", target, attacker)
		COMMON_FNS.EQUIPMENT.FlipTarget(attacker, target)
	end
end
--------------------------------------------------------------------------
-- Ability Functions
--------------------------------------------------------------------------
local function PyrePoker(inst, caster, pos)
	caster:PushEvent("combat_lunge", {
		targetpos = pos,
		weapon = inst
	})
end

local function OnLunge(inst, lunger)
	inst.components.rechargeable:StartRecharge()
	inst.components.aoespell:OnSpellCast(lunger)
end
--------------------------------------------------------------------------
-- Pristine Functions
--------------------------------------------------------------------------
local function PristineFN(inst)
	-- aoeweapon_lunge (from aoeweapon_lunge component) added to pristine state for optimization
	COMMON_FNS.AddTags(inst, "sharp", "pointy", "aoeweapon_lunge")
end
--------------------------------------------------------------------------
local weapon_values = {
	name_override = "spear_gungnir",
	swap_strings  = {"swap_spear_gungnir"},
	OnAttack      = OnAttack,
	AOESpell      = PyrePoker,
	pristine_fn   = PristineFN,
}
--------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.EQUIPMENT.CommonWeaponFN("spear_gungnir", nil, weapon_values, tuning_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	COMMON_FNS.EQUIPMENT.AOEWeaponLungeInit(inst, tuning_values.ALT_WIDTH, tuning_values.ALT_STIMULI, OnLunge)
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
return ForgePrefab("pithpike", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/inventoryimages.xml", "spear_gungnir.tex", "swap_spear_gungnir", "common_hand")
