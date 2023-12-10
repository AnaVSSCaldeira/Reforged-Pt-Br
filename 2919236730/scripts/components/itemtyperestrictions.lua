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

local ItemTypeRestrictions = Class(function(self, inst)
	self.inst = inst
	self.restrictions = {}
end)

function ItemTypeRestrictions:SetRestrictions(restrictions) --Now accepts item prefab names too!
	if type(restrictions) == "table" then
		for k,v in pairs(restrictions) do
			self.restrictions[v] = true
		end
	else
		self.restrictions[restrictions] = true
	end
end

function ItemTypeRestrictions:IsAllowed(item)
	for k,v in pairs(self.restrictions) do
		if (item.components.itemtype and not item.components.itemtype:IsAllowed(self)) or self.restrictions[item.prefab] then
			return false
		end
	end
	return true
end

return ItemTypeRestrictions