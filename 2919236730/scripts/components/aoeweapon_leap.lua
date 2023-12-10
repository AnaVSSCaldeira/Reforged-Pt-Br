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
local AOEWeapon_Leap = Class(function(self, inst)
    self.inst = inst
	self.radius = 4
	self.damage = nil
	self.stimuli = nil
	self.onleap = nil
end)

function AOEWeapon_Leap:SetRange(radius)
	self.radius = radius
end

--[[function AOEWeapon_Leap:SetDamage(damage)
	self.damage = damage
end]]

function AOEWeapon_Leap:SetStimuli(stimuli)
	self.stimuli = stimuli
end

function AOEWeapon_Leap:SetOnLeapFn(fn)
	self.onleap = fn
end
--Debug:PrintTable(COMMON_FNS.EQUIPMENT.GetAOETargets(ThePlayer, ThePlayer:GetPosition(), 4, {"shockable"}, COMMON_FNS.GetEnemyTags(ThePlayer), nil, nil, nil, true))
function AOEWeapon_Leap:DoLeap(leaper, startingpos, targetpos)
	local scale = leaper.components.scaler and leaper.components.scaler.scale or 1
	local targets = COMMON_FNS.EQUIPMENT.GetAOETargets(leaper, targetpos, self.radius*scale, nil, COMMON_FNS.GetPlayerExcludeTags(leaper))
	--[[if self.stimuli == "electric" and not REFORGED_SETTINGS.gameplay.mutators.friendly_fire then
		local shockable_targets = COMMON_FNS.EQUIPMENT.GetAOETargets(leaper, targetpos, self.radius*scale, {"shockable"}, COMMON_FNS.GetEnemyTags(leaper), nil, nil, nil, true)
		for _,target in pairs(shockable_targets) do
			leaper.components.combat:DoAttack(target, self.inst, nil, self.stimuli, nil, nil, true)
		end
	end--]]
	if self.inst.components.weapon and self.inst.components.weapon:HasAltAttack() then
		self.inst.components.weapon:DoAltAttack(leaper, targets, nil, self.stimuli)
	end

	if self.onleap then self.onleap(self.inst, leaper, startingpos, targetpos) end
end

return AOEWeapon_Leap
