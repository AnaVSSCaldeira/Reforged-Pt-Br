local function OnLaunch(inst)
    local complex_projectile = inst.replica.complexprojectile
    if complex_projectile then
        complex_projectile:Launch(complex_projectile:GetTargetPos(), complex_projectile:GetAttacker())
    end
end

local ComplexProjectile = Class(function(self, inst)
    self.inst      = inst
    self._attacker = net_entity(inst.GUID, "combat._attacker")
    self._gravity  = net_int(inst.GUID, "combat._gravity")
    self._horizontal_speed = net_int(inst.GUID, "combat._horizontal_speed")
    self._high_arc     = net_bool(inst.GUID, "combat._high_arc")
    self._target_pos_x = net_float(inst.GUID, "combat._target_pos_x")
    self._target_pos_y = net_float(inst.GUID, "combat._target_pos_y")
    self._target_pos_z = net_float(inst.GUID, "combat._target_pos_z")
    self._on_launch    = net_bool(inst.GUID, "complexprojectile._on_launch", "onlaunch")
    if not TheNet:IsDedicated() then
        self.inst:ListenForEvent("onlaunch", OnLaunch)
        self.client_projectile = nil
        self.starting_pos  = nil
        self.velocity = Vector3(0, 0, 0)
        self.attacker = nil
        --self.onupdatefn = nil
    end
end)

function ComplexProjectile:GetAttacker()
    return self._attacker:value()
end

function ComplexProjectile:SetAttacker(val)
    self._attacker:set(val)
end

function ComplexProjectile:GetGravity()
    return self._gravity:value()
end

function ComplexProjectile:SetGravity(val)
    self._gravity:set(val)
end

function ComplexProjectile:GetHorizontalSpeed()
    return self._horizontal_speed:value()
end

function ComplexProjectile:SetHorizontalSpeed(val)
    self._horizontal_speed:set(val)
end

function ComplexProjectile:GetHighArc()
    return self._high_arc:value()
end

function ComplexProjectile:SetHighArc(val)
    self._high_arc:set(val)
end

function ComplexProjectile:GetTargetPosX()
    return self._target_pos_x:value()
end

function ComplexProjectile:SetTargetPosX(val)
    self._target_pos_x:set(val)
end

function ComplexProjectile:GetTargetPosY()
    return self._target_pos_y:value()
end

function ComplexProjectile:SetTargetPosY(val)
    self._target_pos_y:set(val)
end

function ComplexProjectile:GetTargetPosZ()
    return self._target_pos_z:value()
end

function ComplexProjectile:SetTargetPosZ(val)
    self._target_pos_z:set(val)
end

function ComplexProjectile:GetTargetPos()
    return Vector3(self:GetTargetPosX(), self:GetTargetPosY(), self:GetTargetPosZ())
end

function ComplexProjectile:GetOnLaunch()
    return self._on_launch:value()
end

function ComplexProjectile:SetOnLaunch(val)
    self._on_launch:set(val)
end

function ComplexProjectile:CalculateTrajectory(startPos, endPos, speed)
    local speedSq = speed * speed
    local g = -self:GetGravity()

    local dx = endPos.x - startPos.x
    local dy = endPos.y - startPos.y
    local dz = endPos.z - startPos.z

    local rangeSq = dx * dx + dz * dz
    local range = math.sqrt(rangeSq)
    local discriminant = speedSq * speedSq - g * (g * rangeSq + 2 * dy * speedSq)
    local angle
    if discriminant >= 0 then
        local discriminantSqrt = math.sqrt(discriminant)
        local gXrange = g * range
        local angleA = math.atan((speedSq - discriminantSqrt) / gXrange)
        local angleB = math.atan((speedSq + discriminantSqrt) / gXrange)
        angle = self:GetHighArc() and math.max(angleA, angleB) or math.min(angleA, angleB)
    else
        --Not enough speed to reach endPos
        angle = 30 * DEGREES
    end

    local cosangleXspeed = math.cos(angle) * speed
    self.velocity.x = cosangleXspeed
    self.velocity.z = 0.0
    self.velocity.y = math.sin(angle) * speed
end

function ComplexProjectile:Launch(target_pos, attacker)
    self.client_projectile = SpawnPrefab(self.inst.prefab)
    self.client_projectile.Transform:SetPosition(attacker:GetClientProjectilePosition(self.inst, attacker):Get())
    local pos = self.client_projectile:GetPosition()

	self.client_projectile:ForceFacePoint(target_pos:Get())

    self:CalculateTrajectory(pos, target_pos, self:GetHorizontalSpeed())
    self.inst:StartUpdatingComponent(self)
end

function ComplexProjectile:Hit(target)
    self.inst:StopUpdatingComponent(self)

    self.client_projectile.Physics:SetMotorVel(0,0,0)
    self.client_projectile.Physics:Stop()
    self.velocity.x, self.velocity.y, self.velocity.z = 0, 0, 0
    self.client_projectile:Remove()
end

function ComplexProjectile:OnUpdate(dt)
    self.client_projectile.Physics:SetMotorVel(self.velocity:Get())
    self.velocity.y = self.velocity.y + (self:GetGravity() * dt)
    if self.velocity.y < 0 then
        local x, y, z = self.client_projectile.Transform:GetWorldPosition()
        if y <= 0.05 then -- a tiny bit above the ground, to account for collision issues
            self:Hit()
        end
    end
end

function ComplexProjectile:OnRemoveFromEntity()
    if self.client_projectile and self.client_projectile:IsValid() then
        self.client_projectile:Remove()
    end
end
ComplexProjectile.OnRemoveEntity = ComplexProjectile.OnRemoveFromEntity

return ComplexProjectile
