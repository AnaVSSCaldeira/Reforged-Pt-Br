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
    Asset("ANIM", "anim/spear_gungnir.zip"),
    Asset("ANIM", "anim/swap_spear_gungnir.zip"),
}
local assets_fx = {
    Asset("ANIM", "anim/lavaarena_blowdart_attacks.zip"),
}
local prefabs = {
    "reticuleline",
    "reticulelineping",
    "spear_gungnir_lungefx",
    "weaponsparks_fx",
    "firehit",
}
local tuning_values = TUNING.FORGE.LAVAARENA_GAUNTLET
--------------------------------------------------------------------------
-- Ability Functions
--------------------------------------------------------------------------
local function ChargedPunch(inst, caster, pos)
	caster:PushEvent("combat_punch", {
		targetpos = pos,
		weapon = inst
	})
    inst.components.rechargeable:StartRecharge()
    inst.components.aoespell:OnSpellCast(caster)
    --TODO Leo: I want to make a few more visual improvements to the alt attack in a future update, might have to creature custom FX.
    --Also could do with better sounds...
end
--------------------------------------------------------------------------
-- Attack Functions
--------------------------------------------------------------------------
local function OnAttack(inst, attacker, target)
	if not inst.components.weapon.isaltattacking then
        COMMON_FNS.CreateFX("weaponsparks_fx", target, attacker)
        COMMON_FNS.EQUIPMENT.ApplyArmorBreak(attacker, target)
	end
end

local ATTACK_KNOCKBACK = 2 -- TODO tuning, also make size a mob a factor in the knockback
local function OnHitOther(inst, data)
    local weapon = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if weapon and weapon.components.weapon.isaltattacking then
        _G.COMMON_FNS.KnockbackOnHit(inst, data.target, 5, ATTACK_KNOCKBACK, ATTACK_KNOCKBACK, true) -- TODO tuning
    end
end
--------------------------------------------------------------------------
-- Weapon Functions
--------------------------------------------------------------------------
local function OnEquip(inst, owner)
    owner:ListenForEvent("onhitother", OnHitOther)
end

local function OnUnEquip(inst, owner)
    owner:RemoveEventCallback("onhitother", OnHitOther)
end
--------------------------------------------------------------------------
-- Pristine Functions
--------------------------------------------------------------------------
local function PristineFN(inst)
    -- aoeweapon_lunge (from aoeweapon_lunge component) added to pristine state for optimization
    COMMON_FNS.AddTags(inst, "sharp", "pointy", --[["aoeweapon_lunge", ]]"punch")
end
--------------------------------------------------------------------------
local weapon_values = {
    name_override = "lavaarena_gauntlet",
    swap_strings  = {"hand", "swap_lavaarena_gauntlet"},
	OnAttack      = OnAttack,
	AOESpell      = ChargedPunch,
    onequip_fn    = OnEquip,
    onunequip_fn  = OnUnEquip,
    type          = "fist",
    pristine_fn   = PristineFN,
}
--------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.EQUIPMENT.CommonWeaponFN("lavaarena_gauntlet", nil, weapon_values, tuning_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
	inst.components.inventoryitem.atlasname = "images/reforged.xml"
	inst.components.inventoryitem.imagename = "gauntlet"
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
local function CreateFx(parent)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    --[[Non-networked entity]]

    inst.AnimState:SetBuild("lavaarena_blowdart_attacks")
    inst.AnimState:SetBank("lavaarena_blowdart_attacks")
    inst.AnimState:PlayAnimation("attack_4_large", true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(1)

    inst:AddTag("NOCLICK")
    inst:AddTag("DECOR")
    inst:AddTag("FX")

    inst.persists = false
    inst.entity:SetParent(parent.entity)

    return inst
end

local function CreateTail(parent, oneshot)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    --[[Non-networked entity]]

    inst.AnimState:SetBank("lavaarena_fire_fx")
    inst.AnimState:SetBuild("lavaarena_fire_fx")
    inst.AnimState:PlayAnimation("firefissure_warning")
    inst.AnimState:SetTime(6 * FRAMES)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetFinalOffset(1)
    inst.AnimState:SetScale(1.5, 1.5)

    inst:AddTag("NOCLICK")
    inst:AddTag("DECOR")
    inst:AddTag("FX")

    inst.persists = false
    inst.entity:SetParent(parent.entity)

    if oneshot then
        inst:ListenForEvent("animover", inst.Remove)
    end

    return inst
end

local function fxfn(startfn, oneshot)
    return function()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddNetwork()

        inst:AddTag("FX")
        inst:AddTag("NOCLICK")

        if not TheNet:IsDedicated() then
            startfn(inst, oneshot)
        end
        ------------------------------------------
        inst.entity:SetPristine()
        ------------------------------------------
        if not TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------
        inst.persists = false

        if oneshot then
            inst:DoTaskInTime(1, inst.Remove)
        end

        return inst
    end
end
--------------------------------------------------------------------------
return ForgePrefab("lavaarena_gauntlet", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/reforged.xml", "gauntlet.tex", "swap_lavaarena_gauntlet", "common_hand"),
       Prefab("gauntlet_ground_fx", fxfn(CreateFx), assets_fx),
       Prefab("gauntlet_tail_fx", fxfn(CreateTail, true), assets_fx)
