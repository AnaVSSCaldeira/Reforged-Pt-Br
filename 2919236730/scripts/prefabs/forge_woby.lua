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
	Asset("ANIM", "anim/pupington_build.zip"),
    Asset("ANIM", "anim/pupington_basic.zip"),
    Asset("ANIM", "anim/pupington_emotes.zip"),
    Asset("ANIM", "anim/pupington_traits.zip"),
    Asset("ANIM", "anim/pupington_jump.zip"),

    Asset("ANIM", "anim/pupington_woby_build.zip"),
    Asset("ANIM", "anim/pupington_transform.zip"),
    Asset("ANIM", "anim/woby_big_build.zip"),
}

local fx_assets = {
	Asset("ANIM", "anim/trinket_echoes_fx.zip"),
}

local prefabs = {
	"die_fx",
}
local tuning_values = TUNING.FORGE.WOBY
local woby_cooldown = TUNING.FORGE.WOBY.BUFF_COOLDOWN
local woby_duration = TUNING.FORGE.WOBY.BUFF_DURATION
local woby_range = TUNING.FORGE.WOBY.BUFF_RANGE
local sound_path = "dontstarve/creatures/together/pupington/"
--------------------------------------------------------------------------
-- Behavior Functions
--------------------------------------------------------------------------
local function ShouldWakeUp(inst)
    return inst.components.follower.leader and not inst.components.follower.leader.components.health:IsDead()
end

local function ShouldSleep(inst)
    return inst.components.follower.leader == nil or inst.components.follower.leader.components.health:IsDead()
end

local function GetPeepChance(inst)
    return 0
end

local function IsAffectionate(inst)
    return true
end

local function IsPlayful(inst)
	return true
end

local function IsSuperCute(inst)
	return true
end
--------------------------------------------------------------------------
-- Pet Functions
--------------------------------------------------------------------------
local function SetBuffActive(inst, val)
	inst.buff_ready = val
	if val then
		inst:SpawnChild("forge_woby_power_fx")
		inst:RemoveTag("NOCLICK")
	else
		inst:AddTag("NOCLICK")
	end
end

local function BuffAllies(inst)
	local pos = inst:GetPosition()
	local ents = TheSim:FindEntities(pos.x, 0, pos.z, woby_range, {"_combat", "player"}, {"notarget", "playerghost", "INLIMBO"})
	for i, v in ipairs(ents) do
		if v:IsValid() and v.components.health and not v.components.health:IsDead() and v.components.debuffable then
			v.components.debuffable:AddDebuff("buff_woby", "buff_woby")
		end
	end
	if next(ents) then
		inst.SoundEmitter:PlaySound("dontstarve/creatures/together/clayhound/howl")
	end
	inst:SetBuffActive(false)
	inst:DoTaskInTime(woby_cooldown, function(inst)
		inst:SetBuffActive(true)
	end)
end

local function UpdatePetLevel(inst, level, force_level)
    -- Only level up if the current level will change
    if level and level ~= 0 or force_level and level ~= inst.current_level then
        inst.current_level = force_level and level or inst.current_level + level
        -- Update Size
        local s = 1 + ((inst.current_level - 1)*(SCALE/5)) -- TODO need better equation, check if scaling values are correct, 1 and 1.2? it might be a 30% increase for all pets, but I can't tell if baby spiders change size or not
        inst.components.buffable:AddBuff("pet_level", {{name = "scaler", type = "mult", val = s}})
        inst.components.scaler:ApplyScale()
        inst:SetHairStyle(inst.current_level > 1 and 2 or 1)
		-- Update Stats
		woby_range = 18
		woby_duration = 30
        woby_cooldown = 38
    end
end
--------------------------------------------------------------------------
-- Physics Functions
--------------------------------------------------------------------------
local physics = {
    scale  = 1,
    mass   = 1,
    radius = 0.5,
    shadow = {1,0.33},
}
local function PhysicsInit(inst)
	MakeCharacterPhysics(inst, physics.mass, physics.radius)
	inst.DynamicShadow:SetSize(unpack(physics.shadow))
    inst.Transform:SetFourFaced()
end
--------------------------------------------------------------------------
-- Pristine Function
--------------------------------------------------------------------------
local function PristineFN(inst)
	COMMON_FNS.AddTags(inst, "woby", "notarget", "specialnoclick")
	------------------------------------------
	inst.ForgeOnSpawn = function(self)
		SpawnAt("die_fx", inst)
	end
end
--------------------------------------------------------------------------
local pet_values = {
	name_override   = "wobysmall",
    physics         = physics,
	physics_init_fn = PhysicsInit,
	pristine_fn     = PristineFN,
	stategraph      = "SGwobysmall_forge", --Need to set certain variables first before using woby's SG to prevent crashing.
	brain           = require("brains/woby_forgebrain"),
	sounds = {
		pant         = sound_path .. "pant",
		tail         = sound_path .. "tail",
		scratch      = sound_path .. "emote_scratch",
		bark		 = "dontstarve/characters/walter/woby/small/bark",
		growl        = sound_path .. "growl",
		eat			 = "dontstarve/characters/walter/woby/small/eat",
		sleep        = sound_path .. "sleep",
		stallion	 = "dontstarve/creatures/together/sheepington/stallion",
		transform	 = "dontstarve/characters/walter/woby/transform_small_to_big",
		roar		 = "dontstarve/characters/walter/woby/big/roar",

	},
	tags = {}, -- TODO
}
--------------------------------------------------------------------------
local function fx()
    local inst = CreateEntity()
	------------------------------------------
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
	------------------------------------------
    inst.AnimState:SetBank("trinket_echoes")
    inst.AnimState:SetBuild("trinket_echoes_fx")
    inst.AnimState:PlayAnimation("idle"..math.random(1, 3), true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(1)
    inst.AnimState:SetFinalOffset(2)
	inst.AnimState:SetDeltaTimeMultiplier(1.25)
	inst.AnimState:SetLightOverride(1)
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	------------------------------------------
	inst.entity:SetPristine()
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	inst.persists = false
	inst.entity:SetCanSleep(false)
	------------------------------------------
    inst:ListenForEvent("animover", inst.Remove)
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.CommonPetFN("pupington", "pupington_woby_build", pet_values, tuning_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	inst.current_level = 1
	inst.UpdatePetLevel = UpdatePetLevel
    ------------------------------------------
	inst.acidimmune = true
	inst.buff_ready = false
	------------------------------------------
	inst:DoTaskInTime(woby_cooldown, function(inst) --Antes o woby_cooldown era tuning_values.BUFF_COOLDOWN
		inst:SetBuffActive(true)
	end)
	------------------------------------------
	--inst.current_level = 1
	--inst.UpdatePetLevel = UpdatePetLevel
	inst:AddComponent("timer") --required for crittertraits apparently
	inst:AddComponent("crittertraits")
	------------------------------------------
	inst.components.health:SetInvincible(true)
	------------------------------------------
    inst:AddComponent("sleeper")
    inst.components.sleeper.testperiod = GetRandomWithVariance(2, 1)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWakeUp)
	------------------------------------------
	inst.SetBuffActive = SetBuffActive
	inst.BuffAllies = BuffAllies
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
return ForgePrefab("forge_woby", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/reforged.xml", "pet_woby.tex"),
	   Prefab("forge_woby_power_fx", fx, fx_assets)
