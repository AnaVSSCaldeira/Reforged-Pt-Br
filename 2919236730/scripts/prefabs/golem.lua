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
--[[
TODO
	if hit near the end of its timeline it will play the death anim twice, might be because timer ends during death anim?
	might not be removed correctly after death anim from timer it seems like its still there and can be hit to trigger it again and this time be completely removed.
--]]
local tuning_values = TUNING.FORGE.GOLEM
local sound_path = "dontstarve/common/lava_arena/spell/elemental/"
--------------------------------------------------------------------------
-- Pet Function
--------------------------------------------------------------------------
local function SetCaster(inst, caster)
	inst.caster = caster
end

local function SetCharged(inst, charged)
	if charged then
		inst.AnimState:Show("head_spikes")
	end
end
--------------------------------------------------------------------------
-- Death Function
--------------------------------------------------------------------------
local function Die(inst)
	if not inst.components.health:IsDead() then
		if inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("attack") then
			inst.sg.statemem.wants_to_die = true
		end
		inst.components.health:Kill()
	end
end
--------------------------------------------------------------------------
-- Physics Functions
--------------------------------------------------------------------------
local physics = {
    scale  = 1,
    mass   = 450,
    radius = 0.65,
    shadow = {1.1,0.7},
}
local function PhysicsInit(inst)
	inst:SetPhysicsRadiusOverride(physics.radius)
	MakeCharacterPhysics(inst, physics.mass, physics.radius)
	inst.Physics:SetFriction(10)
	inst.DynamicShadow:SetSize(unpack(physics.shadow))
    inst.Transform:SetFourFaced()
    inst.AnimState:Hide("head_spikes")
end
--------------------------------------------------------------------------
-- Pristine Function
--------------------------------------------------------------------------
local function PristineFN(inst)
	COMMON_FNS.AddTags(inst, "character", "scarytoprey", "elemental", "flying", "notraptrigger", "NOCLICK")
	------------------------------------------
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
end
--------------------------------------------------------------------------
local pet_values = {
	anim            = "spawn",
	name_override   = "lavaarena_elemental",
	physics         = physics,
	physics_init_fn = PhysicsInit,
	pristine_fn     = PristineFN,
	stategraph      = "SGgolem",
	brain           = require("brains/golembrain"),
	sounds = {
		enter  = sound_path .. "enter",
		idle   = sound_path .. "idle_LP",
		hit    = sound_path .. "hit",
		attack = sound_path .. "attack",
		death  = sound_path .. "death",
	},
	sentry = true,
	combat = true,
	retarget_period = 0.5, -- TODO baby spiders had 1, should they match?
	RetargetFn = FORGE_TARGETING.PetSentryRetargetFn,
	KeepTarget = FORGE_TARGETING.PetSentryKeepTarget,
}
--------------------------------------------------------------------------
local function fn()
    local inst = COMMON_FNS.CommonPetFN("lavaarena_elemental_basic", nil, pet_values, tuning_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	inst:AddComponent("inventory")
	inst.weapon = COMMON_FNS.EQUIPMENT.ProjectileWeaponInit(inst, tuning_values.PROJECTILE, tuning_values.DAMAGE, TUNING.FORGE.DAMAGETYPES.MAGIC, tuning_values.ATTACK_PERIOD)
	inst.components.inventory:Equip(inst.weapon)
	------------------------------------------
	inst.no_knockback = true
	inst.duration     = tuning_values.LIFE_TIME
	inst.SetCaster    = SetCaster
	inst.SetCharged   = SetCharged
	inst:DoTaskInTime(0, function()
		inst.death_timer  = inst:DoTaskInTime(inst.caster and inst.caster.components.buffable and inst.caster.components.buffable:ApplyStatBuffs({"spell_duration"}, inst.duration) or inst.duration, Die)
	end)
	------------------------------------------
	COMMON_FNS.PetStatTrackerInit(inst)
	------------------------------------------
	local _oldRemove = inst.Remove
	inst.Remove = function()
		inst.weapon:Remove() -- Remove Weapon
		_oldRemove(inst)
	end
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
return ForgePrefab("golem", fn, nil, nil, nil, tuning_values.ENTITY_TYPE, nil, "images/reforged.xml", "pet_golem.tex")
