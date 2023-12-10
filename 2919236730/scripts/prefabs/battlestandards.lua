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

--Everything below this is my work.
--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
--\\\\Copyright 2018, Leonardo Coxington, All rights reserved.\\\\ -- GlassArrow helped a little bit
--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
local tuning_values = TUNING.FORGE.BATTLESTANDARD
--------------------------------------------------------------------------
-- Structure Functions
--------------------------------------------------------------------------
local function CreatePulse(target)
    local inst = CreateEntity()

    inst:AddTag("DECOR") --"FX" will catch mouseover
    inst:AddTag("NOCLICK")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBank("lavaarena_battlestandard")
    inst.AnimState:SetBuild("lavaarena_battlestandard")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst.entity:SetParent(target.entity)

    return inst
end

local function ApplyPulse(ent, params)
    if ent:HasTag("debuffable") and not (ent.replica.health ~= nil and ent.replica.health:IsDead()) then
        local fx = CreatePulse(ent)
        fx:ListenForEvent("animover", fx.Remove)
        fx.AnimState:PlayAnimation(params.fxanim or "heal_fx")
    end
end

local function OnPulse(inst)
    if inst.fxanim and inst.fx and inst.fx:IsValid() then
        inst.fx.AnimState:PlayAnimation(inst.fxanim)
    end
    if TheWorld.components.lavaarenamobtracker and not inst:HasTag("companion") then
        TheWorld.components.lavaarenamobtracker:ForEachMob(ApplyPulse, { fxanim = inst.fxanim })
	elseif inst:HasTag("companion") then
		for i, v in ipairs(AllPlayers) do
			ApplyPulse(v, {fxanim = inst.fxanim})
		end
    end
end
--[[
TODO
anyway to check for spawned mobs? that way we can just add the buffs on spawn instead of spamming findents?
this would work because spawned mobs are the only mobs that would not have a buff from a banner.
could add an event for spawning mobs?
just seems odd to be spamming this when 99% of the time this will do nothing
--]]
local function DoAura(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 255, nil, TableConcat({"battlestandard", "nobuff"}, COMMON_FNS.GetEnemyTags(inst)), COMMON_FNS.GetAllyTags(inst))
    for _,ent in ipairs(ents) do
        if ent.components.health and not ent.components.health:IsDead() and ent.components.debuffable and not ent.components.debuffable:HasDebuff(inst.debuff_prefab) then
			ent.components.debuffable:AddDebuff(inst.debuff_prefab, inst.debuff_prefab)
		end
    end
	inst.components.debuffable:AddDebuff(inst.debuff_prefab, inst.debuff_prefab)
end

local function RemoveDebuff(ent, params)
    if ent.components.debuffable and ent.components.debuffable:HasDebuff(params.debuff_prefab) then
        ent.components.debuffable:RemoveDebuff(params.debuff_prefab)
    end
end

local function CheckforBuffs(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
	local battlestandards = {}
    local ents = TheSim:FindEntities(x, y, z, 255, inst:HasTag("companion") and {"companion"} or nil, {"playerghost", "ghost", "INLIMBO" }, {"battlestandard"})
    for _,ent in ipairs(ents) do
        if ent.prefab == inst.prefab and ent ~= inst and not ent.components.health:IsDead() then
			table.insert(battlestandards, ent)
		end
    end
    -- If there are no more battlestandards of this kind remove the debuff.
	if #battlestandards <= 0 and TheWorld.components.lavaarenamobtracker then
		if not inst:HasTag("companion") then
			TheWorld.components.lavaarenamobtracker:ForEachMob(RemoveDebuff, {debuff_prefab = inst.debuff_prefab})
		else
			for i, v in ipairs(AllPlayers) do
				RemoveDebuff(v, {debuff_prefab = inst.debuff_prefab})
			end
		end
    end
end

local function PlayPulse(inst)
    if not inst.components.health:IsDead() then
        inst.AnimState:PlayAnimation("active")
        inst.AnimState:PushAnimation("idle", true)
        inst.pulse:push() -- Tell clients to pulse
        inst:OnPulse(inst)
    end
end
--------------------------------------------------------------------------
-- Attack Functions
--------------------------------------------------------------------------
local function OnHit(inst)
    if not inst.components.health:IsDead() then
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle", true)
        inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_wood_armour_sharp")
    end
end
--------------------------------------------------------------------------
-- Death Functions
--------------------------------------------------------------------------
local function OnDeath(inst)
    RemoveTask(inst.DoAura)
    RemoveTask(inst.DoPulse)
	CheckforBuffs(inst)
    inst.AnimState:PlayAnimation("break")
	inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/banner_break")
	inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + 2 * FRAMES, function(inst) inst:Remove() end)
end
------------------------------------------------------------------------------
local function MakeBattleStandard(name, build_swap, debuff_prefab, fx_anim, aura, friendly)
    local assets = {
        Asset("ANIM", "anim/lavaarena_battlestandard.zip"),
		Asset("ANIM", "anim/lavaarena_battlestandard_alt1.zip"),
    }
    --------------------------------------------------------------------------
    if build_swap ~= nil then
        table.insert(assets, Asset("ANIM", "anim/"..build_swap..".zip"))
    end
    --------------------------------------------------------------------------
    local prefabs = {debuff_prefab}
    --------------------------------------------------------------------------
    -- Pristine Function
    --------------------------------------------------------------------------
    local function PristineFN(inst)
        if build_swap ~= nil then
            inst.AnimState:AddOverrideBuild(build_swap)
        end
        inst.AnimState:PushAnimation("idle", true)
        ------------------------------------------
        inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/banner")
        ------------------------------------------
        if not friendly then
            COMMON_FNS.AddTags(inst, "battlestandard")
        end
        ------------------------------------------
        inst.fxanim = fx_anim
        inst.pulse = net_event(inst.GUID, "lavaarena_battlestandard_damager.pulse")
        ------------------------------------------
        --Dedicated server does not need local fx
        if not TheNet:IsDedicated() then
            inst.fx = CreatePulse(inst)
        end
    end
    --------------------------------------------------------------------------
    local structure_values = {
        anim      = "place",
        anim_loop = false,
        friendly  = friendly,
        OnHit     = OnHit,
        name_override = "lavaarena_battlestandard",
        pristine_fn = PristineFN,
    }
    --------------------------------------------------------------------------
    local function fn()
        local inst = COMMON_FNS.CommonStructureFN("lavaarena_battlestandard", name == "battlestandard_shield_friendly" and "lavaarena_battlestandard_alt1" or "lavaarena_battlestandard", structure_values, tuning_values)
		------------------------------------------
        if not TheWorld.ismastersim then
			inst:ListenForEvent("lavaarena_battlestandard_damager.pulse", OnPulse)
            return inst
        end
        ------------------------------------------
		ShakeAllCameras(CAMERASHAKE.FULL, .4, .03, .4, inst, 30)
        ------------------------------------------
        inst.debuff_prefab = debuff_prefab
        inst.OnPulse = OnPulse
		inst.DoAura  = inst:DoPeriodicTask(tuning_values.PULSE_TICK, DoAura)
		inst.DoPulse = inst:DoPeriodicTask(tuning_values.PULSE_TIME, PlayPulse)
        ------------------------------------------
        inst:ListenForEvent("death", OnDeath)
        ------------------------------------------
		inst:AddComponent("debuffable") --Leo: this is only here so the battlestandard can have its own buff, it doesn't do anything for it but its needed for visuals.
        ------------------------------------------
        --COMMON_FNS.LoadMutators(name, inst) -- TODO Remove?
        ------------------------------------------
        return inst
    end

    return ForgePrefab(name, fn, assets, prefabs, nil, "BUFFS", nil, "images/reforged.xml", name .. "_icon.tex")
end
------------------------------------------------------------------------------
local attach_fns = {
    defense = function(inst, target)
        if target.components.combat and not target.components.combat:HasDamageBuff("defense_banner", true) then
            target.components.combat:AddDamageBuff("defense_banner", math.max(tuning_values.DEF_BUFF / math.max(inst.efficiency, 0.1), 0.01), true)
        end
    end,
    attack = function(inst, target)
        if target.components.combat and not target.components.combat:HasDamageBuff("attack_banner") then
            target.components.combat:AddDamageBuff("attack_banner", 1 + (tuning_values.ATK_BUFF * inst.efficiency))
        end
    end,
    regen = function(inst, target)
        if target.components.health then
            target.components.health:StartRegen(tuning_values.HEALTH_PER_TICK * inst.efficiency, tuning_values.HEALTH_TICK)
        end
    end,
    speed = function(inst, target)
        if target.components.locomotor then
            target.components.locomotor:SetExternalSpeedMultiplier(inst, "speed_banner", tuning_values.SPEED_BUFF * inst.efficiency)
        end
    end,
}

local function OnAttached(inst, target)
    inst.entity:SetParent(target.entity)
    -- Remove debuff when target dies
    inst:ListenForEvent("death", function()
        inst.components.debuff:Stop()
    end, target)
    -- Attach buff
	if target ~= nil and not target.components.health:IsDead() and not target:HasTag("nobuff") and inst.type and attach_fns[inst.type] then
		attach_fns[inst.type](inst, target)
	end
end

local detach_fns = {
    defense = function(inst, target)
        if target.components.combat and target.components.combat:HasDamageBuff("defense_banner", true) then
            target.components.combat:RemoveDamageBuff("defense_banner", true)
        end
    end,
    attack = function(inst, target)
        if target.components.combat and target.components.combat:HasDamageBuff("attack_banner") then
            target.components.combat:RemoveDamageBuff("attack_banner")
        end
    end,
    regen = function(inst, target)
        if target.components.health then
            target.components.health:StopRegen()
        end
    end,
    speed = function(inst, target)
        if target.components.locomotor then
            target.components.locomotor:RemoveExternalSpeedMultiplier(target, "speed_banner")
        end
    end,
}

local function OnDetached(inst, target)
	if target and not target.components.health:IsDead() and not target:HasTag("nobuff") and inst.type and detach_fns[inst.type] then
        detach_fns[inst.type](inst, target)
	end
	inst:Remove()
end
------------------------------------------------------------------------------
local function MakeBuff(name, type)
	local function fn()
		local inst = CreateEntity()
        inst:AddTag("battlestandard_buff")
        ------------------------------------------
		inst.entity:SetPristine()
		------------------------------------------
		if not TheWorld.ismastersim then
            inst:DoTaskInTime(0, inst.Remove)
			return inst
		end
        ------------------------------------------
        inst.entity:AddTransform()
        ------------------------------------------
		inst:AddComponent("debuff")
		inst.components.debuff:SetAttachedFn(OnAttached)
		inst.components.debuff:SetDetachedFn(OnDetached)
        ------------------------------------------
		inst.type = type or "defense"
        inst.efficiency = 1
        ------------------------------------------
        --COMMON_FNS.LoadMutators(name, inst) -- TODO remove?
        ------------------------------------------
		return inst
	end

	return Prefab(name, fn)
end
------------------------------------------------------------------------------
return MakeBattleStandard("battlestandard_damager", "lavaarena_battlestandard_attack_build", "damager_buff", "attack_fx3", "Attack"),
    MakeBattleStandard("battlestandard_shield", nil, "shield_buff", "defend_fx", "Defense"),
    MakeBattleStandard("battlestandard_heal", "lavaarena_battlestandard_heal_build", "healer_buff", "heal_fx", "Heal"),
	MakeBattleStandard("battlestandard_speed", "lavaarena_battlestandard_speed_build", "speed_buff", "attack_fx3", "Speed"),
	--Friendly Banners--
	MakeBattleStandard("battlestandard_damager_friendly", "lavaarena_battlestandard_attack_build_alt1", "damager_buff", "attack_fx3", "Attack", true),
    MakeBattleStandard("battlestandard_shield_friendly", nil, "shield_buff", "defend_fx", "Defense", true), --TODO Fix corrupted texture
    MakeBattleStandard("battlestandard_heal_friendly", "lavaarena_battlestandard_heal_build_alt1", "healer_buff", "heal_fx", "Heal", true),
	MakeBattleStandard("battlestandard_speed_friendly", "lavaarena_battlestandard_speed_build_alt1", "speed_buff", "attack_fx3", "Speed", true),
	MakeBuff("shield_buff", "defense"),
	MakeBuff("damager_buff", "attack"),
	MakeBuff("healer_buff", "regen"),
	MakeBuff("speed_buff", "speed")
