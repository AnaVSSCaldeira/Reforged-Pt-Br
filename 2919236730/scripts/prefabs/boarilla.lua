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
local prefabs = {}
-----------------------------
local tuning_values = TUNING.FORGE.BOARILLA
local sound_path = "dontstarve/creatures/lava_arena/trails/"
--------------------------------------------------------------------------
-- Custom Variations Functions
--------------------------------------------------------------------------
-- Variations:
--   "" - is H
--    1 - is single plate
--    2 - is double plates
local variations = {"",2,1} -- Final variation should always be single plate
local function SetVariation(inst, variation)
	inst.variation = ((variation or #variations) - 1) % #variations + 1
	local build = inst.AnimState:GetBuild()
	inst.AnimState:OverrideSymbol("armour", build, "armour" .. tostring(variations[inst.variation]))
	inst.AnimState:OverrideSymbol("mouth", build, "mouth" .. tostring(variations[inst.variation]))
	if not inst.duplicator_source then
		inst:PushEvent("variation_changed", {variation = inst.variation})
	end
end

local function GetVariation(inst)
	return inst.variation
end
--------------------------------------------------------------------------
-- Attack Functions
--------------------------------------------------------------------------
-- Apply knockback to all hits
local function OnHitOther(inst, target)
	COMMON_FNS.KnockbackOnHit(inst, target, inst.sg:HasStateTag("rolling") and 2.5 or 5, tuning_values.ATTACK_KNOCKBACK) -- TODO tuning
end
--------------------------------------------------------------------------
-- Phases (Health Triggers)
--------------------------------------------------------------------------
local function EnterRollPhase1Trigger(inst) -- TODO needs to taunt on each phase trigger best way? do it like sleep and handle it in idle?
	inst.components.healthtrigger:RemoveTrigger(tuning_values.ROLL_TRIGGER_1)
	inst.components.combat:ToggleAttack("roll", not inst.classic)
	inst.components.combat:SetCooldown("roll", tuning_values.ROLL_CD)
end

local function EnterRollPhase2Trigger(inst)
	inst.components.healthtrigger:RemoveTrigger(tuning_values.ROLL_TRIGGER_2)
	inst.components.combat:SetCooldown("roll", tuning_values.ROLL_CD/2)
end

local function EnterRollPhase3Trigger(inst)
	inst.components.healthtrigger:RemoveTrigger(tuning_values.ROLL_TRIGGER_3)
	inst.components.combat:SetCooldown("roll", tuning_values.ROLL_CD)
end

local function EnterSlamTrigger(inst)
	inst.components.healthtrigger:RemoveTrigger(tuning_values.SLAM_TRIGGER)
	inst.components.combat:ToggleAttack("slam", true)
end

local function OnSlamCooldownComplete(inst)
	inst.components.combat.ignorehitrange = true
end
--------------------------------------------------------------------------
-- Physics Functions
--------------------------------------------------------------------------
local physics = {
	scale  = 1.2,
	mass   = 500,
	radius = 1.25,
	shadow = {3.25,1.75},
}
local function PhysicsInit(inst)
	MakeCharacterPhysics(inst, physics.mass, physics.radius)
	inst:SetPhysicsRadiusOverride(physics.radius)
	inst.DynamicShadow:SetSize(unpack(physics.shadow))
	local scale = physics.scale
	inst.Transform:SetScale(scale,scale,scale)
    inst.Transform:SetFourFaced()
end
--------------------------------------------------------------------------
-- Pristine Function
--------------------------------------------------------------------------
local function PristineFN(inst)
	COMMON_FNS.AddTags(inst, "epic", "largecreature")
	------------------------------------------
	--inst:AddComponent("attack_radius_display")
	--inst.components.attack_radius_display:AddCircle("melee_range", tuning_values.ATTACK_RANGE, WEBCOLOURS.RED)
	--inst.components.attack_radius_display:AddCircle("hit_range", 5, WEBCOLOURS.PURPLE)
	--inst.components.attack_radius_display:AddOffsetCircle("melee_hit_range", nil, tuning_values.FRONT_AOE_OFFSET, tuning_values.HIT_RANGE, WEBCOLOURS.ORANGE)
	--inst.components.attack_radius_display:AddCircle("roll_range", 8, WEBCOLOURS.LIGHTSKYBLUE)
	--inst.components.attack_radius_display:AddOffsetCircle("slam", nil, 3, 3, WEBCOLOURS.YELLOW)
end
--------------------------------------------------------------------------
local mob_values = {
	name_override   = "trails",
	physics         = physics,
	physics_init_fn = PhysicsInit,
	pristine_fn     = PristineFN,
	stategraph      = "SGboarilla",
	brain           = require("brains/boarillabrain"),
	builds = {
		"lavaarena_trails_basic",
		"lavaarena_trails_alt1",
	},
	sounds = {
		step         = sound_path .. "step",
		run          = sound_path .. "run",
		grunt        = sound_path .. "grunt",
		taunt        = sound_path .. "taunt",
		hit          = sound_path .. "hit",
		shell_impact = sound_path .. "hide_hit",
		hide_pre     = sound_path .. "hide_pre",
		hide_pst     = sound_path .. "hide_swell",
		attack1      = sound_path .. "attack1",
		attack2      = sound_path .. "attack2",
		swish        = sound_path .. "swish",
		bodyfall     = sound_path .. "bodyfall",
		sleep_in     = sound_path .. "sleep_in",
		sleep_out    = sound_path .. "sleep_out",
	},
}
--------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.CommonMobFN("trails", "lavaarena_trails_basic", mob_values, tuning_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	COMMON_FNS.AddSymbolFollowers(inst, "helmet", nil, "large", {symbol = "body"}, {symbol = "body"})
	------------------------------------------
	inst:AddComponent("item_launcher")
	------------------------------------------
	inst.SetVariation = SetVariation
	inst.GetVariation = GetVariation
	------------------------------------------
	--inst.components.Fossilizer:SetOverrideDuration(tuning_values.FOSSIL_TIME) -- TODO need to set fossilzable override duration that fossilzer calls
	------------------------------------------
	inst:AddComponent("bloomer")
	------------------------------------------
	inst.classic = false
	inst.recentlycharged = {}
    inst.Physics:SetCollisionCallback(COMMON_FNS.OnCollideDestroyObject)
	------------------------------------------
	local attacks = {
		slam = {cooldown = tuning_values.SLAM_CD, cooldown_fn = OnSlamCooldownComplete},
		roll = {cooldown = tuning_values.ROLL_CD},
	}
	inst.components.combat:AddAttacks(attacks)
	------------------------------------------
	inst:AddComponent("healthtrigger")
	inst.components.healthtrigger:AddTrigger(tuning_values.ROLL_TRIGGER_1, EnterRollPhase1Trigger)
	inst.components.healthtrigger:AddTrigger(tuning_values.ROLL_TRIGGER_2, EnterRollPhase2Trigger)
	inst.components.healthtrigger:AddTrigger(tuning_values.ROLL_TRIGGER_3, EnterRollPhase3Trigger)
	inst.components.healthtrigger:AddTrigger(tuning_values.SLAM_TRIGGER, EnterSlamTrigger)
	------------------------------------------
	inst.components.combat.onhitotherfn = OnHitOther
	------------------------------------------
	--MakeMediumBurnableCharacter(inst, "body")
	------------------------------------------
    return inst
end

return ForgePrefab("boarilla", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/reforged.xml", "boarilla_icon.tex")
