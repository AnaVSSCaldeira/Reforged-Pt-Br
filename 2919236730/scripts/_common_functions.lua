----------------------
-- Common Functions --
----------------------
--[[
This file contains functions that are commonly used.
--]]
----------------------
local function GetPlayerExcludeTags(inst, force_player_tags)
    return (not TheNet:GetPVPEnabled() or force_player_tags) and TUNING.FORGE.PLAYER_EXCLUDE_TAGS or {}
end
FORGE_TEAM_TAGS.player = GetPlayerExcludeTags()
FORGE_TEAM_TAGS.companion = GetPlayerExcludeTags()
FORGE_TEAM_TAGS.ally = GetPlayerExcludeTags() --This tag is similar in priority to player tag.
FORGE_TEAM_TAGS.LA_mob = {"LA_mob"} --why does this use battlestandard tag, doesn't it also have LA_mob tag?
IGNORE_FRIENDLY_FIRE_TAGS = {LA_mob = true}

local IGNORE_TAGS = {"notarget", "INLIMBO", "playerghost"}

local function GetTeamTag(inst)
    local k_names = {}
    for k in pairs(FORGE_TEAM_TAGS) do
        if (not TheNet:GetPVPEnabled() or IGNORE_FRIENDLY_FIRE_TAGS[k]) and inst:HasTag(k) then
            return k
        end
    end
end

local function CommonExcludeTags(inst, force_mob, force_tags, include_team_tags)
	local tags = {}
    local tag_link = {}
    local include_team_tags = include_team_tags == nil or include_team_tags
    if include_team_tags then
        TableConcatNoDupeValues(tags, force_mob and FORGE_TEAM_TAGS["LA_mob"] or (FORGE_TEAM_TAGS[GetTeamTag(inst)] or {}), tag_link)
    end
    TableConcatNoDupeValues(tags, IGNORE_TAGS, tag_link)
    TableConcatNoDupeValues(tags, force_tags or {}, tag_link)
	return tags
end
--[[
local function CommonExcludeTags(inst, force_mob) --used for mob attacks/etc -- TODO rename?
	if force_mob or inst:HasTag("LA_mob") and not inst:HasTag("brainwashed") then
		return {"LA_mob", "notarget", "INLIMBO"} -- TODO create global table?
    else
        local exclude_tags = {"brainwashed", "notarget", "INLIMBO"}
        -- Add valid player exclude tags
        for _,tag in pairs(GetPlayerExcludeTags()) do
            table.insert(exclude_tags, tag)
        end
		return exclude_tags
	end
end]]

local function GetAllyTags(inst)
    local team_tag = GetTeamTag(inst)
    if team_tag then
        return FORGE_TEAM_TAGS[team_tag]
    else
        local exclude_tags = {}
        -- Add valid player exclude tags
        for _,tag in pairs(GetPlayerExcludeTags()) do
            table.insert(exclude_tags, tag)
        end
        return exclude_tags
    end
end

local function GetEnemyTags(inst)
    if inst:HasTag("LA_mob") then
        local exclude_tags = {}
        -- Add valid player exclude tags
        for _,tag in pairs(GetPlayerExcludeTags()) do
            table.insert(exclude_tags, tag)
        end
        return exclude_tags
    else
        return FORGE_TEAM_TAGS["LA_mob"]
    end
end

local function GetAllyAndEnemyTags(inst)
    local exclude_tags = {"LA_mob", "brainwashed"}
    -- Add valid player exclude tags
    for _,tag in pairs(GetPlayerExcludeTags()) do
        table.insert(exclude_tags, tag)
    end
    return exclude_tags
end

local function SwitchTeamTag(inst, tag)
	if FORGE_TEAM_TAGS[tag] and GetTeamTag(inst) then
		inst:RemoveTag(GetTeamTag(inst))
		inst:AddTag(tag)
	else
		Debug:Print("SwitchTeamTag could not find the key '"..tag.."' in FORGE_TEAM_TAGS", "error")
	end
end

-- TODO adapt this to include players AND mobs
local function IsAlly(inst, target)
    for _,tag in pairs(CommonExcludeTags(inst)) do
        if target:HasTag(tag) then
            return true
        end
    end
    return false
    -- This is the old method, remove when new one is tested and confirmed working
    --[[for _,tag in pairs(GetPlayerExcludeTags(inst)) do
        if target:HasTag(tag) then
            return true
        end
    end
    return false--]]
end



local function AddDependenciesToPrefab(prefab_name, deps) -- TODO does not work, remove this?
    local prefab = _G.Prefabs[prefab_name]
    if prefab then
        Debug:Print("Adding dependencies to " .. tostring(prefab_name) .. "...", "log")
        for _,dep in pairs(deps) do
            print(" - " .. tostring(dep))
            table.insert(prefab.deps, dep)
        end
    else
        Debug:Print("Prefab not found for " .. tostring(prefab_name) .. "!", "warning")
    end
end

--This is a function that should be used to return to the ground, since a lot of basegame functions don't account for blocked areas (aka crowdstands)
local function ReturnToGround(inst)
	local pos = inst:GetPosition()
    local result_offset
    local distance = 0
    local step = 0.5
    while result_offset == nil do
        result_offset = FindValidPositionByFan(distance, distance, distance, function(offset)
    		local test_point = pos + offset
    		return not TheWorld.Map:IsGroundTargetBlocked(test_point) and TheWorld.Map:IsPassableAtPoint(test_point:Get()) and TheWorld.Map:IsValidTileAtPoint(test_point:Get())
        end)
        distance = distance + step
    end

    local target_pos = result_offset and pos + result_offset or _G.TheWorld.multiplayerportal and _G.TheWorld.multiplayerportal:GetPosition()

    -- Spawn fx depending on where the entity was last at.
    local fx = _G.SpawnPrefab("splash_lavafx") -- TODO have different fx based on where it's teleporting from?
    fx.Transform:SetPosition(pos:Get())

	if inst.components.inventoryitem then
        inst.components.inventoryitem:DoDropPhysics(target_pos.x, 10, target_pos.z, false, false)
    else
        inst.Physics:Teleport(target_pos.x, 0, target_pos.z)
    end
end

--This is for launching items manually, if you want to automatically launch items (like snortoise spinning does) look at the item_launcher component.
local function LaunchItems(inst, radius, speed, ignore_scaling)
    local scaler = not ignore_scaling and inst.components.scaler and inst.components.scaler.scale or 1
    local radius = radius * scaler
	local pos = inst:GetPosition()
	local ents = TheSim:FindEntities(pos.x, 0, pos.z, radius or 3, { "_inventoryitem" }, { "locomotor", "INLIMBO" })
	if #ents > 0 then
		for i, v in ipairs(ents) do
			if not v.components.inventoryitem.nobounce and v.Physics ~= nil and v.Physics:IsActive() then
				Launch(v, inst, speed or 0.2)
			end
		end
	end
end

local function SetupBossFade(inst, time, mustneverfade) --mustneverfade is for special cases like Rhinocebros where they shouldn't fade away until they truly die.
	if not mustneverfade then
		if TheWorld.components.lavaarenaevent:GetCurrentRound() == #TheWorld.components.lavaarenaevent.waveset_data and not TheWorld.components.lavaarenaevent.endless then
			inst.components.health.nofadeout = true
		else
			inst.components.health.nofadeout = nil
			inst.components.health.destroytime = time or 5
		end
	else
		inst.components.health.nofadeout = true
		if TheWorld.components.lavaarenaevent:GetCurrentRound() ~= #TheWorld.components.lavaarenaevent.waveset_data then
			inst.should_fadeout = time or 5 --This doesn't do anything on its own, look at the death state SGrhinocebros to see how this is setup.
		end
	end
end

local function FadeOut(inst, delay)
    inst:AddTag("NOCLICK")
    inst.persists = false
    inst:DoTaskInTime(delay or 0, ErodeAway) -- Default is 2 in health component
end

local function GetHealingCircle(inst, musthaveplayers) -- TODO remove this function, no longer used
	local pos = inst:GetPosition()
	local circle = FindEntity(inst, 255,  nil, nil, {"notarget"}, {"healingcircle"}, {"healingcircle"}) or nil
	if musthaveplayers and circle then
		local circlepos = circle:GetPosition()
		local ents = TheSim:FindEntities(circlepos.x, 0, circlepos.z, circle.components.heal_aura.range, {"notarget"}, {"player"})
		return #ents > 0 and circle or nil
	else
		return circle
	end
end

local function GetHealAuras(inst, range) -- TODO change healingcircle to healaura in all files?
    local pos = inst:GetPosition()
    local range = range or 8 -- TODO what should the default range be?
    local heal_auras = TheSim:FindEntities(pos.x, 0, pos.z, range, {"healingcircle"})
    if heal_auras then
        -- Sort Heal Auras from closest to furthest from inst
        table.sort(heal_auras, function(a,b)
            local a_distance_sq = a ~= nil and distsq(a:GetPosition(), pos) or 99999
            local b_distance_sq = b ~= nil and distsq(b:GetPosition(), pos) or 99999
            return a_distance_sq <= b_distance_sq
        end)
    end
    return heal_auras
end

local function FindDouble(inst, tags) --for very specific situations involving double trouble
	local pos = inst:GetPosition()
	local ents = TheSim:FindEntities(pos.x, 0, pos.z, 255, tags)
	local doubles = {}
	if ents and #ents > 0 then
		for i, v in ipairs(ents) do
			if v:IsValid() and v.components.health and not v.components.health:IsDead() and v ~= inst then
				table.insert(doubles, v)
			end
		end
	end
	return #doubles
end
--inst, target, min_range, max_range, distance_override, ignore_scaling
-- Checks if target is within the given range of the inst
local function IsTargetInRange(inst, target, min_range, max_range, opts)
    local options = opts or {
        --distance_override = nil,
        --ignore_scaling    = nil,
    }
    ------------------------------------------
    local scaler = not options.ignore_scaling and inst.components.scaler and inst.components.scaler.scale or 1
    local min_range = (min_range or 0) * scaler
    local max_range = max_range ~= nil and (max_range * scaler + inst:GetPhysicsRadius(0))
    ------------------------------------------
    -- Default Target
    if not target then
        target = inst.components.combat.target
    end
    ------------------------------------------
    local distance_to_target = options.distance_override or distsq(target and target:GetPosition() or inst:GetPosition(), inst:GetPosition())
    ------------------------------------------
    return target and (distance_to_target >= min_range * min_range) and (not max_range or distance_to_target <= max_range * max_range)
end

local function DoAttack(inst, source, target, damage, opts)
    local options = opts or {
        --name        = nil,
        --stimuli     = nil,
        --damage_type = nil,
        --is_alt      = nil,
        --weapon      = nil,
        --projectile  = nil,
        --target_pos  = nil,
        --onhit_fn    = nil,
        --invulnerability_time = nil,
    }
    ------------------------------------------
    target.components.combat:GetAttacked(source, type(damage) == "function" and damage(inst, source, target) or damage, options.weapon, options.stimuli, options.is_alt, options.projectile, options.damage_type)
    ------------------------------------------
    -- Give invulnerability to this AOE attack for the current target
    if (options.invulnerability_time or 0) > 0 then -- TODO should this be added to combat?
        source.aoe_attacked_targets[options.name][target] = true
        source:DoTaskInTime(options.invulnerability_time, function()
            source.aoe_attacked_targets[options.name][target] = nil
        end)
    end
    ------------------------------------------
    if options.onhit_fn then
        options.onhit_fn(inst, source, target, options.target_pos)
    end
end

-- TODO include mob radius?
--inst, damage, offset, range, stimuli, invulnerability_time, target_pos, projectile, no_aggro, source, onhit_fn, name, ignore_scaling, damage_type, is_alt, weapon
local function DoAOE(inst, source, damage, opts) -- TODO DoFrontAOE
    local source = source and source:IsValid() and source or inst
    if not source then return end
    ------------------------------------------
    local options = {
        name           = "general",
        offset         = 0, -- TODO was 3
        range          = 1, -- TODO was 3
        --stimuli        = nil,
        --damage_type    = nil,
        --is_alt         = nil,
        --weapon         = nil,
        --projectile     = nil,
        --target_pos     = nil,
        --no_aggro       = nil,
        --onhit_fn       = nil,
        --ignore_scaling = nil,
        --invulnerability_time = nil,
    }
    MergeTable(options, opts or {}, true)
    ------------------------------------------
	local angle = -source.Transform:GetRotation() * DEGREES
    local scaler = not options.ignore_scaling and inst.components.scaler and inst.components.scaler.scale or 1
	local offset = options.offset * scaler
	local offset_pos = Vector3(math.cos(angle), 0, math.sin(angle)) * offset
	local target_pos = options.target_pos or source:GetPosition() + offset_pos
    local range = options.range * scaler
	local ents = TheSim:FindEntities(target_pos.x, 0, target_pos.z, range, {"_combat"}, CommonExcludeTags(source))
    local current_target_hit = false
    local target_hit = false
	-- Create invulnerability table
	if options.invulnerability_time then
        EnsureTable(source, "aoe_attacked_targets", options.name)
	end
    ------------------------------------------
    --print("Checking targets for " .. tostring(source) .. "...")
	for _,ent in ipairs(ents) do
        --print("- ent: " .. tostring(ent))
        if not (options.invulnerability_time and source.aoe_attacked_targets[options.name][ent]) then
            -- Just deal damage directly to target if source has no combat component
            if not source.components.combat then
                DoAttack(inst, source, ent, damage, options)
    		elseif source.components.combat:IsValidTarget(ent) then
                --print("- - attacked")
                DoAttack(inst, source, ent, source.components.combat:CalcDamage(ent, nil, nil, nil, options.damage_type, options.stimuli, damage), options)
    			source:PushEvent("onattackother", {target = ent, stimuli = options.stimuli, no_aggro = options.no_aggro})
    			current_target_hit = current_target_hit or source.components.combat.target == ent
                target_hit = true
            end
		end
	end
    ------------------------------------------
	if not target_hit then
		source:PushEvent("onmissother", {target = source.sg and source.sg.statemem.target or source.components.combat and source.components.combat.target})
	elseif current_target_hit then -- Only update the last doattack time if the current target is affected
		source.components.combat.lastdoattacktime = GetTime()
	end
end

local function GetTargetsWithinRange(inst, min_range, max_range, opts)
    local options = opts or {
        --include_tags   = nil,
        --exclude_tags   = nil,
        --ignore_scaling = nil,
    }
    ------------------------------------------
    local scaler = not options.ignore_scaling and inst.components.scaler and inst.components.scaler.scale or 1
    local min_range = (min_range or 0) * scaler
    local max_range = (max_range or 5) * scaler
    local targets = {}
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, max_range, options.include_tags, CommonExcludeTags(inst, nil, options.exclude_tags))
    for _,ent in ipairs(ents) do
        if ent ~= inst.components.combat.target and inst.components.combat:CanTarget(ent) then
            local distance_to_target = distsq(ent:GetPosition(), inst:GetPosition()) or 0
            if distance_to_target > (min_range*min_range - ent:GetPhysicsRadius(0)) and distance_to_target < (max_range*max_range + ent:GetPhysicsRadius(0)) then
                table.insert(targets, ent)
            end
        end
    end
    return targets
end

local REPEL_RADIUS = 5
local REPEL_RADIUS_SQ = REPEL_RADIUS * REPEL_RADIUS
-- Common Knockback function for mobs that do not have a knockback state
local function Knockback(inst, target, radius, attack_knockback)
    if inst.components.combat and inst.components.combat:IsValidTarget(target) and not (target:HasTag("epic") or target:HasTag("largecreature")) and target.Physics then
        local x, y, z = inst.Transform:GetWorldPosition()
        local distsq = target:GetDistanceSqToPoint(x, 0, z)
        --if distsq < REPEL_RADIUS_SQ then
        if distsq > 0 then
            target:ForceFacePoint(x, 0, z)
        end
        local k = .5 * distsq / REPEL_RADIUS_SQ - 1
        target.speed = 60 * k
        target.dspeed = 2
        target.Physics:ClearMotorVelOverride()
        target.Physics:Stop()
        --[[ TODO why aren't we using kleis?
        local k = distsq < rangesq and .3 * distsq / rangesq - 1 or -.7
        inst.sg.statemem.speed = (data.strengthmult or 1) * 12 * k
        inst.sg.statemem.dspeed = 0--]]

        -- TODO Leo: Need to change this to check for bodyslot for these tags.
        if target.components.inventory and target.components.inventory:ArmorHasTag("heavyarmor") or target:HasTag("heavybody") then
            target:DoTaskInTime(0.1, function(inst) -- TODO why is this set to 0.1 and the else is set to 0? if they should both be the same then we can shorten this if statement to just be the dotaskintime
                target.Physics:SetMotorVelOverride(-TUNING.FORGE.KNOCKBACK_RESIST_SPEED, 0, 0)
            end)
        else
            target:DoTaskInTime(0, function(inst)
                target.Physics:SetMotorVelOverride(-(attack_knockback or 1), 0, 0)
            end)
        end
        target:DoTaskInTime(0.4, function(inst)
            target.Physics:ClearMotorVelOverride()
            target.Physics:Stop()
        end)
    end
end

-- TODO strengthmult and forcelanded should be applied and used if needed, double check all calls to this. Also, probably change the generic knockback function above to include those parameters as well. This means it will have to be rewritten to use them as well.
-- TODO need to go through all onhitother event calls that use this knockback and make sure they are using data.target and not target.
-- Applies Knockback to each hit. If the target does not have a knockback event then a generic knockback will be applied to the target (see Knockback above).
local function KnockbackOnHit(inst, target, radius, attack_knockback, strength_mult, force_land)
    if target.sg and target.sg.sg.states.knockback then
        target:PushEvent("knockback", {knocker = inst, radius = radius, strengthmult = strength_mult, forcelanded = force_land})
    else
        Knockback(inst, target, radius, attack_knockback)
    end
end

--ToDo: Leo: all these collision functions are for when we will allow them to be outside the forge. This will break trees and nonsense.
--If we are planning to do that then we should make this a common fn for Giants. (Also could possibly used for modding things if someone makes use of a tree or something)
-- Return true if the given object can be destroyed.
local function CanDestroyObject(inst, object)
    return object and object:IsValid() and object.components.workable and object.components.workable:CanBeWorked() and object.components.workable.action ~= ACTIONS.DIG and object.components.workable.action ~= ACTIONS.NET and not inst.recentlycharged[object]
end

-- Removes the given object from the recently charged list which will allows it to get charged again.
local function ClearRecentlyCharged(inst, object)
    inst.recentlycharged[object] = nil
end

local function CanDestroy(inst, object)
    --return object:HasTag("wall") and object.OnCollideDestroy
    return object and object:IsValid() and object.OnCollideDestroy
end

-- Destroys the given object
local RECENTLY_CHARGED_DURATION = 3
local function OnDestroyObject(inst, object)
    if CanDestroyObject(inst, object) then
        SpawnPrefab("collapse_small").Transform:SetPosition(object.Transform:GetWorldPosition())
        object.components.workable:Destroy(inst)
        inst.recentlycharged[object] = true
        inst:DoTaskInTime(RECENTLY_CHARGED_DURATION, ClearRecentlyCharged, object)
    elseif CanDestroy(inst, object) then
        object:OnCollideDestroy(inst)
        inst.recentlycharged[object] = true
        inst:DoTaskInTime(RECENTLY_CHARGED_DURATION, ClearRecentlyCharged, object)
    end
end

-- This was added so the mobs could be used in base game, this will cause the mob to destroy objects they collide with.
local DESTROY_OBJECT_DELAY = 2*FRAMES
local function OnCollideDestroyObject(inst, object)
    if CanDestroyObject(inst, object) or CanDestroy(inst, object) then
        inst:DoTaskInTime(DESTROY_OBJECT_DELAY, OnDestroyObject, object)
    end
end

-- Moves the mob from its current position to the given position in the amount of frames given.
local function JumpToPosition(inst, target_pos, total_frames) -- TODO better name?
    ToggleOffCharacterCollisions(inst)
    inst.sg:AddStateTag("nointerrupt")
    if target_pos then
        local starting_pos = inst:GetPosition()
        -- Calculate and set the velocity needed to reach the target in the amount of frames given.
        inst:ForceFacePoint(target_pos:Get())
        inst.Physics:SetMotorVel(math.sqrt(distsq(starting_pos.x, starting_pos.z, target_pos.x, target_pos.z)) / (total_frames * FRAMES), (target_pos.y - starting_pos.y)/(total_frames * FRAMES), 0)
    end
end

local function CalculateScaleRate(start_scale, final_scale, duration)
    local scale_rate = {}
    for i=1,2 do
        table.insert(scale_rate, (final_scale[i] - start_scale[i]) / duration)
    end
    return scale_rate
end

local function ConvertScale(start_scale)
    local scale = {}
    for i=1,2 do
        table.insert(scale, start_scale[i]/2) -- Seems to be twice as big as dynamic shadows
    end
    return scale
end

-- COMMON_FNS.SpawnWarningShadow(ThePlayer, {0,0,0}, {5,5,5}, 100)
local function SpawnWarningShadow(source, start_scale, final_scale, total_frames, manual_start)
    local pos = source:GetPosition()
    local warning_shadow = SpawnPrefab("warningshadow")
    local scale = {} -- TODO need to convert start size so that it's the right scaling
    warning_shadow.scale_rate = CalculateScaleRate(start_scale, final_scale, total_frames)
    warning_shadow.Transform:SetPosition(pos.x, 0, pos.z)
    warning_shadow.AnimState:SetScale(unpack(ConvertScale(start_scale)))
    warning_shadow.scale_update_count = 0
    warning_shadow.StartShadowUpdate = function(inst)
            inst.scale_task = inst:DoPeriodicTask(FRAMES, function()
            if inst.scale_update_count >= total_frames then
                inst.scale_task:Cancel()
                inst:Remove()
            else
                inst.scale_update_count = inst.scale_update_count + 1
                local scale = {}
                for i=1,2 do
                    table.insert(scale, start_scale[i] + inst.scale_rate[i]*inst.scale_update_count)
                end
                inst.AnimState:SetScale(unpack(ConvertScale(scale)))
            end
        end)
    end

    if not manual_start then
        warning_shadow:StartShadowUpdate()
    end

    return warning_shadow
end

local function SpawnEntsInCircle(inst, opts, current_ents)
    local options = {
       pos          = TheWorld.components.lavaarenaevent:GetArenaCenterPoint() or inst.Transform:GetPosition(),
       offset       = 13.5,
       angle_offset = PI/4,
       prefab       = "battlestandard_damager",
       max          = 4,
       delay_per_spawn = 4*FRAMES,
       duplicates      = false,
    }
    current_ents = current_ents or {}
    -- Load custom options
    MergeTable(options, opts or {}, true)
    -- Generate Positions
    local positions = {}
    for i = 1, options.max do
        local current_angle = 2 * PI / options.max * i + options.angle_offset
        local angled_offset = Vector3(options.offset * math.cos(current_angle), 0, options.offset * math.sin(current_angle))
        local pos = options.pos + angled_offset
        -- Check to see if ent already exists in this position
        local is_valid_pos = true
        if not options.duplicates then
            for _,ent in pairs(current_ents) do
                local ent_pos = ent:GetPosition()
                for i,val in pairs(ent_pos) do
                    ent_pos[i] = Round(val,100)
                end
                local is_same_pos = ent_pos.x == pos.x and ent_pos.y == pos.y and ent_pos.z == pos.z
                is_valid_pos = is_valid_pos and (ent:GetDistanceSqToPoint(pos) > 0.1)
            end
        end
        if is_valid_pos then
            table.insert(positions, pos)
        end
    end
    -- Spawn ents in random order
    local prefab = type(options.prefab) == "function" and options.prefab(inst) or options.prefab
    for i = 1, #positions do
        local rand = math.random(#positions)
        local pos = positions[rand]
        table.remove(positions, rand)
        inst:DoTaskInTime(options.delay_per_spawn*(i-1), function(inst)
            local ent = SpawnPrefab(prefab)
            ent.Transform:SetPosition(pos:Get())
            current_ents[ent] = ent
            ent:ListenForEvent("onremove", function()
                current_ents[ent] = nil
            end)
        end)
    end

    return current_ents
end

local MAX_TRAIL_VARIATIONS = 7
local MAX_RECENT_TRAIL = 4
local TRAIL_PERIOD = .2
local TRAIL_LEVELS = {
    {
        min_scale = .5,
        max_scale = .8,
        threshold = 8,
        duration = 1.2,
    },{
        min_scale = .5,
        max_scale = 1.1,
        threshold = 2,
        duration = 2,
    },{
        min_scale = 1,
        max_scale = 1.3,
        threshold = 1,
        duration = 4,
    },
}

local function PickTrail(inst)
    return math.random(MAX_TRAIL_VARIATIONS)
end

local function DoTrail(inst)
    if inst.trail_condition_fn and not inst.trail_condition_fn(inst) then return end
    local level = inst.trail_levels and inst.trail_levels[1] or TRAIL_LEVELS[
        (not inst.sg:HasStateTag("moving") and 1) or
        (inst.components.locomotor.walkspeed <= _G.TUNING.BEEQUEEN_SPEED and 2) or
        3
    ] -- TODO

    inst.trail_count = inst.trail_count + 1

    if inst.trail_threshold > level.threshold then
        inst.trail_threshold = level.threshold
    end

    if inst.trail_count >= inst.trail_threshold then
        local hx, hy, hz = inst.Transform:GetWorldPosition()
        inst.trail_count = 0
        if inst.trail_threshold < level.threshold then
            inst.trail_threshold = math.ceil((inst.trail_threshold + level.threshold) * .5)
        end

        local fx = nil
        if _G.TheWorld.Map:IsPassableAtPoint(hx, hy, hz) then
            fx = COMMON_FNS.CreateFX(inst.trail_prefab or "honey_trail", nil, inst)
            fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
            fx.source = inst
            fx:SetVariation(PickTrail(inst), _G.GetRandomMinMax(level.min_scale, level.max_scale), level.duration + math.random() * .5)
        else
            fx = COMMON_FNS.CreateFX("splash_sink", nil, inst)
            fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        end
    end
end

local function StartTrail(inst)
    if inst.trail_task == nil then
        inst.trail_threshold = (inst.trail_levels or TRAIL_LEVELS)[1].threshold
        inst.trail_count = math.ceil(inst.trail_threshold * .5)
        inst.trail_task = inst:DoPeriodicTask(inst.trail_period or TRAIL_PERIOD, DoTrail, 0)
    end
end

local function StopTrail(inst)
    RemoveTask(inst.trail_task)
    inst.trail_task = nil
end

local function CreateTrail(inst, trail_prefab, max_trail_variations, trail_levels, trail_period, trail_condition_fn)
    inst.trail_prefab = trail_prefab
    inst.StartTrail = StartTrail
    inst.StopTrail = StopTrail
    inst.trail_task = nil
    inst.trail_count = 0
    inst.trail_threshold = 0
    inst.trail_levels = trail_levels
    inst.trail_period = trail_period
    inst.trail_condition_fn = trail_condition_fn

    inst:StartTrail()
end

local function SlamTrail(inst, target_pos, slam_options)
    local options = {
        starting_offset     = 4,
        max_trails          = 11,
        dist_between_trails = 2.5,
        trail_width         = 2,
        trail_offset        = 1,
        angle_difference    = 0,
        max_angle           = 180, -- TODO
        prefab   = "", -- supports functions
        damage   = 10, -- supports functions
        range    = 1,
        stimuli  = nil,
        no_aggro = true,
        invulnerability_time = 0.2,
        duration             = nil,
        delay_between_trails = _G.FRAMES,
        do_damage       = true,
        ignore_ground   = false,
        ignore_blockers = false,
        max_distance    = nil,
    }
    -- Load custom options
    MergeTable(options, slam_options or {}, true)

    local scale = inst.components.scaler.scale or 1
    local source_pos = inst:GetPosition()
    local normalized_offset = target_pos and target_pos ~= source_pos and (target_pos - source_pos):GetNormalized() or Vector3(0,0,0)
    local starting_pos = source_pos + normalized_offset * options.starting_offset * scale

    -- Calculate max trails if a max distance is given. Will always have at least 1 trail spawn.
    if options.max_distance then
        options.max_trails = math.max(math.floor((options.max_distance - (options.starting_offset or 0)) / (options.trail_offset*scale)), 1)
    end

    local angle = -inst.Transform:GetRotation() * DEGREES
    local center_trail_offset = (options.trail_width%2 == 0 and options.dist_between_trails/2 or 0) * scale
    local center_trail        = options.trail_width/2 + 0.5
    for i = 1, options.max_trails do
        inst:DoTaskInTime(i * (options.duration and (options.duration/options.max_trails) or options.delay_between_trails), function()
            for j = 1, options.trail_width do
                -- offset between trails
                local angle_between_trails = angle + (center_trail == j and 0 or center_trail > j and -PI/2 or PI/2)
                local current_dist_between_trails = options.dist_between_trails * math.abs(center_trail - j) * scale
                local angled_offset = Vector3(math.cos(angle_between_trails), 0, math.sin(angle_between_trails)) * current_dist_between_trails
                -- angled offset
                local current_angle = angle + (j - (options.trail_width/2 + 0.5))*options.angle_difference*DEGREES
                local normalized_angled_offset = Vector3(math.cos(current_angle), 0, math.sin(current_angle))
                -- calculate position
                local current_pos = starting_pos + normalized_angled_offset * options.trail_offset * scale * i + angled_offset
                local x, y, z = current_pos:Get()
                if (options.ignore_ground or TheWorld.Map:IsAboveGroundAtPoint(x, y, z)) and (options.ignore_blockers or not TheWorld.Map:IsGroundTargetBlocked(current_pos)) and (not options.ShouldSpawnFN or options.ShouldSpawnFN(inst, i, j, options.max_trails, current_pos)) then
                    local trail = COMMON_FNS.CreateFX(type(options.prefab) == "function" and options.prefab(inst, i, j, options.max_trails) or options.prefab, nil, inst)
                    trail.Transform:SetPosition(x, y, z)
                    if options.OnSpawnFN then
                        options.OnSpawnFN(inst, trail, i, j, options.max_trails)
                    end
                    if options.do_damage then
                        COMMON_FNS.DoAOE(inst, nil, type(options.damage) == "function" and options.damage(inst, i, options.max_trails) or options.damage, {range = options.range*scale, stimuli = options.stimuli, invulnerability_time = options.invulnerability_time, target_pos = current_pos, projectile = trail, no_aggro = options.no_aggro})
                    end
                end
            end
        end)
    end
end

-- TODO replace all resets used in the mod.
local function ResetWorld()
    local function doreset()
        StartNextInstance({
            reset_action = RESET_ACTION.LOAD_SLOT,
            save_slot    = ShardGameIndex:GetSlot(),
            reforged     = _G.REFORGED_SETTINGS.gameplay,
        })
    end
    if _G.TheWorld ~= nil and _G.TheWorld.ismastersim then
        _G.ShardGameIndex:Delete(doreset, true)
    end
end

local function AddTags(inst, ...)
	for _,tag in pairs({...}) do
		inst:AddTag(tag)
	end
end

local function CreateFX(prefab, target, source, opts)
    local opts = opts or {}
    local fx = SpawnPrefab(prefab)
    local source = source or target
    if source and source.components.scaler then
        if not fx.components.scaler then
            fx:AddComponent("scaler")
        end
        fx.components.scaler:SetBaseScale(opts.scale)
        fx.components.scaler:SetSource(source)
    end
    if opts.position then
        fx.Transform:SetPosition(opts.position:Get())
    end
    if opts.OnSpawn then
        opts.OnSpawn(fx)
    end
    if fx.OnSpawn then
        fx:OnSpawn({target = target, source = source or target})
    end
    return fx
end

local function RemoveFX(fx)
    if fx then
        if fx.RemoveFX then
            fx:RemoveFX()
        else
            fx:Remove()
        end
    end
end

local function NetworkCreateFX(inst, fx, source)
    if _G.REFORGED_SETTINGS.performance.all_fx then -- TODO add the other fx settings here
        inst.fx_source:set(source)
        inst.client_fx:set("")
        inst.client_fx:set(fx)
    end
end

local function NetworkRemoveFX(inst, fx)
    if inst then
        inst.remove_client_fx:set("")
        inst.remove_client_fx:set(fx)
    end
end

-- TODO save in a table for reference???
local function OnFXDirty(inst)
    local prefab = inst.client_fx:value()
    if prefab and prefab ~= "" then -- TODO add settings check for client_side_fx
        local fx = SpawnPrefab(prefab)
        if fx then
            -- Start tracking fx
            inst.fx_tracker[prefab] = fx -- TODO what if multiple fx of the same prefab?
            -- Make sure fx is no longer tracked after being removed
            local _oldRemove = fx.Remove
            fx.Remove = function(fx_inst)
                inst.fx_tracker[fx] = nil
                _oldRemove(fx_inst)
            end
            if fx.OnSpawn then
                fx:OnSpawn({target = inst, source = inst.fx_source:value()})
            end
        end
    end
end

local function OnRemoveFXDirty(inst)
    local fx = inst.remove_client_fx:value()
    if fx and inst.fx_tracker[fx] then
        -- Check for custom Remove function
        if inst.fx_tracker[fx].RemoveFX then
            inst.fx_tracker[fx]:RemoveFX()
        else
            inst.fx_tracker[fx]:Remove()
        end
    end
end

local function CreateFXNetwork(inst)
    inst.fx_tracker = {}
    inst.fx_source = net_entity(inst.GUID, "player.fxsource")
    inst.client_fx = net_string(inst.GUID, "player.fxdirty", "fxdirty")
    inst.remove_client_fx = net_string(inst.GUID, "player.removefxdirty", "removefxdirty")
    if not TheNet:IsDedicated() then
        inst:ListenForEvent("fxdirty", OnFXDirty)
        inst:ListenForEvent("removefxdirty", OnRemoveFXDirty)
    end
end

local function IsScripter(userid)
    local script_data = _G.Settings.match_results and _G.Settings.match_results.outcome and _G.Settings.match_results.outcome.script_data or _G.TheFrontEnd.match_results and _G.TheFrontEnd.match_results.outcome and _G.TheFrontEnd.match_results.outcome.script_data
    return script_data and script_data[userid] and script_data[userid].exp_mult > 0
end

local function AddStateToStategraph(sg, state, override)
    assert(state:is_a(State),"Non-state added in state table!")
    if override or not sg.states[state.name] then
        sg.states[state.name] = state
    end
end
local function AddStatesToStategraph(sg, states, override)
    for _,state in pairs(states or {}) do
        AddStateToStategraph(sg, state, override)
    end
end

local function ApplyStategraphPostInits(stategraph)
    for k,modhandlers in pairs(ModManager:GetPostInitData("StategraphActionHandler", stategraph.name)) do
        for i,v in ipairs(modhandlers) do
            assert( v:is_a(ActionHandler),"Non-action handler added in mod actionhandler table!")
            stategraph.actionhandlers[v.action] = v
        end
    end
    for k,modhandlers in pairs(ModManager:GetPostInitData("StategraphEvent", stategraph.name)) do
        for i,v in ipairs(modhandlers) do
            assert( v:is_a(EventHandler),"Non-event added in mod events table!")
            stategraph.events[v.name] = v
        end
    end
    for k,modhandlers in pairs(ModManager:GetPostInitData("StategraphState", stategraph.name)) do
        for i,v in ipairs(modhandlers) do
            assert( v:is_a(State),"Non-state added in mod state table!")
            stategraph.states[v.name] = v
        end
    end

    local modfns = ModManager:GetPostInitFns("StategraphPostInit", stategraph.name)
    for i,modfn in ipairs(modfns) do
        modfn(stategraph)
    end
end

local function ForceTaunt(inst)
    if not inst.components.health:IsDead() and (inst.sg:HasStateTag("hit") or not inst.sg:HasStateTag("busy")) then
        inst.sg:GoToState("taunt")
    else
        inst.sg.mem.wants_to_taunt = true
    end
end

local function MakeComplexProjectilePhysics(inst, mass, friction, damp, res, cap_l, cap_w)
    inst.Physics:SetMass(mass or 1)
    inst.Physics:SetFriction(friction or 0)
    inst.Physics:SetDamping(damp or 0)
    inst.Physics:SetRestitution(res or .5)
    inst.Physics:SetCollisionGroup(COLLISION.ITEMS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
    inst.Physics:SetCapsule(cap_l or .2, cap_w or cap_l or .2)
end

local function SpreadShot(source, attacker, target, opts)
    local options = {
        amount        = 1,
        angle         = 0,
        start_angle   = 0,
        damage        = 10,
        offset        = 1,
        is_alt        = false,
        total_angle   = nil, -- Will ignore angle and fit all projectiles within the total angle.
        prefab        = "forgedarts_projectile_alt",
        ignore_center = false, -- Will assume a projectile is being shot at center
    }
    MergeTable(options, opts, true)
    local attacker_pos = attacker:GetPosition()
    local target_pos = target and target:GetPosition()
    attacker:ForceFacePoint(target_pos)
    local current_angle = -attacker:GetRotation()
    local total_projectiles = options.amount - (options.ignore_center and 1 or 0)
    local angle_between_projectiles = options.total_angle and options.total_angle/options.amount or options.angle
    for i=1,total_projectiles do
        local projectile = SpawnPrefab(options.prefab)
        projectile.Transform:SetPosition(attacker_pos:Get())
        -- Calculate offset for current projectile
        local angle = (options.start_angle + current_angle + (options.ignore_center and (-total_projectiles/2 + i - (total_projectiles/2 >= i and 1 or 0)) or (i - math.ceil(total_projectiles/2))) * angle_between_projectiles) * DEGREES
        local offset_pos = Vector3(math.cos(angle), 0, math.sin(angle)) * options.offset
        -- Throw Projectile
        projectile.components.projectile:AimedThrow(source, attacker, attacker_pos + offset_pos, options.damage, options.is_alt)
    end
end

--[[
TODO
check to see how long an item glowed on drop in the orig forge
    30 seconds (ours is 10 seconds?)
WATCH 2 man runs to double check item drops
    need to see if any random item could drop on last mob and if more than one random item could drop from the same mob
--]]
local function DropItem(pos, prefab)
    local item = SpawnPrefab(prefab)
    if item == nil then return end
    local x, y, z = pos:Get()
    item.Transform:SetPosition(x, y, z)
    if item.components.inventoryitem then
        item.components.inventoryitem:DoDropPhysics(x, y, z, true, 1.2) --TODO klei does launch theirs much stronger but in tests I did, anything higher can get it oob. Need to figure that out.
        local lootbeacon = SpawnPrefab("lavaarena_lootbeacon") -- TODO this lasted 30 seconds in the vid I watched, ours last 10 seconds
        lootbeacon:SetTarget(item)
    end
end
-- Test function to simulate items dropping near edge.
--local function DropItem(inst, prefab) local item = SpawnPrefab(prefab) if item == nil then return end local x, y, z = inst:GetPosition():Get() item.Transform:SetPosition(x, y, z) if item.components.inventoryitem then item.components.inventoryitem:DoDropPhysics(x, y, z, true, 1.2) local lootbeacon = SpawnPrefab("lavaarena_lootbeacon") lootbeacon:SetTarget(item) end end DropItem(ThePlayer, "forgedarts")
-- AllPlayers[1]:DoPeriodicTask(0.5, function() local function DropItem(inst, prefab) local item = SpawnPrefab(prefab) if item == nil then return end local x, y, z = inst:GetPosition():Get() item.Transform:SetPosition(x, y, z) if item.components.inventoryitem then item.components.inventoryitem:DoDropPhysics(x, y, z, true, 1.2) local lootbeacon = SpawnPrefab("lavaarena_lootbeacon") lootbeacon:SetTarget(item) end end DropItem(AllPlayers[1], "forgedarts") end)

local function IsEventActive(event)
	return REFORGED_SETTINGS.display.event_tracking and IsSpecialEventActive(event)
end

local function CheckCommand(name, userid, conditional_fn)
    return TheWorld ~= nil and (not TheWorld.ismastersim or (TheWorld.net.components.command_manager == nil or TheWorld.net.components.command_manager:IsCommandReadyForUser(name, userid, conditional_fn)))
end
--------------
-- Entities --
--------------
--This is for builds that require multiple parts due to issues with compiler limitations.
--It takes the base build of the mob and then swaps it with the parted builds.
--Basically it just combines the builds into a singular mob.

--example
--local boarrior_symbols_1 = {"spark", "hand", "head", "pelvis", "chest", "splash", "rock2", "shoulder", "rock"}
--local boarrior_symbols_2 = {"arm", "nose", "swap_weapon", "mouth", "eyes", "swap_weapon_spin", "swipes"}
--local boarrior_symbols = {boarrior_symbols_1, boarrior_symbols_2} --this gets thrown into the symbols parameter below

--If you want to use this, make sure you name your builds "buildname_ptx"
--where x is the number of the part, e.g. "lavaarena_boarrior_pt1"

--alt parameter is me lazily making this just overriding a group of symbols for duplicator alts
local function ApplyMultiBuild(inst, symbols, build, alt)
    if symbols and build then
        for pt = 1, #symbols do
            --print(pt)
            for i, v in ipairs(symbols[pt]) do
                inst.AnimState:OverrideSymbol(v, alt and build or build.."_pt"..pt, v)
            end
        end
    end
end

local function ApplyBuild(inst, build)
    if build and type(build) == "table" then
        inst.AnimState:SetBuild(build.base)
        ApplyMultiBuild(inst, build.symbols, build.name)
    else
        inst.AnimState:SetBuild(build)
    end
end

local function SetBuild(inst, build)
    local build_num = (build - 1 )%#inst.builds + 1
    local build = inst.builds[build_num]
    ApplyBuild(build)
end

local function HideSymbols(inst, symbols)
    for _,symbol in pairs(symbols) do
        inst.AnimState:HideSymbol(symbol)
    end
end
--(bank, build, anim, anim_bool, no_anim)
local function BasicEntityInit(bank, build, anim, opts) -- TODO add to all items, double check to what they use
    local options = {
        anim        = anim or "idle",
        anim_loop   = true,
        noanim      = false,
        --pristine_fn = nil,
    }
    MergeTable(options, opts or {}, true)
    ------------------------------------------
	local inst = CreateEntity()
    ------------------------------------------
	inst.entity:AddTransform()
    ------------------------------------------
    if bank ~= nil then
        inst.entity:AddAnimState()
    	inst.AnimState:SetBank(bank)
        ApplyBuild(inst, build or bank)
    	if not options.noanim then
    		inst.AnimState:PlayAnimation(options.anim, options.anim_loop)
    	end
    end
    ------------------------------------------
    inst.entity:AddNetwork()
    ------------------------------------------
    if options.pristine_fn then
        options.pristine_fn(inst)
    end
    ------------------------------------------
	inst.entity:SetPristine() --Don't have this here.
	--setpristine tells the dedi that both server and client know everything prior to the mastersim check, so it always needs to be by the mastersim check.
	--Whether or not it can be called twice I'm not sure since some areas did call it twice and work fine but neither had important changes between them so idk.
    --CreateFXNetwork(inst)
    ------------------------------------------
	return inst
end

-- Calls the difficulty function for the inst if it exists to update the inst to the correct difficulty.
local function LoadDifficulty(prefab, inst)
    local difficulty = _G.REFORGED_SETTINGS.gameplay.difficulty
    local difficulty_fns = _G.REFORGED_DATA.difficulties and _G.REFORGED_DATA.difficulties[difficulty]
    if difficulty_fns and difficulty_fns[prefab] then
        difficulty_fns[prefab](inst)
    end
end

-- Loads any valid mutators for the inst.
local function LoadMutators(prefab, inst)
    local mutators = _G.REFORGED_SETTINGS.gameplay.mutators
    for mutator,val in pairs(mutators) do
        local mutator_info = _G.REFORGED_DATA.mutators[mutator]
        if val and mutator_info then
            if mutator_info.is_valid_fn(prefab, inst) then
                mutator_info.mutator_fn(inst)
            end
        end
    end
end

-- Returns a table of all the collision types the ent collides with
-- NOTE: "LIMITS" and "WORLD" are combinations of other collisions and not actual collisions themselves
--    LIMITS: BOAT_LIMITS + LAND_OCEAN_LIMITS
--    WORLD: BOAT_LIMITS + LAND_OCEAN_LIMITS + GROUND
local collision_types = {"GROUND", "BOAT_LIMITS", "LAND_OCEAN_LIMITS", "ITEMS", "OBSTACLES", "CHARACTERS", "FLYERS", "SANITY", "SMALLOBSTACLES", "GIANTS"}
local function GetEntityCollisions(ent)
    if not ent.Physics then return {} end
    local collisions = {}
    local collision_mask = ent.Physics:GetCollisionMask()

    local count = math.floor(math.log(collision_mask)/math.log(2)) - 4
    while collision_mask > 0 and count > 0 do
        local current_collision_value = COLLISION[collision_types[count]]
        if current_collision_value <= collision_mask then
            collision_mask = collision_mask - current_collision_value
            collisions[collision_types[count]] = true
        end
        count = count - 1
    end

    return collisions
end

---------
-- Mob --
---------
local sizes = {
    tiny = {
        burnable = MakeSmallBurnableCharacter, -- TODO create function for tiny?
        freezable = MakeTinyFreezableCharacter,
    },
    small = {
        burnable = MakeSmallBurnableCharacter,
        freezable = MakeSmallFreezableCharacter,
    },
    medium = {
        burnable = MakeMediumBurnableCharacter,
        freezable = MakeMediumFreezableCharacter,
    },
    large = {
        burnable = MakeLargeBurnableCharacter,
        freezable = MakeLargeFreezableCharacter,
    },
    huge = {
        burnable = MakeLargeBurnableCharacter, -- TODO create function
        freezable = MakeHugeFreezableCharacter,
    },
}

local function AddSymbolFollowers(inst, symbol, offset, size, fire_opts, freeze_opts)
    local pos = offset or Vector3(0,0,0)
	if inst.components.debuffable then
		inst.components.debuffable:SetFollowSymbol(symbol, pos.x, pos.y, pos.z)--offset.x or 0, offset.y or 0 , offset.z or 0)
	end
	if inst.components.armorbreak_debuff then
		inst.components.armorbreak_debuff:SetFollowSymbol(symbol, offset)
	end
    if fire_opts ~= false then
        sizes[size].burnable(inst, fire_opts and fire_opts.symbol or symbol, fire_opts and fire_opts.offset or offset)
    end
    if freeze_opts ~= false then
        sizes[size].freezable(inst, freeze_opts and freeze_opts.symbol or symbol, freeze_opts and freeze_opts.offset or offset)
    end
end

local function MobEntityInit(bank, build, anim, opts) -- TODO add to all mobs, double check what mobs use
    local options = {
        anim        = anim or "idle_loop",
        --anim_loop   = true,
        --noanim     = false,
        pristine_fn = nil,
    }
    MergeTable(options, opts or {}, true)
    local pristine_fn = options.pristine_fn
    options.pristine_fn = function(inst)
        inst.entity:AddSoundEmitter()
        inst.entity:AddDynamicShadow()
        inst.AnimState:AddOverrideBuild("fossilized")
        ------------------------------------------
        if pristine_fn then
            pristine_fn(inst)
        end
    end
    ------------------------------------------
	local inst = BasicEntityInit(bank, build, options.anim, options)
    ------------------------------------------
	return inst
end

local function ForgeMobTrackerInit(inst, round, wave, spawner)
    if TheWorld.components.forgemobtracker then
        TheWorld.components.forgemobtracker:StartTracking(inst, round, wave, spawner)
    end
end

local function MobTrackerInit(inst)
	if TheWorld.components.lavaarenamobtracker then
        TheWorld.components.lavaarenamobtracker:StartTracking(inst)
    end
end

local function GetMobWeight(inst, prefab_override)
    local prefab = (inst or prefab_override) and string.upper(prefab_override or inst.prefab) or nil
    return prefab and _G.TUNING.FORGE[prefab] and _G.TUNING.FORGE[prefab].WEIGHT or 1
end

local function AddScalerComponent(inst, opts)
    local opts = opts or {}
    inst:AddComponent("scaler")
    inst.components.scaler:SetBaseScale(opts.scale)
    inst.components.scaler:SetBaseRadius(opts.radius)
    inst.components.scaler:SetBaseMass(opts.mass)
    inst.components.scaler:SetBaseShadow(opts.shadow)
    inst.components.scaler:SetRadiusRate(opts.radius_rate)
    inst.components.scaler:SetMassRate(opts.mass_rate)
    inst.components.scaler:SetShadowRate(opts.shadow_rate)
end

local function AddCommonMobComponents(inst, tuning_values, mob_values)
	inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.runspeed = tuning_values.RUNSPEED or inst.components.locomotor.runspeed
	inst.components.locomotor.walkspeed = tuning_values.WALKSPEED or inst.components.locomotor.walkspeed
	------------------------------------------
	inst:AddComponent("follower")
    ------------------------------------------
    if tuning_values.HEALTH then
        inst:AddComponent("health")
        inst.components.health:SetMaxHealth(tuning_values.HEALTH)
    end
	------------------------------------------
	inst:AddComponent("colouradder")
	inst:AddComponent("colourtweener")
    ------------------------------------------
    inst:AddComponent("buffable")
    inst:AddComponent("debuffable")
    inst:AddComponent("armorbreak_debuff")
    inst:AddComponent("fossilizable")
	inst.components.fossilizable:SetDuration(tuning_values.FOSSIL_TIME)
    if not mob_values.no_sleep then
        inst:AddComponent("sleeper")
    end
    --inst.components.sleeper:SetResistance(3)
    --inst.components.sleeper.testperiod = GetRandomWithVariance(6, 2)
    --inst.components.sleeper:SetSleepTest(ShouldSleep)
    --inst.components.sleeper:SetWakeTest(ShouldWakeUp)
    inst:AddComponent("timelockable")
    ------------------------------------------
    inst:AddComponent("lootdropper")
    --inst.components.lootdropper:SetChanceLootTable('snortoise')
    ------------------------------------------
    inst:AddComponent("inspectable")
    ------------------------------------------
    AddScalerComponent(inst, mob_values.physics)
    ------------------------------------------
    inst:AddComponent("shader_manager")
end

local function AddBasicCombatComponent(inst, tuning_values) -- TODO add default values???
	inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(tuning_values.DAMAGE)
	inst.components.combat:SetRange(tuning_values.ATTACK_RANGE, tuning_values.HIT_RANGE)
    inst.components.combat:SetAttackPeriod(tuning_values.ATTACK_PERIOD)
	inst.components.combat:SetDamageType(TUNING.FORGE.DAMAGETYPES.PHYSICAL) -- TODO parameter? add tuning to each mob? tuning_values.DAMAGE_TYPE?
	inst.components.combat.battlecryinterval = tuning_values.BATTLECRY_CD or 5
    inst.components.combat.battlecryenabled = not tuning_values.DISABLE_BATTLECRY and inst.components.combat.battlecryenabled
end

local function CommonMobPhysicsInit(inst)
	MakeCharacterPhysics(inst, 50, .5)
    inst.DynamicShadow:SetSize(1.75, 0.75)
	inst.Transform:SetScale(0.8, 0.8, 0.8)
    inst.Transform:SetSixFaced()
end
--bank, build, nameoverride, mob_values, tuning_values
local function CommonMobFN(bank, build, mob_values, tuning_values)
    local mob_values = mob_values or {}
    local pristine_fn = mob_values.pristine_fn
    mob_values.pristine_fn = function(inst)
        if mob_values.physics_init_fn then
            mob_values.physics_init_fn(inst)
        else
            CommonMobPhysicsInit(inst)
        end
        ------------------------------------------
        inst.nameoverride = mob_values.name_override --So we don't have to make the describe strings.
        AddTags(inst, "monster", "hostile", "fossilizable")
        ------------------------------------------
        MobTrackerInit(inst)
        ------------------------------------------
        if pristine_fn then
            pristine_fn(inst)
        end
    end
	local inst = MobEntityInit(bank, build, mob_values.anim, mob_values)
    ------------------------------------------
    AddTags(inst, "LA_mob")
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	AddCommonMobComponents(inst, tuning_values, mob_values)
	------------------------------------------
	AddBasicCombatComponent(inst, tuning_values)
    inst.components.combat.playerdamagepercent = 1
	FORGE_TARGETING.Init(inst)
    ------------------------------------------
    inst:DoTaskInTime(0, function(inst) -- Ensure mob is tracked.
        if not inst._registered and not mob_values.no_tracking then
            ForgeMobTrackerInit(inst)
        end
    end)
    ------------------------------------------
    inst.sounds = mob_values.sounds
    inst.anims  = mob_values.anims
    inst.builds = mob_values.builds or {build or bank}
	inst:SetStateGraph(mob_values.stategraph)
    inst.sg.mem.radius = inst.physicsradiusoverride -- used for toggling character collisions
    inst:SetBrain(mob_values.brain)
    ------------------------------------------
    --MakeHauntablePanic(inst)
	--MakeMediumBurnableCharacter(inst, "bod")
	------------------------------------------
    return inst
end

-- Spawns the mob at a given position and starts tracking it for Forge.
-- duplicate: If true or nil then mobs will be duplicated based on the duplicated mutator value.
--     - If no duplication is wanted then you must set it to false.
local function SpawnMob(prefab, pos, round, wave, spawner, duplicate, duplicate_count)
    local mob = SpawnAt(prefab, pos)
    if mob then
        local mobs = mob.GetMobs and mob:GetMobs() or {[mob] = mob}
        local duplicate_mobs = {}
        local mob_count = 0
        for _,spawned_mob in pairs(mobs) do
            mob_count = mob_count + 1
            ForgeMobTrackerInit(spawned_mob, round, wave, spawner)
            TheWorld:PushEvent("on_spawned_mob", {mob = spawned_mob})
            local mob_duplicator = REFORGED_SETTINGS.gameplay.mutators.mob_duplicator
            if (duplicate or duplicate == nil) and mob_duplicator > 1 then
                -- Spawn duplicated mobs
                duplicate_mobs[spawned_mob] = {}
                for i=1,math.ceil(mob_duplicator)-1 do
                    local duplicated_mob = SpawnAt(spawned_mob.prefab, pos)
                    ForgeMobTrackerInit(duplicated_mob, round, wave, spawner)
                    TheWorld:PushEvent("on_spawned_mob", {mob = duplicated_mob})
                    REFORGED_DATA.mutators.mob_duplicator.mutator_fns.apply_server_fn(duplicated_mob, i, spawned_mob)
                    table.insert(duplicate_mobs[spawned_mob], duplicated_mob)
                end
            elseif duplicate_count then
                REFORGED_DATA.mutators.mob_duplicator.mutator_fns.apply_server_fn(mob, duplicate_count)
            end
        end
        return mob_count == 1 and not duplicate and mob or mobs, duplicate_mobs
    else
        Debug:Print("Failed to spawn '" .. tostring(prefab) .. "'. Prefab does not exist.", "error")
    end
end

---------
-- Pet --
---------
local function PetEntityInit(bank, build, anim, opts)
    local options = opts or {
        --anim_loop   = true,
        --noanim     = false,
        --pristine_fn = nil,
    }
    local pristine_fn = options.pristine_fn
    options.pristine_fn = function(inst)
        inst.entity:AddSoundEmitter()
        inst.entity:AddDynamicShadow()
        ------------------------------------------
        if pristine_fn then
            pristine_fn(inst)
        end
    end
    ------------------------------------------
	local inst = BasicEntityInit(bank, build, anim, options)
    ------------------------------------------
	return inst
end

local function PetStatTrackerInit(inst)
	if TheWorld.components.stat_tracker then
		TheWorld.components.stat_tracker:StartTrackingPetStats(inst)
	end
end

local function AddCommonPetComponents(inst, pet_values, tuning_values)
	if not (pet_values and pet_values.sentry) then
		inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
	    inst.components.locomotor.runspeed = tuning_values.RUNSPEED or inst.components.locomotor.runspeed
		inst.components.locomotor.walkspeed = tuning_values.WALKSPEED or inst.components.locomotor.walkspeed
	end
	------------------------------------------
	inst:AddComponent("follower")
	-- baby spiders did not have this, problem?
	inst.components.follower:KeepLeaderOnAttacked() -- TODO make sure the other companions need this
	inst.components.follower.keepdeadleader = true -- TODO make sure the other companions need this
    ------------------------------------------
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(tuning_values.HEALTH)
	------------------------------------------
	if pet_values and pet_values.combat then
		inst:AddComponent("combat")
		inst.components.combat:SetRange(tuning_values.ATTACK_RANGE, tuning_values.HIT_RANGE)
	    inst.components.combat:SetDefaultDamage(tuning_values.DAMAGE)
	    inst.components.combat:SetAttackPeriod(tuning_values.ATTACK_PERIOD)
	    inst.components.combat:SetRetargetFunction(pet_values.retarget_period or 1, pet_values.RetargetFn)
	    inst.components.combat:SetKeepTargetFunction(pet_values.KeepTarget)
	end
    ------------------------------------------
	inst:AddComponent("colouradder")
    ------------------------------------------
    inst:AddComponent("buffable")
    ------------------------------------------
    inst:AddComponent("debuffable") -- baby spiders did not have this, problem?
    ------------------------------------------
    inst:AddComponent("lootdropper")
    ------------------------------------------
    inst:AddComponent("inspectable")
    ------------------------------------------
    AddScalerComponent(inst, pet_values.physics)
    ------------------------------------------
    inst:AddComponent("shader_manager")
    ------------------------------------------
end
--bank, build, anim, nameoverride, pet_values, tuning_values
local function CommonPetFN(bank, build, pet_values, tuning_values)
    local pet_values = pet_values or {}
    local pristine_fn = pet_values.pristine_fn
    pet_values.pristine_fn = function(inst)
        if pet_values.physics_init_fn then
            pet_values.physics_init_fn(inst)
        else
            --CommonPetPhysicsInit(inst) -- TODO is there common physics?
        end
        ------------------------------------------
        inst.nameoverride = pet_values.nameoverride --So we don't have to make the describe strings.
        AddTags(inst, "companion")
        ------------------------------------------
        if pristine_fn then
            pristine_fn(inst)
        end
    end
	local inst = PetEntityInit(bank, build, pet_values.anim, pet_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	AddCommonPetComponents(inst, pet_values, tuning_values)
	------------------------------------------
	inst.sounds = pet_values.sounds
	inst:SetStateGraph(pet_values.stategraph)
    inst:SetBrain(pet_values.brain)
	------------------------------------------
	--AddBasicCombatComponent(inst, tuning_values)
    --inst.components.combat.playerdamagepercent = 1 -- TODO test what this actually does
	------------------------------------------
    --MakeHauntablePanic(inst)
	--MakeMediumBurnableCharacter(inst, "bod") -- TODO can we dictate small, medium, large by size of mob?
	------------------------------------------
    return inst
end

local function NoHoles(pt)
    return not TheWorld.Map:IsGroundTargetBlocked(pt)
end

local function SpawnPet(pet_prefab, amount, player)
    local petleash = player.components.petleash
    if petleash then
        petleash.petprefab = pet_prefab
        petleash.maxpets = petleash.numpets + amount
        local pt = player:GetPosition()
        local radius = 1
        for i=1,amount do
            local theta = (i/amount) * 2 * _G.PI
            local offset = _G.FindWalkableOffset(pt, theta, radius, 3, true, true, NoHoles) or {x = 0, y = 0, z = 0}
            local pet = player.components.petleash:SpawnPetAt(pt.x + offset.x, 0, pt.z + offset.z)
            -- Display pet health badge
            if player and player.components.pethealthbars then
                player.components.pethealthbars:AddPet(pet)
            end
        end
    end
end

------------
-- Summon --
------------
local function Summon(prefab, caster, pos, amount)
    local ent = SpawnPrefab(prefab)
    ent.Transform:SetPosition(pos:Get())
    -- Apply Damage Buffs
    if caster.components.buffable then
        local mults, adds, flats = caster.components.buffable:GetStatBuffs({"spell_dmg"})
        ent.components.combat:AddDamageBuff("spell_dmg_mult", {buff = mults, addtype = "mult"})
        ent.components.combat:AddDamageBuff("spell_dmg_add", {buff = (adds - 1), addtype = "add"})
        ent.components.combat:AddDamageBuff("spell_dmg_flat", {buff = flats, addtype = "flat"})
        if ent.SetCharged then -- TODO do this in golem only or leave here for modders? if so then add to api
            ent:SetCharged(caster.components.buffable:HasBuff("amplify") or mults*adds + flats >= 1.5)
        end
    end
    -- Attach summon to caster
    if caster then
        caster.components.leader:AddFollower(ent)
        if ent.UpdatePetLevel then
            ent:UpdatePetLevel(caster.current_pet_level or 1, true, true)
        end
        ent.components.scaler:SetSource(caster)
    end

    -- Display pet health badge
    if caster and caster.components.pethealthbars then
        caster.components.pethealthbars:AddPet(ent)
    end

    return ent
end

---------------
-- Structure --
---------------
local function StructureEntityInit(bank, build, anim, opts)
    local options = {
        anim        = anim or "idle_loop",
        --anim_loop   = true,
        --noanim     = false,
        pristine_fn = nil,
    }
    MergeTable(options, opts or {}, true)
    local pristine_fn = options.pristine_fn
    options.pristine_fn = function(inst)
        inst.entity:AddSoundEmitter()
        ------------------------------------------
        if pristine_fn then
            pristine_fn(inst)
        end
    end
    ------------------------------------------
    local inst = BasicEntityInit(bank, build, options.anim, options)
    ------------------------------------------
    return inst
end

local function AddCommonStructureComponents(inst, structure_values, tuning_values)
    if tuning_values.HEALTH then
        inst:AddComponent("health")
        inst.components.health:SetMaxHealth(tuning_values.HEALTH)
    end
    ------------------------------------------
    if not structure_values.no_combat then
        inst:AddComponent("combat")
        inst.components.combat:SetOnHit(structure_values.OnHit)
        inst.components.combat:SetDefaultDamage(tuning_values.DAMAGE or 0)
        inst.components.combat:SetRange(tuning_values.ATTACK_RANGE or 0, tuning_values.HIT_RANGE)
        inst.components.combat:SetAttackPeriod(tuning_values.ATTACK_PERIOD or 3)
        inst.components.combat:SetDamageType(TUNING.FORGE.DAMAGETYPES.PHYSICAL)
        inst.components.combat.battlecryinterval = tuning_values.BATTLECRY_CD or 5
        inst.components.combat.battlecryenabled = not tuning_values.DISABLE_BATTLECRY and inst.components.combat.battlecryenabled
        inst.components.combat.playerdamagepercent = 1
        FORGE_TARGETING.Init(inst)
    end
    ------------------------------------------
    inst:AddComponent("inspectable")
end

local function CommonStructurePhysicsInit(inst)
    MakeObstaclePhysics(inst, 1)
    inst.Transform:SetFourFaced()
end
--bank, build, nameoverride, structure_values, tuning_values
local function CommonStructureFN(bank, build, structure_values, tuning_values)
    local structure_values = structure_values or {}
    local tuning_values = tuning_values or {}
    local pristine_fn = structure_values.pristine_fn
    structure_values.pristine_fn = function(inst)
        if structure_values.physics_init_fn then
            structure_values.physics_init_fn(inst)
        else
            --CommonStructuresPhysicsInit(inst)
        end
        ------------------------------------------
        inst.nameoverride = structure_values.name_override -- So we don't have to make the describe strings.
        AddTags(inst, "structure", "nobuff", structure_values.is_wall and "wall" or nil)
        ------------------------------------------
        if pristine_fn then
            pristine_fn(inst)
        end
    end
    local inst = MobEntityInit(bank, build, structure_values.anim, structure_values)
    ------------------------------------------
    AddTags(inst, structure_values.neutral and "neutral" or structure_values.friendly and "companion" or "LA_mob")
    ------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    AddCommonStructureComponents(inst, structure_values, tuning_values)
    ------------------------------------------
    if TheWorld.components.stat_tracker then
        TheWorld.components.stat_tracker:StartTrackingStructureStats(inst)
    end
    ------------------------------------------
    inst.OnCollideDestroy = structure_values.OnCollideDestroy
    ------------------------------------------
    inst.sounds = structure_values.sounds
    if structure_values.stategraph then
        inst:SetStateGraph(structure_values.stategraph)
    end
    if structure_values.brain then
        inst:SetBrain(structure_values.brain)
    end
    ------------------------------------------
    --MakeHauntablePanic(inst)
    --MakeMediumBurnableCharacter(inst, "bod")
    ------------------------------------------
    return inst
end

--------
-- FX --
--------
--bank, build, anim, remove_fn, noanimover, noanim, anim_loop
local function FXEntityInit(bank, build, anim, opts)
    local options = {
        anim = anim,
        --remove_fn  = nil,
        --noanimover = nil,
        --noanim = nil,
        anim_loop = false,
        --pristine_fn = nil,
    }
    MergeTable(options, opts or {}, true)
    local pristine_fn = options.pristine_fn
    options.pristine_fn = function(inst)
        --inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh") -- TODO do all fx use this?
        ------------------------------------------
        AddTags(inst, "FX", "NOCLICK")
        ------------------------------------------
        if pristine_fn then
            pristine_fn(inst)
        end
    end
	local inst = BasicEntityInit(bank, build, options.anim, options)
	------------------------------------------
	--inst.entity:SetPristine() -- Moved to each instance rather than a common function
	------------------------------------------
	if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
    inst:AddComponent("scaler")
    ------------------------------------------
	if not options.noanimover then
		inst:ListenForEvent("animover", options.remove_fn or inst.Remove)
	end
	------------------------------------------
	return inst
end

local function CreateProjectileAnim(bank, build, anim)
    local inst = CreateEntity()
    COMMON_FNS.AddTags(inst, "FX", "NOCLICK")
    --[[Non-networked entity]]
    inst.persists = false
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    ------------------------------------------
    --Leo: We're not sure why Klei left this here, but it seems to break other similar projectiles like waterballoon?
    --Doesn't seem to do anything in general, real weird. If anyone is using this for their own firebomb clone, if your projectile is turning invisible, just disable this.
    --inst.Transform:SetSixFaced()
    ------------------------------------------
    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build or bank)
    inst.AnimState:PlayAnimation(anim, true)
    ------------------------------------------
    return inst
end

---------
-- Map --
---------
local function MapPreInit(inst, map_values)
    REFORGED_SETTINGS.gameplay.map = map_values.name or "lavaarena"
    MapLayerManager:SetSampleStyle(map_values.sample_style or MAP_SAMPLE_STYLE.MARCHING_SQUARES)
end

local function MapPostInit(inst, map_values)
    inst:AddComponent("ambientlighting")
    if map_values.ambient_lighting then
        inst:PushEvent("overrideambientlighting", Point(unpack(map_values.ambient_lighting)))
    end
    ------------------------------------------
    inst:AddComponent("lavaarenamobtracker")
    ------------------------------------------
    -- Dedicated server does not require these components
    -- NOTE: ambient lighting is required by light watchers
    if not TheNet:IsDedicated() then
        inst:AddComponent("ambientsound")
        ------------------------------------------
        inst:AddComponent("colourcube")
        if map_values.colour_cube then
            inst:PushEvent("overridecolourcube",  map_values.colour_cube)
        end
        ------------------------------------------
        inst:ListenForEvent("playeractivated", function(inst, player)
            if ThePlayer == player then
                TheNet:UpdatePlayingWithFriends()
            end
        end)
    end
end

local function FindNextValidSpawnerID(spawners)
    local current_index = 1
    for i,_ in ipairs(spawners) do
        current_index = i
    end
    return current_index
end

local function MapMasterPostInit(inst)
    -- Forge Event Manager
    inst:AddComponent("lavaarenaevent")
    inst:AddComponent("stat_tracker")
    inst:AddComponent("achievement_tracker")
    --inst:AddComponent("wavetracker") -- TODO not used at all? Should we take wave stuff out of lavaarenaevent, move it to wavetracker and then call that?
    ------------------------------------------
    -- Spawn Portal
    ------------------------------------------
    inst:ListenForEvent("ms_register_lavaarenaportal", function(inst, portal)
        inst.multiplayerportal = portal
    end)
    ------------------------------------------
    -- Mob Spawners
    ------------------------------------------
    inst.spawners = {}
    inst:ListenForEvent("ms_register_lavaarenaspawner", function(inst, data)
        local spawner_id = not inst.spawners[data.id] and data.id or FindNextValidSpawnerID(inst.spawners)
        if data.id ~= spawner_id then
            if not data.id then
                Debug:Print("Spawner has no ID and has been assigned the next valid id of " .. tostring(spawner_id) .. ".", "warning")
            elseif inst.spawners[data.id] then
                Debug:Print("Duplicate spawner ID detected. Assigning spawner a new valid id of " .. tostring(spawner_id) .. ".", "warning")
            end
            data.spawner.spawnerid = spawner_id
        end
        inst.spawners[spawner_id] = data.spawner
    end)
    ------------------------------------------
    -- Mob Tracker
    ------------------------------------------
    inst:AddComponent("forgemobtracker")
    local _onstoptrackingold = inst.components.lavaarenamobtracker._onremovemob
    inst.components.lavaarenamobtracker._onremovemob = function(mob)
        _onstoptrackingold(mob)
        inst:PushEvent("ms_lavaarena_mobgone") -- TODO what is this used for? if nothing then this function can be removed
    end
    ------------------------------------------
    -- Load Gametypes
    ------------------------------------------
    local gameplay_settings = _G.REFORGED_SETTINGS.gameplay
    local gametype = gameplay_settings.gametype
    local gametype_data = _G.REFORGED_DATA.gametypes[gametype]
    if gametype_data and gametype_data.fns.enable_server_fn then
        gametype_data.fns.enable_server_fn(inst)
    end
    ------------------------------------------
    local function OnPlayerDied(world, data)
        local self = world.components.lavaarenaevent
        -- End game if all players are dead
        if self.victory == nil and AreAllPlayersDead({[data.userid] = true}) then
            self:End(false)
        -- Let the Forge Lord know a player has died (ex. this will cause pugna to laugh)
        else
            local forge_lord = self:GetForgeLord()
            if forge_lord then
                forge_lord:PushEvent("player_died")
            end
        end
    end
    inst:ListenForEvent("ms_playerdied", OnPlayerDied)
    ------------------------------------------
    local function OnPlayerLeft(world, data)
        local self = world.components.lavaarenaevent
        if #AllPlayers == 0 then -- Reset world if no players are left in the server
            COMMON_FNS.ResetWorld()
        elseif self.start_time > 0 then -- Check if last player alive left the game.
            OnPlayerDied(world, data)
        end
    end
    inst:ListenForEvent("ms_playerleft", OnPlayerLeft)
end

-------------
-- Network --
-------------
local function OnNewCenter(inst)
    local center_str = inst.center_point_str:value()
    local center_pos = ConvertStringToTable(center_str)
    inst.center_pos = center_str and Vector3(center_pos.x, center_pos.y, center_pos.z) or Vector3()
end

local FollowText = require "widgets/followtext"
local DEFAULT_OFFSET = _G.Vector3(0, -400, 0)
local function NetworkSetup(inst)
    -- Total Rounds and Waves
    local function OnWavesetData(inst)
        inst.waveset_data = _G.ConvertStringToTable(inst:GetWavesetData())
    end
    inst._waveset_data = _G.net_string(inst.GUID, "lavaarena_network._waveset_data", "wavesetdata")
    inst.waveset_data = {}
    if not _G.TheNet:IsDedicated() then
        inst:ListenForEvent("wavesetdata", OnWavesetData)
    end
    function inst:SetWavesetData(data)
        local waveset_data = {}
        for i = 1,#data do
            waveset_data[i] = #(data[i].waves)
        end
        inst._waveset_data:set(_G.SerializeTable(waveset_data))
    end
    function inst:GetWavesetData()
        return inst._waveset_data:value()
    end
    function inst:GetTotalRounds()
        return #inst.waveset_data
    end
    function inst:GetTotalWaves(round)
        return inst.waveset_data[round] or 0
    end

    function inst:GetForgeLord()
        return inst.forge_lord
    end

    function inst:SetForgeLord(forge_lord)
        inst.forge_lord = forge_lord
        inst:UpdateForgeLord()
    end

    function inst:UpdateForgeLord(previous_name)
        local current_name = _G.REFORGED_DATA.wavesets[_G.REFORGED_SETTINGS.gameplay.waveset].forge_lord
        local current_forge_lord = _G.GetForgeLord(nil, true)
        local previous_forge_lord = _G.GetForgeLord(previous_name)
        if inst.forge_lord and current_forge_lord and (previous_forge_lord == nil or previous_name ~= current_name) then
            if previous_forge_lord and previous_forge_lord.on_changed_from_fn then
                previous_forge_lord.on_changed_from_fn(inst.forge_lord)
            end
			inst.forge_lord.nameoverride = current_forge_lord.nameoverride or nil
            inst.forge_lord.AnimState:SetBank(current_forge_lord.bank or "boarlord")
            inst.forge_lord.AnimState:SetBuild(current_forge_lord.build or "boarlord")
            inst.forge_lord.AnimState:SetScale(current_forge_lord.scale[1] or -1, current_forge_lord.scale[2] or 1)
			if TheWorld.ismastersim and not TheWorld.net.components.lavaarenaeventstate:IsInProgress() then
				inst.forge_lord:SetStateGraph(current_forge_lord.stategraph or "SGboarlord")
			end            
            inst.forge_lord.avatar = current_forge_lord.avatar
            if current_forge_lord and current_forge_lord.on_changed_to_fn then
                current_forge_lord.on_changed_to_fn(inst.forge_lord)
            end
        end
    end

    inst.admin_talker = _G.SpawnPrefab("reforged_admin_talker")
    function inst:GetAdminTalker()
        return inst.admin_talker
    end

    -- Gameplay Settings Update
    inst.settings_str      = net_string(inst.GUID, "lavaarena_network.gameplay_settings", "updategameplaysettings")
    inst.scripts_str       = net_string(inst.GUID, "lavaarena_network.scripts", "updatescripts")
    inst.chat_announce_str = net_string(inst.GUID, "lavaarena_network.chat_announce", "updatechatannounce")
    inst.center_pos        = inst.center_pos or Vector3(0,0,0)
    inst.center_point_str  = net_string(inst.GUID, "lavaarena_network.center_point_str", "new_center")
    if not _G.TheNet:IsDedicated() then
        inst:ListenForEvent("updategameplaysettings", function(inst, data)
            _G.REFORGED_SETTINGS.gameplay = _G.ConvertStringToTable(inst.settings_str:value())
            inst:UpdateForgeLord()
        end)
        local scripts_text_list = {}
        local function SetScripterHUD(HUD, scripts_text, player)
            if not (HUD and scripts_text and player) then return end
            scripts_text:SetTarget(player)
            for _,healthbar in pairs(HUD.controls.teamstatus.healthbars) do
                if healthbar.userid == player.userid then
                    healthbar.playername:SetColour(_G.unpack(_G.UICOLOURS.RED))
                    break
                end
            end
        end
        inst:ListenForEvent("updatescripts", function(inst, data)
            local HUD = _G.ThePlayer and _G.ThePlayer.HUD
            if not HUD then return end
            local scripts = _G.ConvertStringToTable(inst.scripts_str:value())
            for userid,_ in pairs(scripts) do
                if not scripts_text_list[userid] then
                    for __,player in pairs(_G.AllPlayers) do
                        if player.userid == userid then
                            local scripts_text = HUD:AddChild(FollowText(_G.TALKINGFONT, 35, STRINGS.NAMES.CHEATER))
                            scripts_text.text:SetColour(_G.unpack(_G.UICOLOURS.RED))
                            scripts_text:SetOffset(DEFAULT_OFFSET)
                            SetScripterHUD(HUD, scripts_text, player)
                            scripts_text_list[userid] = scripts_text
                            break
                        end
                    end
                end
            end
        end)
        inst:ListenForEvent("playerentered", function(inst, player)
            local userid = player and player.userid
            if userid and scripts_text_list[userid] then
                scripts_text_list[userid]:Show()
                SetScripterHUD(_G.ThePlayer and _G.ThePlayer.HUD, scripts_text_list[userid], player)
            end
        end, _G.TheWorld)
        inst:ListenForEvent("playerexited", function(inst, player)
            local userid = player and player.userid
            if userid and scripts_text_list[userid] then
                scripts_text_list[userid]:Hide()
            end
        end, _G.TheWorld)
        inst:ListenForEvent("updatechatannounce", function(inst, data)
            _G.Networking_Say(nil, nil, STRINGS.UI.LOBBYSCREEN.SERVER_ANNOUNCEMENT_NAME, nil, inst.chat_announce_str:value(), _G.UICOLOURS.WHITE)
        end)
        inst:ListenForEvent("new_center", OnNewCenter)
    end
    if _G.TheWorld.ismastersim then -- TODO is this still used?
        -- Initialize Gameplay Settings
        inst.settings_str:set(_G.SerializeTable(_G.REFORGED_SETTINGS.gameplay))
        inst.UpdateGameplaySettings = function()
            inst.settings_str:set(_G.SerializeTable(_G.REFORGED_SETTINGS.gameplay))
        end
        inst.scripts_list = {}
        function inst:UpdateScripts(player)
            local userid = player.userid
            if inst.scripts_list[userid] then return end
            inst.scripts_list[userid] = true
            inst.scripts_str:set(_G.SerializeTable(inst.scripts_list))
        end
        function inst:SendChatAnnouncement(message)
            inst.chat_announce_str:set(message)
        end
    end

    inst:AddComponent("worldvoter")

    if _G.TheWorld and _G.TheWorld.ismastersim then
        inst:AddComponent("lobbyvote")
        --inst:AddComponent("leaderboardmanager")
        inst:AddComponent("levelmanager")
        inst:AddComponent("achievementmanager")
        inst:AddComponent("mutatormanager")
        inst:AddComponent("serverinfomanager")
        --inst:AddComponent("fxnetwork")
        inst:AddComponent("perk_tracker")
        inst:AddComponent("command_manager")
        -- Sync Initial Gameplay Settings
        _G.TheWorld:ListenForEvent("ms_clientauthenticationcomplete", function()
            inst:UpdateGameplaySettings()
        end)

        local UserCommands = require "usercommands"
        --Leo: Overwrite /rescue because its not good at its job and is used to break even further oob.
        local rescue_command = UserCommands.GetCommandFromName("rescue")
        rescue_command.serverfn = function(params, caller)
            local pos = caller:GetPosition()
            if not _G.TheWorld.Map:IsPassableAtPoint(pos.x, pos.y, pos.z, true) or _G.TheWorld.Map:IsGroundTargetBlocked(pos) then
                local portal = _G.TheWorld.multiplayerportal
                if portal then
                    caller.Physics:Teleport(portal:GetPosition():Get())
                else
                    _G.COMMON_FNS.ReturnToGround(caller)
                end
            end
        end

        -- Update kleis user commands to support our command manager
        local player_ready_command = UserCommands.GetCommandFromName("playerreadytostart")
        player_ready_command.hasaccessfn = function(command, caller, targetid)
            return _G.COMMON_FNS.CheckCommand("playerreadytostart", caller.userid)
        end
    end
end

local function PostInit(inst)
    inst:LongUpdate(0)
    inst.entity:FlushLocalDirtyNetVars()

    for k, v in pairs(inst.components) do
        if v.OnPostInit ~= nil then
            v:OnPostInit()
        end
    end
end

local function OnRemoveEntity(inst)
    if TheWorld ~= nil then
        assert(TheWorld.net == inst)
        TheWorld.net = nil
    end
end

local function DoPostInit(inst)
    if not TheWorld.ismastersim then
        if TheWorld.isdeactivated then
            --wow what bad timing!
            return
        end
        --master sim would have already done a proper PostInit in loading
        TheWorld:PostInit()
    end
    if not TheNet:IsDedicated() then
        if ThePlayer == nil then
            TheNet:SendResumeRequestToServer(TheNet:GetUserID())
        end
        PlayerHistory:StartListening()
    end
end

local function NetworkInit()
    local inst = CreateEntity()
    ------------------------------------------
    assert(TheWorld ~= nil and TheWorld.net == nil)
    TheWorld.net = inst
    ------------------------------------------
    inst.entity:SetCanSleep(false)
    inst.persists = false
    ------------------------------------------
    inst.entity:AddNetwork()
    inst:AddTag("CLASSIFIED")
    inst.entity:SetPristine()
    ------------------------------------------
    inst:AddComponent("autosaver")
    inst:AddComponent("worldcharacterselectlobby")
    inst:AddComponent("lavaarenaeventstate")
    inst:AddComponent("bgm_manager_reforged")
    ------------------------------------------
    inst.PostInit = PostInit
    inst.OnRemoveEntity = OnRemoveEntity
    ------------------------------------------
    inst:DoTaskInTime(0, DoPostInit)
    ------------------------------------------
    NetworkSetup(inst)
    ------------------------------------------
    return inst
end

----------------------------------------------
-- Boarlord 
----------------------------------------------
-- OnTalk is client side
local Widget = require("widgets/widget")
local Text = require("widgets/text")
local UIAnim = require "widgets/uianim"

local function SpeechRootKillTask(speechroot_inst, inst)
    if inst.speechroot ~= nil then
        if inst.speechroot.inst:IsValid() then
            inst.speechroot:Kill()
        end
        inst.speechroot = nil
    end
end

local function OnTalk(inst, data)
	if data ~= nil and data.message ~= nil and ThePlayer ~= nil and ThePlayer.HUD ~= nil and ThePlayer:IsValid() then
		if inst.speechroot == nil then
			--inst.speech_parent = ThePlayer.HUD.eventannouncer
			--inst.speech_parent:SetPosition(0, -70)
			inst.speechroot = Widget("speech root")
            local settings = {
                bank      = "lavaarena_boarlord_dialogue",
                build     = "lavaarena_boarlord_dialogue",
                anim      = "dialogue_loop",
                font      = UIFONT,
                font_size = 40,
                colour    = {247/255, 165/255, 68/255, 1},
                offset    = Vector3(0,-70,0),
            }
            MergeTable(settings, inst.avatar or {}, true)
			local speech_text = inst.speechroot:AddChild(Text(settings.font, settings.font_size, nil, settings.colour)) -- TALKINGFONT, UIFONT

			local speech_head = inst.speechroot:AddChild(UIAnim())
			speech_head:GetAnimState():SetBuild(settings.build)
			speech_head:GetAnimState():SetBank(settings.bank)
			speech_head:GetAnimState():PushAnimation(settings.anim, true)
			speech_head:SetClickable(false)
			speech_head:SetScale(0.4)

            ThePlayer.HUD:AddTalker(inst.speechroot, settings.offset)
            inst.speechroot:MoveToBack()

			inst.speechroot.SetTint = function(obj, r, g, b, a)
				local cr, cb, cg = unpack(speech_text:GetColour())
				speech_text:SetColour(cr, cb, cg, a)
			end

			inst.speechroot.SetSpeechString = function(s)
				inst.speechroot:SetTint(1, 1, 1, 0)
				inst.speechroot:TintTo({ r=1, g=1, b=1, a=0 }, { r=1, g=1, b=1, a=1 }, .3)

				speech_text:SetString(s)

				local x = speech_text:GetRegionSize()
				speech_head:SetPosition(-.5 * x - 35, 0)
			end

			inst:ListenForEvent("onremove", function()
				if inst.speech_parent ~= nil and inst.speech_parent.inst:IsValid() then
					inst.speech_parent:SetPosition(0, 0)
					inst.speech_parent = nil
				end
                if inst.speechroot ~= nil and ThePlayer ~= nil and ThePlayer.HUD ~= nil then
                    ThePlayer.HUD:RemoveTalker(inst.speechroot)
                end
				inst.speechroot = nil
			end, inst.speechroot.inst)
		end
		if inst.speechroot ~= nil then
			if inst.speechroot.inst.killtask ~= nil then
				inst.speechroot.inst.killtask:Cancel()
				inst.speechroot.inst.killtask = nil
			end

			inst.speechroot.SetSpeechString(data.message)
		end
	elseif inst.speechroot ~= nil and inst.speechroot.inst:IsValid() then
		inst.speechroot.inst.killtask = inst.speechroot.inst:DoTaskInTime(.5, SpeechRootKillTask, inst)
	end
end

local function GetDialogueStrings(inst, str_id, str_tbl)
    local chatter = inst.components.talker.chatter
    -- Get the dialogue
    local string_table = _G.ParseString(str_tbl:value(), ".")
    local dialogue = _G.CheckTable(_G.STRINGS, unpack(string_table))
    -- Load Script
    if dialogue then
        local id = str_id:value()
        dialogue = type(dialogue) == "string" and {dialogue} or dialogue
        local script = {}
        for _,str in pairs(id == 0 and dialogue or {dialogue[id]}) do
            local str_par = chatter.strpar:value()
            local message = str
            -- Load any string parameters
            if str_par ~= "" then
                -- Check if any parameter passed is referencing a string from the string table
                local str_par_tbl = _G.ConvertStringToTable(str_par)
                for i,par in pairs(str_par_tbl) do
                    if type(par) == "string" then
                        local par_tbl = _G.ParseString(par, ".")
                        if #par_tbl > 1 then
                            str_par_tbl[i] = _G.CheckTable(_G.STRINGS, unpack(par_tbl))
                        end
                    else
                        str_par_tbl[i] = tostring(par)
                    end
                end
                message = string.format(str, _G.unpack(str_par_tbl))
            end
            table.insert(script, {message = message, lineduration = chatter.strtime:value(), noanim = chatter.forcetext:value()})
        end
        return script
    end
end

-- Randomly choose an id for the banter
local function GetBanterID(str_tbl)
    local id = 0
    if type(str_tbl) == "string" then
        local string_table = ParseString(str_tbl, ".")
        local dialogue = CheckTable(STRINGS, unpack(string_table))
        id = math.random(#dialogue)
    else
        id = math.random(#str_tbl)
    end
    return id
end

return {
    -- Other
    AddDependenciesToPrefab      = AddDependenciesToPrefab,
	ReturnToGround               = ReturnToGround,
	LaunchItems                  = LaunchItems,
	FindDouble                   = FindDouble,
	SetupBossFade                = SetupBossFade,
    FadeOut                      = FadeOut,
	GetHealingCircle             = GetHealingCircle,
    GetHealAuras                 = GetHealAuras,
	CommonExcludeTags            = CommonExcludeTags,
    GetAllyTags                  = GetAllyTags,
    GetEnemyTags                 = GetEnemyTags,
    GetAllyAndEnemyTags          = GetAllyAndEnemyTags,
    GetPlayerExcludeTags         = GetPlayerExcludeTags,
	SwitchTeamTag				 = SwitchTeamTag,
	GetTeamTag					 = GetTeamTag,
    IsAlly                       = IsAlly,
    IsTargetInRange              = IsTargetInRange,
	DoAOE                        = DoAOE,
    GetTargetsWithinRange        = GetTargetsWithinRange,
    Knockback                    = Knockback,
    KnockbackOnHit               = KnockbackOnHit,
    OnCollideDestroyObject       = OnCollideDestroyObject,
    JumpToPosition               = JumpToPosition,
    SpawnWarningShadow           = SpawnWarningShadow,
    SpawnEntsInCircle            = SpawnEntsInCircle,
    CreateTrail                  = CreateTrail,
    SlamTrail                    = SlamTrail,
    ResetWorld                   = ResetWorld,
    CreateFX                     = CreateFX,
    RemoveFX                     = RemoveFX,
    IsScripter                   = IsScripter,
    AddStateToStategraph         = AddStateToStategraph,
    AddStatesToStategraph        = AddStatesToStategraph,
    ApplyStategraphPostInits     = ApplyStategraphPostInits,
    ForceTaunt                   = ForceTaunt,
    MakeComplexProjectilePhysics = MakeComplexProjectilePhysics,
    SpreadShot                   = SpreadShot,
    DropItem                     = DropItem,
	IsEventActive                = IsEventActive,
    CheckCommand                 = CheckCommand,
    --CreateFXNetwork = CreateFXNetwork,
    -- Entities
	AddTags             = AddTags,
    ApplyMultiBuild     = ApplyMultiBuild,
    ApplyBuild          = ApplyBuild,
    SetBuild            = SetBuild,
    HideSymbols         = HideSymbols,
	BasicEntityInit     = BasicEntityInit,
    LoadDifficulty      = LoadDifficulty,
    LoadMutators        = LoadMutators,
    GetEntityCollisions = GetEntityCollisions,
	-- Mob
	AddSymbolFollowers      = AddSymbolFollowers,
	AddBasicCombatComponent = AddBasicCombatComponent,
	AddCommonMobComponents  = AddCommonMobComponents,
    AddScalerComponent      = AddScalerComponent,
	CommonMobFN             = CommonMobFN,
	MobEntityInit           = MobEntityInit,
    ForgeMobTrackerInit     = ForgeMobTrackerInit,
	MobTrackerInit          = MobTrackerInit,
    GetMobWeight            = GetMobWeight,
    SpawnMob                = SpawnMob,
	-- Pet
	AddCommonPetComponents = AddCommonPetComponents,
	PetStatTrackerInit     = PetStatTrackerInit,
	CommonPetFN            = CommonPetFN,
	PetEntityInit          = PetEntityInit,
    SpawnPet               = SpawnPet,
    -- Structure
    StructureEntityInit          = StructureEntityInit,
    AddCommonStructureComponents = AddCommonStructureComponents,
    CommonStructureFN            = CommonStructureFN,
    -- Summon
    Summon = Summon,
	-- FX
	FXEntityInit         = FXEntityInit,
    CreateProjectileAnim = CreateProjectileAnim,
    -- Map
    MapPreInit        = MapPreInit,
    MapPostInit       = MapPostInit,
    MapMasterPostInit = MapMasterPostInit,
    -- Network
    NetworkInit  = NetworkInit,
    NetworkSetup = NetworkSetup,
	--Boarlord
	OnTalk             = OnTalk,
    GetDialogueStrings = GetDialogueStrings,
    GetBanterID        = GetBanterID,
}
