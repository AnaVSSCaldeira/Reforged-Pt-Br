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
    Asset("ANIM", "anim/blowdart_lava.zip"),
    Asset("ANIM", "anim/swap_blowdart_lava.zip"),
}
local assets_projectile = {
    Asset("ANIM", "anim/lavaarena_blowdart_attacks.zip"),
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
local tuning_values = TUNING.FORGE.FORGEDARTS
--------------------------------------------------------------------------
-- Ability Functions
--------------------------------------------------------------------------
local function Barrage(inst, caster, pos)
	local damage = caster.components.combat:CalcDamage(nil, inst, nil, true)
	local darts = {}
	for i = 1,6 do -- TODO tuning 6 TOTAL_DARTS???
		inst:DoTaskInTime(0.08 * i, function()
            local caster_scale = caster.components.scaler and caster.components.scaler.scale or 1
			local scaler = math.random()*2.5 - 1.25
			local offset = Vector3(math.random(), 0, math.random()):Normalize()*scaler*caster_scale
			local dart = SpawnPrefab("forgedarts_projectile_alt")
			if i == 1 then dart.components.projectile:SetStimuli("strong") end
			dart.Transform:SetPosition((inst:GetPosition() + offset):Get())
			dart.components.projectile:AimedThrow(inst, caster, pos + offset, damage, true)
			dart.components.projectile:DelayVisibility(inst.projectiledelay)
			table.insert(darts, dart)
		end)
	end
	caster.SoundEmitter:PlaySound("dontstarve/common/lava_arena/blow_dart_spread")
	inst.components.rechargeable:StartRecharge()
	inst.components.aoespell:OnSpellCast(caster, nil, darts)
end
--------------------------------------------------------------------------
-- Pristine Functions
--------------------------------------------------------------------------
local function PristineFN(inst)
	COMMON_FNS.AddTags(inst, "blowdart", "aoeblowdart_long", "sharp")
	------------------------------------------
	inst.projectiledelay = PROJECTILE_DELAY
end
--------------------------------------------------------------------------
local weapon_values = {
	name_override = "blowdart_lava",
	swap_strings  = {"swap_blowdart_lava"},
	projectile    = "forgedarts_projectile",
	AOESpell      = Barrage,
	pristine_fn   = PristineFN,
}
--------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.EQUIPMENT.CommonWeaponFN("blowdart_lava", nil, weapon_values, tuning_values)
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
	if target then
		-- TODO is there a better way than this?
		-- Used to determine if a spinning snortoise should be interrupted
		target.dartalt_hits = target.dartalt_hits and (target.dartalt_hits + 1) or 1
		if not target.dartalt_task then
			target.dartalt_task = target:DoTaskInTime(1, function(inst)
				inst.dartalt_hits = nil
			end)
		end
	end
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
local function commonprojectilefn(alt)
	projectile_values.pristine_fn = function(inst)
	    inst.entity:AddSoundEmitter()
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
return ForgePrefab("forgedarts", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/inventoryimages.xml", "blowdart_lava.tex", "swap_blowdart_lava", "common_hand"),
    Prefab("forgedarts_projectile", projectilefn, assets_projectile, prefabs_projectile),
    Prefab("forgedarts_projectile_alt", projectilealtfn, assets_projectile, prefabs_projectile)
