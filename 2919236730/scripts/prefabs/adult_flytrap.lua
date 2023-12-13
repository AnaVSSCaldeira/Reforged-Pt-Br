local assets = {
    Asset("ANIM", "anim/venus_flytrap_lg_build.zip"),
	Asset("ANIM", "anim/venus_flytrap_planted.zip"),
    Asset("SOUND", "sound/tentacle.fsb"),
    Asset("MINIMAP_IMAGE", "mean_flytrap"),
}
local prefabs = { -- TODO probably not needed?
    "plantmeat",
    "venus_stalk",
    "vine",
    "nectar_pod",
}
local tuning_values = TUNING.FORGE.ADULT_FLYTRAP
local sound_path = "reforge/creatures/venus_flytrap/4/"

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


local scale = 1.8
local transition_scale = 1.3
local total_frames_per_scale = 4
local scale_per_level = 0.05
local function OnSpawn(inst) -- TODO leaving this here until we figure out spawning anim stuff...
    inst.start_scale = transition_scale/scale
    inst.inc_scale = (scale - transition_scale) / scale / total_frames_per_scale
    inst.components.buffable:AddBuff("transform", {{name = "scaler", type = "mult", val = inst.start_scale}})
    inst.components.scaler:ApplyScale()
    inst.sg:GoToState("grow")
    inst.SoundEmitter:PlaySound(inst.sounds.taunt)
    inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/mole/emerge")
end

local damage_increase_per_level = 20 / tuning_values.DAMAGE
local health_increase_per_level = 150 / tuning_values.HEALTH

local function UpdatePetLevel(inst, level, force_level, instant)
	-- Only level up if the current level will change
	if level and level ~= 0 or force_level and force_level ~= inst.current_level then
		local previous_level = inst.current_level
		inst.current_level = force_level and level or inst.current_level + level
		local new_level = inst:GetLevel() - 1 -- shifted over by 1 for base level calculations

		-- Update Appearance
		inst.start_scale = 1 + scale_per_level * (previous_level - 1)
		local scale = 1 + scale_per_level * new_level
		inst.inc_scale = (scale - inst.start_scale) / total_frames_per_scale
		if instant then
			inst.components.buffable:AddBuff("pet_level", {{name = "scaler", type = "mult", val = scale}})
        	inst.components.scaler:ApplyScale()
		end

        -- Update Stats
		inst.components.combat:AddDamageBuff("pet_level", {buff = damage_increase_per_level * new_level + 1}, nil, true) -- TODO double check this
		inst.components.health:AddHealthBuff("pet_level", health_increase_per_level * new_level + 1, "mult")
		CheckFunction("SetMaxHealth", {inst, inst.components.health.maxhealth}, inst.components.follower, "leader", "components", "pethealthbars")
    end
end
--------------------------------------------------------------------------
-- Attack Functions
--------------------------------------------------------------------------
local function OnHitOther(inst, data)
    if data.target then
        FORGE_TARGETING.ForceAggro(data.target, inst, TUNING.FORGE.AGGROTIMER_LUCY)
    end
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
    scale  = 1.8,
    mass   = 0,
    radius = 0.25,
}
local function PhysicsInit(inst)
    MakeObstaclePhysics(inst, physics.radius)
    inst.Transform:SetFourFaced()
    local scale = physics.scale
    inst.Transform:SetScale(scale,scale,scale)
    inst.Transform:SetRotation(math.random(360))
    inst.AnimState:Hide("root")
    inst.AnimState:Hide("leaf")
end
--------------------------------------------------------------------------
-- Pristine Function
--------------------------------------------------------------------------
local function PristineFN(inst)
    COMMON_FNS.AddTags(inst, "character", "scarytoprey", "monster", "flytrap", "hostile", "animal") -- TODO some of these are probably not needed?
end
--------------------------------------------------------------------------
local pet_values = {
    anim            = "idle",
    name_override   = "adult_flytrap",
    physics         = physics,
    physics_init_fn = PhysicsInit,
    pristine_fn     = PristineFN,
    stategraph      = "SGadultflytrap",
    brain           = require("brains/golembrain"), -- TODO create a brain for it, currently uses golems brain
    sounds = {
        taunt      = sound_path .. "taunt",
        breath_in  = sound_path .. "",
        breath_out = sound_path .. "",
        attack_pre = sound_path .. "attack_pre",
        attack     = sound_path .. "attack",
        death_pre  = "reforge/creatures/venus_flytrap/death_pre",
        death      = sound_path .. "death",
    },
    sentry = true,
    combat = true,
    retarget_period = GetRandomWithVariance(2, 0.5), -- TODO base game had this, do we want to change it?
    RetargetFn = FORGE_TARGETING.PetSentryRetargetFn,
    KeepTarget = FORGE_TARGETING.PetSentryKeepTarget,
}
--------------------------------------------------------------------------
local function fn(Sim)
	local inst = COMMON_FNS.CommonPetFN("venus_flytrap_planted", "venus_flytrap_lg_build", pet_values, tuning_values) -- TODO replace name when strings are set
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    inst.current_level = 1
	inst.UpdatePetLevel = UpdatePetLevel
	inst.GetLevel = GetLevel

    OnSpawn(inst)
    inst:ListenForEvent("onhitother", OnHitOther)
    inst.death_timer = inst:DoTaskInTime(tuning_values.LIFE_TIME, Die)
    ------------------------------------------
    return inst
end

return ForgePrefab("adult_flytrap", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/reforged.xml", "pet_snaptooth.tex")
