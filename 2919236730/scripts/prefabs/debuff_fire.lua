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
    Asset("ANIM", "anim/fire_large_character.zip"),
    Asset("SOUND", "sound/common.fsb"),
}
local prefabs = {
    "firefx_light",
}
------------------------------------------------------------------------------
local firelevels = {
    {
    anim  = "loop_small",
    pre   = "pre_small",
    pst   = "post_small",
    sound = "dontstarve/common/campfire",
    radius    = 2,
    intensity = .6,
    falloff   = .7,
    colour    = {197/255,197/255,170/255},
    soundintensity = 1
    },{
    anim  = "loop_med",
    pre   = "pre_med",
    pst   = "post_med",
    sound = "dontstarve/common/treefire",
    radius    = 3,
    intensity = .75,
    falloff   = .5,
    colour    = {255/255,255/255,192/255},
    soundintensity = 1
    },{
    anim  = "loop_large",
    pre   = "pre_large",
    pst   = "post_large",
    sound = "dontstarve/common/forestfire",
    radius    = 4,
    intensity = .8,
    falloff   = .33,
    colour    = {197/255,197/255,170/255},
    soundintensity = 1
    },
}

local function OnTick(inst, target) -- TODO need to have a check to make sure damage does not go over total_damage, also the animation for the health loss doesn't consistenly decrease due to the tick rate. Maybe make the tick rate be whatever 1 health would be? this way the animation is clean
    -- Extra check just in case this runs after the debuff has been removed
    if not target.components.debuffable:HasDebuff("debuff_fire") then
        target.components.health:RemoveRegen("debuff_fire")
        return
    end
    local current_time = GetTime()
    local current_tick_duration = current_time - inst.previous_tick_time
    inst.previous_tick_time = current_time
    if target.components.health and not target.components.health:IsDead() and not target:HasTag("playerghost") and target:IsValid() then
        local fire_dmg = -inst.total_damage / inst.duration * current_tick_duration--(inst.tick_rate - FRAMES)
        if target.components.buffable then -- Apply fire resistance
            fire_dmg = target.components.buffable:ApplyStatBuffs({"fire_resistance"}, fire_dmg)
        end
        target.components.health:DoDelta(fire_dmg < 0 and fire_dmg or 0, true, inst.cause, nil, nil, true)
        target.components.health:AddRegen(inst.prefab, (fire_dmg/(inst.tick_rate/FRAMES)) * 30) -- Calculate 1 seconds worth of damage
    else
        inst.components.debuff:Stop()
    end
end

local function UpdateFireState(inst, state)
    inst.fire_state:set_local(state)
    inst.fire_state:set(state)
end

local function OnAnimOver(inst)
    inst.components.debuff:Stop()
end

local function ResetTimer(inst, target)
    target.fire_debuff_timer = target:DoTaskInTime(inst.duration, function()
        local has_anim = inst.components.firefx:Extinguish()
        if has_anim then
            UpdateFireState(inst, "stop")
            inst.has_anim_over = true
            inst:ListenForEvent("animover", OnAnimOver)
        else
            inst.components.debuff:Stop()
        end
    end)
end

local function OnAttached(inst, target)
    --inst.Transform:SetScale(target.Transform:GetScale())
    --inst.Transform:SetPosition(0,0,1)
    inst.current_level = 2 -- TODO adjust from 1 to 3 based on size
    inst:DoTaskInTime(0, function() -- Delay so level can be set
        inst.entity:SetParent(target.entity)
        -- Remove debuff when target dies
        inst:ListenForEvent("death", function()
            inst.components.debuff:Stop()
        end, target)
        ResetTimer(inst, target)
        inst.components.firefx:SetLevel(inst.current_level)--, immediate)
        inst.previous_tick_time = GetTime()
        inst.damage_task = inst:DoPeriodicTask(inst.tick_rate, OnTick, nil, target) -- TODO low tick rate causes issues...hmmm
        --target.components.health:AddRegen("debuff_fire", -inst.total_damage/inst.duration)
    end)
end

local function OnExtended(inst, target)
    if inst.has_anim_over then
        inst.has_anim_over = nil
        inst.components.firefx.level = nil
        inst.components.firefx:SetLevel(inst.current_level, true)
        UpdateFireState(inst, "high")
        inst:RemoveEventCallback("animover", OnAnimOver)
    end
    RemoveTask(target.fire_debuff_timer)
    ResetTimer(inst, target)
end

local function OnDetached(inst, target)
    UpdateFireState(inst, "stop")
    RemoveTask(target.fire_debuff_timer)
    RemoveTask(inst.damage_task)
    target:DoTaskInTime(0, function()
        target.components.health:RemoveRegen("debuff_fire")
        inst:Remove()
    end)
end
-- ThePlayer.components.debuffable:AddDebuff("debuff_fire", "debuff_fire")
local function DoT_OnInit(inst)
    UpdateFireState(inst, "high")
end

local function OnDebuffFireDirty(inst)
    local parent = inst.entity:GetParent()
    if parent then
        local fire_state = inst.fire_state:value()
        if fire_state == "low" or fire_state == "high" then
            parent:PushEvent("startfiredamage", {low = fire_state == "low"})
        else
            parent:PushEvent("stopfiredamage")
        end
    end
end
------------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.BasicEntityInit("fire_large_character", nil, nil, {noanim = true, pristine_fn = function(inst)
        inst.entity:AddSoundEmitter()
        ------------------------------------------
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetRayTestOnBB(true)
        inst.AnimState:SetFinalOffset(-1)
        ------------------------------------------
        COMMON_FNS.AddTags(inst, "FX", "NOCLICK", "CLASSIFIED")
        ------------------------------------------
        inst.fire_state = net_string(inst.GUID, "debuff_fire.fire_state", "debufffiredirty")
        ------------------------------------------
        inst:DoTaskInTime(FRAMES, DoT_OnInit)
        ------------------------------------------
    	if not TheNet:IsDedicated() then
            inst:ListenForEvent("debufffiredirty", OnDebuffFireDirty)
    	end
    end})
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    inst.source = nil
    --inst.damage = 0.3
    inst.total_damage = 30
    inst.tick_rate = 4*FRAMES--0.1 -- of a second (for acid)
    inst.cause = "fire_dot"
    inst.duration = 3
    inst.current_level = 1
    inst.SetCurrentLevel = function(inst, level)
        isnt.current_level = level
        inst.components.firefx:SetLevel(inst.current_level)--, immediate)
    end
    ------------------------------------------
	inst:AddComponent("debuff")
	inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetExtendedFn(OnExtended)
	inst.components.debuff:SetDetachedFn(OnDetached)
    ------------------------------------------
    inst:AddComponent("firefx")
    inst.components.firefx.levels = firelevels
    ------------------------------------------
	return inst
end
------------------------------------------------------------------------------
return Prefab("debuff_fire", fn, assets, prefabs)

--[[
fx.entity:AddFollower()
fx.Follower:FollowSymbol(self.inst.GUID, v.follow, xoffs, yoffs, zoffs)
"torso" for players
anyway to get center part of ents? or a way to adjust to it?

arrow on health badge is not displaying
--]]
