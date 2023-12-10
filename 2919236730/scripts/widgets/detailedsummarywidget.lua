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
local easing = require "easing"
local Widget = require "widgets/widget"
require("stringutil")

--[[
include averages?
save stats that you typically get with certain characters?
only save victories for averages

TODO:
Hide stats that are 0, if 0 deaths then display it still?
	only unnecessary stats only regardless of it being 0?
		only pet characters will show pet stats
		melee stats for melee users only
		etc
	colored numbers for stats based on quality of the number?
	different colored font for titles/headers etc?

	add own stats that you keep track of
		- Approximate Wasted Damage, all 0 damage added up?
--]]
local DetailedSummaryWidget = Class(Widget, function(self, options, player_info, stat_fields, stat_rankings, mvp_widget, current_eventid)
    ------------------ NO TOUCHY ------------------
	Widget._ctor(self, "DetailedSummaryWidget")
	self.debug_mode = false

	-- Options
	self.only_show_nonzero_stats = options.only_show_nonzero_stats
	self.display_colored_stats = options.display_colored_stats
	self.default_rotation = options.default_rotation
	self.rotation = options.rotation
	--self.track_damage_wasted_stats = options.track_damage_wasted_stats

	self.current_eventid = current_eventid

	-- Stat info
	self.player_info = player_info
	self.stat_fields = stat_fields
	self.stat_rankings = stat_rankings
	self.mvp_widget = mvp_widget
	self.mvp_widget_original_position = mvp_widget:GetPosition()
	self.mvp_widget_original_rotation = mvp_widget.inst.UITransform:GetRotation()

	self:StatSetup()

	-- Display --

	-- Font constant
	local title_font = TITLEFONT
	local header_font = BODYTEXTFONT
	self.font = BODYTEXTFONT

	-- Title Text
	local stats_title_pos_x = -100--50
	local stats_title_pos_y = 350
	local stats_title_fontsize = 50
	local stats_title_spacing = 50

	self.stats_title_text = self:AddChild( Text(title_font, stats_title_fontsize, STRINGS.UI.DETAILEDSUMMARYSCREEN.TITLE, UICOLOURS.WHITE) )
	local stats_title_text_size_x, stats_title_text_size_y = self.stats_title_text:GetRegionSize()
	self.stats_title_text:SetPosition(stats_title_pos_x + stats_title_text_size_x*0.5, stats_title_pos_y - stats_title_text_size_y*0.5 - stats_title_spacing, 0)

	-- Header Text
	local stats_header_fontsize = 40
	local stats_header_spacing = 40

	-- Stats Text
	local stats_starting_pos_x = -100
	local stats_starting_pos_y = stats_title_pos_y - stats_title_spacing
	self.stats_current_pos_x = stats_starting_pos_x
	self.stats_current_pos_y = stats_starting_pos_y

	self.stats_text = self:AddChild( Widget("Stats Text") )
	-- Create text for each category that has stats to display
	for i,category in pairs(self.stat_order) do
		local values = self.stat_list[category]
		if values and values.count > 0 then
			local stats_header_text = self:AddChild( Text(header_font, stats_header_fontsize, values.title, UICOLOURS.WHITE) )
			local stats_header_text_size_x, stats_header_text_size_y = stats_header_text:GetRegionSize()
			self.stats_current_pos_y = self.stats_current_pos_y - stats_header_spacing
			stats_header_text:SetPosition(self.stats_current_pos_x + stats_header_text_size_x*0.5, self.stats_current_pos_y - stats_header_text_size_y*0.5, 0)
			self:CreateStatText(values.stats, category)
		end
		if i == 2 then -- TODO make this change based on height of stats, OR are we making a page for each stat type?
			self.stats_current_pos_x = stats_starting_pos_x + 300
			self.stats_current_pos_y = stats_starting_pos_y
		end
	end

	self:Hide()
end)

-- Organizes stats into categories and orders them based on a priority
function DetailedSummaryWidget:StatSetup()
	self.stat_order = {"attack", "crowd_control", "defense", "healing", "other"}
	self.stat_list = {
		attack = {
			title = STRINGS.UI.DETAILEDSUMMARYSCREEN.STATS.TITLES.attack,
			count = 0, stats = {},},
		crowd_control = {
			title = STRINGS.UI.DETAILEDSUMMARYSCREEN.STATS.TITLES.crowd_control,
			count = 0, stats = {},},
		defense = {
			title = STRINGS.UI.DETAILEDSUMMARYSCREEN.STATS.TITLES.defense,
			count = 0, stats = {},},
		healing = {
			title = STRINGS.UI.DETAILEDSUMMARYSCREEN.STATS.TITLES.healing,
			count = 0, stats = {},},
		other = {
			title = STRINGS.UI.DETAILEDSUMMARYSCREEN.STATS.TITLES.other,
			count = 0, stats = {},},
	}

	local stat_offset = 9
	-- Organize stats into their respective categories
	for i, field in pairs(self.stat_fields) do
		if i > stat_offset then
			if self.only_show_nonzero_stats and self.player_info[i] and self.player_info[i] > 0 or not self.only_show_nonzero_stats then
				local current_cat = self.stat_list[(TUNING.FORGE.STAT_CATEGORIES[field] and TUNING.FORGE.STAT_CATEGORIES[field].category or "other")]
				current_cat.count = current_cat.count + 1
				table.insert(current_cat.stats, i)
			elseif not self.player_info[i] then
				Debug:Print("stat '" .. tostring(i) .. "' has a value of nil", "error", "DetailedSummaryWidget", self.debug_mode, true)
			end
		end
	end
	-- Order the stats in each category based on its priority
	for category,data in pairs(self.stat_list) do
		table.sort(data.stats, function(a,b)
			return (TUNING.FORGE.STAT_CATEGORIES[self.stat_fields[a]] and TUNING.FORGE.STAT_CATEGORIES[self.stat_fields[a]].priority or 9999) < (TUNING.FORGE.STAT_CATEGORIES[self.stat_fields[b]] and TUNING.FORGE.STAT_CATEGORIES[self.stat_fields[b]].priority or 9999) -- Note: 9999 is used for stats with no priority so that they will be listed last
		end)
	end
end

-- Toggle Summary Screen
function DetailedSummaryWidget:DisplaySummaryScreen(display)
	if not display then--self:IsVisible() then
		self.mvp_widget:SetPosition(self.mvp_widget_original_position)
		self.mvp_widget:SetRotation(self.mvp_widget_original_rotation)
		self:Hide()
	else
		-- update widget position and rotation
		self.mvp_widget_original_position = self.mvp_widget:GetPosition()
		self.mvp_widget_original_rotation = self.mvp_widget.inst.UITransform:GetRotation()
		self.mvp_widget:SetPosition(-400,0)
		self.mvp_widget:SetRotation(self.default_rotation and self.mvp_widget_original_rotation or self.rotation)
		self:Show()
	end
	self.mvp_widget:Show()
end

-- Create text for each stat given
function DetailedSummaryWidget:CreateStatText(stats)
	local function GetTextRankingColor(rank)
		return self.display_colored_stats and (rank == 1 and UICOLOURS.GOLD or rank == 2 and UICOLOURS.SILVER or rank == 3 and UICOLOURS.BRONZE) or UICOLOURS.WHITE
	end
	local font = BODYTEXTFONT
	local stats_fontsize = 30
	local stats_spacing = 30
	local header_buffer = 5

	self.stats_current_pos_y = self.stats_current_pos_y - header_buffer
	for i, stat in pairs(stats) do
		local stat_text = self.stats_text:AddChild( Text(font, stats_fontsize, tostring(self.player_info[stat]) .. " " .. (STRINGS.UI.MVP_LOADING_WIDGET[self.current_eventid].DESCRIPTIONS[self.stat_fields[stat]] or STRINGS.MVP_LOADING_WIDGET[self.current_eventid].DESCRIPTIONS.unknown), GetTextRankingColor(self.stat_rankings[stat])) )

		local stats_text_size_x, stats_text_size_y = stat_text:GetRegionSize()
		self.stats_current_pos_y = self.stats_current_pos_y - stats_spacing
		stat_text:SetPosition(self.stats_current_pos_x + stats_text_size_x*0.5, self.stats_current_pos_y - stats_fontsize*0.5, 0)
	end
end

return DetailedSummaryWidget
