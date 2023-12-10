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
    Asset("ANIM", "anim/swap_lavaarena_spicebomb.zip"),
	Asset("ANIM", "anim/lavaarena_spicebomb.zip"),
	Asset("ANIM", "anim/lavaarena_spicebomb_def_build.zip"),
	Asset("ANIM", "anim/lavaarena_spicebomb_dmg_build.zip"),
	Asset("ANIM", "anim/lavaarena_spicebomb_speed_build.zip"),
	Asset("ANIM", "anim/lavaarena_spicebomb_regen_build.zip"),
}
local assets_fx = {
    Asset("ANIM", "anim/lavaarena_firebomb.zip"),
    Asset("ANIM", "anim/spices.zip"),
}
local assets_sparks = {
    Asset("ANIM", "anim/sparks_molotov.zip"),
}
local prefabs = {
    "firebomb_projectile",
    "firebomb_proc_fx",
    "firebomb_sparks",
    "sleepbomb_burst",
    "sleepcloud",
    "reticuleaoesmall",
    "reticuleaoesmallping",
    "reticuleaoesmallhostiletarget",
}
local prefabs_projectile = {
    "firebomb_explosion",
    "firehit",
}
local tuning_values = TUNING.FORGE.SPICE_BOMB
--------------------------------------------------------------------------
-- Ability Functions
--------------------------------------------------------------------------
-- TODO COMMON FN
local function DoSpiceAoe(weapon, projectile, caster, target_pos, radius, damage, excluded_targets, is_alt)
	local targets = COMMON_FNS.EQUIPMENT.GetAOETargets(caster, target_pos, radius, nil, COMMON_FNS.GetPlayerExcludeTags(caster), nil, excluded_targets)
	for _,target in pairs(targets) do
		caster.components.combat:DoAttack(target, weapon, projectile, tuning_values.STIMULI, nil, damage, is_alt)
	end
end

local function GiveBuffToTargets(inst, targets, projectile, caster, is_buff, is_impact)
    for _,target in pairs(targets) do
        local debuffable = target.components.debuffable
        if debuffable and debuffable:IsEnabled() then
            local name = "debuff_spice_" .. (projectile.spice_type or "regen")
            debuffable:AddDebuff(name, "debuff_spice")
            local debuff_spice = debuffable:GetDebuff(name)
            if debuff_spice then
                debuff_spice:SetCaster(caster)
                debuff_spice:SetSpiceType(projectile.spice_type)
                debuff_spice:SetIsBuff(is_buff)
                debuff_spice:SetMult(is_impact and 1 or tuning_values.LINGERING_MULT)
                debuff_spice:SetSource(inst)
            end
            inst.targets[target] = target
        end
    end
end

local function ApplySpiceBuffs(inst, weapon, projectile, caster, target_pos, radius, damage, excluded_targets, is_alt, is_impact)
    -- Buff players and their comrades
    GiveBuffToTargets(inst, COMMON_FNS.EQUIPMENT.GetAOETargets(caster, target_pos, radius, nil, COMMON_FNS.CommonExcludeTags(caster, true), nil, inst.targets, nil, true), projectile, caster, true, is_impact)
    -- Debuff enemies
    GiveBuffToTargets(inst, COMMON_FNS.EQUIPMENT.GetAOETargets(caster, target_pos, radius, nil, COMMON_FNS.CommonExcludeTags(caster), nil, inst.targets, nil, true), projectile, caster, false, is_impact)
end

local function OnEquipfn(inst, owner)
	if inst.spice_type then
		owner.AnimState:ClearOverrideSymbol("swap_object")
		owner.AnimState:OverrideSymbol("swap_object", "swap_lavaarena_spicebomb", "swap_lavaarena_spicebomb")
	end
end

local spice_type_lookup = {"regen", "dmg", "def", "speed"}
local function SpicebombToss(inst, caster, pos, options)
	local projectile = SpawnPrefab("spice_buff_bomb_" .. (options.ctrl and spice_type_lookup[options.ctrl] or "regen") .. "_projectile")
	projectile.Transform:SetPosition(inst:GetPosition():Get())
	projectile.owner = caster
	projectile.components.complexprojectile:Launch(pos, caster, inst, caster.components.combat:CalcDamage(nil, inst, nil, true, nil, tuning_values.ALT_STIMULI), true)
	inst.components.rechargeable:StartRecharge()
	inst.components.aoespell:OnSpellCast(caster)
end

local function GetStimuliFn(inst, owner, target)
    return inst.charge == tuning_values.MAXIMUM_CHARGE_HITS and tuning_values.ALT_STIMULI or tuning_values.STIMULI
end
--------------------------------------------------------------------------
-- Pristine Functions
--------------------------------------------------------------------------
local function PristineFN(inst)
    inst.entity:AddSoundEmitter()
    ------------------------------------------
    inst:AddTag("throw_line")
    ------------------------------------------
    inst.ability_strings = {"SPICE_BOMB_HEAL", "SPICE_BOMB_ATTACK", "SPICE_BOMB_DEFENSE", "SPICE_BOMB_SPEED"}
end
--------------------------------------------------------------------------
local weapon_values = {
    swap_strings = {"swap_lavaarena_spicebomb"},
	AOESpell     = SpicebombToss,
	--OnAttack     = OnHitOther,
	onequip_fn   = OnEquipfn,
    --onunequip_fn = ResetCharge,
    projectile   = "spice_bomb_projectile",
    pristine_fn  = PristineFN,
}
--------------------------------------------------------------------------
local function fn()
    local inst = COMMON_FNS.EQUIPMENT.CommonWeaponFN("lavaarena_spicebomb", "lavaarena_spicebomb_normal_build", weapon_values, tuning_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
	inst.components.inventoryitem.imagename = "spice_bomb" --TODO find out why it couldn't get to it manually? It worked before I changed the art...
	inst.components.inventoryitem.atlasname = "images/reforged.xml"
    ------------------------------------------
    inst.spice_type = "regen"
	------------------------------------------
    inst.components.weapon:SetOverrideStimuliFn(GetStimuliFn)
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
-- Projectile Functions
--------------------------------------------------------------------------
local function CreateProjectileAnim(bank, build, anim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    ------------------------------------------
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    ------------------------------------------
    --[[Non-networked entity]]
    inst.persists = false
    ------------------------------------------
    inst.AnimState:SetBank(bank or "lavaarena_spicebomb")
    inst.AnimState:SetBuild(build or "lavaarena_spicebomb")
    inst.AnimState:PlayAnimation(anim or "spin", true)
    ------------------------------------------
    return inst
end

local function OnDirectionDirty(inst)
    inst.animent.Transform:SetRotation(inst.direction:value())
end

local function onthrown(inst, owner)
    inst:AddTag("NOCLICK")
    inst.persists = false

    --inst.Physics:SetMass(1)
    --inst.Physics:SetCapsule(0.2, 0.2)
    --inst.Physics:SetFriction(0)
    --inst.Physics:SetDamping(0)
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.ITEMS)
end

local spice_colors = {
    dmg   = {1,0,0,1},
    def   = {0,0,1,1},
    regen = {0,1,0,1},
    speed = {1,1,1,1},
}
local function OnHitSpice(inst, attacker, target, weapon, damage)
    local scale = attacker.components.scaler and attacker.components.scaler.scale or 1
    if inst.spice_type then
        local pos = inst:GetPosition()
        local spice_fx = COMMON_FNS.CreateFX("spice_explosion", target, attacker, {scale = 1.25})
        spice_fx.Transform:SetPosition(pos:Get())
        spice_fx:SetSpiceType(inst.spice_type)
        spice_fx:SetDuration(tuning_values.IMPACT_DURATION + tuning_values.LINGERING_DURATION)
        SpawnAt("spice_aoe", inst):ApplyBuffs(weapon, inst, attacker, damage, tuning_values.IMPACT_DURATION, tuning_values.LINGERING_DURATION)
    else
        --SpawnPrefab("sleepbomb_burst").Transform:SetPosition(inst.Transform:GetWorldPosition())
        local spice_explosion_fx = COMMON_FNS.CreateFX("poopcloud", target, attacker)
        spice_explosion_fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        --spice_explosion_fx.AnimState:SetMultColour(unpack(spice_colors.damage))
        DoSpiceAoe(weapon, inst, attacker, inst:GetPosition(), tuning_values.AOE_RADIUS*scale, damage, nil, true)
    end
    inst:Remove()
end
--------------------------------------------------------------------------
-- Physics Functions
--------------------------------------------------------------------------
local physics = {
    mass   = 1,
    radius = 0.2,
}
local function PhysicsInit(inst)
    inst.entity:AddPhysics()
    inst.Physics:SetMass(physics.mass)
    inst.Physics:SetFriction(0)
    inst.Physics:SetDamping(0)
    inst.Physics:SetRestitution(.5)
    inst.Physics:SetCollisionGroup(COLLISION.ITEMS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
    inst.Physics:SetCapsule(physics.radius,physics.radius)
end
--------------------------------------------------------------------------
local projectile_values = {
    physics         = physics,
    physics_init_fn = PhysicsInit,
    complex         = true,
    no_tail         = true,
    speed           = tuning_values.HORIZONTAL_SPEED,
    gravity         = tuning_values.GRAVITY,
    launch_offset   = Vector3(unpack(tuning_values.VECTOR)),
    OnLaunch        = onthrown,
    OnHit           = OnHitSpice,
}
--------------------------------------------------------------------------
local function common_projectilefn(bank, build, anim, is_large)
    projectile_values.pristine_fn = function(inst)
        inst.entity:AddSoundEmitter()
        ------------------------------------------
        inst.Transform:SetTwoFaced()
        ------------------------------------------
        inst.direction = net_float(inst.GUID, "spice_bomb_projectile.direction", "directiondirty")
        ------------------------------------------
        --Dedicated server does not need to spawn the local animation
        if not TheNet:IsDedicated() then
            inst.animent = CreateProjectileAnim(bank, build, anim)
            inst.animent.entity:SetParent(inst.entity)
        end
    end
    ------------------------------------------
    local inst = COMMON_FNS.EQUIPMENT.CommonProjectileFN(nil, nil, nil, projectile_values)
    ------------------------------------------
    if not TheWorld.ismastersim then
        inst:ListenForEvent("directiondirty", OnDirectionDirty)
        return inst
    end
    ------------------------------------------
    if is_large then
        inst.components.complexprojectile:SetHorizontalSpeed(tuning_values.ALT_HORIZONTAL_SPEED)
        inst.components.complexprojectile:SetGravity(tuning_values.ALT_GRAVITY)
        inst.components.complexprojectile:SetLaunchOffset(Vector3(unpack(tuning_values.ALT_VECTOR)))
    end
    ------------------------------------------
    return inst
end

local function spice_bomb_fn()
    local inst = common_projectilefn("lavaarena_spicebomb", "lavaarena_spicebomb_normal_build", "spin", false)
    ------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    return inst
end

local function spice_bomb_damage_fn()
    local inst = common_projectilefn("lavaarena_spicebomb", "lavaarena_spicebomb_dmg_build", "spin", true)
    ------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    inst.spice_type = "dmg"
    ------------------------------------------
    return inst
end

local function spice_bomb_defense_fn()
    local inst = common_projectilefn("lavaarena_spicebomb", "lavaarena_spicebomb_def_build", "spin", true)
    ------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    inst.spice_type = "def"
    ------------------------------------------
    return inst
end

local function spice_bomb_regen_fn()
    local inst = common_projectilefn("lavaarena_spicebomb", "lavaarena_spicebomb_regen_build", "spin", true)
    ------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    inst.spice_type = "regen"
    ------------------------------------------
    return inst
end

local function spice_bomb_speed_fn()
    local inst = common_projectilefn("lavaarena_spicebomb", "lavaarena_spicebomb_speed_build", "spin", true)
    ------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    inst.spice_type = "speed"
    ------------------------------------------
    return inst
end
--------------------------------------------------------------------------
local function explosionfn()
    local inst = COMMON_FNS.FXEntityInit("sleepcloud", "sleepcloud", "sleepcloud_pre", {noanimover = true, pristine_fn = function(inst)
        inst.AnimState:PushAnimation("sleepcloud_loop", true)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetFinalOffset(-1)
    	inst.AnimState:SetScale(1.25, 1.25)
    end})
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    inst.type = "regen"
    inst.SetSpiceType = function(inst, type)
        inst.type = type
		inst:DoTaskInTime(0, function(inst)
			inst.AnimState:SetMultColour(unpack(spice_colors[type] or {0,1,0,0}))
		end)
    end
    inst.SetDuration = function(inst, time)
        inst.loop_timer = inst:DoTaskInTime(time, function(inst)
            inst.AnimState:PlayAnimation("sleepcloud_pst")
            inst:ListenForEvent("animover", inst.Remove)
        end)
    end
	------------------------------------------
	inst.persists = false
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
local function spiceaoefn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    --[[Non-networked entity]]
    ------------------------------------------
    inst.persists = false
    inst:AddTag("CLASSIFIED")
    ------------------------------------------
    inst.entity:SetCanSleep(false)
    ------------------------------------------
    inst:AddComponent("updatelooper")
    ------------------------------------------
    inst.ApplyBuffs = function(inst, weapon, source, attacker, damage, impact_time, lingering_time)
        local scale = attacker.components.scaler and attacker.components.scaler.scale or 1
        local function Apply(inst)
            ApplySpiceBuffs(inst, weapon, source, attacker, inst:GetPosition(), tuning_values.ALT_RADIUS*scale, damage, nil, true, GetTaskRemaining(inst.buffs_task) > lingering_time)
        end
        inst.targets = {}
        inst.components.updatelooper:AddOnUpdateFn(Apply)
        inst.buffs_task = inst:DoTaskInTime((impact_time and impact_time or 1) + (lingering_time and lingering_time or 0), function(inst)
            inst.components.updatelooper:RemoveOnUpdateFn(Apply)
            inst:Remove()
        end)
    end
    ------------------------------------------
    return inst
end
--------------------------------------------------------------------------
return ForgePrefab("spice_bomb", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/reforged.xml", "spice_bomb.tex", "swap_lavaarena_firebomb", "common_hand"),
    Prefab("spice_bomb_projectile", spice_bomb_fn, assets_fx, prefabs_projectile),
    Prefab("spice_buff_bomb_dmg_projectile", spice_bomb_damage_fn, assets_fx, prefabs_projectile),
    Prefab("spice_buff_bomb_def_projectile", spice_bomb_defense_fn, assets_fx, prefabs_projectile),
    Prefab("spice_buff_bomb_regen_projectile", spice_bomb_regen_fn, assets_fx, prefabs_projectile),
    Prefab("spice_buff_bomb_speed_projectile", spice_bomb_speed_fn, assets_fx, prefabs_projectile),
    Prefab("spice_explosion", explosionfn, assets_fx),
    Prefab("spice_aoe", spiceaoefn)
--[[
TODO
Use "alt", "ctrl", "shift", ctrl_mods
playercontroller deciphers it
have text display on ret that shows:
    "leftclick         = Damage Buff"
    "shift + leftclick = Regen Buff"
    "ctrl + leftclick  = Defense Buff"
    "alt + leftclick   = Speed Buff"
Need to make it generalized, so that other weapons can make use of it, and only display text for clicks that are used.

aoe needs to be adjusted slightly to match ret (should be the same as healing aura)
--]]
