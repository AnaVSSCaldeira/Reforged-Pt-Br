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
local MouseCrafting = require "widgets/mousecrafting"
local ControllerCrafting = require "widgets/controllercrafting"
local ControllerCrafting_SingleTab = require "widgets/controllercrafting_singletab"
local CraftTabs = require "widgets/crafttabs"

local AdminCommandsSelection = require "widgets/admin_commands_selection"


local HINT_UPDATE_INTERVAL = 2.0 -- once per second
local QUAGMIRE_HINT_SHOW_DELAY = .3
local SCROLL_REPEAT_TIME = .15
local MOUSE_SCROLL_REPEAT_TIME = 0

local ADMIN_TABS = {
    ENEMIES    = {str = "ENEMIES",    sort = 0, icon = "tab_arcane.tex"},
    WEAPONS    = {str = "WEAPONS",    sort = 1, icon = "tab_fight.tex"},
    HELMS      = {str = "HELMS",      sort = 2, icon = "tab_dress.tex" },
    ARMOR      = {str = "ARMOR",      sort = 2, icon = "lavaarena_armorextraheavy.tex", icon_atlas = "images/inventoryimages.xml"},
    PETS       = {str = "PETS",       sort = 3, icon = "tab_orphanage.tex"},
    STRUCTURES = {str = "STRUCTURES", sort = 4, icon = "tab_sculpt.tex"},
	BUFFS      = {str = "BUFFS",      sort = 5, icon = "tab_madscience_lab.tex"},
    MUTATORS   = {str = "MUTATORS",   sort = 6, icon = "tab_moonaltar.tex"},
    FORGE      = {str = "FORGE",      sort = 7, icon = "tab_light.tex" },
	GENERAL    = {str = "GENERAL",    sort = 8, icon = "tab_science.tex"},
}

local tab_bg = {
    atlas = "images/hud.xml",
    normal = "tab_normal.tex",
    selected = "tab_selected.tex",
    highlight = "tab_highlight.tex",
    bufferedhighlight = "tab_place.tex",
    overlay = "tab_researchable.tex",
}

local AdminCommandTabs = Class(CraftTabs, function(self, owner, top_root)
    CraftTabs._ctor(self, owner, top_root)
	self:StopUpdating()
    self.owner = owner

    self.base_scale = 0.75

    self.craft_idx_by_tab = {}

    local tabnames = {}

	self.isforge = TheNet:GetServerGameMode() == "lavaarena"
	self.display = false

	local crafting_scale = 0.95

	self:SetPosition(0,0,0)

	-- Delete what was created by "CraftTabs" and update it for AdminCommands
	-- Selected Tab Setup
	self.crafting:KillAllChildren()
	self.crafting = self:AddChild(AdminCommandsSelection(owner))
	self.crafting:Hide()
	self.crafting:SetScale(crafting_scale)
	-- Tab List Setup
	self.tabs:KillAllChildren()
	self.tabs = self:AddChild(TabGroup())
	self.tabs:SetPosition(-16,0,0)

	local numtabslots = 1 --reserver 1 slot for crafting station tabs
	for _,tab in pairs(ADMIN_TABS) do
		table.insert(tabnames, tab)
		if not tab.crafting_station then
			numtabslots = numtabslots + 1
		end
	end

	table.sort(tabnames, function(a,b) return a.sort < b.sort end)

	self.tabs.spacing = 750 / numtabslots

	self.tabbyfilter = {}
	local was_crafting_station = nil
	for index,tab_info in ipairs(tabnames) do
		local tab = self.tabs:AddTab(
			STRINGS.UI.ADMINMENU.TABS[tab_info.str],
			resolvefilepath(tab_bg.atlas),
			tab_info.icon_atlas or resolvefilepath("images/hud.xml"),
			tab_info.icon,
			tab_bg.normal,
			tab_bg.selected,
			tab_bg.highlight,
			tab_bg.bufferedhighlight,
			tab_bg.overlay,

			function(widget) --select fn
				if not self.controllercraftingopen then

					if self.craft_idx_by_tab[index] then
						self.crafting.idx = self.craft_idx_by_tab[index]
					end

					local default_filter = function(name)
						local item = GetValidForgePrefab(name) or GetValidAdminCommand(name)
                        local mutator = REFORGED_DATA.mutators[name]
						return item ~= nil and item.type == tab_info.str or mutator ~= nil and tab_info.str == "MUTATORS"
					end

					local advanced_filter = function(name)
						local item = GetValidForgePrefab(name) or GetValidAdminCommand(name)
						local mutator = REFORGED_DATA.mutators[name]
                        return item ~= nil and item.type == tab_info.str or mutator ~= nil and tab_info.str == "MUTATORS"
					end

					self.crafting:SetFilter(advanced_filter)
					self.crafting:Open()
					self.preventautoclose = nil
				end
			end,

			function(widget) --deselect fn
				self.craft_idx_by_tab[index] = self.crafting.idx
				self.crafting:Close()
				self.preventautoclose = nil
			end,

			was_crafting_station and tab_info.crafting_station --collapsed
		)
		was_crafting_station = tab_info.crafting_station
		tab.filter = tab_info
		tab.icon = tab_info.icon
		tab.icon_atlas = tab_info.icon_atlas or resolvefilepath("images/hud.xml")
		tab.tabname = STRINGS.TABS[tab_info.str]

		self.tabbyfilter[tab_info] = tab
	end

    self:SetOnGainFocus(function()
        TheCamera:SetControllable(false)
    end)
    self:SetOnLoseFocus(function()
        TheCamera:SetControllable(true)
    end)

	self.inst:RemoveAllEventCallbacks()
	self:StartUpdating()
	self:Hide()
end)

function AdminCommandTabs:DoUpdateRecipes()
    if self.needtoupdate then
        self.needtoupdate = false
        local tabs_to_highlight = {}
        local tabs_to_alt_highlight = {}
        local tabs_to_overlay = {}
        local valid_tabs = {}

        for k,v in pairs(self.tabbyfilter) do
            tabs_to_highlight[v] = 0
            tabs_to_alt_highlight[v] = 0
            tabs_to_overlay[v] = 0
            valid_tabs[v] = false
        end

		-- Tab Selection
        local to_select = nil
        local current_open = nil

        for k, v in pairs(valid_tabs) do
            if v then
                self.tabs:ShowTab(k)
            else
                self.tabs:HideTab(k)
            end

            local num = tabs_to_highlight[k]
            local alt = tabs_to_alt_highlight[k] > 0
            if num > 0 or alt then
                local numchanged = self.tabs_to_highlight == nil or num ~= self.tabs_to_highlight[k]
                k:Highlight(num, not numchanged, alt)
            else
                k:UnHighlight()
            end

            if tabs_to_overlay[k] > 0 then
                k:Overlay()
            else
                k:HideOverlay()
            end
        end

        self.tabs_to_highlight = tabs_to_highlight

        local selected = self.tabs:GetCurrentIdx()
        local tab = selected ~= nil and self.tabs.tabs[selected] or nil
        if tab ~= nil and self.tabs.shown[tab] then
            if self.controllercraftingopen then
                self.controllercrafting:OpenRecipeTab(selected)
            elseif self.crafting.shown then
                self.crafting:UpdateRecipes()
            end
        elseif self.controllercraftingopen then
            self.owner.HUD:CloseControllerCrafting()
        elseif self.crafting.shown then
            self.crafting:Close()
            self.tabs:DeselectAll()
        end
    end
end

function AdminCommandTabs:ToggleDisplay()
	if self.display then
		self:Hide()
	else
		self:Show()
	end
	self.display = not self.display
end

return AdminCommandTabs
