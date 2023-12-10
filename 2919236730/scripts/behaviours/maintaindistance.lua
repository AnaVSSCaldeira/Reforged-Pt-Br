MaintainDistance = Class(BehaviourNode, function(self, inst, find_avoidance_object_fn, min_distance, max_distance, on_within_distance_fn)
    BehaviourNode._ctor(self, "MaintainDistance")
    self.inst = inst
    self.min_distance = min_distance or 6
    self.max_distance = max_distance or 8
    self.find_avoidance_object_fn = find_avoidance_object_fn
    self.on_within_distance_fn = on_within_distance_fn
end)

function MaintainDistance:__tostring()
    return string.format("target %s", tostring(self.inst.components.combat.target))
end

function MaintainDistance:OnStop()

end

-- Checks if entity is within the distance parameters of the avoided object.
-- Returns a "is_within_distance" boolean and a offset based on whether or not the entity is too far or too close.
function MaintainDistance:CheckDistance(distance_to_avoided_object_sq) -- TODO include physics radius???
    local buffer_distance = math.max(self.inst:GetPhysicsRadius(0), 0.15) -- 0.15 is ARRIVE_STEP from locomotor
    local min_distance = self.min_distance - buffer_distance
    local max_distance = self.max_distance + buffer_distance
    if distance_to_avoided_object_sq > max_distance * max_distance then -- TODO + physics radius???
        return false, self.max_distance -- TODO + physics radius???
    elseif distance_to_avoided_object_sq < min_distance * min_distance then -- TODO + physics radius???
        return false, self.min_distance -- TODO + physics radius???
    else
        return true
    end
end

function MaintainDistance:Visit()
    if self.status == READY then
        if self.find_avoidance_object_fn(self.inst) then
            self.status = RUNNING
        else
            self.status = FAILED
        end
    end

    if self.status == RUNNING then
        local avoided_object = self.find_avoidance_object_fn(self.inst)
        if not avoided_object then
            self.status = FAILED
            self.inst.components.locomotor:Stop()
        else
            local current_pos = self.inst:GetPosition()
            local avoided_object_pos = avoided_object:GetPosition()
            -- local dist = distsq(c_sel():GetPosition(), Point(9.5,0,-9.47)) print(tostring(dist))
            -- local dist = distsq(Point(9.5,0,-3.57), Point(9.5,0,-9.47)) print(tostring(dist))
            -- print("offset test") local angle = c_sel():GetAngleToPoint(Point(9.5,0,-9.47)) * DEGREES local offset_pos = Point(6*math.cos(angle),0,6*math.sin(angle)) print(tostring(Point(9.5,0,-9.47) + offset_pos))
            local distance_to_avoided_object_sq = distsq(current_pos, avoided_object_pos)
            local is_within_distance, offset = self:CheckDistance(distance_to_avoided_object_sq)

            if is_within_distance then
                self.inst.components.locomotor:Stop()
                if self.on_within_distance_fn(self.inst) then
                    self.status = SUCCESS
                end
            else
                local angle_to_avoided_object = self.inst:GetAngleToPoint(avoided_object_pos) * DEGREES -- TODO maybe have the ent face away from the avoided object and tell it to move forward? just seems like this current method is not causing them to run away perfectly.
                local offset_pos = Point(offset * math.cos(angle_to_avoided_object), 0, offset * math.sin(angle_to_avoided_object))
                local target_pos = avoided_object_pos + offset_pos
                self.inst.components.locomotor:GoToPoint(avoided_object_pos + offset_pos, nil, true) -- TODO locomotor uses ARRIVE_STEP to prevent moving to a point that is closer than a step. This can cause an infinite loop of the bros standing still because they are not within the distance due to being within an ARRIVE_STEP of the given point
            end
        end
    end
end
--[[
local angle = (c_sel():GetAngleToPoint(ThePlayer:GetPosition()) + 180)*DEGREES local offset_pos = Point(6*math.cos(angle), 0, 6*math.sin(angle)) print("offset:"..tostring(offset_pos)) local target_pos = c_sel():GetPosition() + offset_pos print("Target:"..tostring(target_pos)) ThePlayer.components.locomotor:GoToPoint(target_pos, nil, true)
print(tostring(Point(-1,-2,-3) + ThePlayer:GetPosition())

0,0
1,0 => 6,0

--]]
