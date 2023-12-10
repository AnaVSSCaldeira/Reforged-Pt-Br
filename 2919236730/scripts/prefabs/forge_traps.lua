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
    Asset("ANIM", "anim/lavaarena_trap_spikes.zip"),
}
local prefabs = {
    "collapse_small",
}

local function BreakTrap(inst)
	inst.state = "death"
	inst.AnimState:PlayAnimation("death")
end

------------------------------------------------------------------
--Spikes

local spike_values = TUNING.FORGE.TRAP_SPIKES

local spike_sounds = {
	activate  = "dontstarve/common/together/portable/cookpot/collapse",
	deactivate = "dontstarve/common/cookingpot_open",
}

local function DeactivateSpikes(inst)
	inst.AnimState:PlayAnimation("deactivate")
	inst.state = "deactivated"
	inst:DoTaskInTime(inst.activate_time or spike_values.ACTIVATE_TIME, inst.activate_fn)
end

local function ActivateSpikes(inst)
	inst.AnimState:PlayAnimation("activate")
	inst.state = "activated"
	local pos = inst:GetPosition()
	local ents = TheSim:FindEntities(pos.x, 0, pos.z, spike_values.HIT_RANGE or 3, {"_combat", "_health"}, {"LA_mob", "notarget", "ghost", "shadow", "INLIMBO"})
	if #ents > 0 then
		for i, v in ipairs(ents) do
			if v ~= inst then
				v.components.combat:GetAttacked(inst, inst.components.combat.defaultdamage)		
				COMMON_FNS.KnockbackOnHit(inst, v, 2)
			end
		end
	end
	inst:DoTaskInTime(inst.deactivate_time or spike_values.DEACTIVATE_TIME, inst.deactivate_fn)
end

local function spike_fn()
    local inst = COMMON_FNS.BasicEntityInit("lavaarena_trap_spikes", "lavaarena_trap_spikes", "activate", {pristine_fn = function(inst)
	    inst.entity:AddSoundEmitter()
	    ------------------------------------------
	    COMMON_FNS.AddTags(inst, "trap", "spikes")
	end})
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
	inst.Transform:SetNoFaced()
	inst.Transform:SetScale(5, 5, 5) --TODO FIX THE ANIM SO I DON'T NEED TO DO THIS!
	------------------------------------------
    inst.sounds = spike_sounds
	inst.activate_time = spike_values.ACTIVATE_TIME
	inst.deactivate_time = spike_values.DEACTIVATE_TIME
	inst.activate_fn = ActivateSpikes
	inst.deactivate_fn = DeactivateSpikes
    ------------------------------------------
	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(spike_values.DAMAGE)
    ------------------------------------------
	ActivateSpikes(inst)
    ------------------------------------------
    return inst
end
--------------------------------------------------------
--Beartraps
local beartrap_values = TUNING.FORGE.TRAP_BEARTRAP

local function DeactivateSnare(inst)
	
end

local function ActivateSnare(inst, target)
	inst.AnimState:PlayAnimation("activate")
	inst.state = "activated"
	if target then
		inst.target = target
		target.components.combat:GetAttacked(inst, inst.components.combat.defaultdamage)		
		target.components.debuffable:AddDebuff("trap_snare_debuff", "trap_snare_debuff")
	end
	inst:DoTaskInTime(inst.deactivate_time or beartrap_values.DEACTIVATE_TIME, inst.deactivate_fn)
end

local function FindNearbyTarget(inst)
	local canttags = inst:HasTag("companion") and {"companion", "player"} or {"LA_mob"}
	local ent = FindEntity(inst, beartrap_values.HIT_RANGE, nil, {"_combat", "_health"}, canttags)
	if ent then
		inst.target = ent
		ent.components.combat:GetAttacked(inst, inst.components.combat.defaultdamage)		
		ent.components.debuffable:AddDebuff("trap_snare_debuff", "trap_snare_debuff")
	end

end

local function ActivateBearTrap(inst)
	inst.AnimState:PlayAnimation("land", false)
	inst:ListenForEvent("animover", function(inst) 
		inst:DoPeriodicTask(0.5, FindNearbyTarget)
	end)
end

local function beartrap_fn()
    local inst = COMMON_FNS.BasicEntityInit("lavaarena_trap_beartrap", "lavaarena_trap_beartrap", "land", {pristine_fn = function(inst)
	    inst.entity:AddSoundEmitter()
	    ------------------------------------------
		COMMON_FNS.AddTags(inst, "trap", "beartrap")
	end})
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
	inst.Transform:SetTwoFaced()
	---inst.Transform:SetScale(5, 5, 5)
	------------------------------------------
    inst.sounds = spike_sounds
	inst.deactivate_time = beartrap_values.DEACTIVATE_TIME
	inst.activate_fn = ActivateSnare
	inst.deactivate_fn = DeactivateSnare
    ------------------------------------------
	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(beartrap_values.DAMAGE)
    ------------------------------------------
	ActivateBearTrap(inst)
    ------------------------------------------
    return inst
end

return Prefab("forge_trap_spikes", spike_fn, assets, prefabs)
	--Prefab("forge_trap_beartrap", beartrap_fn, assets, prefabs)
