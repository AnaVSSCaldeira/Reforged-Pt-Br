local fissure_assets = {
    Asset("ANIM", "anim/antlion_sinkhole.zip"),
}
local lava_fissure_assets = {
    Asset("ANIM", "anim/lavaarena_fissure.zip"),
    Asset("ANIM", "anim/deer_fire_burst.zip"),
}
local fissure_prefabs = {
    "deer_fire_burst",
    "antlion_sinkhole",
}
-------------------------------------------------------
local NUM_CRACKING_STAGES = 3
local function UpdateOverrideSymbols(inst, state)
    if state == NUM_CRACKING_STAGES then
        inst.AnimState:ClearOverrideSymbol("cracks1")
        if inst.components.unevenground ~= nil then
            inst.components.unevenground:Enable()
        end
    else
        inst.AnimState:OverrideSymbol("cracks1", "antlion_sinkhole", "cracks_pre"..tostring(state))
        if inst.components.unevenground ~= nil then
            inst.components.unevenground:Disable()
        end
    end
end
--inst.SoundEmitter:PlaySoundWithParams("dontstarve/creatures/together/antlion/sfx/ground_break", { size = math.pow(stage / NUM_CRACKING_STAGES, 2) })

local RANDOM_SEGS = 8
local SEG_ANGLE = 360 / RANDOM_SEGS
local ANGLE_VARIANCE = SEG_ANGLE * 2 / 3
local function GetRandomAngle(inst)
    if inst.angles == nil then
        inst.angles = {}
        local offset = math.random() * 360
        for i = 0, RANDOM_SEGS - 1 do
            table.insert(inst.angles, offset + i * SEG_ANGLE)
        end
    end
    local rnd = math.random()
    rnd = rnd * rnd
    local angle = table.remove(inst.angles, math.max(1, math.ceil(rnd * rnd * RANDOM_SEGS)))
    table.insert(inst.angles, angle)
    return (angle + math.random() * ANGLE_VARIANCE) * DEGREES
end

local function DoBurst(inst, x, z, minr, maxr)
    local fx = COMMON_FNS.CreateFX("deer_fire_burst", nil, inst)
    local theta = GetRandomAngle(inst)
    local rad = GetRandomMinMax(minr, maxr)
    fx.Transform:SetPosition(x + rad * math.cos(theta), 0, z + rad * math.sin(theta))
end

local MAX_TIME_BETWEEN_BURSTS = 60 -- These are FRAMES
local MIN_TIME_BETWEEN_BURSTS = 30
local function OnUpdateLavaFissure(inst, x, z)
    -- Spawn Random Fire Bursts
    inst.burst_delay = (inst.burst_delay or MAX_TIME_BETWEEN_BURSTS) - 1
    if inst.burst_delay < 0 then
        inst.burst_delay = math.random(MIN_TIME_BETWEEN_BURSTS, MAX_TIME_BETWEEN_BURSTS)
        DoBurst(inst, x, z, math.min(1, inst.radius * 0.2), math.max(inst.radius - 0.25, inst.radius * 0.9))
    end

    -- Apply Burn Debuff to any valid ent
    for _,ent in ipairs(TheSim:FindEntities(x, 0, z, inst.radius, nil, inst.exclude_tags)) do
        local debuffable = ent.components.debuffable
        if ent:IsValid() and not (ent.components.health ~= nil and ent.components.health:IsDead()) and debuffable and debuffable:IsEnabled() then
            debuffable:AddDebuff("debuff_fire", "debuff_fire")
            local debuff_fire = debuffable:GetDebuff("debuff_fire")
            if debuff_fire then
                debuff_fire.source = inst.owner
            end
        end
    end
end

local FISSURE_RADIUS = TUNING.ANTLION_SINKHOLE.UNEVENGROUND_RADIUS
local function LavaFissureInit(inst)
    inst.exclude_tags = COMMON_FNS.CommonExcludeTags(inst.owner)
    local x, y, z = inst.Transform:GetWorldPosition()
    inst.radius = FISSURE_RADIUS * inst.components.scaler.scale
    inst.task = inst:DoPeriodicTask(0, OnUpdateLavaFissure, nil, x, z)
    OnUpdateLavaFissure(inst, x, z)
end

local function OnApplyScale(inst, current_scale, scaler)
    inst.components.unevenground.radius = TUNING.ANTLION_SINKHOLE.UNEVENGROUND_RADIUS * scaler
end
-------------------------------------------------------
local function common_pristine_fn(inst)
    inst.entity:AddSoundEmitter()
    ------------------------------------------
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(2)
    inst.Transform:SetEightFaced()
    ------------------------------------------
    COMMON_FNS.AddTags(inst, "antlion_sinkhole", "antlion_sinkhole_blocker", "NOCLICK")
    --inst:SetDeployExtraSpacing(4)
end

local function common_fn(inst)
    ------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    inst:AddComponent("unevenground")
    inst.components.unevenground.radius = TUNING.ANTLION_SINKHOLE.UNEVENGROUND_RADIUS
    ------------------------------------------
    inst:AddComponent("scaler")
    inst.components.scaler.OnApplyScale = OnApplyScale
end

local function fn()
    local inst = COMMON_FNS.BasicEntityInit("sinkhole", "antlion_sinkhole", "idle", {pristine_fn = common_pristine_fn})
    ------------------------------------------
    common_fn(inst)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    return inst
end

local function lava_fn()
    local inst = COMMON_FNS.BasicEntityInit("sinkhole", "lavaarena_fissure", "idle", {pristine_fn = function(inst)
        common_pristine_fn(inst)
        ------------------------------------------
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    end})
    ------------------------------------------
    common_fn(inst)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    inst.SetOwner = function(inst, owner)
        inst.owner = owner
        LavaFissureInit(inst)
    end
    ------------------------------------------
    return inst
end

return Prefab("fissure", fn, fissure_assets, fissure_prefabs),
    Prefab("lava_fissure", lava_fn, lava_fissure_assets, fissure_prefabs)
