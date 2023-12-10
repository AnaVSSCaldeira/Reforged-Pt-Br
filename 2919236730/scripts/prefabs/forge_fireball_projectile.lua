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
local assets_fireballhit = {
    Asset("ANIM", "anim/fireball_2_fx.zip"),
    Asset("ANIM", "anim/deer_fire_charge.zip"),
}
local assets_blossomhit = {
    Asset("ANIM", "anim/lavaarena_heal_projectile.zip"),
}
local assets_gooballhit = {
    Asset("ANIM", "anim/gooball_fx.zip"),
}
--------------------------------------------------------------------------
-- Physics Functions
--------------------------------------------------------------------------
local function PhysicsInit(inst)
    MakeInventoryPhysics(inst)
    inst.Physics:ClearCollisionMask()
end
--------------------------------------------------------------------------
-- Pristine Functions
--------------------------------------------------------------------------
local function PristineFN(inst)
    inst.AnimState:SetFinalOffset(-1)
end
--------------------------------------------------------------------------
local function MakeProjectile(name, bank, build, speed, light_override, add_colour, mult_colour, hit_fx, stimuli, damage_type, scale)
    local assets = {
        Asset("ANIM", "anim/"..build..".zip"),
    }
    local prefabs = hit_fx ~= nil and { hit_fx } or nil
	--------------------------------------------------------------------------
	local function OnHit(inst, attacker, target)
		local hit_fx = COMMON_FNS.CreateFX(hit_fx, target, attacker)
        hit_fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
		inst:Remove()
	end
	--------------------------------------------------------------------------
	local projectile_values = {
		scale          = scale,
        speed          = speed,
        stimuli        = stimuli,
        damage_type    = damage_type or TUNING.FORGE.DAMAGETYPES.MAGIC,
		--range          = tuning_values.HIT_RANGE, -- TODO range is not set which means the projectile will travel until it hits the target, if it's outside the hit range of the weapon then it does nothing to the target. Maybe retrieve hit range from the weapon? or could make ranged weapons have infinite hit range if homing?
		hit_dist       = 0.5, -- TODO default is 0.5 atm
		OnHit          = OnHit,
		add_colour     = add_colour,
		mult_colour    = mult_colour,
		light_override = light_override,
        pristine_fn    = PristineFN,
	}
    local tail_values = {
        physics_init_fn = PhysicsInit,
        bank            = bank,
        build           = build,
        scale           = scale,
        speed           = speed,
        add_colour      = add_colour,
        mult_colour     = mult_colour,
        light_override  = light_override,
        final_offset    = -1,
    }
	--------------------------------------------------------------------------
    local function fn()
        local inst = COMMON_FNS.EQUIPMENT.CommonProjectileFN(bank, build, "idle_loop", projectile_values, tail_values)
		------------------------------------------
        if not TheWorld.ismastersim then
            return inst
        end
		------------------------------------------
        inst._hastail:set(true)
		inst.persists = false
		------------------------------------------
        return inst
    end
	--------------------------------------------------------------------------
    return Prefab(name, fn, assets, prefabs)
end
--------------------------------------------------------------------------
local function fireballhit_fn()
	local inst = COMMON_FNS.FXEntityInit("fireball_fx", "deer_fire_charge", "blast", {pristine_fn = function(inst)
    	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    	inst.AnimState:SetLightOverride(1)
        inst.AnimState:SetFinalOffset(-1)
        ------------------------------------------
    	inst.persists = false
    end})
    ------------------------------------------
    return inst
end
--------------------------------------------------------------------------
local function shadowballhit_fn()
	local inst = COMMON_FNS.FXEntityInit("fireball_fx", "deer_fire_charge", "blast", {pristine_fn = function(inst)
    	inst.AnimState:SetLightOverride(1)
        inst.AnimState:SetFinalOffset(-1)
    	inst.AnimState:SetMultColour(0, 0, 0, 1)
        ------------------------------------------
    	inst.persists = false
    end})
    ------------------------------------------
    return inst
end
--------------------------------------------------------------------------
local function blossomhit_fn()
    local inst = COMMON_FNS.FXEntityInit("lavaarena_heal_projectile", "lavaarena_heal_projectile", "hit", {pristine_fn = function(inst)
        inst.AnimState:SetAddColour(0, .1, .05, 0)
        inst.AnimState:SetFinalOffset(-1)
        ------------------------------------------
    	inst.persists = false
    end})
    ------------------------------------------
    return inst
end
--------------------------------------------------------------------------
local function gooballhit_fn()
    local inst = COMMON_FNS.FXEntityInit("gooball_fx", "gooball_fx", "blast", {pristine_fn = function(inst)
        inst.entity:AddSoundEmitter()
        inst.AnimState:SetMultColour(.2, 1, 0, 1)
        inst.AnimState:SetFinalOffset(-1)
    	inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/poison_hit")
        ------------------------------------------
    	inst.persists = false
    end})
    ------------------------------------------
    return inst
end
--------------------------------------------------------------------------
return MakeProjectile("forge_fireball_projectile", "fireball_fx", "fireball_2_fx", 15, 1, nil, nil, "forge_fireball_hit_fx", "fire"),
    MakeProjectile("forge_blossom_projectile", "lavaarena_heal_projectile", "lavaarena_heal_projectile", 15, 0, { 0, .2, .1, 0 }, nil, "forge_blossom_hit_fx"), -- TODO is this life blossom? if so this has fire stimuli? lol
    MakeProjectile("forge_gooball_projectile", "gooball_fx", "gooball_fx", 20, 0, nil, { .2, 1, 0, 1 }, "forge_gooball_hit_fx"),
    Prefab("forge_fireball_hit_fx", fireballhit_fn, assets_fireballhit),
	Prefab("forge_shadowball_hit_fx", shadowballhit_fn, assets_fireballhit),
    Prefab("forge_blossom_hit_fx", blossomhit_fn, assets_blossomhit),
    Prefab("forge_gooball_hit_fx", gooballhit_fn, assets_gooballhit),
    --Leo: Blame klei for not allowing to edit projectiles spawned via weapon component.
    MakeProjectile("forge_fireball_projectile_fast", "fireball_fx", "fireball_2_fx", 30, 1, nil, nil, "forge_fireball_hit_fx", "fire"),
	MakeProjectile("forge_fireball_projectile_big", "fireball_fx", "fireball_2_fx", 30, 1, nil, nil, "forge_fireball_hit_fx", "fire", nil, 2),
	MakeProjectile("rf_shadowball_projectile", "fireball_fx", "fireball_2_fx", 15, 1, nil, {0, 0, 0, 1}, "forge_shadowball_hit_fx")
