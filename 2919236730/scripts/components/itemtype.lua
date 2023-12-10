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

local ItemType = Class(function(self, inst)
	self.inst = inst
	self.types = {}
	self.characters = {}
end)

function ItemType:IsType(_type)
	return self.types[_type] ~= nil or _type == self.inst.prefab
end

function ItemType:SetType(types)
	if type(types) == "table" then
		for k,v in pairs(types) do
			self.types[v] = true
		end
	else
		self.types[types] = true
	end
end

function ItemType:SetCharacterSpecific(characters)
	if type(characters) == "table" then
		for k,v in pairs(characters) do
			self.characters[v] = true
		end
	else
		self.characters[characters] = true
	end
end

function ItemType:IsAllowed(itr)
	if itr.restrictions[self.inst.prefab] or (GetTableSize(self.characters) > 0 and not self.characters[itr.inst.prefab]) then
		return false
	end
	for k,v in pairs(self.types) do
		if itr.restrictions[k] or k == "restricted" then
			return false
		end
	end
	return true
end

return ItemType
