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

-- TODO possible rounding issue here, overall healing might be off?
local function OnTick(inst, target)
    -- Extra check just in case this runs after the debuff has been removed
    if not target.components.debuffable:HasDebuff("healingcircle_regenbuff") then
        target.components.health:RemoveRegen("healingcircle_regenbuff")
        return
    end
    if target.components.health ~= nil and not target.components.health:IsDead() and not (target:HasTag("corpse") or target:HasTag("playerghost")) then
		local heal_value = inst.heal_value
		if target.components.buffable then
			heal_value = target.components.buffable:ApplyStatBuffs({"heal_recieved"}, heal_value)
		end
        target.components.health:DoDelta(heal_value, true, "healingcircle", true, inst.caster)
        target.components.health:AddRegen("healingcircle_regenbuff", heal_value * 30)
    else
        inst.components.debuff:Stop()
    end
end

local function OnAttached(inst, target)
    inst.entity:SetParent(target.entity)
    --inst:DoTaskInTime(0, function() -- Delay one frame to ensure any changes made to the healing value
        --target.components.health:AddRegen("healingcircle_regenbuff", inst.heal_value * 30)
    --end)
    inst.task = inst:DoPeriodicTask(inst.tick_rate, OnTick, nil, target)
    inst:ListenForEvent("death", function()
        inst.components.debuff:Stop()
    end, target)
end

local function OnTimerDone(inst, data)
    if data.name == "regenover" then
        inst.components.debuff:Stop()
    end
end

local function OnExtended(inst, target)
    inst.components.timer:StopTimer("regenover")
    inst.components.timer:StartTimer("regenover", inst.duration)
    inst.task:Cancel()
    inst.task = inst:DoPeriodicTask(inst.tick_rate, OnTick, nil, target)
end

local function OnDetached(inst, target)
    target:DoTaskInTime(0, function()
        target.components.health:RemoveRegen("healingcircle_regenbuff")
    end)
    inst.task:Cancel()
    inst:Remove()
end

local function OnInit(inst)
    local parent = inst.entity:GetParent()
    if parent ~= nil then
        parent:PushEvent("starthealthregen", inst)
	else
		Debug:Print("Failed to get parent for healingcircle_regenbuff", "error")
		inst:Remove()
    end
end

local function fn()
    local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddNetwork()

	inst:DoTaskInTime(0, OnInit)
    ------------------------------------------
	inst.entity:SetPristine()
	------------------------------------------
    if not TheWorld.ismastersim then
        --Not meant for client!
		--but this is a copy of the original healthregenbuff except this one will be needed by the client maybe?
        --inst:DoTaskInTime(0, inst.Remove)

        return inst
    end
    ------------------------------------------
	-- 30 ticks, 6 / 30 = 0.2, 8 / 30
	inst.tick_rate = 1/30
	inst.heal_value = TUNING.FORGE.LIVINGSTAFF.HEAL_RATE * inst.tick_rate
	inst.duration = TUNING.FORGE.LIVINGSTAFF.DURATION
	inst.caster = nil

    --[[Non-networked entity]]
    --inst.entity:SetCanSleep(false)
    inst.entity:Hide()
    inst.persists = false

    inst:AddTag("CLASSIFIED")

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetDetachedFn(OnDetached)
    inst.components.debuff:SetExtendedFn(OnExtended)
    inst.components.debuff.keepondespawn = true

    inst:AddComponent("timer")
    inst.components.timer:StartTimer("regenover", inst.duration)
    inst:ListenForEvent("timerdone", OnTimerDone)

    return inst
end

return Prefab("healingcircle_regenbuff", fn)
