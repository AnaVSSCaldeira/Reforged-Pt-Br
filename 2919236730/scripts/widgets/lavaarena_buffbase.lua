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

--TODO: Leo - Will need to go over this and remove any unnessecary code relating to Fluffle's old debuff display. 
local Widget = require "widgets/widget"
local UIAnim = require "widgets/uianim"
--local BuffWdgt = require "widgets/lavaarena_buff"

local OFFSET_X = 150
local OFFSET_Y = -80

local BuffBase = Class(Widget, function(self, owner)
    Widget._ctor(self, "BuffBase")
	self.owner = owner
	
	self.buffs = {}
	self.spots = {}
	self.root = self:AddChild(Widget("root"))
	
	self:SetClickable(false)
	
	rawset(_G, "PushBuff", function(n) self:PushBuff(n) end)
	rawset(_G, "RemoveBuff", function(n) self:RemoveBuff(n) end)
end)

function BuffBase:GetSpot()
	for i = 1, 4 do
		if not self.spots[i] then
			return i
		end
	end
	
	return 0
end

function BuffBase:PushBuff(name)
	if self.buffs[name] ~= nil then
		Debug:Print(string.format("Tried to add existing buff %s!\n(%s)", name, CalledFrom()), "error")
		return
	end
end

function BuffBase:RemoveBuff(name)
	if not self.buffs[name] then
		Debug:Print(string.format("Tried to remove non-existing buff (%s)!\n%s", name, CalledFrom()), "error")
		return
	end
end

return BuffBase
