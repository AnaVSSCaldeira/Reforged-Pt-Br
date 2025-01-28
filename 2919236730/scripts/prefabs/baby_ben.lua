local assets = {
    Asset("ANIM", "anim/ghost_kid.zip"),
    Asset("ANIM", "anim/ghost_build.zip"),
    Asset("SOUND", "sound/ghost.fsb"),
}
local prefabs = {}
local tuning_values = TUNING.FORGE.BABY_BEN
local sound_path = "dontstarve/characters/wendy/small_ghost/"
--------------------------------------------------------------------------
-- Ability Functions
--------------------------------------------------------------------------
local function CheckForValidShieldTarget(inst)
    local pos = inst:GetPosition()
    local targets = TheSim:FindEntities(pos.x, pos.y, pos.z, inst.shield_opts.max_range, nil, COMMON_FNS.GetEnemyTags(inst), COMMON_FNS.GetAllyTags(inst))
    for _,target in pairs(targets) do
        if target:IsValid() and target.components.health and not target.components.health:IsDead() and target.components.debuffable and not target.components.debuffable:HasDebuff("debuff_shield") and target.components.combat and (GetTime() - target.components.combat.lastwasattackedtime) <= inst.shield_opts.max_last_attacked_time then
            inst:PushEvent("give_shield", {target = target})
            break
        end
    end
end

local function GiveShield(inst, target)
    if target and target:IsValid() and not target.components.health:IsDead() and target.components.debuffable then
        local debuffable = target.components.debuffable
        RemoveTask(inst.shield_task)
        debuffable:AddDebuff("debuff_shield", "debuff_shield")
        local debuff_shield = debuffable:GetDebuff("debuff_shield")
		if debuff_shield then
			debuff_shield:SetDuration(inst.shield_opts.duration)
			debuff_shield:SetShieldMult(inst.shield_opts.shield_mult)
			inst.shield_cooldown = inst:DoTaskInTime(inst.shield_opts.cooldown, function(inst)
				inst.shield_cooldown = nil
				inst.shield_task = inst:DoPeriodicTask(0.5, CheckForValidShieldTarget)
			end)
		end
    end
end
--------------------------------------------------------------------------
-- Pet Functions
--------------------------------------------------------------------------
local BASE_DURATION    = 10
local BASE_SHIELD_MULT = 0.5
local SHIELD_RATE = 0.1
local SCALE = 1
local function UpdatePetLevel(inst, level, force_level)
    -- Only level up if the current level will change
    if level and level ~= 0 or force_level and level ~= inst.current_level then
        inst.current_level = force_level and level or inst.current_level + level
        -- Update Size
        local s = 1 + ((inst.current_level - 1)*(SCALE/5)) -- TODO need better equation, check if scaling values are correct, 1 and 1.2? it might be a 30% increase for all pets, but I can't tell if baby spiders change size or not
        inst.components.buffable:AddBuff("pet_level", {{name = "scaler", type = "mult", val = s}})
        inst.components.scaler:ApplyScale()
        inst:SetHairStyle(inst.current_level > 1 and 2 or 1)
        inst.shield_opts.duration = BASE_DURATION + 5  --BASE_DURATION * inst.current_level
        inst.shield_opts.shield_mult = math.max(1 - SHIELD_RATE * inst.current_level, 0)
        inst.shield_opts.cooldown = 7
    end
end

local function ForgeOnSpawn(inst, leader)
    --inst.AnimState:PlayAnimation("appear")
    ------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    if leader.components.pethealthbars then
        leader.components.pethealthbars:AddPet(inst)
    end
end

local function ForgeOnDespawn(inst ,leader)
    inst.sg:GoToState("dissipate")
end
--------------------------------------------------------------------------
-- Appearance Functions
--------------------------------------------------------------------------
local function SetHairStyle(inst, hairstyle)
    inst._hairstyle = hairstyle or math.random(0, 3)
    if inst._hairstyle ~= 0 then
        inst.AnimState:OverrideSymbol("smallghost_hair", "ghost_kid", "smallghost_hair_"..tostring(inst._hairstyle))
    end
end
--------------------------------------------------------------------------
-- Physics Functions
--------------------------------------------------------------------------
local physics = {
    scale  = 1,
    mass   = 0.5,
    radius = 0.5,
    shadow = {0.75,0.75},
}
local function PhysicsInit(inst)
    MakeTinyGhostPhysics(inst, physics.mass, physics.radius)
    -- Light Effects
    inst.entity:AddLight()
    inst.AnimState:SetBloomEffectHandle("shaders/anim_bloom_ghost.ksh")
    inst.AnimState:SetLightOverride(TUNING.GHOST_LIGHT_OVERRIDE)
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
    COMMON_FNS.AddTags(inst, "girl", "ghost", "noauradamage", "notraptrigger", "ghost_kid", "NOBLOCK", "flying")
    ------------------------------------------
    inst.ForgeOnSpawn = ForgeOnSpawn
    inst.ForgeOnDespawn = ForgeOnDespawn
end
--------------------------------------------------------------------------
local pet_values = {
    physics         = physics,
    physics_init_fn = PhysicsInit,
    pristine_fn     = PristineFN,
    stategraph      = "SGbabyben",
    brain           = require("brains/babybenbrain"),
    sounds = {
        howl = sound_path .. "howl",
        joy  = sound_path .. "joy",
    },
    tags = {}, -- TODO
}
--------------------------------------------------------------------------
local function fn()
    local inst = COMMON_FNS.CommonPetFN("ghost_kid", "ghost_kid", pet_values, tuning_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    inst.shield_opts = {duration = BASE_DURATION, shield_mult = BASE_SHIELD_MULT, max_last_attacked_time = 3, max_range = 12, cooldown = 12}
    inst.current_level  = 1
    inst.UpdatePetLevel = UpdatePetLevel
    inst.SetHairStyle   = SetHairStyle
    inst.GiveShield     = GiveShield
    inst.shield_task    = inst:DoPeriodicTask(0.5, CheckForValidShieldTarget)
    ------------------------------------------
    inst.components.health:SetInvincible(true)
    inst.components.health.nofadeout = true
    ------------------------------------------
    return inst
end

return ForgePrefab("baby_ben", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/reforged.xml", "pet_babyben.tex")
