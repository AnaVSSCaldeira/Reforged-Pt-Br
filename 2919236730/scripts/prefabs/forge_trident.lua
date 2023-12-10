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
    Asset("ANIM", "anim/trident.zip"),
    Asset("ANIM", "anim/swap_trident.zip"),
}
local prefabs = {
    "reticuleaoesmall",
    "reticuleaoesmallping",
    "reticuleaoesmallhostiletarget",
    "weaponsparks_fx",
}
local tuning_values = TUNING.FORGE.FORGE_TRIDENT
--------------------------------------------------------------------------
-- Ability Functions
--------------------------------------------------------------------------
local function SummonMermGuard(inst, caster, pos)
    local new_merm = COMMON_FNS.Summon("merm_guard", caster, pos)

    local fx = SpawnPrefab("merm_spawn_fx")
    fx.Transform:SetPosition(new_merm.Transform:GetWorldPosition())
    new_merm.SoundEmitter:PlaySound("dontstarve/characters/wurt/merm/throne/spawn")

    new_merm:UpdatePetLevel(nil, caster.current_pet_level or 1, true)
    inst.components.rechargeable:StartRecharge()
    inst.components.aoespell:OnSpellCast(caster)
end
--------------------------------------------------------------------------
-- Attack Functions
--------------------------------------------------------------------------
local function OnAttack(inst, attacker, target)
    COMMON_FNS.CreateFX("weaponsparks_fx", target, attacker)
end
--------------------------------------------------------------------------
-- Pristine Functions
--------------------------------------------------------------------------
local function PristineFN(inst)
    -- aoeweapon_lunge (from aoeweapon_lunge component) added to pristine state for optimization
    COMMON_FNS.AddTags(inst, "sharp", "pointy")
end
--------------------------------------------------------------------------
local weapon_values = {
    swap_strings = {"swap_trident"},
	OnAttack     = OnAttack,
	AOESpell     = SummonMermGuard,
    pristine_fn  = PristineFN,
}
--------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.EQUIPMENT.CommonWeaponFN("trident", nil, weapon_values, tuning_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end

	inst.components.inventoryitem.atlasname = "images/reforged.xml"
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
return ForgePrefab("forge_trident", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/reforged.xml", "trident.tex", "swap_trident", "common_hand")
