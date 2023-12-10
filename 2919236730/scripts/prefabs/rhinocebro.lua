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
local tuning_values = TUNING.FORGE.RHINOCEBRO
local sound_path = "dontstarve/forge2/rhino_drill/"
--------------------------------------------------------------------------
-- Attack Functions
--------------------------------------------------------------------------
local function DoPulse(inst)
    inst.task = nil
    if inst.level > 0 then
        inst:Show()
        inst.AnimState:PlayAnimation("attack_fx3")
    else
        inst:Remove()
    end
end

local function OnPulseAnimOver(inst)
    RemoveTask(inst.task)
    if inst.level >= 7 then
        inst.AnimState:PlayAnimation("attack_fx3")
    elseif inst.level > 0 then
        inst.task = inst:DoTaskInTime(3.5 - inst.level * .5, DoPulse)
        inst:Hide()
    else
        inst:Remove()
    end
end

local function CreatePulse()
    local inst = CreateEntity()
    inst:AddTag("DECOR") --"FX" will catch mouseover
    inst:AddTag("NOCLICK")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false
    ------------------------------------------
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    ------------------------------------------
    inst.AnimState:SetBank("lavaarena_battlestandard")
    inst.AnimState:SetBuild("lavaarena_battlestandard")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    ------------------------------------------
    inst:Hide()
    inst.level = 0
    inst.task = inst:DoTaskInTime(1, DoPulse)
    inst:ListenForEvent("animover", OnPulseAnimOver)
    ------------------------------------------
    return inst
end

local function OnBuffLevelDirty(inst)
    --Dedicated server does not need to spawn the local fx
    if not TheNet:IsDedicated() then
        -- Continuous Buff FX
        if inst.buff_fx ~= nil then
            inst.buff_fx.level = 0
            inst.buff_fx = nil
        end
        RemoveTask(inst.buff_fx)
        if inst._bufflevel:value() > 0 then
            inst.buff_fx = CreatePulse()
            inst.buff_fx.entity:SetParent(inst.entity)
            inst.buff_fx.level = inst._bufflevel:value()
        end
        -- Buff Icon
        local fx = SpawnPrefab("rhinocebro_buff_fx")
        fx.entity:SetParent(inst.entity)
        fx.entity:AddFollower()
        fx.Follower:FollowSymbol(inst.GUID, "head", 0, 0, 0)
        fx.Transform:SetPosition(0, 0, 0)
    end
end

local function SetBuffLevel(inst, level)
    level = math.clamp(level, 0, tuning_values.MAX_BUFFS)
    inst.bro_stacks = level
    if inst._bufflevel:value() ~= level then -- TODO is it possible for the value to be corrupt? due to size limit?
        -- Update damage buff
        inst.components.combat:RemoveDamageBuff("rhinocebro_buff", false)
        inst.components.combat:AddDamageBuff("rhinocebro_buff", 1 + (tuning_values.BUFF_DAMAGE_INCREASE * inst.bro_stacks) / tuning_values.DAMAGE, false)
        inst._bufflevel:set(level)
        OnBuffLevelDirty(inst)
    end
end

-- Apply Knockback to "charging" hits
local function OnHitOther(inst, target)
    if inst.sg:HasStateTag("charging") then
        COMMON_FNS.KnockbackOnHit(inst, target, 2, tuning_values.ATTACK_KNOCKBACK) -- TODO tuning
    end
end
--------------------------------------------------------------------------
-- Phases (Health Triggers)
--------------------------------------------------------------------------
local function DamagedTrigger(inst)
    inst.components.healthtrigger:RemoveTrigger(tuning_values.DAMAGED_TRIGGER)
    inst.AnimState:AddOverrideBuild("lavaarena_rhinodrill_damaged" .. inst.damagedtype)
end
--------------------------------------------------------------------------
-- Death Functions
--------------------------------------------------------------------------
local function IsTrueDeath(inst)
	return inst.bro and inst.bro.components.health and inst.bro.components.health:IsDead() or inst.bro == nil
end

local function OnDeath(inst)
    if not inst:IsTrueDeath() then
        inst:ListenForEvent("mob_death", inst.TrueDeathCheck, TheWorld)
    end
end

local function CanBeRevivedBy(inst, reviver)
    return not reviver:HasTag("player") and reviver:HasTag("LA_mob")
end
--------------------------------------------------------------------------
-- Physics Functions
--------------------------------------------------------------------------
local physics = {
    scale  = 1.15,
    mass   = 400,
    radius = 1,
    shadow = {2.75,1.25},
}
local function PhysicsInit(inst)
	inst:SetPhysicsRadiusOverride(physics.radius)
	MakeCharacterPhysics(inst, physics.mass, physics.radius)
	inst.DynamicShadow:SetSize(unpack(physics.shadow))
    inst.Transform:SetSixFaced()
    local scale = physics.scale
    inst.Transform:SetScale(scale,scale,scale)
end
--------------------------------------------------------------------------
local mob_values = {
    name_override   = "rhinodrill",
    physics         = physics,
	physics_init_fn = PhysicsInit,
	stategraph      = "SGrhinocebro",
	brain           = require("brains/rhinocebrobrain"),
	sounds = {
		cheer             = sound_path .. "cheer",
		taunt             = sound_path .. "taunt",
		grunt             = sound_path .. "grunt",
		hit               = sound_path .. "hit",
		attack            = sound_path .. "attack",
		attack_2          = sound_path .. "attack_2",
		death             = sound_path .. "death",
		death_final       = sound_path .. "death_final",
		death_final_final = sound_path .. "death_final_final",
		revive_lp         = sound_path .. "revive_LP",
		sleep_pre         = sound_path .. "sleep_pre",
		sleep_in          = sound_path .. "sleep_in",
		sleep_out         = sound_path .. "sleep_out",
		bodyfall		  = "dontstarve/movement/bodyfall_dirt",
	},
}
--------------------------------------------------------------------------
local function fn(sim, alt)
    mob_values.pristine_fn = function(inst)
        inst.AnimState:OverrideSymbol("fx_wipe", "wilson_fx", "fx_wipe")
        if alt then
            inst.AnimState:AddOverrideBuild("lavaarena_rhinodrill_clothed_b_build")
        end
        ------------------------------------------
        COMMON_FNS.AddTags(inst, "largecreature")
        ------------------------------------------
        inst:AddComponent("revivablecorpse")
        inst.components.revivablecorpse:SetCanBeRevivedByFn(CanBeRevivedBy)
        inst.components.revivablecorpse:SetBaseReviveHealthPercent(1)
        inst.components.revivablecorpse:SetReviveHealthPercent(1)
        inst.components.revivablecorpse:SetReviveSpeedMult(0.5)
        ------------------------------------------
        inst._bufflevel = net_tinybyte(inst.GUID, "rhinodrill._bufflevel", "buffleveldirty")
        inst.displaynamefn = function(inst)
            return STRINGS.NAMES[string.upper(alt and "rhinodrill2" or "rhinodrill")]
        end
    end
    ------------------------------------------
	local inst = COMMON_FNS.CommonMobFN("rhinodrill", "lavaarena_rhinodrill_basic", mob_values, tuning_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        inst:ListenForEvent("buffleveldirty", OnBuffLevelDirty)
        --inst:ListenForEvent("camerafocusdirty", OnCameraFocusDirty) -- TODO
        return inst
    end
    ------------------------------------------
    COMMON_FNS.AddSymbolFollowers(inst, "head", nil, "medium", {symbol = "body"}, {symbol = "body"})
    ------------------------------------------
    inst.IsTrueDeath = IsTrueDeath
    inst.TrueDeathCheck = function(world, data)
        if not (data.mob and data.mob == inst or inst._is_truly_dead) and IsTrueDeath(inst) then
            inst._is_truly_dead = true -- Used to prevent events that trigger at the same from pushing multiple true deaths.
            inst:RemoveEventCallback("mob_death", inst.TrueDeathCheck, TheWorld)
            inst:PushEvent("truedeath")
        end
    end
    ------------------------------------------
	COMMON_FNS.SetupBossFade(inst, 3, true)
	------------------------------------------
	inst:AddComponent("healthtrigger")
	inst.components.healthtrigger:AddTrigger(tuning_values.DAMAGED_TRIGGER, DamagedTrigger)
	inst:AddComponent("bloomer") -- TODO this used?
    ------------------------------------------
    inst:AddComponent("corpsereviver")
    inst.components.corpsereviver:SetReviveHealthPercentMult(tuning_values.REV_PERCENT)
	------------------------------------------
    local attacks = {
        charge = {active = true, cooldown = tuning_values.CHARGE_CD},
        cheer  = {active = true, cooldown = tuning_values.CHEER_CD},
    }
    inst.components.combat:AddAttacks(attacks)
    inst.components.combat:StartCooldown("cheer")
	inst.bro_stacks = 0
	inst.damagedtype = "" --used to pick a specific build for damaged. -- TODO is it?
    inst.SetBuffLevel = SetBuffLevel
	------------------------------------------
	inst.components.combat.onhitotherfn = OnHitOther
	------------------------------------------
    inst:ListenForEvent("death", OnDeath)
    ------------------------------------------
    MakeHauntablePanic(inst) -- TODO?
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
local function alt_fn(sim)
	local inst = fn(sim, true)
    ------------------------------------------
	if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
	return inst
end
--------------------------------------------------------------------------
local function BroSetup(inst, bro_1, bro_2)
	bro_1:DoTaskInTime(0, function(bro_1)
    bro_1.Transform:SetPosition((inst:GetPosition()):Get())
    -- Link Bros
    bro_1.bro = bro_2
    inst.mobs[bro_1] = bro_1
    bro_1:ListenForEvent("onremove", function()
        inst.mobs[bro_1] = nil
        if not inst.mobs[bro_2] then
            inst:Remove()
        end
    end)
	end)
end
--------------------------------------------------------------------------
local function bros_fn(sim)
    local inst = fn(sim, true)
    ------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    inst.mobs = {}
    ------------------------------------------
    inst.GetMobs = function(inst)
        return inst.mobs
    end
    ------------------------------------------
    local bro_1 = SpawnPrefab("rhinocebro")
    local bro_2 = SpawnPrefab("rhinocebro2")
    BroSetup(inst, bro_1, bro_2)
    BroSetup(inst, bro_2, bro_1)
	inst:DoTaskInTime(0, inst.Remove)
    ------------------------------------------
    return inst
end
--------------------------------------------------------------------------
local function fx_fn() -- TODO is the common fn for fx usable here?
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.AnimState:SetBank("lavaarena_rhino_buff_effect")
    inst.AnimState:SetBuild("lavaarena_rhino_buff_effect")
    inst.AnimState:PlayAnimation("in")
    inst.AnimState:PushAnimation("idle", false)
    inst.AnimState:PushAnimation("out", false)
    inst.Transform:SetSixFaced()
	------------------------------------------
    inst:AddTag("DECOR") --"FX" will catch mouseover
    inst:AddTag("NOCLICK")
	------------------------------------------
    inst.entity:SetPristine()
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	inst.persists = false
	------------------------------------------
	inst:ListenForEvent("animqueueover", inst.Remove)
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
return ForgePrefab("rhinocebro", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/reforged.xml", "rhinocebro_icon.tex"),
    ForgePrefab("rhinocebro2", alt_fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/reforged.xml", "rhinocebro_icon.tex"),
    ForgePrefab("rhinocebros", bros_fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/reforged.xml", "rhinocebros_icon.tex"),
    Prefab("rhinocebro_buff_fx", fx_fn)
