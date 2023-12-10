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
    Asset("ANIM", "anim/player_ghost_withhat.zip"),
    Asset("ANIM", "anim/ghost_abigail_build.zip"),
    Asset("SOUND", "sound/ghost.fsb"),
}
local prefabs = {
    "forge_abigail_flower",
}
local tuning_values = TUNING.FORGE.FORGE_ABIGAIL
local sound_path = "dontstarve/ghost/"
--------------------------------------------------------------------------
-- Attack Functions
--------------------------------------------------------------------------
local function Retarget(inst) -- TODO this is still default
    return FindEntity(inst, 20, function(mob)
		return inst._playerlink and inst.components.combat:CanTarget(mob) and (mob.components.combat.target == inst._playerlink or inst._playerlink.components.combat.target == mob)
	end, {"_combat", "_health"}, {"INLIMBO", "noauradamage", "_isinheals", "fossilized", "player", "companion"})
end

local function OnAttacked(inst, data)
	if data.attacker and not ((data.attacker:HasTag("player") or data.attacker:HasTag("companion")) or data.attacker:HasTag("_isinheals")) then -- TODO being attacked in heals should not affect target at all?
		if not data.attacker then -- TODO this is impossible
			inst.components.combat:SetTarget(nil)
		elseif data.attacker == inst._playerlink then -- TODO if wendy attacks abigail somehow, instakills her?
			inst.components.health:SetVal(0)
		elseif not data.attacker:HasTag("noauradamage") then
			inst.components.combat:SetTarget(data.attacker)
		end
	end
end

local function auratest(inst, target)
    -- Don't attack the the leader?
    if target == inst._playerlink then
        return false
    -- Attack the current target
    elseif inst.components.combat.target == target then
        return true
    end

    local leader = inst.components.follower.leader
    -- Attack the target if it is attacking you or your leader
    if target.components.combat.target and (target.components.combat.target == inst or target.components.combat.target == leader) then
        return true
    -- Don't attack the leader or any of the leaders followers
    elseif leader and (leader == target or (target.components.follower and target.components.follower.leader == leader)) then
        return false
    end

    -- Don't attack players, sleeping or targets in a heal, or fossilized targets. Only attack "monster" targets.
    return not COMMON_FNS.IsAlly(inst, target) and target:HasTag("monster") and not (target.sg and ((target.sg:HasStateTag("sleeping") or target:HasTag("_isinheals") and GetTime() - target.components.combat.last_player_attack > 1) or target.sg:HasStateTag("fossilized"))) -- TODO make keeptarget function that returns this? then set combat keeptarget to it and have it called here or just use auratest for keeptarget function in combat? tuning for the 1
end
--------------------------------------------------------------------------
-- Death Functions
--------------------------------------------------------------------------
local function OnDeath(inst)
	if inst._playerlink then
		inst._playerlink.components.petleash.petprefab = "forge_abigail_flower"
		local flower = inst._playerlink.components.petleash:SpawnPetAt(inst.Transform:GetWorldPosition())
		if flower then
            flower:Initialize(inst._playerlink, inst.current_level, inst)
        end
	end
    inst.components.aura:Enable(false)
end
--------------------------------------------------------------------------
-- Pet Functions
--------------------------------------------------------------------------
local function unlink(inst)
    inst._playerlink.abigail = nil
end

local function linktoplayer(inst, player)
    inst.persists = false
    inst._playerlink = player
    player.abigail = inst
    player.components.leader:AddFollower(inst)
    if player.components.pethealthbars then
        player.components.pethealthbars:AddPet(inst, "pet_abigail", tuning_values.HEALTH, true)
    end
    player:ListenForEvent("onremove", unlink, inst)
end

-- TODO can this function be commonized? seems like most of it is the same, scaling seems to be the only real issue if baby spiders do not scale. Also combat, but we can check to see if they have the combat component and change accordingly and whatnot.
-- Spamming equip/unequip breaks this, abigail either unlinks or gets over buffed, probably because the state is being interrupted
local SCALE = 1
local function UpdatePetLevel(inst, level, force_level)
	-- Only level up if the current level will change
	if level and level ~= 0 or force_level and level ~= inst.current_level then
		inst.current_level = force_level and level or inst.current_level + level
		-- Update Health
        inst.components.health:AddHealthBuff("pet_level", inst.current_level, "mult")
		CheckFunction("SetMaxHealth", {inst, inst.components.health.maxhealth}, inst.components.follower, "leader", "components", "pethealthbars")
		inst.components.health:StartRegen(inst.current_level*2, 1) -- TODO was a 2, level 1 is 1...so does this match level?
		-- Update Damage
        inst.components.combat:AddDamageBuff("pet_level", {buff = inst.current_level}, nil, true) -- TODO double check this
		-- Update Size
		local s = 1 + ((inst.current_level - 1)*(SCALE/5)) -- TODO need better equation, check if scaling values are correct, 1 and 1.2? it might be a 30% increase for all pets, but I can't tell if baby spiders change size or not
        inst.components.buffable:AddBuff("pet_level", {{name = "scaler", type = "mult", val = s}})
        inst.components.scaler:ApplyScale()
	end
end

local function ForgeOnSpawn(inst, leader)
    inst.AnimState:PlayAnimation("appear")
    ------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    inst:DoTaskInTime(0, function()
		inst:LinkToPlayer(leader)
	end)
end

local function ForgeOnDespawn(inst ,leader)
    inst.sg:GoToState("dissipate")
end

local function getstatus(inst)
    return "LEVEL"..inst.current_level or 1
end
--------------------------------------------------------------------------
-- Physics Functions
--------------------------------------------------------------------------
local physics = {
    scale  = 1,
    mass   = 1,
    radius = 0.5,
    --shadow = {1.75,0.75},
}
local function PhysicsInit(inst) -- TODO abigail does not add dynamicshadow but the commonpetfn does, fix this
	MakeGhostPhysics(inst, physics.mass, physics.radius)
	-- Light Effects
    inst.entity:AddLight()
	inst.AnimState:SetBloomEffectHandle("shaders/anim_bloom_ghost.ksh")
    inst.AnimState:SetLightOverride(TUNING.GHOST_LIGHT_OVERRIDE)
    --inst.AnimState:SetMultColour(1, 1, 1, .6)
    inst.Light:SetIntensity(.6)
    inst.Light:SetRadius(.5)
    inst.Light:SetFalloff(.6)
    inst.Light:Enable(true)
    inst.Light:SetColour(180 / 255, 195 / 255, 225 / 255)
end
--------------------------------------------------------------------------
-- Pristine Function
--------------------------------------------------------------------------
local function PristineFN(inst)
    COMMON_FNS.AddTags(inst, "character", "scarytoprey", "girl", "ghost", "noauradamage", "notraptrigger", "abigail", "NOBLOCK")
    ------------------------------------------
    --It's a loop that's always on, so we can start this in our pristine state
    if inst.SoundEmitter:PlayingSound("howl") then
        inst.SoundEmitter:KillSound("howl")
    end
    inst.SoundEmitter:PlaySound("dontstarve/ghost/ghost_girl_howl_LP", "howl")
    ------------------------------------------
    inst.ForgeOnSpawn = ForgeOnSpawn
    inst.ForgeOnDespawn = ForgeOnDespawn
end
--------------------------------------------------------------------------
local pet_values = {
    name_override   = "abigail",
    physics         = physics,
	physics_init_fn = PhysicsInit,
    pristine_fn     = PristineFN,
	stategraph      = "SGabby_forge",
	brain           = require("brains/abigailbrain_reforged"),
	sounds = {
		howl    = sound_path .. "ghost_girl_howl",
		howl_lp = sound_path .. "ghost_girl_howl_LP",
		attack  = sound_path .. "ghost_girl_attack_LP",
	},
	tags = {}, -- TODO
}
--------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.CommonPetFN("ghost", "ghost_abigail_build", pet_values, tuning_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	inst.current_level = 1
	inst.UpdatePetLevel = UpdatePetLevel
	------------------------------------------
	inst.components.inspectable.getstatus = getstatus --So inspection strings work after the abby update.
	------------------------------------------
	inst.components.health:StartRegen(1, 1)
	inst.components.health.nofadeout = true
	------------------------------------------
    inst:AddComponent("combat")
    inst.components.combat.defaultdamage = tuning_values.DAMAGE
    inst.components.combat:SetRetargetFunction(3, Retarget) -- TODO add keeptarget, kleis base game abigail sets keeptarget to auratest, should we?
	------------------------------------------
	inst:AddComponent("aura")
    inst.components.aura.radius = 3
    inst.components.aura.tickperiod = 1
    inst.components.aura.ignoreallies = true
    inst.components.aura.auratestfn = auratest
	------------------------------------------
	inst.acidimmune = true -- TODO is this needed? she is immune to poison, does this do that?
	------------------------------------------
	inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("death", OnDeath)
	------------------------------------------
	inst.LinkToPlayer = linktoplayer
	------------------------------------------
    return inst
end

return ForgePrefab("forge_abigail", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/reforged.xml", "pet_abby.tex")
