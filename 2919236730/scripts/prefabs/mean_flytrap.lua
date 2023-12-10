local assets = {
	Asset("ANIM", "anim/venus_flytrap_sm_build.zip"),
	Asset("ANIM", "anim/venus_flytrap_lg_build.zip"),
	Asset("ANIM", "anim/venus_flytrap_build.zip"),
	Asset("ANIM", "anim/venus_flytrap.zip"),
	Asset("SOUND", "sound/hound.fsb"),
}
local prefabs = { -- TODO probably don't need???
	"plantmeat",
	"vine",
	"nectar_pod",
}
local tuning_values = TUNING.FORGE.MEAN_FLYTRAP
local sound_path = "reforge/creatures/venus_flytrap/"
--------------------------------------------------------------------------
-- Pet Functions
--------------------------------------------------------------------------
local MIN_LEVEL = 1
local MAX_LEVEL = 3
-- Returns the current level within the level constraints.
local function GetLevel(inst)
	local level = inst.current_level
	return level < MIN_LEVEL and MIN_LEVEL or level > MAX_LEVEL and MAX_LEVEL or level
end

local function GetSound(inst, sound)
	if sound == "death_pre" then
		return sound_path.."death_pre"
	end
	return sound_path .. inst:GetLevel() .. "/" .. inst.sounds[sound]
end

local scale_per_level = 0.2
local total_frames_per_scale = 4
local builds = {
	"venus_flytrap_sm_build",
	"venus_flytrap_build",
	"venus_flytrap_lg_build",
}
local damage_increase_per_level = 5 / tuning_values.DAMAGE
local health_increase_per_level = 50 / tuning_values.HEALTH
local speed_decrease_per_level = 0.5 / tuning_values.RUNSPEED
local function UpdatePetLevel(inst, level, force_level, instant)
	-- Only level up if the current level will change
	if level and level ~= 0 or force_level and force_level ~= inst.current_level then
		local previous_level = inst.current_level
		inst.current_level = force_level and level or inst.current_level + level
		local new_level = inst:GetLevel() - 1 -- shifted over by 1 for base level calculations

		-- Update Appearance
		inst.build = builds[new_level + 1] -- undid shift for correct index in the build table
		inst.start_scale = 1 + scale_per_level * (previous_level - 1)
		local scale = 1 + scale_per_level * new_level
		inst.inc_scale = (scale - inst.start_scale) / total_frames_per_scale
		if instant then
			inst.components.buffable:AddBuff("pet_level", {{name = "scaler", type = "mult", val = scale}})
        	inst.components.scaler:ApplyScale()
			inst.AnimState:SetBuild(inst.build)
		end

		-- Used for determining run sounds
		if inst.current_level == 1 then
			inst:AddTag("usefastrun")
		else
			inst:RemoveTag("usefastrun")
		end

		-- Update Stats
		inst.components.combat:AddDamageBuff("pet_level", {buff = damage_increase_per_level * new_level + 1}, nil, true) -- TODO double check this
		inst.components.health:AddHealthBuff("pet_level", health_increase_per_level * new_level + 1, "mult")
		CheckFunction("SetMaxHealth", {inst, inst.components.health.maxhealth}, inst.components.follower, "leader", "components", "pethealthbars")
		inst.components.locomotor:SetExternalSpeedMultiplier(inst, "pet_level", speed_decrease_per_level * new_level + 1)
	end
end

local function BecomeAdult(inst)
	COMMON_FNS.Summon("adult_flytrap", inst.components.follower:GetLeader(), inst:GetPosition())
	--adult.Transform:SetPosition(inst.Transform:GetWorldPosition())
	--adult.onSpawn(adult)
	inst:Remove()
end
--------------------------------------------------------------------------
-- Death Functions
--------------------------------------------------------------------------
local function Die(inst)
	if not inst.components.health:IsDead() then
		inst.components.health:Kill()
	end
end
--------------------------------------------------------------------------
-- Physics Functions
--------------------------------------------------------------------------
local physics = {
    scale  = 1,
    mass   = 10,
    radius = 0.5,
    shadow = {2.5,1.5},
}
local function PhysicsInit(inst)
	MakeCharacterPhysics(inst, physics.mass, physics.radius)
	inst.DynamicShadow:SetSize(unpack(physics.shadow))
	inst.Transform:SetFourFaced()
	inst.AnimState:Hide("dirt")
end
--------------------------------------------------------------------------
-- Pristine Function
--------------------------------------------------------------------------
local function PristineFN(inst)
	COMMON_FNS.AddTags(inst, "character", "scarytoprey", "monster", "flying", "flytrap", "hostile", "animal", "usefastrun") -- TODO probably don't need some of these tags?
end
--------------------------------------------------------------------------
local pet_values = {
	anim            = "idle",
	name_override   = "mean_flytrap",
	physics         = physics,
	physics_init_fn = PhysicsInit,
	pristine_fn     = PristineFN,
	stategraph      = "SGflytrap",
	brain           = require("brains/flytrapbrain"),
	sounds = {
		step       = "step",
		taunt      = "taunt",
		breath_in  = "breath_in",
		breath_out = "breath_out",
		attack     = "attack",
		death      = "death",
	},
	combat = true,
	RetargetFn = FORGE_TARGETING.PetRetargetFn,
	KeepTarget = FORGE_TARGETING.PetKeepTarget,
}
--------------------------------------------------------------------------
local function fn(Sim)
	local inst = COMMON_FNS.CommonPetFN("venus_flytrap", "venus_flytrap_sm_build", pet_values, tuning_values)
	------------------------------------------
	if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	inst.current_level = 1
	inst.UpdatePetLevel = UpdatePetLevel
	inst.GetLevel = GetLevel
	inst.GetSound = GetSound
	inst.BecomeAdult = BecomeAdult
	inst.wants_to_become_adult = nil
	inst.death_timer = inst:DoTaskInTime(tuning_values.LIFE_TIME, Die)
	------------------------------------------
	MakeMediumFreezableCharacter(inst, "stem")
	MakeMediumBurnableCharacter(inst, "stem")
	------------------------------------------
	return inst
end
--------------------------------------------------------------------------
return ForgePrefab("mean_flytrap", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/reforged.xml", "pet_seedling.tex")
