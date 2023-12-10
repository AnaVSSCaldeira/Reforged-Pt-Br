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
    go through projectile prefab below
    edit the projectile, comminize it if possible (if nothing changes then 3 darts have the same projectile stuff)
--]]
local assets = {
    Asset("ANIM", "anim/lavaarena_seeddart.zip"),
    Asset("ANIM", "anim/swap_lavaarena_seeddart.zip"),
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
local tuning_values = TUNING.FORGE.LAVAARENA_SEEDDARTS
--------------------------------------------------------------------------
-- Ability Functions
--------------------------------------------------------------------------
local function PlantSeedling(inst, caster, pos) -- TODO this code is the same as golems, might be some difference later on, but for the most part it's the same, create common fn for it.
    local flytrap = COMMON_FNS.Summon("mean_flytrap", caster, pos)
    inst.components.rechargeable:StartRecharge()
    inst.components.aoespell:OnSpellCast(caster)
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
    swap_strings = {"swap_lavaarena_seeddart"},
	projectile   = "seed_projectile",
	AOESpell     = PlantSeedling,
    pristine_fn  = PristineFN,
}
--------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.EQUIPMENT.CommonWeaponFN("lavaarena_seeddart", nil, weapon_values, tuning_values)
    ------------------------------------------
    inst.components.aoetargeting:SetRange(1) -- TODO tuning?
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
	inst.components.inventoryitem.atlasname = "images/reforged.xml"
    --inst.components.inventoryitem:ChangeImageName("lavaarena_seeddart2") -- TODO why is this not working?
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
    local inst = COMMON_FNS.EQUIPMENT.CommonProjectileFN("lavaarena_blowdart_attacks", "lavaarena_blowdart_attacks", "attack_3", projectile_values, tail_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    inst._hastail:set(true)
	------------------------------------------
	if alt then
		inst.components.projectile:SetRange(tuning_values.ALT_RANGE)
	end
	------------------------------------------
	inst.SoundEmitter:PlaySound("dontstarve/common/lava_arena/blow_dart")
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
return ForgePrefab("lavaarena_seeddarts", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/reforged.xml", "lavaarena_seeddart.tex", "swap_lavaarena_seeddart", "common_hand"),
    Prefab("seed_projectile", projectilefn, assets_projectile, prefabs_projectile)
