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
    Asset("ANIM", "anim/healingstaff.zip"),
    Asset("ANIM", "anim/swap_healingstaff.zip"),
}
local prefabs = {
    "forge_blossom_projectile",
    "forge_blossom_hit_fx",
    "lavaarena_healblooms",
    "reticuleaoe",
    "reticuleaoeping",
    "reticuleaoefriendlytarget",
}
local PROJECTILE_DELAY = 4 * FRAMES -- TODO tuning? if tuning might be able to put in common prefab fn
local tuning_values = TUNING.FORGE.LIVINGSTAFF
--------------------------------------------------------------------------
-- Ability Functions
--------------------------------------------------------------------------
local function LifeBlossom(inst, caster, pos)
	local heal_rate = inst.heal_rate
	local boosted = false
	if caster.components.buffable then
		heal_rate = caster.components.buffable:ApplyStatBuffs({"spell_heal_rate", "heal_dealt"}, heal_rate)
		boosted = heal_rate > inst.heal_rate -- TODO use TUNING.FORGE
	end
	local circle = SpawnAt("healingcircle", pos)
	local cc = circle.components.heal_aura
	cc.heal_rate = heal_rate
	cc.caster = caster
    cc.range = cc.range * (caster and caster.components.scaler.scale or 1)
	circle.buffed = boosted
    circle.caster = caster
	Debug:Print("Heal: " .. tostring(heal_rate) .. "/s", nil, "LifeBlossom", nil, true)
	TheWorld:PushEvent("healingcircle_spawned")
	inst.components.aoespell:OnSpellCast(caster) -- TODO anything special here?
	inst.components.rechargeable:StartRecharge()
end
--------------------------------------------------------------------------
-- Attack Functions
--------------------------------------------------------------------------
local function OnSwing(inst, attacker, target)
	inst.SoundEmitter:PlaySound("dontstarve/common/lava_arena/heal_staff")
	local offset = (target:GetPosition() - attacker:GetPosition()):GetNormalized()*1.2
	local particle = COMMON_FNS.CreateFX("forge_blossom_hit_fx", target, attacker, {scale = 0.8})
	particle.Transform:SetPosition((attacker:GetPosition() + offset):Get())
end
--------------------------------------------------------------------------
-- Pristine Functions
--------------------------------------------------------------------------
local function PristineFN(inst)
	inst.entity:AddSoundEmitter()
	------------------------------------------
	COMMON_FNS.AddTags(inst, "rangedweapon", "magicweapon")
	------------------------------------------
	inst.projectiledelay = PROJECTILE_DELAY
end
--------------------------------------------------------------------------
local weapon_values = {
	name_override = "healingstaff",
	swap_strings  = {"swap_healingstaff"},
	projectile    = "forge_blossom_projectile",
	projectile_fn = OnSwing,
	AOESpell      = LifeBlossom,
	pristine_fn   = PristineFN,
}
--------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.EQUIPMENT.CommonWeaponFN("healingstaff", nil, weapon_values, tuning_values)
	------------------------------------------
	if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
    inst.castsound = "dontstarve/common/lava_arena/spell/heal" -- TODO move into sound table?
	inst.heal_rate = tuning_values.HEAL_RATE -- per second
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
return ForgePrefab("livingstaff", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/inventoryimages.xml", "healingstaff.tex", "swap_healingstaff", "common_hand")
