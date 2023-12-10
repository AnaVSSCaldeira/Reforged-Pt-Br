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
local SHADOW_DISTANCE = 5
local MAX_SHADOW_SPAWN = 5
local angle_per_shadow = 2*math.pi/MAX_SHADOW_SPAWN
local SPAWN_DELAY = 0.1

local function OnHitOther(inst, data)
	if not (data.weapon and data.weapon.components.aoespell and data.weapon.components.aoespell.casting) then
		inst.components.passive_shadows:OnDamageDealt(data.target, data.damageresolved)
	else
		inst.components.passive_shadows:UpdateTarget(data.target)
	end
end

local function OnDeath(inst, data)
	inst.components.passive_shadows:UpdateTarget()
end

local function GenerateOffsets()
	local offsets = {}
	for i=1, MAX_SHADOW_SPAWN, 1 do
		local angle = angle_per_shadow * i * 2 -- mutliplying by 2 gives it the star pattern
		offsets[i] = Vector3(SHADOW_DISTANCE * math.sin(angle), 0, SHADOW_DISTANCE * math.cos(angle))
	end
	return offsets
end

local PassiveShadows = Class(function(self, player)
	self.debug_mode = false
	self.debug_type = "Shadows"
    self.player = player
	self.damage_threshold = 380
	self.damage_dealt = 0
	self.current_target = nil
	self.offsets = GenerateOffsets()

	self.player:ListenForEvent("onhitother", OnHitOther)
	self.player:ListenForEvent("death", OnDeath)
end)

function PassiveShadows:UpdateTarget(target)
	-- Reset damage if new target
	if not target or target ~= self.current_target then
		self.current_target = target or self.current_target
		self.damage_dealt = 0
	end
end

-- Update the Shadows status every time damage is dealt
function PassiveShadows:OnDamageDealt(target, damage)
	self:UpdateTarget(target)
	self.damage_dealt = self.damage_dealt + (damage or 0)
	Debug:Print("DamageUpdate: " .. tostring(self.damage_dealt), "log", self.debug_type, self.debug_mode, true)
	-- Shadows trigger check
	if self.damage_dealt >= self.damage_threshold then
		self:ApplyShadows()
	end
end

-- Attack the current target with Shadows
function PassiveShadows:ApplyShadows()
	Debug:Print("Attacking with Shadows...", "log", self.debug_type, self.debug_mode, true)
	self.damage_dealt = 0
	if self.current_target then
		for i=1, MAX_SHADOW_SPAWN do
			self.player:DoTaskInTime(SPAWN_DELAY*i, function()
				local shadow_fx = SpawnPrefab("passive_shadow_fx")
				shadow_fx:SetOwner(self.player)
				shadow_fx:SetTarget(self.current_target, self.offsets[i])
			end)
		end
	end
end

function PassiveShadows:SetDamageThreshold(val)
	self.damage_threshold = val
end

function PassiveShadows:SetMaxShadows(val)
	MAX_SHADOW_SPAWN = val
	angle_per_shadow = 2*math.pi/MAX_SHADOW_SPAWN
	self.offsets = GenerateOffsets()
end

function PassiveShadows:SetShadowDistance(val)
	SHADOW_DISTANCE = val
	self.offsets = GenerateOffsets()
end

function PassiveShadows:SetSpawnDelay(val)
	SPAWN_DELAY = val
end

function PassiveShadows:OnRemoveFromEntity()
	self.player:RemoveEventCallback("onhitother", OnHitOther)
	self.player:RemoveEventCallback("death", OnDeath)
end

function PassiveShadows:GetDebugString()
    return string.format("Target: %s, Damage Dealt: %d", tostring(self.current_target), self.damage_dealt)
end

return PassiveShadows
