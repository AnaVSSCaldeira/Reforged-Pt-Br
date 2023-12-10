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
    edit the projectile, comminize it if possible (if nothing changes then 3 darts have the same projectile stuff)
--]]
local assets = {
    Asset("ANIM", "anim/lavaarena_seeddart2.zip"),
    Asset("ANIM", "anim/swap_blowdart_lava.zip"),
}
local assets_projectile = {
    Asset("ANIM", "anim/lavaarena_blowdart_attacks.zip"),
}
local prefabs = {
    "forgedarts_projectile",
    "reticuleaoesmall",
    "reticuleaoesmallping",
    "reticuleaoesmallhostiletarget",
}
local prefabs_projectile = {
    "weaponsparks_piercing_fx",
}
local PROJECTILE_DELAY = 4 * FRAMES -- TODO tuning? if tuning might be able to put in common prefab fn
local tuning_values = TUNING.FORGE.LAVAARENA_SEEDDART2
--------------------------------------------------------------------------
-- Ability Functions
--------------------------------------------------------------------------
local function PlantSnaptooth(inst, caster, pos)
    local flytrap = COMMON_FNS.Summon("mean_flytrap", caster, pos)
    flytrap:UpdatePetLevel(3, true, true)
    flytrap.wants_to_become_adult = true
    inst.components.rechargeable:StartRecharge() -- TODO should these 2 lines be a common function???
    inst.components.aoespell:OnSpellCast(caster)
end
--------------------------------------------------------------------------
-- Attack Functions
--------------------------------------------------------------------------
-- TODO battlecry does not apply to these shots, find a way to get it to?
local total_projectiles = 2 -- must be even
local angle_between_projectiles = 10
local function SpreadShot(weapon, attacker, target)
    local attacker_pos = attacker:GetPosition()
    local target_pos = target:GetPosition()
    local current_angle = -attacker:GetRotation()

    for i=1,total_projectiles do
        local projectile = SpawnPrefab("snaptooth_seed_projectile")
        projectile.Transform:SetPosition(attacker_pos:Get())
        -- Calculate offset for current projectile
        local angle = (current_angle + (i - (total_projectiles - (total_projectiles/2 < i and 1 or 0))) * angle_between_projectiles) * DEGREES
        local offset = tuning_values.HIT_RANGE
        local offset_pos = Point(offset*math.cos(angle), 0, offset*math.sin(angle))
        -- Throw Projectile
        projectile.components.projectile:AimedThrow(weapon, attacker, attacker_pos + offset_pos, tuning_values.damage, false, nil)
        projectile.components.projectile:DelayVisibility(weapon.projectiledelay)
    end
end
--------------------------------------------------------------------------
-- Pristine Functions
--------------------------------------------------------------------------
local function PristineFN(inst)
    COMMON_FNS.AddTags(inst, "blowdart", "plant_seed", "sharp")
    ------------------------------------------
    inst.projectiledelay = PROJECTILE_DELAY
end
--------------------------------------------------------------------------
local weapon_values = {
    swap_strings = {"swap_lavaarena_seeddart2"},
	projectile   = "snaptooth_seed_projectile",
	AOESpell     = PlantSnaptooth,
    hit_weight   = tuning_values.HIT_WEIGHT,
    pristine_fn  = PristineFN,
}
--------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.EQUIPMENT.CommonWeaponFN("lavaarena_seeddart2", nil, weapon_values, tuning_values)
    ------------------------------------------
    inst.components.aoetargeting:SetRange(1) -- TODO tuning?
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
    inst.components.inventoryitem.atlasname = "images/reforged.xml"
	------------------------------------------
    inst.components.weapon:SetOnProjectileLaunch(SpreadShot)
    ------------------------------------------
    return inst
end
--------------------------------------------------------------------------
-- Projectile Functions
--------------------------------------------------------------------------
local FADE_FRAMES = 5
local function OnUpdateProjectileTail(inst)
    local c = (not inst.entity:IsVisible() and 0) or (inst._fade and (FADE_FRAMES - inst._fade:value() + 1) / FADE_FRAMES) or 1
    if c > 0 then -- TODO what is c?
        local tail = inst.CreateTail(inst.tail_values, inst)
        tail.Transform:SetPosition(inst.Transform:GetWorldPosition())
        tail.Transform:SetRotation(inst.Transform:GetRotation())
        if c < 1 then
            tail.AnimState:SetTime(c * tail.AnimState:GetCurrentAnimationLength())
        end
    end
end

local function OnHit(inst, attacker, target)
    COMMON_FNS.CreateFX("weaponsparks_piercing_fx", target, attacker)
	inst:Remove()
end
--------------------------------------------------------------------------
local projectile_values = {
	speed         = 35,
	range         = tuning_values.HIT_RANGE,
	hit_dist      = 0.5,
	launch_offset = Vector3(-2, 1, 0),
	OnHit         = OnHit,
    add_colour    = {1,1,0,0},
}
local tail_values = {
    bank        = "lavaarena_blowdart_attacks",
    build       = "lavaarena_blowdart_attacks",
    anim        = "tail_1",
    orientation = ANIM_ORIENTATION.OnGround,
    OnUpdateProjectileTail = OnUpdateProjectileTail,
}
--------------------------------------------------------------------------
local function projectilefn(alt)
    projectile_values.pristine_fn = function(inst)
        inst.entity:AddSoundEmitter()
        ------------------------------------------
        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        ------------------------------------------
        COMMON_FNS.AddTags(inst, "dart")
        ------------------------------------------
        if alt then
            inst._fade = net_tinybyte(inst.GUID, "blowdart_lava_projectile_alt._fade")
        end
    end
    ------------------------------------------
    local inst = COMMON_FNS.EQUIPMENT.CommonProjectileFN("lavaarena_blowdart_attacks", "lavaarena_blowdart_attacks", "attack_3", projectile_values, tail_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
    inst._hastail:set(true)
    ------------------------------------------
	inst.SoundEmitter:PlaySound("dontstarve/common/lava_arena/blow_dart")
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
return ForgePrefab("lavaarena_seeddart2", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/reforged.xml", "lavaarena_seeddart2.tex", "swap_lavaarena_seeddart2", "common_hand"),
    Prefab("snaptooth_seed_projectile", projectilefn, assets_projectile, prefabs_projectile)
