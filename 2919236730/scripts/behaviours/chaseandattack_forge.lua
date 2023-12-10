ChaseAndAttack_Forge = Class(BehaviourNode, function(self, inst, max_chase_time, findavoidanceobjectsfn, avoid_dist)
    BehaviourNode._ctor(self, "ChaseAndAttack_Forge") -- TODO rename to ChaseAndAttackAndAvoid_Forge??? or something else?
    self.inst = inst
    self.max_chase_time = max_chase_time or 8
	self.damage_taken = 0
    self.damage_needed = 150 -- to keep agro
	self.findavoidanceobjectsfn = findavoidanceobjectsfn
	self.avoid_dist_sq = avoid_dist and (avoid_dist * avoid_dist) or 0
	self.avoid_buffer_dist_sq = self.inst:GetPhysicsRadius(0) * self.inst:GetPhysicsRadius(0) + 10 -- 10 was used because the mobs radius was not enough, if the avoiding function becomes smart enough not to rely on a buffer zone then this will not be needed.
	self.avoid_targets = {}

    -- we need to store this function as a key to use to remove itself later
    self.onattackedfn = function(inst, data) self:OnAttacked(data.attacker, data.damage, data.stimuli) end
    self.onattackotherfn = function(inst, data) self:OnAttackOther(data) end
    self.onnewtargetfn = function(inst, data) self:OnNewTarget() end
	self.forceaggrofn = function(inst, data) self:ForceAggro(data.target, data.aggro_reset_time) end

	self.inst:ListenForEvent("attacked", self.onattackedfn)
    self.inst:ListenForEvent("onattackother", self.onattackotherfn)
	self.inst:ListenForEvent("onareaattackother", self.onattackotherfn)
    self.inst:ListenForEvent("newcombattarget", self.onnewtargetfn)
	self.inst:ListenForEvent("forceaggro", self.forceaggrofn)
end)

function ChaseAndAttack_Forge:__tostring()
    return string.format("target %s, avoiding %s", tostring(self.inst.components.combat.target), tostring(self.avoid_targets))
end

function ChaseAndAttack_Forge:OnStop()
    self.inst:RemoveEventCallback("attacked", self.onattackedfn)
    self.inst:RemoveEventCallback("onattackother", self.onattackotherfn)
	self.inst:RemoveEventCallback("onareaattackother", self.onattackotherfn)
	self.inst:RemoveEventCallback("forceaggro", self.forceaggrofn)
end

-- this should handle agro when kiting mobs around
function ChaseAndAttack_Forge:OnAttacked(attacker, damage, stimuli)
    --if not attacker or not damage then return end
	if attacker == self.inst.components.combat.target then
		self.damage_taken = self.damage_taken + damage
        local damage_needed = self.damage_needed
		if attacker.components.buffable then
			damage_needed = attacker.components.buffable:ApplyStatBuffs({"aggro_gain"}, damage_needed)
		end
        -- reset chase time if target has done enough damage
		if self.damage_taken > damage_needed then
			self.damage_taken = 0
			self.startruntime = GetTime()
		end
    else
        self.damage_taken = 0
	end
end

-- this resets the chase time when the mob lands a hit
function ChaseAndAttack_Forge:OnAttackOther(data)
	if data.target == self.inst.components.combat.target and not data.no_aggro then
		self.startruntime = GetTime()
	end
end

-- Reset current chase if aggro goes to a new target
function ChaseAndAttack_Forge:OnNewTarget()
    self.damage_taken = 0
    self.startruntime = GetTime()
end

-- this resets the chase time when forced to change target
function ChaseAndAttack_Forge:ForceAggro(target, aggro_reset_time)
    if self.inst.components.combat.has_forced_target then return end
	self.damage_taken = 0
	self.startruntime = GetTime()
    self.inst.components.combat:SetTarget(target)
    self.inst.forced_aggro_reset_time = GetTime() + (aggro_reset_time or 0)
end

function ChaseAndAttack_Forge:Visit()
    local combat = self.inst.components.combat
    if self.status == READY then
        combat:ValidateTarget()

        if combat.target then
			self.inst.components.combat:BattleCry()
            self.startruntime = GetTime()
            self.status = RUNNING
        else
            self.status = FAILED
        end
    end

	if self.findavoidanceobjectsfn ~= nil then
		self.avoid_targets = self.findavoidanceobjectsfn(self.inst) or {}
	end

    if self.status == RUNNING then
		if combat.nextbattlecrytime == nil or GetTime() > combat.nextbattlecrytime then --TODO: might be random, not set, still investigating
            --self.inst.components.combat:BattleCry() -- TODO this if statement is inside this function lol, need to figure out condition for battle cries, should it be a parameter? do mobs have similar battle cry timing as in they all refer to a period? or after a specific attack or number of attacks or being hit by a stun or forced hit or target change or target loss???
			-- TODO might be simple actually, croc seems to have a 5 second taunt period and inside combat the default battlecry period is 5 with a random variance of 0 to 3. So what if each mob just has a battlecryinterval? In BattleCry if the mob is in a busy state then it will not go to taunt BUT the cooldown is reset, so it essentially skips that taunt. If this is the case then we just need to figure out where to call BattleCry!
        end

        if not combat.target or not combat.target.entity:IsValid() then
            self.status = FAILED
            combat:SetTarget(nil)
            self.inst.components.locomotor:Stop()
        elseif combat.target.components.health and combat.target.components.health:IsDead() then
            self.status = SUCCESS
            combat:SetTarget(nil)
            self.inst.components.locomotor:Stop()
        else
            local target_pos = combat.target:GetPosition()
			local current_pos = self.inst:GetPosition()
            local distance_to_target_sq = distsq(target_pos, self.inst:GetPosition())
            local range = self.inst:GetPhysicsRadius(0) + combat.target:GetPhysicsRadius(1) + 1
            local running = self.inst.components.locomotor:WantsToRun()

			local ignore_avoided_objects = false
			local potential_pos = nil
			local pos_updated = false
			local moving = true
			-- Update next target position based on any active avoid objects
			for _,avoid_target in pairs(self.avoid_targets) do -- TODO would like to make this more dynamic and update next position based on healing circles location without the use of a buffer zone. This is also not perfected yet, sometime Boarrior will still walk into a heal when more than one heal is up, not always but sometimes. Possibly might be because the order of the healing circles is not based on distance to target so the further one goes first and he is outside the buffer zone of that one so it does not affect him BUT the next one he is inside the buffer zone so it updates position which happens to be the in the first healing circle checked. In other words we need to make sure the avoid_targets given are in sorted order by distance to Boarrior.
				if avoid_target:IsValid() and not ignore_avoided_objects and moving then
					local avoid_point = avoid_target:GetPosition()
					local distance_to_avoided_object_sq = distsq(avoid_point, current_pos)
					local delta_dir = anglediff(self.inst:GetAngleToPoint(target_pos), self.inst:GetAngleToPoint(avoid_point))
					-- Ignore avoided objects if already within avoid distance
					if distance_to_avoided_object_sq <= self.avoid_dist_sq then
						ignore_avoided_objects = true
					-- Don't move if the potential position is inside another avoided object
					elseif potential_pos and distsq(avoid_point, potential_pos) <= self.avoid_dist_sq then
						moving = false
					-- TODO is 90 correct? is it less? it is the maximum angle difference between the avoid circle and the target, 45 was used in kleis but that will make the mob cut corners
					-- Calculate potential position if within avoid buffer zone (avoid distance to avoid distance + mobs radius) and the path to the target is through the avoided object and no potential position has been calculated yet.
					elseif not pos_updated and delta_dir < 90 and distance_to_avoided_object_sq <= (self.avoid_dist_sq + self.avoid_buffer_dist_sq) then
						-- TODO if abs angle diff is less than 1 and target is closer don't move, prevents the constant flip flopping that occurs???
						if math.abs(delta_dir) > 1 then
							local offset = (avoid_point - current_pos):GetNormalized()
							if delta_dir > 0 then
								offset.x, offset.z = offset.z, -offset.x
							else
								offset.x, offset.z = -offset.z, offset.x
							end
							potential_pos = current_pos + offset
							pos_updated = true
						else
							moving = false
						end
					end
				end
			end
			-- Update target position if not currently within avoid distance
			if potential_pos and not ignore_avoided_objects then
				target_pos = potential_pos
			end

			if not self.inst.sg:HasStateTag("keepmoving") and moving then -- TODO change tag "keepmoving" to "ignoremovement"??? since it applies to rolling boarillas and lunging pitpigs, lunging pitpigs don't really "keep" moving
				if (running and distance_to_target_sq > range * range) or (not running and distance_to_target_sq > combat:CalcAttackRangeSq()) then
					self.inst.components.locomotor:GoToPoint(target_pos, nil, true)
				elseif not (self.inst.sg and self.inst.sg:HasStateTag("keepmoving")) then -- TODO this can become an else?
					self.inst.components.locomotor:Stop()
					if self.inst.sg:HasStateTag("canrotate") then
						self.inst:FacePoint(target_pos)
					end
				end
			end
            if not combat:TryAttack() and not self.inst.sg:HasStateTag("moving") then -- TODO "not moving" instead?
				self.inst.components.combat:BattleCry() -- TODO allow taunts during movement? need to find vid of this, seems like they never taunt when moving, also all mobs might have 5 seconds for their interval,
			end

            local max_chase_time = self.max_chase_time
			if combat.target.components.buffable then
				max_chase_time = combat.target.components.buffable:ApplyStatBuffs({"aggro_timer"}, max_chase_time)
			end
            if self.max_chase_time and self.startruntime and GetTime() - self.startruntime > max_chase_time then -- TODO possibly need check for only 1 target because if dropped the mob will stop moving for a second, but if there is only one target there shouldn't be any drop in target.
                self.status = FAILED
                self.inst.components.combat:GiveUp()
				if not (self.inst.sg and self.inst.sg:HasStateTag("keepmoving")) then -- Create a common function for locomotor:Stop so that it will always check the keepmoving tag and whatnot.
					self.inst.components.locomotor:Stop()
				end
                return
            end

            self:Sleep(.125)
        end
    end
end
