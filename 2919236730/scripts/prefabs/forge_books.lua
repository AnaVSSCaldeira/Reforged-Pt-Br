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
local prefabs_fossil = {
    "lavaarena_fossilizing",
    "reticuleaoe",
    "reticuleaoeping",
    "reticuleaoecctarget",
}
local prefabs_elemental = {
    "golem",
    "reticuleaoesummon",
    "reticuleaoesummonping",
    "reticuleaoesummontarget",
}
--------------------------------------------------------------------------
local CastSpell = {
	fossil = function(inst, caster, pos)
		inst.components.fossilizer:Fossilize(pos, caster)
		inst.components.rechargeable:StartRecharge() -- TODO should these 2 lines be a common function???
		inst.components.aoespell:OnSpellCast(caster)
	end,

	elemental = function(inst, caster, pos)
		local golem = COMMON_FNS.Summon("golem", caster, pos)
		inst.components.rechargeable:StartRecharge()
		inst.components.aoespell:OnSpellCast(caster)
	end,

	seedling = function(inst, caster, pos)
		local flytrap = COMMON_FNS.Summon("mean_flytrap", caster, pos)
        flytrap:UpdatePetLevel(nil, caster.current_pet_level or 1, true)
        inst.components.rechargeable:StartRecharge()
        inst.components.aoespell:OnSpellCast(caster)
	end,

	-- TODO different name?
	flytrap = function(inst, caster, pos)
		COMMON_FNS.Summon("adult_flytrap", caster, pos)
        inst.components.rechargeable:StartRecharge()
        inst.components.aoespell:OnSpellCast(caster)
	end,
}
--------------------------------------------------------------------------
local booktype_to_name = {-- TODO if we change booktype to match name then we can get rid of this table, why don't they match currently?
	fossil    = "petrifyingtome",
	elemental = "bacontome",
	seedling  = "seedlingtome",
	flytrap   = "flytraptome",
}
local prefab_override_name = {
	fossil = "book_fossil",
	elemental = "book_elemental"
}
--------------------------------------------------------------------------
local function MakeBook(booktype, prefabs)
    local name = "book_" .. booktype
	if booktype == "seedling" or booktype == "flytrap" then -- TODO remove this when seedling/flytrap has its own assets
		name = "book_elemental"
	end
	------------------------------------------
    local tuning_values = TUNING.FORGE[string.upper(booktype_to_name[booktype])]
	local assets = {
        Asset("ANIM", "anim/"..name..".zip"),
        Asset("ANIM", "anim/swap_"..name..".zip"),
    }
	--------------------------------------------------------------------------
	-- Pristine Functions
	--------------------------------------------------------------------------
    local function PristineFN(inst)
    	inst:AddTag("book")
    end
    ------------------------------------------
	local weapon_values = {
		anim          = name,
		name_override = prefab_override_name[booktype],
		swap_strings  = {"book_closed", "swap_" .. name},
		AOESpell      = CastSpell[booktype],
		type          = "book",
		pristine_fn   = PristineFN,
	}
	------------------------------------------
    local function fn()
		local inst = COMMON_FNS.EQUIPMENT.CommonWeaponFN(name, name, weapon_values, tuning_values)
		------------------------------------------
		if not TheWorld.ismastersim then
            return inst
        end
		------------------------------------------
		inst.castsound = "dontstarve/common/lava_arena/spell/fossilized" -- TODO move into sound table?
		------------------------------------------
		if booktype == "fossil" then
			inst:AddComponent("fossilizer")
			inst.components.fossilizer:SetRange(TUNING.FORGE.PETRIFYINGTOME.ALT_RADIUS)
		end
		------------------------------------------
        return inst
    end
    ------------------------------------------
    if booktype == "seedling" or booktype == "flytrap" then -- TODO remove this if statement when it's public
    	return Prefab(booktype_to_name[booktype], fn, assets, prefabs)
    else
    	return ForgePrefab(booktype_to_name[booktype], fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/inventoryimages.xml", name .. ".tex", {hide = {"swap_object", "ARM_carry"}, show = {"ARM_normal"}})
    end
end
--------------------------------------------------------------------------
return MakeBook("fossil", prefabs_fossil),
    MakeBook("elemental", prefabs_elemental),
	MakeBook("seedling", prefabs_elemental),
	MakeBook("flytrap", prefabs_elemental)
