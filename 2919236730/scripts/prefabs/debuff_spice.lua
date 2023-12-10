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
    Asset("ANIM", "anim/sleepcloud.zip"),
}
local prefabs = {}
local tuning_values = TUNING.FORGE.SPICE_BOMB

local spice_colors = {
    dmg  = {1,0,0,1},
    def = {0,0,1,1},
    regen   = {0,1,0,1},
    speed   = {1,1,1,1},
}
------------------------------------------------------------------------------
local function OnTick(inst, target) -- TODO need to have a check to make sure damage does not go over total_damage, also the animation for the health loss doesn't consistenly decrease due to the tick rate. Maybe make the tick rate be whatever 1 health would be? this way the animation is clean
    -- Extra check just in case this runs after the debuff has been removed
    if not target.components.debuffable:HasDebuff("debuff_spice_regen") then
        target.components.health:RemoveRegen("debuff_spice")
        return
    end
    local current_time = GetTime()
    local current_tick_duration = current_time - inst.previous_tick_time
    inst.previous_tick_time = current_time
    if target.components.health and not target.components.health:IsDead() and not target:HasTag("playerghost") and target:IsValid() then
        local heal_value = inst.total_heal * inst.current_mult / inst.duration * current_tick_duration--(inst.tick_rate - FRAMES)
        if target.components.buffable then -- Apply healing factors
            heal_value = target.components.buffable:ApplyStatBuffs({"heal_recieved"}, heal_value)
        end
        target.components.health:DoDelta(heal_value > 0 and heal_value or 0, true, inst.cause, nil, inst.caster, true)
        target.components.health:AddRegen(inst.prefab, (heal_value/(inst.tick_rate/FRAMES)) * 30) -- Calculate 1 seconds worth of heal
    else
        inst.components.debuff:Stop()
    end
end

local SLEEP_DELAY = 1
local function OnAttacked(inst, data)
    if not inst.remove_spice_timer then
        inst.remove_spice_timer = inst:DoTaskInTime(SLEEP_DELAY, function(inst)
            inst.components.debuffable:RemoveDebuff("debuff_spice_regen")
            inst.remove_spice_timer = nil
        end)
    end
end

local function AddBuff(inst, target)
    inst.current_mult = inst.mult
    if inst.type == "dmg" then
        if target.components.combat then
            target.components.combat:AddDamageBuff("spice_atk_buff", 1 + (inst.is_buff and inst.buffs.attack or inst.debuffs.attack) * inst.current_mult)
        end
    elseif inst.type == "def" then
        if target.components.combat then
            target.components.combat:AddDamageBuff("spice_def_buff", 1 + (inst.is_buff and inst.buffs.defense or inst.debuffs.defense) * inst.current_mult, true)
        end
    elseif inst.type == "speed" then
        if target.components.locomotor then
            target.components.locomotor:SetExternalSpeedMultiplier(target, "spice_speed_buff", 1 + (inst.is_buff and inst.buffs.speed or inst.debuffs.speed) * inst.current_mult)
        end
    else -- "regen"
        if inst.is_buff then
            inst.previous_tick_time = GetTime()
            inst.regen_task = inst:DoPeriodicTask(inst.tick_rate, OnTick, nil, target) -- TODO low tick rate causes issues...hmmm
            local debuffable = target.components.debuffable
            if debuffable and debuffable:HasDebuff("scorpeon_dot") then
                debuffable:RemoveDebuff("scorpeon_dot")
            end
        elseif target.components.sleeper then
            target.components.sleeper:GoToSleep(inst.debuffs.sleep, inst.caster) -- TODO add listener to remove buff on wake up?
            target:ListenForEvent("attacked", OnAttacked)
        end
    end
end

local function OnAttached(inst, target)
    inst.target = target
    inst:DoTaskInTime(0, function() -- Delay so duration and attack mult debuff can be set
        inst.entity:SetParent(target.entity)
        -- Remove debuff when target dies
        inst:ListenForEvent("death", function()
            inst.components.debuff:Stop()
        end, target)
        -- Attach buff
        AddBuff(inst, target)

        target["spice_debuff_" .. tostring(inst.type) .. "_timer"] = target:DoTaskInTime(inst.duration, function() -- TODO
            inst.components.debuff:Stop()
        end)
    end)
end

local function RemoveBuff(inst, target, type)
    if type == "dmg" then
        if target.components.combat then
            target.components.combat:RemoveDamageBuff("spice_atk_buff")
        end
    elseif type == "def" then
        if target.components.combat then
            target.components.combat:RemoveDamageBuff("spice_def_buff", true)
        end
    elseif type == "speed" then
        if target.components.locomotor then
            target.components.locomotor:RemoveExternalSpeedMultiplier(target, "spice_speed_buff")
        end
    elseif inst.regen_task then -- "regen"
        inst.regen_task = inst:DoPeriodicTask(inst.tick_rate, OnTick, nil, target)
    elseif type == "regen" and not inst.is_buff then -- "sleep"
		if target.components.sleeper then
            target.components.sleeper:WakeUp()
        end
        target:RemoveEventCallback("attacked", OnAttacked)
    end
end

local function OnExtended(inst, target)
    RemoveTask(target["spice_debuff_" .. tostring(inst.type) .. "_timer"])
    inst:DoTaskInTime(0, function() -- Delay so previous type and current type can be updated
        -- Change buff if different type or if switching to a buff/debuff or if sleep debuff is being applied
        if inst.previous_type ~= inst.type or inst.was_buff ~= inst.is_buff or inst.type == "regen" and not inst.is_buff then
            RemoveBuff(inst, target, inst.previous_type)
            AddBuff(inst, target)
        end

       target["spice_debuff_" .. tostring(inst.type) .. "_timer"] = target:DoTaskInTime(inst.duration, function()
            inst.components.debuff:Stop()
        end)
    end)
end

local function OnDetached(inst, target)
    RemoveBuff(inst, target, inst.type)
    RemoveTask(target.spice_debuff_timer)
    inst.AnimState:PlayAnimation("sleepcloud_overlay_pst")
    if inst.source then
        inst.source.targets[target] = nil
    end
end
------------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.BasicEntityInit("sleepcloud", nil, "sleepcloud_overlay_pre", {anim_loop = false, pristine_fn = function(inst)
        inst.AnimState:SetFinalOffset(2)
        ------------------------------------------
        inst.Transform:SetScale(0.5,0.5,0.5)
        ------------------------------------------
        COMMON_FNS.AddTags(inst, "FX", "NOCLICK")
    end})
	------------------------------------------
	if not TheWorld.ismastersim then
		return inst
	end
    ------------------------------------------
    inst.source = nil
    inst.duration = tuning_values.DURATION
    inst.buffs = {
        attack  = 0.25,--1.25,
        defense = -0.2,--0.8,
        regen   = 60,
        speed   = 0.2,--1.2,
    }
    inst.debuffs = {
        attack  = -0.1,--0.9,
        defense = 0.1,--1.1,
        sleep   = 10,
        speed   = -0.1,--0.9,
    }
    inst.tick_rate = 4*FRAMES--0.1 -- of a second (for acid)
    inst.cause = "spice_regen"
    inst.total_heal = inst.buffs.regen
    inst.SetCaster = function(inst, caster)
        if caster == nil then return end
        inst.caster = caster
        inst.total_heal = caster.components.buffable:ApplyStatBuffs({"heal_dealt"}, inst.buffs.regen)
        inst.duration = caster.components.buffable:ApplyStatBuffs({"spell_duration"}, inst.duration)
    end
    inst.is_buff = true
    inst.SetIsBuff = function(inst, is_buff)
        inst.was_buff = inst.is_buff
        inst.is_buff = is_buff
    end
    inst.type = "regen"
    inst.SetSpiceType = function(inst, type)
        inst.previous_type = inst.type
        inst.type = type
		inst:DoTaskInTime(0, function(inst) --SetMultColour won't run without a delay on spawn
			inst.AnimState:SetMultColour(unpack(spice_colors[type] or {0,1,0,0}))
		end)
    end
    inst.mult = 1
    inst.SetMult = function(inst, mult)
        inst.mult = mult or 1
    end
    inst.SetSource = function(inst, source)
        inst.source = source
    end
    ------------------------------------------
	inst:AddComponent("debuff")
	inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetExtendedFn(OnExtended)
	inst.components.debuff:SetDetachedFn(OnDetached)
    ------------------------------------------
    inst:ListenForEvent("animover", function(inst)
        if not inst.AnimState:IsCurrentAnimation("sleepcloud_overlay_pst") then
            inst.AnimState:PlayAnimation("sleepcloud_overlay_loop")
        else
            inst:Remove()
        end
    end)
    ------------------------------------------
	return inst
end
------------------------------------------------------------------------------
return Prefab("debuff_spice", fn, assets, prefabs)
