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
	retargeting currently still applies. A boarilla lost aggro because he did not get a hit in due to knockback (I think) and changed his target. Possibly need to have a bernie check in the targeting and force them to stay on bernie if dancing unless someone pulls aggro from him.
	if bernie is dead what happens when equipping/unequipping the pet armor? No checks for death in the orig file...hmmmm
--]]
local assets = {
    Asset("ANIM", "anim/bernie.zip"),
    Asset("ANIM", "anim/bernie_build.zip"),
}
local prefabs = {
    "small_puff",
}
local tuning_values = TUNING.FORGE.FORGE_BERNIE
local sound_path = "dontstarve/creatures/together/bernie/"
--------------------------------------------------------------------------
-- Pet Functions
--------------------------------------------------------------------------TODO should these be server side only? The fx in here should probably be in the stategraph???
local function ForgeOnSpawn(inst, leader) -- TODO spawn stategraph???
    local fx = _G.SpawnPrefab("collapse_small") --its either this or smallpuff
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	------------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    if leader.components.pethealthbars then
        leader.components.pethealthbars:AddPet(inst, "pet_bernie", tuning_values.HEALTH)
    end
    ------------------------------------------
    inst.Dance = function(leader, data)
        local target = data.attacker
        local pos = inst:GetPosition()
        if pos and target and target:IsValid() then
            local distance = target:GetDistanceSqToPoint(pos)
            if not inst.components.health:IsDead() and not inst.sg:HasStateTag("deactivated") and target.components.combat and distance <= tuning_values.TAUNT_RADIUS*tuning_values.TAUNT_RADIUS then
                inst.taunt_start_time = GetTime()
                if not inst.sg:HasStateTag("taunt") then
                    inst.sg:GoToState("taunt")
                end
                target.components.combat:SetTarget(inst)
            end
        end
    end
    leader:ListenForEvent("attacked", inst.Dance)
end

local function ForgeOnDespawn(inst, leader)
    ------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    leader:RemoveEventCallback("attacked", inst.Dance)
end

local function CanBeRevivedBy(inst, reviver)
    return reviver:HasTag("bernie_reviver")
end

local SCALE = TUNING.LAVAARENA_BERNIE_SCALE-- 1.2
local function UpdatePetLevel(inst, level, force_level)
	-- Only level up if the current level will change
	if level and level ~= 0 or force_level and force_level ~= inst.current_level then
		inst.current_level = force_level and level or inst.current_level + level
		-- Update Health
        inst.components.health:AddHealthBuff("pet_level", inst.current_level, "mult")
		CheckFunction("SetMaxHealth", {inst, inst.components.health.maxhealth}, inst.components.follower, "leader", "components", "pethealthbars")
		-- Update Size
		local scaler = 1 + (inst.current_level - 1)/3
        inst.components.buffable:AddBuff("pet_level", {{name = "scaler", type = "mult", val = scaler}})
        inst.components.scaler:ApplyScale()
		-- Update Revive Speed
		inst.components.revivablecorpse:SetReviveSpeedMult(tuning_values.REVIVE_SPEED_MULT/(inst.current_level*2 - 1)) -- TODO should this be changing the revivers speed mult like wilson and not bernie itself? For instance if a willow that is not wearing this armor goes and revives a bernie whose willow is wearing this will revive him faster, would that happen?
	end
end
--------------------------------------------------------------------------
-- Physics Functions
--------------------------------------------------------------------------
local physics = {
    scale  = TUNING.LAVAARENA_BERNIE_SCALE,
    mass   = 50,
    radius = 0.35,
    shadow = {1.1,0.55},
}
local function PhysicsInit(inst)
	inst:SetPhysicsRadiusOverride(physics.radius)
    MakeCharacterPhysics(inst, physics.mass, physics.radius)
    inst.DynamicShadow:SetSize(unpack(physics.shadow))
    local scale = physics.scale
    inst.Transform:SetScale(scale,scale,scale)
    inst.Transform:SetFourFaced()
end
--------------------------------------------------------------------------
-- Pristine Function
--------------------------------------------------------------------------
local function PristineFN(inst)
    COMMON_FNS.AddTags(inst, "character", "smallcreature")
    ------------------------------------------
    inst:AddComponent("revivablecorpse")
    inst.components.revivablecorpse:SetCanBeRevivedByFn(CanBeRevivedBy)
    inst.components.revivablecorpse:SetReviveHealthPercent(1) -- Revives to max health
    inst.components.revivablecorpse:SetReviveSpeedMult(tuning_values.REVIVE_SPEED_MULT)
    ------------------------------------------
    inst.ForgeOnSpawn = ForgeOnSpawn
    inst.ForgeOnDespawn = ForgeOnDespawn
end
--------------------------------------------------------------------------
local pet_values = {
    anim            = "idle_loop",
    name_override   = "lavaarena_bernie",
    physics         = physics,
	physics_init_fn = PhysicsInit,
    pristine_fn     = PristineFN,
	stategraph      = "SGbernie_forge",
	brain           = require("brains/bernie_forgebrain"),
	sounds = {
		idle     = sound_path .. "idle",
		walk     = sound_path .. "walk",
		sit_down = sound_path .. "sit_down",
		sit_up   = sound_path .. "sit_up",
		taunt    = sound_path .. "taunt",
		hit      = sound_path .. "hit",
		death    = sound_path .. "death",
	},
	tags = {}, -- TODO
}
--------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.CommonPetFN("bernie", "bernie_build", pet_values, tuning_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	inst.current_level = 1
	inst.UpdatePetLevel = UpdatePetLevel
	------------------------------------------
	inst.components.health.nofadeout = true
	------------------------------------------
    inst:AddComponent("combat")
	inst:AddComponent("timer")
	inst:AddComponent("bloomer")
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
return ForgePrefab("forge_bernie", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/reforged.xml", "pet_bernie.tex")
