--[[
Copyright (C) 2018 Forged Forge

This file is part of Forged Forge.

The source code of this program is shared under the RECEX
SHARED SOURCE LICENSE (version 1.0).
The source code is shared for referrence and academic purposes
with the hope that people can read and learn from it. This is not
Free and Open Source software, and code is not redistributable
without permission of the author. Read the RECEX SHARED
SOURCE LICENSE for details
The source codes does not come with any warranty including
the implied warranty of merchandise.
You should have received a copy of the RECEX SHARED SOURCE
LICENSE in the form of a LICENSE file in the root of the source
directory. If not, please refer to
<https://raw.githubusercontent.com/Recex/Licenses/master/SharedSourceLicense/LICENSE.txt>
]]

--TODO: Make this work as a main attack as well as an alt attack
local AimedProjectile = Class(function(self, inst)
    self.inst = inst
	self.hitdist = 1
	self.range = 10
	self.speed = 20
	self.damage = nil
	self.stimuli = nil
	self.onthrown = nil
    self.onhit = nil
    self.onmiss = nil
end)

function AimedProjectile:SetHitDistance(hitdist) --Range from the projectile to the target
	self.hitdist = hitdist
end

function AimedProjectile:SetRange(range)
	self.range = range
end

function AimedProjectile:SetSpeed(speed)
	self.speed = speed
end

function AimedProjectile:SetDamage(damage)
	self.damage = damage
end

function AimedProjectile:SetStimuli(stimuli)
	self.stimuli = stimuli
end

function AimedProjectile:SetOnThrownFn(fn)
    self.onthrown = fn
end

function AimedProjectile:SetOnHitFn(fn)
    self.onhit = fn
end

function AimedProjectile:SetOnMissFn(fn)
    self.onmiss = fn
end

function AimedProjectile:RotateToTarget(dest)
    local direction = (dest - self.inst:GetPosition()):GetNormalized()
    local angle = math.acos(direction:Dot(Vector3(1, 0, 0))) / DEGREES
    self.inst.Transform:SetRotation(angle)
    self.inst:FacePoint(dest)
end

function AimedProjectile:Throw(owner, attacker, targetpos)
	self.owner = owner
	self.attacker = attacker
	self.start = owner:GetPosition()
	self.dest = targetpos

	if attacker ~= nil and self.launchoffset ~= nil then
		local x, y, z = self.inst.Transform:GetWorldPosition()
		local facing_angle = attacker.Transform:GetRotation() * DEGREES
		self.inst.Transform:SetPosition(x + self.launchoffset.x * math.cos(facing_angle), y + self.launchoffset.y, z - self.launchoffset.x * math.sin(facing_angle))
	end

	self:RotateToTarget(self.dest)
	self.inst.Physics:SetMotorVel(self.speed, 0, 0)
	self.inst:StartUpdatingComponent(self)
	self.inst:PushEvent("onthrown", { thrower = attacker })
	if self.onthrown ~= nil then
		self.onthrown(self.inst, owner, attacker, targetpos)
	end
end

function AimedProjectile:Stop()
    self.inst:StopUpdatingComponent(self)
    self.target = nil
	self.attacker = nil
    self.owner = nil
end

function AimedProjectile:Miss()
    if self.onmiss ~= nil then
        self.onmiss(self.inst, self.owner, self.attacker)
    end
	self:Stop()
end

function AimedProjectile:Hit(target)
	self.inst.Physics:Stop()
    --if self.attacker ~= nil and self.attacker.components.combat ~= nil then
		--self.attacker.components.combat:DoAttack(target, self.owner, self.inst, self.stimuli, nil, self.damage, true)
    --end
	if self.attacker and self.owner and self.owner.components.weapon then
		self.owner.components.weapon:DoAltAttack(self.attacker, target, nil, self.stimuli)
	end
    if self.onhit ~= nil then
        self.onhit(self.inst, self.owner, self.attacker, target)
    end
	self:Stop()
end

function AimedProjectile:OnUpdate(dt)
	local current = self.inst:GetPosition()
	if self.range ~= nil and distsq(self.start, current) > self.range * self.range then
		self:Miss()
	else
		local validtargets = {}
		local target = nil
		local x, y, z = current:Get()
		local ents = TheSim:FindEntities(x, y, z, 3, nil, COMMON_FNS.GetPlayerExcludeTags(self.attacker))
		for _,ent in ipairs(ents) do
			if ent.entity:IsValid() and ent.entity:IsVisible() and ent.components.health and not ent.components.health:IsDead() then
				local hitrange = ent:GetPhysicsRadius(0) + self.hitdist
				local currentrange = distsq(current, ent:GetPosition())
				if hitrange > currentrange then table.insert(validtargets, {target = ent, hitrange = hitrange, currentrange = currentrange}) end
			end
		end
		for _,data in pairs(validtargets) do
			if target == nil or data.currentrange - data.hitrange < target.range then
				target = {ent = data.target, range = data.currentrange - data.hitrange}
			end
		end
		if target ~= nil then
			self:Hit(target.ent)
		end
	end
end

local function OnShow(inst, self)
    self.delaytask = nil
    inst:Show()
end

function AimedProjectile:DelayVisibility(duration)
    if self.delaytask ~= nil then
        self.delaytask:Cancel()
    end
    self.inst:Hide()
    self.delaytask = self.inst:DoTaskInTime(duration, OnShow, self)
end

return AimedProjectile
