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
    Asset("ANIM", "anim/lavaarena_shadow_lunge.zip"),
    Asset("ANIM", "anim/waxwell_shadow_mod.zip"),
    Asset("ANIM", "anim/swap_nightmaresword_shadow.zip"),
}
local prefabs = {
    "statue_transition_2",
    "shadowstrike_slash_fx",
    "shadowstrike_slash2_fx",
    "weaponsparks_thrusting_fx",
}
local tuning_values = TUNING.FORGE.SHADOWS
--------------------------------------------------------------------------
local function StartShadows(inst) -- TODO possibly make a stategraph for shadows?
	SpawnPrefab("statue_transition_2").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.AnimState:PlayAnimation("lunge_pre")
	inst.AnimState:PushAnimation("lunge_loop")
	inst.AnimState:PushAnimation("lunge_pst")

	inst:DoTaskInTime(12*FRAMES, function(inst)
		inst.Physics:SetMotorVel(tuning_values.LUNGE_SPEED, 0, 0)
	end)
	inst:DoTaskInTime(15*FRAMES, function(inst)
		inst.components.combat:DoAttack(inst.target, nil, nil, "strong")--"shadow")
	end)
	inst:DoTaskInTime(22*FRAMES, function(inst)
		inst.Physics:ClearMotorVelOverride()
	end)
	inst:DoTaskInTime(35*FRAMES, function(inst)
		inst:Remove()
	end)
end
--------------------------------------------------------------------------
local function fn()
    local inst = COMMON_FNS.BasicEntityInit("lavaarena_shadow_lunge", "waxwell_shadow_mod", nil, {noanim = true, pristine_fn = function(inst)
	    inst.entity:AddSoundEmitter()
	    inst.entity:AddPhysics()
		------------------------------------------
	    inst.Transform:SetFourFaced(inst)
		------------------------------------------
	    inst.AnimState:AddOverrideBuild("lavaarena_shadow_lunge")
	    inst.AnimState:SetMultColour(0, 0, 0, .5)
	    inst.AnimState:OverrideSymbol("swap_object", "swap_nightmaresword_shadow", "swap_nightmaresword_shadow")
	    inst.AnimState:Hide("HAT")
	    inst.AnimState:Hide("HAIR_HAT")
		------------------------------------------
	    inst.Physics:SetMass(1)
	    inst.Physics:SetFriction(0)
	    inst.Physics:SetDamping(5)
	    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
	    inst.Physics:ClearCollisionMask()
	    inst.Physics:CollidesWith(COLLISION.GROUND)
	    inst.Physics:SetCapsule(.5, 1)
		------------------------------------------
		COMMON_FNS.AddTags(inst, "scarytoprey", "NOBLOCK")
	end})
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(tuning_values.DAMAGE)
	------------------------------------------
	inst.SetOwner = function(inst, owner)
		inst.owner = owner
		if owner and owner.components.combat then
			owner.components.combat:CopyBuffsTo(inst)
		end
	end
	------------------------------------------
    inst.SetTarget = function(inst, target, offset)
		inst.target = target
		inst.offset = offset or {x = 0, y = 0, z = 0}
        if inst.target then
    		local target_pos = target:GetPosition()
    		inst.Transform:SetPosition((target_pos + offset):Get())
    		inst:FacePoint(target_pos)
    		StartShadows(inst)
        else -- Remove if no target
            inst:Remove()
        end
	end
	------------------------------------------
	inst:ListenForEvent("onhitother", function(inst, data)
		-- Spawn Hit FX
		local fx = SpawnPrefab(math.random(1,2) == 1 and "shadowstrike_slash_fx" or "shadowstrike_slash2_fx") -- TODO check these, are they client side?
		fx.Transform:SetPosition(data.target:GetPosition():Get())
		fx.Transform:SetRotation(inst.Transform:GetRotation())
		local spark_offset_mult = 0.25
		--SpawnPrefab("weaponsparks_fx"):SetThrusting(data.target, inst.offset * spark_offset_mult)
        COMMON_FNS.CreateFX("weaponsparks_thrusting_fx", data.target, inst)
		-- Spawn Damage Numbers
		inst.owner:SpawnChild("damage_number"):UpdateDamageNumbers(inst.owner, data.target, math.floor(data.damageresolved + 0.5), nil, data.stimuli, true)
	end)
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
return Prefab("passive_shadow_fx", fn, assets, prefabs)
