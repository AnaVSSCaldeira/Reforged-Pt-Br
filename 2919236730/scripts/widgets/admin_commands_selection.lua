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

local TileBG = require "widgets/tilebg"
local InventorySlot = require "widgets/invslot"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Widget = require "widgets/widget"
local TabGroup = require "widgets/tabgroup"
local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"
local CraftSlot = require "widgets/craftslot"
local Crafting = require "widgets/crafting"
local ItemSlots = require "widgets/item_slots"

require "widgets/widgetutil"

local NUM_TABS = 10
local CRAFTING_ATLAS = nil

local AdminCommandsSelection = Class(Crafting, function(self, owner, num_tabs)
    self.override_complete = false
	Crafting._ctor(self, owner, num_tabs or NUM_TABS)

	CRAFTING_ATLAS = GetGameModeProperty("hud_atlas") or HUD_ATLAS --done inside the constructor so that pipeline scripts don't need GetGameModeProperty

    self.in_pos = Vector3(145,0,0)
    self.out_pos = Vector3(0,0,0)

	-- Delete and replace craftslots
	self.craftslots:KillAllChildren()
	self.craftslots = nil
	self.craftslots = ItemSlots(num_tabs or NUM_TABS, owner)
    self:AddChild(self.craftslots)
	self.craftslots:EnablePopups()

	-- Arrange widgets back in the correct order
	self.downconnector:MoveToFront()
	self.upconnector:MoveToFront()
	self.downbutton:MoveToFront()
	self.upbutton:MoveToFront()

	self.override_complete = true
	self:UpdateRecipes()
end)

local function SortByKey(a, b)
    return a.sortkey < b.sortkey
end

function AdminCommandsSelection:UpdateRecipes()
    if self.owner ~= nil and self.owner.replica.builder ~= nil  and self.override_complete then

        self.valid_recipes = {}
        for category,mod_info in pairs(AllForgePrefabs) do
            for mod_id,forge_prefabs in pairs(mod_info) do
                for name,forge_prefab in pairs(forge_prefabs) do
                    if self.filter == nil or self.filter(forge_prefab.name) then
                        table.insert(self.valid_recipes, forge_prefab)
                    end
                end
            end
        end

        for _,admin_command in pairs(AllAdminCommands) do
            if self.filter == nil or self.filter(admin_command.name) then
                table.insert(self.valid_recipes, admin_command)
            end
        end

        for name,mutator in pairs(REFORGED_DATA.mutators) do
            if self.filter == nil or self.filter(name) then
                table.insert(self.valid_recipes, mutator)
            end
        end

		table.sort(self.valid_recipes, SortByKey)

        local shown_num = 0 --Number of recipes shown

        local num = math.min(self.max_slots, #self.valid_recipes) --How many recipe slots we're going to need

        self:Resize(#self.valid_recipes)
        self.craftslots:Clear()

        self:UpdateIdx()

        --V2C: NOTE: when it does need to scroll, there are 2 empty half-slots
        --           at the top and bottom, which is why this math looks weird
        --default is -1, the recipe starts in the top slot.
        self.idx = self.use_idx
            and math.clamp(self.idx, -1, #self.valid_recipes - (self.max_slots - 1))
            or -1

        for i = 1, num + 1 do --For each visible slot assign a recipe
            local slot = self.craftslots.slots[i]
            if slot ~= nil then
                local item = self.valid_recipes[((self.use_idx and self.idx) or 0) + i]
                if item then
                    slot:SetItem(item.name)
                    shown_num = shown_num + 1
                else
                    slot:Clear()
                    slot:Close()
                end
            end
        end

        self:UpdateScrollButtons()
    end
end

return AdminCommandsSelection
