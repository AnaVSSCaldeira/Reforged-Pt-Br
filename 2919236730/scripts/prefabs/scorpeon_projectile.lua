local assets = {}
local prefabs = {}
local tuning_values = TUNING.FORGE.SCORPEON
---------------------------------------------------------------------------------------
local function projectile_onhitother(inst, target)
	target.components.combat:GetAttacked(inst.thrower or inst, tuning_values.SPIT_DAMAGE, inst.thrower, "acid", nil, inst)
	--Leo: Added acidimmune to make it easy for modded characters to be immune to acid if they so well please.
	if target.components.health and target.components.debuffable and target.components.debuffable:IsEnabled() and not target.acidimmune and not target.components.debuffable:HasDebuff("healingcircle_regenbuff") and not (target.sg and target.sg:HasStateTag("noattack")) then -- TODO better way to handle immunities? tags? hmmm
		target.components.debuffable:AddDebuff("scorpeon_dot", "scorpeon_dot")
	end
end

local function projectile_onland(inst, attacker, target)
    local current_scale = inst.Transform:GetScale()
	local splash = SpawnAt("scorpeon_splashfx", inst:GetPosition())
    splash.Transform:SetScale(current_scale,current_scale,current_scale)
	inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/poison_drop")

	local x, y, z = inst.Transform:GetWorldPosition()
	local targets = COMMON_FNS.EQUIPMENT.GetAOETargets(attacker, inst:GetPosition(), tuning_values.SPIT_ATTACK_RANGE, nil, (attacker and attacker:IsValid()) and COMMON_FNS.GetAllyTags(attacker) or FORGE_TEAM_TAGS.LA_mob, nil, nil, nil, true)
	for k,target in pairs(targets) do
		if target.components.combat and target.components.health and not target.components.health:IsDead() and target ~= inst.thrower then
			projectile_onhitother(inst, target)
		end
	end
	inst:Remove()
end
--------------------------------------------------------------------------
-- Pristine Functions
--------------------------------------------------------------------------
local function PristineFN(inst)
	inst.entity:AddSoundEmitter()
end
---------------------------------------------------------------------------------------
local projectile_values = {
    complex       = true,
    speed         = 15,
    gravity       = -50,
    launch_offset = Point(0.2,2.5,0),
    OnHit         = projectile_onland,
    mult_colour   = {0.2,1,0,1},
    pristine_fn   = PristineFN,
}
local tail_values = {
    mult_colour  = {0.2,1,0,1},
    final_offset = -1,
}
---------------------------------------------------------------------------------------
local function projectile_fn(inst)
    local inst = COMMON_FNS.EQUIPMENT.CommonProjectileFN("gooball_fx", "gooball_fx", "idle_loop", projectile_values, tail_values)
	------------------------------------------
	if not TheWorld.ismastersim then
		return inst
    end
	------------------------------------------
    inst:AddTag("spat")
	------------------------------------------
	inst:Show()
    inst.persists = false
    inst._hastail:set(true)
	------------------------------------------
	inst:AddComponent("combat")
	inst.components.combat:SetDamageType(TUNING.FORGE.DAMAGETYPES.LIQUID)
	------------------------------------------
	inst:DoTaskInTime(20, inst.Remove) -- in case projectile gets stuck, remove self.
	------------------------------------------
	return inst
end
---------------------------------------------------------------------------------------
local function splashfx_fn()
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	inst.entity:AddNetwork()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    ------------------------------------------
    inst.AnimState:SetBank("lavaarena_hits_splash")
    inst.AnimState:SetBuild("lavaarena_hits_splash")
    inst.AnimState:PlayAnimation("aoe_hit")
    inst.AnimState:SetMultColour(.2, 1, 0, 1)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:SetScale(.54, .54)
    ------------------------------------------
	inst.entity:SetPristine()
	------------------------------------------
	if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	--inst:ListenForEvent("animover", inst.Remove)
    inst.persists = false
    inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + 2 * FRAMES, inst.Remove) -- TODO test; this is what klei has
	------------------------------------------
	return inst
end
---------------------------------------------------------------------------------------
return Prefab("scorpeon_projectile", projectile_fn),
Prefab("scorpeon_splashfx", splashfx_fn)
