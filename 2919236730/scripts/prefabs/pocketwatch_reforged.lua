--TODO Leo: For the love of god, we really need to set a standard for naming these things. Too inconsistent. 

local assets = {
    Asset("ANIM", "anim/pocketwatch_weapon.zip"),
}
local prefabs = {
    "pocketwatch_weapon_fx",
    "reticuleaoe",
    "reticuleaoeping",
    "reticuleaoehostiletarget",
}
local tuning_values = TUNING.FORGE.POCKETWATCH_REFORGED
--------------------------------------------------------------------------
-- FX Functions
--------------------------------------------------------------------------
local function TryStartFx(inst, owner)
    owner = owner or inst.components.equippable:IsEquipped() and inst.components.inventoryitem.owner
    if not owner then return end

    if inst._vfx_fx_inst == nil then
        inst._vfx_fx_inst = SpawnPrefab("pocketwatch_weapon_fx")
        inst._vfx_fx_inst.entity:AddFollower()
        inst._vfx_fx_inst.entity:SetParent(owner.entity)
        inst._vfx_fx_inst.Follower:FollowSymbol(owner.GUID, "swap_object", 15, 70, 0)
    end
end

local function StopFx(inst)
    if inst._vfx_fx_inst then
        inst._vfx_fx_inst:Remove()
        inst._vfx_fx_inst = nil
    end
end
--------------------------------------------------------------------------
-- Attack Functions
--------------------------------------------------------------------------
local function OnAttack(inst, attacker, target)
    COMMON_FNS.CreateFX("weaponsparks_fx", target, attacker) -- TODO should there be sparks?
    --inst.SoundEmitter:PlaySound("wanda2/characters/wanda/watch/weapon/attack")
    inst.SoundEmitter:PlaySound("wanda2/characters/wanda/watch/weapon/shadow_attack")
end
--------------------------------------------------------------------------
-- Ability Functions
--------------------------------------------------------------------------
local function TimeWarp(inst, caster, pos)
    local x, y, z = pos:Get()
    -- Revert
    local revert_targets = TheSim:FindEntities(x, y, z, inst.range, nil, COMMON_FNS.GetEnemyTags(inst), COMMON_FNS.GetAllyTags(inst))
    for _,target in pairs(revert_targets) do
        if target.components.health then
            local clock_fx = COMMON_FNS.CreateFX("pocketwatch_ground_fx", target, nil, {position = target:GetPosition()})
            local prev_health = target.components.health:GetHistoryPosition(true)
            if prev_health then
                if target.components.health:IsDead() and target.components.revivablecorpse and prev_health > 0 then
                    target.components.revivablecorpse:AddCharge(inst, prev_health, nil, 1)
                elseif not target.components.health:IsDead() then
                    local heal_fx = COMMON_FNS.CreateFX("pocketwatch_heal_fx", target, nil, {position = target:GetPosition()})
                    local current_health = target.components.health:GetPercent()
                    local heal = (prev_health - current_health) * target.components.health.maxhealth
                    target.components.health:DoDelta(heal, nil, "time_warp", true, caster, true)
                end
            end
        end
    end

    -- Freeze
    local mults, adds, flats = caster and caster.components.buffable and caster.components.buffable:GetStatBuffs({"spell_duration"}) or 1,1,0
    local freeze_targets = TheSim:FindEntities(x, y, z, inst.range, nil, COMMON_FNS.GetAllyTags(inst), COMMON_FNS.GetEnemyTags(inst))
    for _,target in pairs(freeze_targets) do
        if target:IsValid() and not (target.components.health and target.components.health:IsDead()) and target.components.timelockable then
            local clock_fx = COMMON_FNS.CreateFX("pocketwatch_ground_fx", target, nil, {position = target:GetPosition()})
            local has_constant_duration = target.components.timelockable:HasConstantDuration()
            local duration = target.components.timelockable:GetDuration()
            duration = not has_constant_duration and (duration * mults * adds + flats) or duration
            target:PushEvent("time_locked", {duration = duration, doer = caster})
        end
    end

    inst.components.rechargeable:StartRecharge()
    inst.components.aoespell:OnSpellCast(caster)
end
--------------------------------------------------------------------------
-- Pristine Functions
--------------------------------------------------------------------------
local function PristineFN(inst)
    inst.entity:AddSoundEmitter()
    ------------------------------------------
    COMMON_FNS.AddTags(inst, "pocketwatch", "shadow_item")
end
--------------------------------------------------------------------------
local weapon_values = {
    name_override = "pocketwatch_weapon",
    image_name    = "pocketwatch_weapon",
    swap_strings  = {"pocketwatch_weapon", "swap_object"},
    AOESpell      = TimeWarp,
    OnAttack      = OnAttack,
    onequip_fn    = TryStartFx,
    onunequip_fn  = StopFx,
    pristine_fn   = PristineFN,
}
--------------------------------------------------------------------------
local function fn()
    local inst = COMMON_FNS.EQUIPMENT.CommonWeaponFN("pocketwatch_weapon", nil, weapon_values, tuning_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    inst.range = tuning_values.RANGE
    ------------------------------------------
    return inst
end
--------------------------------------------------------------------------
return ForgePrefab("pocketwatch_reforged", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/inventoryimages2.xml", "pocketwatch_weapon.tex", "pocketwatch_weapon", "common_hand")
