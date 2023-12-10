--[[-----------------------------------------------------------------------------------------
										Combat
-------------------------------------------------------------------------------------------]]
--New combat stuff for alt attacks and damage buffs
--TODO: Make sure EVERY single damage source has at least a damagetype clarified
--(Might set it so that it automatically has physical as a default) and also fill in stimuli wherever it seems reasonable to do so
_G.TUNING.FORGE.DAMAGETYPES = {
	PHYSICAL = 1,
	MAGIC = 2,
	SOUND = 3,
	GAS = 4,
	LIQUID = 5
}
_G.DAMAGETYPE_IDS = {} -- TODO ???
for k,v in pairs(_G.TUNING.FORGE.DAMAGETYPES) do
	_G.DAMAGETYPE_IDS[v] = k
end

--TODO: Make this all compatible with mounts and saddle bonuses

AddComponentPostInit("combat", function(self)
	self.damage_override = nil
	self.damagetype = nil
	self.damagebuffs = { dealt = {}, recieved = {} }

	_OldStartTrackingTarget = self.StartTrackingTarget
	function self:StartTrackingTarget(target)
		if target then
			self.target_aggro_start = _G.GetTime()
		end
		_OldStartTrackingTarget(self, target)
	end

	_OldStopTrackingTarget = self.StopTrackingTarget
	function self:StopTrackingTarget(target)
		if target ~= nil then
			local target_player = target:HasTag("player") and target or target.components.follower and target.components.follower.leader and target.components.follower.leader:HasTag("player") and target.components.follower.leader or nil
			if _G.TheWorld and _G.TheWorld.components.stat_tracker and target_player then
				_G.TheWorld.components.stat_tracker:AdjustStat("aggroheld", target_player, _G.GetTime() - (self.target_aggro_start or _G.GetTime()))
			end
		end
		_OldStopTrackingTarget(self, target)
	end

	local _oldSetTarget = self.SetTarget
	function self:SetTarget(target, forced)
		if not self.has_forced_target then
			_oldSetTarget(self, target)
			if forced and self.target == target then
				self.has_forced_target = true
			end
		end
	end
	
	--[[
	local old_IsAlly = self.IsAlly
	function self:IsAlly(guy,...)
		if COMMON_FNS.IsAlly(self.inst, guy) then
			return true
		end
		return old_IsAlly(self,guy,...)
	end]]

	function self:SetDamageType(damagetype)
		self.damagetype = damagetype
	end

	function self:HasDamageBuff(buffname, recieved)
		return self.damagebuffs[recieved and "recieved" or "dealt"][buffname] ~= nil
	end

	function self:AddDamageBuff(buffname, data, recieved, remove_old_buff)
		--buffname = unique string name pertaining to this buff (Make sure it is a very unique name as to not conflict with other damage buffs)
		--data.buff = buff value (Remember, as additive add 0.1 for +10%, as multiplicative add 1.1 for +10%, and as a flat add value put in an actual damage number that adds to the overall damage)
		--(Remember, data.buff can be a number value OR a function using the arguments [attacker, victim, weapon, stimuli]. Just make sure it returns the correct number value.)
		--data.addtype = nil or "mult" if multiplicative, "add" if additive, "flat" if flat added damage
		--data.stimuli = string value for a buff pertaining to a specific stimuli
		--data.damagetype = number value (matching DAMAGETYPES table) for a buff pertaining to a specific damagetype
		--data.weapontype = string value for a buff pertaining to a specific weapontype
		--(If multiple of stimuli/damagetype/weapontype are set, all requirements must be met for the buff to apply)
		--recieved = true if modifier on damage taken rather than damage dealt
		if remove_old_buff and self:HasDamageBuff(buffname, recieved) then
			self:RemoveDamageBuff(buffname, recieved)
		end
		if not self:HasDamageBuff(buffname, recieved) then
			local buff = type(data) == "number" and {buff = data} or data
			self.damagebuffs[recieved and "recieved" or "dealt"][buffname] = buff
		end
	end

	function self:RemoveDamageBuff(buffname, recieved)
		self.damagebuffs[recieved and "recieved" or "dealt"][buffname] = nil
	end

	function self:CopyBuffsTo(ent)
		--Used to make 1 entity's damage component read buffs off of another (like shadow dueslists off of maxwell)
		--WARNING: When using this function, if either entity adds or removes a buff it will affect BOTH entities.
		if ent and ent.components.combat then
			ent.components.combat.damagebuffs = self.damagebuffs
		end
	end

	local _oldGetAttackRange = self.GetAttackRange
	function self:GetAttackRange()
		local weapon = self:GetWeapon()
		if weapon and weapon.components.weapon:CanAltAttack() then
			return weapon.components.weapon.altattackrange
		else
			return _oldGetAttackRange(self)
		end
	end

	local _oldGetHitRange = self.GetHitRange
	function self:GetHitRange()
		local weapon = self:GetWeapon()
		if weapon and weapon.components.weapon:CanAltAttack() then
			return self.attackrange + weapon.components.weapon.althitrange
		else
			return _oldGetHitRange(self)
		end
	end

	self.base_attack_range = self.attackrange
	self.base_hit_range = self.hitrange
	self.base_area_hit_range = nil
	local _oldSetRange = self.SetRange
	function self:SetRange(attack, hit)
		_oldSetRange(self, attack, hit)
		self.base_attack_range = self.attackrange
		self.base_hit_range = self.hitrange
		self:UpdateRange()
	end

	local _oldSetAreaDamage = self.SetAreaDamage
	function self:SetAreaDamage(range, ...)
		_oldSetAreaDamage(self, range, ...)
		self.base_area_hit_range = range
		self:UpdateRange()
	end

	-- Adjust range based on scaling of entity
	function self:UpdateRange()
		local scaler = self.inst.components.scaler
		if scaler then
			local scale = scaler.scale or 1
			self.attackrange = self.base_attack_range * scale
			self.hitrange = self.base_hit_range * scale
			if self.areahitrange then
				self.areahitrange = self.base_area_hit_range * scale
			end
		end
	end

	self.attacks = {}
	function self:AddAttack(attack, active, cooldown, cooldown_fn, custom_opts)
		self.attacks[attack] = {
			active = active ~= nil and active, -- Default is false
			ready = ready ~= nil and ready or nil,
			opts = custom_opts or {},
		}
		self:SetCooldown(attack, cooldown, cooldown_fn)
	end
	function self:AddAttacks(attacks)
		for attack,data in pairs(attacks) do
			self:AddAttack(attack, data.active, data.cooldown, data.cooldown_fn, data.opts)
		end
	end
	function self:ToggleAttack(attack, active)
		if not self.attacks[attack] then return end
		self.attacks[attack].active = active or active == nil and not self.attacks[attack].active
	end
	function self:ReadyAttack(attack, ready)
		if not self.attacks[attack] then return end
		self.attacks[attack].ready = ready or ready == nil and not self.attacks[attack].ready
	end
	function self:IsAttackActive(attack)
		return self.attacks[attack] and self.attacks[attack].active
	end
	function self:IsAttackReady(attack)
		return self.attacks[attack] and self.attacks[attack].active and not self:InCooldown(attack) and (self.attacks[attack].ready == nil or self.attacks[attack].ready)
	end
	function self:GetAttackOptions(attack)
		return self.attacks[attack] and self.attacks[attack].opts
	end
	-- is_override will completely replace the options of the attack.
	function self:SetAttackOptions(attack, options, is_override)
		if not self.attacks[attack] then return end
		if is_override then
			self.attacks[attack].opts = options
		else
			_G.MergeTable(self.attacks[attack].opts, options, true)
		end
	end

	self.cooldowns = {}
    self.cooldown_timers = {}
    self.cooldown_complete_fns = {}
    -- Returns the cooldown of the give attack
	-- original: returns the cooldown without buffs
    function self:GetTotalCooldown(attack, original)
    	local cooldown = self.cooldowns[attack] or 0
    	return not original and self.inst.components.buffable and self.inst.components.buffable:ApplyStatBuffs({"attack_rate"}, cooldown) or cooldown
    end
	function self:InCooldown(attack)
	    return self.cooldown_timers[attack] ~= nil or attack == nil and self.laststartattacktime ~= nil and self.laststartattacktime + self:GetAttackPeriod() > _G.GetTime()
	end
	function self:GetCooldown(attack)
	    return self.cooldown_timers[attack] and _G.GetTaskRemaining(self.cooldown_timers[attack].timer) or attack == nil and  self.laststartattacktime ~= nil and math.max(0, self:GetAttackPeriod() - _G.GetTime() + self.laststartattacktime) or 0
	end
	local function RemoveCooldown(inst, attack)
        if not self.cooldown_timers[attack] then return end
        self.cooldown_timers[attack] = nil
        if self.cooldown_complete_fns[attack] then
        	self.cooldown_complete_fns[attack](self.inst)
        end
    end
    function self:StartCooldown(attack, cooldown_override)
    	if not self.attacks[attack] then return end
    	if self.cooldown_timers[attack] then
        	_G.RemoveTask(self.cooldown_timers[attack].timer)
        end
        local cooldown_time = cooldown_override or self:GetTotalCooldown(attack) or 0
        if cooldown_time > 0 then
	        self.cooldown_timers[attack] = {timer = self.inst:DoTaskInTime(cooldown_time, function()
	        	RemoveCooldown(inst, attack)
	        end), time = cooldown_time}
	    elseif self.cooldown_complete_fns[attack] then
	    	self.cooldown_complete_fns[attack](self.inst)
	    end
    end
    -- Sets the cooldown of the given attack. If the attack is currently on cooldown then the current cooldown timer is updated as well.
    function self:SetCooldown(attack, cooldown, on_cooldown_complete_fn)
    	if on_cooldown_complete_fn then
    		self.cooldown_complete_fns[attack] = on_cooldown_complete_fn -- TODO should this be set to nil if just updating cooldown?
    	end
    	self.cooldowns[attack] = cooldown or 0
    	-- Check if the cooldown is already active and update its value
        if self.cooldown_timers[attack] then
            local percent_left = _G.GetTaskRemaining(self.cooldown_timers[attack].timer) / self.cooldown_timers[attack].time
            self:StartCooldown(attack, self:GetCooldown(attack) * percent_left)
        end
    end
    -- Checks active cooldown timers to see if they need to be adjusted due to a cooldown change.
    function self:UpdateCooldown()
    	for attack,info in pairs(self.cooldown_timers) do
    		local current_cooldown = self:GetTotalCooldown(attack)
    		if info.time ~= current_cooldown then
    			self:StartCooldown(attack, _G.GetTaskRemaining(info.timer) / info.time * current_cooldown)
    		end
    	end
    end
    function self:CancelCooldown(attack)
    	if self:InCooldown(attack) then
        	_G.RemoveTask(self.cooldown_timers[attack].timer)
        	RemoveCooldown(self.inst, attack)
    	end
    end

    -- TODO need to replace all instances of combat.min_attack_period with this function call, might need to add an exception for player since they use replica?
    function self:GetAttackPeriod()
        return math.max(self.inst.components.buffable and self.inst.components.buffable:ApplyStatBuffs({"attack_rate"}, self.min_attack_period) or self.min_attack_period, 0)
    end

	--cuz SourceModifierList is stupid
	local function calcbuff(recieved, attacker, victim, weapon, stimuli, damage_type)
		local mult = 1
		local add = 1
		local flat = 0
		local source = weapon ~= nil and weapon.components.weapon or self
		for buff,data in pairs(self.damagebuffs[recieved and "recieved" or "dealt"]) do
			local canbuff = true
			if data.stimuli and stimuli ~= data.stimuli then
				canbuff = false
			end
			if data.damagetype and (damage_type or source.damagetype) ~= data.damagetype then
				canbuff = false
			end
			if data.weapontype then
				if weapon == nil or not (weapon.components.itemtype ~= nil and weapon.components.itemtype:IsType(data.weapontype)) then
					canbuff = false
				end
			end

			if canbuff then
				local buff = type(data.buff) == "function" and (data.buff(attacker, victim, weapon, stimuli) or (data.addtype == "flat" and 0 or 1)) or data.buff
				if not data.addtype or data.addtype == "mult" then
					mult = mult * buff
				elseif data.addtype == "add" then
					add = add + buff
				elseif data.addtype == "flat" then
					flat = flat + buff
				end
			end
		end

		return mult, add, flat
	end

	--function self:GetBuffMults(recieved, attacker, victim, weapon, stimuli)
		--return calcbuff(recieved, attacker, victim, weapon, stimuli)
	--end

	local _oldCalcDamage = self.CalcDamage
	function self:CalcDamage(target, weapon, multiplier, is_alt, damage_type, stimuli, damage_override)
		if target and target:HasTag("alwaysblock") then
			return 0
		end
		local basedamage = damage_override or weapon ~= nil and weapon.components.weapon and weapon.components.weapon.damage or self.defaultdamage
		basedamage = type(basedamage) == "function" and basedamage(self.inst, target) or basedamage
		local basemultiplier = self.damagemultiplier
		local externaldamagemultipliers = self.externaldamagemultipliers
		local bonus = self.damagebonus --not affected by multipliers
		local is_player = target and target:HasTag("player")
		local playermultiplier = weapon ~= nil and is_player and self.playerdamagepercent or 1
		local pvpmultiplier = is_player and self.inst:HasTag("player") and self.pvp_damagemod or 1

		if not damage_override then
			if self.damage_override then
				basedamage = type(self.damage_override) == "function" and self.damage_override(self.inst, target) or self.damage_override
	        elseif weapon and (weapon.components.weapon and weapon.components.weapon:CanAltAttack() or is_alt) then
	            basedamage = weapon.components.weapon.altdamagecalc ~= nil and weapon.components.weapon.altdamagecalc(weapon, self.inst, target) or (weapon.components.weapon.altdamage or basedamage)
	        end
	    end

		-- Also plugging here to apply damage dealt buffs since this function only ever runs from the dealing damage side
		local mult, add, flat = calcbuff(false, self.inst, target, weapon, stimuli or self.currentstimuli, damage_type)
		self.currentstimuli = nil
		return basedamage * (basemultiplier or 1) * self.externaldamagemultipliers:Get() * (multiplier or 1) * playermultiplier * pvpmultiplier * mult * add + flat + (bonus or 0)
	end

	local _oldGetWeapon = self.GetWeapon
    function self:GetWeapon()
        return not self.damage_override and _oldGetWeapon(self) or nil
    end

    -- Make sure source is valid before attempting target checks.
	local _oldCanTarget = self.CanTarget
    function self:CanTarget(target)
	    return self.inst:IsValid() and _oldCanTarget(self, target)
	end

	-- Can't use kleis because they cause forge projectiles to fail even though they hit
	local _oldCanHitTarget = self.CanHitTarget
	function self:CanHitTarget(target, weapon, projectile)--[[
		print("self.inst: " .. tostring(self.inst))
		print("self.inst:IsValid: " .. tostring(self.inst:IsValid()))
		print("target: " .. tostring(target))
		print("target:IsValid: " .. tostring(target:IsValid()))
		print("target:IsInLimbo: " .. tostring(target:IsInLimbo()))
		print("Extinguish: " .. tostring(self:CanExtinguishTarget(target, weapon)))
		print("Lightable: " .. tostring(self:CanLightTarget(target, weapon)))
		print("target:CanBeAttacked: " .. tostring(target.components.combat:CanBeAttacked(self.inst)))--]]
		if self.inst and self.inst:IsValid() and target and target:IsValid() and not target:IsInLimbo() and (self:CanExtinguishTarget(target, weapon) or self:CanLightTarget(target, weapon) or (target.components.combat and target.components.combat:CanBeAttacked(self.inst))) then
			local targetpos = target:GetPosition()
			-- V2C: this is 3D distsq, ignore range for alt attacks, they use a different range check. TODO double check that this is correct
			if self.ignorehitrange or _G.distsq(targetpos, self.inst:GetPosition()) <= self:CalcHitRangeSq(target)
				or weapon and weapon.components.weapon and weapon.components.weapon.isaltattacking -- alt attacks have their own hit detection function
				or projectile and projectile.components.complexprojectile then -- Complex projectiles have their own hit detection function
				return true
			-- Weapon is a projectile range check
			elseif weapon and weapon.components.projectile then
				local range = target:GetPhysicsRadius(0) + weapon.components.projectile.hitdist
				-- V2C: this is 3D distsq
				return _G.distsq(targetpos, weapon:GetPosition()) <= range * range
			-- Aimed projectiles always hit and so should any regular projectile attack since projectile checks if target is hit prior. TODO double check that this should always be the case
			elseif weapon and (weapon.aimed_projectile_hit or weapon.components.weapon.projectile) then
				weapon.aimed_projectile_hit = nil
				return true
			end
		end
		return false
	end

	_oldDoAttack = self.DoAttack
	function self:DoAttack(target, weapon, projectile, stimuli, instancemult, damage_override, is_alt, is_special, damage_type)
		--_oldDoAttack(self, target_override, weapon, projectile, stimuli, instancemult)
		-- nil checks
		target = target or self.target
		weapon = weapon or self:GetWeapon()
		-- Stimuli override
		if not stimuli and weapon and weapon.components.weapon and weapon.components.weapon.overridestimulifn then
			stimuli = weapon.components.weapon.overridestimulifn(weapon, self.inst, target)
		end
		self.currentstimuli = stimuli

		if not self:CanHitTarget(target, weapon, projectile) then
			self.inst:PushEvent("onmissother", { target = target, weapon = weapon })
			if self.areahitrange and not self.areahitdisabled then
				self:DoAreaAttack(projectile or self.inst, self.areahitrange, weapon, nil, stimuli, { "INLIMBO" })
			end
			return
		end

		self.inst:PushEvent("onattackother", { target = target, weapon = weapon, projectile = projectile, stimuli = stimuli, is_special = is_special, damage_type = damage_type })

		-- If a weapon has a projectile and this attack is not a projectile then throw the projectile
		if weapon and projectile == nil then
			if weapon.components.projectile and not weapon.components.projectile.melee_weapon or weapon.components.complexprojectile then
				local projectile = self.inst.components.inventory:DropItem(weapon, false)
				if projectile then
					if weapon.components.projectile then
						self.currentstimuli = projectile.components.projectile.stimuli
						projectile.components.projectile:Throw(self.inst, target, self:CalcDamage(target, weapon, 1, nil, damage_type) * (instancemult or 1)) -- TODO check mult value, should it just be 1 or is the electric check needed?
					elseif weapon.components.complexprojectile then
						self.currentstimuli = projectile.components.complexprojectile.stimuli
						projectile.components.complexprojectile:Launch(target:GetPosition(), self.inst, nil, self:CalcDamage(target, weapon, 1, nil, damage_type) * (instancemult or 1)) -- TODO check mult value, should it just be 1 or is the electric check needed?
					end
					self.inst:PushEvent("onprojectileattack", { target = target, weapon = weapon, projectile = projectile, stimuli = stimuli })
				end
				return
			elseif weapon.components.weapon:CanRangedAttack() then
				self.currentstimuli = weapon.components.weapon.stimuli
				weapon.components.weapon:LaunchProjectile(self.inst, target, self:CalcDamage(target, weapon, 1, nil, damage_type) * (instancemult or 1)) -- TODO check mult value, should it just be 1 or is the electric check needed?
				self.inst:PushEvent("onprojectileattack", { target = target, weapon = weapon, projectile = projectile, stimuli = stimuli })
				return
			end
		end

		local reflected_dmg = 0
		local reflect_list = {}
		-- Calculate damage to target and attack the target
		if target.components.combat then
			local mult = 1--(stimuli == "electric" or (weapon and weapon.components.weapon and weapon.components.weapon.stimuli == "electric")) and not (target:HasTag("electricdamageimmune") or (target.components.inventory and target.components.inventory:IsInsulated())) and _G.TUNING.ELECTRIC_DAMAGE_MULT + _G.TUNING.ELECTRIC_WET_DAMAGE_MULT * (target.components.moisture and target.components.moisture:GetMoisturePercent() or (target:GetIsWet() and 1 or 0)) or 1 -- electric damage bonus
			local dmg = damage_override or self:CalcDamage(target, weapon, mult, nil, damage_type) * (instancemult or 1)
			-- Calculate reflect first, before GetAttacked destroys armor etc.
			if projectile == nil then
				reflected_dmg = self:CalcReflectedDamage(target, dmg, weapon, stimuli, reflect_list)
			end
			target.components.combat:GetAttacked(self.inst, dmg, weapon, stimuli, is_alt, projectile, damage_type)
		-- Calculate reflected damage even if the target has no combat component
		elseif not projectile then
			reflected_dmg = self:CalcReflectedDamage(target, 0, weapon, stimuli, reflect_list)
		end

		if weapon and weapon.components.weapon then
			weapon.components.weapon:OnAttack(self.inst, target, projectile)
		end

		if self.areahitrange and not self.areahitdisabled then
			self:DoAreaAttack(target, self.areahitrange, weapon, nil, stimuli, { "INLIMBO" })
		end

		self.lastdoattacktime = _G.GetTime()

		-- Apply reflected damage to self after our attack damage is completed
		if reflected_dmg > 0 and self.inst.components.health and not self.inst.components.health:IsDead() then
			self:GetAttacked(target, reflected_dmg)
			for i, v in ipairs(reflect_list) do
				if v.inst:IsValid() then
					v.inst:PushEvent("onreflectdamage", v)
				end
			end
		end
	end

	_oldDoAreaAttack = self.DoAreaAttack
	function self:DoAreaAttack(target, range, weapon, validfn, stimuli, excludetags)
		self.currentstimuli = stimuli
		--self.lastdoattacktime = _G.GetTime()
		return _oldDoAreaAttack(self, target, range, weapon, validfn, stimuli, excludetags)
	end

	function self:SetDodgeFN(fn)
		self.dodge_fn = fn
	end

	_oldGetAttacked = self.GetAttacked
	function self:GetAttacked(attacker, damage, weapon, stimuli, is_alt, projectile, damage_type, unblockable)
		self:UpdateLastPlayerAttack(attacker)
		local mult, add, flat = calcbuff(true, attacker, self.inst, weapon, stimuli, damage_type)
		damage = damage * mult * add + flat
		self.lastwasattackedtime = _G.GetTime()

		--print ("ATTACKED", self.inst, attacker, damage)
		--V2C: redirectdamagefn is currently only used by either mounting or parrying,
		--     but not both at the same time.  If we use it more, then it really needs
		--     to be refactored.
		local blocked = false
		local damageredirecttarget = self.redirectdamagefn and self.redirectdamagefn(self.inst, attacker, damage, weapon, stimuli) or nil
		local damageresolved = 0

		self.lastattacker = attacker

		-- Calculate True Damage
		local true_damage = damage
		if true_damage then
			if self.inst.components.inventory then
				true_damage = self.inst.components.inventory:ApplyDamage(true_damage, attacker, weapon)
			end
			true_damage = true_damage * self.externaldamagetakenmultipliers:Get()
			--Bonus damage only applies after unabsorbed damage gets through your armor
			if true_damage > 0 and attacker and attacker.components.combat and attacker.components.combat.bonusdamagefn then
				damage = damage + attacker.components.combat.bonusdamagefn(attacker, self.inst, damage, weapon) or 0
			end
			if self.block_fn then
				true_damage = self.block_fn(self.inst, attacker, weapon, projectile, damage, true_damage, stimuli, damage_type)
			end
		end

		if self.inst.components.health and damage ~= nil and damageredirecttarget == nil then
			damage = true_damage
			if self.dodge_fn and self.dodge_fn(self.inst, attacker, weapon, projectile, damage, stimuli, damage_type) then
				self.inst:PushEvent("dodged", {attacker = attacker, damage = damage, weapon = weapon, stimuli = stimuli, projectile = projectile})
				return false
			elseif damage > 0 and not self.inst.components.health:IsInvincible() then
				local cause = attacker == self.inst and weapon or attacker
				--V2C: guess we should try not to crash old mods that overwrote the health component
				damageresolved = self.inst.components.health:DoDelta(-damage, nil, cause ~= nil and (cause.nameoverride or cause.prefab) or "NIL", nil, cause, _G.TUNING.FORGE.IGNORE_ABSORB_STIMULI[stimuli] ~= nil)
				damageresolved = damageresolved ~= nil and -damageresolved or damage
				if self.inst.components.health:IsDead() then
					if attacker then
						attacker:PushEvent("killed", { victim = self.inst })
					end
					if self.onkilledbyother then
						self.onkilledbyother(self.inst, attacker)
					end
				end
			elseif not unblockable then
				blocked = true
			end
		end

		local redirect_combat = damageredirecttarget and damageredirecttarget.components.combat or nil
		if redirect_combat then
			redirect_combat:GetAttacked(attacker, damage, weapon, stimuli)
		end

		if self.inst.SoundEmitter and not self.inst:IsInLimbo() then
			local hitsound = self:GetImpactSound(damageredirecttarget or self.inst, weapon)
			if hitsound then
				self.inst.SoundEmitter:PlaySound(hitsound)
			end
			local hurtsound = damageredirecttarget and redirect_combat and redirect_combat.hurtsound or self.hurtsound
			if hurtsound then
				self.inst.SoundEmitter:PlaySound(hurtsound)
			end
		end

		if not blocked or self.inst.components.health:IsDead() then -- can't block if dead
			self.inst:PushEvent("attacked", {attacker = attacker, damage = damage, damageresolved = damageresolved, weapon = weapon, stimuli = stimuli, redirected = damageredirecttarget, noimpactsound = self.noimpactsound, projectile = projectile, true_damage = true_damage})

			if self.onhitfn then
				self.onhitfn(self.inst, attacker, damage)
			end

			if attacker then
				attacker:PushEvent("onhitother", { target = self.inst, damage = damage, damageresolved = damageresolved, stimuli = stimuli, weapon = weapon, redirected = damageredirecttarget, is_alt = is_alt, projectile = projectile })
				if attacker.components.combat and attacker.components.combat.onhitotherfn then
					attacker.components.combat.onhitotherfn(attacker, self.inst, damage, stimuli, projectile)
				end
			end
		else
			self.inst:PushEvent("blocked", { attacker = attacker, damage = damage, damageresolved = damageresolved, weapon = weapon, stimuli = stimuli, redirected = damageredirecttarget, noimpactsound = self.noimpactsound, projectile = projectile, true_damage = true_damage })
		end

		return not blocked
	end

	function self:DoSpecialAttack(dmg, target_override, stimuli, instancemult, aoe_data, damage_type) --Used for special attacks from players, like WX's shock attack
		self.damage_override = dmg --dmg can be a function or a number, as a function the arguments will be: attacker, target
		if aoe_data then --target_override and instancemult arguments do not get used if doing an aoe attack and valid aoe_data variables are target, range, validfn, and excludetags
			self:DoAreaAttack(aoe_data.target, aoe_data.range, nil, aoe_data.validfn, stimuli, aoe_data.excludetags)
		else
			self.ignorehitrange = true --Don't mind me, just slapping on a bandaid fix
			self:DoAttack(target_override, nil, nil, stimuli, instancemult, nil, nil, true, damage_type)
			self.ignorehitrange = false
		end
		self.damage_override = nil
	end

	-- Used for determining if a pet should keep attacking when a mob is in a heal
	self.last_player_attack = 0
	function self:UpdateLastPlayerAttack(attacker)
		if attacker and attacker:HasTag("player") then
			self.last_player_attack = _G.GetTime()
		end
	end
end)

------------
-- Weapon --
------------
--TODO: Maybe put altcondition in an OnUpdate check to automatically swap the weapon's alt state?
AddComponentPostInit("weapon", function(self)
	self.hasaltattack = false
	self.isaltattacking = false
	self.altattackrange = nil
	self.althitrange = nil
	self.altdamage = nil
	self.altdamagecalc = nil
	self.altcondition = nil
	self.altprojectile = nil
	self._projectile = nil --ZARKLORD: FIDOOOP YOU LITERALY POOPED OUR CODEBASE!!?!?!?! --"poop" -- Just in case. It'll be overided in SetProjectile
							--Fid: It was Cunning Fox actually... @n@
							--Fox: No u
							--Fid: Ok it was probably Chris
	self.damagetype = nil
	self.altdamagetype = nil
	self._damagetype = nil
	self.launch_pos_override_fn = nil
	self.sync_projectile = nil
	self.hit_weight = nil
	self.hit_weight_fn = nil

	function self:SetDamageType(damagetype)
		self.damagetype = damagetype
		self._damagetype = damagetype
	end

	function self:SetStimuli(stimuli)
		self.stimuli = stimuli
	end

	--Trying to fix invisible poj after using the AltAtk
	function self:SetProjectile(projectile)
		self.projectile = projectile
		self._projectile = projectile
	end

	function self:GetLaunchPositionOverride(attacker)
		return self.launch_pos_override_fn and self.launch_pos_override_fn(self.inst, attacker)
	end

	function self:SetLaunchPositionOverride(pos)
		self.launch_pos_override_fn = pos
	end

	function self:SyncProjectile(val)
		self.sync_projectile = val
	end

	function self:GetHitWeight()
		return self.hit_weight_fn and self.hit_weight_fn(self.inst) or self.hit_weight
	end

	function self:SetHitWeight(val)
		self.hit_weight = val
	end

	function self:SetHitWeightFN(fn)
		self.hit_weight_fn = fn
	end

	function self:SetAltAttack(damage, range, proj, damagetype, damagecalcfn, conditionfn) --Used to give weapons a 2nd attack
		self.hasaltattack = true
		self.altdamage = damage ~= nil and damage or self.damage
		if range ~= nil then
			self.altattackrange = (type(range) == "table" and range[1] or type(range) ~= "table" and range) or self.attackrange
			self.althitrange = type(range) == "table" and range[2] or self.altattackrange
		else
			--Uhmmmm.......... Is this healthy?
			self.altattackrange = 20
			self.althitrange = 20
		end
		self.base_alt_attack_range = self.altattackrange
		self.base_alt_hit_range = self.althitrange
		self.altprojectile = proj --Not required, only uses projectile and complexprojectile. An aimedprojectile alt needs to be used through something like aoespell
		self.altdamagetype = damagetype ~= nil and damagetype or self.damagetype --Used incase an alt attack is a different damagetype than the main attack
		self.altdamagecalc = damagecalcfn --Used for when the damage could turn out as a different value under a specific circumstance like with infernal staff (Will default to self.altdamage)
		self.altcondition = conditionfn --Used for telling the weapon when it should alt attack

		if self.altdamagecalc then
			local _olddamagecalc = self.altdamagecalc
			self.altdamagecalc = function(weapon, attacker, target)
				local dmg = _olddamagecalc(weapon, attacker, target)
				return dmg ~= nil and dmg or self.altdamage
			end
		end

		if self.inst.replica.inventoryitem then
			self.inst.replica.inventoryitem:SetAltAttackRange(self.altattackrange)
		end
	end

	function self:UpdateAltAttackRange(attack_range, hit_range, owner)
		local owner = owner or self.inst.components.inventoryitem and self.inst.components.inventoryitem.owner
		self.base_alt_attack_range = attack_range or self.base_alt_attack_range or 0
		self.base_alt_hit_range = hit_range or self.base_alt_hit_range or 0
		if owner and owner.components.scaler then
			local scale = owner.components.scaler.scale
			self.altattackrange = self.base_alt_attack_range * scale
			self.althitrange = self.base_alt_hit_range * scale
		else
			self.altattackrange = self.base_alt_attack_range
			self.althitrange = self.base_alt_hit_range
		end
		if self.inst.replica.inventoryitem then
			self.inst.replica.inventoryitem:SetAltAttackRange(self.altattackrange)
		end
	end

	function self:SetIsAltAttacking(alt, no_netvar)
		self.isaltattacking = alt
		if self.inst.replica.inventoryitem then--and not no_netvar then
			self.inst.replica.inventoryitem:SetIsAltAttacking(alt)
		end
		--*intense grumbling*
		if alt then
			self.projectile = self.altprojectile
			self.damagetype = self.altdamagetype
		else
			self.projectile = self._projectile
			self.damagetype = self._damagetype
		end
	end

	function self:HasAltAttack()
		return self.hasaltattack
	end

	function self:CanAltAttack()
		if self:HasAltAttack() and self.isaltattacking then
			return self.altcondition ~= nil and self.altcondition(self.inst) or true
		end
	end

	_oldCanRangedAttack = self.CanRangedAttack
	function self:CanRangedAttack()
		return self:CanAltAttack() and self.altprojectile or _oldCanRangedAttack(self)
	end

	function self:DoAltAttack(attacker, target_override, projectile, stimuli, instancemult, damage_override, damage_type) --Used to force an alt attack out for situations where the alt system is handled seperately like with aoespell
		self:SetIsAltAttacking(true, true)
		--Set setalt to true if the alt is a single attack or AOE attack.
		--If the alt hits rapidly though, leave it false and control SetIsAltAttacking before and after the rapid attacks all trigger (This way we avoid rapidly pushing a netbool)
		if attacker and attacker.components.combat and self:CanAltAttack() then
			if target_override and type(target_override) == "table" and not target_override.prefab then --You can pass a table of collected entities through the target_override argument to do an AOE attack
				for _,ent in ipairs(target_override) do
					if ent ~= attacker and attacker.components.combat:IsValidTarget(ent) and ent.components.health and not ent.components.health:IsDead() then
						--I'm deciding not to push this event since mob collection occurs before this function runs and
						--I don't want 2 events pushed for every attack
						--attacker:PushEvent("onareaattackother", { target = ent, weapon = self.inst, stimuli = stimuli }) --
						--DoAttack(target, weapon, projectile, stimuli, instancemult, damage_override, is_alt, is_special, damage_type)
						attacker.components.combat:DoAttack(ent, self.inst, projectile, stimuli, instancemult, damage_override, true, nil, damage_type)
					end
					--attacker:PushEvent("alt_attack_complete", {})
				end
			else
				if attacker.components.combat:IsValidTarget(target_override) then
					attacker.components.combat:DoAttack(target_override, self.inst, projectile, stimuli, instancemult, damage_override, true, nil, damage_type)
				end
			end
		end
		attacker:PushEvent("alt_attack_complete", {weapon = self.inst})
		self:SetIsAltAttacking(false, true)
	end

	-- Basically default function with the added damage parameter so that projectile damage is set on throw and not impact.
	function self:LaunchProjectile(attacker, target, damage)
		if self.projectile then
			if self.onprojectilelaunch then
				self.onprojectilelaunch(self.inst, attacker, target, damage)
			end

			local proj = _G.SpawnPrefab(self.projectile)
			if proj then
				if proj.components.projectile then
					proj.Transform:SetPosition(attacker.Transform:GetWorldPosition())
					proj.components.projectile:Throw(self.inst, target, attacker, damage)
					if self.inst.projectiledelay then
						proj.components.projectile:DelayVisibility(self.inst.projectiledelay)
					end
				elseif proj.components.complexprojectile then
					proj.Transform:SetPosition(attacker.Transform:GetWorldPosition())
					proj.components.complexprojectile:Launch(target:GetPosition(), attacker, self.inst, damage)
				end
				if self.onprojectilelaunched then
		            self.onprojectilelaunched(self.inst, attacker, target, proj)
		        end
			end
		end
	end
end)

----------------
-- Equippable --
----------------
AddComponentPostInit("equippable", function(self)
	self.uniquebuffs = {}
	self.damagebuffs = { dealt = {}, recieved = {} }

	function self:AddBuffsTo(owner)
		if owner then
			if owner.components.buffable then
				owner.components.buffable:AddBuff(self.inst.prefab, self.uniquebuffs)
			end
			if owner.components.combat then
				for buff,data in pairs(self.damagebuffs.dealt) do
					owner.components.combat:AddDamageBuff(buff, data)
				end
				for buff,data in pairs(self.damagebuffs.recieved) do
					owner.components.combat:AddDamageBuff(buff, data, true)
				end
			end
		end
	end

	function self:RemoveBuffsFrom(owner)
		if owner then
			if owner.components.buffable then
				owner.components.buffable:RemoveBuff(self.inst.prefab)
			end
			if owner.components.combat then
				for buff,data in pairs(self.damagebuffs.dealt) do
					owner.components.combat:RemoveDamageBuff(buff)
				end
				for buff,data in pairs(self.damagebuffs.recieved) do
					owner.components.combat:RemoveDamageBuff(buff, true)
				end
			end
		end
	end

	function self:AddUniqueBuff(data)
		for bufftype,buff in pairs(data) do
			self.uniquebuffs[bufftype] = buff
		end
		if self:IsEquipped() then
			local owner = self.inst.components.inventoryitem.owner
			if owner and owner.components.buffable then
				owner.components.buffable:AddBuff(self.inst.prefab, self.uniquebuffs)
			end
		end
	end

	function self:RemoveUniqueBuff(bufftype)
		self.uniquebuffs[bufftype] = nil
		if self:IsEquipped() then
			local owner = self.inst.components.inventoryitem.owner
			if owner and owner.components.buffable then
				owner.components.buffable:AddBuff(self.inst.prefab, self.uniquebuffs)
			end
		end
	end

	--All damagebuff related functions work exactly the same as in combat for sake of simplicity
	function self:HasDamageBuff(buffname, recieved)
		return self.damagebuffs[recieved and "recieved" or "dealt"][buffname] ~= nil
	end

	function self:AddDamageBuff(buffname, data, recieved, remove_old_buff)
		if remove_old_buff and self:HasDamageBuff(buffname, recieved) then
			self:RemoveDamageBuff(buffname, recieved)
		end
		if not self:HasDamageBuff(buffname, recieved) then
			local buff = type(data) == "number" and {buff = data} or data
			self.damagebuffs[recieved and "recieved" or "dealt"][buffname] = buff

			if self:IsEquipped() then
				local owner = self.inst.components.inventoryitem.owner
				if owner and owner.components.combat then
					owner.components.combat:AddDamageBuff(buffname, data, recieved)
				end
			end
		end
	end

	function self:RemoveDamageBuff(buffname, recieved)
		self.damagebuffs[recieved and "recieved" or "dealt"][buffname] = nil

		if self:IsEquipped() then
			local owner = self.inst.components.inventoryitem.owner
			if owner and owner.components.combat then
				owner.components.combat:RemoveDamageBuff(buffname, recieved)
			end
		end
	end

	local _oldequip = self.Equip
	function self:Equip(owner)
		self:AddBuffsTo(owner)
		_oldequip(self, owner)
	end

	local _oldunequip = self.Unequip
	function self:Unequip(owner)
		self:RemoveBuffsFrom(owner)
		_oldunequip(self, owner)
	end
end)

----------------------------
-- Inventory Item Replica --
----------------------------
AddClassPostConstruct("components/inventoryitem_replica", function(self)
	self.can_altattack_fn = function() return true end

	function self:SetIsAltAttacking(alt)
		self.classified.isaltattacking:set(alt)
	end

	function self:SetAltAttackRange(range)
		self.classified.altattackrange:set(range or self:AttackRange())
	end

	function self:AltAttackRange()
		if self.inst.components.weapon then
			return self.inst.components.weapon.altattackrange
		elseif self.classified ~= nil then
			return math.max(0, self.classified.altattackrange:value())
		else
			return self:AttackRange()
		end
	end

	function self:SetAltAttackCheck(fn)
		if fn and type(fn) == "function" then
			self.can_altattack_fn = fn
		end
	end

	function self:CanAltAttack()
		if self.classified.isaltattacking:value() then
			return self.inst.components.weapon and self.components.weapon:CanAltAttack() or self.can_altattack_fn(self.inst)
		end
	end

	_oldAttackRange = self.AttackRange
	function self:AttackRange()
		return self:CanAltAttack() and self:AltAttackRange() or _oldAttackRange(self)
	end
end)

--------------------
-- Combat Replica --
--------------------
local function OnNewTarget(inst)
	local target = inst.replica.combat:GetTarget()
	if inst.sg then
		inst.sg.statemem.attacktarget = target
	end
end
-- No more attacking your friends!
AddClassPostConstruct("components/combat_replica", function(self)
	self._target_test = _G.net_entity(self.inst.GUID, "combat._target_test", "_new_target")
	if not _G.TheNet:IsDedicated() then
		self.inst:ListenForEvent("_new_target", OnNewTarget)
	end

    local _oldCanBeAttacked = self.CanBeAttacked
    function self:CanBeAttacked(attacker)
        if self.inst:HasTag("companion") and not self.inst:HasTag("LAmob") and attacker and attacker:HasTag("player") then
            return false
        end
        return _oldCanBeAttacked(self, attacker)
    end

    local _oldSetTarget = self.SetTarget
    function self:SetTarget(target)
    	_oldSetTarget(self, target)
    	self._target_test:set(target)
    end
end)

-----------------
-- Projectiles --
-----------------
-- Adds aimed throws to the projectile component
AddComponentPostInit("projectile", function(self)
	self.aimed_throw = false
	self.dropped = false
	self.melee_weapon = false
	self.damage = nil -- used to set projectile damage on throw and not impact
	self.is_piercing = false
	self.pierce_limit = 0
	self.pierce_count = 0
	self.no_pierce_limit = false
	self.hit_targets = {}
	self.onpierce_all = nil
	self.does_damage = true
	self.stimuli = nil
	self.damage_type = _G.TUNING.FORGE.DAMAGETYPES.PHYSICAL

	-- Setting this to true means the projectile can only be used for aimed throws and that its basic attack is a melee attack.
	function self:SetMeleeWeapon(melee_weapon)
		self.melee_weapon = melee_weapon
	end

	function self:SetDamageType(damage_type)
		self.damage_type = damage_type or self.damage_type
	end

	local old_SetLaunchOffset = self.SetLaunchOffset
	function self:SetLaunchOffset(offset)
		self.launchoffset = offset -- x is radius, y is height, z is ignored
		self.base_launch_offset = offset
	end

	function self:UpdateLaunchOffset()
		if self.base_launch_offset then
			local scale = self.attacker.components.scaler and self.attacker.components.scaler.scale or 1
			self.launchoffset = self.base_launch_offset * scale
		end
	end

	local old_Throw = self.Throw
	function self:Throw(owner, target, attacker, damage, is_alt)
		self.attacker = attacker or owner -- default projectile component sets their attacker to owner
		self.inst:SetSource(self.attacker)
		self.damage = damage
		self.is_alt = is_alt
		self.start_pos = owner:GetPosition()
		self.last_position = self.start_pos
		self:UpdateLaunchOffset()
		old_Throw(self, owner, target, attacker)
	end

	function self:AimedThrow(owner, attacker, target_pos, damage, is_alt)
		self.owner = owner
		self.attacker = attacker or owner
		self.inst:SetSource(self.attacker)
		self.damage = damage
		self.is_alt = is_alt
		self.start = owner:GetPosition()
		self.start_pos = owner:GetPosition()
		self.last_position = self.start_pos
		self.dest = target_pos
		self.aimed_throw = true

		if attacker and self.launchoffset then
			self:UpdateLaunchOffset()
			local x, y, z = self.inst.Transform:GetWorldPosition()
			local facing_angle = attacker.Transform:GetRotation() * _G.DEGREES
			self.inst.Transform:SetPosition(x + self.launchoffset.x * math.cos(facing_angle), y + self.launchoffset.y, z - self.launchoffset.x * math.sin(facing_angle))
		end

		self:RotateToTarget(self.dest)
		self.inst.Physics:SetMotorVel(self.speed, 0, 0)
		self.inst:StartUpdatingComponent(self)
		self.inst:PushEvent("onthrown", { thrower = attacker })
		if self.onthrown then
			self.onthrown(self.inst, attacker, target_pos)
		end
	end

	function self:Drop(owner, attacker, damage, is_alt, life_fn)
		self.owner = owner
		self.attacker = attacker or owner
		self.inst:SetSource(self.attacker)
		self.damage = damage
		self.is_alt = is_alt
		self.life_fn = life_fn
		self.start = owner:GetPosition()
		self.start_pos = owner:GetPosition()
		self.last_position = self.start_pos
		self.dropped = true

		self.inst:StartUpdatingComponent(self)
		self.inst:PushEvent("onthrown", { thrower = attacker })
		if self.onthrown then
			self.onthrown(self.inst, attacker)
		end
	end

	-- Copied from projectile
	local function StopTrackingDelayOwner(self)
		if self.delayowner ~= nil then
			self.inst:RemoveEventCallback("onremove", self._ondelaycancel, self.delayowner)
			self.inst:RemoveEventCallback("newstate", self._ondelaycancel, self.delayowner)
			self.delayowner = nil
		end
	end

	function self:Miss(target)
		StopTrackingDelayOwner(self)
		if self.onmiss then
			self.onmiss(self.inst, self.attacker, target)
		end
		self:Stop()
	end

	function self:HitTarget(target)
		if self.does_damage then
			if self.aimed_throw and self.attacker and self.owner and self.owner.components.weapon then
				self.owner.aimed_projectile_hit = true
				--self.owner.components.weapon:DoAltAttack(self.attacker, target, self.inst, self.stimuli, nil, self.damage)
				if self.attacker:IsValid() then
					self.attacker.components.combat:DoAttack(target, self.owner, self.inst, self.stimuli, nil, self.damage, self.is_alt, nil, self.damage_type)
				-- Attack Target directly if projectile hit a target after its owner is removed.
				else
					target.components.combat:GetAttacked(self.attacker, self.damage, weapon, self.stimuli, self.is_alt, self.inst, self.damage_type)
				end
			elseif self.attacker and self.attacker.components.combat and not self.hit_targets[target] then
				local weapon = self.owner.components.weapon and self.owner or self.inst
				if self.attacker:IsValid() then
					self.attacker.components.combat:DoAttack(target, weapon, self.inst, self.stimuli, nil, self.damage, self.is_alt, nil, self.damage_type)
				-- Attack Target directly if projectile hit a target after its owner is removed.
				else
					target.components.combat:GetAttacked(self.attacker, self.damage, weapon ~= nil and weapon:IsValid() and weapon, self.stimuli, self.is_alt, self.inst, self.damage_type)
				end
			end
		end
		if self.onhit then
			self.onhit(self.inst, self.attacker, target)
		end
	end

	local old_Hit = self.Hit
	function self:Hit(target)
		if not (target.components.combat and target.components.combat.dodge_fn and target.components.combat.dodge_fn(target, self.attacker, self.owner, self.inst, self.damage, self.stimuli, self.damage_type)) then
			self.pierce_count = self.pierce_count + 1
			self:HitTarget(target)
			if not (self.is_piercing and (self.no_pierce_limit or self.pierce_count < self.pierce_limit)) then
				StopTrackingDelayOwner(self)
				self.inst.Physics:Stop()
				self:Stop()
				if self.is_piercing then
					if self.onpierce_all then
						self.onpierce_all(self.inst)
					else
						self.inst:Remove()
					end
				end
			end
		-- If target dodged and projectile is homing, change it to an aimed throw so that it continues to travel to max distance or until a different valid target gets hit.
		elseif target == self.target and self.homing then
			self.homing = false
			self.aimed_throw = true
		end
	end

	local old_Stop = self.Stop
	function self:Stop()
		old_Stop(self)
		self.attacker = nil
		self.damage = nil
		self.aimed_throw = false
		self.dropped = false
		self.life_fn = nil
	end

	local function CheckForTargets(self, inst, check_walls)
		local current_pos = self.inst:GetPosition()
		current_pos.y = 0
		-- Get valid targets near the projectile
		local valid_targets = {}
		local target = nil
		local x, y, z = current_pos:Get()
		local ents = TheSim:FindEntities(x, y, z, 3, check_walls and {"wall"}, _G.COMMON_FNS.CommonExcludeTags(self.attacker)) -- TODO check hit radius throughout this function
		for _,ent in ipairs(ents) do
			-- The owner/attacker is not a valid target.
			if ent.entity:IsValid() and ent.entity:IsVisible() and ent.components.health and not ent.components.health:IsDead() and not (ent == self.attacker or ent == self.owner) and ent.components.combat then
				local hit_range = ent:GetPhysicsRadius(0) + self.hitdist
				local current_range = _G.distsq(current_pos, ent:GetPosition())
				if hit_range > current_range then
					table.insert(valid_targets, {target = ent, hit_range = hit_range, current_range = current_range})
				end
			end
		end
		-- Check if any valid target is within hit range? TODO check this
		for _,data in pairs(valid_targets) do
			if not target or data.current_range - data.hit_range < target.range then
				target = {ent = data.target, range = data.current_range - data.hit_range}
				break
			end
		end
		if target then -- TODO can't we call this inside that for loop and return?
			--print("Hit Target: " .. tostring(target.ent))
			if target.ent then
				if target.ent.OnProjectileHit then
					target.ent.OnProjectileHit(inst) -- Custom projectile hit for wall
				else
					self:Hit(target.ent)
				end
			end
		end
	end

	self.distance_traveled = 0
	local old_OnUpdate = self.OnUpdate
	function self:OnUpdate(dt)
		if self.aimed_throw or self.dropped then
			local current_pos = self.inst:GetPosition()
			current_pos.y = 0
			-- Check if max range has been reached
			if self.aimed_throw and self.range and _G.distsq(self.start, current_pos) > self.range * self.range or self.dropped and self.life_fn and self.life_fn(self.inst) then
				self:Miss()
			else
				CheckForTargets(self, inst)
			end
		else
		    -- Update distance traveled
		    if self.range ~= nil then
		        self.distance_traveled = (self.distance_traveled or 0) + math.sqrt(_G.distsq(self.last_position, self.inst:GetPosition()))
		        self.last_position = self.inst:GetPosition()
		        -- Updating the start position so the original OnUpdate does not need to manually overwritten.
		        self.start = self.last_position + _G.Vector3(1,0,0) * self.distance_traveled
		    end
			old_OnUpdate(self, dt)
			if self.attacker then
				CheckForTargets(self, inst, true)
			end
		end
	end
end)

-- Adds damage parameters
AddComponentPostInit("complexprojectile", function(self)
	self.sync_projectile = true

	function self:SyncProjectile(val)
		self.sync_projectile = true
		if self.sync_projectile then
			self.inst.replica.complexprojectile:SetGravity(self.gravity)
			self.inst.replica.complexprojectile:SetHorizontalSpeed(self.horizontalSpeed)
			self.inst.replica.complexprojectile:SetHighArc(self.usehigharc)
		end
	end

	self.base_gravity = self.gravity
	local old_SetGravity = self.SetGravity
	function self:SetGravity(gravity)
	    self.gravity = gravity
	    self.base_gravity = gravity
	end

	local old_SetLaunchOffset = self.SetLaunchOffset
	function self:SetLaunchOffset(offset)
		self.launchoffset = offset -- x is radius, y is height, z is ignored
		self.base_launch_offset = offset
	end

	function self:UpdateLaunchInfo()
		local scale = self.attacker.components.scaler and self.attacker.components.scaler.scale or 1
		self.gravity = self.base_gravity / scale
		if self.base_launch_offset then
			self.launchoffset = self.base_launch_offset * scale
		end
	end

	local _oldLaunch = self.Launch
	function self:Launch(target_pos, attacker, weapon, damage, is_alt)
		self.inst:SetSource(attacker)
		self.attacker = attacker
		self:UpdateLaunchInfo()
	    _oldLaunch(self, target_pos, attacker, weapon)
	    self.gravity = self.base_gravity
	    self.damage = damage
		self.is_alt = is_alt

	    -- Display a client only projectile for visual purposes
	    if self.sync_projectile and attacker and attacker.GetClientProjectilePosition then
	    	self:SyncProjectile(weapon and weapon.components.weapon:SyncProjectile())
		    self.inst:Hide()
			self.inst.replica.complexprojectile:SetAttacker(attacker)
			self.inst.replica.complexprojectile:SetTargetPosX(target_pos.x)
			self.inst.replica.complexprojectile:SetTargetPosY(target_pos.y)
			self.inst.replica.complexprojectile:SetTargetPosZ(target_pos.z)
		    self.inst.replica.complexprojectile:SetOnLaunch(true)
		end
	end

	local _oldHit = self.Hit
	function self:Hit(target)
		self.inst:StopUpdatingComponent(self)

		self.inst.Physics:SetMotorVel(0,0,0)
		self.inst.Physics:Stop()
		self.velocity.x, self.velocity.y, self.velocity.z = 0, 0, 0

		if self.onhitfn then
			self.onhitfn(self.inst, self.attacker, target, self.owningweapon, self.damage, self.is_alt)
		end
	end
end)
