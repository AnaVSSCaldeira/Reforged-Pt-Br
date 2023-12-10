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

local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"
local TextButton = require "widgets/textbutton"
local ImageButton = require "widgets/imagebutton"
local easing = require "easing"
local Widget = require "widgets/widget"
local TEMPLATES = require "widgets/redux/templates"
require("stringutil")

local MAX_ITEMS_DISPLAYED = 6

--[[
Creates a side scrolling list
--]]
local SideScrollingList = Class(Widget, function(self, items, options)
    ------------------ NO TOUCHY ------------------
	Widget._ctor(self, "SideScrollingList")

	self.index = 1
	self.old_index = 1
	self.options = options
	self.options.max_items_displayed = options.max_items_displayed or MAX_ITEMS_DISPLAYED
	self.options.button_offsets = {x = options.button_offsets.x or 0, y = options.button_offsets.y or 0, z = options.button_offsets.z or 0}
	self.items = items
	self.item_count = #items
	self.item_width = self.options.item_width or 0--, self.item_height = items and items[1] and items[1]:GetRegionSize() or 0,0

	-- Create background and buttons
	self.bg = self:AddChild( Image("images/ui.xml", "blank.tex") )
	self.bg:MoveToBack()
	self.left_button = self:AddChild( ImageButton("images/global_redux.xml", "arrow2_left.tex", "arrow2_left_over.tex", "arrow_left_disabled.tex", "arrow2_left_down.tex") )
	self.right_button = self:AddChild( ImageButton("images/global_redux.xml", "arrow2_right.tex", "arrow2_right_over.tex", "arrow_right_disabled.tex", "arrow2_right_down.tex") )

	--[[
	Create scrollbar?
	]]

	-- update list
	self:UpdateItems(items)
	self:UpdateDisplay()
end)

-- index is the far left item, NOT the center?
function SideScrollingList:ShiftIndex(increment)
	self.old_index = self.index
	local new_index = self.index + increment
	self.index = (new_index > 0 and new_index <= (self.item_count - self.options.max_items_displayed + 1) and new_index) or (new_index <= 0 and 1) or (new_index > self.item_count and self.item_count) or self.old_index
	self:UpdateDisplay()
end

-- Button display control
function SideScrollingList:UpdateButtonDisplay()
	if self.index > 1 and self.item_count > self.options.max_items_displayed then
		self.left_button:Enable()
	else
		self.left_button:Disable()
	end
	if self.index + self.options.max_items_displayed - 1 >= self.item_count then
		self.right_button:Disable()
	else
		self.right_button:Enable()
	end
end

-- Update which items should be displayed
function SideScrollingList:UpdateDisplay()
	local items_to_display = ((self.item_count > self.options.max_items_displayed) and self.options.max_items_displayed) or self.item_count
	local space = 255
	local offset = space * ((items_to_display-1)/2)
	local y_offset = 25
	local rot_spacing = 4
	local rot_offset = rot_spacing * ((items_to_display-1)/2)

	-- Hide items that should not be displayed
	local index_delta = self.index - self.old_index -- 2 to 3
	if index_delta ~= 0 then
		for i=((index_delta > 0 and self.old_index) or (self.old_index + self.options.max_items_displayed - 1)),((math.abs(index_delta) >= self.options.max_items_displayed and self.options.max_items_displayed) or (index_delta > 0 and (self.index - 1)) or (self.index + self.options.max_items_displayed)),(index_delta > 0 and 1 or -1) do
			self.items[i]:Hide()
		end
	end

	-- Show and update positions/rotations of items that should be shown
	for i=1,items_to_display,1 do
		local item = self.items[self.index + i - 1]
		if item then
			local x = (space * (i-1)) - offset
			local y = ((item.fake_rand or 1) * y_offset + y_offset) * (i%2==0 and 1 or -1)
			item:SetPosition(x,y)
			item:SetRotation((rot_spacing * (i-1)) - rot_offset + ((item.fake_rand or 1) * 2.5 - 1.25))
			item:Show()
		else
			Debug:Print("SideScrollingList - item is nil at index " .. tostring(self.index + i - 1), "error", nil, nil, true)
		end
	end
	self:UpdateButtonDisplay()
end

-- Replaces the old list with the given list and updates the display
function SideScrollingList:UpdateItems(items)
	self.items = items
	self.item_count = #items
	self.index = 1
	self.old_index = 1

	-- Update background
	local bg_width = self.options.width or self.item_width * (self.item_count <= self.options.max_items_displayed and self.item_count or self.options.max_items_displayed) or 0
	local bg_height = self.options.height or 0
	self.bg:ScaleToSize(bg_width, bg_height)
	--self.bg:SetPosition(-bg_width/2, bg_height/2)

	-- Update buttons
	self.left_button:SetPosition(-self.options.button_offsets.x - self.item_width * self.options.max_items_displayed / 2, self.options.button_offsets.y, 0)
	self.left_button:SetOnClick(function() self:ShiftIndex(-1) end)

	self.right_button:SetOnClick(function() self:ShiftIndex(1) end)
	self.right_button:SetPosition(self.options.button_offsets.x + self.item_width * self.options.max_items_displayed / 2, self.options.button_offsets.y, 0)

	-- Only display buttons if item list is larger than display limit
	if self.options.max_items_displayed >= self.item_count then
		self.left_button:Hide()
		self.right_button:Hide()
	else
		self.left_button:Show()
		self.right_button:Show()
		self.left_button:MoveToFront()
		self.right_button:MoveToFront()
	end

	-- Make the scrollwheel function on top of items
	local ssl_inst = self
	for i,item in pairs(self.items) do
		local _OnControl = item.OnControl
		item.OnControl = function(self, control, down, force)
			_OnControl(self, control, down, force)
			if down and (self.focus or force) and ssl_inst:IsVisible() then
				if control == CONTROL_SCROLLBACK then
					ssl_inst:ShiftIndex(-1)
					TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
					return true
				elseif control == CONTROL_SCROLLFWD then
					ssl_inst:ShiftIndex(1)
					TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
					return true
				end
			end
		end
    end
	self.bg:MoveToBack() -- move the background behind items
	self:UpdateDisplay()
end

local function ToggleItemDisplay(self, show)
	for i=self.index,(((self.index + self.options.max_items_displayed - 1) > self.item_count) and (self.item_count - self.index + 1) or (self.index + self.options.max_items_displayed - 1)),1 do
		if show then
			self.items[i]:Show()
		else
			self.items[i]:Hide()
		end
	end
end

function SideScrollingList:ShowItems()
	ToggleItemDisplay(self, true)
end

function SideScrollingList:HideItems()
	ToggleItemDisplay(self, false)
end

-- Gives scroll wheel control over all children of the list
function SideScrollingList:OnControl(control, down, force)
    if SideScrollingList._base.OnControl(self, control, down) then return true end

    if down and (self.focus or force) and self:IsVisible() then
        if control == CONTROL_SCROLLBACK then
			self:ShiftIndex(-1)
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
            return true
        elseif control == CONTROL_SCROLLFWD then
			self:ShiftIndex(1)
			TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
            return true
        end
    end
end

return SideScrollingList
