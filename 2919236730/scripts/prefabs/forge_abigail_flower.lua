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
    Asset("ANIM", "anim/abigail_flower.zip"),
}
local prefabs = {
    "lavaarena_abigail",
    "redpouch_unwrap",
}
local tuning_values = TUNING.FORGE.FORGE_ABIGAIL
--------------------------------------------------------------------------
local status_strings = {"LONG", "MEDIUM", "SOON", "HAUNTED_GROUND"}
local function getstatus(inst)
	return status_strings[inst._chargestate > 0 and inst._chargestate or "LONG"]
end

local function deactivate(inst)
    inst.SoundEmitter:KillAllSounds()
end

local function activate(inst)
    --inst.SoundEmitter:PlaySound("dontstarve/common/haunted_flower_LP", "loop") -- TODO this was commented out, needed?
	SpawnPrefab("small_puff").Transform:SetPosition(inst.Transform:GetWorldPosition())
	if inst._playerlink then
		inst._playerlink.components.petleash.petprefab = "forge_abigail"
        if inst._abigail then
            inst._abigail.Transform:SetPosition(inst.Transform:GetWorldPosition())
            inst._abigail.SoundEmitter:PlaySound("dontstarve/common/ghost_spawn")
            inst._abigail.components.health:SetPercent(1)
            inst._playerlink.components.pethealthbars:SetSymbol(inst._abigail, "pet_abigail")
            inst._abigail:UpdatePetLevel(inst.current_level, true)
            inst._abigail.sg:GoToState("appear")
        end
		deactivate(inst)
		inst:Remove()
	end
end

-- Updates the stage of the flower
-- Each stage lasts one cooldown length
local function updatestate(inst)
	if not inst._playerlink then return end -- Only stay if playerlink exists

	inst._chargestate = (inst._chargestate or 0) + 1
	-- Stage 4
	if inst._chargestate >= 4 then
		activate(inst)
		--inst.AnimState:ClearBloomEffectHandle() -- TODO needed? this was used if updatestate was called when abigail was ready to spawn and awaiting a kill, seemed to occur when picking up the flower and having it in your inventory, never happens so this would never run in forge?
	-- Stage 3
	elseif inst._chargestate >= 3 then
		inst.AnimState:PlayAnimation("haunted_pre")
		inst.AnimState:PushAnimation("idle_haunted_loop", true)
		inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        if inst._playerlink.components.pethealthbars then
            inst._playerlink.components.pethealthbars:SetSymbol(inst._abigail, "pet_flower2")
        end
	-- Stage 2
	elseif inst._chargestate >= 2 then
		inst.AnimState:PlayAnimation("idle_2")
        if inst._playerlink.components.pethealthbars then
            inst._playerlink.components.pethealthbars:SetSymbol(inst._abigail, "pet_flower1")
        end
	-- Stage 1
	else
		inst.AnimState:PlayAnimation("idle_1")
	end
	inst.components.cooldown:StartCharging()
end

local function unlink(inst)
    if inst._playerlink then
        inst._playerlink = nil
    end
end

local function linktoplayer(inst, player)
    if player then
        inst._playerlink = player
		player.components.leader:AddFollower(inst)
		player:ListenForEvent("onremove", unlink, inst)
    end
end

local TOTAL_STATES = 3 -- TODO tuning states? or local states?
-- Calculates and returns the current cooldown time based on the current level
-- Cooldowns:
-- 1: 90, 2: 30, 3: 18, ..., etc.
local function CalculateNewCooldown(inst)
	return tuning_values.RESPAWN_TIME/(TOTAL_STATES * (inst.current_level > 1 and (inst.current_level * 2 - 1) or 1))
end

local function Initialize(inst, player, current_level, abigail)
	inst:LinkToPlayer(player)
	inst._abigail = abigail
	inst.current_level = current_level
	inst.components.cooldown.cooldown_duration = CalculateNewCooldown(inst)
	updatestate(inst)
end
--------------------------------------------------------------------------
local function fn()
    local inst = COMMON_FNS.BasicEntityInit("abigail_flower", nil, "idle_1", {pristine_fn = function(inst)
	    inst.entity:AddSoundEmitter()
		inst:AddTag("nospawnfx") --Leo: a common tag made for modders if they need it to disable the spawnfx, like for pets transitioning between prefabs and such. - TODO put in API
	    ------------------------------------------
	    inst.nameoverride = "abigail_flower"
	end})
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
    inst._onremoveplayer = function()
        unlink(inst)
        updatestate(inst)
    end
	-----------------------------------
	inst.LinkToPlayer = linktoplayer
	inst.Initialize = Initialize
    inst._chargestate = 0
    -----------------------------------
    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus
	-----------------------------------
    inst:AddComponent("cooldown")
    inst.components.cooldown.cooldown_duration = tuning_values.RESPAWN_TIME / TOTAL_STATES
    inst.components.cooldown.onchargedfn = updatestate
	-----------------------------------
	inst:AddComponent("follower")
	inst.components.follower.keepdeadleader = true
	-----------------------------------
	inst:ListenForEvent("updatepetmastery", function(inst, data)
		-- Update Pet Level
		inst.current_level = (inst.current_level or 1) + data.level
		-- Update Cooldown
		local cooldown = inst.components.cooldown
		local cooldown_percent = cooldown:GetTimeToCharged() / cooldown.cooldown_duration
		cooldown.cooldown_duration = CalculateNewCooldown(inst)
		cooldown:StartCharging(cooldown_percent * cooldown.cooldown_duration)
	end)
	-----------------------------------
    return inst
end

return Prefab("forge_abigail_flower", fn, assets, prefabs)
