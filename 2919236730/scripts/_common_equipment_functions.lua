-----------------------------
-- Common Weapon Functions --
-----------------------------
--[[
This file contains functions that are commonly used by weapons.
--]]
-----------------------------

--------------------------
-- Equippable Functions --
--------------------------
local function CheckSwapStrings(swap_strings)
	if #swap_strings < 3 then -- use first string for the 3rd string
		table.insert(swap_strings, swap_strings[1])
	end
	return swap_strings
end

local function OnBlockedArmor(inst)
	local armor = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
	if armor then
		inst.SoundEmitter:PlaySound(armor.hitsound)
	end
end

local onequip_fns = {
	body = function(onequip_fn, ...)
		local swap_strings = CheckSwapStrings({...})
		return function(inst, owner)
			owner.AnimState:OverrideSymbol(unpack(swap_strings))
			inst:ListenForEvent("blocked", OnBlockedArmor, owner)

			-- Apply Max Health Increase
			if inst.max_hp then -- TODO should this be in all equip fns regardless of type?
				owner.components.health:AddHealthBuff(inst.prefab, inst.max_hp, "flat")
			end

			-- Apply Pet Levels
			if inst.pet_level_up then -- TODO should this be in all equip fns regardless of type?
				owner.current_pet_level = (owner.current_pet_level or 1) + inst.pet_level_up
				if owner.components.leader and owner.components.leader.followers then
					for pet,_ in pairs(owner.components.leader.followers) do
						pet:PushEvent("updatepetmastery", {level = inst.pet_level_up}) -- TODO could add levels of mastery instead where each pet has their own level scaling
					end
				end
			end

			if onequip_fn then
				onequip_fn(inst, owner)
			end
		end
	end,
	book = function(onequip_fn, ...)
		local swap_strings = CheckSwapStrings({...})
		return function(inst, owner)
			owner.AnimState:ClearOverrideSymbol("swap_object")
			owner.AnimState:OverrideSymbol(unpack(swap_strings))
			if onequip_fn then
				onequip_fn(inst, owner)
			end
		end
	end,
	fist = function(onequip_fn, ...)
		local swap_strings = CheckSwapStrings({...})
		return function(inst, owner)
			owner.AnimState:ClearOverrideSymbol("swap_object")
			owner.AnimState:OverrideSymbol(unpack(swap_strings))
			owner.AnimState:Hide("ARM_carry")
			owner.AnimState:Show("ARM_normal")
			if onequip_fn then
				onequip_fn(inst, owner)
			end
		end
	end,
	hand = function(onequip_fn, ...) -- Weapon
		local swap_strings = CheckSwapStrings({...})
	    return function (inst, owner)
			owner.AnimState:OverrideSymbol("swap_object", unpack(swap_strings))
			owner.AnimState:Show("ARM_carry")
			owner.AnimState:Hide("ARM_normal")
			if onequip_fn then
				onequip_fn(inst, owner)
			end
		end
	end,
	head = function(onequip_fn, ...) -- Helm
		local swap_strings = CheckSwapStrings({...})
		return function(inst, owner)
		    owner.AnimState:OverrideSymbol(unpack(swap_strings))
			owner.AnimState:Show("HAT")
			if inst.cover_head then
				owner.AnimState:Show("HAIR_HAT")
				owner.AnimState:Show("HEAD_HAT")
				owner.AnimState:Hide("HAIR_NOHAT")
				owner.AnimState:Hide("HAIR")
				owner.AnimState:Hide("HEAD")
			end
			if onequip_fn then
				onequip_fn(inst, owner)
			end
		end
	end,
}
local onunequip_fns = {
	body = function(onunequip_fn)
		return function(inst, owner)
			owner.AnimState:ClearOverrideSymbol("swap_body")
			inst:RemoveEventCallback("blocked", OnBlockedArmor, owner)

			-- Remove Max Health Increase
			if inst.max_hp then
				owner.components.health:RemoveHealthBuff(inst.prefab, "flat")
			end

			-- Remove Pet Levels
			if inst.pet_level_up then
				owner.current_pet_level = (owner.current_pet_level or 1) - inst.pet_level_up
				if owner.components.leader and owner.components.leader.followers then
					for pet,_ in pairs(owner.components.leader.followers) do
						pet:PushEvent("updatepetmastery", {level = -inst.pet_level_up})
					end
				end
			end

			if onunequip_fn then
				onunequip_fn(inst, owner)
			end
		end
	end,
	fist = function(onunequip_fn)
		return function(inst, owner)
			owner.AnimState:Hide("ARM_carry")
		    owner.AnimState:Show("ARM_normal")
			owner.AnimState:OverrideSymbol("hand", owner.prefab, "hand")
			owner.AnimState:ClearOverrideSymbol("hand")
			owner.components.skinner:SetClothing(owner.components.skinner.clothing.hand)
			owner.components.skinner:SetClothing(owner.components.skinner.clothing.body) --because some skins alter the hands
	    	if onunequip_fn then
				onunequip_fn(inst, owner)
	    	end
	    end
	end,
	hand = function(onunequip_fn)
		return function(inst, owner)
	    	owner.AnimState:Hide("ARM_carry")
	    	owner.AnimState:Show("ARM_normal")
	    	if onunequip_fn then
				onunequip_fn(inst, owner)
	    	end
	    end
	end,
	head = function(onunequip_fn) -- Helm
		return function(inst, owner)
		    owner.AnimState:ClearOverrideSymbol("swap_hat")
			owner.AnimState:Hide("HAT")
			if inst.cover_head then
				owner.AnimState:Hide("HAIR_HAT")
				owner.AnimState:Hide("HEAD_HAT")
				owner.AnimState:Show("HAIR_NOHAT")
				owner.AnimState:Show("HAIR")
				owner.AnimState:Show("HEAD")
			end
	    	if onunequip_fn then
				onunequip_fn(inst, owner)
	    	end
	    end
	end,
}

local function EquippableInit(inst, type, onequip_fn, onunequip_fn, symbol_1, symbol_2, symbol_3) -- TODO different name for symbol?
	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip_fns[type] and onequip_fns[type](onequip_fn, symbol_1, symbol_2 or symbol_1, symbol_3) or onequip_fn)
	local onunequip = inst.components.equippable:SetOnUnequip(onunequip_fns[type] and onunequip_fns[type](onunequip_fn) or onunequip_fn)
end
--------------------------

-------------------
-- AOE Reticules --
-------------------
local function AOEReticuleTargetFn(radius)
	return function ()
		local player = ThePlayer
		local ground = TheWorld.Map
		local pos = Vector3()
		--Cast range is 8, leave room for error
		--4 is the aoe range
		for r = radius, 0, -.25 do
			pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
			if ground:IsPassableAtPoint(pos:Get()) and not ground:IsGroundTargetBlocked(pos) then
				return pos
			end
		end
		return pos
	end
end

local function AOEReticuleInit(inst, radius, reticule_prefab, ping_prefab, valid_color, valid_colors, invalid_color)
	inst:AddComponent("aoetargeting")
	inst.components.aoetargeting.targetprefab = ping_prefab or "reticuleaoehostiletarget"
    inst.components.aoetargeting.reticule.reticuleprefab = reticule_prefab or "reticuleaoe"
    inst.components.aoetargeting.reticule.pingprefab = reticule_prefab and reticule_prefab.."ping" or "reticuleaoeping"
    inst.components.aoetargeting.reticule.targetfn = AOEReticuleTargetFn(radius) -- TODO or default of 7?
    inst.components.aoetargeting.reticule.validcolour = valid_color or { 1, .75, 0, 1 } -- TODO tuning?
    inst.components.aoetargeting.reticule.validcolours = valid_colors or {} -- TODO tuning?
    inst.components.aoetargeting.reticule.invalidcolour = invalid_color or { .5, 0, 0, 1 } -- TODO tuning?
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true
end
-------------------

---------------------------
-- Directional Reticules --
---------------------------
local function DirectionalReticuleTargetFn(length)
    return function ()
		return Vector3(ThePlayer.entity:LocalToWorldSpace(length * (ThePlayer.replica.scaler and ThePlayer.replica.scaler:GetScale() or 1), 0, 0))
	end
end

local function ReticuleMouseTargetFn(length)
    return function (inst, mousepos)
		if mousepos ~= nil then
			local x, y, z = inst.Transform:GetWorldPosition()
			local dx = mousepos.x - x
			local dz = mousepos.z - z
			local l = dx * dx + dz * dz
			if l <= 0 then
				return inst.components.reticule.targetpos
			end
			l = length / math.sqrt(l) * (ThePlayer.replica.scaler and ThePlayer.replica.scaler:GetScale() or 1)
			return Vector3(x + dx * l, 0, z + dz * l)
		end
	end
end

local function ReticuleUpdatePositionFn(inst, pos, reticule, ease, smoothing, dt)
    local x, y, z = inst.Transform:GetWorldPosition()
    reticule.Transform:SetPosition(x, 0, z)
    local rot = -math.atan2(pos.z - z, pos.x - x) / DEGREES
    if ease and dt ~= nil then
        local rot0 = reticule.Transform:GetRotation()
        local drot = rot - rot0
        rot = Lerp((drot > 180 and rot0 + 360) or (drot < -180 and rot0 - 360) or rot0, rot, dt * smoothing)
    end
    reticule.Transform:SetRotation(rot)
end

local function DirectionalReticuleInit(inst, length, reticule_prefab, ping_prefab, always_valid)
	inst:AddComponent("aoetargeting")
	inst.components.aoetargeting:SetAlwaysValid(always_valid == nil or always_valid)
    inst.components.aoetargeting.reticule.reticuleprefab = reticule_prefab or "reticulelong"
    inst.components.aoetargeting.reticule.pingprefab = ping_prefab or "reticulelongping"
	inst.components.aoetargeting.reticule.targetfn = DirectionalReticuleTargetFn(length) -- TODO or default of 6.5?
	inst.components.aoetargeting.reticule.mousetargetfn = ReticuleMouseTargetFn(length) -- TODO or default of 6.5?
	inst.components.aoetargeting.reticule.updatepositionfn = ReticuleUpdatePositionFn
	inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
    inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true
end
---------------------------

----------------------
-- Attack Functions --
----------------------
-- Applies the armor break debuff to the given target if valid
local function ApplyArmorBreak(attacker, target)
	--if target and target.components.armorbreak_debuff and not (attacker and attacker.components.passive_shock and attacker.components.passive_shock.shock) then
	if target and target.components.armorbreak_debuff and not CheckTable(attacker, "components", "passive_shock", "shock") then -- TODO check this, make sure it still works, delete commented if above if does.
		target.components.armorbreak_debuff:ApplyDebuff()
	end
end

-- Flips the target if the target can be flipped
local function FlipTarget(attacker, target)
	if target and target:HasTag("flippable") then
		target:PushEvent("flipped", {flipper = attacker})
	end
end

-- Hitbox Radius of all mobs:
--      Banners: 0
--       Pitpig: 0.5
-- Crocommander: 0.75
--    Snortoise: 0.80000001192093
--     Scorpeon: 0.80000001192093
--     Boarilla: 1.25
--     Rhinobro: 1
--     Boarrior: 1.5
--   Swineclops: 1.75
local HITBOX_RADIUS_BUFFER = 2
-- Returns all valid targets within a given radius. Hitboxes are included in the check.
-- target_table - all targets found will be added to this table
-- excluded_targets must be in this format: {target_inst1 = true, target_inst2 = true, ...}
-- add_to_excluded will add the new targets to the given excluded_targets
local function GetAOETargets(attacker, center_pos, radius, included, excluded, target_table, excluded_targets, add_to_excluded, ignore_targeting) -- TODO make sure all aoe use this to find targets, this includes cc like petrify and healing
	-- TODO should the align with our doaoe function as well????
	local targets = target_table or {}
	local x, y, z = center_pos:Get()
	local ents = TheSim:FindEntities(x, y, z, radius + HITBOX_RADIUS_BUFFER, included, excluded)
	for _,ent in ipairs(ents) do
		--print("Ent: " .. tostring(ent))
		-- Valid Target Check
		if (ignore_targeting or attacker and attacker.components.combat:CanTarget(ent)) and not (excluded_targets and excluded_targets[ent]) then
			--print("- Valid")
			-- Mob Hitbox Check
			local total_radius = ent:GetPhysicsRadius(0) + radius
			if distsq(ent:GetPosition(), center_pos) <= total_radius * total_radius then
				--print("- In Range")
				table.insert(targets, ent)
				if excluded_targets and add_to_excluded then
					excluded_targets[ent] = true
				end
			end
		end
	end
	return targets
end
----------------------

------------------------
-- ItemType Functions --
------------------------
local function ItemTypeInit(inst, type)
	inst:AddComponent("itemtype")
	inst.components.itemtype:SetType(type)
end
------------------------

-----------------------------
-- InventoryItem Functions --
-----------------------------
-- TODO need to find our where momentum is handled and when it's not moving trigger this
local function InventoryItemInit(inst, image_name)
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = image_name
	-- If an item goes out of bounds force it to return to the closest inbound location.
	inst:ListenForEvent("on_landed", function(inst)
		local pos = inst:GetPosition()
		if not TheWorld.Map:IsPassableAtPoint(pos:Get()) or TheWorld.Map:IsGroundTargetBlocked(pos) then-- or not TheWorld.Map:IsValidTileAtPoint(pos:Get()) then -- TheWorld.Map:IsGroundTargetBlocked(pos) or
			COMMON_FNS.ReturnToGround(inst)
		end
		-- TODO remove this when bandaid is no longer needed
		inst:DoTaskInTime(5, function()
			if not TheWorld.Map:IsPassableAtPoint(pos:Get()) or TheWorld.Map:IsGroundTargetBlocked(pos) then
				COMMON_FNS.ReturnToGround(inst)
			end
		end)
	end)
end
-----------------------------

------------------------
-- AOESpell Functions --
------------------------
local function AOESpellInit(inst, aoe_spell_fn, spell_types)
	inst:AddComponent("aoespell")
	inst.components.aoespell:SetAOESpell(aoe_spell_fn)
	if spell_types then
		inst.components.aoespell:SetSpellTypes(spell_types)
	end
end
------------------------

----------------------------
-- Rechargeable Functions --
----------------------------
local function RechargeableInit(inst, tuning_values)
	inst:AddComponent("rechargeable")
	local is_timer = tuning_values.COOLDOWN_TIMER == nil or tuning_values.COOLDOWN_TIMER
	inst.components.rechargeable:SetIsTimer(is_timer)
	if tuning_values.COOLDOWN then
		if is_timer then
			inst.components.rechargeable:SetRechargeTime(tuning_values.COOLDOWN)
		else
			inst.components.rechargeable:SetMaxRecharge(tuning_values.COOLDOWN)
		end
	end

end
-------------------------------

-----------------------------
-- AOEWeaponLeap Functions --
-----------------------------
local function AOEWeaponLeapInit(inst, stimuli, on_leap_fn)
	inst:AddComponent("aoeweapon_leap")
	--inst.components.aoeweapon_leap:SetDamage(tuning_values.ALT_DAMAGE)
	--inst.components.aoeweapon_leap:SetRadius(tuning_values.RADIUS)
	inst.components.aoeweapon_leap:SetStimuli(stimuli)
	inst.components.aoeweapon_leap:SetOnLeapFn(on_leap_fn)
end
-----------------------------

-----------------------------
-- AOEWeaponLeap Functions --
-----------------------------
local function AOEWeaponLungeInit(inst, width, stimuli, on_lunge_fn)
	inst:AddComponent("aoeweapon_lunge")
	inst.components.aoeweapon_lunge:SetWidth(width)
	--inst.components.aoeweapon_lunge:SetDamage(tuning_values.ALT_DAMAGE)
	inst.components.aoeweapon_lunge:SetStimuli(stimuli)
	inst.components.aoeweapon_lunge:SetOnLungeFn(on_lunge_fn)
end
-----------------------------

----------------------
-- Weapon Functions --
----------------------
local function WeaponInit(inst, weapon_values, tuning_values)
	inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(tuning_values.DAMAGE)
	inst.components.weapon:SetOnAttack(weapon_values.OnAttack)
    inst.components.weapon:SetRange(tuning_values.ATTACK_RANGE, tuning_values.HIT_RANGE)
    inst.components.weapon:SetProjectile(weapon_values.projectile)
	inst.components.weapon:SetOnProjectileLaunch(weapon_values.projectile_fn)
	inst.components.weapon:SetDamageType(tuning_values.DAMAGE_TYPE)
	inst.components.weapon:SetStimuli(tuning_values.STIMULI)
	inst.components.weapon:SetHitWeight(weapon_values.hit_weight)
	inst.components.weapon:SetHitWeightFN(weapon_values.HitWeightFN)
	if tuning_values.ALT_DAMAGE then -- TODO if a weapon has an alt attack it must have ALT_DAMAGE, right?
		inst.components.weapon:SetAltAttack(tuning_values.ALT_DAMAGE, tuning_values.ALT_RADIUS or tuning_values.ALT_RANGE or {tuning_values.ALT_ATTACK_RANGE or tuning_values.ATTACK_RANGE, tuning_values.ALT_HIT_RANGE or tuning_values.HIT_RANGE}, nil, tuning_values.DAMAGE_TYPE, weapon_values.CalcAltDamage) -- TODO ALT_DAMAGE defaulted to DAMAGE if the same (need to change check if yes)?, ALT ranges defaulted to regular attack range, do these cause issues? should they always be set in tuning even if they are the same? range is hacky, fix
	end
end
----------------------

--------------------------
-- Projectile Functions --
--------------------------
local function ProjectileInit(inst, projectile_values)
	local values = projectile_values.is_alt and projectile_values.alt or projectile_values
    inst:AddComponent("projectile")
	inst.components.projectile:SetSpeed(values.speed or 35)
	inst.components.projectile:SetRange(values.range or 20)
	inst.components.projectile:SetStimuli(values.stimuli)
	inst.components.projectile:SetDamageType(values.damage_type)
	inst.components.projectile:SetHitDist(values.hit_dist or 0.5)
	inst.components.projectile:SetLaunchOffset(values.launch_offset)
	inst.components.projectile:SetOnThrownFn(values.OnThrown)
	inst.components.projectile:SetOnHitFn(values.OnHit)
	inst.components.projectile:SetOnMissFn(values.OnMiss or inst.Remove)
	inst.components.projectile:SetHoming(values.homing or values.homing == nil)
end

local function ComplexProjectileInit(inst, projectile_values)
	local values = projectile_values.is_alt and projectile_values.alt or projectile_values
    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetHorizontalSpeed(values.speed or 20)
    inst.components.complexprojectile:SetGravity(values.gravity or 30)
    inst.components.complexprojectile:SetLaunchOffset(values.launch_offset or Vector3(0,0,0))
    inst.components.complexprojectile:SetOnLaunch(values.OnLaunch)
    inst.components.complexprojectile:SetOnHit(values.OnHit)
    inst.components.complexprojectile.usehigharc = values.high_arc == nil and inst.components.complexprojectile.usehigharc or values.high_arc
end
----------------------

------------------------
-- Weapon Prefab Init --
------------------------
--bank, build, anim, nameoverride, image_name, swap_strings, weapon_values, tuning_values
local function CommonWeaponFN(bank, build, weapon_values, tuning_values)
	local inst = COMMON_FNS.BasicEntityInit(bank, build, weapon_values.anim, {pristine_fn = function(inst)
		MakeInventoryPhysics(inst)
		------------------------------------------
		inst.nameoverride = weapon_values.name_override
		------------------------------------------
		-- rechargeable (from rechargeable component) added to pristine state for optimization
		inst:AddTag("rechargeable")
		------------------------------------------
		if weapon_values.pristine_fn then
			weapon_values.pristine_fn(inst)
		end
	end})
	------------------------------------------
	local reticule = tuning_values.RET or {}
	if reticule.TYPE == "directional" then
		DirectionalReticuleInit(inst, reticule.LENGTH, reticule.PREFAB, reticule.PING_PREFAB, reticule.ALWAYS_VALID)
	elseif reticule.TYPE == "aoe" then
		AOEReticuleInit(inst, reticule.LENGTH, reticule.PREFAB, reticule.PING_PREFAB, reticule.VALID_COLOR,reticule.VALID_COLORS, reticule.INVALID_COLOR)
	end
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	AOESpellInit(inst, weapon_values.AOESpell, tuning_values.SPELL_TYPES)
	------------------------------------------
	RechargeableInit(inst, tuning_values)
	------------------------------------------
	WeaponInit(inst, weapon_values, tuning_values)
	------------------------------------------
	ItemTypeInit(inst, tuning_values.ITEM_TYPE)
	------------------------------------------
	inst:AddComponent("inspectable")
	------------------------------------------
	InventoryItemInit(inst, weapon_values.image_name or bank)
	------------------------------------------
	local function WeaponOnEquip(inst, owner)
		if weapon_values.onequip_fn then
			weapon_values.onequip_fn(inst, owner)
		end
		inst.components.weapon:UpdateAltAttackRange(nil, nil, owner)
	end
	local function WeaponOnUnequip(inst, owner)
		if weapon_values.onunequip_fn then
			weapon_values.onunequip_fn(inst, owner)
		end
		inst.components.weapon:UpdateAltAttackRange(nil, nil, owner)
	end
	EquippableInit(inst, weapon_values.type or "hand", weapon_values.onequip_fn, weapon_values.onunequip_fn, unpack(weapon_values.swap_strings))
	------------------------------------------
	return inst
end

local function ProjectileWeaponInit(inst, projectile_prefab, damage, damage_type, attack_period, attack_range, hit_range, OnLaunch, OnLaunched, sync_projectile)--LaunchPositionOverride)
	local weapon = CreateEntity()
	weapon.entity:AddTransform()
	------------------------------------------
	weapon:AddComponent("weapon")
	weapon.components.weapon:SetDamage(damage)
	weapon.components.weapon:SetRange(attack_range, hit_range)
	weapon.components.weapon:SetProjectile(projectile_prefab)
	weapon.components.weapon:SetDamageType(damage_type) -- TODO need damage_type in tuning_values somehow
	weapon.components.weapon:SetOnProjectileLaunch(OnLaunch)
	weapon.components.weapon:SetOnProjectileLaunched(OnLaunched)
	--weapon.components.weapon:SetLaunchPositionOverride(LaunchPositionOverride)
	weapon.components.weapon:SyncProjectile(sync_projectile)
	weapon.attack_period = attack_period
	------------------------------------------
	weapon:AddComponent("inventoryitem")
	weapon.components.inventoryitem:SetOnDroppedFn(inst.Remove) -- TODO is this really needed?
	------------------------------------------
	ItemTypeInit(inst, "restricted")
	------------------------------------------
	weapon:AddComponent("equippable")
	------------------------------------------
	weapon.persists = false
	------------------------------------------
	return weapon
end
------------------------

----------------------------
-- Projectile Prefab Init --
----------------------------
local function CreateTail(tail_values, source)
    local inst = CreateEntity()
    COMMON_FNS.AddTags(inst, "FX", "NOCLICK")
    --Non-networked entity
    inst.entity:SetCanSleep(false)
    inst.persists = false
    ------------------------------------------
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    ------------------------------------------
    --MakeInventoryPhysics(inst)
    --inst.Physics:ClearCollisionMask()
    if tail_values.physics_init_fn then
    	tail_values.physics_init_fn(inst)
    end
    ------------------------------------------
    inst.AnimState:SetBank(tail_values.bank)
    inst.AnimState:SetBuild(tail_values.build)
    inst.AnimState:PlayAnimation(tail_values.anim)
    ------------------------------------------
    if tail_values.orientation then
    	inst.AnimState:SetOrientation(tail_values.orientation)
    end
    ------------------------------------------
    local scale = tail_values.scale or source.Transform:GetScale()
    if scale then
        inst.AnimState:SetScale(scale, scale)
    end
    ------------------------------------------
    local add_colour = tail_values.add_colour
    if add_colour then
        inst.AnimState:SetAddColour(unpack(add_colour))
    end
    ------------------------------------------
    local mult_colour = tail_values.mult_colour
    if mult_colour then
        inst.AnimState:SetMultColour(unpack(mult_colour))
    end
    ------------------------------------------
    local light_override = tail_values.light_override
    if (light_override or 0) > 0 then
        inst.AnimState:SetLightOverride(light_override)
    end
    ------------------------------------------
    if tail_values.final_offset then
    	inst.AnimState:SetFinalOffset(tail_values.final_offset)
    end
    ------------------------------------------
    if tail_values.shader then
    	inst.AnimState:SetBloomEffectHandle(tail_values.shader)
    end
    ------------------------------------------
    inst:ListenForEvent("animover", inst.Remove)
    ------------------------------------------
    return inst
end

local function OnUpdateProjectileTail(inst)
    local tail_values = inst.tail_values
    local x, y, z = inst.Transform:GetWorldPosition()
    for tail,_ in pairs(inst.tails) do
        tail:ForceFacePoint(x, y, z)
    end
    if inst.entity:IsVisible() then
        local tail = inst.CreateTail(tail_values, inst)
        local rot = inst.Transform:GetRotation()
        tail.Transform:SetRotation(rot)
        rot = rot * DEGREES
        local offsangle = math.random() * 2 * PI
        local offsradius = (math.random() * .2 + .2) * (tail_values.scale or 1)
        local hoffset = math.cos(offsangle) * offsradius
        local voffset = math.sin(offsangle) * offsradius
        tail.Transform:SetPosition(x + math.sin(rot) * hoffset, y + voffset, z + math.cos(rot) * hoffset)
        if tail_values.speed then
        	tail.Physics:SetMotorVel(tail_values.speed * (.2 + math.random() * .3), 0, 0)
        end
        inst.tails[tail] = true
        inst:ListenForEvent("onremove", function(tail)
            inst.tails[tail] = nil
        end, tail)
        tail:ListenForEvent("onremove", function(inst)
            tail.Transform:SetRotation(tail.Transform:GetRotation() + math.random() * 30 - 15)
        end, inst)
    end
end

local function OnHasTailDirty(inst)
    if inst._hastail:value() and inst.tails == nil then
        inst.tails = {}
        if inst.components.updatelooper == nil then
            inst:AddComponent("updatelooper")
        end
        inst.components.updatelooper:AddOnUpdateFn(inst.OnUpdateProjectileTail)
    end
end

local function SetProjectileSource(inst, source, force_update)
	inst.source = source
	inst.components.scaler:SetSource(source, force_update)
end

local function CommonProjectileFN(bank, build, anim, projectile_values, tail_values)
	local inst = COMMON_FNS.BasicEntityInit(bank, build, anim, {pristine_fn = function(inst)
		if projectile_values.physics_init_fn then
			projectile_values.physics_init_fn(inst)
		else
			MakeInventoryPhysics(inst)
		end
		RemovePhysicsColliders(inst) -- TODO is this in all projectiles???
		------------------------------------------
		-- projectile (from projectile component) added to pristine state for optimization
	    COMMON_FNS.AddTags(inst, "projectile", "NOCLICK")
		------------------------------------------
		if projectile_values.add_colour then
			inst.AnimState:SetAddColour(unpack(projectile_values.add_colour))
		end
		if projectile_values.mult_colour then
			inst.AnimState:SetMultColour(unpack(projectile_values.mult_colour))
		end
		if (projectile_values.light_override or 0) > 0 then
			inst.AnimState:SetLightOverride(projectile_values.light_override)
		end
	    ------------------------------------------
	    if not projectile_values.no_tail then
			local common_tail_values = {
			    bank  = bank,
			    build = build or bank,
			    anim  = "disappear",
			}
		    inst.tail_values = tail_values or {}
		    MergeTable(inst.tail_values, common_tail_values)
		    inst.CreateTail = inst.tail_values.CreateTail or CreateTail
		    inst.OnUpdateProjectileTail = inst.tail_values.OnUpdateProjectileTail or OnUpdateProjectileTail
		    ------------------------------------------
	    	inst._hastail = net_bool(inst.GUID, tostring(inst.prefab).."._hastail", "hastaildirty")
	    	------------------------------------------
			if not TheNet:IsDedicated() then
				inst:ListenForEvent("hastaildirty", OnHasTailDirty)
			end
			------------------------------------------
		end
		------------------------------------------
		if projectile_values.pristine_fn then
			projectile_values.pristine_fn(inst)
		end
	end, anim_loop = projectile_values.anim_loop})
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	if projectile_values.complex then
		ComplexProjectileInit(inst, projectile_values)
	else
		ProjectileInit(inst, projectile_values)
	end
	------------------------------------------
	if projectile_values.shader then
		inst.AnimState:SetBloomEffectHandle(projectile_values.shader)
	end
	------------------------------------------
	inst.SetSource = SetProjectileSource
	------------------------------------------
	local physics = projectile_values.physics or {}
	COMMON_FNS.AddScalerComponent(inst, {mass = physics.mass or 1, radius = physics.radius or 0.5})
	if projectile_values.scale then
		inst.components.scaler:SetBaseScale(projectile_values.scale)
	end
	------------------------------------------
	return inst
end

local function OnDirectionDirty(inst)
    inst.animent.Transform:SetRotation(inst.direction:value())
end

local function CommonComplexProjectileFN(bank, build, anim, projectile_values)
	local inst = COMMON_FNS.BasicEntityInit(bank, build, anim, {pristine_fn = function(inst)
		inst.entity:AddPhysics()
		if projectile_values.physics_init_fn then
			projectile_values.physics_init_fn(inst)
		else
			COMMON_FNS.MakeComplexProjectilePhysics(inst)
		end
		------------------------------------------
		-- projectile (from projectile component) added to pristine state for optimization
	    COMMON_FNS.AddTags(inst, "projectile", "NOCLICK")
	    ------------------------------------------
	    inst.direction = net_float(inst.GUID, tostring(bank) .. "_projectile.direction", "directiondirty")
		------------------------------------------
		-- Dedicated server does not need to spawn the local animation
	    if not TheNet:IsDedicated() then
	        inst.animent = projectile_values.CreateProjectileAnim and projectile_values.CreateProjectileAnim(bank, build, anim) or COMMON_FNS.CreateProjectileAnim(bank, build, anim)
	        inst.animent.entity:SetParent(inst.entity)

	        if not TheWorld.ismastersim then
	            inst:ListenForEvent("directiondirty", OnDirectionDirty)
	        end
	    end
	    ------------------------------------------
	    if projectile_values.pristine_fn then
	    	projectile_values.pristine_fn(inst)
	    end
	end})
    ------------------------------------------
    --inst.entity:SetPristine() -- Moved to each instance rather than a common function
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	ComplexProjectileInit(inst, projectile_values)
	------------------------------------------
	inst.SetSource = SetProjectileSource
	------------------------------------------
	local physics = projectile_values.physics or {}
	COMMON_FNS.AddScalerComponent(inst, {mass = physics.mass or 1, radius = physics.radius or 0.5})
	if projectile_values.scale then
		inst.components.scaler:SetBaseScale(projectile_values.scale)
	end
	------------------------------------------
	return inst
end
------------------------

-----------
-- Armor --
-----------
--bank, build, anim, nameoverride, image_name, swap_strings, armor_values, tuning_values
local function ArmorInit(bank, build, anim, armor_values, tuning_values)
	local armor_values = armor_values or {}
	local inst = COMMON_FNS.BasicEntityInit(bank, build, anim, {pristine_fn = function(inst)
		MakeInventoryPhysics(inst)
	    ------------------------------------------
	    inst.nameoverride = armor_values.name_override
	    inst:AddTag("hide_percentage")
    	------------------------------------------
    	if armor_values.pristine_fn then
    		armor_values.pristine_fn(inst)
    	end
    end})
    ------------------------------------------
	--inst.entity:SetPristine() -- Moved to each instance rather than a common function
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
	ItemTypeInit(inst, "armors")
	------------------------------------------
	inst:AddComponent("inspectable")
	------------------------------------------
	InventoryItemInit(inst, armor_values.image_name or bank)
	------------------------------------------
	EquippableInit(inst, armor_values.type or "body", armor_values.onequip_fn, armor_values.onunequip_fn, unpack(armor_values.wap_strings or {"swap_body", build or bank, "swap_body"}))
	inst.components.equippable.equipslot = EQUIPSLOTS.BODY
	------------------------------------------
	inst:AddComponent("armor")
	------------------------------------------
    return inst
end
-----------

----------
-- Helm --
----------
--bank, build, anim, nameoverride, image_name, swap_strings, hat_values, tuning_values
local function HelmInit(bank, build, anim, hat_values, tuning_values)
	local hat_values = hat_values or {}
	local inst = COMMON_FNS.BasicEntityInit(bank, build, anim, {pristine_fn = function(inst)
		MakeInventoryPhysics(inst)
	    ------------------------------------------
	    inst.nameoverride = hat_values.name_override
	    inst:AddTag("hat")
    	------------------------------------------
    	if hat_values.pristine_fn then
    		hat_values.pristine_fn(inst)
    	end
    end})
    ------------------------------------------
	--inst.entity:SetPristine() -- Moved to each instance rather than a common function
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
	ItemTypeInit(inst, "hats")
	------------------------------------------
	inst:AddComponent("inspectable")
	------------------------------------------
	InventoryItemInit(inst, hat_values.image_name or bank)
	------------------------------------------
	EquippableInit(inst, hat_values.type or "head", hat_values.onequip_fn, hat_values.onunequip_fn, unpack(hat_values.swap_strings or {"swap_hat", build or bank, "swap_hat"}))
	inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
	inst.cover_head = hat_values.cover_head
	------------------------------------------
    return inst
end
----------

-----------------------------
-- Common Weapon Functions --
-----------------------------
local function HasProjectile(weapon)
	return weapon and (weapon.components.projectile or weapon.components.complexprojectile or weapon.components.weapon:CanRangedAttack())
end
-----------------------------

return {
	-- Equippable Functions
	EquippableInit = EquippableInit,
	onequip_fns    = onequip_fns,
	onunequip_fns  = onunequip_fns,
	-- AOE Reticules
	AOEReticuleInit     = AOEReticuleInit,
	AOEReticuleTargetFn = AOEReticuleTargetFn,
	-- Directional Reticules
	DirectionalReticuleInit     = DirectionalReticuleInit,
	DirectionalReticuleTargetFn = DirectionalReticuleTargetFn,
	ReticuleMouseTargetFn       = ReticuleMouseTargetFn,
	ReticuleUpdatePositionFn    = ReticuleUpdatePositionFn,
	-- Attack Functions
	ApplyArmorBreak = ApplyArmorBreak,
	FlipTarget      = FlipTarget,
	GetAOETargets   = GetAOETargets,
	-- Basic Component Inits
	ItemTypeInit         = ItemTypeInit,
	InventoryItemInit    = InventoryItemInit,
	AOESpellInit         = AOESpellInit,
	RechargeableInit     = RechargeableInit,
	AOEWeaponLeapInit    = AOEWeaponLeapInit,
	AOEWeaponLungeInit   = AOEWeaponLungeInit,
	WeaponInit           = WeaponInit,
	ProjectileWeaponInit = ProjectileWeaponInit,
	-- Basic Prefab Init
	CommonWeaponFN            = CommonWeaponFN,
	SetProjectileSource       = SetProjectileSource,
	CommonProjectileFN        = CommonProjectileFN,
	CommonComplexProjectileFN = CommonComplexProjectileFN,
	ArmorInit                 = ArmorInit,
	HelmInit                  = HelmInit,
	-- Common Weapon Functions
	HasProjectile = HasProjectile,
}
