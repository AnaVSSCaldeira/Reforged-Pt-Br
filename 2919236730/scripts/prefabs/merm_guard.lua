local assets = {
    Asset("ANIM", "anim/merm_guard_build.zip"),
    Asset("ANIM", "anim/merm_guard_small_build.zip"),
    Asset("ANIM", "anim/merm_guard_transformation.zip"),
    Asset("ANIM", "anim/merm_actions.zip"),
	Asset("SOUND", "sound/merm.fsb"),
}
local prefabs = {
	"merm_splash",
    "merm_spawn_fx",
}
local tuning_values = TUNING.FORGE.MERM_GUARD
local sound_path = "dontstarve/characters/wurt/merm/warrior/"
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

local scale_per_level = 0.1
local builds = {
	"merm_guard_small_build",
	"merm_guard_build",
}
local damage_increase_per_level = 10 / tuning_values.DAMAGE
local health_increase_per_level = 100 / tuning_values.HEALTH
--local speed_decrease_per_level = 0.5
local function UpdatePetLevel(inst, level, force_level)
	-- Only level up if the current level will change
	if level and level ~= 0 or force_level and force_level ~= inst.current_level then
		local previous_level = inst.current_level
		inst.current_level = force_level and level or inst.current_level + level
		local new_level = inst:GetLevel() - 1 -- shifted over by 1 for base level calculations

		-- Update Appearance
		inst.build = builds[new_level + 1] -- undid shift for correct index in the build table
		local scaler = 1 + scale_per_level * new_level
		inst.components.buffable:AddBuff("pet_level", {{name = "scaler", type = "mult", val = scaler}})
        inst.components.scaler:ApplyScale()
		inst.AnimState:SetBuild(inst.build)

		-- Update Stats
		inst.components.combat:AddDamageBuff("pet_level", {buff = damage_increase_per_level * new_level + 1}, nil, true) -- TODO double check this
		inst.components.health:AddHealthBuff("pet_level", health_increase_per_level * new_level + 1, "mult")
		CheckFunction("SetMaxHealth", {inst, inst.components.health.maxhealth}, inst.components.follower, "leader", "components", "pethealthbars")
		--inst.components.locomotor:SetExternalSpeedMultiplier(inst, "pet_level", speed_decrease_per_level * new_level + 1)
	end
end
--------------------------------------------------------------------------
-- Attack Functions
--------------------------------------------------------------------------
-- Target takes more damage from electric attacks and moves slightly slower
local function ApplyWetDebuff(inst)
	inst.components.debuffable:AddDebuff("debuff_wet", "debuff_wet")
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
    mass   = 50,
    radius = 0.5,
    shadow = {1.5,0.75},
}
local function PhysicsInit(inst)
	MakeCharacterPhysics(inst, physics.mass, physics.radius)
    inst.DynamicShadow:SetSize(unpack(physics.shadow))
    inst.Transform:SetFourFaced()
    local scale = physics.scale
    inst.Transform:SetScale(scale,scale,scale)
end
--------------------------------------------------------------------------
-- Pristine Function
--------------------------------------------------------------------------
local function PristineFN(inst)
	COMMON_FNS.AddTags(inst, "character", "merm", "wet", "mermguard", "guard")
end
--------------------------------------------------------------------------
local pet_values = {
	physics         = physics,
	physics_init_fn = PhysicsInit,
	pristine_fn     = PristineFN,
	stategraph      = "SGmermguard",
	brain           = require("brains/flytrapbrain"),
	sounds = {
	    talk   = sound_path .. "talk",
	    buff   = sound_path .. "yell",
	    sleep  = sound_path .. "sleep",
		attack = sound_path .. "attack",
		hit    = sound_path .. "hit",
		death  = sound_path .. "death",
	},
	combat = true,
	RetargetFn = FORGE_TARGETING.PetRetargetFn,
	KeepTarget = FORGE_TARGETING.PetKeepTarget,
}
--------------------------------------------------------------------------
local function fn(Sim)
	local inst = COMMON_FNS.CommonPetFN("pigman", "merm_guard_small_build", pet_values, tuning_values)
	------------------------------------------
	if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	inst.current_level = 1
	inst.UpdatePetLevel = UpdatePetLevel
	inst.GetLevel = GetLevel
	inst.death_timer = inst:DoTaskInTime(tuning_values.LIFE_TIME, Die)
	------------------------------------------
	-- All attacks besides projeciles apply wet debuff
	inst:ListenForEvent("onhitother", function(inst, data)
		if data.target and not data.projectile then
			ApplyWetDebuff(data.target)
		end
	end)
	inst:ListenForEvent("attacked", function(inst, data)
		if data.attacker and not data.projectile then
			ApplyWetDebuff(data.attacker)
		end
	end)
	------------------------------------------
	MakeMediumFreezableCharacter(inst, "stem")
	MakeMediumBurnableCharacter(inst, "stem")
	------------------------------------------
	return inst
end
--------------------------------------------------------------------------
return ForgePrefab("merm_guard", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/reforged.xml", "pet_merm_guard.tex")
