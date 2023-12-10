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


_G.FE_MUSIC = _G.FESTIVAL_EVENT_MUSIC.lavaarena.sound

local UIAnim = _G.require "widgets/uianim"

AddClassPostConstruct("screens/redux/mainscreen", function(self)
	_G.TheSim:LoadPrefabs({"lavaarena_fest_frontend"})
end)

AddClassPostConstruct("screens/redux/multiplayermainscreen", function(self)
	local _OnUpdate = self.OnUpdate
	self.OnUpdate = function(self, dt)
		_OnUpdate(self, dt)
		if not self.hasbeenforged then
			for _,widget in pairs(self.banner_root.children) do
				if widget and widget.name == "UIAnim" then
					widget:Kill()
				end
			end
			self.banner_root.anim_bg = self.banner_root:AddChild(UIAnim()) --THIS IS HOW YOU DO IT KLEI, YOU DON'T MAKE IT A LOCAL VARIABLE, YOU MAKE IT ABLE TO BE ACCESSED
			self.banner_root.anim_bg:GetAnimState():SetBuild("dst_menu_lavaarena_s2")
			self.banner_root.anim_bg:GetAnimState():SetBank("dst_menu_lavaarena_s2")
			self.banner_root.anim_bg:GetAnimState():PlayAnimation("idle", true)
			self.banner_root.anim_bg:SetScale(0.48)
			self.banner_root.anim_bg:SetPosition(0, -160)
			self.banner_root.anim_bg:MoveToBack()
			
			self.logo:SetTexture("images/lavaarena_frontend.xml", "title.tex")
			self.logo:SetScale(.6)
			self.logo:SetPosition( -_G.RESOLUTION_X/2 + 180, 5)
			
			self.hasbeenforged = true
		end
	end
end)