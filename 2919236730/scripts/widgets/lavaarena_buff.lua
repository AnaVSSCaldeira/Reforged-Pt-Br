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

local Widget = require "widgets/widget"
local UIAnimButton = require "widgets/uianimbutton"

local OVERRIDE_SYMBOL = "swap_icon"
local BUFFS = TUNING.FORGE.BUFFS_DATA

local BuffWdgt = Class(Widget, function(self, buff)
   Widget._ctor(self, "BuffWdgt")
	
	local DATA = BUFFS[string.upper(buff)]
	assert(DATA ~= nil, "Warning! Tried to add non-exsiting buff ("..buff.."). Your buff must exsist in \"TUNING.FORGE.BUFFS_DATA\".")
	
    self.root = self:AddChild(Widget("ROOT"))
	
	self.base = self.root:AddChild(UIAnimButton("buffindex", "lavaarena_".. (not DATA.BUFF and "de" or "") .."buff_build", nil, nil, "idle_open", nil, nil))
    self.base:SetTooltip(STRINGS.UI.ITEM_SCREEN.DISABLED_TOAST_TOOLTIP)
	self.base:SetOnClick(function()end)
	self.base:SetOnFocus(function()end)
	self.base:SetScale(0.4)
	self.base:Disable()
    --self.base:SetTooltipPos(-100, 0, 0)
	
	self.anim = self.base.animstate
	
	self.anim:OverrideSymbol(OVERRIDE_SYMBOL, "lavaarena_bufficons", "swap_icon_"..DATA.SYMBOL)
	self.anim:PlayAnimation("rollout")
	self.anim:PushAnimation("idle_open", true)
end)

function BuffWdgt:Close(cb)
	self.anim:PlayAnimation("rollin")
	self.inst:DoTaskInTime(0.25, cb)
end

return BuffWdgt