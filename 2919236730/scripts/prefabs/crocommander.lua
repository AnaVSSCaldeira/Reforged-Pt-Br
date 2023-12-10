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
	crocommander = {},
	crocommander_rapidfire = {
		Asset("ANIM", "anim/lavaarena_snapper_rapidfire.zip"),
	}
}
local prefabs = {
	crocommander = {},
	crocommander_rapidfire = {}
}
local tuning_values = TUNING.FORGE.CROCOMMANDER
local sound_path = "dontstarve/creatures/lava_arena/snapper/"
--------------------------------------------------------------------------
-- Attack Functions
--------------------------------------------------------------------------
local function SetBanner(inst)
	local wave = TheWorld.components.lavaarenaevent
	return wave and wave.current_round_data and wave.current_round_data.banner or "battlestandard_heal"
end
--------------------------------------------------------------------------
-- Physics Functions
--------------------------------------------------------------------------
local physics = {
	mass   = 100,
	radius = 0.75,
	shadow = {2,0.75},
}
local function PhysicsInit(inst)
	MakeCharacterPhysics(inst, physics.mass, physics.radius)
	inst.DynamicShadow:SetSize(unpack(physics.shadow))
    inst.Transform:SetFourFaced()
end
--------------------------------------------------------------------------
local mob_values = {
	physics         = physics,
	physics_init_fn = PhysicsInit,
	stategraph      = "SGcrocommander",
	brain           = require("brains/crocommanderbrain"),
	sounds = {
		taunt   = sound_path .. "taunt",
		taunt_2 = sound_path .. "taunt_2",
		hit     = sound_path .. "hit",
		stun    = sound_path .. "stun",
		attack  = sound_path .. "attack",
		spit    = sound_path .. "spit",
		spit2   = sound_path .. "spit2",
		death   = sound_path .. "death",
		sleep   = sound_path .. "sleep",
	},
}
--------------------------------------------------------------------------
local function common_fn(build, name_override, tuning_values)
	mob_values.name_override = name_override
	local inst = COMMON_FNS.CommonMobFN("snapper", build, mob_values, tuning_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	COMMON_FNS.AddSymbolFollowers(inst, "head", nil, "medium", {symbol = "body"}, {symbol = "body"})
	------------------------------------------
	inst:AddComponent("leader")
	------------------------------------------
	inst.weapon = COMMON_FNS.EQUIPMENT.ProjectileWeaponInit(inst, tuning_values.SPIT_PROJECTILE, tuning_values.SPIT_DAMAGE, TUNING.FORGE.DAMAGETYPES.LIQUID, tuning_values.SPIT_ATTACK_PERIOD, tuning_values.SPIT_ATTACK_RANGE)
	------------------------------------------
	inst:AddComponent("inventory")
	------------------------------------------
	--TODO: Remove this when done
	--inst:AddComponent("attack_radius_display")
	--inst.components.attack_radius_display:AddCircle("melee", tuning_values.ATTACK_RANGE, WEBCOLOURS.RED)
	--inst.components.attack_radius_display:AddCircle("melee_range", tuning_values.MELEE_RANGE, WEBCOLOURS.MEDIUMPURPLE)
	--inst.components.attack_radius_display:AddCircle("ranged", tuning_values.SPIT_ATTACK_RANGE + tuning_values.SPIT_ATTACK_RANGE, WEBCOLOURS.LIGHTSKYBLUE) --weapons add attack range unto existing attack range
	------------------------------------------
	local _oldRemove = inst.Remove
	inst.Remove = function()
		inst.weapon:Remove() -- Remove Weapon
		_oldRemove(inst)
	end
	------------------------------------------
	return inst
end
--------------------------------------------------------------------------
local fns = {}
fns.crocommander = function()
	local inst = common_fn("lavaarena_snapper_basic", "snapper", TUNING.FORGE.CROCOMMANDER)
	------------------------------------------
	if not TheWorld.ismastersim then
		return inst
	end
	------------------------------------------
	inst.components.combat:AddAttack("banner", true, tuning_values.BANNER_CD, nil, {banners = {SetBanner()}})
	------------------------------------------
	return inst
end

fns.crocommander_rapidfire = function()
	local inst = common_fn("lavaarena_snapper_rapidfire", nil, TUNING.FORGE.CROCOMMANDER_RAPIDFIRE)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	return inst
end

local variants = {"crocommander", "crocommander_rapidfire"}
local function MakeVariant(prefab)
	return ForgePrefab(prefab, fns[prefab], assets[prefab], prefabs[prefab], nil, TUNING.FORGE[string.upper(prefab)].ENTITY_TYPE, nil, "images/reforged.xml", prefab.."_icon.tex")
end
local prefs = {}
for k,v in pairs(variants) do
	table.insert(prefs, MakeVariant(v))
end
return unpack(prefs)
