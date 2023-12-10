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

Have this inherit detailedsummarywidget?
	then add parameters for similar methods
	overwrite any methods that differ or add to methods that do everything and more
--]]
local TeamStatsWidget = Class(Widget, function(self, options, session_stats, stat_rankings, player_link, mvp_cards, mvp_widgets, current_eventid)
    ------------------ NO TOUCHY ------------------
	Widget._ctor(self, "TeamStatsWidget")

	-- Options
	self.display_colored_stats = options.display_colored_stats
	--self.track_damage_wasted_stats = options.track_damage_wasted_stats

	self.current_eventid = current_eventid

	-- Stat info
	self.players_stats = session_stats.data
	self.stat_fields = session_stats.fields
	self.stat_rankings = stat_rankings

	-- Link stats to their corresponding index
	self.stat_link = {}
	for i,j in pairs(self.stat_fields) do
		self.stat_link[j] = i
	end

	self.mvp_widgets = mvp_widgets
	-- Link player id to mvp badges
	self.mvp_link = {}
	for i,j in pairs(self.mvp_widgets) do
		self.mvp_link[j.userid] = i
	end

	self.player_link = player_link

	self:StatSetup()

	-- Display --

	-- Font constant
	local title_font = TITLEFONT
	self.header_font = BODYTEXTFONT
	self.font = BODYTEXTFONT

	-- Title Text
	self.stats_title_pos_x = -100--50
	self.stats_title_pos_y = 350
	local stats_title_fontsize = 50
	self.stats_title_spacing = 50

	self.stats_title_text = self:AddChild( Text(title_font, stats_title_fontsize, STRINGS.UI.DETAILEDSUMMARYSCREEN.TITLE, UICOLOURS.WHITE) )
	local stats_title_text_size_x, stats_title_text_size_y = self.stats_title_text:GetRegionSize()
	self.stats_title_text:SetPosition(self.stats_title_pos_x + stats_title_text_size_x*0.5, self.stats_title_pos_y - stats_title_text_size_y*0.5 - self.stats_title_spacing, 0)

	-- Header Text
	self.stats_header_fontsize = 40
	self.stats_header_spacing = 40

	-- Stats Text
	self.stats_starting_pos_x = -100
	local stats_starting_pos_y = self.stats_title_pos_y - self.stats_title_spacing
	self.stats_current_pos_x = self.stats_starting_pos_x
	self.stats_current_pos_y = stats_starting_pos_y

	self.stats_text = self:AddChild( Widget("Stats Text") )
	-- Create text for each category that has stats to display
	for i,category in pairs(self.stat_order) do
		local values = self.stat_list[category]
		if values and values.count > 0 then
			local stats_header_text = self.stats_text:AddChild( Text(self.header_font, self.stats_header_fontsize, values.title, UICOLOURS.WHITE) )
			local stats_header_text_size_x, stats_header_text_size_y = stats_header_text:GetRegionSize()
			self.stats_current_pos_y = self.stats_current_pos_y - self.stats_header_spacing
			stats_header_text:SetPosition(self.stats_current_pos_x + stats_header_text_size_x*0.5, self.stats_current_pos_y - stats_header_text_size_y*0.5, 0)
			self:CreateStatText(values.stats, category)
		end
		if i == 2 then -- TODO make this change based on height of stats, OR are we making a page for each stat type?
			self.stats_current_pos_x = self.stats_starting_pos_x + 300
			self.stats_current_pos_y = stats_starting_pos_y
		end
	end

	-- Current Rank
	self.current_rank_text = self:AddChild( Widget("Rank Text") )
	self.current_rank_text:Hide()

	-- Back Button
	local back_button_pos_x = 300
	local back_button_pos_y = -250

	self.back_button = self:AddChild( TextButton() )
	self.back_button:SetFont(title_font)
	self.back_button.text:SetSize(stats_title_fontsize)
	self.back_button:SetText(STRINGS.UI.DETAILEDSUMMARYSCREEN.TEAMSTATS.BACK)
	self.back_button.text:SetColour(UICOLOURS.WHITE)
	self.back_button:SetOnClick(function()
		self:ToggleCurrentStatDisplay()
	end)
	self.back_button:Hide()
	local stat_text_size_x, stat_text_size_y = self.back_button:GetSize()
	self.back_button:SetPosition(back_button_pos_x + stat_text_size_x*0.5, back_button_pos_y - stats_title_fontsize*0.5, 0)

	self:Hide()
end)

-- Organizes team stats into categories and orders them based on a priority
function TeamStatsWidget:StatSetup() -- TODO same method in detailedsummarywidget
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

	-- Calculate Team Stats
	local stat_offset = 9
	self.team_stats = {}
	for i, player_stats in pairs(self.players_stats) do
		for stat_num, val in pairs(player_stats) do
			if stat_num > stat_offset then
				self.team_stats[stat_num] = (self.team_stats[stat_num] or 0) + (val or 0)
			end
		end
	end

	-- Organize stats into their respective categories
	for i, field in pairs(self.stat_fields) do
		if i > stat_offset then
			if not self.team_stats[i] then
				Debug:Print("DetailedSummaryWidget - stat '" .. tostring(i) .. "' has a value of nil", "error", nil, true)
			else
				local current_cat = self.stat_list[(TUNING.FORGE.STAT_CATEGORIES[field] and TUNING.FORGE.STAT_CATEGORIES[field].category or "other")]
				current_cat.count = current_cat.count + 1
				table.insert(current_cat.stats, i)
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

-- Create text for each stat given
function TeamStatsWidget:CreateStatText(stats, category)
	local font = BODYTEXTFONT
	local stats_fontsize = 30
	local stats_spacing = 30
	local header_buffer = 5

	self.stats_current_pos_y = self.stats_current_pos_y - header_buffer
	for i, stat in pairs(stats) do
		local stat_text = self.stats_text:AddChild( TextButton() )
		stat_text:SetFont(font)
		stat_text.text:SetSize(stats_fontsize)
		stat_text:SetText(tostring(self.team_stats[stat]) .. " " .. (STRINGS.UI.MVP_LOADING_WIDGET[self.current_eventid].DESCRIPTIONS[self.stat_fields[stat]] or STRINGS.UI.MVP_LOADING_WIDGET[self.current_eventid].DESCRIPTIONS.unknown))
		stat_text:SetTextColour(UICOLOURS.WHITE)
		stat_text:SetTextFocusColour(UICOLOURS.GOLD_CLICKABLE)

		-- Only update current stat if the stat has a value greater than 0
		stat_text:SetOnClick(function()
			if self.team_stats[stat] > 0 then
				self:UpdateCurrentStat(stat)
			end
		end)
		stat_text:Show()

		local stat_text_size_x, stat_text_size_y = stat_text:GetSize()
		self.stats_current_pos_y = self.stats_current_pos_y - stats_spacing
		stat_text:SetPosition(self.stats_current_pos_x + stat_text_size_x*0.5, self.stats_current_pos_y - stats_fontsize*0.5, 0)
	end
end

-- Create the players rank text for the given stat
function TeamStatsWidget:UpdateCurrentStat(current_stat)
	local function GetTextRankingColor(rank)
		return self.display_colored_stats and (rank == 1 and UICOLOURS.GOLD or rank == 2 and UICOLOURS.SILVER or rank == 3 and UICOLOURS.BRONZE) or UICOLOURS.WHITE
	end
	local max_players_displayed = 10
	self.current_stat = current_stat
	self.current_rank_text:KillAllChildren() -- Do this to get rid of previous rank text

	-- Create text for each player to display, max of 10 players, players must have a stat value > 0 to be displayed
	local buffer = 10
	local current_pos_x = self.stats_starting_pos_x
	local current_pos_y = self.stats_title_pos_y - self.stats_title_spacing - buffer
	local count = 1
	local previous_rank = 1
	while self.stat_rankings[current_stat] and self.stat_rankings[current_stat][count] and self.stat_rankings[current_stat][count].val > 0 and count <= max_players_displayed do
		local stat_info = self.stat_rankings[current_stat][count]

		-- Check for ties, only update rank if no tie is found
		if count > 1 and stat_info.val < self.stat_rankings[current_stat][count - 1].val then
			previous_rank = count
		end

		local stat_rank_text = self.current_rank_text:AddChild( Text(self.header_font, self.stats_header_fontsize, previous_rank .. ": " .. tostring(self.mvp_widgets[self.mvp_link[stat_info.player]].playername:GetString()) .. " - " .. tostring(stat_info.val), GetTextRankingColor(previous_rank)) )

		local stats_text_size_x, stats_text_size_y = stat_rank_text:GetRegionSize()
		current_pos_y = current_pos_y - self.stats_header_spacing
		stat_rank_text:SetPosition(current_pos_x + stats_text_size_x*0.5, current_pos_y - self.stats_header_fontsize*0.5, 0)

		count = count + 1
	end

	-- Title
	self.stats_title_text:SetString(STRINGS.UI.DETAILEDSUMMARYSCREEN.TEAMSTATS.STATHEADERS[self.stat_fields[current_stat] or "unknown"])
	local stats_title_text_size_x, stats_title_text_size_y = self.stats_title_text:GetRegionSize()
	self.stats_title_text:SetPosition(self.stats_title_pos_x + stats_title_text_size_x*0.5, self.stats_title_pos_y - stats_title_text_size_y*0.5 - self.stats_title_spacing, 0)

	-- Display the player rankings for the given stat
	self:ToggleCurrentStatDisplay()
end

-- Resets the mvp widget to its original state
function TeamStatsWidget:ResetMVP()
	self.mvp_info.mvp:SetPosition(self.mvp_info.original_position)
	self.mvp_info.mvp:SetRotation(self.mvp_info.original_rotation)
	self.mvp_info.mvp.title:SetString(self.mvp_info.original_title)
	self.mvp_info.mvp.score:SetString(self.mvp_info.original_score)
	self.mvp_info.mvp.description:SetString(self.mvp_info.original_description)
	self.mvp_info.mvp:Hide()

	self.mvp_info = nil
end

-- Toggles between the team stat screen and the stat rank screen
function TeamStatsWidget:ToggleCurrentStatDisplay()
	if self.current_rank_text:IsVisible() then
		self.current_rank_text:Hide()
		self:SetMVP(self.mvp_widgets[1], "0")
		self.stats_text:Show()
		self.back_button:Hide()
		self.stats_title_text:SetString(STRINGS.UI.DETAILEDSUMMARYSCREEN.TEAMSTATS.TITLE)
		local stats_title_text_size_x, stats_title_text_size_y = self.stats_title_text:GetRegionSize()
		self.stats_title_text:SetPosition(self.stats_title_pos_x + stats_title_text_size_x*0.5, self.stats_title_pos_y - stats_title_text_size_y*0.5 - self.stats_title_spacing, 0)
	-- Only show stat screen the selected stat has value
	elseif self.team_stats[self.current_stat] > 0 then
		self.current_rank_text:Show()
		self:SetMVP(self.mvp_widgets[self.mvp_link[self.stat_rankings[self.current_stat][1].player]], self.current_stat)
		self.stats_text:Hide()
		self.back_button:Show()
	end
end

-- Displays the given mvp to the left of the total stats.
-- If stat == "0" then it will display the mvps best stat else it will display the given stat
function TeamStatsWidget:SetMVP(mvp_widget, stat)
	if self.mvp_info ~= nil then
		self:ResetMVP()
	end

	self.mvp_info = {
		mvp = mvp_widget,
		original_position = mvp_widget:GetPosition(),
		original_rotation = mvp_widget.inst.UITransform:GetRotation(),
		original_title = mvp_widget.title:GetString(),
		original_score = mvp_widget.score:GetString(),
		original_description = mvp_widget.description:GetString(),
	}
	-- self.players_stats[self.player_link[mvp_widget.userid]][self.stat_link[stat]]
	if stat ~= "0" then
		self:RefreshMVP(stat)
	else
		self.current_stat = nil
	end

	mvp_widget:SetPosition(-400, 0)
	mvp_widget:SetRotation(0)
	mvp_widget:Show()
end

-- Finds and sets the mvp to the person with the highest value of the given stat
function TeamStatsWidget:RefreshMVP(stat)
	if self.mvp_info ~= nil and stat ~= "0" then
		local stat_name = self.stat_fields[stat]
		local score = self.players_stats[self.player_link[self.mvp_info.mvp.userid]][stat]
		local stat_str = stat_name .. (TUNING.FORGE.DEFAULT_FORGE_TITLES[stat_name] and TUNING.FORGE.DEFAULT_FORGE_TITLES[stat_name].tier2 and (TUNING.FORGE.DEFAULT_FORGE_TITLES[stat_name].tier2 <= (score or 0)) and "2" or "")

		self.mvp_info.mvp.title:SetString(STRINGS.UI.MVP_LOADING_WIDGET[self.current_eventid].TITLES[stat_str] or tostring(stat_name))
		self.mvp_info.mvp.score:SetString(score)
		self.mvp_info.mvp.description:SetString((STRINGS.UI.MVP_LOADING_WIDGET[self.current_eventid].DESCRIPTIONS[stat_name] or STRINGS.MVP_LOADING_WIDGET[self.current_eventid].DESCRIPTIONS.unknown))
	end
end

return TeamStatsWidget
