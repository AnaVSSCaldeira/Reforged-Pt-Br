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
local function OnDamageDealt(inst, data)
	if inst.components.passive_amplify then
		inst.components.passive_amplify:OnDamageDealt(data.damageresolved, data.is_alt)
	end
end

local function RemoveAmplify(inst, data)
	local amplify = inst.components.passive_amplify
	if amplify and (amplify.active or amplify.player.components.health:IsDead()) then
		inst.components.passive_amplify:RemoveAmplify()
	end
end

local function OnDisconnect(inst, data) -- TODO is this only called for this player or if a different player disconnects as well?
	if inst.components.passive_amplify and inst.userid == data.userid then
		inst.components.passive_amplify:RemoveAmplify()
	end
end

local PassiveAmplify = Class(function(self, player)
	self.debug_mode = false
	self.debug_type = "Amplify"
    self.player = player
	self.active = false
	self.damage_dealt = 0
	self.damage_threshold = 200
	self.spell_dmg_mult = 1.5
	self.spell_heal_rate = 1.5
	self.spell_duration_mult = 1.5

	self.player:ListenForEvent("onhitother", OnDamageDealt)
	self.player:ListenForEvent("spell_complete", RemoveAmplify)
	self.player:ListenForEvent("death", RemoveAmplify)
	self.player:ListenForEvent("ms_clientdisconnected", OnDisconnect)-- TODO ??? , TheWorld) -- TODO this is a world event, so never called on player, need to see if disconnect is needed
end)

-- Update the Amplify status every time damage is dealt
function PassiveAmplify:OnDamageDealt(damage, is_alt)
	if not self.active and not is_alt then
		self.damage_dealt = self.damage_dealt + damage
		Debug:Print("DamageUpdate: " .. tostring(self.damage_dealt), "log", self.debug_type, self.debug_mode, true)
		if self.damage_dealt >= self.damage_threshold then
			self:ApplyAmplify()
		end
	end
end

-- Apply Amplify
local function SetDirty(netvar, val)
	netvar:set_local(val)
	netvar:set(val)
end

function PassiveAmplify:ApplyAmplify()
	if not self.active then
		Debug:Print("Applying Amplify...", "log", self.debug_type, self.debug_mode, true)
		self.active = true

		-- Add Buff
		if self.player.components.buffable then
			self.player.components.buffable:AddBuff("amplify", {
				{name = "spell_dmg", val = self.spell_dmg_mult, type = "mult"},-- TODO this is for golem buff atm, need to find a better way of handling this
				{name = "spell_heal_rate", val = self.spell_heal_rate, type = "mult"},
				{name = "spell_duration", val = self.spell_duration_mult, type = "mult"}
			})
			self.player.components.combat:AddDamageBuff("amplify", {buff = function(attacker, victim, weapon, stimuli)
				return weapon and weapon.components.aoespell and weapon.components.aoespell.casting and self.spell_dmg_mult or 1
			end}, false)
		end

		self.fx = COMMON_FNS.CreateFX("amplify_fx", self.player)

		if self.player.player_classified then
			SetDirty(self.player.player_classified.net_buffs, json.encode({name = "wick_buff", removed = false}))
		end
	end
end

-- Remove Amplify and reset it
function PassiveAmplify:RemoveAmplify()
	if self.active then
		Debug:Print("Removing Amplify...", "log", self.debug_type, self.debug_mode, true)
		COMMON_FNS.RemoveFX(self.fx)
		self.fx = nil
		if self.player.components.buffable then
			self.player.components.buffable:RemoveBuff("amplify")
			self.player.components.combat:RemoveDamageBuff("amplify")
		end
		if self.player.player_classified then
			SetDirty(self.player.player_classified.net_buffs, json.encode({name = "wick_buff", removed = true}))
		end
	end
	self.active = false
	self.damage_dealt = 0
end

function PassiveAmplify:SetDamageThreshold(val)
	self.damage_threshold = val
end

function PassiveAmplify:SetSpellDamageMult(val)
	self.spell_dmg_mult = val
end

function PassiveAmplify:SetSpellDurationMult(val)
	self.spell_duration_mult = val
end

function PassiveAmplify:SetSpellHealRate(val)
	self.spell_heal_rate = val
end

function PassiveAmplify:OnRemoveFromEntity()
	self:RemoveAmplify()
	self.player:RemoveEventCallback("onhitother", OnDamageDealt)
	self.player:RemoveEventCallback("spellcomplete", RemoveAmplify)
	self.player:RemoveEventCallback("death", RemoveAmplify)
	self.player:RemoveEventCallback("ms_clientdisconnected", OnDisconnect)
end

function PassiveAmplify:GetDebugString()
    return string.format("Status: %s, Damage Dealt: %.1d", tostring(self.active), self.damage_dealt)
end

return PassiveAmplify
