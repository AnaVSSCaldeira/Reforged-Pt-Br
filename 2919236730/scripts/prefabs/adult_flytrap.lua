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
local scale = 1.8
local transition_scale = 1.4
local total_frames_per_scale = 4
local function OnSpawn(inst) -- TODO leaving this here until we figure out spawning anim stuff...
    inst.start_scale = transition_scale/scale
    inst.inc_scale = (scale - transition_scale) / scale / total_frames_per_scale
    inst.components.buffable:AddBuff("transform", {{name = "scaler", type = "mult", val = inst.start_scale}})
    inst.components.scaler:ApplyScale()
    inst.sg:GoToState("grow")
    inst.SoundEmitter:PlaySound(inst.sounds.taunt)
    inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/mole/emerge")
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
        breath_in  = sound_path .. "breath_in",
        breath_out = sound_path .. "breath_out",
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
    OnSpawn(inst)
    inst:ListenForEvent("onhitother", OnHitOther)
    inst.death_timer = inst:DoTaskInTime(tuning_values.LIFE_TIME, Die)
    ------------------------------------------
    return inst
end

return ForgePrefab("adult_flytrap", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/reforged.xml", "pet_snaptooth.tex")
