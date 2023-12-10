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
    Asset("ANIM", "anim/lavaarena_arcane_orb.zip"),
}
local prefabs = {
    "spellmasteryorbs",
}
local prefabs_orbs = {
    "spellmasteryorb",
}
--------------------------------------------------------------------------
local function fn()
    local inst = COMMON_FNS.BasicEntityInit("lavaarena_arcane_orb", "lavaarena_arcane_orb", "anchor", {pristine_fn = function(inst)
	    inst.AnimState:SetLightOverride(1)
	    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	    ------------------------------------------
		COMMON_FNS.AddTags(inst, "FX", "NOCLICK")
	end})
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
    inst.orbs = SpawnPrefab("spellmasteryorbs")
	------------------------------------------
	inst.SetTarget = function(inst_tar, target)
		inst.orbs:SetTarget(target)
	end
	------------------------------------------
	inst.RemoveAmplifyFX = function(inst_re)
		inst.orbs:RemoveOrbsFX()
		inst.orbs = nil
		inst:Remove()
	end
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
local function orbfn()
    local inst = COMMON_FNS.BasicEntityInit("lavaarena_arcane_orb", "lavaarena_arcane_orb", "in", {pristine_fn = function(inst)
	    inst.entity:AddSoundEmitter()
		inst.entity:AddFollower()
		------------------------------------------
	    inst.Transform:SetEightFaced()
	    ------------------------------------------
	    COMMON_FNS.AddTags(inst, "FX", "NOCLICK")
	end})
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
    inst.AnimState:PushAnimation("idle")
    inst.persists = false
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
local function orbsfn()
    local inst = CreateEntity()
    inst.entity:AddFollower()
	inst.entity:AddNetwork()
	inst.entity:AddSoundEmitter()
    inst:AddTag("FX")
    ------------------------------------------
	inst.entity:SetPristine()
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	-- Attach Orbs to player
	inst.SetTarget = function(inst_tar, target)
		local max_orbs = 3
		inst.target = target
		-- Create each orb
		inst.orb = {}
		for i = 1, max_orbs, 1 do
			inst.orb[i] = SpawnPrefab("spellmasteryorb") -- Starting rotations: 120, 240, 360
			inst.orb[i].current_degree = 360 / max_orbs * i
			local set = inst.OrbPositions[inst.orb[i].current_degree]
			local current_x = set[1]
			local current_y = set[2]
			inst.orb[i].entity:AddFollower()
			-- Attach Orb to player
			inst.orb[i].Follower:FollowSymbol(target.GUID, "torso", current_x, current_y + 100, current_y / 100)
			target.SoundEmitter:PlaySound("dontstarve/common/lava_arena/spell/start_light_orb")
		end

		-- Start rotating orbs
		inst.Rotating = inst:DoPeriodicTask(0.01, inst.RotateOrbs, nil, inst)

		-- Play orb idle loop
        if target.SoundEmitter:PlayingSound("orb_loop") then
            target.SoundEmitter:KillSound("orb_loop")
        end
        target.SoundEmitter:PlaySound("reforge/sfx/loop_light_orb_LP", "orb_loop")
        target.SoundEmitter:SetVolume("orb_loop", 0.35)
	end
	------------------------------------------
	-- Create a lookup table of orb positions for each degree
	inst.GenerateOrbPositions = function()
		local orb_positions = {}
		local distance = 100
		for i = 1, 360, 1 do
			local radian = i * (math.pi / 180)
			local x = distance * math.cos(radian)
			local y = distance / 2 * math.sin(radian)
			orb_positions[i] = {x, y}
		end
		return orb_positions
	end
	inst.OrbPositions = inst:GenerateOrbPositions()
	------------------------------------------
	-- Rotate each orb 2 degrees
	inst.RotateOrbs = function()
		-- Rotate each orb
		for i, orb in pairs(inst.orb) do
			-- Reset current degree if next degree will be above 360
			if orb.current_degree >= 360 then
				orb.current_degree = 2
			else
				orb.current_degree = orb.current_degree + 2
			end

			-- Update orbs offset
			local set = inst.OrbPositions[orb.current_degree]
			local current_x = set[1]
			local current_y = set[2]
			orb.Follower:SetOffset(current_x, current_y + 100, current_y/100)
		end
	end
	------------------------------------------
	inst.RemoveOrbsFX = function()
		-- Stop playing orb idle loop
		inst.target.SoundEmitter:KillSound("orb_loop") -- TODO test this, was inst but now is target, might fix the issue ex talked about
		-- Remove each orb
		for i, orb in pairs(inst.orb) do
			orb.AnimState:PlayAnimation("out")
			orb.SoundEmitter:PlaySound("dontstarve/common/lava_arena/spell/stop_light_orb") -- TODO sound plays on target
			orb:Remove()
			orb = nil
		end
		inst:Remove()
	end
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
return Prefab("passive_amplify_fx", fn, assets, prefabs),
    Prefab("spellmasteryorb", orbfn, assets),
    Prefab("spellmasteryorbs", orbsfn, nil, prefabs_orbs)
