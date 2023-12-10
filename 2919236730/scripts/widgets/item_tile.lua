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

local RecipeTile = require "widgets/recipetile"
local MAX_WIDTH  = 62
local MAX_HEIGHT = 62

local MOD_MAX_WIDTH  = 20
local MOD_MAX_HEIGHT = 20

local ItemTile = Class(RecipeTile, function(self, item)
    RecipeTile._ctor(self, item)
	if item ~= nil then
        self:SetItem(item)
    end
    self.mod_icon = self:AddChild(Image())
    self.mod_icon:SetPosition(45,25)
    self.mod_icon:Hide()
end)

function ItemTile:SetItem(item)
    self.item = item
    local image = item.imagefn ~= nil and item.imagefn() or item.image or item.icon and item.icon.tex
    self.img:SetTexture(item.atlas or item.icon and item.icon.atlas, image, image ~= item.image and item.image or nil)
    local width,height = self.img:GetSize()
    local scale = math.min(MAX_WIDTH / width, MAX_HEIGHT / height)
    self:SetScale(scale,scale,scale)

    -- Display mod icon on item if it belongs to a mod
    if item.mod_id then
        local mod_icon_info = TUNING.FORGE.MOD_ICONS[item.mod_id] or TUNING.FORGE.MOD_ICONS.DEFAULT
        self.mod_icon:SetTexture(mod_icon_info.atlas, mod_icon_info.tex)
        local mod_width,mod_height = self.img:GetSize()
        local mod_scale = math.min(MOD_MAX_WIDTH / mod_width, MOD_MAX_HEIGHT / mod_height)
        self.mod_icon:SetScale(mod_scale,mod_scale,mod_scale)
        self.mod_icon:Show()
    else
        self.mod_icon:Hide()
    end
end

function ItemTile:SetSize(width, height)
	self.img:ScaleToSize(width, height, true)
end

return ItemTile
