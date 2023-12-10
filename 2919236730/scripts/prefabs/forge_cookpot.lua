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
    Asset("ANIM", "anim/portable_cook_pot.zip"),
	Asset("ANIM", "anim/food_projectile.zip"),
}
local prefabs = {
    "collapse_small",
}
local tuning_values = TUNING.FORGE.COOKPOT
local sounds = {
	collapse  = "dontstarve/common/together/portable/cookpot/collapse",
	open      = "dontstarve/common/cookingpot_open",
	close     = "dontstarve/common/cookingpot_close",
	cook_loop = "dontstarve/common/cookingpot_rattle",
	finish    = "dontstarve/common/cookingpot_finish",
}
--------------------------------------------------------------------------
-- Ability Functions
--------------------------------------------------------------------------
local function OnRemove(inst)
	if inst.owner and inst.owner.sg:HasStateTag("cooking") then --in the event that cookpot gets removed by unknown means
		inst.owner.sg:GoToState("idle", "idle_wardrobe1_pst")
	end
	local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(inst:GetPosition():Get())
	inst:Remove()
end

local function Despawn(inst)
	local cookpot = inst:HasTag("forge_cookpot") and inst or inst.cookpot
    RemoveTask(cookpot.cook_task)
	if inst.cookpot then
		inst.cookpot = nil
	end
	cookpot.SoundEmitter:KillSound("snd")
	cookpot.AnimState:PlayAnimation("collapse")
	cookpot.SoundEmitter:PlaySound(cookpot.sounds.collapse)
	cookpot:ListenForEvent("animover", OnRemove)
end

local function GetCookTime(inst, owner)
	local buffable = owner.components.buffable
	return buffable and buffable:ApplyStatBuffs({"cook_duration"}, tuning_values.COOK_TIME) or tuning_values.COOK_TIME
end

local function Spit(inst, target)
	inst.AnimState:PlayAnimation("hit_full")
	inst.SoundEmitter:PlaySound(inst.sounds.finish)
	local pos = inst:GetPosition()
	local target_pos = target:GetPosition()
	local spit = SpawnPrefab("food_projectile")
	spit.Transform:SetPosition(pos.x, 0.5, pos.z)
	spit.thrower = inst
    spit.chef = inst.owner
    spit.heal_rate = inst.heal_rate
	spit.components.complexprojectile:Launch(target_pos, inst)
end

local function LaunchFood(inst)
	local pos = inst:GetPosition()
	local ents = TheSim:FindEntities(pos.x, 0, pos.z, tuning_values.RANGE, {"player"}, {"notarget", "playerghost", "INLIMBO"})
	if #ents > 0 then
        -- Create launch task for all valid ents
        local launch_count = 0
		for _,ent in ipairs(ents) do
			if ent and ent.components.health and not ent.components.health:IsDead() and not ent.cannoteat then
                launch_count = launch_count + 1
                inst:DoTaskInTime(tuning_values.SPIT_DELAY * launch_count, function(inst)
                    Spit(inst, ent)
                end)
			end
		end
        -- Remove the crockpot one spit delay after all food has been launched
        if launch_count > 0 then
            inst:DoTaskInTime(tuning_values.SPIT_DELAY * (launch_count + 1), function(inst)
                inst.AnimState:Hide("swap_cooked")
                Despawn(inst)
            end)
		else
			Despawn(inst)
        end
	else
		Despawn(inst)
	end
end

local function FinishCooking(inst)
	inst.cooked = true
	if inst.owner and not inst.owner.components.health:IsDead() then
		local owner = inst.owner
		owner.cookpot = nil
		owner.sg:GoToState("idle", "idle_wardrobe1_pst")
		if owner.components.talker and not owner:HasTag("mime") then
			owner.components.talker:Say(STRINGS.REFORGED.CHARACTER.COOKING[string.upper(owner.prefab)] or STRINGS.REFORGED.CHARACTER.COOKING.OTHER)
		end
	end
	inst.SoundEmitter:KillSound("snd")
	inst.AnimState:PlayAnimation("cooking_pst")
    inst.AnimState:PushAnimation("idle_full", false)
	inst:DoTaskInTime(tuning_values.LAUNCH_DELAY, LaunchFood)
	inst.SoundEmitter:PlaySound(inst.sounds.finish)
	inst.AnimState:OverrideSymbol("swap_cooked", "food_projectile", "swap_food")
end

local function StartCooking(inst, owner)
	owner.cookpot = inst
    inst.heal_rate = tuning_values.REGEN_TICK_VALUE
    if owner and owner.components.buffable then
        inst.heal_rate = owner.components.buffable:ApplyStatBuffs({"heal_dealt", "food_regen"}, inst.heal_rate)
    end

	if not (owner and owner.components.buffable and owner.components.buffable:ApplyStatBuffs({"chef_mastery"}, 0) > 0)  and not (owner and owner.components.health:IsDead()) then
		owner.sg:GoToState("forge_cooking", inst)
	end
	inst.AnimState:PlayAnimation("cooking_pre_loop", false)
	inst.AnimState:PushAnimation("cooking_loop", true)

	inst.cook_task = inst:DoTaskInTime(GetCookTime(inst, owner), FinishCooking)
	--Sounds--
	inst:DoTaskInTime(0, function(inst)
        inst.SoundEmitter:PlaySound(inst.sounds.open)
    end)
	inst:DoTaskInTime(10*FRAMES, function(inst)
		inst.SoundEmitter:PlaySound(inst.sounds.close)
        if inst.SoundEmitter:PlayingSound("snd") then
            inst.SoundEmitter:KillSound("snd")
        end
        inst.SoundEmitter:PlaySound(inst.sounds.cook_loop, "snd")
	end)
end

local function OnSpawn(inst)
	if inst.owner then
		StartCooking(inst, inst.owner)
	else
		Despawn(inst)
	end
end
--------------------------------------------------------------------------
-- Weapon Functions
--------------------------------------------------------------------------
local function SetOwner(inst, owner)
    inst.owner = owner
    inst.components.scaler:SetSource(owner)
end
--------------------------------------------------------------------------
local function fn()
    local inst = COMMON_FNS.FXEntityInit("portable_cook_pot", "portable_cook_pot", "place", {noanimover = true, pristine_fn = function(inst)
        inst.entity:AddSoundEmitter()
        ------------------------------------------
    	inst:AddTag("forge_cookpot")
    end})
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
    inst.sounds = sounds
	inst.Despawn = Despawn
	inst.SetOwner = SetOwner
    ------------------------------------------
	inst:AddComponent("inspectable")
    ------------------------------------------
	inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength(), OnSpawn)
    ------------------------------------------
    return inst
end
--------------------------------------------------------------------------
-- Projectile Functions
--------------------------------------------------------------------------
local function projectile_onland(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x,0,z, tuning_values.FOOD_HIT_RANGE, {"player"}, {"corpse"})
	local targets = {}
	if #ents > 0 then
		for _,ent in pairs(ents) do
			if ent.components.combat and ent.components.health and not ent.components.health:IsDead() and
				not ent:HasTag("cannoteat") and ent.components.eater and ent.sg.currentstate.name ~= "eat" and
				not ent.sg:HasStateTag("parrying") and not ent.sg:HasStateTag("busy") and not ent.sg:HasStateTag("attack") then
				ent.sg:GoToState(ent.eatstateoverride or (ent.sg:HasState("eat") and "eat" or "idle")) --eatstateoverride is incase someone uses a custom sg or if they just want to do a new state in general.
				ent.components.eater:Eat(inst)
				break
            else
				inst.AnimState:PlayAnimation("land")
				inst:ListenForEvent("animover", inst.Remove)
			end
		end
	else
		inst.AnimState:PlayAnimation("land")
		inst:ListenForEvent("animover", inst.Remove)
	end
end

local function OnEaten(inst, eater)
    local debuffable = eater.components.debuffable
    if debuffable then
        debuffable:AddDebuff("spatula_food_buff", "spatula_food_buff")
        local spatula_food_buff = debuffable:GetDebuff("spatula_food_buff")
        if spatula_food_buff then
        	spatula_food_buff.chef = inst.chef
        	spatula_food_buff.heal_rate = inst.heal_rate
        end
    end
end
--------------------------------------------------------------------------
-- Physics Functions
--------------------------------------------------------------------------
local physics = {
    mass   = 1,
    radius = 0.2,
}
local function PhysicsInit(inst)
	MakeInventoryPhysics(inst)
	inst.Transform:SetTwoFaced()
end
--------------------------------------------------------------------------
-- Pristine Functions
--------------------------------------------------------------------------
local function PristineFN(inst)
    inst.entity:AddSoundEmitter()
    ------------------------------------------
    COMMON_FNS.AddTags(inst, "spat", "food")
end
------------------------------------------------------------------------------
local projectile_values = {
    physics         = physics,
    physics_init_fn = PhysicsInit,
    complex         = true,
    no_tail         = true,
    speed           = tuning_values.HORIZONTAL_SPEED,
    gravity         = tuning_values.GRAVITY,
    launch_offset   = Vector3(unpack(tuning_values.VECTOR)),
    OnHit           = projectile_onland,
    pristine_fn     = PristineFN,
}
------------------------------------------------------------------------------
local function projectile_fn(inst)
	local inst = COMMON_FNS.EQUIPMENT.CommonProjectileFN("food_projectile", nil, nil, projectile_values)
    ------------------------------------------
	if not TheWorld.ismastersim then
		return inst
    end
	------------------------------------------
	inst:Show()
    inst.persists = false
	------------------------------------------
	inst:AddComponent("edible")
    inst.components.edible:SetOnEatenFn(OnEaten)
	------------------------------------------
	inst:DoTaskInTime(20, inst.Remove) -- in case projectile gets stuck, remove self.
	------------------------------------------
	return inst
end
--------------------------------------------------------------------------
-- Buff Functions
--------------------------------------------------------------------------
local function Regen(inst, eater, chef)
    if eater.components.health and not eater.components.health:IsDead() then
        local heal_value = inst.heal_rate
        if eater.components.buffable then
            heal_value = eater.components.buffable:ApplyStatBuffs({"heal_recieved"}, heal_value)
        end
        eater.components.health:DoDelta(heal_value, true, "spatula_food", nil, chef)
    end
end

local function AttachTimers(inst, target)
    if target.components.health then
        target.spatula_food_regen_task = target:DoPeriodicTask(tuning_values.REGEN_TICK_RATE, function(inst_tar)
            Regen(inst, inst_tar, inst.chef)
        end)
    end
    local chef_buffable = inst.chef and inst.chef.components.buffable
    local buff_duration = chef_buffable and chef_buffable:ApplyStatBuffs({"food_duration"}, tuning_values.BUFF_DURATION) or tuning_values.BUFF_DURATION
    target.spatula_food_buff_timer = target:DoTaskInTime(buff_duration, function(target_inst)
        inst.components.debuff:Stop()
        target_inst.spatula_food_buff_timer = nil
    end)
end

local function OnAttached(inst, target)
    inst:DoTaskInTime(0, function() -- Delay one frame so that buff values can be set
        inst.entity:SetParent(target.entity)
        -- Remove debuff when target dies
        inst:ListenForEvent("death", function()
            inst.components.debuff:Stop()
        end, target)
        -- Attach buff
        if target.components.combat then
            local chef_buffable = inst.chef and inst.chef.components.buffable
            local damage_buff = chef_buffable and chef_buffable:ApplyStatBuffs({"food_damage"}, tuning_values.DAMAGE_BUFF) or tuning_values.DAMAGE_BUFF
            local defense_buff = chef_buffable and chef_buffable:ApplyStatBuffs({"food_defense"}, tuning_values.DEFENSE_BUFF) or tuning_values.DEFENSE_BUFF
            target.components.combat:AddDamageBuff("spatula_food_buff", damage_buff)
            target.components.combat:AddDamageBuff("spatula_food_buff", defense_buff, true)
        end
        AttachTimers(inst, target)
    end)
end

local function OnExtended(inst, target)
    inst:DoTaskInTime(0, function() -- Delay one frame so that buff values can be set
        RemoveTask(target.spatula_food_buff_timer)
        RemoveTask(target.spatula_food_regen_task)
        AttachTimers(inst, target)
    end)
end

local function OnDetached(inst, target)
    if target.components.combat then
        target.components.combat:RemoveDamageBuff("spatula_food_buff")
        target.components.combat:RemoveDamageBuff("spatula_food_buff", true)
    end
    RemoveTask(target.spatula_food_buff_timer)
    RemoveTask(target.spatula_food_regen_task)
	inst:Remove()
end
------------------------------------------------------------------------------
local function food_buff_fn()
	local inst = CreateEntity()
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
    inst.components.debuff:SetExtendedFn(OnExtended)
	inst.components.debuff:SetDetachedFn(OnDetached)
    ------------------------------------------
	return inst
end
------------------------------------------------------------------------------
return Prefab("forge_cookpot", fn, assets, prefabs),
	Prefab("food_projectile", projectile_fn, assets, prefabs),
	Prefab("spatula_food_buff", food_buff_fn)
