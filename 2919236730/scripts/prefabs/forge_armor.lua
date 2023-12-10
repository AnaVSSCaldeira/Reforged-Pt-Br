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

local data = {
	---------------------------------------------------------------------------
	--Forge Season 1
	armorlight = {
		prefab = "reedtunic",
		tags = { "grass" },
		foleysound = "dontstarve/movement/foley/grassarmour",
		hitsound = "dontstarve/wilson/hit_straw",
		masterfn = function(inst)
			inst.components.itemtype:SetType("armors")
			inst.components.armor:InitIndestructible(TUNING.FORGE.REEDTUNIC.DEFENSE)
			inst.components.equippable:AddUniqueBuff({
				{name = "cooldown", val = TUNING.FORGE.REEDTUNIC.BONUS_COOLDOWNRATE, type = "add"}
			})
		end
	},

	armorlightspeed = {
		prefab = "featheredtunic",
		tags = { "grass" },
		foleysound = "dontstarve/movement/foley/grassarmour",
		hitsound = "dontstarve/wilson/hit_straw",
		masterfn = function(inst)
			inst.components.itemtype:SetType("armors")
			inst.components.armor:InitIndestructible(TUNING.FORGE.FEATHEREDTUNIC.DEFENSE)
			inst.components.equippable.walkspeedmult = TUNING.FORGE.FEATHEREDTUNIC.SPEEDMULT
		end
	},

	armormedium = {
		prefab = "forge_woodarmor",
		tags = { "wood" },
		foleysound = "dontstarve/movement/foley/logarmour",
		hitsound = "dontstarve/wilson/hit_armour",
		masterfn = function(inst)
			inst.components.itemtype:SetType("armors")
			inst.components.armor:InitIndestructible(TUNING.FORGE.FORGE_WOODARMOR.DEFENSE)
		end
	},

	armormediumdamager = {
		prefab = "jaggedarmor",
		tags = { "wood" },
		foleysound = "dontstarve/movement/foley/logarmour",
		hitsound = "dontstarve/wilson/hit_armour",
		masterfn = function(inst)
			inst.components.itemtype:SetType("armors")
			inst.components.armor:InitIndestructible(TUNING.FORGE.JAGGEDARMOR.DEFENSE)
			inst.components.equippable:AddDamageBuff("jaggedarmor", {buff = TUNING.FORGE.JAGGEDARMOR.BONUSDAMAGE, damagetype = TUNING.FORGE.DAMAGETYPES.PHYSICAL})
		end
	},

	armormediumrecharger = {
		prefab = "silkenarmor",
		tags = { "wood" },
		foleysound = "dontstarve/movement/foley/logarmour",
		hitsound = "dontstarve/wilson/hit_armour",
		masterfn = function(inst)
			inst.components.itemtype:SetType("armors")
			inst.components.armor:InitIndestructible(TUNING.FORGE.SILKENARMOR.DEFENSE)
			inst.components.equippable:AddUniqueBuff({
				{name = "cooldown", val = TUNING.FORGE.SILKENARMOR.BONUS_COOLDOWNRATE, type = "add"}
			})
		end
	},

	armorheavy = {
		prefab = "splintmail",
		tags = { "marble" },
		foleysound = "dontstarve/movement/foley/marblearmour",
		hitsound = "dontstarve/wilson/hit_marble",
		masterfn = function(inst)
			inst.components.itemtype:SetType("armors")
			inst.components.armor:InitIndestructible(TUNING.FORGE.SPLINTMAIL.DEFENSE)
		end
	},

	armorextraheavy = {
		prefab = "steadfastarmor",
		tags = { "marble", "heavyarmor" },
		foleysound = "dontstarve/movement/foley/marblearmour",
		hitsound = "dontstarve/wilson/hit_marble",
		masterfn = function(inst)
			inst.components.itemtype:SetType({"heavy", "armors"})
			inst.components.armor:InitIndestructible(TUNING.FORGE.STEADFASTARMOR.DEFENSE)
			inst.components.equippable.walkspeedmult = TUNING.FORGE.STEADFASTARMOR.SPEEDMULT
		end
	},

	---------------------------------------------------------------------------
	--Forge Season 2
	armor_hpextraheavy = {
		prefab = "steadfastgrandarmor",
		tags = { "ruins", "metal", "heavyarmor" },
		foleysound = "dontstarve/movement/foley/metalarmour",
		hitsound = "dontstarve/wilson/hit_metal",
		masterfn = function(inst)
			inst.nameoverride = "lavaarena_armor_hpextraheavy"
			inst.components.itemtype:SetType({"hp_armors", "armors"})
			inst.components.armor:InitIndestructible(TUNING.FORGE.STEADFASTGRANDARMOR.DEFENSE)
			inst.max_hp = TUNING.FORGE.STEADFASTGRANDARMOR.MAX_HP
		end
	},

	armor_hppetmastery = {
		prefab = "whisperinggrandarmor",
		tags = { "ruins", "metal" },
		foleysound = "dontstarve/movement/foley/metalarmour",
		hitsound = "dontstarve/wilson/hit_metal",
		masterfn = function(inst)
			inst.nameoverride = "lavaarena_armor_hppetmastery"
			inst.components.itemtype:SetType({"hp_armors", "armors"})
			inst.components.armor:InitIndestructible(TUNING.FORGE.WHISPERINGGRANDARMOR.DEFENSE)
			inst.max_hp = TUNING.FORGE.WHISPERINGGRANDARMOR.MAX_HP
			inst.pet_level_up = TUNING.FORGE.WHISPERINGGRANDARMOR.PET_LEVEL_UP
		end
	},

	armor_hprecharger = {
		prefab = "silkengrandarmor",
		tags = { "ruins", "metal" },
		foleysound = "dontstarve/movement/foley/metalarmour",
		hitsound = "dontstarve/wilson/hit_metal",
		masterfn = function(inst)
			inst.nameoverride = "lavaarena_armor_hprecharger"
			inst.components.itemtype:SetType({"hp_armors", "armors"})
			inst.components.armor:InitIndestructible(TUNING.FORGE.SILKENGRANDARMOR.DEFENSE)
			inst.components.equippable:AddUniqueBuff({
				{name = "cooldown", val = TUNING.FORGE.SILKENGRANDARMOR.BONUS_COOLDOWNRATE, type = "add"}
			})
			inst.max_hp = TUNING.FORGE.SILKENGRANDARMOR.MAX_HP
		end
	},

	armor_hpdamager = {
		prefab = "jaggedgrandarmor",
		tags = { "ruins", "metal" },
		foleysound = "dontstarve/movement/foley/metalarmour",
		hitsound = "dontstarve/wilson/hit_metal",
		masterfn = function(inst)
			inst.nameoverride = "lavaarena_armor_hpdamager"
			inst.components.itemtype:SetType({"hp_armors", "armors"})
			inst.components.armor:InitIndestructible(TUNING.FORGE.JAGGEDGRANDARMOR.DEFENSE)
			inst.components.equippable:AddDamageBuff("jaggedarmor", {buff = TUNING.FORGE.JAGGEDGRANDARMOR.BONUSDAMAGE, damagetype = TUNING.FORGE.DAMAGETYPES.PHYSICAL})
			inst.max_hp = TUNING.FORGE.JAGGEDGRANDARMOR.MAX_HP
		end
	},
}
--------------------------------------------------------------------------
local function MakeArmour(name)
	local build = name
	if not name:find("armor_") then
		build = build:gsub("armor", "armor_")
	end

    local assets = {
        Asset("ANIM", "anim/"..build..".zip"),
    }
	--------------------------------------------------------------------------
    local function fn()
    	local armor_values = {
    		name_override = "lavaarena_"..name,
    		pristine_fn = function(inst)
		        COMMON_FNS.AddTags(inst, unpack(data[name].tags))
		        ------------------------------------------
		        inst.foleysound = data[name].foleysound
		        inst.hitsound = data[name].hitsound
    		end,
    	}
    	------------------------------------------
        local inst = COMMON_FNS.EQUIPMENT.ArmorInit(build, nil, "anim", armor_values)
		------------------------------------------
        if not TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------
		inst.components.inventoryitem.imagename = "lavaarena_"..name
		------------------------------------------
		data[name].masterfn(inst)
		------------------------------------------
        return inst
    end

    return ForgePrefab(data[name].prefab, fn, assets, nil, nil, TUNING.FORGE[string.upper(data[name].prefab)].ENTITY_TYPE, nil, "images/inventoryimages.xml", "lavaarena_" .. name .. ".tex", name:gsub("armor", "armor_"), "common_body")
end
--------------------------------------------------------------------------
local armors = {}
for k,v in pairs(data) do
    table.insert(armors, MakeArmour(k))
end
return unpack(armors)
