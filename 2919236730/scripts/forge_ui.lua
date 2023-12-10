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

local BuffBase = require "widgets/lavaarena_buffbase"
local AtlasChecker = require "util/atlas_checker"
local Image = require "widgets/image"

local function Controls(self)
	--self.buff_base = self.right_root:AddChild(BuffBase(self.owner))
	--self.buff_base:SetPosition(-50, 200)
end

local function TeammateHealthBadge(self)
	-- Fox: So klei used symbols to swap player bages
	-- We can't do that (for mod compatibility) so we'll just use self-inspect images instead
	-- self-inspect: 44x54; klei: 36x44
	self.avatar = self.underNumber:AddChild(Image("images/hud.xml", "self_inspect_wilson.tex"))
	self.avatar:SetPosition(1, 0)
	self.avatar:SetScale(0.78)
	
	self.avatar:MoveToBack()
	
	local _SetPlayer = self.SetPlayer
	local _SetPercent = self.SetPercent
	
	function self:SetPlayer(player, ...)
		_SetPlayer(self, player, ...)
		
		self.anim:GetAnimState():HideSymbol("character_wilson")
		
		local image_name = "self_inspect_"..player.prefab..".tex"
		local atlas_name = "images/avatars/self_inspect_"..player.prefab..".xml"
		if not softresolvefilepath(atlas_name) then
			atlas_name = "images/hud.xml"
			
			if not AtlasChecker(image_name, atlas_name) then
				image_name = "self_inspect_mod1.tex"
			end
		end
		
		self.avatar:SetTexture(atlas_name, image_name)
	end
	
	function self:SetPercent(val)
		_SetPercent(self, val)
		
		self.avatar:SetFadeAlpha(self.percent <= 0 and 0.5 or 1)
	end
end

return {
	["widgets/controls"] = Controls,
	["widgets/teammatehealthbadge"] = TeammateHealthBadge,
}
