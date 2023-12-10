--[[
TODO
Possible Displays: Maybe add waveset info by the map? number of rounds? boss name? description?
        Reset Button               General      Admin Button|Vote Button
            Presets: Forge                           Map Display
               Mode: Forge
            Waveset: Classic
                Map: Lavaarena
----------------------------------------------------------------------------------
                                   Mutators
 Damage: dmg_spinner           Redlight/Greenlight [ ] Shields Can't be broken [ ]
 Health: health_spinner          Invisible Players [ ]         Super Knockback [ ]
  Speed: speed_spinner              Invisible Mobs [ ] Use icons instead?
Defense: defense_spinner     Healing Circle Sleeps [ ]

Game Settings
	General:
		Presets: Custom, Forge, Forge 2.0, Expansions, etc.
		Mode: Forge, ForgedForge (this will have changes to passives, maybe targeting, etc., should these also be mutators?)
		Waveset:
		Map:
	Mutators:
		Sliders (Percent) (might have to do spinners)
			Damage, Health, Speed, Defense
		On/Off button (or checkbox)
			Redlight/Greenlight
			Invisible Players
			Invisible Mobs
			Healing circle sleeps
			Shields can't be broken
			Super knockback

Buttons
	Reset Options
		resets all options to the current settings
			loop through selected settings and change them to current settings.
	Vote Setting
		calls a vote to change game settings to the currently selected settings
	Admin Change
		immediately changes the game settings to the currently selected settings
		This is the same button as Vote Setting, but if an admin hits it then no vote is called and the settings are immediately applied
		Make the icon different that the Vote Settings Button?

Put all strings into string file

Hide Map Selection if expansion is not ready before release.

Dynamically update all possible settings when changing the selected map or waveset. This means that if a map is selected and it only has 3 spawners then only display wavesets that use 3 or less spawners. The same goes for a selected waveset. If a waveset uses 3 spawners only display maps that have 3 or more spawners. TODO should it just match so that the waveset functions correctly? or does it matter?

Have the ability to save custom presets???

Checkbox mutators do not get set correctly when clicking the info button on a different screen
	seems that each checkbox has the opposite value...wtf
	text does not change to white either...
In the same scenario the tab Completed Quests does not have the correct font settings.

Need to prevent the change settings button (vote/admin) from doing anything if there are no new settings selected. Ignore preset.

Apply dark boxes behind text?
look at other games for examples
--]]
local UserCommands = require "usercommands"
local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"
local TextButton = require "widgets/textbutton"
local ImageButton = require "widgets/imagebutton"
--local TextWithIcon = require "widgets/textwithiconwidget"
local easing = require "easing"
local Widget = require "widgets/widget"
local TEMPLATES = require "widgets/redux/templates"
local Spinner = require "widgets/spinner"
local GREATER_THAN = 1
local LESS_THAN = 2
local ALIGN_L = 1
local ALIGN_C = 0
local ALIGN_R = -1
require("stringutil")

local nil_str = "nil"
local function unparsecommand(command, params) -- TODO commonfn?
    local s = command.name
    for i,paramname in ipairs(command.params) do
        -- handle "optional" params -- once we're missing one, the whole string is moot, so just bail and assume the command fn will nil check.
        if params[paramname] == nil then
            if command.paramsoptional and command.paramsoptional[i] then
                params[paramname] = nil_str
            else
                print("Building a command without enough arguments!")
                break
            end
        end
        s = s.. " " .. params[paramname]
    end
    return s
end

local function MakeDetailsLine(details_root, x, y, scale, image_override)
	local value_title_line = details_root:AddChild(Image("images/quagmire_recipebook.xml", image_override or "quagmire_recipe_line.tex"))
	value_title_line:SetScale(scale, scale)
	value_title_line:SetPosition(x, y)
	return value_title_line
end

local function MakeSpinner(labeltext, spinnerdata, onchanged_fn, initial_data, options)
	local spacing = options and options.spacing or 5
	local font = options and options.font or HEADERFONT
	local font_size = options and options.font_size or 30

	local width_label = options and options.width_label or 150 -- TODO make dynamic OR change the size of the runs so that it is smaller
	local width_spinner = options and options.width_spinner or 300
	local height = options and options.height or 50

	local total_width = width_label + width_spinner + spacing
	local wdg = Widget("labelspinner")
	wdg.label = wdg:AddChild( Text(font, font_size, labeltext) )
	wdg.label:SetPosition( (-total_width/2)+(width_label/2), 0 )
	wdg.label:SetRegionSize( width_label, height )
	wdg.label:SetHAlign( ANCHOR_RIGHT )
	wdg.label:SetColour(UICOLOURS.BROWN_DARK)

	local lean = true
	wdg.spinner = wdg:AddChild(Spinner(spinnerdata, width_spinner, height, {font = font, size = font_size}, nil, "images/quagmire_recipebook.xml", nil, lean))
	wdg.spinner:SetTextColour(UICOLOURS.BROWN_DARK)
	wdg.spinner:SetOnChangedFn(onchanged_fn)
	wdg.spinner:SetPosition((total_width/2)-(width_spinner/2), 0)

	wdg.spinner:SetSelected(initial_data)

	return wdg
end

--[[
Creates a panel in the Lavaarena book that displays the current game settings. These settings can be adjusted and a vote can be called to apply the changes. Admins can immediately apply their changes without needing to vote.
--]]
local GameSettingsPanel = Class(Widget, function(self, options)
    ------------------ NO TOUCHY ------------------
	Widget._ctor(self, "GameSettingsPanel")
	self.settings = { -- TODO meta table? on set or insert? for selected check current, if it matches then set selecteds value to nil
		current = REFORGED_SETTINGS.gameplay,
		selected = { -- only has settings that differ from the current settings
			mutators = {
			},
		},
	}
	------------------------------------------
	self.icon_sizes = {
		mutator = {25, 25},
		button  = {50,50},
	}
	------------------------------------------
	local panel_root = self
	------------------------------------------
	self.top_root = self:AddChild(Widget("top_root")) -- Rename? or call method to build each group?
	self.top_root:SetPosition(0, 100)
	self.top_root:SetScale(.66)
	------------------------------------------
	self.bottom_root = self:AddChild(Widget("bottom_root")) -- Rename? or call method to build each group?
	self.bottom_root:SetPosition(0, -135)
	self.bottom_root:SetScale(.66)
	------------------------------------------
	-- General Settings Display
	self.general_display = self.top_root:AddChild( self:BuildGeneralDisplay() )
	--self.general_display:SetScale(.66)
	------------------------------------------
	-- Line Break between settings
	local line_break = self:AddChild(Image("images/lavaarena_unlocks.xml", "divider.tex"))
	local line_break_width, line_break_height = line_break:GetSize()
	line_break:SetPosition(0, -line_break_height/2)
	line_break:SetScale(.68)
	------------------------------------------
	-- Mutator Settings Display
	self.mutator_display = self.bottom_root:AddChild( self:BuildMutatorDisplay() )
	------------------------------------------
	self.parent_default_focus = self
end)

--[[------------------------------
			Mutator Display
---------------------------------]]
function GameSettingsPanel:BuildGeneralDisplay()
	local general_root = Widget("general_root")

	-- Display for each outcome text
	local function RunTextItem(title_text, val_text, title_size, text_size, pos_x, pos_y, right_align, color)
		local title = general_root:AddChild(Text(HEADERFONT, title_size, title_text, color))
		local title_w, title_h = title:GetRegionSize()
		local x = right_align and title_w/2 or 0
		title:SetPosition(pos_x + x, pos_y)
		if val_text then
			local text = general_root:AddChild(Text(HEADERFONT, text_size, val_text, color))
			local text_w, text_h = text:GetRegionSize()
			local x = right_align and text_w/2 or 0
			text:SetPosition(pos_x + title_w + x, pos_y)
		end
	end
	local function RunCheck()
		return #self.current_forge_runs > 0
	end

	local y_buffer = -110
	local border_buffer = 10
	-- Background Image
	local bg = general_root:AddChild(Image("images/lavaarena_unlocks.xml", "box6.tex"))
    bg:SetScale(1.1, .75)
	local bg_width, bg_height = bg:GetSize()
	bg:SetPosition(0, 0)--bg_height/2 + y_buffer)

	local current_y_offset = bg_height/2 + y_buffer--125 + bg_height/2 + y_buffer--top - 11
	local current_x_offset = 425
	local x_offset = 0
	local title_font_size = 34
	local text_font_size = 22

	local outcome = (self.current_run and self.current_run.outcome) or nil

	-- Title text
	RunTextItem(STRINGS.UI.GAME_SETTINGS_PANEL.TITLE, nil, title_font_size, nil, 0, current_y_offset - border_buffer, false, UICOLOURS.BROWN_DARK)
	local buttons = {}
	-- Save Settings Button
	if REFORGED_SETTINGS.vote.game_settings_panel and not _G.TheWorld.net.components.lavaarenaeventstate:IsInProgress() then
		buttons.save_settings = general_root:AddChild( ImageButton("images/reforged.xml", "gamesettings_vote.tex", nil, nil, nil, nil) )
		buttons.save_settings:SetHoverText(STRINGS.UI.GAME_SETTINGS_PANEL.VOTE)
		buttons.save_settings:ScaleImage(unpack(self.icon_sizes.button))
		buttons.save_settings:SetOnClick(function()
			if TheWorld.net.replica.lobbyvote and not (TheWorld.net.replica.lobbyvote:IsVoteActive() or TheWorld.net.replica.lobbyvote:IsWorldResetting()) and _G.REFORGED_SETTINGS.vote.game_settings_panel and not self:HasNoSelectedSettings() then
				local settings_str = SerializeTable(self.settings.selected)
				UserCommands.RunUserCommand("lobbyvotestart", {command = "settings", force_success = "false", params_str = settings_str}, TheNet:GetClientTableForUser(TheNet:GetUserID()))
			else
				-- TODO display error message: Cannot vote while a vote is already in progress!
			end
		end)
	end
	-- Force Settings Button
	if TheNet:GetIsServerAdmin() and not _G.TheWorld.net.components.lavaarenaeventstate:IsInProgress() then
		buttons.force_settings = general_root:AddChild( ImageButton("images/reforged.xml", "gamesettings_force.tex", nil, nil, nil, nil) )
		buttons.force_settings:SetHoverText(STRINGS.UI.GAME_SETTINGS_PANEL.FORCE)
		buttons.force_settings:ScaleImage(unpack(self.icon_sizes.button))
		buttons.force_settings:SetOnClick(function()
			if TheWorld.net.replica.lobbyvote and not (TheWorld.net.replica.lobbyvote:IsVoteActive() or TheWorld.net.replica.lobbyvote:IsWorldResetting()) and _G.REFORGED_SETTINGS.vote.game_settings_panel and not self:HasNoSelectedSettings() then
				local settings_str = SerializeTable(self.settings.selected)
				UserCommands.RunUserCommand("lobbyvotestart", {command = "settings", force_success = "true", params_str = settings_str}, TheNet:GetClientTableForUser(TheNet:GetUserID()))
			else
				-- TODO display error message: Cannot vote while a vote is already in progress!
			end
		end)
	end
	-- Reset Settings Button
	buttons.reset_settings = general_root:AddChild( ImageButton("images/reforged.xml", "gamesettings_refresh.tex", nil, nil, nil, nil) )
	buttons.reset_settings:SetHoverText(STRINGS.UI.GAME_SETTINGS_PANEL.RESET)
	buttons.reset_settings:ScaleImage(unpack(self.icon_sizes.button))
	buttons.reset_settings:SetOnClick(function()
		self:ChangeSettings(self.settings.current)
	end)

	-- Position the buttons
	local count = 1
	local spacing = 10
	local button_x_offset = -(#buttons - 1) / 2 * (self.icon_sizes.button[1] + spacing) - 85
	for _,button in pairs(buttons) do
		button:SetPosition(current_x_offset + button_x_offset, current_y_offset + 5)
		count = count + 1
		button_x_offset = button_x_offset + self.icon_sizes.button[1] + spacing
	end

	-- Settings
	self.spinners = {}
	local spinner_height = 50
	local bg_height_bottom = bg_height - 150 - 25 -- 150 is top part, 25 is the bottom cutoff
	--current_y_offset = bg_height/2 - 150 - bg_height_bottom / 2 + (#items - 1) * spinner_height / 2
	--w:SetPosition(-current_x_offset + 50, current_y_offset)
	--current_y_offset = current_y_offset - spinner_height
	local top_y_offset = bg_height/2 - 150 - border_buffer/2 - spinner_height / 2
	local bottom_y_offset = top_y_offset - 100 - 10
	local left_x_offset = -current_x_offset + 50 - 10
	local right_x_offset = current_x_offset - 50
	local desc_width = 400
	local desc_lines = 2
	local desc_max_char = 100
	local function CreateDescription(str, x, y)
		local description = general_root:AddChild( Text(HEADERFONT, 25, "", UICOLOURS.BROWN_DARK) )
		description:SetPosition(x, y - spinner_height)
		description:SetHAlign(ANCHOR_LEFT)
		description:SetVAlign(ANCHOR_TOP) -- TODO doesn't seem to work...
		description:SetMultilineTruncatedString(str or STRINGS.REFORGED.unknown, desc_lines, desc_width, desc_max_char, nil, true)
		return description
	end
	local function CreateDivider(x, y)
		local divider = general_root:AddChild(Image("images/ui.xml", "line_horizontal_4.tex"))
		local divider_y_offset = 30
		divider:SetSize(400, 5)
		divider:SetPosition(x, y + divider_y_offset)
		divider:SetTint(107/255, 84/255, 58/255, 0.5)
	end
	CreateDivider(left_x_offset, bottom_y_offset)
	CreateDivider(right_x_offset, bottom_y_offset)
	------------
	-- Preset --
	------------
	local function PresetOnChangedFN(selected, old)-- TODO need to make preset display Custom when changing the other options
		self:UpdateSetting("preset", selected)
		if selected ~= "custom" then
			self.loading_preset = true
			local preset = REFORGED_DATA.presets[selected]
			if preset.mode and self.spinners.mode then
				self.spinners.mode.spinner:SetSelected(preset.mode)
			end
			if preset.difficulty and self.spinners.difficulty then
				self.spinners.difficulty.spinner:SetSelected(preset.difficulty)
			end
			if preset.gametype and self.spinners.gametype then
				self.spinners.gametype.spinner:SetSelected(preset.gametype)
			end
			if preset.waveset and self.spinners.waveset then
				self.spinners.waveset.spinner:SetSelected(preset.waveset)
			end
			if preset.map and self.spinners.map then
				self.spinners.map.spinner:SetSelected(preset.map)
			end
			for _,mutator in pairs(self.mutator_spinners or {}) do
				self.settings.selected.mutators[mutator] = preset.mutators[mutator] or 1
		    end
		    if self.slider_mutators_list then
		    	self.slider_mutators_list:RefreshView()
		    end
		    for mutator,checkbox in pairs(self.mutator_checkboxes or {}) do
	        	self.mutator_checkboxes[mutator].button.onclick(preset.mutators[mutator] or false)
			end
			self.loading_preset = nil
		end
	end

	self.spinners.preset = general_root:AddChild(MakeSpinner(STRINGS.UI.GAME_SETTINGS_PANEL.PRESET, self:GetPresets(), PresetOnChangedFN, self.settings.current.preset, {width_label = 100, width_spinner = 275}))
	self.spinners.preset:SetPosition(-425, bg_height/2 + y_buffer + 5)

	----------
	-- Mode --
	----------
	local mode_description = CreateDescription(STRINGS.REFORGED.MODES[self.settings.current.mode].desc, left_x_offset, top_y_offset)
	local function ModeOnChangedFN(selected, old)
		self:UpdateSetting("mode", selected)
		mode_description:SetMultilineTruncatedString(STRINGS.REFORGED.MODES[selected].desc or STRINGS.REFORGED.unknown, desc_lines, desc_width, desc_max_char, nil, true)
		self:UpdatePreset()
	end
	self.spinners.mode = general_root:AddChild(MakeSpinner(STRINGS.UI.GAME_SETTINGS_PANEL.MODE, self:GetModes(), ModeOnChangedFN, self.settings.current.mode))
	self.spinners.mode:SetPosition(left_x_offset, top_y_offset)

	--------------
	-- Gametype --
	--------------
	local gametype_description = CreateDescription(STRINGS.REFORGED.GAMETYPES[self.settings.current.gametype].desc, right_x_offset, bottom_y_offset)
	local function GametypeOnChangedFN(selected, old)
		self:UpdateSetting("gametype", selected)
		gametype_description:SetMultilineTruncatedString(STRINGS.REFORGED.GAMETYPES[selected].desc or STRINGS.REFORGED.unknown, desc_lines, desc_width, desc_max_char, nil, true)
		self:UpdatePreset()
	end
	self.spinners.gametype = general_root:AddChild(MakeSpinner(STRINGS.UI.GAME_SETTINGS_PANEL.GAMETYPE, self:GetGametypes(), GametypeOnChangedFN, self.settings.current.gametype))
	self.spinners.gametype:SetPosition(right_x_offset, bottom_y_offset)

	-------------
	-- Waveset --
	-------------
	local waveset_description = CreateDescription(STRINGS.REFORGED.WAVESETS[self.settings.current.waveset].desc, right_x_offset, top_y_offset)
	local function WavesetOnChangedFN(selected, old)
		self:UpdateSetting("waveset", selected)
		waveset_description:SetMultilineTruncatedString(STRINGS.REFORGED.WAVESETS[selected] and STRINGS.REFORGED.WAVESETS[selected].desc or STRINGS.REFORGED.unknown, desc_lines, desc_width, desc_max_char, nil, true)
		self:UpdatePreset()
	end
	self.spinners.waveset = general_root:AddChild(MakeSpinner(STRINGS.UI.GAME_SETTINGS_PANEL.WAVESET, self:GetWavesets(), WavesetOnChangedFN, self.settings.current.waveset))
	self.spinners.waveset:SetPosition(right_x_offset, top_y_offset)

	---------
    -- Map --
    ---------
    local minimap = general_root:AddChild(Image())
    minimap:SetPosition(0,-12)
	local function MapOnChangedFN(selected, old)
		self:UpdateSetting("map", selected)
		local map_data = REFORGED_DATA.maps[selected]
		local minimap_data = map_data and map_data.minimap
		if minimap_data then
			minimap:SetTexture(minimap_data.atlas, minimap_data.tex)
		end
		self:UpdatePreset()
		local spinner = self.spinners.waveset.spinner
		local wavesets = self:GetWavesets()
		spinner:SetOptions(wavesets)
		local waveset = self.settings.selected.waveset or self.settings.current.waveset
		-- Ensure the current selected setting is displayed
		if spinner:GetSelectedData() ~= waveset then
			spinner:SetSelected(waveset)
			-- If waveset is not in the current list then select the first index
			if spinner:GetSelectedData() ~= waveset then
				spinner:SetSelected(wavesets[1].data)
			end
		end
	end
    self.spinners.map = general_root:AddChild(MakeSpinner(STRINGS.UI.GAME_SETTINGS_PANEL.MAP, self:GetMaps(), MapOnChangedFN, self.settings.current.map))
    self.spinners.map:SetPosition(0 - 40, -bg_height/2 + spinner_height + border_buffer + 25)

    ----------------
    -- Difficulty --
    ----------------
    local difficulty_description = CreateDescription(STRINGS.REFORGED.DIFFICULTIES[self.settings.current.difficulty].desc, left_x_offset, bottom_y_offset)
    local function DifficultyOnChangedFN(selected, old)
		self:UpdateSetting("difficulty", selected)
		difficulty_description:SetMultilineTruncatedString(STRINGS.REFORGED.DIFFICULTIES[selected].desc or STRINGS.REFORGED.unknown, desc_lines, desc_width, desc_max_char, nil, true)
		self:UpdatePreset() -- TODO should this be uncommented?
	end
    self.spinners.difficulty = general_root:AddChild(MakeSpinner(STRINGS.UI.GAME_SETTINGS_PANEL.DIFFICULTY, self:GetDifficulties(), DifficultyOnChangedFN, self.settings.current.difficulty))
    self.spinners.difficulty:SetPosition(left_x_offset, bottom_y_offset)

	return general_root
end

-- TODO this is getting called multiple times when changing one setting, need to find out why and fix it.
-- Checks if the new setting is the current setting, if not updates new settings.
function GameSettingsPanel:UpdateSetting(setting, value)
	if value == self.settings.current[setting] then
		self.settings.selected[setting] = nil
		if self.spinners and self.spinners[setting] then -- TODO better way?
			self.spinners[setting].spinner:SetTextColour(UICOLOURS.BROWN_DARK)
		end
	else
		self.settings.selected[setting] = value
		if self.spinners then -- TODO better way?
			self.spinners[setting].spinner:SetTextColour(UICOLOURS.WHITE)
		end
	end
end

function GameSettingsPanel:HasNoSelectedSettings()
	for setting,value in pairs(self.settings.selected) do
		if setting == "mutators" then
			for mutator,val in pairs(value) do
				return false
			end
		else
			return false
		end
	end
	return true
end

-- Changes the selected preset to custom if changing any setting outside of preset.
function GameSettingsPanel:UpdatePreset()
	if not self.loading_preset then
		-- If settings have not been changed then just display the current preset
		if self:HasNoSelectedSettings() then
			self.spinners.preset.spinner:SetSelected(self.settings.current.preset)
		else
			local selected_preset = "custom"
			-- Check to see if selected settings match a preset
			for preset,data in pairs(REFORGED_DATA.presets) do
				if preset ~= "custom" then
					local invalid = false
					for setting,value in pairs(self.settings.current) do
						if setting == "mutators" then
							for mutator,val in pairs(value) do
								if (self.settings.selected[setting][mutator] or val) ~= (data[setting][mutator] or type(val) == "number" and 1) then
									invalid = true
									break
								end
							end
						elseif setting ~= "preset" and (self.settings.selected[setting] or value) ~= data[setting] then
							invalid = true
						end
						-- Immediately break if preset is invalid
						if invalid then break end
					end
					-- Stop looking for a valid preset once one is found
					if not invalid then
						selected_preset = preset
						break
					end
				end
			end
			self.spinners.preset.spinner:SetSelected(selected_preset)
		end
	end
end

--
function GameSettingsPanel:ChangeSettings(settings)
	--print("Changing Settings...")
	--Debug:PrintTable(self.settings.current, 3)
	--Debug:PrintTable(settings, 3)
	for setting,data in pairs(self.settings.current) do
		if setting == "mutators" then
		    for mutator,val in pairs(data) do
		    	local selected_val = settings.mutators[mutator]
		    	selected_val = selected_val == nil and val or selected_val ~= nil and selected_val -- TODO better way?
		    	--if self.mutator_spinners[mutator] then
		        	--self.mutator_spinners[mutator].spinner:SetSelected(selected_val)
		        --else
		        if self.mutator_checkboxes[mutator] then
		        	self.mutator_checkboxes[mutator].button.onclick(selected_val)
		        end
			end
		elseif self.spinners[setting] then
			local selected_val = settings[setting]
			selected_val = selected_val == nil and data or selected_val
			self.spinners[setting].spinner:SetSelected(selected_val)
		end
	end
	self.slider_mutators_list:RefreshView()
end

-- Resets all values to the current setting of the server.
function GameSettingsPanel:ResetSettings()
	self:ChangeSettings(REFORGED_SETTINGS.gameplay)
end

function GameSettingsPanel:GetOptions(category)
	local options = {}
	local strings = STRINGS.REFORGED[string.upper(category)]
	for name,data in pairs(REFORGED_DATA[category] or {}) do
		local map_data = REFORGED_DATA.maps[self.settings.selected.map or self.settings.current.map]
		if not (category == "wavesets" and (not REFORGED_SETTINGS.other.enable_sandbox and name == "sandbox" or map_data and map_data.spawners < data.spawners)) then
			table.insert(options, {text = strings and (strings[name] and strings[name].name or strings[name]) or STRINGS.REFORGED.unknown, data = name, order_priority = data.order_priority or 999}) -- TODO text needs to be implemented using our strings. default string will be the name
		end
	end
	table.sort(options, function(a, b)
		return a.order_priority < b.order_priority
	end)
	return options
end

function GameSettingsPanel:GetPresets()
	return self:GetOptions("presets")
end

function GameSettingsPanel:GetModes()
	return self:GetOptions("modes")
end

function GameSettingsPanel:GetGametypes()
	return self:GetOptions("gametypes")
end

function GameSettingsPanel:GetWavesets()
	return self:GetOptions("wavesets")
end

function GameSettingsPanel:GetMaps()
	return self:GetOptions("maps")
end

function GameSettingsPanel:GetDifficulties()
	return self:GetOptions("difficulties")
end

--[[------------------------------
			FILTERS
---------------------------------]]
function GameSettingsPanel:BuildMutatorDisplay()
	local mutator_root = Widget("mutator_root")
	--mutator_root:SetScale(1.5)

	local bg = mutator_root:AddChild(Image("images/lavaarena_unlocks.xml", "box1.tex"))
    bg:SetScale(1, 1.3)
    local bg_width, bg_height = bg:GetSize()
	bg:SetPosition(0, 0)

	local top = 50
	local left = 0 -- -width/2 + 5

	local spacing = 5
	local divider_spacing = 10
	local filters_per_row = 3
	local starting_x_pos = -300
	local starting_y_pos = 50
	local current_x_pos = 0
	local max_filter_categories = 4 -- TODO make constant? or check self.filters?

	local y_buffer = 00-- -110
	local border_buffer = 10
	local current_y_offset = bg_height/2
	local current_x_offset = 350
	--[[
	local title = mutator_root:AddChild( Text(HEADERFONT, 36, "Mutators:", UICOLOURS.BROWN_DARK) )
	title:SetPosition(0,0)--current_y_offset)--]]

	--[[
	local divider_horiz = mutator_root:AddChild(Image("images/ui.xml", "line_horizontal_4.tex"))
    --divider_horiz:SetScale(.75, .75)
	divider_horiz:SetSize((filters_per_row * self.icon_sizes.filters[1] + spacing + divider_spacing)* max_filter_categories, 2)
	divider_horiz:SetPosition(0, 60)
	divider_horiz:SetTint(107/255, 84/255, 58/255, 0.5)
	--]]

	local function BuildNumConfig(startNum, endNum, step, percent, suffix, specific_values)
		local numTable = {}
		local iterator = 1
		local suffix = percent and "%" or suffix or ""
		for i = startNum, endNum, step or 1 do
			numTable[iterator] = {text = i..suffix, data = percent and i / 100 or i}
			iterator = iterator + 1
		end
		if specific_values then
			TableConcat(numTable, specific_values)
			table.sort(numTable, function(a,b)
				return a.data < b.data
			end)
		end
		return numTable
	end
	-- Settings
	local slider_preset_options = {
		stat   = BuildNumConfig(50, 300, 5, true),
		mult   = BuildNumConfig(1, 10, 1, nil, "X"),
		slider = BuildNumConfig(1, 10, 1),
	}
	local spinner_options = {
		width_label = 200,
		width_spinner = 200,
	}

	local mutator_stats_count = 5 -- TODO get rid of this...not sure why stuff was dependent on this...
	-- Spinner Mutator Settings
	self.mutator_spinners = {}
	local spinner_height = 50
	local spinner_x = -350
	local spinner_y = (mutator_stats_count - 1) * spinner_height / 2
	-- Checkbox Mutator Settings
	self.mutator_checkboxes = {}
	local max_checkboxes_per_column = mutator_stats_count
	local checkbox_current_x = 0
	local checkbox_current_y = spinner_y
	local checkbox_columns = 2
	local checkbox_count = 0
	local mutators = {}
	-- Organize mutators in order
	for mutator,value in pairs(self.settings.current.mutators) do
		table.insert(mutators, {mutator = mutator, value = value, order_priority = REFORGED_DATA.mutators[mutator].order_priority or 999})
	end
	table.sort(mutators, function(a, b)
		return a and b and a.order_priority < b.order_priority
	end)
	-- Create Display for Mutators
	for _,data in pairs(mutators) do
		local mutator = data.mutator
		local value = data.value
		local mutator_data = REFORGED_DATA.mutators[mutator]
		-- Stat Mutators (use Spinners)
		if mutator_data and slider_preset_options[mutator_data.type] then
			table.insert(self.mutator_spinners, mutator)
		-- Other Mutators (use Checkboxes)
		else
			checkbox_count = checkbox_count + 1
			local checkbox = mutator_root:AddChild(TEMPLATES.OptionsLabelCheckbox(function() return true end, (STRINGS.REFORGED.MUTATORS[mutator] and STRINGS.REFORGED.MUTATORS[mutator].name or STRINGS.REFORGED.unknown) .. ":", self.settings.current.mutators[mutator], 250, 50, 50, 75, 5, HEADERFONT, 30))
			checkbox.button:SetOnClick(function(checked)
				local selected_mutators = self.settings.selected.mutators
				if checked ~= nil then -- TODO more efficient if statement?
					if self.settings.current.mutators[mutator] == checked then
						selected_mutators[mutator] = nil
						checkbox.label:SetColour(UICOLOURS.BROWN_DARK)
					else
						selected_mutators[mutator] = checked
						checkbox.label:SetColour(UICOLOURS.WHITE)
					end
				elseif selected_mutators[mutator] ~= nil then
					selected_mutators[mutator] = nil
					checked = self.settings.current.mutators[mutator]
					checkbox.label:SetColour(UICOLOURS.BROWN_DARK)
				else
					selected_mutators[mutator] = not self.settings.current.mutators[mutator]
					checked = selected_mutators[mutator]
					checkbox.label:SetColour(UICOLOURS.WHITE)
				end
				if checked then
					checkbox.button:SetTextures("images/global_redux.xml", "checkbox_normal_check.tex", "checkbox_focus_check.tex", "checkbox_normal.tex", nil, nil, {1,1}, {0,0})
					checkbox.button.image:SetTexture("images/global_redux.xml", "checkbox_normal_check.tex")
				else
	            	checkbox.button:SetTextures("images/global_redux.xml", "checkbox_normal.tex", "checkbox_focus.tex", "checkbox_normal_check.tex", nil, nil, {1,1}, {0,0})
	            	checkbox.button.image:SetTexture("images/global_redux.xml", "checkbox_normal.tex")
	            end
	            self:UpdatePreset()
			end)
			checkbox.label:SetColour(UICOLOURS.BROWN_DARK)
			checkbox:SetPosition(checkbox_current_x, checkbox_current_y)
			if checkbox_count % checkbox_columns == 0 then
				checkbox_current_x = checkbox_current_x - 350
				checkbox_current_y = checkbox_current_y - 50
			else
				checkbox_current_x = checkbox_current_x + 350
			end
			--[[
			checkbox_current_y = checkbox_current_y - 50
			if checkbox_count%max_checkboxes_per_column == 0 then
				checkbox_current_x = checkbox_current_x + 350
				checkbox_current_y = (mutator_stats_count - 1) * spinner_height / 2
			end
			--]]
			self.mutator_checkboxes[mutator] = checkbox
		end
	end

    local spacing = 5
	local font = HEADERFONT
	local font_size = 30
	local width_label = 200
	local width_spinner = 200
	local height = 50
	local total_width = width_label + width_spinner + spacing
    local function ScrollWidgetsCtor(context, index)
        local row = self.mutator_list_rows:AddChild(Widget("forge_runs_list_row"))
		-- TODO are these supposed to be set to index?
        -- The index within the filtered list
        row.display_index = -1
        -- The index within self.servers
        row.unfiltered_index = -1

		-- Mutator Name
		row.LABEL = row:AddChild( Text(font, font_size, "") )
		row.LABEL:SetRegionSize( width_label, height )
		row.LABEL:SetHAlign( ANCHOR_RIGHT )
		row.LABEL:SetColour(UICOLOURS.BROWN_DARK)
		--[[row.LABEL._align = {
            maxwidth = 50,
            maxchars = 5,
            x = -row_width/2,--self.column_offsets.INDEX,
            y = y_offset_top,
        }--]]
		row.LABEL:SetPosition( (-total_width/2)+(width_label/2), 0 )

		local lean = true
		-- Mutator Values
		row.SPINNER = row:AddChild(Spinner({}, width_spinner, height, {font = font, size = font_size}, nil, "images/quagmire_recipebook.xml", nil, true))
		row.SPINNER:SetTextColour(UICOLOURS.BROWN_DARK)
		row.SPINNER:SetOnChangedFn(function(selected, old)
			local mutator = row.mutator
			if mutator then
				local selected_mutators = self.settings.selected.mutators
				if selected ~= selected_mutators[mutator] then
					if selected == self.settings.current.mutators[mutator] then
						selected_mutators[mutator] = nil
						row.LABEL:SetColour(UICOLOURS.BROWN_DARK)
					else
						selected_mutators[mutator] = selected
						row.LABEL:SetColour(UICOLOURS.WHITE)
					end
					self:UpdatePreset()
				end
			end
		end)
		row.SPINNER:SetPosition((total_width/2)-(width_spinner/2), 0)

        return row
    end

    local function UpdateMutatorListWidget(context, widget, mutator, index)
		if not widget then return end

		-- If there are no runs hide everything
        if not mutator then
            widget.display_index = -1
            widget.LABEL:Hide()
            widget.SPINNER:Hide()
            widget:Disable()
            widget.mutator = nil
        -- Add run to the list
		else
            widget:Enable()
            widget.display_index = index

			local mutator_data = REFORGED_DATA.mutators[mutator]

			-- Mutator Name
            local mutator_name = STRINGS.REFORGED.MUTATORS[mutator] and STRINGS.REFORGED.MUTATORS[mutator].name or STRINGS.REFORGED.unknown
            --widget.LABEL:SetTruncatedString(mutator_name, widget.LABEL._align.maxwidth, widget.LABEL._align.maxchars, true)
            widget.LABEL:SetString(mutator_name)
            --local w, h = widget.LABEL:GetRegionSize()
            --local max_width_label = 32
            --widget.LABEL:SetPosition(widget.LABEL._align.x - w * .5 + max_width_label, widget.LABEL._align.y, 0)
			widget.LABEL:Show()

			if widget.mutator ~= mutator then
				widget.mutator = mutator
				-- Mutator Value
				local mutator_num_config = mutator_data.num_config
				local mutator_preset_options = mutator_num_config and BuildNumConfig(mutator_num_config.min, mutator_num_config.max, mutator_num_config.step, mutator_num_config.percent, mutator_num_config.suffix, mutator_num_config.specific_values) or slider_preset_options.stat
				widget.SPINNER:SetOptions(mutator_preset_options)
			end

			-- Update Value
			local selected_mutators = self.settings.selected.mutators
			local current_value = selected_mutators[mutator] or self.settings.current.mutators[mutator]
			if current_value ~= widget.SPINNER:GetSelectedData() then
				if current_value == self.settings.current.mutators[mutator] then
					selected_mutators[mutator] = nil
					widget.LABEL:SetColour(UICOLOURS.BROWN_DARK)
				else
					selected_mutators[mutator] = current_value
					widget.LABEL:SetColour(UICOLOURS.WHITE)
				end
				widget.SPINNER:SetSelected(current_value, true)
			end
			widget.SPINNER:Show()
        end
    end

	self.mutator_list_rows = self:AddChild(Widget("mutator_list_rows"))
    self.slider_mutators_list = mutator_root:AddChild(TEMPLATES.ScrollingGrid(self.mutator_spinners or {},{
        context = {},
        widget_width  = total_width,
        widget_height = height,
        num_visible_rows = 5,
        num_columns      = 1,
        item_ctor_fn = ScrollWidgetsCtor,
        apply_fn     = UpdateMutatorListWidget,
        scrollbar_offset = 20,
        scrollbar_height_offset = -60,
    }))

	self.mutator_list_rows:MoveToFront()

	self.slider_mutators_list.up_button:SetTextures("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_arrow_hover.tex")
    self.slider_mutators_list.up_button:SetScale(0.5)

	self.slider_mutators_list.down_button:SetTextures("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_arrow_hover.tex")
    self.slider_mutators_list.down_button:SetScale(-0.5)

	self.slider_mutators_list.scroll_bar_line:SetTexture("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_bar.tex")
	self.slider_mutators_list.scroll_bar_line:SetScale(.3)

	self.slider_mutators_list.position_marker:SetTextures("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_handle.tex")
	self.slider_mutators_list.position_marker.image:SetTexture("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_handle.tex")
    self.slider_mutators_list.position_marker:SetScale(.6)

    self.slider_mutators_list:SetPosition(spinner_x,0)

	return mutator_root
end

return GameSettingsPanel
