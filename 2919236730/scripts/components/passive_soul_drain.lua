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
	need visual indicator?
		souls going to Wortox on hit scaled based on damage dealt?
			0 damage does not create a soul?
		increment damage dealt when soul reaches wortox?
        make fx disabled through performance settings
            only possible if client only?
        make fx client only
            might not be possible
            idea
                make all fx type of stuff set a networked variable that triggers a function that creates the fx
                create something to easily add these types of functions?
--]]
local function OnDamageDealt(inst, data)
	if inst.components.passive_soul_drain then
		inst.components.passive_soul_drain:OnDamageDealt(data.damageresolved, data.is_alt)
	end
end

local function ResetSoulDrain(inst, data)
	if inst.components.passive_soul_drain then
		inst.components.passive_soul_drain:ResetSoulDrain()
	end
end

local PassiveSoulDrain = Class(function(self, player)
    self.debug_mode = false
    self.debug_type = "SoulDrain"
    self.player = player
	self.damage_dealt = 0
	self.damage_threshold = 200
	self.heal_percent = 0.05
    self.heal_range = 10

	self.player:ListenForEvent("onhitother", OnDamageDealt)
	self.player:ListenForEvent("death", ResetSoulDrain)
end)

-- Update the Amplify status every time damage is dealt
function PassiveSoulDrain:OnDamageDealt(damage, is_alt)
	if not is_alt then
		self.damage_dealt = self.damage_dealt + damage
		Debug:Print("DamageUpdate: " .. tostring(self.damage_dealt), "log", self.debug_type, self.debug_mode, true)
		if self.damage_dealt >= self.damage_threshold then
			self:ApplySoulDrain()
		end
	end
end

function PassiveSoulDrain:ApplySoulDrain()
	Debug:Print("Activating Soul Drain...", "log", self.debug_type, self.debug_mode, true)
    local heal_amount = self.damage_dealt * self.heal_percent
    local x, y, z = self.player.Transform:GetWorldPosition()
    local targets = TheSim:FindEntities(x, 0, z, self.heal_range, nil, nil, {"player", "companion"})
    for _,target in ipairs(targets) do
        if target.components.health and not (target.components.health:IsDead() or target.components.health:IsInvincible() or target:HasTag("playerghost")) and
            target.entity:IsVisible() then
            target.components.health:DoDelta(heal_amount, nil, "soul_drain")
            -- Only create fx if the fx does not exist already (possibly from a previous trigger)
            if not target.soul_heal_fx_task then
                target.soul_heal_fx_task = target:DoTaskInTime(.5, function(inst)
                    inst.soul_heal_fx_task = nil
                end)
                local fx = SpawnPrefab("wortox_soul_heal_fx")
                fx.entity:AddFollower():FollowSymbol(target.GUID, target.components.combat.hiteffectsymbol, 0, -50, 0) -- TODO might need to have this be custom based on target.
                fx:Setup(target)
            end
            -- Reset all Soul Drain Passives
            if target.components.passive_soul_drain then
            	target.components.passive_soul_drain:ResetSoulDrain()
            end
        end
    end
	--self:ResetSoulDrain()
end

-- Reset Soul Drain
function PassiveSoulDrain:ResetSoulDrain()
	self.damage_dealt = 0
end

function PassiveSoulDrain:SetDamageThreshold(val)
	self.damage_threshold = val
end

function PassiveSoulDrain:SetHealPercent(val)
	self.heal_percent = val
end

function PassiveSoulDrain:SetHealRange(val)
    self.heal_range = val
end

function PassiveSoulDrain:OnRemoveFromEntity()
	self.player:RemoveEventCallback("onhitother", OnDamageDealt)
	self.player:RemoveEventCallback("death", ResetSoulDrain)
end

function PassiveSoulDrain:GetDebugString()
    return string.format("Damage Dealt: %.1d", self.damage_dealt)
end

return PassiveSoulDrain
