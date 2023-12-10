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
    Asset("ANIM", "anim/balloons_empty.zip"),
	Asset("ANIM", "anim/balloon.zip"),
    Asset("ANIM", "anim/balloon_shapes.zip"),
}
local assets_projectile = {}
local prefabs = {}
local prefabs_projectile = {}
local PROJECTILE_DELAY = 4 * FRAMES -- TODO tuning? if tuning might be able to put in common prefab fn
local tuning_values = TUNING.FORGE.BALLOON
--------------------------------------------------------------------------
-- Ability Functions
--------------------------------------------------------------------------
local function BlowBalloon(inst, caster, pos) 
    local balloon = COMMON_FNS.Summon("forge_balloon", caster, pos)
	balloon.owner = caster
    inst.components.rechargeable:StartRecharge()
    inst.components.aoespell:OnSpellCast(caster)
end
--------------------------------------------------------------------------
-- Pristine Functions
--------------------------------------------------------------------------
local function PristineFN(inst)
    COMMON_FNS.AddTags(inst, "balloonpile")
end
--------------------------------------------------------------------------
local weapon_values = {
    name_override = "balloons_empty",
    swap_strings  = {"book_closed", "swap_slingshot"},
	--projectile    = "forge_slingshot_projectile",
	AOESpell      = BlowBalloon,
    pristine_fn   = PristineFN,
}
--------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.EQUIPMENT.CommonWeaponFN("balloons_empty", nil, weapon_values, tuning_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
--Balloons
local colours = {
    { 198/255,  43/255,  43/255, 1 },
    {  79/255, 153/255,  68/255, 1 },
    {  35/255, 105/255, 235/255, 1 },
    { 233/255, 208/255,  69/255, 1 },
    { 109/255,  50/255, 163/255, 1 },
    { 222/255, 126/255,  39/255, 1 },
}

local easing = require("easing")

local balloons = {}
local MAX_BALLOONS = tuning_values.MAX_BALLOONS
local num_balloons = 0
--------------------------------------------------------------------------
-- Attack Functions
--------------------------------------------------------------------------
local AREAATTACK_EXCLUDETAGS = { "player", "companion", "INLIMBO", "notarget", "noattack", "flight", "invisible", "playerghost" }
local function DoAreaAttack(inst)
    inst.components.combat:DoAreaAttack(inst, tuning_values.AOE_RADIUS, nil, nil, "electric", AREAATTACK_EXCLUDETAGS)
end

local function GrabAggro(inst)
    local pos = inst:GetPosition()
    local ents = TheSim:FindEntities(pos.x, 0, pos.z, tuning_values.AGGRO_RADIUS, { "locomotor", "LA_mob" }, AREAATTACK_EXCLUDETAGS)
    for i, v in ipairs(ents) do
        if v.components.health and not v.components.health:IsDead() and not (inst.components.combat.target and inst.components.combat.target:HasTag("balloon")) then
            v.components.combat:SetTarget(inst)
        end
    end
end
--------------------------------------------------------------------------
-- Death Functions
--------------------------------------------------------------------------
local function OnDeath(inst)
    RemovePhysicsColliders(inst)
    inst.AnimState:PlayAnimation("pop")
    inst.SoundEmitter:PlaySound(inst.sounds.death)
    inst.DynamicShadow:Enable(false)
    inst:AddTag("NOCLICK")
    inst.persists = false
    local attack_delay = .1 + math.random() * .2
    local remove_delay = math.max(attack_delay, inst.AnimState:GetCurrentAnimationLength()) + FRAMES
    inst:DoTaskInTime(attack_delay, DoAreaAttack)
    inst:DoTaskInTime(remove_delay, inst.Remove)
end

local function flyoff(inst)
    UnregisterBalloon(inst)
    inst:AddTag("notarget")
    inst.Physics:SetCollisionCallback(nil)
    inst.persists = false

    local xvel = math.random() * 2 - 1
    local yvel = 5
    local zvel = math.random() * 2 - 1

    inst:DoPeriodicTask(FRAMES, updatemotorvel, nil, xvel, yvel, zvel, GetTime())
end
--------------------------------------------------------------------------
-- Pet Functions
--------------------------------------------------------------------------
local function UnregisterBalloon(inst)
    if balloons[inst] == nil then
        return
    end
    balloons[inst] = nil
    num_balloons = num_balloons - 1
    inst.OnRemoveEntity = nil
end

local function RegisterBalloon(inst)
    if balloons[inst] then
        return
    end
    if num_balloons >= MAX_BALLOONS then
        local rand = math.random(num_balloons)
        for k, v in pairs(balloons) do
            if rand > 1 then
                rand = rand - 1
            else
                flyoff(k)
                break
            end
        end
    end
    balloons[inst] = true
    num_balloons = num_balloons + 1
    inst.OnRemoveEntity = UnregisterBalloon
end
--------------------------------------------------------------------------
-- Physics Functions
--------------------------------------------------------------------------
local function updatemotorvel(inst, xvel, yvel, zvel, t0)
    local x, y, z = inst.Transform:GetWorldPosition()
    if y >= 35 then
        inst:Remove()
        return
    end
    local time = GetTime() - t0
    if time >= 15 then
        inst:Remove()
        return
    elseif time < 1 then
        local scale = easing.inQuad(time, 1, -1, 1)
        inst.DynamicShadow:SetSize(scale, .5 * scale)
    else
        inst.DynamicShadow:Enable(false)
    end
    local hthrottle = easing.inQuad(math.clamp(time - 1, 0, 3), 0, 1, 3)
    yvel = easing.inQuad(math.min(time, 3), 1, yvel - 1, 3)
    inst.Physics:SetMotorVel(xvel * hthrottle, yvel, zvel * hthrottle)
end

local function oncollide(inst, other)
    if other:HasTag("LA_mob") then
        inst.components.health:Kill()
        return
    end
    if (inst:IsValid() and Vector3(inst.Physics:GetVelocity()):LengthSq() > .1) or
        (other ~= nil and other:IsValid() and other.Physics ~= nil and Vector3(other.Physics:GetVelocity()):LengthSq() > .1) then
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle", true)
        --inst.SoundEmitter:PlaySound("dontstarve/common/balloon_bounce")
    end
end

local function PhysicsInit(inst)
	MakeCharacterPhysics(inst, 10, .25)
    inst.Physics:SetFriction(.3)
    inst.Physics:SetDamping(0)
    inst.Physics:SetRestitution(1)
	inst.DynamicShadow:SetSize(1, .5)
end
--------------------------------------------------------------------------
local pet_values = {
    anim            = "idle",
    name_override   = "balloon",
	physics_init_fn = PhysicsInit,
	stategraph = nil,
	brain = nil,
	sounds = {
		death = "dontstarve/common/balloon_pop",
	},
	tags = {"balloon"}, -- TODO
}

--------------------------------------------------------------------------
local function mobfn()
	local inst = COMMON_FNS.CommonPetFN("balloon", "balloon", pet_values, tuning_values)
    ------------------------------------------
	if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	inst.AnimState:SetTime(math.random() * 2)
    ------------------------------------------
    inst.balloon_num = math.random(4)
    inst.AnimState:OverrideSymbol("swap_balloon", "balloon_shapes", "balloon_"..tostring(inst.balloon_num))
    inst.colour_idx = math.random(#colours)
    inst.AnimState:SetMultColour(unpack(colours[inst.colour_idx]))
	-----------------------------
	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(1)
	inst.components.health.nofadeout = true
	------------------------------------------
	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(tuning_values.ALT_DAMAGE)
	------------------------------------------
	inst.aggro_task = inst:DoPeriodicTask(tuning_values.TICK_RATE, GrabAggro)
	------------------------------------------
	inst:ListenForEvent("death", OnDeath)
	------------------------------------------
	RegisterBalloon(inst)	
end
--------------------------------------------------------------------------
return ForgePrefab("forge_balloonpile", fn, assets, prefabs, nil, "WEAPONS", false, "images/inventoryimages.xml", "balloonsempty.tex", nil, tuning_values, STRINGS.REFORGED.WEAPONS.SLINGSHOT.ABILITIES, "swap_slingshot", "common_hand"),
    Prefab("forge_balloon", mobfn, assets, prefabs)
