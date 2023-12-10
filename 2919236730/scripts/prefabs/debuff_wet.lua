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
local tuning_values = TUNING.FORGE.WURT
------------------------------------------------------------------------------
local function OnAttached(inst, target)
    --TODO redo DamageBuffs to include multiple stimulis
    if target.components.combat and not target.components.combat:HasDamageBuff("wet_debuff", true) then
        target.components.combat:AddDamageBuff("wet_debuff", {buff = tuning_values.WET_DEBUFF_ELECTRIC, stimuli = "electric"}, true)
        target.components.combat:AddDamageBuff("wet_debuff_weak", {buff = tuning_values.WET_DEBUFF_ELECTRIC, stimuli = "electric_weak"}, true)
    end
    if target.components.buffable then
        target.components.buffable:AddBuff("wet_debuff", {{name = "attack_rate", type = "mult", val = 1.1}})
    end
    if target.components.locomotor then
        target.components.locomotor:SetExternalSpeedMultiplier(target, "wet_debuff", tuning_values.WET_DEBUFF_MOVEMENT)
    end
    if target.components.moisture then
        target.components.moisture:DoDelta(10)
    end
    if not target:HasTag("wet") then
        target:AddTag("wet")
    end
    target.AnimState:SetMultColour(0.5, 0.6, 1, 1)
    inst.wet_debuff_timer = inst:DoTaskInTime(tuning_values.WET_DEBUFF_DURATION, function(inst)
        inst.components.debuff:Stop()
        inst.wet_debuff_timer = nil
    end)
end

local function OnExtended(inst, target)
    RemoveTask(inst.wet_debuff_timer)
    if target.components.moisture then
        target.components.moisture:DoDelta(10)
    end
    inst.wet_debuff_timer = inst:DoTaskInTime(tuning_values.WET_DEBUFF_DURATION, function(inst)
        inst.components.debuff:Stop()
        inst.wet_debuff_timer = nil
    end)
end

local function OnDetached(inst, target)
    if target:IsValid() then
        if target.components.combat then
            target.components.combat:RemoveDamageBuff("wet_debuff", true)
			target.components.combat:RemoveDamageBuff("wet_debuff_weak", true)
        end
        if target.components.buffable then
            target.components.buffable:RemoveBuff("wet_debuff")
        end
        if target.components.locomotor then
            target.components.locomotor:RemoveExternalSpeedMultiplier(target, "wet_debuff")
        end
        target:RemoveTag("wet")
        target.AnimState:SetMultColour(1, 1, 1, 1)
    end
    RemoveTask(inst.wet_debuff_timer)
	inst:Remove()
end
------------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.BasicEntityInit(nil, nil, nil, {anim_loop = false})
	------------------------------------------
	if not TheWorld.ismastersim then
		return inst
	end
    ------------------------------------------
	inst:AddComponent("debuff")
	inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetExtendedFn(OnExtended)
	inst.components.debuff:SetDetachedFn(OnDetached)
    ------------------------------------------
	return inst
end
------------------------------------------------------------------------------
return Prefab("debuff_wet", fn, assets, prefabs)
