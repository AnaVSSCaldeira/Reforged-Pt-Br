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
local tuning_values = TUNING.FORGE.SNORTOISE
local sound_path = "dontstarve/creatures/lava_arena/turtillus/"
--------------------------------------------------------------------------
-- Attack Functions
--------------------------------------------------------------------------
local function OnSpinCooldownComplete(inst)
    inst.components.combat.ignorehitrange = true
end
--------------------------------------------------------------------------
-- Phases (Health Triggers)
--------------------------------------------------------------------------
local function SpinTrigger(inst)
	inst.components.healthtrigger:RemoveTrigger(tuning_values.SPIN_TRIGGER)
	inst.components.combat:ToggleAttack("spin", true)
	inst.components.combat.ignorehitrange = true
end
--------------------------------------------------------------------------
-- Physics Functions
--------------------------------------------------------------------------
local physics = {
    scale  = 0.8,
    mass   = 150,
    radius = 0.8,
    shadow = {2.5,1.75},
}
local function PhysicsInit(inst)
	inst:SetPhysicsRadiusOverride(physics.radius)
	MakeCharacterPhysics(inst, physics.mass, physics.radius)
	inst.DynamicShadow:SetSize(unpack(physics.shadow))
    local scale = physics.scale
	inst.Transform:SetScale(scale,scale,scale)
    inst.Transform:SetSixFaced()
end
--------------------------------------------------------------------------
-- Pristine Function
--------------------------------------------------------------------------
local function PristineFN(inst)
	inst:AddTag("flippable")
end
--------------------------------------------------------------------------
local mob_values = {
	name_override   = "turtillus",
    physics         = physics,
	physics_init_fn = PhysicsInit,
	pristine_fn     = PristineFN,
	stategraph      = "SGsnortoise",
	brain           = require("brains/snortoisebrain"),
	sounds = {
		step         = sound_path .. "step",
		shell_walk   = sound_path .. "shell_walk",
		taunt        = sound_path .. "taunt",
		grunt        = sound_path .. "grunt",
		hit          = sound_path .. "hit",
		shell_impact = sound_path .. "shell_impact",
		stun         = sound_path .. "stun",
		hide_pre     = sound_path .. "hide_pre",
		hide_pst     = sound_path .. "hide_pst",
		attack1a     = sound_path .. "attack1a",
		attack_pre   = sound_path .. "attack_pre",
		attack1b     = sound_path .. "attack1b",
		attack2_LP   = sound_path .. "attack2_LP",
		death        = sound_path .. "death",
		sleep        = sound_path .. "sleep",
	},
}
--------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.CommonMobFN("turtillus", "lavaarena_turtillus_basic", mob_values, tuning_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
	COMMON_FNS.AddSymbolFollowers(inst, "body", Vector3(20, -400, 0), "medium", {symbol = "body"}, {symbol = "body"})
    ------------------------------------------
    local attacks = {
        spin = {cooldown = tuning_values.SPIN_CD, cooldown_fn = OnSpinCooldownComplete},
    }
    inst.components.combat:AddAttacks(attacks)
	inst.components.combat:SetAreaDamage(tuning_values.HIT_RANGE, 1)
    ------------------------------------------
	inst:AddComponent("item_launcher")
	------------------------------------------
	inst:AddComponent("healthtrigger")
	inst.components.healthtrigger:AddTrigger(tuning_values.SPIN_TRIGGER, SpinTrigger)
	------------------------------------------
	--TODO: Remove this when done
	--inst:AddComponent("attack_radius_display")
	--inst.components.attack_radius_display:AddCircle("melee", tuning_values.ATTACK_RANGE, WEBCOLOURS.YELLOW)
	--inst.components.attack_radius_display:AddCircle("melee_range", tuning_values.HIT_RANGE, WEBCOLOURS.RED)
	--inst.components.attack_radius_display:AddCircle("ranged", tuning_values.SPIN_ATTACK_RANGE, WEBCOLOURS.PURPLE)
    ------------------------------------------
	--MakeLargeBurnableCharacter(inst, "body")
    ------------------------------------------
    return inst
end

return ForgePrefab("snortoise", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/reforged.xml", "snortoise_icon.tex")
