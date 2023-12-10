local assets = {
    Asset("ANIM", "anim/pocketwatch_weapon.zip"),
}
local prefabs = {
    "pocketwatch_weapon_fx",
    "reticuleaoe",
    "reticuleaoeping",
    "reticuleaoehostiletarget",
}
local tuning_values = TUNING.FORGE.PORTALSTAFF
local PROJECTILE_DELAY = 4 * FRAMES 
--------------------------------------------------------------------------
-- Attack Functions
--------------------------------------------------------------------------
local function OnSwing(inst, attacker, target)
	local offset = (target:GetPosition() - attacker:GetPosition()):GetNormalized()*1.2
	local particle = COMMON_FNS.CreateFX("forge_shadowball_hit_fx", target, attacker, {scale = 0.8})
	particle.Transform:SetPosition((attacker:GetPosition() + offset):Get())
end
--------------------------------------------------------------------------
-- Ability Functions
--------------------------------------------------------------------------
--[[
TODO
 small cooldown for placing marker or no cooldown?
--]]
local function Portal(inst, caster, pos, options)
    -- Spawn Portal marker
    if not inst.marker or options.ctrl and options.ctrl == 2 then -- TODO what should the ctrl be for marker?
        if inst.marker then
            inst.marker:Remove()
        end
        inst.marker = SpawnPrefab("pocketwatch_warp_marker")
        inst.marker.Transform:SetPosition(pos:Get())
        inst.marker:ShowMarker()
        inst.SoundEmitter:PlaySound("wanda2/characters/wanda/watch/MarkPosition")
        inst.components.aoespell.casting = false
    -- Spawn Portal
    else
        local marker_pos = inst.marker:GetPosition()
        local portal = SpawnPrefab("pocketwatch_portal_entrance") 
        portal.Transform:SetPosition(pos:Get())
        portal:SpawnExit(TheShard:GetShardId(), marker_pos.x, marker_pos.y, marker_pos.z)
        inst.SoundEmitter:PlaySound("wanda1/wanda/portal_entrance_pre")

        inst.components.rechargeable:StartRecharge()
        inst.components.aoespell:OnSpellCast(caster)
    end
end

local function RemoveMarker(inst)
    if inst.marker then
        inst.marker:Remove()
    end
end
--------------------------------------------------------------------------
-- Pristine Functions
--------------------------------------------------------------------------
local function PristineFN(inst)
    inst.entity:AddSoundEmitter()
    ------------------------------------------
    COMMON_FNS.AddTags(inst, "magicweapon", "rangedweapon")
    ------------------------------------------
    inst.ability_strings = {"PORTAL_ACTIVATE", "PORTAL_TARGET"}
    ------------------------------------------
    inst.AnimState:SetScale(1.2, 1.2)
    ------------------------------------------
    inst.projectiledelay = PROJECTILE_DELAY
end
--------------------------------------------------------------------------
local weapon_values = {
    anim          = "idle_loop",
    swap_strings  = {"swap_rf_time_staff"},
    AOESpell      = Portal,
	projectile    = "rf_shadowball_projectile",
    projectile_fn = OnSwing,
    pristine_fn   = PristineFN,
}
--------------------------------------------------------------------------
local function fn()
    local inst = COMMON_FNS.EQUIPMENT.CommonWeaponFN("rf_time_staff", nil, weapon_values, tuning_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end	
	------------------------------------------
	inst.components.inventoryitem.imagename = "rf_time_staff"
	inst.components.inventoryitem.atlasname = "images/reforged.xml"
    ------------------------------------------
    inst:ListenForEvent("onremove", RemoveMarker)
    ------------------------------------------
    return inst
end
--------------------------------------------------------------------------
--TODO rename to rf_time_staff? 
return ForgePrefab("portalstaff", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/reforged.xml", "rf_time_staff.tex", "swap_rf_time_staff", "common_hand")
