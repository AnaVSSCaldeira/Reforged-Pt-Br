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
--[[
TODO
Make it life drain on attack?
change name to portal staff?

make game settings panel a server option to be enabled.
--]]
local assets = {
    Asset("ANIM", "anim/staffs.zip"),
    Asset("ANIM", "anim/swap_staffs.zip"),
	Asset("ANIM", "anim/teleport_staff.zip"),
	Asset("ANIM", "anim/swap_teleport_staff.zip"),
}
local prefabs = { -- TODO what are needed?
    "reticuleaoesmall",
    "reticuleaoesmallping",
    "reticuleaoesmallhostiletarget",
    "sand_puff_large_front",
    "sand_puff_large_back",
    "reticule",
    "weaponsparks_fx",
}
local tuning_values = TUNING.FORGE.TELEPORT_STAFF
--------------------------------------------------------------------------
-- Ability Functions
--------------------------------------------------------------------------
local function Teleport(inst, caster, pos)
    caster.components.health:DoDelta(-10, nil, "teleport_staff", true, nil, true)
    if not caster.components.health:IsDead() then
        caster.sg:GoToState("portal_jumpin", {dest = pos})
    end
    inst.components.rechargeable:StartRecharge()
    inst.components.aoespell:OnSpellCast(caster)
end
--------------------------------------------------------------------------
-- Attack Functions
--------------------------------------------------------------------------
-- TODO should it have weapon sparks?
local function OnAttack(inst, attacker, target)
    COMMON_FNS.CreateFX("weaponsparks_fx", target, attacker)
end
--------------------------------------------------------------------------
-- Pristine Functions
--------------------------------------------------------------------------
local function PristineFN(inst)
    COMMON_FNS.AddTags(inst, "soulstealer")
    --inst.AnimState:SetRayTestOnBB(true)
end
--------------------------------------------------------------------------
local weapon_values = {
    swap_strings = {"swap_teleport_staff"},
	OnAttack     = OnAttack,
	AOESpell     = Teleport,
    pristine_fn  = PristineFN,
}
--------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.EQUIPMENT.CommonWeaponFN("teleport_staff", nil, weapon_values, tuning_values)
    ------------------------------------------
    inst.components.aoetargeting:SetRange(tuning_values.ALT_RANGE) -- TODO is this only in this file? should I put in common fn? need to check default values and if others that have alt range use this
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
	inst.components.inventoryitem.atlasname = "images/reforged.xml"
	------------------------------------------
	return inst
end
--------------------------------------------------------------------------
return ForgePrefab("teleport_staff", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/reforged.xml", "teleport_staff.tex", "swap_teleport_staff", "common_hand")
