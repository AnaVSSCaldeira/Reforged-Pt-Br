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
	when using barrage in a crowd of enemies, enemies behind the character may get hit by the darts
	dart spread is incorrect for barrage
--]]
local assets = {
    Asset("ANIM", "anim/slingshot.zip"),
    Asset("ANIM", "anim/swap_slingshot.zip"),
    Asset("ANIM", "anim/floating_items.zip"),
}
local assets_projectile = {
    Asset("ANIM", "anim/lavaarena_blowdart_attacks.zip"),
	Asset("ANIM", "anim/forge_slingshot_projectile.zip"),
	Asset("ANIM", "anim/slingshotammo.zip"),
}
local prefabs = {
    "forgedarts_projectile",
    "forgedarts_projectile_alt",
    "reticulelongmulti",
    "reticulelongmultiping",
}
local prefabs_projectile = {
    "weaponsparks_piercing_fx",
}
local PROJECTILE_DELAY = 4 * FRAMES -- TODO tuning? if tuning might be able to put in common prefab fn
local tuning_values = TUNING.FORGE.FORGE_SLINGSHOT
--------------------------------------------------------------------------
-- Attack Functions
--------------------------------------------------------------------------
local function ShakeIfClose(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, .4, .02, .2, inst, 30)
end

local function OnHit_Alt(inst, attacker, target)
	local explosion_fx = COMMON_FNS.CreateFX("explosivehit", target, attacker)
    explosion_fx.Transform:SetPosition(inst:GetPosition():Get())
	ShakeIfClose(inst)
	if inst.owner then
        local scale = inst.Transform:GetScale()
		local targets = COMMON_FNS.EQUIPMENT.GetAOETargets(attacker, inst:GetPosition(), tuning_values.ALT_RADIUS*scale, {"_combat", "LA_mob"}, {"player", "companion", "notarget"})
		inst.owner.components.weapon:DoAltAttack(attacker, targets, inst, "explosive")
	end
	if target and target.components.debuffable then
		target.components.debuffable:AddDebuff("debuff_mfd", "debuff_mfd")
	end
	inst:Remove()
end
--------------------------------------------------------------------------
-- Ability Functions
--------------------------------------------------------------------------
local function Powershot(inst, caster, pos)
	local damage = caster.components.combat:CalcDamage(nil, inst, nil, true)
	local proj = SpawnPrefab("forge_slingshot_projectile_alt")
	proj.owner = inst
	proj.Transform:SetPosition(inst:GetPosition():Get())
	proj.components.projectile:AimedThrow(inst, caster, pos, 0, true)
	proj.components.projectile:SetOnHitFn(OnHit_Alt)
	--caster.SoundEmitter:PlaySound("dontstarve/common/lava_arena/blow_proj_spread")
	inst.components.rechargeable:StartRecharge()
	inst.components.aoespell:OnSpellCast(caster, nil, proj)
end
--------------------------------------------------------------------------
-- Pristine Functions
--------------------------------------------------------------------------
local function PristineFN(inst)
	COMMON_FNS.AddTags(inst, "slingshot", "aoeblowdart_long")
	------------------------------------------
	inst.projectiledelay = PROJECTILE_DELAY
end
--------------------------------------------------------------------------
local weapon_values = {
	name_override = "slingshot",
	swap_strings  = {"swap_slingshot"},
	projectile    = "forge_slingshot_projectile",
	AOESpell      = Powershot,
	pristine_fn   = PristineFN,
}
--------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.EQUIPMENT.CommonWeaponFN("slingshot", nil, weapon_values, tuning_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
-- Projectile Functions
--------------------------------------------------------------------------
local function OnUpdateProjectileTail(inst)
    local tail = inst.CreateTail(inst.tail_values, inst)
    tail.Transform:SetPosition(inst.Transform:GetWorldPosition())
    tail.Transform:SetRotation(inst.Transform:GetRotation())
end

local function OnHit(inst, attacker, target)
    COMMON_FNS.CreateFX("weaponsparks_piercing_fx", target, attacker)
	inst:Remove()
end
--------------------------------------------------------------------------
local projectile_values = {
	speed         = 30,
	range         = tuning_values.HIT_RANGE,
	hit_dist      = 0.5,
	launch_offset = Vector3(0, 1, 0),
	OnHit         = OnHit,
	alt = {
		speed   = 25,
	},
}
local tail_values = {
    bank  = "forge_slingshot_projectile",
    build = "forge_slingshot_projectile",
    anim  = "trail",
    OnUpdateProjectileTail = OnUpdateProjectileTail,
}
--------------------------------------------------------------------------
local function commonprojectilefn(alt)
	projectile_values.pristine_fn = function(inst)
	    inst.entity:AddSoundEmitter()
	    ------------------------------------------
		if not alt then
			inst.AnimState:SetAddColour(0.5, 0.5, 0, 0)
		end
		------------------------------------------
	    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	end
	------------------------------------------
	local inst = COMMON_FNS.EQUIPMENT.CommonProjectileFN("forge_slingshot_projectile", "forge_slingshot_projectile", alt and "attack_alt" or "attack_idle", projectile_values, tail_values)
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
local function projectilefn()
    return commonprojectilefn(false)
end

local function projectilealtfn()
    return commonprojectilefn(true)
end
--------------------------------------------------------------------------
return ForgePrefab("forge_slingshot", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/inventoryimages2.xml", "slingshot.tex", "swap_slingshot", "common_hand"),
    Prefab("forge_slingshot_projectile", projectilefn, assets_projectile, prefabs_projectile),
    Prefab("forge_slingshot_projectile_alt", projectilealtfn, assets_projectile, prefabs_projectile)
