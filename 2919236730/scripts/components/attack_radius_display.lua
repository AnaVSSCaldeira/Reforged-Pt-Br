local function OnDeath(inst, data)
	inst.components.attack_radius_display:RemoveAllCircles()
end

local AttackRadiusDisplay = Class(function(self, inst)
    self.inst = inst
	self.circles = {}
	self.default_circle_prefab = "reticuleaoe"
	self.default_scale = 1.5
	self.default_radius = 4
	self.default_color = {1,1,1,1}

	self.inst:ListenForEvent("death", OnDeath)
end)

-- Adds a circle that is offset. Useful for attacks that are not centered on the attacker, ie a front aoe attack.
function AttackRadiusDisplay:AddOffsetCircle(name, angle, offset, radius, color, circle_prefab, default_scale, default_radius)
	if self:AddCircle(name, radius, color, circle_prefab, default_scale, default_radius) then
		self:SetCircleOffset(name, offset, angle)
	end
end

-- Adds a circle of the given radius. Optional parameters include a circle_prefab which will have its own default scale and radius that must be given if it does not already match the default circle prefab.
function AttackRadiusDisplay:AddCircle(name, radius, color, circle_prefab, default_scale, default_radius)
	if self.circles[name] then
		Debug:Print("Tried to add an attack radius that already exists!", "error")
		return
	end
	self.circles[name] = SpawnPrefab(circle_prefab or self.default_circle_prefab)
	self.circles[name].entity:SetParent(self.inst.entity)
	self.circles[name]:AddTag("NOCLICK")
	self:SetCircleRadius(name, radius, default_scale, default_radius)
	self:SetCircleColor(name, color)
	return self.circles[name]
end

function AttackRadiusDisplay:GetCircle(name)
	return self.circles[name]
end

function AttackRadiusDisplay:SetCircleOffset(name, offset, angle)
	local circle = self.circles[name]
	if not circle then return end
	local angle = (angle or circle.angle or 0) * DEGREES-- -self.inst.Transform:GetRotation() * DEGREES + (angle or 0)
	local offset = (offset or 3) - self.inst:GetPhysicsRadius(0) -- The offset seems to be off by about 0.5, not sure why.
	local offset_pos = Point(offset * math.cos(angle), 0, offset * math.sin(angle))
	circle.Transform:SetPosition(offset_pos:Get())
	circle.offset = offset
	circle.angle = angle
end

function AttackRadiusDisplay:SetCircleAngle(name, angle)
	if not self.circles[name] then return end
	self:SetCircleOffset(name, nil, angle)
end
--[[
A = 2*pi*r^2
s*pi*r^2 = s*pi*4^2

pi*4^2 = 16*pi
8*pi = sqrt(8)
s*pi*r^2
3^2 = 4^2
3^2/4^2

s = 1.5
r = 4
1.5*pi*4^2 = 1.5*pi*16 = 24*pi
24*pi/1.5 = 16*pi

s*A = pi*r^2
1.5*A = pi*4^2
1.5*A = 16*pi
A = 32/3 * pi
r = sqrt(32/3) = 3.26

(1.5*A) = pi*4^2
s(1.5*A) = pi*3^2
s(pi*4^2) = pi*3^2
s = 3^2/4^2 = radius^2 / default_radius^2

(radius*radius / (default_radius*default_radius)) * default_scale

local angle = -inst.Transform:GetRotation() * DEGREES local offset_dist = 2 local offset_pos = {x = offset_dist * math.cos(angle), y = 0, z = offset_dist * math.sin(angle)}
local target_pos = inst:GetPosition() + offset_pos

local function CreateCircle(inst) local DEFAULT = {ATTEMPTS_TO_FIND_SPAWN = 2,} local total_slots = 20 local dist_from_inst = 3.5 local angle = -inst.Transform:GetRotation() * DEGREES local offset_dist = 2 local offset_pos = {x = offset_dist * math.cos(angle), y = 0, z = offset_dist * math.sin(angle)} local pos = inst:GetPosition() + offset_pos for slot = 1, total_slots, 1 do local item = SpawnPrefab("forginghammer") local offset = FindWalkableOffset(pos, ((slot/total_slots * 360)* PI / 180), dist_from_inst, DEFAULT.ATTEMPTS_TO_FIND_SPAWN, true, true) item.Transform:SetPosition(pos.x + offset.x, pos.y + offset.y, pos.z + offset.z) end end CreateCircle(c_sel())

local total_slots = 20 local angle = -c_sel().Transform:GetRotation() * DEGREES local offset_dist = 2 local offset_pos = {x = offset_dist * math.cos(angle), y = 0, z = offset_dist * math.sin(angle)} local pos = c_sel():GetPosition() + offset_pos for slot = 1, total_slots, 1 do local item = SpawnPrefab("forginghammer") local offset = FindWalkableOffset(pos, ((slot/total_slots * 360)* PI / 180), 3.5, 2, true, true) item.Transform:SetPosition(pos.x + offset.x, pos.y + offset.y, pos.z + offset.z) end

local offset_pos = Point(offset_dist * math.cos(angle), 0, offset_dist * math.sin(angle))
local total_slots = 20 local angle = -c_sel().Transform:GetRotation() * DEGREES local offset_dist = 2 local offset_pos = Point(offset_dist * math.cos(angle), 0, offset_dist * math.sin(angle)) local pos = c_sel():GetPosition() + offset_pos for slot = 1, total_slots, 1 do local item = SpawnPrefab("forginghammer") local offset = FindWalkableOffset(pos, ((slot/total_slots * 360)* PI / 180), 3, 2, true, true) item.Transform:SetPosition(pos.x + offset.x, pos.y + offset.y, pos.z + offset.z) end
--]]
function AttackRadiusDisplay:SetCircleRadius(name, radius, default_scale, default_radius)
	local circle = self.circles[name]
	if not circle then return end
	local default_scale = default_scale or self.default_scale
	local default_radius = default_radius or self.default_radius
	local radius = radius or default_radius
	local current_scale_width, current_scale_height = self.inst.Transform:GetScale()
	--local scale = (radius*radius/(default_radius*default_radius)) * default_scale
	local scale = radius / default_radius * default_scale
	circle.AnimState:SetScale(scale/(current_scale_width*current_scale_width), scale/(current_scale_height*current_scale_height))
	circle.radius = radius
end

function AttackRadiusDisplay:SetCircleColor(name, color)
	local circle = self.circles[name]
	if not circle then return end
	circle.AnimState:SetMultColour(unpack(color or self.default_color))
end

function AttackRadiusDisplay:RemoveCircle(name)
	local circle = self.circles[name]
	if not circle then return end
	circle:Remove()
	self.circles[name] = nil
end

function AttackRadiusDisplay:RemoveAllCircles()
	for name,_ in pairs(self.circles) do
		self:RemoveCircle(name)
	end
end

function AttackRadiusDisplay:SetDefaultCirclePrefab(prefab, scale, radius)
	self.default_circle_prefab = prefab
	self.default_scale = scale
	self.default_radius = radius
end

function AttackRadiusDisplay:OnRemoveFromEntity()
	self.inst:RemoveEventCallback("death", OnDeath)
end

function AttackRadiusDisplay:GetDebugString()
	local circles_str = ""
	for name,circle in pairs(self.circles) do
		circles_str = circles_str .. name .. ": r-" .. tostring(circle.radius or 0) .. ", o-" .. tostring(circle.offset or 0) .. ", a-" .. tostring(circle.angle or 0) .. "; "
	end
	circles_str = string.sub(circles_str, 1, -3)
    return string.format("Circles: %s", circles_str)
end

return AttackRadiusDisplay
