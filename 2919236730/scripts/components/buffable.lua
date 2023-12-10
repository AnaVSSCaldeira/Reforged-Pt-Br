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

-- Stores buffs
local Buffable = Class(function(self, inst)
	self.inst = inst
	self.buffdata = {}
	self.buffs = {}
end)

function Buffable:HasBuff(buffname)
	return self.buffs[buffname] ~= nil
end

function Buffable:HasStatBuff(stat, type)
	return self.buffdata[stat] and self.buffdata[stat][type] ~= nil
end

--[[
If there already exists a buff with given buffname then the old buff will be removed and then replaced with the given buff.
data: list of buffs to add under the given buffname
- Each buff in data must have the name of the stat it affects (list of used stats coming soon) and the type of the buff ("mult", "add", or "flat").
- Ignores and prints error log if any buff in data does not have a name, type, and val
ex. data = {{name = "cooldown", type = "mult", val = 1.1}, {name = "healing_dealt", type = "add", val = 1.25}, {name = "healing_recieved", type = "flat", val = 1.2}...}
--]]
function Buffable:AddBuff(buffname, data)
	if not buffname then return end -- Must have a buff name
	if self.buffs[buffname] ~= nil then self:RemoveBuff(buffname) end
	self.buffs[buffname] = {}
	for i,buff in pairs(data) do
		-- Invalid buffs ignored
		if buff.name and buff.type and buff.val then
			-- New buff checks
			if not self.buffdata[buff.name] then
				self.buffdata[buff.name] = {}
			end
			if not self.buffdata[buff.name][buff.type] then
				self.buffdata[buff.name][buff.type] = {}
				self.buffdata[buff.name][buff.type].val = buff.type == "mult" and 1 or 0
				self.buffdata[buff.name][buff.type].count = 0
			end
			-- Update buff values
			self.buffdata[buff.name][buff.type].val = self.buffdata[buff.name][buff.type].val * (buff.type == "mult" and buff.val or 1) + (buff.type ~= "mult" and buff.val or 0)
			self.buffdata[buff.name][buff.type].count = self.buffdata[buff.name][buff.type].count + 1
			-- Add valid buff to the buffnames list
			table.insert(self.buffs[buffname], buff)
			-- Applying any scaling buffs immediately
			if buff.name == "scaler" and self.inst.components.scaler then
				self.inst.components.scaler:ApplyScale()
			end
		else
			Debug:Print("Invalid buff given from: " .. tostring(buffname) .. " at index " .. tostring(i), "error")
		end
	end
end

function Buffable:RemoveBuff(buffname)
	if self.buffs[buffname] then
		for _,buff in pairs(self.buffs[buffname]) do
			-- Update buff values
			self.buffdata[buff.name][buff.type].val = self.buffdata[buff.name][buff.type].val / (buff.type == "mult" and buff.val or 1) - (buff.type ~= "mult" and buff.val or 0)
			self.buffdata[buff.name][buff.type].count = self.buffdata[buff.name][buff.type].count - 1
			-- Update buff lists
			if self.buffdata[buff.name][buff.type].count < 1 then
				self.buffdata[buff.name][buff.type] = nil
			end
			if GetTableSize(self.buffdata[buff.name]) < 1 then
				self.buffdata[buff.name] = nil
			end
		end
		self.buffs[buffname] = nil
	end
end

-- 3 main types used: "mult", "add", and "flat"
-- custom types can be created
-- returns 0 if type is flat and no buffs are found
-- returns 1 if type is not flat and no buffs are found
function Buffable:GetStatBuff(stat, type)
    local buff = (type == "mult" and 1) or 0
    if stat and type and self:HasStatBuff(stat, type) then
		return self.buffdata[stat][type].val
    end
    return buff
end

-- Returns the mults, adds, and flats of the given bufftypes
-- default returns mults = 1, add = 1, and flats = 0 if the corresponding type has no buffs for the given stats
function Buffable:GetStatBuffs(stats)
	local mults = 1
	local adds = 1
	local flats = 0
	for i,stat in pairs(stats) do
		mults = mults * self:GetStatBuff(stat, "mult")
		adds = adds + self:GetStatBuff(stat, "add")
		flats = flats + self:GetStatBuff(stat, "flat")
	end
	return mults, adds, flats
end

-- Returns the buffed value of the given stats.
-- returns val * mults * adds + flats
-- if no val is given then it then val is set to 1 and returns normally.
-- if an invalid bufftype is given then the given val will be returned
--[[
Notes:
cooldown - flat buffs need to be implemented, atm a flat buff will adjust the cooldownrate directly.
--]]
function Buffable:ApplyStatBuffs(stats, val)
	local mults, adds, flats = self:GetStatBuffs(stats)
	return (val or 1) * mults * adds + flats
end

return Buffable
