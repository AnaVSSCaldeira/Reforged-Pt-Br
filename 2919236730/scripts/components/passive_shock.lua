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
--[[
TODO
	boarriors smash might trigger shock on boarrior, need to make sure this does not happen
--]]
local function OnAttacked(inst, data)
	inst.components.passive_shock:ShockCheck(data.weapon, data.attacker)
end

local function OnDeath(inst, data)
	inst.components.passive_shock:RemoveShock()
end

local PassiveShock = Class(function(self, player)
    self.debug_mode = false
    self.debug_type = "Shock"
    self.player = player
	self.damage = 30--/TUNING.ELECTRIC_DAMAGE_MULT used to be used for removing kleis shock mult
	self.shock = false
	self.on_cooldown = false
	self.cooldown_time = 1
	self.duration = 0.1 -- TODO this might need to be increased to 0.2, hard to check that in vid (With the 50% electric stimuli buff, WX will deal 50 damage)
	self.hit_count = 0
	self.hit_count_trigger = 4
	self.shocked_targets = {}

	self.player:ListenForEvent("attacked", OnAttacked)
	self.player:ListenForEvent("death", OnDeath)
end)

-- Update and check the status of Shock
function PassiveShock:ShockCheck(weapon, attacker)
	-- Only check if attacked when Shock is not active and not on cooldown
	if not self.shock and not self.on_cooldown then
		-- Add current hit
		self.hit_count = self.hit_count + 1
		Debug:Print(tostring(self.player.name) .. " (" .. tostring(self.player.userid) .. ") hit by " .. tostring(attacker) .. ", current hit count: " .. tostring(self.hit_count), "log", self.debug_type, self.debug_mode, true)

		-- Check for Shock trigger
		if self.hit_count >= self.hit_count_trigger then
			self:ApplyShock()
			self:Shock(attacker, weapon)
		end
	elseif self.shock then
		self:Shock(attacker, weapon)
	end
end

function PassiveShock:ApplyShock()
	self.shock = true
	self.on_cooldown = true
	self.shock_timer = self.player:DoTaskInTime(self.duration, function()
		self:RemoveShock()
		self.shock_timer = nil
	end)
	self.cooldown_timer = self.player:DoTaskInTime(self.cooldown_time, function()
		self.on_cooldown = false
		self.cooldown_timer = nil
	end)
end

-- Shock the attacker
function PassiveShock:Shock(attacker, weapon)
	-- Don't do anything if the source of damage is a projectile
	if attacker and attacker ~= self.player and not self.shocked_targets[attacker] and not (weapon and (weapon.components.projectile or weapon.components.complexprojectile or (weapon.components.weapon and weapon.components.weapon:CanRangedAttack()))) then
		--local add, mult = self.player.components.combat:GetBuffMults(false, self.player, attacker, nil, "electric")
		COMMON_FNS.CreateFX("forge_electrocute_fx", attacker)
		self.player.components.combat:DoSpecialAttack(self.damage, attacker, "electric", nil, nil, TUNING.FORGE.DAMAGETYPES.PHYSICAL)
		--attacker.components.combat:GetAttacked(self.player, self.damage * (mult + add), nil, "electric")
		--self.player.components.bloomer:PushBloom("electrocute", "shaders/anim.ksh", -2)
		--self.player.Light:Enable(true)
		self.shocked_targets[attacker] = true -- Can only shock a target once per shock.
	end
end

function PassiveShock:RemoveShock()
	self.shock = false
	self.hit_count = 0
	self.shocked_targets = {}
end

function PassiveShock:OnRemoveFromEntity()
	RemoveTask(self.shock_timer)
	RemoveTask(self.cooldown_timer)
	self.player:RemoveEventCallback("attacked", OnAttacked)
	self.player:RemoveEventCallback("death", OnDeath)
end

function PassiveShock:GetDebugString()
    return string.format("Status: %s, Hit Count: %d, (duration:%2.2f, cooldown:%2.2f)", tostring(self.shock), self.hit_count, self.shock_timer and GetTaskRemaining(self.shock_timer) or 0, self.cooldown_timer and GetTaskRemaining(self.cooldown_timer) or 0)
end

return PassiveShock
