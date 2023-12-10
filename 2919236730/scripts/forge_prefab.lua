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

require "class"
require "util"
require "admin_commands"

local stat_list = {
	DAMAGE = {
		name = STRINGS.UI.ADMINMENU.STATS.DAMAGE,
		val_type = "number",
	},
	COOLDOWN = {
		name = STRINGS.UI.ADMINMENU.STATS.COOLDOWN,
		val_type = "number",
	},
	SPEEDMULT = {
		name = STRINGS.UI.ADMINMENU.STATS.SPEEDMULT,
		val_type = "multiplier",
	},
	BONUSDAMAGE = {
		name = STRINGS.UI.ADMINMENU.STATS.BONUSDAMAGE,
		val_type = "multiplier",
	},
	BONUS_COOLDOWNRATE = {
		name = STRINGS.UI.ADMINMENU.STATS.BONUS_COOLDOWNRATE,
		val_type = "multiplier",
	},
	HEALINGRECEIVEDMULT = {
		name = STRINGS.UI.ADMINMENU.STATS.HEALINGRECEIVEDMULT,
		val_type = "multiplier",
	},
	HEALINGDEALTMULT = {
		name = STRINGS.UI.ADMINMENU.STATS.HEALINGDEALTMULT,
		val_type = "multiplier",
	},
	MAGE_BONUSDAMAGE = {
		name = STRINGS.UI.ADMINMENU.STATS.MAGE_BONUSDAMAGE,
		val_type = "multiplier",
	},
	DEFENSE = {
		name = STRINGS.UI.ADMINMENU.STATS.DEFENSE,
		val_type = "multiplier",
	},
	HEALTH = {
		name = STRINGS.UI.ADMINMENU.STATS.HEALTH,
		val_type = "number",
	},
	RUNSPEED = {
		name = STRINGS.UI.ADMINMENU.STATS.RUNSPEED,
		val_type = "number",
	},
}

-- TODO adjust stat sorter?
function StatDecoder(stats)
	local decoded_stats = {}
	local stat_value = 0

	for stat, value in pairs(stats) do
		if stat_list[stat] then
			local stat_name = stat_list[stat].name
			if stat_list[stat].val_type == "multiplier" then
				if stat == "SPEEDMULT" then
					decoded_stats[stat_name] = "+" .. ((value - 1) * 100) .. "%"
					stat_value = stat_value + (value - 1)
				else
					decoded_stats[stat_name] = (value > 0 and "+" or "") .. (value * 100) .. "%"
					if stat == "DEFENSE" then
						stat_value = stat_value + value * 100
					else
						stat_value = stat_value + value
					end
				end
			else
				decoded_stats[stat_name] = value
				stat_value = stat_value + value
			end
		end
	end

	return decoded_stats, stat_value
end

-- TODO need better positioning. The center is currently set to be between the icon and text but we want the center to be the center as a whole.
-- Display stats of item in rows of 3 below item name
local function UpdateItemStats(self)
	if self.item.stats then
		local col = 1
		local row = 1
		local max_item_per_row = 3
		local x_center = -25
		local y_offset = 70
		local y_offset_per_row = 20
		local spacing = 10
		local current_y = 0
		local total_stats = self.item.stat_count
		local final_col_count = total_stats % 3
		local x_spacing = 80
		local x_offset = 0
		local text_opts = {}
		local icon_info = {}
		for stat,value in pairs(self.item.stats) do
			-- Adjust position
			if total_stats - max_item_per_row >= 0 then
				x_offset = x_spacing * (col - 2)
			elseif final_col_count == 2 then
				x_offset = -x_spacing/2 + x_spacing * (col - 1)
			else
				x_offset = 0
			end

			-- Create/Update Stat Widget
			icon_info.tex = STRINGS.REFORGED.STATS[string.upper(tostring(stat))] and (STRINGS.REFORGED.STATS[string.upper(tostring(stat))].ICON .. ".tex") or "torch.tex"
			icon_info.opts = {hovertext = tostring(stat)}
			local stat_text = tostring(value) -- TODO need to add percent when necessary or color code based on positive/negative numbers? green/red?
			if self.text_icons[stat] then
				self.text_icons[stat].text:SetString(tostring(value))
				self.text_icons[stat]:Show()
			else
				self:AddTextIcon(stat, tostring(value), text_opts, icon_info)
			end
			local pos = self.text_icons[stat]:GetPosition()
			self.text_icons[stat]:SetPosition(x_center + x_offset or pos.x, current_y or pos.y)

			-- New Row Check
			col = col + 1
			if col > max_item_per_row then
				row = row + 1
				col = 1
				total_stats = total_stats - max_item_per_row
				current_y = y_offset + y_offset_per_row * row
			end
		end
	end
end

local function MenuResetFN(self)
	if self.highlight and self.has_ents then
		local selected = self.spinners[1]:GetSelectedData()
		if selected:HasTag("inspectable") then
			selected.AnimState:SetHighlightColour()
			self.highlight = false
			self.has_ents = false
		end
	end
end

local TEXT_WIDTH = 64 * 3 + 30
local equipment = {ARMOR = true, HELMS = true, WEAPONS = true}
local function MenuRefreshFN(self)
	UpdateItemStats(self)
	local category = self.item.type

	-- Spinners
	self:EnsureSpinnersExist(equipment[category] and 1 or 2)

	-- Ent Spinner
	local players_spinner = self.spinners[1]
	players_spinner:SetScale(.75,.75,.75)
	players_spinner:SetPosition(320, -70, 0)
	local players_spinner_opts = {}
	for _,player in pairs(AllPlayers) do
		local atlas = softresolvefilepath("images/avatars/avatar_" .. player.prefab .. ".xml") and "images/avatars/avatar_" .. player.prefab .. ".xml" or "images/avatars.xml"
		local tex = "avatar_" .. tostring(player.prefab) .. ".tex"
		if player == ThePlayer then
			table.insert(players_spinner_opts, 1, {data = player, image = {atlas, tex}, hover_text = player.name})
		else
			table.insert(players_spinner_opts, {data = player, image = {atlas, tex}, hover_text = player.name})
		end
		self.has_ents = true -- TODO figure this out
	end
	players_spinner:SetOptions(players_spinner_opts)
	players_spinner:SetSelected(ThePlayer)
	local init_sel = players_spinner:GetSelectedData()
	players_spinner:SetHoverText(tostring(init_sel.name))
	init_sel.AnimState:SetHighlightColour(255/255, 109/255, 100/255, 0)
	self.highlight = true
	players_spinner.fgimage:Show()
	players_spinner:SetOnChangedFn(function(selected, old)
		if players_spinner.fgimage then
			players_spinner:SetHoverText(tostring(selected.name))
		end
		selected.AnimState:SetHighlightColour(255/255, 109/255, 100/255, 0)
		old.AnimState:SetHighlightColour()
		self.highlight = true
	end)
	players_spinner.width = 150
	players_spinner:Layout()
	players_spinner:Show()

	-- Spawn Count Spinner
	local count_spinner = self.spinners[2]
	if not equipment[category] then
		local spinner_data = {}
		local min_count = 1
		local max_count = 10
		for i = min_count,max_count do
			local current_data = {text = tostring(i), data = i}
			spinner_data[i] = current_data
		end
		count_spinner:SetOptions(spinner_data)
		count_spinner:SetPosition(380, -105, 0)
		count_spinner:SetScale(1,1,1)
		count_spinner.width = 100
		count_spinner:Layout()
		count_spinner:Show()
	end

	-- Buttons
	self:EnsureButtonsExist(category == "WEAPONS" and 4 or category == "ENEMIES" and 3 or 2)
	local current_button_index = 1
	-- Equip Button
	if equipment[category] then
		local equip_button = self.buttons[current_button_index]
		equip_button:Show()
		equip_button:Enable()
	    equip_button.image:SetScale(.45, .7)
		equip_button:SetText(STRINGS.UI.ADMINMENU.BUTTONS.EQUIP)
		equip_button:SetPosition(370, -105, 0)
		equip_button:SetScale(.75,.75,.75)
		equip_button:SetOnClick(function()
			local player = players_spinner:GetSelectedData()
			EquipItem(self.item.name, players_spinner:GetSelectedData() or ThePlayer)
		end)
		current_button_index = current_button_index + 1
	end

	-- Spawn Button
	local spawn_button = self.buttons[current_button_index]
	spawn_button:SetPosition(270, -105, 0)
	spawn_button:SetScale(.75,.75,.75)
	spawn_button.image:SetScale(.45, .7)
	spawn_button:SetText(STRINGS.UI.ADMINMENU.BUTTONS.SPAWN)
	spawn_button:SetOnClick(function()
		self.item:admin_fn({player = players_spinner:GetSelectedData() or ThePlayer, name = self.item.name, amount = count_spinner and count_spinner:GetSelectedData() or 1})
	end)
	spawn_button:Show()
	current_button_index = current_button_index + 1

	-- Description/Ability Buttons
	if category == "ENEMIES" or category == "WEAPONS" then
		self.show_desc = true
		--Description
		local description_button = self.buttons[current_button_index]
	    description_button:SetScale(.7,.7,.7)
	    description_button.image:SetScale(.45, .7)
	    description_button:SetPosition(270, 50, 0)
		description_button:SetText(STRINGS.UI.ADMINMENU.BUTTONS.DESCRIPTION)
		description_button:SetOnClick(function()
			if not self.show_desc then
				self.show_desc = true
				self.desc:SetMultilineTruncatedString(STRINGS.REFORGED[category][string.upper(self.item.name)] and STRINGS.REFORGED[category][string.upper(self.item.name)].DESC or tostring(self.item.name), 4, TEXT_WIDTH, self.smallfonts and 40 or 33, true, true)
			end
		end)
		description_button:Show()
		current_button_index = current_button_index + 1
		-- Abilities
		local abilities_button = self.buttons[current_button_index]
	    abilities_button:SetScale(.7,.7,.7)
	    abilities_button.image:SetScale(.45, .7)
	    abilities_button:SetPosition(370, 50, 0)
		abilities_button:SetText(STRINGS.UI.ADMINMENU.BUTTONS.ABILITIES)
		abilities_button:SetOnClick(function()
			if self.show_desc then
				self.show_desc = false
				local abilities_str = ""
				local count = 0
				local abilities_num = self.item.ability_count
				if self.item.abilities then
					for i, ability in pairs(self.item.abilities) do
						--Lunge - Lunge that does x damage
						--abilities_str = abilities_str .. tostring(STRINGS.REFORGED[category][string.upper(self.item.name)].ABILITIES[string.upper(ability)].NAME) or tostring(ability)
						abilities_str = abilities_str .. tostring(ability.NAME)
						count = count + 1
						if abilities_num > count then
							abilities_str = abilities_str .. ", "
						end
						--abilities_str = abilities_str .. tostring(ability.NAME) .. " - " .. tostring(ability.DESC) .. "\n"
					end
				else
					abilities_str = STRINGS.UI.ADMINMENU.NO_ABILITIES
				end
				--#STRINGS.REFORGED[category][string.upper(self.item.name)].ABILITIES * 2
				self.desc:SetMultilineTruncatedString(tostring(abilities_str), 4, TEXT_WIDTH, self.smallfonts and 40 or 33, true, true)
			end
		end)
		abilities_button:Show()
	end
end

local num = 0
AllForgePrefabs = {}
local DEFAULT_MOD = "FORGE"
ForgePrefab = Class(Prefab, function(self, name, fn, assets, deps, force_path_search, category, mod_id, atlas, image, swap_build, swap_data, admin_fn_override)
	------------------------------------------
	-- Update prefab based on the difficulty
	local _oldfn = fn
	fn = function()
		local inst = _oldfn()
		--COMMON_FNS.LoadDifficulty(name, inst) -- TODO remove?
		--COMMON_FNS.LoadMutators(name, inst) -- TODO remove?
		return inst
	end
	------------------------------------------
	Prefab._ctor(self, name, fn, assets, deps, force_path_search)

    self.name		 	 = name
    self.type 			 = category
    self.menu_refresh_fn = MenuRefreshFN
    self.menu_reset_fn   = MenuResetFN

    self.atlas	 		= (atlas and resolvefilepath(atlas)) or resolvefilepath("images/inventoryimages.xml")
    self.imagefn 		= type(image) == "function" and image or nil
    self.image 			= self.imagefn == nil and image or ("torch.tex")

	--print("[ForgePrefab] name: " .. tostring(name))

	-- TODO make this a parameter so you can set the admin function
	-- spawn prefab function
	self.admin_fn = admin_fn_override or function(self, data)
		SpawnEntity(data.name, data.amount, data.player, category == "PETS")
	end

	--self.damage_type = stats.TYPE or "physical"
	local tuning_values = CheckTable(TUNING, mod_id or DEFAULT_MOD, string.upper(name))
	if tuning_values then
		self.stats, self.stat_value = StatDecoder(tuning_values)
		self.stat_count = 0
		local count = 0
		if self.stats then
			count = 0
			for i,s in pairs(self.stats) do
				count = count + 1
			end
			self.stat_count = count
		end
	end

	self.abilities = CheckTable(STRINGS, "REFORGED", category, string.upper(name), "ABILITIES") -- TODO should mods have their own table like stats?
	self.ability_count = 0
	if self.abilities then
		local count = 0
		for i,a in pairs(self.abilities) do
			count = count + 1
		end
		self.ability_count = count
	end

	--Used for lobbyscreen equips
	self.swap_build = swap_build
	local commonswapdata = {
		common_head1 = {swap = {"swap_hat"}, hide = {"HAIR_NOHAT", "HAIR", "HEAD"}, show = {"HAT", "HAIR_HAT", "HEAD_HAT"}},
		common_head2 = {swap = {"swap_hat"}, show = {"HAT"}},
		common_body = {swap = {"swap_body"}},
		common_hand = {swap = {"swap_object"}, hide = {"ARM_normal"}, show = {"ARM_carry"}}
	}
	self.swap_data = commonswapdata[swap_data] ~= nil and commonswapdata[swap_data] or swap_data

	self.mod_id = mod_id

	-- Sort Key
	self.sortkey = tuning_values and tuning_values.WEIGHT or self.stat_value or num

	-- TODO use this to prevent events from adding item drops to the lootdropper
	if category == "ENEMIES" or category == "PETS" then

	end

    num = num + 1
    EnsureTable(AllForgePrefabs, category or "OTHER", self.mod_id or DEFAULT_MOD)[name] = self -- TODO change to "REFORGED"
end)

function GetValidForgePrefab(name)
	for cat,mod_data in pairs(AllForgePrefabs) do
		for mod_id,prefabs in pairs(mod_data) do
			if prefabs[name] then
				return prefabs[name]
			end
		end
	end
end

function IsForgePrefabValid(name)
    return GetValidForgePrefab(name) ~= nil
end

function RemoveAllForgePrefabs()
    AllForgePrefabs = {}
    num = 0
end
