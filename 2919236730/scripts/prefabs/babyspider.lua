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
ToDo
	with 2 pitpigs I attacked one then the other and then I attack the first one again. This caused the baby spiders to stop attacking and do nothing...interesting
	when attacking a different target do the spiders always taunt?
		need to watch vid of multitargeting as webber for the 2 instances above
--]]
local assets = {}
local prefabs = {
	"die_fx",
}
local tuning_values = TUNING.FORGE.BABYSPIDER
local sound_path = "dontstarve/creatures/lava_arena/baby_spider/"
--------------------------------------------------------------------------
-- Behavior Functions
--------------------------------------------------------------------------
local function ShouldWakeUp(inst)
    return inst.components.follower.leader and not inst.components.follower.leader.components.health:IsDead()
end

local function ShouldSleep(inst)
    return inst.components.follower.leader == nil or inst.components.follower.leader.components.health:IsDead()
end
--------------------------------------------------------------------------
-- Pet Functions
--------------------------------------------------------------------------
local function UpdatePetLevel(inst, level, force_level)
	-- Only level up if the current level will change
	if level and level ~= 0 or force_level and force_level ~= inst.current_level then
		inst.current_level = force_level and level or inst.current_level + level
		-- Update Attack
        inst.components.combat:AddDamageBuff("pet_level", {buff = inst.current_level}, nil, true) -- TODO double check this
		inst.components.combat:SetAttackPeriod(inst.current_level > 1 and 0 or tuning_values.ATTACK_PERIOD) -- TODO is this attack period correct? 0 for level 2 spiders?
		-- Update Appearance
		inst.AnimState:SetBuild(inst.current_level > 1 and "spider_warrior_lavaarena_build" or "spider_build") -- TODO could create a build table so each level has a different build assigned to it
	end
end
--------------------------------------------------------------------------
-- Physics Functions
--------------------------------------------------------------------------
local SCALE = .5
local physics = {
    scale  = 0.5,
    mass   = 10,
    radius = 0.2,
    shadow = {1.5 * 0.5, 0.25 * 0.5},
}
local function PhysicsInit(inst)
	MakeCharacterPhysics(inst, physics.mass, physics.radius)
    inst.DynamicShadow:SetSize(unpack(physics.shadow))
    local scale = physics.scale
    inst.Transform:SetScale(scale,scale,scale)
    inst.Transform:SetFourFaced()
end
--------------------------------------------------------------------------
-- Pristine Function
--------------------------------------------------------------------------
local function PristineFN(inst)
	COMMON_FNS.AddTags(inst, "spider", "notarget")
	------------------------------------------
	inst.ForgeOnSpawn = function(self)
		local fx = _G.SpawnPrefab("die_fx")
		fx.Transform:SetScale(0.5, 0.5, 0.5)
		fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	end
end
--------------------------------------------------------------------------
local pet_values = {
	name_override   = "webber_spider_minion",
    physics         = physics,
	physics_init_fn = PhysicsInit,
	pristine_fn     = PristineFN,
	stategraph      = "SGbabyspider",
	brain           = require("brains/babyspiderbrain"),
	sounds = {
		walk         = sound_path .. "walk_spider",
		attack       = sound_path .. "Attack",
		attack_grunt = sound_path .. "attack_grunt",
		scream       = sound_path .. "scream",
		fall_asleep  = sound_path .. "fallAsleep",
		sleeping     = sound_path .. "sleeping",
		wake_up      = sound_path .. "wakeUp",
		hit          = sound_path .. "hit",
		death        = sound_path .. "die",
	},
	tags = {}, -- TODO
	combat = true,
	RetargetFn = FORGE_TARGETING.PetRetargetFn,
	KeepTarget = FORGE_TARGETING.PetKeepTarget,
}
--------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.CommonPetFN("spider", "spider_build", pet_values, tuning_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
	inst.acidimmune = true
	------------------------------------------
	inst.current_level = 1
	inst.UpdatePetLevel = UpdatePetLevel
	------------------------------------------
	inst.components.health:SetInvincible(true)
	------------------------------------------
	inst.components.combat:SetRange(tuning_values.ATTACK_RANGE * SCALE)
	------------------------------------------
    inst:AddComponent("sleeper")
    inst.components.sleeper.testperiod = GetRandomWithVariance(2, 1)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWakeUp)
	------------------------------------------
    return inst
end

return ForgePrefab("babyspider", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/reforged.xml", "pet_babyspider.tex")
