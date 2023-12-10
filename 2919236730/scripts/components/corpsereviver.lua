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

local CorpseReviver = Class(function(self, inst)
	self.inst = inst
	self.additional_revive_health_percent = 0
	self.reviver_speed_mult = 1
end)

function CorpseReviver:GetAdditionalReviveHealthPercent()
	return self.inst.components.buffable and self.inst.components.buffable:ApplyStatBuffs({"reviver_health"}, self.additional_revive_health_percent) or self.additional_revive_health_percent
end

function CorpseReviver:SetAdditionalReviveHealthPercent(percent)
	self.additional_revive_health_percent = percent
end

function CorpseReviver:GetReviveHealthPercentMult()
	return self.revive_health_percent_mult
end

function CorpseReviver:SetReviveHealthPercentMult(percent)
	self.revive_health_percent_mult = percent
end

function CorpseReviver:GetReviverSpeedMult()
	return self.reviver_speed_mult
end

function CorpseReviver:SetReviverSpeedMult(mult)
	self.reviver_speed_mult = mult
end

function CorpseReviver:GetDebugString()
	return string.format("Bonus Health on Revive: %s, Revie Speed Mult: %s", tostring(self.additional_revive_health_percent), tostring(self.reviver_speed_mult))
end

return CorpseReviver
