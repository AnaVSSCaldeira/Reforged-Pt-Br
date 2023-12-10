local boarilla_sg = deepcopy(require "stategraphs/SGboarilla")
boarilla_sg.name = "boarilla_hard"
local tuning_values = TUNING.FORGE.BOARILLA

----------------
-- Super Slam -- Triggers a seismic event when slamming the ground.
----------------
local SPAWN_DISTANCE_FROM_EDGE = 3
local SPAWN_DISTANCE_FROM_BLOCKER = 5
local function SpawnGroundTrailCondition(inst, offset)
    local pos = inst:GetPosition() + (offset or _G.Point(0,0,0))
    return not (_G.TheWorld.Map:GetNearestPointOnWater(pos.x, pos.z, SPAWN_DISTANCE_FROM_EDGE, 1) or _G.TheWorld.Map:IsGroundTargetBlocked(pos, SPAWN_DISTANCE_FROM_EDGE))
end
--print(tostring(TheWorld.Map:IsGroundTargetBlocked(ThePlayer:GetPosition(), 5)))
local FISSURE_RADIUS = TUNING.ANTLION_SINKHOLE.UNEVENGROUND_RADIUS
local function ReplaceExistingFissures(pos)
    for _,ent in pairs(TheSim:FindEntities(pos.x, 0, pos.z, FISSURE_RADIUS, {"antlion_sinkhole"})) do
        ent:Remove()
    end
end
local MAX_RADIUS_CHECK = 5
local function FindValidLocationForFissure(inst)
    if SpawnGroundTrailCondition(inst) then
        return Point(0,0,0)
    else
        local increment = 0.5
        local radius = increment
        local offset
        while not offset and radius <= MAX_RADIUS_CHECK do
            offset = FindValidPositionByFan((inst.Transform:GetRotation() + 180) * _G.DEGREES, radius, nil, function(offset) return SpawnGroundTrailCondition(inst, offset) end)
            radius = radius + increment
            if offset then
                return offset
            end
        end
    end
end

local attack_slam_state = boarilla_sg.states.attack_slam
local _oldDamageFN = attack_slam_state.timeline[5].fn
attack_slam_state.timeline[5].fn = function(inst)
    local fissure_offset = FindValidLocationForFissure(inst)
    if fissure_offset then
        local pos = inst:GetPosition() + fissure_offset
        ReplaceExistingFissures(pos)
        local crater = SpawnPrefab("fissure")
        crater.Transform:SetPosition(pos:Get())
        local fx = SpawnPrefab("groundpound_fx")
        fx.Transform:SetPosition(pos:Get())
        local ring_fx = SpawnPrefab("groundpoundring_fx")
        ring_fx.Transform:SetPosition(pos:Get())
    end
    _oldDamageFN(inst)
end
local function GroundTrailCondition(inst)
    return inst.sg.currentstate.name == "attack_roll_loop"
end

local function StopGroundTrail(inst)
    inst:StopTrail()
    inst.roll_trail_thread = nil
    --[[
    -- Remove Small Obstacle Collision
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.GIANTS)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)--]]
end
local ground_trail_opts = {{
    min_scale = 1.8,
    max_scale = 2.2,
    threshold = 0,
    duration = 10,
}}
local attack_roll_loop_state = boarilla_sg.states.attack_roll_loop
local _oldOnEnter = attack_roll_loop_state.onenter
attack_roll_loop_state.onenter = function(inst, data)
    _oldOnEnter(inst, data)
    --[[
    -- Remove Small Obstacle Collision, but keep Character Collision off
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.GIANTS)--]]
    if not inst.trail_task then
        _G.COMMON_FNS.CreateTrail(inst, "ground_trail", 1, ground_trail_opts, 0.2, SpawnGroundTrailCondition)
        --(inst, id, initial_delay, period, condition_fn, task_fn, onexit_fn, data)
        if not inst.roll_trail_thread then
            inst.roll_trail_thread = CreateConditionThread(inst, "attack_roll_ground_trails", 0, 0.1, GroundTrailCondition, function() end, StopGroundTrail)
        end
    end

end
local _oldOnExit = attack_roll_loop_state.onexit
attack_roll_loop_state.onexit = function(inst, data)
    _oldOnExit(inst, data)
end
--attack_roll_loop_state.events.onattackother = nil--EventHandler("onattackother", function(inst) end)

COMMON_FNS.ApplyStategraphPostInits(boarilla_sg)
return boarilla_sg
