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
local tuning_values = TUNING.FORGE.SCORPEON
local sound_path = "dontstarve/creatures/lava_arena/peghook/"
--------------------------------------------------------------------------
-- Phases (Health Triggers)
--------------------------------------------------------------------------
local function EnragedTrigger(inst)
	inst.components.healthtrigger:RemoveTrigger(tuning_values.ENRAGED_TRIGGER)
	inst.components.combat:SetAttackPeriod(tuning_values.ATTACK_PERIOD_ENRAGED)
	inst.components.combat:ToggleAttack("spit", true)
	inst.sg:GoToState("taunt") -- TODO should this be handled in idle? as in queue it?
end
--------------------------------------------------------------------------
-- Physics Functions
--------------------------------------------------------------------------
local physics = {
	scale  = 0.9,
	mass   = 150,
	radius = 0.8,
	shadow = {3,1.5},
}
local function PhysicsInit(inst)
	MakeCharacterPhysics(inst, physics.mass, physics.radius)
	inst.DynamicShadow:SetSize(unpack(physics.shadow))
	local scale = physics.scale
	inst.Transform:SetScale(scale,scale,scale)
    inst.Transform:SetSixFaced()
end
--------------------------------------------------------------------------
local mob_values = {
	name_override = "peghook",
	physics         = physics,
	physics_init_fn = PhysicsInit,
	stategraph      = "SGscorpeon",
	brain           = require("brains/scorpeonbrain"),
	sounds = {
		taunt     = sound_path .. "taunt",
		grunt     = sound_path .. "grunt",
		step      = sound_path .. "step",
		attack    = sound_path .. "attack",
		spit      = sound_path .. "spit",
		hit       = sound_path .. "hit",
		stun      = sound_path .. "stun",
		bodyfall  = sound_path .. "bodyfall",
		sleep_in  = sound_path .. "sleep_in",
		sleep_out = sound_path .. "sleep_out",
		death     = sound_path .. "death",
	},
}
--------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.CommonMobFN("peghook", "lavaarena_peghook_basic", mob_values, tuning_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	COMMON_FNS.AddSymbolFollowers(inst, "head", nil, "medium", {symbol = "body"}, {symbol = "body"})
	------------------------------------------
	local attacks = {
		spit = {cooldown = tuning_values.SPIT_CD},
	}
	inst.components.combat:AddAttacks(attacks)
	------------------------------------------
	inst:AddComponent("healthtrigger")
	inst.components.healthtrigger:AddTrigger(tuning_values.ENRAGED_TRIGGER, EnragedTrigger)
	------------------------------------------
	inst.acidimmune = true
	------------------------------------------
	--inst:AddComponent("attack_radius_display")
	--inst.components.attack_radius_display:AddCircle("melee", tuning_values.ATTACK_RANGE, WEBCOLOURS.YELLOW)
	--inst.components.attack_radius_display:AddCircle("melee_range", tuning_values.HIT_RANGE, WEBCOLOURS.RED)
	--inst.components.attack_radius_display:AddCircle("ranged", tuning_values.SPIN_ATTACK_RANGE, WEBCOLOURS.PURPLE)
	------------------------------------------
    return inst
end

return ForgePrefab("scorpeon", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/reforged.xml", "scorpeon_icon.tex")
