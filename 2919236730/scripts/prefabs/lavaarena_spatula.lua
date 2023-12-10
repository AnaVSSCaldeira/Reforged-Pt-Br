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
local prefabs = { -- TODO what are needed?
    "reticuleaoesmall",
    "reticuleaoesmallping",
    "reticuleaoesmallhostiletarget",
    "sand_puff_large_front",
    "sand_puff_large_back",
    "reticule",
    "weaponsparks_fx",
	--
	"forge_cookpot",
}
local tuning_values = TUNING.FORGE.LAVAARENA_SPATULA
--------------------------------------------------------------------------
-- Attack Functions
--------------------------------------------------------------------------
local function OnAttack(inst, attacker, target)
    COMMON_FNS.CreateFX("weaponsparks_fx", target, attacker)
end
--------------------------------------------------------------------------
-- Ability Functions
--------------------------------------------------------------------------
local function SummonCookpot(inst, caster, pos)
    local cookpot = SpawnPrefab("forge_cookpot")
	cookpot.Transform:SetPosition(pos:Get())
	cookpot:SetOwner(caster)
	inst.cookpot = cookpot
    inst.components.rechargeable:StartRecharge()
    inst.components.aoespell:OnSpellCast(caster)
end
--------------------------------------------------------------------------
-- Pristine Functions
--------------------------------------------------------------------------
local function PristineFN(inst)
	COMMON_FNS.AddTags(inst, "cooker", "plant_seed")
end
--------------------------------------------------------------------------
local weapon_values = {
	swap_strings = {"swap_lavaarena_spatula"},
	OnAttack     = OnAttack,
	AOESpell     = SummonCookpot,
	pristine_fn  = PristineFN,
}
--------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.EQUIPMENT.CommonWeaponFN("lavaarena_spatula", nil, weapon_values, tuning_values)
	------------------------------------------
	inst.components.aoetargeting:SetRange(tuning_values.ALT_RANGE)
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
return ForgePrefab("lavaarena_spatula", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/reforged.xml", "lavaarena_spatula.tex", "swap_staffs", "common_hand")
