MeleeRangeSwap = Class(BehaviourNode, function(self, inst, swap_range, weapon, weapon_attack_range, weapon_hit_range, melee_attack_range, melee_hit_range, melee_attack_period)
    BehaviourNode._ctor(self, "MeleeRangeSwap")
    self.inst = inst
	self.weapon = weapon
	self.weapon_attack_range = weapon_attack_range or 5
	self.weapon_hit_range = weapon_hit_range or weapon_attack_range
	self.weapon_attack_period = weapon and weapon.attack_period
	self.swap_range = swap_range
	self.melee_attack_range = melee_attack_range or 2
	self.melee_hit_range = melee_hit_range or melee_attack_range or 3
	self.melee_attack_period = melee_attack_period or 3
end)

function MeleeRangeSwap:__tostring()
    return string.format("current mode: %s", self.weapon and self.weapon.components.equippable:IsEquipped() and "Ranged" or "Melee")
end

function MeleeRangeSwap:ShouldSwapWeapons()
	local is_equipped = self.weapon.components.equippable:IsEquipped()
	local current_target = self.inst.components.combat.target
	if current_target and not self.inst.sg:HasStateTag("attack") and self.inst:IsValid() and current_target:IsValid() then
		local within_melee_range = self.inst:IsNear(current_target, self.swap_range)
		return is_equipped == within_melee_range
	end
	return false
end

function MeleeRangeSwap:Swap()
	if self.weapon.components.equippable:IsEquipped() then
		self.inst.components.inventory:Unequip(EQUIPSLOTS.HANDS)
		self.inst.components.combat:SetRange(self.melee_attack_range, self.melee_hit_range)
		self.inst.components.combat:SetAttackPeriod(self.melee_attack_period)
	else
		self.inst.components.combat:SetRange(self.weapon_attack_range, self.weapon_hit_range)
		self.inst.components.inventory:Equip(self.weapon)
		self.inst.components.combat:SetAttackPeriod(self.weapon_attack_period or self.melee_attack_period)
	end
end

function MeleeRangeSwap:Visit()
    if self.status == READY then
        if self:ShouldSwapWeapons() then
            self.status = RUNNING
        elseif not self.inst.components.combat.target then
            self.status = FAILED
        end
    end

    if self.status == RUNNING then
		if self:Swap() then
			self.status = self.SUCCESS
		else
			self.status = FAILED
		end
    end
end
