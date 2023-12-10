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

local CraftSlots = require "widgets/craftslots"
local ItemSlot = require "widgets/item_slot"

local ItemSlots = Class(CraftSlots, function(self, num, owner)
    CraftSlots._ctor(self, num, owner)
	local CRAFTING_ATLAS = GetGameModeProperty("hud_atlas") or HUD_ATLAS
	self:KillAllChildren()
	self.slots = {}
    for k = 1, num do
        local slot = ItemSlot(CRAFTING_ATLAS, "craft_slot.tex", owner)
        -- self.slots[k] = slot
        self:AddChild(slot)
        table.insert(self.slots, slot)
    end
end)

return ItemSlots