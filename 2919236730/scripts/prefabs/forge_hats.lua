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
	feathercrown = {
		prefab = "featheredwreath",
		masterfn = function(inst)
			inst.components.itemtype:SetType("speed_hats")
			inst.components.equippable.walkspeedmult = TUNING.FORGE.FEATHEREDWREATH.SPEEDMULT
		end
	},

	lightdamager = {
		prefab = "barbedhelm",
		hidesymbols = true,
		masterfn = function(inst)
			inst.components.itemtype:SetType("damage_hats")
			inst.components.equippable:AddDamageBuff("barbedhelm", {buff = TUNING.FORGE.BARBEDHELM.BONUSDAMAGE, damagetype = TUNING.FORGE.DAMAGETYPES.PHYSICAL})
		end
	},

	recharger = {
		prefab = "crystaltiara",
		masterfn = function(inst)
			inst.components.itemtype:SetType("cooldown_hats")
			inst.components.equippable:AddUniqueBuff({
				{name = "cooldown", val = TUNING.FORGE.CRYSTALTIARA.BONUS_COOLDOWNRATE, type = "add"}
			})
		end
	},

	healingflower = {
		prefab = "flowerheadband",
		masterfn = function(inst)
			inst.components.itemtype:SetType("health_hats")
			inst.components.equippable:AddUniqueBuff({
				{name = "heal_recieved", val = TUNING.FORGE.FLOWERHEADBAND.HEALINGRECEIVEDMULT, type = "mult"}
			})
		end
	},

	tiaraflowerpetals = {
		prefab = "wovengarland",
		masterfn = function(inst)
			inst.components.itemtype:SetType("healing_hats")
			inst.components.equippable:AddUniqueBuff({
				{name = "heal_dealt", val = TUNING.FORGE.WOVENGARLAND.HEALINGDEALTMULT, type = "mult"}
			})
		end
	},

	strongdamager = {
		prefab = "noxhelm",
		hidesymbols = true,
		masterfn = function(inst)
			inst.components.itemtype:SetType("damage_hats")
			inst.components.equippable:AddDamageBuff("noxhelm", {buff = TUNING.FORGE.NOXHELM.BONUSDAMAGE, damagetype = TUNING.FORGE.DAMAGETYPES.PHYSICAL})
		end
	},

	crowndamager = {
		prefab = "resplendentnoxhelm",
		hidesymbols = true,
		masterfn = function(inst)
			inst.components.itemtype:SetType({"damage_hats", "speed_hats", "cooldown_hats"})
			inst.components.equippable.walkspeedmult = TUNING.FORGE.RESPLENDENTNOXHELM.SPEEDMULT
			inst.components.equippable:AddDamageBuff("resplendentnoxhelm", {buff = TUNING.FORGE.RESPLENDENTNOXHELM.BONUSDAMAGE, damagetype = TUNING.FORGE.DAMAGETYPES.PHYSICAL})
			inst.components.equippable:AddUniqueBuff({
				{name = "cooldown", val = TUNING.FORGE.RESPLENDENTNOXHELM.BONUS_COOLDOWNRATE, type = "add"}
			})
		end
	},

	healinggarland = {
		prefab = "blossomedwreath",
		masterfn = function(inst)
			inst.components.itemtype:SetType({"health_hats", "speed_hats", "cooldown_hats"})
			inst.HealOwner = function(inst, owner)
				inst.heal_task = inst:DoTaskInTime(TUNING.FORGE.BLOSSOMEDWREATH.REGEN.period, function(inst)
					if inst.components.equippable:IsEquipped() and not owner.components.health:IsDead() then
						if owner.components.health:GetPercent() < TUNING.FORGE.BLOSSOMEDWREATH.REGEN.limit then
							if not inst:HasTag("regen") then
                                inst:AddTag("regen")
                                owner.components.health:AddRegen("blossomedwreath_regen", TUNING.FORGE.BLOSSOMEDWREATH.REGEN.delta/TUNING.FORGE.BLOSSOMEDWREATH.REGEN.period)
                            end
                            if (owner.components.health.currenthealth + TUNING.FORGE.BLOSSOMEDWREATH.REGEN.delta) / owner.components.health.maxhealth > TUNING.FORGE.BLOSSOMEDWREATH.REGEN.limit then
                                owner.components.health:SetPercent(TUNING.FORGE.BLOSSOMEDWREATH.REGEN.limit)
                            else
                                owner.components.health:DoDelta(TUNING.FORGE.BLOSSOMEDWREATH.REGEN.delta, true, "regen", true)
                            end
						else
                            owner.components.health:RemoveRegen("blossomedwreath_regen")
							inst:RemoveTag("regen")
						end
						inst:HealOwner(owner)
					else
						inst:RemoveTag("regen")
					end
				end)
			end
            inst:ListenForEvent("equipped", function(inst, data)
                inst:HealOwner(data.owner)
                inst._deathfunction = function(owner)
                    if inst.heal_task then
                        inst.heal_task:Cancel()
                        inst.heal_task = nil
                    end
                    inst:RemoveTag("regen")
                    owner.components.health:Kill()
                end
                inst._revivefunction = function(owner)
                    inst:HealOwner(owner)
                end
                data.owner:ListenForEvent("ms_respawnedfromghost", inst._revivefunction)
                data.owner:ListenForEvent("death", inst._deathfunction)
            end)
            inst:ListenForEvent("unequipped", function(inst, data)
            	local owner = data.owner
                if inst.heal_task then
                    inst.heal_task:Cancel()
                    inst.heal_task = nil
                end
                inst:RemoveTag("regen")
                owner.components.health:RemoveRegen("blossomedwreath_regen")
                owner:RemoveEventCallback("ms_respawnedfromghost", inst._revivefunction)
                inst._revivefunction = nil
                owner:RemoveEventCallback("death", inst._deathfunction)
                inst._deathfunction = nil
            end)
			inst.components.equippable.walkspeedmult = TUNING.FORGE.BLOSSOMEDWREATH.SPEEDMULT
			inst.components.equippable:AddUniqueBuff({
				{name = "cooldown", val = TUNING.FORGE.BLOSSOMEDWREATH.BONUS_COOLDOWNRATE, type = "add"}
			})
		end
	},

	eyecirclet = {
		prefab = "clairvoyantcrown",
		masterfn = function(inst)
			inst.components.itemtype:SetType({"magic_hats", "speed_hats", "cooldown_hats"})
			inst.components.equippable.walkspeedmult = TUNING.FORGE.CLAIRVOYANTCROWN.SPEEDMULT
			inst.components.equippable:AddDamageBuff("clairvoyantcrown", {buff = TUNING.FORGE.CLAIRVOYANTCROWN.MAGE_BONUSDAMAGE, damagetype = TUNING.FORGE.DAMAGETYPES.MAGIC})
			inst.components.equippable:AddUniqueBuff({
				{name = "cooldown", val = TUNING.FORGE.CLAIRVOYANTCROWN.BONUS_COOLDOWNRATE, type = "add"}
			})
		end
	}
}
--------------------------------------------------------------------------
local function MakeHat(name)
    local build = "hat_"..name
    local name_override = "lavaarena_"..name.."hat"
    local assets = {
        Asset("ANIM", "anim/"..build..".zip"),
    }
    --------------------------------------------------------------------------
    local hat_values = {
    	name_override = name_override,
    	image_name    = name_override,
        cover_head    = data[name].hidesymbols
    }
    --------------------------------------------------------------------------
    local function fn()
        local inst = COMMON_FNS.EQUIPMENT.HelmInit(name.."hat", build, "anim", hat_values)
		------------------------------------------
        if not TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------
		data[name].masterfn(inst)
        ------------------------------------------
        return inst
    end

    return ForgePrefab(data[name].prefab, fn, assets, nil, nil, TUNING.FORGE[string.upper(data[name].prefab)].ENTITY_TYPE, nil, "images/inventoryimages.xml", name_override .. ".tex", build, data[name].hidesymbols and "common_head1" or "common_head2")
end
--------------------------------------------------------------------------
local hats = {}
for k,v in pairs(data) do
	table.insert(hats, MakeHat(k))
end
return unpack(hats)
