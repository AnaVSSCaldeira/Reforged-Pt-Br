local assets = {
    Asset("ANIM", "anim/waterballoon.zip"),
    Asset("ANIM", "anim/swap_waterballoon.zip"),
}
local prefabs = {
    "waterballoon_splash",
    "reticule",
}
local tuning_values = TUNING.FORGE.BALLOON_REFORGED
--------------------------------------------------------------------------
-- Ability Functions
--------------------------------------------------------------------------
local function MakeBalloon(inst, caster, pos)
    local balloon = SpawnPrefab("balloon")
    balloon.Transform:SetPosition(pos:Get())
    --balloon.components.poppable.onpopfn = onpopfn
    --balloon.components.combat:SetDefaultDamage(TUNING.BALLOON_DAMAGE)
end
--------------------------------------------------------------------------
-- Pristine Functions
--------------------------------------------------------------------------
local function PristineFN(inst)
    COMMON_FNS.AddTags(inst, "plant_seed")
end
--------------------------------------------------------------------------
local weapon_values = {
    name_override = "waterballoon",
    swap_strings  = {"swap_object", "swap_waterballoon"},
    AOESpell   = MakeBalloon,
    projectile = "waterballoon_projectile_reforged",
    pristine_fn = PristineFN,
}
--------------------------------------------------------------------------
local function fn()
    local inst = COMMON_FNS.EQUIPMENT.CommonWeaponFN("waterballoon", nil, weapon_values, tuning_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    return inst
end
--------------------------------------------------------------------------
-- Projectile Functions
--------------------------------------------------------------------------
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

local function OnHitWaterBalloon(inst, attacker, target, weapon, damage)
    SpawnPrefab("waterballoon_splash").Transform:SetPosition(inst.Transform:GetWorldPosition()) -- TODO needs to scale?
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
-- Pristine Functions
--------------------------------------------------------------------------
local function PristineFN(inst)
    inst.entity:AddSoundEmitter()
    ------------------------------------------
    inst.Transform:SetTwoFaced()
end
--------------------------------------------------------------------------
local projectile_values = {
    physics         = physics,
    physics_init_fn = PhysicsInit,
    pristine_fn     = PristineFN,
    complex         = true,
    no_tail         = true,
    speed           = tuning_values.HORIZONTAL_SPEED,
    gravity         = tuning_values.GRAVITY,
    launch_offset   = Vector3(unpack(tuning_values.VECTOR)),
    OnLaunch        = onthrown,
    OnHit           = OnHitWaterBalloon,
    --CreateProjectileAnim = CreateProjectileAnim,
}
--------------------------------------------------------------------------
local function waterballoon_projectilefn()
    local inst = COMMON_FNS.EQUIPMENT.CommonComplexProjectileFN("waterballoon", nil, "spin_loop", projectile_values)
    ------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    return inst
end
--------------------------------------------------------------------------
return ForgePrefab("balloon_reforged", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/inventoryimages.xml", "hammer_mjolnir.tex", "swap_hammer_mjolnir", "common_hand"),
    Prefab("waterballoon_projectile_reforged", waterballoon_projectilefn, assets, prefabs)
