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
local AOEWeapon_Lunge = Class(function(self, inst)
    self.inst = inst
	self.width = 3
	self.damage = nil
	self.stimuli = nil
	self.onlunge = nil
end)

function AOEWeapon_Lunge:SetWidth(width)
	self.width = width
end

--[[function AOEWeapon_Lunge:SetDamage(damage)
	self.damage = damage
end]]

function AOEWeapon_Lunge:SetStimuli(stimuli)
	self.stimuli = stimuli
end

function AOEWeapon_Lunge:SetOnLungeFn(fn)
	self.onlunge = fn
end

function AOEWeapon_Lunge:DoLunge(lunger, starting_pos, target_pos)
	local mob_index = {}
	local targets = {}
	local total_steps = 10
	local scale = lunger and lunger.components.scaler and lunger.components.scaler.scale or 1
	local dist_per_step = 0.6 * scale
	local total_distance = math.sqrt(distsq(starting_pos, target_pos))--10-- * scale
	local offset_vector = (target_pos - starting_pos):GetNormalized()
	local count = 1
	while(count * dist_per_step <= total_distance) do
		local offset = offset_vector * count * dist_per_step
		local current_pos = starting_pos + offset
		local lunge_fx = COMMON_FNS.CreateFX("spear_gungnir_lungefx", nil, lunger)
		lunge_fx.Transform:SetPosition(current_pos:Get())
		COMMON_FNS.EQUIPMENT.GetAOETargets(lunger, current_pos, self.width/2 * scale, nil, COMMON_FNS.GetPlayerExcludeTags(lunger), targets, mob_index, true)
		count = count + 1
	end
	if self.inst.components.weapon and self.inst.components.weapon:HasAltAttack() then
		self.inst.components.weapon:DoAltAttack(lunger, targets, nil, self.stimuli)
	end

	if self.onlunge ~= nil then self.onlunge(self.inst, lunger, starting_pos, target_pos) end
	return true
end

return AOEWeapon_Lunge
