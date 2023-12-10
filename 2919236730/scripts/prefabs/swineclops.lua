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
local tuning_values = TUNING.FORGE.SWINECLOPS
local sound_path = "dontstarve/forge2/beetletaur/"
--------------------------------------------------------------------------
-- Attack Functions
--------------------------------------------------------------------------
-- Apply knockback to all hits
local function OnHitOther(inst, target)
	if inst.sg:HasStateTag("slamming") or inst.sg:HasStateTag("knockback") then -- TODO uppercut should be checked here as well (gave it the knockback tag), different knockback value?
        COMMON_FNS.KnockbackOnHit(inst, target, 5, tuning_values.ATTACK_KNOCKBACK) -- TODO tuning
    end
end

local function ShouldGuard(inst)
    return inst.sg.mem.wants_to_guard or not (inst.modes.attack or inst.components.combat:IsAttackActive("guard"))
end

local function ShouldBreakGuard(inst)
    return inst.components.combat:IsAttackActive("guard") and not inst.components.combat:InCooldown("guard") and inst.modes.attack
end

-- Triggers Guard Mode if Swineclops takes a set amount of damage while in Attack Mode.
local function UnguardedDamageTracker(inst, data)
    if inst.modes.guard then
        inst.total_unguarded_damage = (inst.total_unguarded_damage or 0) + data.damageresolved
        if inst.total_unguarded_damage >= tuning_values.GUARD_DAMAGE_TRIGGER then
            inst.sg.mem.wants_to_guard = true
        end
    end
end

local function EnterGuardMode(inst)
    inst._bufftype:set(1)
    inst.components.combat:ToggleAttack("guard", true)
    inst.hit_recovery = tuning_values.GUARD_HIT_RECOVERY
    inst.components.combat:RemoveDamageBuff("swineclops_battlecry_buff")
    inst.components.combat:AddDamageBuff("swineclops_guard_mode_buff", tuning_values.GUARD_BUFF, true)
    inst.components.combat.ignorehitrange = false
    inst.components.combat:SetAttackPeriod(tuning_values.ATTACK_GUARD_PERIOD)
    inst.components.combat:SetHurtSound("dontstarve/creatures/lava_arena/boarrior/bonehit2")
    inst.components.combat.battlecryenabled = false -- Taunts are not available in Guard Mode
    inst.sg.mem.wants_to_slam = nil -- Reset wants to slam so Swineclops does not immediately Body Slam after entering Guard.
    -- Only start Guard timer if Attack Mode is available
    if inst.modes.attack then -- TODO better spot
        inst.components.combat:StartCooldown("guard")
    end
    inst:RemoveEventCallback("attacked", UnguardedDamageTracker)
end

local function BreakGuard(inst)
    inst._bufftype:set(0)
    inst.components.combat:CancelCooldown("guard")
    inst.components.combat:ToggleAttack("guard", false)
    inst.hit_recovery = nil
    inst.components.combat:RemoveDamageBuff("swineclops_guard_mode_buff", true)
    inst.components.combat.ignorehitrange = true
    inst.components.combat:SetAttackPeriod(tuning_values.ATTACK_PERIOD)
    inst.components.combat:SetHurtSound(nil)
    inst.components.combat.battlecryenabled = false--true -- no longer in Guard Mode so taunts are available
    inst.total_unguarded_damage = 0
    inst:ListenForEvent("attacked", UnguardedDamageTracker)
end
--------------------------------------------------------------------------
local function CreateBreakFX()
    local inst = CreateEntity()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    inst.AnimState:SetBank("beetletaur_break")
    inst.AnimState:SetBuild("lavaarena_beetletaur_break")
    inst.AnimState:PlayAnimation("anim")
    inst.AnimState:SetFinalOffset(2)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst:ListenForEvent("animover", inst.Remove)

    return inst
end

local function KillPulseFX(inst)
    if inst.task ~= nil then
        inst:Remove()
    else
        inst.killed = true
    end
end

local function OnPulseDelay(inst, anim)
    inst.task = nil
    inst.AnimState:PlayAnimation(anim or (inst.bufftype == 1 and "defend_fx" or "attack_fx3"))
end

local function OnPulseAnimOver(inst)
    if inst.killed then
        inst:Remove()
    else
        if inst.task ~= nil then
            inst.task:Cancel()
        end
        inst.task = inst:DoTaskInTime(1, OnPulseDelay)
    end
end

local function CreatePulse(bufftype)
    local inst = CreateEntity()
    ------------------------------------------
    inst:AddTag("DECOR") --"FX" will catch mouseover
    inst:AddTag("NOCLICK")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false
    ------------------------------------------
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.AnimState:SetBank("lavaarena_beetletaur_fx")
    inst.AnimState:SetBuild("lavaarena_beetletaur_fx")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    ------------------------------------------
    inst.task = nil
    inst.bufftype = bufftype
    inst.KillFX = KillPulseFX
    ------------------------------------------
    inst:ListenForEvent("animover", OnPulseAnimOver)
    if bufftype == 1 then
        inst.task = inst:DoTaskInTime(4*FRAMES, OnPulseDelay, "defend_fx_pre")
    else
        inst.AnimState:PlayAnimation("attack_fx3_pre")
    end
    ------------------------------------------
    return inst
end

local function OnBuffTypeDirty(inst)
    --Dedicated server does not need to spawn the local fx
    if not TheNet:IsDedicated() and (inst.buff_fx and inst.buff_fx.bufftype or 0) ~= inst._bufftype:value() then
        -- Remove old FX
        if inst.buff_fx then
            -- Break Guard FX
            if inst.buff_fx.bufftype == 1 then
                local fx = CreateBreakFX()
                fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
                fx.SoundEmitter:PlaySound("dontstarve/creatures/slurtle/shatter")
            end
            inst.buff_fx:KillFX()
            inst.buff_fx = nil
        end
        -- Create new FX
        if inst._bufftype:value() == 1 or inst._bufftype:value() == 2 then
            inst.buff_fx = CreatePulse(inst._bufftype:value())
            inst.buff_fx.entity:SetParent(inst.entity)
        end
    end
end
--------------------------------------------------------------------------
-- Camera Functions
--------------------------------------------------------------------------
local function OnCameraFocusDirty(inst)
    if inst._camerafocus:value() then
        if inst:HasTag("NOCLICK") then
            --death
            TheFocalPoint.components.focalpoint:StartFocusSource(inst, nil, nil, 6, 22, 3)
        else
            --pose
            TheFocalPoint.components.focalpoint:StartFocusSource(inst, nil, nil, 60, 60, 3)
            TheCamera:SetDistance(30)
            TheCamera:SetControllable(false)
        end
    else
        TheFocalPoint.components.focalpoint:StopFocusSource(inst)
        TheCamera:SetControllable(true)
    end
end

local function EnableCameraFocus(inst, enable)
    if enable ~= inst._camerafocus:value() then
        inst._camerafocus:set(enable)
        if not TheNet:IsDedicated() then
            OnCameraFocusDirty(inst)
        end
    end
end
--------------------------------------------------------------------------
-- Pose Functions
--------------------------------------------------------------------------
local function CreateFlower()
    local inst = CreateEntity()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("healing_flower")
    inst.AnimState:SetBuild("healing_flower")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:Hide("shadow")

    return inst
end

local function OnFlowerHitGround(flower)
    flower.AnimState:Show("shadow")
    flower.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt", nil, .35)
end

local function CheckPose(flower, inst)
    if not (inst:IsValid() and inst.AnimState:IsCurrentAnimation("end_pose_loop")) then
        ErodeAway(flower, 1)
    end
end

local function OnSpawnFlower(inst)
    local flower = CreateFlower()
    local x, y, z = inst.Transform:GetWorldPosition()
    local vec = TheCamera:GetRightVec()
    flower.Physics:Teleport(x, 7, z)
    flower.Physics:SetVel(vec.x * 5, 20, vec.z * 5)
    flower:DoTaskInTime(1.23, OnFlowerHitGround)
    flower:DoPeriodicTask(.5, CheckPose, nil, inst)
end
--------------------------------------------------------------------------
-- Phases (Health Triggers)
--------------------------------------------------------------------------
local function AttackModeTrigger(inst)
    inst.components.healthtrigger:RemoveTrigger(tuning_values.ATTACK_MODE_TRIGGER)
    inst.modes.guard = false
    inst.modes.attack = true -- TODO need to reset triggers? or maybe they will start updating once this is set to true?
    inst.components.combat:SetAttackOptions("combo", {max = 2})
    inst.components.combat:ToggleAttack("tantrum", true)
    -- TODO better way? need to make all guard triggers available at this point
    inst.components.combat:StartCooldown("guard")
end

local function AttackAndGuardModeTrigger(inst)
    inst.components.healthtrigger:RemoveTrigger(tuning_values.ATTACK_AND_GUARD_MODE_TRIGGER)
    inst.modes.guard = true
    inst.components.combat:ToggleAttack("uppercut", true)
    inst.components.combat:ToggleAttack("buff", true)
    COMMON_FNS.ForceTaunt(inst)
end

local function Combo2Trigger(inst)
    inst.components.healthtrigger:RemoveTrigger(tuning_values.COMBO_2_TRIGGER)
    inst.components.combat:SetAttackOptions("combo", {max = 4})
end

local function InfiniteComboTrigger(inst)
    inst.components.healthtrigger:RemoveTrigger(tuning_values.INFINITE_COMBO_TRIGGER)
    inst.components.combat:SetAttackOptions("combo", {max = 999}) -- TODO what should the infinite value be? Or should there be another variable for inst.infinite_combo???
end
--------------------------------------------------------------------------
-- Physics Functions
--------------------------------------------------------------------------
local physics = {
    scale  = 1.05,
    mass   = 500,
    radius = 1.75,
    shadow = {4.5,2.25},
}
local function PhysicsInit(inst)
	inst:SetPhysicsRadiusOverride(physics.radius)
    MakeCharacterPhysics(inst, physics.mass, physics.radius)
    inst.Transform:SetFourFaced()
    local scale = physics.scale
    inst.Transform:SetScale(scale,scale,scale)
	inst.DynamicShadow:SetSize(unpack(physics.shadow))
end
--------------------------------------------------------------------------
-- Pristine Function
--------------------------------------------------------------------------
local function PristineFN(inst)
    COMMON_FNS.AddTags(inst, "largecreature", "epic")
    ------------------------------------------
    inst._bufftype    = net_tinybyte(inst.GUID, "beetletaur._bufftype", "bufftypedirty") -- 0:none, 1:defense, 2:attack
    inst._camerafocus = net_bool(inst.GUID, "beetletaur._camerafocus", "camerafocusdirty")
    inst._spawnflower = net_event(inst.GUID, "beetletaur._spawnflower")
    inst:ListenForEvent("beetletaur._spawnflower", OnSpawnFlower)
    ------------------------------------------
    if not TheNet:IsDedicated() then -- TODO is this needed in all the other prefabs too then?
        inst:ListenForEvent("bufftypedirty", OnBuffTypeDirty)
    end
end
--------------------------------------------------------------------------
local mob_values = {
    name_override   = "beetletaur",
    physics         = physics,
	physics_init_fn = PhysicsInit,
    pristine_fn     = PristineFN,
	stategraph      = "SGswineclops",
	brain           = require("brains/swineclopsbrain"),
	sounds = {
		taunt     = sound_path .. "taunt",
		hit       = sound_path .. "hit",
		hit_2     = sound_path .. "chain_hit",
		stun      = sound_path .. "grunt",
		attack    = sound_path .. "attack",
		sleep_in  = sound_path .. "sleep_in",
		sleep_out = sound_path .. "sleep_out",
        step      = sound_path .. "step",
        swipe     = sound_path .. "swipe",
        jump      = sound_path .. "jump",
	},
}
--------------------------------------------------------------------------
local function fn()
    local inst = COMMON_FNS.CommonMobFN("beetletaur", "lavaarena_beetletaur", mob_values, tuning_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        inst:ListenForEvent("camerafocusdirty", OnCameraFocusDirty) -- TODO should this be in non dedicated or non server?
        return inst
    end
	------------------------------------------
	COMMON_FNS.AddSymbolFollowers(inst, "head", nil, "large", {symbol = "body"}, {symbol = "body"})
	------------------------------------------
	COMMON_FNS.SetupBossFade(inst, 7)
	inst.EnableCameraFocus = EnableCameraFocus
	inst.OnSpawnFlower = OnSpawnFlower
    ------------------------------------------
    local attacks = { -- TODO add all of swineclops attacks?
        body_slam = {active = true, cooldown = tuning_values.BODY_SLAM_CD},
        combo     = {active = true, opts = {max = 0}},
        uppercut  = {active = false},
        tantrum   = {active = false},
        buff      = {active = false},
        guard     = {active = false, cooldown = tuning_values.GUARD_TIME, opts = {ShouldGuard = ShouldGuard, ShouldBreakGuard = ShouldBreakGuard, EnterGuardMode = EnterGuardMode, BreakGuard = BreakGuard}},
    }
    inst.components.combat:AddAttacks(attacks)
	------------------------------------------
    inst.modes = {attack = false, guard = true}
    inst.attack_body_slam_ready = true -- TODO remove once FF swine has been updated
    inst.is_guarding = false -- TODO remove once FF swine has been updated
    inst.avoid_heal_auras = true
	------------------------------------------
	inst:AddComponent("healthtrigger")
    inst.components.healthtrigger:AddTrigger(tuning_values.ATTACK_MODE_TRIGGER, AttackModeTrigger)
    inst.components.healthtrigger:AddTrigger(tuning_values.ATTACK_AND_GUARD_MODE_TRIGGER, AttackAndGuardModeTrigger)
    inst.components.healthtrigger:AddTrigger(tuning_values.COMBO_2_TRIGGER, Combo2Trigger)
    inst.components.healthtrigger:AddTrigger(tuning_values.INFINITE_COMBO_TRIGGER, InfiniteComboTrigger)
	------------------------------------------
	inst.recentlycharged = {}
    inst.Physics:SetCollisionCallback(COMMON_FNS.OnCollideDestroyObject)
	------------------------------------------
	inst.components.combat.battlecryenabled = false -- TODO should this be true initially???
	inst.components.combat.onhitotherfn = OnHitOther
	------------------------------------------
    MakeHauntablePanic(inst) -- TODO
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
local function MakeFossilizedBreakFX(anim, side, interrupted)
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        inst:AddTag("FX")
        inst.Transform:SetFourFaced()
        ------------------------------------------
        --Leave this out of pristine state to force animstate to be dirty later
        --inst.AnimState:SetBank("beetletaur")
        inst.AnimState:SetBuild("fossilized")
        inst.AnimState:PlayAnimation(anim)
        ------------------------------------------
        if not interrupted then
            inst.AnimState:OverrideSymbol("rock", "lavaarena_beetletaur", "rock")
            inst.AnimState:OverrideSymbol("rock2", "lavaarena_beetletaur", "rock2")
        end
        ------------------------------------------
        if side:len() > 0 then
            inst.AnimState:Hide(side == "right" and "fx_lavarock_L" or "fx_lavarock_R")
        end
        ------------------------------------------
        inst.entity:SetPristine()
        ------------------------------------------
        if not TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------
        inst.persists = false
        inst:ListenForEvent("animover", ErodeAway)
        ------------------------------------------
        return inst
    end

    return Prefab("beetletaur_"..anim..(side:len() > 0 and ("_"..side) or "")..(interrupted and "_alt" or ""), fn, assets)
end
--------------------------------------------------------------------------
return ForgePrefab("swineclops", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/reforged.xml", "swineclops_icon.tex"),
    MakeFossilizedBreakFX("fossilized_break_fx", "right", false),
    MakeFossilizedBreakFX("fossilized_break_fx", "left", false),
    MakeFossilizedBreakFX("fossilized_break_fx", "left", true),
    MakeFossilizedBreakFX("fossilized_break_fx", "", true)
