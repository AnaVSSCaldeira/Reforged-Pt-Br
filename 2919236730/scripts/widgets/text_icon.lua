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
local easing = require "easing"
local Widget = require "widgets/widget"
local TEMPLATES = require "widgets/redux/templates"
require("stringutil")

--[[
Creates text that has an icon attached to it
	TODO
	need font_size, icon_size
		height instead? maybe not
	Optional parameters
		-with default
	text
	icons
		source
		tex
		opts
			icon_size
			pos_offset_x
			pos_offset_y
			hovertext
			font
			font_offset_x
			font_offset_y
	opts		
		pos.x, pos.y, pos.z
		font
		font_size
		h_alignment
		color
--]]
local TextIcon = Class(Widget, function(self, text, icons, opts)
    ------------------ NO TOUCHY ------------------
	Widget._ctor(self, "TextIcon")
	
	self.pos = opts and opts.pos or {x = 0, y = 0, z = 0}
	self.font = opts and opts.font or CHATFONT
	self.font_size = opts and opts.font_size or 20
	self.h_alignment = opts and opts.h_alignment or 1
	self.color = opts and opts.color or {1,1,1,1}
	self.icon_after_text = opts and opts.icon_after_text
	self.icon_alignment = opts and not opts.icon_after_text and -1 or 1 -- TODO does not imply nil as well as false in lua?
	
	-- Text
	self.text = self:AddChild(Text(self.font, self.font_size))
	self.text:SetString(text)
	self.text:SetColour(self.color)
	local text_width, text_height = self.text:GetRegionSize()
	--[[
	center w/2
	right 0
	left w
	--]]
	self.text:SetPosition(self.pos.x + text_width * self.h_alignment * .5, self.pos.y, self.pos.z)
	self.alignment_offset_x = text_width * (self.h_alignment + 1) * .5
	--self.alignment_offset_x = self.alignment_offset_x and self.icon_after_text or -self.alignment_offset_x
	
	local function icon_x_offset(width, offset, alignment_offset)
		if self.icon_after_text then
			return width + offset + alignment_offset
		else
			return - (width + offset)
		end
	end
	
	self.SetString = function(_, text)
		self.text:SetString(text)
		local text_width, text_height = self.text:GetRegionSize()
		
		self.text:SetPosition(self.pos.x + text_width * self.h_alignment * .5, self.pos.y, self.pos.z)
		self.alignment_offset_x = text_width * (self.h_alignment + 1) * .5
		--self.alignment_offset_x = self.alignment_offset_x and self.icon_after_text or -self.alignment_offset_x
		
		-- update icon position
		for i, icon in pairs(self.icons) do
			icon:SetPosition(self.pos.x + icon_x_offset(icon.opts.icon_size[1], icon.opts.pos_offset.x, self.alignment_offset_x), self.pos.y + icon.opts.pos_offset.y, self.pos.z + icon.opts.pos_offset.z)
		end
	end
	
	self.icons = {}
	for i, icon in pairs(icons) do
		local key = icon.key or i
		self.icons[key] = self:AddChild(Image("images/" .. tostring(icon.source), icon.tex))
		-- options
		self.icons[key].opts = {}
		self.icons[key].opts.icon_size = icon.opts and icon.opts.icon_size or {25, 25}
		self.icons[key].opts.pos_offset = icon.opts and icon.opts.pos_offset or {x = 0, y = 0, z = 0}
		self.icons[key].opts.hovertext = icon.opts and icon.opts.hovertext or ""
		self.icons[key].opts.font = icon.opts and icon.opts.font or NEWFONT_OUTLINE
		self.icons[key].opts.font_offset = icon.opts and icon.opts.font_offset or {x = 10, y = -28, z = 0}
		
		self.icons[key]:SetPosition(self.pos.x + icon_x_offset(self.icons[key].opts.icon_size[1] / 2, self.icons[key].opts.pos_offset.x, self.alignment_offset_x), self.pos.y + self.icons[key].opts.pos_offset.y, self.pos.z + self.icons[key].opts.pos_offset.z) -- TODO why is there a "/ 2" on icon size???? is icon centered or not?
		
		self.icons[key]:ScaleToSize(self.icons[key].opts.icon_size, nil, true)
		self.icons[key]:SetHoverText(
			self.icons[key].opts.hovertext,
			{
				font = self.icons[key].opts.font,
				offset_x = self.icons[key].opts.font_offset.x,
				offset_y = self.icons[key].opts.font_offset.y
			})
	end
	
	self.SetIconTexture = function(_, source, tex, key_name)
		local key = key_name or 1
		if self.icons[key] then
			self.icons[key]:SetTexture("images/" .. source, tex)	
			self.icons[key]:SetPosition(self.pos.x + icon_x_offset(self.icons[key].opts.icon_size[1], self.icons[key].opts.pos_offset.x, self.alignment_offset_x), self.pos.y + self.icons[key].opts.pos_offset.y, self.pos.z + self.icons[key].opts.pos_offset.z)
			self.icons[key]:ScaleToSize(self.icons[key].opts.icon_size, nil, true)
		else
			Debug:Print("Icon not found for given key: " .. tostring(key), "error")
		end
	end
	
end)

return TextIcon
