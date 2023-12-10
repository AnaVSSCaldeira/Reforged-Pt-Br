
--[[ Common targeting functions for mobs in the Forge ]]--

local TARGETING_RANGE = 50
local MAX_RANGE = 1200

local function CanTarget(target, mob)
    -- this checks for notarget tag, isvalid, isvisible, is not dead etc
    return mob.components.combat:CanTarget(target) and not COMMON_FNS.IsAlly(mob, target)
end

local function GetLeader(mob)
    return mob.components.follower and mob.components.follower.leader
end

-- Returns the closest target to the given mob
-- exclude_target will only return the exclude target if all other targets are dead
local function FindClosestTarget(mob, targets, exclude_target, pos_override)
    local closest = {target = false, distsq = MAX_RANGE, exclude_target = false, exclude_target_distsq = MAX_RANGE}
    local mob_pos = pos_override or mob:GetPosition()
	local target_exclude_tags = COMMON_FNS.CommonExcludeTags(mob)
	table.insert(target_exclude_tags, "companion") --companions are lower priority, so they aren't targeted. TODO add generic tag for this?
	local tar_table = targets or TheSim:FindEntities(mob_pos.x, 0, mob_pos.z, TARGETING_RANGE, {"_combat"}, target_exclude_tags)
    local function CompareClosest(target, dist_index, target_index)
        local curdistsq = distsq(mob_pos, target:GetPosition())
        if curdistsq < closest[dist_index] then
            closest[dist_index] = curdistsq
            closest[target_index] = target
        end
    end
    for _,target in pairs(tar_table) do
        if CanTarget(target, mob) then
            if target == exclude_target then
                CompareClosest(target, "exclude_target_distsq", "exclude_target")
            else
                CompareClosest(target, "distsq", "target")
            end
        end
    end
    return closest.target or closest.exclude_target or nil, math.sqrt(closest.distsq or closest.exclude_target_distsq)
end

local function FindClosestTargetInRange(mob, targets, range, exclude_target)
    local target, dist = FindClosestTarget(mob, targets, exclude_target)
    return dist <= (range or TARGETING_RANGE) and target
end

-- called when a target dies, by SetTarget(nil), and when a mob gives up on a target
-- PushEvent("droppedtarget", {target=oldtarget})
-- calling EngageTarget since SetTarget does the same but tries to call DropTarget again
-- if the target dropped was bernie then target bernies leader
local function OnDroppedTarget(mob, data)
    mob.components.combat:EngageTarget(data.target.prefab == "lavaarena_bernie" and data.target.components.follower.leader or FindClosestTarget(mob, nil, mob.giveuptarget))
end

-- self.inst:ListenForEvent("giveuptarget", OnGiveUp)
-- called by ChaseAndAttack_Forge after chasing and failing to hit a target after 8 seconds
-- PushEvent("giveuptarget", { target = self.target })
local function OnGiveUp(mob, data)
    mob.giveuptarget = data.target
end

-- called by EngageTarget which is called by SetTarget
-- PushEvent("newcombattarget", {target=target, oldtarget=oldtarget})
-- DoTaskInTime to prevent easily regaining aggro once lost
local function OnNewTarget(mob, data)
    mob.components.combat.last_attacked_by_target = GetTime() -- reset last attacked time on new target
    mob:DoTaskInTime(4, function() mob.giveuptarget = nil end) -- TODO tuning
end

-- called by a periodic task set for 2? seconds by all mobs
-- calls TryRetarget if the 2nd value returns true, or it doesn't have a current target
-- since we don't return any values, this just ensures a mob has a target on spawn and every 2 seconds after
local function RetargetFn(mob)
    if not mob.components.combat.target and not GetLeader(mob) then
        mob.components.combat:EngageTarget(FindClosestTarget(mob))
	elseif GetLeader(mob) and mob.components.follower.leader.components.combat.target then
		mob.components.combat:SetTarget(mob.components.follower.leader.components.combat.target)
    end
end

-- called OnUpdate once every second unless combat.keeptargettimeout is increased elsewhere
-- the OnUpdate calls DropTarget and pushes event "losttarget" if this and combat:CanBeAttacked returns false
-- might not be needed since ChaseAndAttack_Forge ensures the target is alive
local function KeepTarget(mob, target)
    local tags = COMMON_FNS.CommonExcludeTags(mob)
	local keep = true
	if target then
		for i, v in ipairs(tags) do
			if target:HasTag(v) then
				keep = false
			end
		end
	end
    return keep
end

local MIN_LAST_PLAYER_ATTACK_TIME_IN_CC = 0.5
local function PetIsValidTarget(inst, target)
    return inst.components.combat:CanTarget(target) and
	not (target.sg and (target.sg:HasStateTag("sleeping") or target.sg:HasStateTag("fossilized"))) and -- Don't attack targets in cc
	(target:HasTag("_isinheals") and (GetTime() - target.components.combat.last_player_attack < MIN_LAST_PLAYER_ATTACK_TIME_IN_CC) or not target:HasTag("_isinheals")) -- Stop attacking targets in heal if players have not attacked target recently
end

local forced_aggro_stimuli = {
    electric = TUNING.FORGE.AGGROTIMER_STUN
}

local function PetRetargetFn(inst, target)
    local leader = inst.components.follower.leader
    return leader and not leader.components.health:IsDead() and leader.components.combat.target or nil
end

local function PetKeepTarget(inst, target)
    return PetIsValidTarget(inst, target) and
    not (inst.components.follower.leader and inst.components.follower.leader.components.combat.target and inst.components.follower.leader.components.combat.target ~= target) -- Only keep leaders target
end

local function PetSentryRetargetFn(inst, target)
    return FindEntity(inst, inst.components.combat:GetAttackRange(), function(target)
        return PetIsValidTarget(inst, target)
    end, nil, { "player", "companion" }, {"monster", "hostile", "LA_mob"})
end

local function PetSentryKeepTarget(inst, target)
    return PetIsValidTarget(inst, target) and inst:IsNear(target, inst.components.combat:GetAttackRange())
end
--attacker = {
--    wolfgang = function(data)
--        return data.attacker:HasTag("heavybody") and 1
--    end
--}

-- Forces the mob to target the given target.
local function ForceAggro(mob, target, aggro_reset_time) -- TODO should there be a check for forced_aggro_reset_time or does force aggro ignore other forced aggro hits? as in target shouldn't change on a lucy throw for 1 second (or whatever it is set to) so would another lucy throw immediately override it or would it just be ignored during this 1 second period?
    if target and mob and mob.components.combat then
        --mob.components.combat:SetTarget(target) -- TODO moved these 2 lines to chase and attack to where the event is listened to, remove if that works better else revert back to this.
        --mob.forced_aggro_reset_time = GetTime() + (forced_aggro_reset_time or 0)
        mob:PushEvent("forceaggro", {target = target, aggro_reset_time = aggro_reset_time})
    end
end

local attack_buffer = 2
-- PushEvent("attacked", { attacker = attacker, damage = damage, damageresolved = damageresolved, weapon = weapon, stimuli = stimuli, redirected = damageredirecttarget, noimpactsound = self.noimpactsound })
local function OnAttacked(mob, data)
    local attacker = data.attacker
    local combat = mob.components.combat
    local current_time = GetTime()
    combat.last_attacked_by_target = attacker == combat.target and current_time or combat.last_attacked_by_target or 0
    if attacker == combat.target or not CanTarget(attacker, mob) or GetLeader(mob) then return end --if attacker is already the target or mob has a leader
    local forced_aggro_time = forced_aggro_stimuli[data.stimuli]
    if forced_aggro_time then
        ForceAggro(mob, attacker, forced_aggro_time)
        return
    end -- less aggro attacker needs the mob to not have attacked anyone for twice as long to pull aggro
    local normal_aggro_time = combat.min_attack_period-- * 2
	if attacker.components.buffable then
		normal_aggro_time = attacker.components.buffable:ApplyStatBuffs({"aggro_gain"}, normal_aggro_time)
	end
	--if combat.lastwasattackedtime and mob.forced_aggro_reset_time then -- TODO Removed this. I believe this was needed prior to all mobs using the init function below which sets this up. Leaving here just in case it is in fact needed
		if combat.lastwasattackedtime > mob.forced_aggro_reset_time --if not on a forced aggro timer
		and (current_time - math.max(combat.laststartattacktime or 0, combat.lastdoattacktime or 0) > normal_aggro_time * 2 --it has been more than normal_aggro_time * 2 since landing an attack on target or starting an attack on a target (just in case the attack is interrupted) -- TODO *2 is a bit hacky right now, not sure of what else to do, maybe every mob has the same value? this is mainly here for swine
        or (current_time - combat.last_attacked_by_target > normal_aggro_time and combat.target and distsq(mob:GetPosition(), attacker:GetPosition()) < distsq(mob:GetPosition(), combat.target:GetPosition()))) --it has been more than normal_aggro_time since the target hit the mob and the attacker is closer
        --[[
        TODO
            if croc spitting at a target and hitting the target
            woodie chops croc
            croc is not changing aggro
            if mob gets hit and the mob has not been attacked by their target switch if attacker is closer than target?
        --]]
		and (not mob.giveuptarget or attacker ~= mob.giveuptarget) then --and attacker isn't a recent giveuptarget
			combat:SetTarget(attacker)
            combat.last_attacked_by_target = current_time
		end
	--end
    --[[
    print("ON ATTACKED:")
    print(" - Forced Aggro Time: " .. tostring(forced_aggro_time))
    print(" - lastwasattackedtime > forced_aggro_reset_time? " .. tostring(combat.lastwasattackedtime > mob.forced_aggro_reset_time))
    print(" - - Last Attacked: " .. tostring(combat.lastwasattackedtime))
    print(" - - Forced Aggro Reset Time: " .. tostring(mob.forced_aggro_reset_time))
    print(" - current_time - lastdoattacktime > normal_aggro_time? " .. tostring(current_time - combat.lastdoattacktime > normal_aggro_time))
    print(" - - Current Time: " .. tostring(current_time))
    print(" - - Last Attack Time: " .. tostring(combat.lastdoattacktime))
    print(" - - Last Attacked by Target Time: " .. tostring(combat.last_attacked_by_target))
    print(" - - normal_aggro_time: " .. tostring(normal_aggro_time))
    print(" - not giveuptarget or attacker ~= giveuptarget? " .. tostring(not mob.giveuptarget or attacker ~= mob.giveuptarget))
    print(" - - GiveUpTarget: " .. tostring(mob.giveuptarget))
    print(" - - Attacker: " .. tostring(attacker))--]]
end

-- PushEvent("onattackother", { target = targ, weapon = weapon, projectile = projectile, stimuli = stimuli })
local function OnAttackOther(mob, data)
    -- can be used by crocs to share their target to pigs?
end

local function Init(mob)
    mob.components.combat:SetKeepTargetFunction(KeepTarget)
    mob.components.combat:SetRetargetFunction(2, RetargetFn)
    mob:ListenForEvent("attacked", OnAttacked)
	mob:ListenForEvent("droppedtarget", OnDroppedTarget)
    mob:ListenForEvent("giveuptarget", OnGiveUp)
	mob:ListenForEvent("newcombattarget", OnNewTarget)
	mob.components.combat.lastdoattacktime = 0
	mob.forced_aggro_reset_time = 0
    mob:DoTaskInTime(10*FRAMES, function(mob) RetargetFn(mob) end)
end

return {
    Init                     = Init,
    CanTarget                = CanTarget,
	FindClosestTarget        = FindClosestTarget,
    FindClosestTargetInRange = FindClosestTargetInRange,
	KeepTarget               = KeepTarget,
    PetIsValidTarget         = PetIsValidTarget,
	PetKeepTarget            = PetKeepTarget,
    PetRetargetFn            = PetRetargetFn,
    PetSentryKeepTarget      = PetSentryKeepTarget,
    PetSentryRetargetFn      = PetSentryRetargetFn,
	OnAttacked               = OnAttacked,
	OnAttackOther            = OnAttackOther,
	OnDroppedTarget          = OnDroppedTarget,
	OnGiveUp                 = OnGiveUp,
    OnNewTarget              = OnNewTarget,
	RetargetFn               = RetargetFn,
	ForceAggro               = ForceAggro,
}
