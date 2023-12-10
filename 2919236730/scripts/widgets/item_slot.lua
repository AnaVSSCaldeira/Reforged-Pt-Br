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

local CraftSlot = require "widgets/craftslot"
local ItemTile = require "widgets/item_tile"
local ItemPopup = require "widgets/item_popup"

local ItemSlot = Class(CraftSlot, function(self, atlas, bgim, owner)
    CraftSlot._ctor(self, atlas, bgim, owner)

	self.tile:KillAllChildren()
	self.tile = self:AddChild(ItemTile(nil))
end)

function ItemSlot:EnablePopup()
    if not self.item_popup then
        self.item_popup = self:AddChild(ItemPopup())
        self.item_popup:SetPosition(0,-20,0)
        self.item_popup:Hide()
        local s = 1.25
        self.item_popup:SetScale(s,s,s)
    end
end

function ItemSlot:OnControl(control, down)
    if ItemSlot._base.OnControl(self, control, down) then return true end

    if not down and control == CONTROL_ACCEPT then
        if self.owner and self.item then
            if self.item_popup and not self.item_popup.focus and self.item_popup.buttons[1] then
                TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
                self.item_popup.buttons[1].onclick()
                return true
            end
        end
    end
end

function ItemSlot:Clear()
    ItemSlot._base.Clear(self)
    self.item = nil
end

function ItemSlot:Open()
    if self.item_popup then
        self.item_popup:SetPosition(0,-20,0)
    end
    self.open = true
    self:ShowItem()
    TheFocalPoint.SoundEmitter:PlaySound("dontstarve/HUD/click_mouseover")
end

function ItemSlot:Close()
    self.open = false
    self.locked = false
    self:HideItem()
end

function ItemSlot:ShowItem()
    if self.item and self.item_popup then
        self.item_popup:Show()
        self.item_popup:SetItem(self.item, self.owner)
    end
end

function ItemSlot:HideItem()
    if self.item_popup then
		self.item_popup:HideReset()
        self.item_popup:Hide()
    end
end

function ItemSlot:Refresh(name)
	name = name or self.item_name
	local item = GetValidForgePrefab(name) or AllAdminCommands[name] or REFORGED_DATA.mutators[name]

    self.item_name = name
    self.item = item
    if self.item then

        self.tile:SetItem(self.item)
        self.tile:Show()

        if self.fgimage then
			self.fgimage:Hide()
			self.lightbulbimage:Hide()
            self.fgimage:SetTint(1, 1, 1, 1)
        end

        if self.item_popup then
            --self.item_popup:SetItem(self.item, self.owner)
			if self.focus and not self.open then
				self:Open()
			end
		end
    end
end

function ItemSlot:SetItem(name)
    self:Show()
	self:Refresh(name)
end

return ItemSlot
