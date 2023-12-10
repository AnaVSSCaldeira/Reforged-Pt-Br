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
local SYMBOL_OFFSET = -130

local ArmorBreak_Debuff = Class(function(self, inst)
    self.inst = inst
	self.followsymbol = nil
	self.debuffed = false
	self.debufflevel = 0
	self.timer = 0
	self.followoffset = Vector3(0, SYMBOL_OFFSET, 0)
end)

function ArmorBreak_Debuff:SetFollowSymbol(symbol, offset)
	self.followsymbol = symbol
	if offset then
		self.followoffset = Vector3(offset.x, offset.y, offset.z)
	end
end

function ArmorBreak_Debuff:ApplyDebuff(time)
	self.timer = time or 4
	if not self.debuffed then
		self.debuffed = true
		self:RunTimer()
	end
	if self.debufflevel < 5 then
		self.debufflevel = self.debufflevel + 1
	end
	self.inst.components.combat:AddDamageBuff("armorbreak", {
		buff = function(attacker, victim, weapon, stimuli)
			if victim and victim == self.inst then
				return 1 + 0.02*self.debufflevel
			end
		end
	}, true)
	if self.debuff_fx == nil then
		self.debuff_fx = COMMON_FNS.CreateFX("forgedebuff_fx", self.inst)
	end
end

function ArmorBreak_Debuff:RunTimer()
	if self.timer == 0 then
		self:RemoveDebuff()
	elseif self.timer > 0 then --if its negative, then never run the timer.
		self.timer = self.timer - 1
		self.inst:DoTaskInTime(1, function() self:RunTimer() end)
	end
end

function ArmorBreak_Debuff:RemoveDebuff()
	if self.debuff_fx then
	self.debuff_fx.AnimState:PlayAnimation("pst")
	self.debuff_fx = nil
	end
	self.debuffed = false
	self.debufflevel = 0
	self.inst.components.combat:RemoveDamageBuff("armorbreak", true)
end

return ArmorBreak_Debuff
