local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"
local TextButton = require "widgets/textbutton"
local ImageButton = require "widgets/imagebutton"
--local TextWithIcon = require "widgets/textwithiconwidget"
local easing = require "easing"
local Widget = require "widgets/widget"
local TEMPLATES = require "widgets/redux/templates"
local Spinner = require "widgets/spinner"
local PlayerAvatarPortrait = require "widgets/redux/playeravatarportrait"
local Puppet = require "widgets/skinspuppet"
local GREATER_THAN = 1
local LESS_THAN = 2
local ALIGN_L = 1
local ALIGN_C = 0
local ALIGN_R = -1
require("stringutil")

local number_values = {round = true, time = true, total_deaths = true}
local string_exclusions = {["false"] = true, ["nil"] = true}
local month_str_to_num = {
    Jan = 1,
    Feb = 2,
    Mar = 3,
    Apr = 4,
    May = 5,
    June = 6,
    July = 7,
    Aug = 8,
    Sept = 9,
    Oct = 10,
    Nov = 11,
    Dec = 12,
}
-- Parses the data from the given file and adds the valid runs to the list
-- Date Format:
-- full_date == false:
--      - name: mm-dd-yy
--      - file: mm/dd/yy hh:mm:ss ex. 12/22/19 18:46:25
-- full_date == false:
--      - name: mm-dd-yyyy
--      - file: Mon Dec 23 14:39:21 2019
local function GetRunsFromFile(self, filename, full_date)
    local run_count = {total = 0, valid = 0, invalid = 0, duplicate = 0}
    TheSim:GetPersistentString(filename, function(load_success, data)
        if load_success and data ~= nil then
            local forge_data = ParseString(data, "\n")
            local current_run = {}
            current_run.mutators = {}
            current_run.players_stats = {}
            local duplicate_run = false
            local invalid_run = false
            local random_characters = true
            local unique_characters = true
            local character_index = 3
            local death_index = 1
            local total_deaths = 0
            local current_characters = {}
            local fields = {}
            local mutator_fields = {}
            local valid_run = true
            for i,j in pairs(forge_data) do
                local line_data = ParseString(j, ",")
                --[[print("index: " .. tostring(i))
                for l,m in pairs(line_data) do
                    print(tostring(l) .. ": " .. tostring(m))
                end--]]

                if line_data[1] == "endofmatch" then
                    if valid_run then
                        if current_run.total_deaths == nil then
                            current_run.total_deaths = total_deaths
                        end
                        current_run.random_team = random_characters
                        current_run.unique_team = unique_characters
                        -- Add valid runs
                        if not invalid_run then
                            table.insert(self.loaded_runs, current_run)
                            run_count.valid = run_count.valid + 1
                        else
                            run_count.invalid = run_count.invalid + (invalid_run and 1 or 0)
                        end
                        run_count.total = run_count.total + 1

                        -- reset
                        current_run = {}
                        current_run.mutators = {}
                        current_run.players_stats = {}
                        invalid_run = false
                        random_characters = true
                        unique_characters = true
                        current_characters = {}
                        total_deaths = 0
                        fields = {}
                    else
                        valid_run = true
                    end
                elseif valid_run then
                    if #fields > 0 then
                        invalid_run = #fields ~= #line_data
                        local player_stats = {}
                        if not invalid_run then
	                        -- Make the index be the stat name
	                        for index,stat in pairs(fields) do
	                            local val = line_data[index]
	                            player_stats[stat] = val == "true" and true or not string_exclusions[val] and val ~= "false" and val or false
	                            if stat == "character" then
	                                unique_characters = unique_characters and not current_characters[val]
	                                current_characters[val] = current_characters[val]
	                            elseif stat == "random_character" then
	                                random_characters = random_characters and val == "true"
	                            elseif stat == "deaths" and current_run.total_deaths == nil then
	                                total_deaths = total_deaths + tonumber(val)
	                            end
	                        end
	                    end
                        table.insert(current_run.players_stats, player_stats)
                    elseif #mutator_fields > 0 then
                        current_run.mutators = {}
                        -- Make the index be the mutator name
                        for index,mutator in pairs(mutator_fields) do
                            current_run.mutators[mutator] = line_data[index]
                        end
                        mutator_fields = {}
                    elseif line_data[1] == "fields" then
                        fields = line_data
                    elseif line_data[1] == "mutators" then
                        mutator_fields = line_data
                    elseif line_data[1] == "client_date" or line_data[1] == "server_date" then
                        local date = line_data[2]
                        -- file: Mon Dec 23 14:39:21 2019
                        if full_date then
                            local date_data = ParseString(date, " ")
                            date = tostring(month_str_to_num[date_data[2]] or 1) .. "/" .. date_data[3] .. "/" .. string.sub(date_data[5], 3) .. " " .. date_data[4]
                        end
                        current_run["date_time"] = date
                    elseif line_data[1] == "stats_type" then
                        valid_run = line_data[2] == "ReForged"
                    elseif line_data[1] == "mode" and line_data[2] == "forge" then
                        current_run[line_data[1]] = "forge_s02"
                    elseif number_values[line_data[1]] then
                        current_run[line_data[1]] = tonumber(line_data[2])
                    elseif line_data[1] ~= nil then
                        current_run[line_data[1]] = line_data[2] == "true" and true or not string_exclusions[line_data[2]] and line_data[2] or false
                    end
                end
            end
        end
    end)
    return run_count
end

-- Attempts to get all runs from within the given date range.
local function GetFilesFromDateRange(self, filename, start_date, end_date)
    local max_days_per_month = 31
    local months_per_year = 12
    local current_date = start_date

    -- Loop through each date
    local file_count = 0
    local run_count = {total = 0, valid = 0, invalid = 0, duplicate = 0}
    local function UpdateRunCount(new_run_count)
        if new_run_count.total > 0 then
            run_count.total = run_count.total + new_run_count.total
            run_count.valid = run_count.valid + new_run_count.valid
            run_count.invalid = run_count.invalid + new_run_count.invalid
            run_count.duplicate = run_count.duplicate + new_run_count.duplicate
            file_count = file_count + 1
        end
    end
    local complete = false
    while not complete do
        --print(string.format("%02d-%02d-%02d.csv", current_date.month, current_date.day, current_date.year))
        UpdateRunCount(GetRunsFromFile(self, string.format("%s%02d-%02d-%02d.csv", filename, current_date.month, current_date.day, current_date.year)))
        UpdateRunCount(GetRunsFromFile(self, string.format("%s%02d-%02d-%02d.csv", filename, current_date.month, current_date.day, current_date.year + 2000), true))

        -- Check if looped through every date
        if current_date.day == end_date.day and current_date.month == end_date.month and current_date.year == end_date.year then
            complete = true
        -- Update date values
        elseif current_date.day == max_days_per_month then
            current_date.day = 1
            if current_date.month == months_per_year then
                current_date.month = 1
                current_date.year = current_date.year + 1
            else
                current_date.month = current_date.month + 1
            end
        else
            current_date.day = current_date.day + 1
        end
    end
    print("- " .. tostring(file_count) .. " files found.")
    print("- " .. tostring(run_count.total) .. " total runs found.")
    print("-- " .. tostring(run_count.valid) .. " valid runs, " .. tostring(run_count.invalid) .. " invalid runs, " .. tostring(run_count.duplicate) .. " duplicate runs found")
end

local function MakeDetailsLine(details_root, x, y, scale, image_override)
	local value_title_line = details_root:AddChild(Image("images/quagmire_recipebook.xml", image_override or "quagmire_recipe_line.tex"))
	value_title_line:SetScale(scale, scale)
	value_title_line:SetPosition(x, y)
	return value_title_line
end

local function ConvertTotalSecondsToTime(time)
	if time <= 0 then
		return "00:00:00";
	else
		local hours = string.format("%02.f", math.floor(time/3600));
		local mins = string.format("%02.f", math.floor(time/60 - (hours*60)));
		local secs = string.format("%02.f", math.floor(time - hours*3600 - mins *60));
		return hours .. ":" .. mins .. ":" .. secs
	end
end

local stat_exclusions = {fields = true, userid = true, netid = true, name = true, character = true, cardstat = true, player_name = true, is_you = true, random_character = true, current_perk = true, original_perk = true}
local MAX_FILTERS_PER_COL = 5
--[[
Creates a panel in the Lavaarena book that displays the servers leaderboard.

TODO
add 30 second buffer for date_time dupe check
december runs are not shown for some reason
highlight selected run in list?

server options
	number of runs displayed?
		so only top 10 per section are displayed?
		this would not work when wanting to see top runs for specific types since the top 10 fastest for classic waveset would be different that top 10 for swineclops
			this means have to send all of the runs? hmmmm
	display leaderboard

dedicated server was not saving runs...
only display server leaderboard tab if there are runs to display
dont display sandbox runs
	maybe don't save sandbox runs at all?
display victories only?
	makes the list shorter so you can add a mutator section

player display
	copy how filters do it and only display 6 players at a time

Filters
	mutators (11)
		mob damage, mob health, mob defense, mob speed, battlestandard efficiency (if not default value)
		endless
			need to make sure that the other mutators do NOT need to be on and ALL endless runs are displayed
			BUT if endless is not on then mutators filter out normally
	maps ???
display game settings on tab ingame?
display items on waiting screen
--]]
local ServerLeaderboardPanel = Class(Widget, function(self, options)
    ------------------ NO TOUCHY ------------------
	Widget._ctor(self, "ServerLeaderboardPanel")

	self.only_show_nonzero_stats = REFORGED_SETTINGS.display.only_show_nonzero_stats
	self.display_colored_stats = REFORGED_SETTINGS.display.display_colored_stats
	self.current_eventid = "LAVAARENA"

	self.current_index = 1
	self.average_stats_displayed = true

	self.players = {}
	self.player_display = {}
	self.stat_fields = {}
	self.display_stats = {false, false, false, false}

	local row_pos_x = 0
	self.max_column_widths ={
		INDEX = 32,
		OUTCOME = 50,
		CHARACTERS = 150,
		TIME = 40,
		MODE = 70,
		DATE = 50,
	}
	self.icon_size ={15,15}
	local old_coins_offset = 340
	local spacing = 15
	local INDEX_X = row_pos_x
	local OUTCOME_X = INDEX_X + self.max_column_widths.INDEX + spacing
	local CHARACTERS_X = OUTCOME_X + self.max_column_widths.OUTCOME
	local TIME_X = CHARACTERS_X + self.max_column_widths.CHARACTERS + spacing
	local MODE_X = TIME_X + self.max_column_widths.TIME
	local DATE_X = MODE_X + self.max_column_widths.MODE + spacing
	self.total_row_width = DATE_X + self.max_column_widths.DATE - spacing-- Buffer? this may need to be adjusted, not sure
	--print("[GHP] Total width: " .. tostring(self.total_row_width))
	self.column_offsets ={
		INDEX = INDEX_X,
		OUTCOME = OUTCOME_X,
		CHARACTERS = CHARACTERS_X,
		TIME = TIME_X,
		MODE = MODE_X,
		DATE = DATE_X,
	}
	--[[
	for i, offset in pairs(self.column_offsets) do
		print("[Offsets] " .. tostring(i) .. ": " .. tostring(offset))
	end--]]

	self.icon_sizes = {
		list = {25, 25},
		player = {50,50},
		stats = {40,40},
		filters = {25,25},
	}
	self.filter_keys = {
		general      = 1,
		modes        = 2,
        difficulties = 3,
		characters   = 4,
		mutators     = 5,
		players      = 6,
		gametypes    = 7,
		wavesets     = 8,
        maps         = 9,
        presets      = 10,
	}
	self.filters = {
		[1] = {
			victory = {
				is_on = false,
				str = STRINGS.UI.FORGEHISTORYPANEL.FILTERS.VICTORIES,
				icon = "lab_win.tex",
			},
			deathless = {
				is_on = false,
				str = STRINGS.UI.FORGEHISTORYPANEL.FILTERS.DEATHLESS,
				icon = "lab_no_deaths_team.tex",
			},
			commands_used = {
				is_on = false,
				str = STRINGS.UI.FORGEHISTORYPANEL.FILTERS.COMMANDS,
				force_source = "images/inventoryimages1.xml",
				icon = "arrowsign_post_factory.tex",
			},
			scripts_used = {
				is_on = false,
				str = STRINGS.UI.FORGEHISTORYPANEL.FILTERS.SCRIPTS,
				force_source = "images/inventoryimages1.xml",
				icon = "blueprint_rare.tex",
			},
			is_you = { -- TODO
				is_on = false,
				str = STRINGS.UI.FORGEHISTORYPANEL.FILTERS.IS_YOU,
				icon = "lab_no_deaths_player.tex",
			},
			unique_characters = {
				is_on = false,
				str = STRINGS.UI.FORGEHISTORYPANEL.FILTERS.UNIQUE_CHARACTERS,
				icon = "lab_unique_characters.tex",
			},
			random_characters = {
				is_on = false,
				str = STRINGS.UI.FORGEHISTORYPANEL.FILTERS.RANDOM_CHARACTERS,
				force_source = "images/avatars.xml",
				icon = "avatar_random.tex", -- TODO
			},
			afk_runs = {
				is_on = true,
				str = STRINGS.UI.FORGEHISTORYPANEL.FILTERS.AFK_RUNS,
				force_source = "images/filter_icons.xml",
				icon = "afk.tex",
			},
			options = {
				name = "general",
				source = "images/lavaarena_quests.xml",
				pos = {x = 0, y = 0},
				order = {"victory", --[["leaderboard", "all_stats", --]]"deathless", "random_characters", "unique_characters", "is_you", "commands_used", "scripts_used", "afk_runs"},
				filters_per_row = 2,
			},
		},
		[2] = {
			options = {
				name = "modes",
				pos = {x = 0, y = 0},
				order = {},
			},
		},
        [3] = {
            options = {
                name = "difficulties",
                pos = {x = 0, y = 0},
                order = {},
            },
        },
		[4] = { -- TODO add button that toggles all of them on or off?
			wilson       = {is_on = true, str = STRINGS.NAMES.WILSON,           icon = "wilson.tex"},
			willow       = {is_on = true, str = STRINGS.NAMES.WILLOW,           icon = "willow.tex"},
			wolfgang     = {is_on = true, str = STRINGS.NAMES.WOLFGANG,         icon = "wolfgang.tex"},
			wendy        = {is_on = true, str = STRINGS.NAMES.WENDY,            icon = "wendy.tex"},
			wx78         = {is_on = true, str = STRINGS.NAMES.WX78,             icon = "wx78.tex"},
			wickerbottom = {is_on = true, str = STRINGS.NAMES.WICKERBOTTOM,     icon = "wickerbottom.tex"},
			woodie       = {is_on = true, str = STRINGS.NAMES.WOODIE,           icon = "woodie.tex"},
			wes          = {is_on = true, str = STRINGS.NAMES.WES,              icon = "wes.tex"},
			waxwell      = {is_on = true, str = STRINGS.NAMES.WAXWELL,          icon = "waxwell.tex"},
			wathgrithr   = {is_on = true, str = STRINGS.NAMES.WATHGRITHR,       icon = "wathgrithr.tex"},
			webber       = {is_on = true, str = STRINGS.NAMES.WEBBER,           icon = "webber.tex"},
			winona       = {is_on = true, str = STRINGS.NAMES.WINONA,           icon = "winona.tex"},
			wortox       = {is_on = true, str = STRINGS.NAMES.WORTOX,           icon = "wortox.tex"},
			warly        = {is_on = true, str = STRINGS.NAMES.WARLY,            icon = "warly.tex"},
			wormwood     = {is_on = true, str = STRINGS.NAMES.WORMWOOD,         icon = "wormwood.tex"},
			wurt         = {is_on = true, str = STRINGS.NAMES.WURT,             icon = "wurt.tex"},
			walter       = {is_on = true, str = STRINGS.NAMES.WALTER,           icon = "walter.tex"},
			wanda        = {is_on = true, str = STRINGS.NAMES.WANDA,            icon = "wanda.tex"},
			unknown      = {is_on = true, str = STRINGS.NAMES.MODDED_CHARACTER, icon = "unknown.tex"},
			options = {
				name = "characters",
				source = "images/avatars_resize.xml",
				pos = {x = 0, y = 0},
				order = {"wilson", "willow", "wolfgang", "wendy", "wx78", "wickerbottom", "woodie", "wes", "waxwell", "wathgrithr", "webber", "winona", "wortox", "warly", "wormwood", "wurt", "walter", "wanda", "unknown"},
				filters_per_row = 4,
			},
		},
		[5] = {
			options = {
				name = "mutators",
				pos = {x = 0, y = 0},
				order = {},
			},
		},
		[6] = {
			options = {
				name = "players",
				pos = {x = 0, y = 0},
				order = {},
			},
		},
		[7] = {
			options = {
				name = "gametypes",
				pos = {x = 0, y = 0},
				order = {},
			},
		},
		[8] = {
			options = {
				name = "wavesets",
				pos = {x = 0, y = 0},
				order = {},
			},
		},
        [9] = {
            options = {
                name = "maps",
                pos = {x = 0, y = 0},
                order = {},
            },
        },
        [10] = {
            options = {
                name = "presets",
                pos = {x = 0, y = 0},
                order = {},
            },
        },
	}

    local function FilterSetup(filter_name, filters, options)
        local strings = options.strings
        for filter,data in pairs(options.filters or REFORGED_DATA[filter_name]) do
            filters[filter] = {is_on = options.is_on and (options.is_on[filter] or options.is_on.all) or false, str = strings and (type(strings) == "function" and strings(filter) or strings[filter] and (type(strings[filter]) == "table" and strings[filter].name or strings[filter])) or STRINGS.REFORGED.unknown, force_source = type(data) == "table" and data.icon and data.icon.atlas or options.default_source, icon = type(data) == "table" and data.icon and data.icon.tex or options.default_icon}
            table.insert(filters.options.order, filter)
        end
        filters.options.filters_per_row = math.ceil(#filters.options.order / MAX_FILTERS_PER_COL)
    end

	-- Add player count filters to the general category
    local player_filters = {}
    local max_players = 6
    for i=1,max_players + 1 do
        table.insert(player_filters, true)
    end
    local function GetPlayerFilterString(filter)
        return tostring(filter) .. (filter == max_players + 1 and "+" or "")
    end
    FilterSetup(nil, self.filters[self.filter_keys.players], {filters = player_filters, is_on = {all = true}, strings = GetPlayerFilterString, default_source = "text"})

	-- Add mode filters
    FilterSetup("modes", self.filters[self.filter_keys.modes], {is_on = {all = true}, strings = STRINGS.REFORGED.MODES})

    -- Add difficulty filters
    FilterSetup("difficulties", self.filters[self.filter_keys.difficulties], {is_on = {all = true}, strings = STRINGS.REFORGED.DIFFICULTIES})

	-- Add waveset filters
    FilterSetup("wavesets", self.filters[self.filter_keys.wavesets], {is_on = {all = true}, strings = STRINGS.REFORGED.WAVESETS, default_source = "images/filter_icons.xml", default_icon = "orig_forge.tex"})

	-- Add gametype filters
    FilterSetup("gametypes", self.filters[self.filter_keys.gametypes], {is_on = {all = true}, strings = STRINGS.REFORGED.GAMETYPES, default_source = "images/filter_icons.xml", default_icon = "orig_forge.tex"})

	-- Add mutator filters
    FilterSetup("mutators", self.filters[self.filter_keys.mutators], {strings = STRINGS.REFORGED.MUTATORS})

    -- Add map filters
    FilterSetup("maps", self.filters[self.filter_keys.maps], {is_on = {all = true}, strings = STRINGS.REFORGED.MAPS})

    -- Add preset filters
    FilterSetup("presets", self.filters[self.filter_keys.presets], {is_on = {all = true}, strings = STRINGS.REFORGED.PRESETS, default_source = "images/filter_icons.xml", default_icon = "orig_forge.tex"})

	-- Retrieve Forge History
	local current_date = os.date("*t")
    -- Load ReForged Runs
    Debug:Print("Loading ReForged Runs...", "log")
    self.loaded_runs = {}
    GetFilesFromDateRange(self, "event_match_stats\\reforged_stats_", {day = 1, month = 11, year = 19}, {day = current_date.day, month = current_date.month, year = tonumber(string.sub(current_date.year,-2))}) -- Check from start date to current date
	self:ScanForgeRuns()

	local panel_root = self
	-----------

	self.top_root = self:AddChild(Widget("top_root")) -- Rename? or call method to build each group?
	self.top_root:SetPosition(0, 100)
	self.top_root:SetScale(.66)

	self.bottom_root = self:AddChild(Widget("bottom_root")) -- Rename? or call method to build each group?
	self.bottom_root:SetScale(.66)

	-- Average Stats Button
	self.average_stats_button = self:AddChild( ImageButton("images/inventoryimages.xml", "book_elemental.tex") )
	self.average_stats_button:ScaleImage(self.icon_sizes.stats[1], self.icon_sizes.stats[2])
	self.average_stats_button:SetPosition(0, 210)
	self.average_stats_button:SetHoverText(STRINGS.UI.FORGEHISTORYPANEL.AVERAGE_STATS.BUTTON)
	self.average_stats_button.image:SetTint(unpack(self.average_stats_displayed and {1,1,1,1} or {.5,.5,.5,1}))
	self.average_stats_button:SetOnClick(function()
		self.average_stats_displayed = not self.average_stats_displayed -- Toggle it
		-- Don't allow current run stats to be displayed if there are none
		--self.average_stats_displayed = not (#self.current_forge_runs > 0 and not self.average_stats_displayed)
		--self.average_stats_button.image:SetTint(unpack(self.average_stats_displayed and {1,1,1,1} or {.5,.5,.5,1}))
		self:RefreshForgeRunDisplay()
	end)
	-- Make BuildForgeRunDisplay
	-- need to shift up a bit
	-- TODO put with top_root? that way you can move them as a group at once?
	self.forge_run_display = self:AddChild( self:BuildForgeRunDisplay() )
	self.forge_run_display:SetScale(.66)
	self.average_stats_button:MoveToFront()

	-- Place between these 2 widgets
	local line_break = self:AddChild(Image("images/lavaarena_unlocks.xml", "divider.tex"))
	local line_break_width, line_break_height = line_break:GetSize()
	line_break:SetPosition(0, -line_break_height/2)
	line_break:SetScale(.68)

	-- Make BuildForgeRunsList method
	-- TODO put with bottom widget? that way you can move them as a group at once?
	self.forge_runs_list_menu = self.bottom_root:AddChild( self:BuildForgeRunListMenu() )
	self.forge_runs_list_menu:SetPosition(0, -line_break_height/2 - 175)

	self.parent_default_focus = self
end)

-- Update the current list based on the current filter settings. Also, updates overall stat values based on the current list.
function ServerLeaderboardPanel:ScanForgeRuns()
	local function ValidRun(run, user_exists, character_usage)
		local general_filters = self.filters[self.filter_keys.general]
		-- Check general filters
		if (general_filters.victory.is_on and not run.won)
			or (general_filters.deathless.is_on and run.total_deaths > 0)
			or (not self.filters[self.filter_keys.players][#run.players_stats < 7 and #run.players_stats or 7].is_on)
			or (general_filters.random_characters.is_on and not run.random_team)
			or (general_filters.unique_characters.is_on and not run.unique_team)
			or (general_filters.is_you.is_on and not user_exists)
			or (run.round == 1 and run.time > TUNING.FORGE.AFK_TIME and not general_filters.afk_runs.is_on)
			-- on and commands or commands
			or (not general_filters.commands_used.is_on and run.commands)
			or (not general_filters.scripts_used.is_on and run.scripts)
            or (not (self.filters[self.filter_keys.modes][run.mode] and self.filters[self.filter_keys.modes][run.mode].is_on))
			or (not (self.filters[self.filter_keys.gametypes][run.gametype] and self.filters[self.filter_keys.gametypes][run.gametype].is_on))
            or (not (self.filters[self.filter_keys.difficulties][run.difficulty] and self.filters[self.filter_keys.difficulties][run.difficulty].is_on))
            or (not (self.filters[self.filter_keys.wavesets][run.waveset] and self.filters[self.filter_keys.wavesets][run.waveset].is_on))
            or (not (self.filters[self.filter_keys.maps][run.map] and self.filters[self.filter_keys.maps][run.map].is_on))
            or (not (self.filters[self.filter_keys.presets][run.preset or "custom"] and self.filters[self.filter_keys.presets][run.preset or "custom"].is_on)) then
			return false
		else
			-- Check characters used
			for character,_ in pairs(character_usage) do
				if not self.filters[self.filter_keys.characters][character].is_on then
					return false
				end
			end
			-- Check mutators
			for mutator,data in pairs(self.filters[self.filter_keys.mutators]) do
				local mutator_value = run.mutators[mutator]
				if mutator_value and not data.is_on or data.is_on and not mutator_value then
					return false
				end
			end
			return true
		end
		return true
	end

	self.current_forge_runs = {}
	self.average_player_stats = {}
	self.average_match_stats = {
		victories = 0,
		defeats = 0,
		leaderboards = 0,
		total_time = 0,
		fastest_time = 99999, -- TODO might want to check to show 0 seconds if not changed?
		slowest_time = 0, -- Currently Invisible
		total_deaths = 0,
		average_time = 0,
		character_usage = {wilson = 0, willow = 0, wolfgang = 0, wendy = 0, wx78 = 0, wickerbottom = 0, woodie = 0, wes = 0, waxwell = 0, wathgrithr = 0, webber = 0, winona = 0, wortox = 0, warly = 0, wormwood = 0, wurt = 0, walter = 0, wanda = 0, unknown = 0},
		most_used_character = "wilson",
		difficulties = {},
		gametypes = {},
		modes = {},
		wavesets = {},
	}
	for i, run in pairs(self.loaded_runs) do
		local user_exists = false
		local character_usage = {}
		local average_player_stats = {}
		for j,stats in pairs(run.players_stats) do
			-- Did user participate in this run?
			if stats.userid == TheNet:GetUserID() then
				user_exists = true
    			for field,val in pairs(stats) do
    				if not stat_exclusions[field] then
    					average_player_stats[field] = (average_player_stats[field] or 0) + tonumber(val)
    				elseif field == "character" then
    					local character = self.filters[self.filter_keys.characters][val] and val or "unknown"
    					character_usage[character] = (character_usage[character] or 0) + 1
    				end
    			end
            end
		end

        --Debug:PrintTable(run, 3)
		-- Only add valid runs
		if ValidRun(run, user_exists, character_usage) then
			local time = tonumber(run.time)
			-- Update average match stats
			self.average_match_stats.victories = self.average_match_stats.victories + (run.won and 1 or 0)
			self.average_match_stats.defeats = self.average_match_stats.defeats + (not run.won and 1 or 0)
			self.average_match_stats.total_time = self.average_match_stats.total_time + time
			self.average_match_stats.fastest_time = run.won and self.average_match_stats.fastest_time > time and time or self.average_match_stats.fastest_time
			self.average_match_stats.slowest_time = run.won and self.average_match_stats.slowest_time < time and time or self.average_match_stats.slowest_time
			self.average_match_stats.average_time = self.average_match_stats.average_time + (run.won and time or 0)
			self.average_match_stats.total_deaths = self.average_match_stats.total_deaths + tonumber(run.total_deaths or 0)
			self.average_match_stats.difficulties[run.difficulty] = (self.average_match_stats.difficulties[run.difficulty] or 0) + 1
			self.average_match_stats.gametypes[run.gametype] = (self.average_match_stats.gametypes[run.gametype] or 0) + 1
			self.average_match_stats.modes[run.mode] = (self.average_match_stats.modes[run.mode] or 0) + 1
			self.average_match_stats.wavesets[run.waveset] = (self.average_match_stats.wavesets[run.waveset] or 0) + 1

			-- Add run stats to total stats for users character
			for field,val in pairs(average_player_stats) do
				self.average_player_stats[field] = (self.average_player_stats[field] or 0) + tonumber(val)
			end
			for character,val in pairs(character_usage) do
				self.average_match_stats.character_usage[character] = (self.average_match_stats.character_usage[character] or 0) + 1
			end

			-- Add run to the current list
			table.insert(self.current_forge_runs, run)
		end
	end

	-- Calculate most frequent stats
	local function GetMostFrequent(data)
		local most_frequent
		local most_frequent_count = 0
		for name,count in pairs(data) do
			if count > most_frequent_count then
				most_frequent = name
				most_frequent_count = count
			end
		end
		return most_frequent
	end
	self.average_match_stats.most_used_character    = GetMostFrequent(self.average_match_stats.character_usage)
	self.average_match_stats.most_played_difficulty = GetMostFrequent(self.average_match_stats.difficulties)
	self.average_match_stats.most_played_gametype   = GetMostFrequent(self.average_match_stats.gametypes)
	self.average_match_stats.most_played_mode       = GetMostFrequent(self.average_match_stats.modes)
	self.average_match_stats.most_played_waveset    = GetMostFrequent(self.average_match_stats.wavesets)
    --Debug:PrintTable(self.average_match_stats.wavesets, 3)
    --print("Most Played: " .. tostring(self.average_match_stats.most_played_waveset))
	-- Calculate Averages
	local total_runs = #self.current_forge_runs
	for field,val in pairs(self.average_player_stats) do
		self.average_player_stats[field] = math.floor(val/total_runs + 0.5)
	end
	self.average_match_stats.average_time = math.floor(self.average_match_stats.average_time / total_runs + 0.5)

	self:UpdateCurrentRunStats(self.current_forge_runs[1])
end

--[[------------------------------
			FORGE RUN
---------------------------------]]
-- Outcome displays that shows date/time, victory, time, players, and filter conditions
function ServerLeaderboardPanel:BuildForgeRunDisplay()
	local outcome_root = Widget("outcome_root")

	-- Display for each outcome text
	local function RunTextItem(title_text, val_text, title_size, text_size, pos_x, pos_y, right_align, color)
		local title = outcome_root:AddChild(Text(HEADERFONT, title_size, title_text, color))
		local title_w, title_h = title:GetRegionSize()
		local x = right_align and title_w/2 or 0
		title:SetPosition(pos_x + x, pos_y)
		if val_text then
			local text = outcome_root:AddChild(Text(HEADERFONT, text_size, val_text, color))
			local text_w, text_h = text:GetRegionSize()
			local x = right_align and text_w/2 or 0
			text:SetPosition(pos_x + title_w + x, pos_y)
		end
	end
	local function RunCheck()
		return #self.current_forge_runs > 0
	end

	local y_buffer = -75
	-- Background Image
	local bg = outcome_root:AddChild(Image("images/lavaarena_unlocks.xml", "box6.tex"))
    bg:SetScale(1.1, .75)
	local bg_width, bg_height = bg:GetSize()
	bg:SetPosition(0, bg_height/2 + y_buffer)

	local current_y_offset = 125 + bg_height/2 + y_buffer--top - 11
	local current_x_offset = 425
	local x_offset = 0
	local title_font_size = 34
	local text_font_size = 22

	-- Victory status text
	local str = (self.average_stats_displayed and STRINGS.UI.FORGEHISTORYPANEL.AVERAGE_STATS.TITLE) or (self.current_run.won and STRINGS.UI.FORGEHISTORYPANEL.RUN.VICTORY) or (self.current_run and STRINGS.UI.FORGEHISTORYPANEL.RUN.DEFEAT) or STRINGS.UI.FORGEHISTORYPANEL.RUN.NONE
	local time_str = (self.average_stats_displayed and "") or (self.current_run.time and ConvertTotalSecondsToTime(tonumber(self.current_run.time))) or STRINGS.UI.FORGEHISTORYPANEL.RUN.NA
	RunTextItem(str .. " " .. time_str, nil, title_font_size, nil, 0, current_y_offset - 10, false, UICOLOURS.BROWN_DARK)

	-- Players
	self.portrait = outcome_root:AddChild(PlayerAvatarPortrait())
	self.portrait:AlwaysHideRankBadge()
	local character = self.average_match_stats.most_used_character or "wilson"
	self.portrait:SetSkins(character, character .. "_magma", {body = "body_" .. tostring(character) .. "_magma", hand = "hand_" .. tostring(character) .. "_magma", legs = "legs_" .. tostring(character) .. "_magma", feet = "feet_" .. tostring(character) .. "_magma"})
	self.portrait:SetBackground("playerportrait_bg_spawngate")
	self.portrait:SetPosition(0,120)
	self.portrait:SetScale(1.2)
	if self.current_run and not self.average_stats_displayed then
		outcome_root:AddChild( self:PlayerIcons(self.current_run.players_stats, self.current_run.fields, -current_x_offset, current_y_offset) )
	elseif self.average_stats_displayed then
		local str = string.format(STRINGS.UI.FORGEHISTORYPANEL.AVERAGE_STATS.WIN_RATE .. ": %.2f", RunCheck() and (self.average_match_stats.victories / (self.average_match_stats.victories + self.average_match_stats.defeats) * 100) or 0)
		RunTextItem(str .. "%", nil, title_font_size, title_font_size, -current_x_offset, current_y_offset, false, UICOLOURS.BROWN_DARK)
	end

	-- Date/Time text
	local str = (self.current_run and self.current_run.date_time and tostring(self.current_run.date_time)) or STRINGS.UI.FORGEHISTORYPANEL.RUN.NA .. " " ..  STRINGS.UI.FORGEHISTORYPANEL.RUN.NA
	local date_time = ParseString(str, " ")
	RunTextItem((self.average_stats_displayed and (STRINGS.UI.FORGEHISTORYPANEL.AVERAGE_STATS.AVERAGE_TIME .. ": " .. ConvertTotalSecondsToTime(RunCheck() and self.average_match_stats.average_time or 0))) or (date_time[1] .. " " .. date_time[2]), nil, title_font_size, title_font_size, current_x_offset, current_y_offset, false, UICOLOURS.BROWN_DARK)

	-- Display Average Stats
	if self.average_stats_displayed then
		local average_stats_root = outcome_root:AddChild( self:BuildAverageStats() )
		average_stats_root:SetPosition(0, 225)

		-- Create Stat Text
		--local average_match_stats_root = outcome_root:AddChild( Widget("stat_root") )
		--average_match_stats_root:SetPosition(600, 225)
		--self.current_team_stat_text = average_match_stats_root:AddChild( self:CreateStatText(average_match_stats_root, nil, self.average_player_stats, "Average Match Stats", true) ) -- TODO string
	else
		-- Stat Icons
		-- Stat Setup
		local stat_order = {"attack", "crowd_control", "defense", "healing", "other"}
		local stat_list = {
			attack = {title = STRINGS.UI.DETAILEDSUMMARYSCREEN.STATS.TITLES.attack, image = "laq_fullhands",},
			crowd_control = {title = STRINGS.UI.DETAILEDSUMMARYSCREEN.STATS.TITLES.crowd_control, image = "laq_petrify",},
			defense = {title = STRINGS.UI.DETAILEDSUMMARYSCREEN.STATS.TITLES.defense, image = "laq_battlestandards",},
			healing = {title = STRINGS.UI.DETAILEDSUMMARYSCREEN.STATS.TITLES.healing, image = "laq_fasthealing",},
			other = {title = STRINGS.UI.DETAILEDSUMMARYSCREEN.STATS.TITLES.other, image = "laq_wintime_20",},
		}
		local stat_icon_x_offset = 0
		local stat_icon_y_offset = 10--200
		local max_icons_per_col = 3
		self.current_stat_display_cat = "attack"

		local function CreateStatIcon(source, tex, pos_x, pos_y, hover_text, cat)
			local stat_icon = outcome_root:AddChild( ImageButton(source, tex, nil, nil, nil, nil) )
			stat_icon:ScaleImage(self.icon_sizes.stats[1], self.icon_sizes.stats[2])
			stat_icon:SetPosition(pos_x, pos_y)
			stat_icon:SetHoverText(hover_text)
			stat_icon:SetOnClick(function()
				if self.current_stat_display_cat ~= cat then
					-- Hide previously selected category
					if self.current_stat_display then
						self.current_stat_display:GetStatsText()[self.current_stat_display_cat]:Hide()
					end
					self.current_team_stat_text:GetStatsText()[self.current_stat_display_cat]:Hide()
					if self.current_rank_text and self.current_rank_text:IsVisible() then
						self.current_rank_text:Hide()
					end

					-- Show the new selected category
					self.current_stat_display_cat = cat
					if self.current_stat_display then
						self.current_stat_display:GetStatsText()[self.current_stat_display_cat]:Show()
					end
					self.current_team_stat_text:GetStatsText()[self.current_stat_display_cat]:Show()
				end
			end)
			return stat_icon
		end

		local stat_icons_offset = -(#stat_order / 2 - 0.5)
		for i,cat in pairs(stat_order) do -- TODO could this be place in for loop above?
			local stat_icon = CreateStatIcon("images/lavaarena_quests.xml", tostring(stat_list[cat].image) .. ".tex", stat_icon_x_offset + self.icon_sizes.stats[1]*(stat_icons_offset + i - 1), stat_icon_y_offset, stat_list[cat].title, cat)
		end
		self.current_stat_display_cat = "attack"
	end

	return outcome_root
end

--
function ServerLeaderboardPanel:BuildAverageStats()
	local average_stats = Widget("average_stats")

	local current_y_offset = 0--125 + bg_height/2 + y_buffer--top - 11
	local current_x_offset = 0
	local x_offset = -600
	local title_font_size = 34
	local text_font_size = 22
	local right_side_offset = 125
	local border_buffer = 10
	local spacing = 10

	local function ConvertTotalSecondsToTime(time)
		if time <= 0 then
			return "00:00:00";
		else
			local hours = string.format("%02.f", math.floor(time/3600));
			local mins = string.format("%02.f", math.floor(time/60 - (hours*60)));
			local secs = string.format("%02.f", math.floor(time - hours*3600 - mins *60));
			return hours .. ":" .. mins .. ":" .. secs
		end
	end

	-- Display for each outcome text
	local function RunTextItem(title_text, val_text, title_size, text_size, pos_x, pos_y, right_align, color)
		local title = average_stats:AddChild(Text(HEADERFONT, title_size, title_text, color))
		local title_w, title_h = title:GetRegionSize()
		local x = right_align and title_w/2 or 0
		title:SetPosition(pos_x + x + border_buffer, pos_y - border_buffer)
		if val_text then
			local text = average_stats:AddChild(Text(HEADERFONT, text_size, val_text, color))
			local text_w, text_h = text:GetRegionSize()
			local x = right_align and text_w/2 or 0
			text:SetPosition(pos_x + title_w + x + border_buffer, pos_y - border_buffer)
		end
	end
	local function RunCheck()
		return #self.current_forge_runs > 0
	end

	-- Total Playtime
	local str = STRINGS.UI.FORGEHISTORYPANEL.AVERAGE_STATS.TOTAL_TIME .. ": " .. ConvertTotalSecondsToTime(self.average_match_stats.total_time)
	RunTextItem(str, nil, title_font_size, nil, x_offset, current_y_offset, true, UICOLOURS.BROWN_DARK)
	current_y_offset = current_y_offset - title_font_size

	-- Fastest and Slowest Time
	local str = STRINGS.UI.FORGEHISTORYPANEL.AVERAGE_STATS.FASTEST_SLOWEST_TIME .. ": " .. ConvertTotalSecondsToTime(RunCheck() and self.average_match_stats.fastest_time or 0) .. "/" .. ConvertTotalSecondsToTime(RunCheck() and self.average_match_stats.slowest_time or 0)
	RunTextItem(str, nil, title_font_size, nil, x_offset, current_y_offset, true, UICOLOURS.BROWN_DARK)
	current_y_offset = current_y_offset - title_font_size

	-- Most Played Title
	local center_left_x_offset = -450
	local str = STRINGS.UI.FORGEHISTORYPANEL.AVERAGE_STATS.MOST_PLAYED_TITLE .. ":"
	RunTextItem(str, nil, title_font_size, nil, center_left_x_offset, current_y_offset, true, UICOLOURS.BROWN_DARK)
	current_y_offset = current_y_offset - title_font_size

	-- Most Played Difficulty
	local str = STRINGS.UI.GAME_SETTINGS_PANEL.DIFFICULTY .. ": " .. (self.average_match_stats.most_played_difficulty and STRINGS.REFORGED.DIFFICULTIES[self.average_match_stats.most_played_difficulty].name or STRINGS.UI.FORGEHISTORYPANEL.RUN.NA)
	RunTextItem(str, nil, title_font_size, nil, x_offset, current_y_offset, true, UICOLOURS.BROWN_DARK)
	current_y_offset = current_y_offset - title_font_size

	-- Most Played Gametype
	local str = STRINGS.UI.GAME_SETTINGS_PANEL.GAMETYPE .. ": " .. (self.average_match_stats.most_played_gametype and STRINGS.REFORGED.GAMETYPES[self.average_match_stats.most_played_gametype].name or STRINGS.UI.FORGEHISTORYPANEL.RUN.NA)
	RunTextItem(str, nil, title_font_size, nil, x_offset, current_y_offset, true, UICOLOURS.BROWN_DARK)
	current_y_offset = current_y_offset - title_font_size

	-- Most Played Mode
	local str = STRINGS.UI.GAME_SETTINGS_PANEL.MODE .. ": " .. (self.average_match_stats.most_played_mode and STRINGS.REFORGED.MODES[self.average_match_stats.most_played_mode].name or STRINGS.UI.FORGEHISTORYPANEL.RUN.NA)
	RunTextItem(str, nil, title_font_size, nil, x_offset, current_y_offset, true, UICOLOURS.BROWN_DARK)
	current_y_offset = current_y_offset - title_font_size

	-- Most Played Waveset
	local str = STRINGS.UI.GAME_SETTINGS_PANEL.WAVESET .. ": " .. (self.average_match_stats.most_played_waveset and STRINGS.REFORGED.WAVESETS[self.average_match_stats.most_played_waveset].name or STRINGS.UI.FORGEHISTORYPANEL.RUN.NA)
	RunTextItem(str, nil, title_font_size, nil, x_offset, current_y_offset, true, UICOLOURS.BROWN_DARK)
	current_y_offset = current_y_offset - title_font_size


	-- Character Usage
	local str = STRINGS.UI.FORGEHISTORYPANEL.AVERAGE_STATS.CHARACTER_USAGE .. ":"
	local max_line_width = 500
	local center_right_x_offset = 350
	local starting_x_offset = center_right_x_offset - max_line_width/2 -- 450 is center?
	current_x_offset = starting_x_offset
	current_y_offset = 0
	RunTextItem(str, nil, title_font_size, nil, center_right_x_offset, current_y_offset, false, UICOLOURS.BROWN_DARK)
	current_y_offset = current_y_offset - title_font_size
	local max_characters_per_row = 4
	local character_count = 0
	local max_line_width = 4*title_font_size/2
	--for character,usage in pairs(self.average_match_stats.character_usage) do
	for index,character in pairs(self.filters[self.filter_keys.characters].options.order) do
		--character_count = character_count + 1
		local character_str = self.filters[self.filter_keys.characters][character] and character or "unknown"
		local char_usage = average_stats:AddChild( Image("images/avatars_resize.xml", tostring(character) .. ".tex") )
		char_usage:ScaleToSize(self.icon_sizes.stats[1], self.icon_sizes.stats[2], true)
		char_usage:SetPosition(current_x_offset + border_buffer + self.icon_sizes.stats[1]/2, current_y_offset - border_buffer)
		current_x_offset = current_x_offset + self.icon_sizes.stats[1] + spacing

		local char_usage_text = average_stats:AddChild( Text(HEADERFONT, title_font_size, tostring(self.average_match_stats.character_usage[character]), UICOLOURS.BROWN_DARK) )
		local text_width, text_height = char_usage_text:GetRegionSize()
		char_usage_text:SetPosition(current_x_offset + border_buffer + text_width/2, current_y_offset - border_buffer)
		current_x_offset = current_x_offset + max_line_width + spacing

		-- Update Offsets
		if index % max_characters_per_row == 0 then
			current_x_offset = starting_x_offset
			current_y_offset = current_y_offset - title_font_size - spacing
		end
	end

	return average_stats
end

-- Creates player icons that can be clicked to display player stats
function ServerLeaderboardPanel:PlayerIcons(players_stats, fields, pos_x, pos_y)
	local player_icons = Widget("player_icons")

	local function LinkFieldsToData(stats, fields, index)
		local field_data = {}
		local character = "wilson"
		local is_player = false
		local player_name = "unknown"
		for i,field in pairs(fields) do
			if stat_exclusions[field] == nil then
				field_data[field] = stats[i]
			elseif field == "character" then
				character = stats[i]
			elseif field == "userid" then
				is_player = stats[i] == TheNet:GetUserID()
			elseif field == "is_you" then
				is_player = stats[i] == "yes"
			elseif field == "name" then
				player_name = stats[i] == "user" and ("player" .. tostring(index)) or stats[i]
			end
		end

		-- Update clients username
		if is_player then
			player_name = TheNet:GetLocalUserName()
		end

		return field_data, player_name, character, is_player
	end

	if players_stats then
		local players = {}
		local current_x_offset = 25
		local spacing = 20
		local num_players = #players_stats
		local starting_x = 0
		if num_players == 3 then
			starting_x = starting_x - self.icon_sizes.player[1]-- - spacing
		elseif num_players == 2 then
			starting_x = starting_x - spacing/2
		end

		self.players = {}
		self.players_stat_text = {}
		self.player_display = {}
		for i,stats in pairs(players_stats) do
			--local field_link, player_name, character, is_player = LinkFieldsToData(player, fields, i)
			local character = stats.character
			local is_player = stats.userid == TheNet:GetUserID() --stats.is_you == "yes"
			players[i] = player_icons:AddChild( ImageButton("images/avatars_resize.xml", tostring(self.filters[self.filter_keys.characters][character] and character or "unknown") .. ".tex", nil, nil, nil, nil) )

			-- Create Stat Text
			local stat_root = player_icons:AddChild( Widget("stat_root") )
			stat_root:SetPosition(-600, 225)
			self.players_stat_text[i] = stat_root:AddChild( self:CreateStatText(stat_root, stats.fields, stats, string.format(STRINGS.UI.FORGEHISTORYPANEL.RUN.PLAYER_STATS_TITLE .. ":", tostring(stats.name))) )
			if is_player then
				self.player_display[i] = true
				self.current_stat_display = self.players_stat_text[i]
				self.portrait:SetSkins(character, tostring(character) .. "_magma", {body = "body_" .. tostring(character) .. "_magma", hand = "hand_" .. tostring(character) .. "_magma", legs = "legs_" .. tostring(character) .. "_magma", feet = "feet_" .. tostring(character) .. "_magma"})
				self.portrait:SetBackground("playerportrait_bg_spawngate")
			else
				self.players_stat_text[i]:Hide()
				self.player_display[i] = false
			end
			players[i]:SetOnClick(function()
				if not self.players_stat_text[i]:IsVisible() then
					self:UpdateCurrentStatScreen(character)
					--self.player_display[i] = true
                    if self.current_stat_display then
    					self.current_stat_display:GetStatsText()[self.current_stat_display_cat]:Hide()
    					self.current_stat_display:Hide()
    					self.current_stat_display = self.players_stat_text[i]
    					self.current_stat_display:Show()
    					self.current_stat_display:GetStatsText()[self.current_stat_display_cat]:Show()
                    end
					self.portrait:SetSkins(character, tostring(character) .. "_magma", {body = "body_" .. tostring(character) .. "_magma", hand = "hand_" .. tostring(character) .. "_magma", legs = "legs_" .. tostring(character) .. "_magma", feet = "feet_" .. tostring(character) .. "_magma"})
					self.portrait:SetBackground("playerportrait_bg_spawngate")
				end
			end)
			players[i]:ScaleImage(self.icon_sizes.player[1], self.icon_sizes.player[2])
			players[i]:SetPosition(pos_x + self.icon_sizes.player[1] * (-(num_players - 1)/2 + (i - 1)), pos_y)
			--local width, height = players[i]:GetSize()
			local width = self.icon_sizes.player[1]
			players[i]:SetHoverText(stats.name)
			current_x_offset = current_x_offset + width-- + spacing
		end
	else
		-- TODO should it display empty stuff or just leave blank?
	end

	-- Create Stat Text
	local team_stats_root = player_icons:AddChild( Widget("stat_root") )
	team_stats_root:SetPosition(600, 225)
	self.current_team_stat_text = team_stats_root:AddChild( self:CreateStatText(team_stats_root, nil, self.current_team_stats, STRINGS.UI.DETAILEDSUMMARYSCREEN.TEAMSTATS.TITLE, true, true) )

	return player_icons
end

--
function ServerLeaderboardPanel:UpdateCurrentStatScreen(character)
	-- Hide all then check which one is shown
	for i, players in pairs(self.players) do
		players:Hide()
		self.player_display[i] = false
	end
	self.portrait.puppet:SetCharacter(character)
end

--
function ServerLeaderboardPanel:UpdateCurrentStats()

end

--[[------------------------------
			STATS
---------------------------------]]
-- Creates Player Stats panel
function ServerLeaderboardPanel:CreateStatText(root, player, player_stats, title, right_side, is_team)
	local stat_text_root = Widget("stat_text_root")
	local title_font_size = 35

	local current_x_offset = 0--max_width -- need to shift initial offset so the numbers are to the right
	local current_y_offset = 0

	-- Stat Setup
	local stat_order = {"attack", "crowd_control", "defense", "healing", "other"}
	local stat_list = {
		attack = {
			title = STRINGS.UI.DETAILEDSUMMARYSCREEN.STATS.TITLES.attack,
			count = 0, stats = {}, image = "laq_specials_somany",},
		crowd_control = {
			title = STRINGS.UI.DETAILEDSUMMARYSCREEN.STATS.TITLES.crowd_control,
			count = 0, stats = {}, image = "laq_petrify",},
		defense = {
			title = STRINGS.UI.DETAILEDSUMMARYSCREEN.STATS.TITLES.defense,
			count = 0, stats = {}, image = "laq_battlestandards",},
		healing = {
			title = STRINGS.UI.DETAILEDSUMMARYSCREEN.STATS.TITLES.healing,
			count = 0, stats = {}, image = "laq_stronghealing",},
		other = {
			title = STRINGS.UI.DETAILEDSUMMARYSCREEN.STATS.TITLES.other,
			count = 0, stats = {}, image = "laq_wintime_20",},
	}

	-- Organize Stats
	for field, val in pairs(player_stats) do
		if not stat_exclusions[field] and (self.only_show_nonzero_stats and tonumber(val) > 0 or not self.only_show_nonzero_stats) then
			local current_cat = stat_list[(TUNING.FORGE.STAT_CATEGORIES[field] and TUNING.FORGE.STAT_CATEGORIES[field].category or "other")]
			current_cat.count = current_cat.count + 1
			table.insert(current_cat.stats, field)
		end
	end
	-- Order the stats in each category based on its priority
	for category,data in pairs(stat_list) do
		table.sort(data.stats, function(a,b)
			return (TUNING.FORGE.STAT_CATEGORIES[a] and TUNING.FORGE.STAT_CATEGORIES[a].priority or 9999) < (TUNING.FORGE.STAT_CATEGORIES[b] and TUNING.FORGE.STAT_CATEGORIES[b].priority or 9999) -- Note: 9999 is used for stats with no priority so that they will be listed last
		end)
	end

	local max_line_width = 250
	local border_buffer = 20

	-- Title
	local stat_title = stat_text_root:AddChild( Text(HEADERFONT, title_font_size, title, UICOLOURS.WHITE) )
	local stats_header_text_size_x, stats_header_text_size_y = stat_title:GetRegionSize()
	stat_title:SetPosition(current_x_offset + max_line_width * (right_side and -1 or 1), current_y_offset - stats_header_text_size_y*0.5)
	local details_line = MakeDetailsLine(stat_text_root, current_x_offset + max_line_width * (right_side and -1 or 1), current_y_offset - stats_header_text_size_y, .5)
	local details_line_width, details_line_height = details_line:GetSize()
	local details_line_x_offset = -50

	-- Create the players rank text for the given stat
	local function UpdateCurrentStat(team_stat_widget, current_stat)
		local function GetTextRankingColor(rank)
			return self.display_colored_stats and (rank == 1 and UICOLOURS.GOLD or rank == 2 and UICOLOURS.SILVER or rank == 3 and UICOLOURS.BRONZE) or UICOLOURS.WHITE
		end
		local max_players_displayed = 12
		local max_players_per_col = 6
		self.current_stat = current_stat
		if self.current_rank_text ~= nil then
			self.current_rank_text:Kill() -- Do this to get rid of previous rank text
		end
		-- Current Rank
		self.current_rank_text = stat_text_root:AddChild( Widget("Rank Text") )
		--self.current_rank_text:Hide()

		-- Create text for each player to display, max of 12 players, players must have a stat value > 0 to be displayed
		local header_font = BODYTEXTFONT
		local stats_header_fontsize = 30
		local stats_header_spacing = 10
		local buffer = 10
		local current_pos_x = 0--self.stats_starting_pos_x
		local current_pos_y = 0--self.stats_title_pos_y - self.stats_title_spacing - buffer
		local count = 1
		local previous_rank = 1
		while self.current_team_stat_rankings[current_stat] and self.current_team_stat_rankings[current_stat][count] and self.current_team_stat_rankings[current_stat][count].val > 0 and count <= max_players_displayed do
			local stat_info = self.current_team_stat_rankings[current_stat][count]

			-- Check for ties, only update rank if no tie is found
			if count > 1 and stat_info.val < self.current_team_stat_rankings[current_stat][count - 1].val then
				previous_rank = count
			end

			local stat_rank_text = self.current_rank_text:AddChild( Text(header_font, stats_header_fontsize, previous_rank .. ": " .. tostring(self.current_run.players_stats[self.stat_user_link[stat_info.player]].userid == TheNet:GetUserID() and TheNet:GetLocalUserName() or self.current_run.players_stats[self.stat_user_link[stat_info.player]].name) .. " - " .. tostring(stat_info.val), GetTextRankingColor(previous_rank)) )

			local stats_text_size_x, stats_text_size_y = stat_rank_text:GetRegionSize()
			current_pos_y = current_pos_y - stats_header_fontsize
			stat_rank_text:SetPosition(current_pos_x - max_line_width * (count <= max_players_per_col and 2 or 1) + border_buffer + stats_text_size_x*0.5, current_pos_y - stats_header_fontsize*0.5, 0)

			if count == max_players_per_col then
				current_pos_y = 0
			end
			count = count + 1
			stat_rank_text:Show()
		end

		-- Title
		stat_title:SetString(STRINGS.UI.DETAILEDSUMMARYSCREEN.TEAMSTATS.STATHEADERS[current_stat or "unknown"])
		local stats_title_text_size_x, stats_title_text_size_y = stat_title:GetRegionSize()
		stat_title:SetPosition(current_x_offset + max_line_width * (right_side and -1 or 1), -stats_title_text_size_y*0.5, 0)

		-- Back Button
		local back_button = self.current_rank_text:AddChild( ImageButton("images/ui.xml", "crafting_inventory_arrow_l_idle.tex") )
		back_button:ScaleImage(self.icon_sizes.stats[1], self.icon_sizes.stats[2])
		back_button:SetPosition(current_pos_x - max_line_width * 1.5 - border_buffer*2, -border_buffer/2)
		back_button:SetHoverText(STRINGS.UI.FORGEHISTORYPANEL.RUN.BACK_BUTTON)
		back_button:SetOnClick(function()
			self.current_rank_text:Hide()
			team_stat_widget:Show()
			back_button:Hide()
			stat_title:SetString(title)
			local stats_title_text_size_x, stats_title_text_size_y = stat_title:GetRegionSize()
			stat_title:SetPosition(current_x_offset + max_line_width * (right_side and -1 or 1), -stats_title_text_size_y*0.5)
		end)
		self.current_rank_text:Show()
		team_stat_widget:Hide()
	end

	local function CreateStatText(stats, pos_x, pos_y)
		local stat_text = Widget("stat_text")
		local font = BODYTEXTFONT
		local stats_fontsize = 30
		local header_buffer = 5
		local current_x_offset = 0
		local current_y_offset = 0
		local max_stats_per_col = 6

		local function GetTextRankingColor(rank)
			return self.display_colored_stats and (rank == 1 and UICOLOURS.GOLD or rank == 2 and UICOLOURS.SILVER or rank == 3 and UICOLOURS.BRONZE) or UICOLOURS.WHITE
		end
		local function GetXPosition(text_width, index)
			local base_x_pos = pos_x + text_width*0.5 + border_buffer
			local offset_x = (right_side and (-max_line_width * (index <= max_stats_per_col and 2 or 1))) or (index > max_stats_per_col and max_line_width or 0)

			return base_x_pos + offset_x
		end

		for i,stat in pairs(stats) do
			if is_team then
				local text = stat_text:AddChild( TextButton() )
				text:SetFont(font)
				text.text:SetSize(stats_fontsize)
				text:SetText(tostring(self.current_team_stats[stat]) .. " " .. (STRINGS.UI.MVP_LOADING_WIDGET[self.current_eventid].DESCRIPTIONS[stat] or STRINGS.MVP_LOADING_WIDGET[self.current_eventid].DESCRIPTIONS.unknown))
				text:SetTextColour(UICOLOURS.WHITE)
				text:SetTextFocusColour(UICOLOURS.GOLD_CLICKABLE)

				-- Only update current stat if the stat has a value greater than 0
				text:SetOnClick(function()
					if self.current_team_stats[stat] > 0 then
						UpdateCurrentStat(stat_text, stat)
					end
				end)
				text:Show()

				local stat_text_size_x, stat_text_size_y = text:GetSize()
				text:SetPosition(GetXPosition(stat_text_size_x, i), pos_y + current_y_offset - stats_fontsize*0.5, 0)
				current_y_offset = current_y_offset - stats_fontsize
			else
				local text = stat_text:AddChild( Text(font, stats_fontsize, tostring(player_stats[stat]) .. " " .. (STRINGS.UI.MVP_LOADING_WIDGET[self.current_eventid].DESCRIPTIONS[stat] or STRINGS.UI.MVP_LOADING_WIDGET[self.current_eventid].DESCRIPTIONS.unknown), player and GetTextRankingColor(self.current_player_stat_rankings[player][stat]) or UICOLOURS.WHITE) ) --(self.stat_rankings[stat])

				local stats_text_size_x, stats_text_size_y = text:GetRegionSize()
				text:SetPosition(GetXPosition(stats_text_size_x, i), pos_y + current_y_offset - stats_fontsize*0.5, 0)
				current_y_offset = current_y_offset - stats_fontsize
			end

			if i == max_stats_per_col then
				current_y_offset = 0
			end
		end

		return stat_text
	end

	-- Create text for each category that has stats to display
	local stats_text = {}
	for i,category in pairs(stat_order) do
		local values = stat_list[category]
		stats_text[category] = stat_text_root:AddChild( CreateStatText(values.stats, current_x_offset, current_y_offset - stats_header_text_size_y) )
		if i > 1 then
			stats_text[category]:Hide()
			self.display_stats[i] = false
		else
			self.display_stats[i] = true
		end
	end
	stat_text_root.GetStatsText = function()
		return stats_text
	end

	return stat_text_root
end

--
function ServerLeaderboardPanel:UpdateCurrentRunStats(run)
	self.current_run = run
	self.current_player_stat_rankings = {}
	self.current_team_stat_rankings = {}
	self.current_team_stats = {}
	self.current_stat_field_link = {}
	if #self.current_forge_runs > 0 then

		-- Get each players stat info
		for j,stats in pairs(run.players_stats) do
			local player = stats.fields--stats[1] == "user" and ("player" .. tostring(j)) or stats[1] or STRINGS.UI.MVP_LOADING_WIDGET.LAVAARENA.DESCRIPTIONS.unknown
			for field,val in pairs(stats) do
				if not stat_exclusions[field] then
					if not self.current_team_stat_rankings[field] then
						self.current_team_stat_rankings[field] = {}
					end
					-- Keep list of stats in ranking order for team stats
					table.insert(self.current_team_stat_rankings[field], {player = player, val = tonumber(val)})
					self.current_team_stats[field] = (self.current_team_stats[field] or 0) + (tonumber(val) or 0)
				end
			end
		end
		for field,ranks in pairs(self.current_team_stat_rankings) do
			local stat_ranks = self.current_team_stat_rankings[field]
			-- Rank each player by highest stat value
			table.sort(ranks, function(a,b)
				return a.val > b.val
			end)
			-- Link player id to their stat rankings
			for rank,stat_data in pairs(ranks) do
				if not self.current_player_stat_rankings[stat_data.player] then
					self.current_player_stat_rankings[stat_data.player] = {}
				end
				-- If the player above the current rank has the same stat value then they will copy that players rank else they will get the current rank
				self.current_player_stat_rankings[stat_data.player][field] = ((rank > 1) and (stat_ranks[rank - 1].val == stat_data.val) and self.current_player_stat_rankings[stat_ranks[rank - 1].player][field]) or rank
			end
		end
		self.stat_user_link = {}
		for i,stats in pairs(run.players_stats) do
			if stats.fields then
				self.stat_user_link[stats.fields] = i
			end
		end
	end
end

--[[------------------------------
		Forge Runs List Menu
---------------------------------]]
--
function ServerLeaderboardPanel:BuildForgeRunListMenu()
	local menu_root = Widget("menu_root")

	local border_buffer = 20

	local bg = menu_root:AddChild(Image("images/lavaarena_unlocks.xml", "box1.tex"))
    bg:SetScale(1, 1.3)
    local bg_width, bg_height = bg:GetSize()
	bg:SetPosition(0, 0)

	self.forge_runs_list = menu_root:AddChild( self:BuildForgeRunsList() )
	local list_scale = 1.3
	self.forge_runs_list:SetScale(list_scale)
	self.forge_runs_list.empty_list = self.forge_runs_list:AddChild( Text(HEADERFONT, 40, STRINGS.UI.FORGEHISTORYPANEL.RUN.EMPTY_LIST, UICOLOURS.BROWN_DARK) )
	local grid_w, grid_h = self.forge_runs_list:GetScrollRegionSize()
	self.forge_runs_list:SetPosition(-bg_width/2 + grid_w/2*list_scale + border_buffer, 0)
	self.forge_runs_list.empty_list:Hide()

	self.filters_root = menu_root:AddChild(self:BuildFilterPanel())
	self.filters_root:SetPosition(bg_width/4, 0)
	self:AdjustFilterDisplay()

	return menu_root
end

--[[------------------------------
			FILTERS
---------------------------------]]
-- Change index of current meal and update display
function ServerLeaderboardPanel:ApplyFilters()
	self:ScanForgeRuns()
	self:UpdateForgeRunsList()
	self:RefreshForgeRunDisplay()
	--self:_DoFocusHookups() -- what did I use this for??? TODO
end

function ServerLeaderboardPanel:UpdateForgeRunsList()
	-- Runs
	if self.current_forge_runs and #self.current_forge_runs > 0 then
		self.forge_runs_list:SetItemsData(self.current_forge_runs)
		self.forge_runs_list.empty_list:Hide()
	else
		self.forge_runs_list:SetItemsData()
		self.forge_runs_list.empty_list:Show()
	end
end

function ServerLeaderboardPanel:RefreshForgeRunDisplay()
	-- Don't allow current run stats to be displayed if there are none
	self.average_stats_displayed = not (#self.current_forge_runs > 0 and not self.average_stats_displayed)
	self.average_stats_button.image:SetTint(unpack(self.average_stats_displayed and {1,1,1,1} or {.5,.5,.5,1}))
	-- Forge Run
	self.forge_run_display:KillAllChildren()
	self.forge_run_display:AddChild(self:BuildForgeRunDisplay())
end

function ServerLeaderboardPanel:BuildFilterPanel()
	local root = Widget("filter_root")
	root:SetScale(1.5)

	local top = 50
	local left = 0 -- -width/2 + 5

	local forge_runs_options = {}
	for i=1, #self.current_forge_runs, 1 do
		table.insert(forge_runs_options, {text = string.format(STRINGS.UI.FORGEHISTORYPANEL.SORTERS.RUN_COUNT, tostring(i), tostring(#self.current_forge_runs)), data = i})
	end
	local function on_forge_runs_filter( data )
		self.current_index = data
		self:UpdateCurrentRunStats(self.current_forge_runs[data])
		--self.spinners[2]:SetSelected(self.current_sorting_filter) -- TODO see if this did anything
		self:RefreshForgeRunDisplay()
	end

	local sorting_options = {
		{text = STRINGS.UI.FORGEHISTORYPANEL.SORTERS.MOST_RECENT, data = "most_recent"},
		{text = STRINGS.UI.FORGEHISTORYPANEL.SORTERS.FASTEST_TIME, data = "fast_time"},
		{text = STRINGS.UI.FORGEHISTORYPANEL.SORTERS.LONGEST_TIME, data = "slow_time"},
	}
	local function on_sorting_filter( data )
		local function ConvertStringListToNum(strings)
			local numbers = {}
			for i,j in pairs(strings) do
				numbers[i] = tonumber(j)
			end

			return numbers
		end
		local function SplitDateTime(str)
			local date_time = ParseString(str, " ")
			local date = ParseString(date_time[1], "/")
			local time = ParseString(date_time[2], ":")

			return ConvertStringListToNum(date), ConvertStringListToNum(time)
		end
		self.current_sorting_filter = data
		if data == "fast_time" then
			table.sort(self.current_forge_runs, function(a,b)
				return tonumber(a.time) < tonumber(b.time)
			end)
		elseif data == "slow_time" then
			table.sort(self.current_forge_runs, function(a,b)
				return tonumber(a.time) > tonumber(b.time)
			end)
		elseif data == "most_recent" then
			table.sort(self.current_forge_runs, function(a,b)
				local a_date, a_time = SplitDateTime(a.date_time)
				local b_date, b_time = SplitDateTime(b.date_time)

				return a_date[3] > b_date[3] or a_date[3] == b_date[3] and ( a_date[1] > b_date[1] or a_date[1] == b_date[1] and ( a_date[2] > b_date[2] or ( a_date[2] == b_date[2] and ( a_time[1] > b_time[1] or a_time[1] == b_time[1] and ( a_time[2] > b_time[2] or a_time[2] == b_time[2] and (a_time[3] > b_time[3]) ) ) ) ) )
			end)
		end
		self.current_index = 1
		self:UpdateCurrentRunStats(self.current_forge_runs[self.current_index]) -- TODO does not update display atm, should I? if not get rid of this.
		if self.spinners then
			self.spinners[1]:SetSelected(self.current_index)
		end
		--self:ApplyFilters() -- TODO
		self:UpdateForgeRunsList()
		self:RefreshForgeRunDisplay()
	end

	local width_label = 150 -- TODO make dynamic OR change the size of the runs so that it is smaller
	local width_spinner = 150
	local height = 25

	local function MakeSpinner(labeltext, spinnerdata, onchanged_fn, initial_data)
		local spacing = 5
		local font = HEADERFONT
		local font_size = 18

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

	local items = {}
	table.insert(items, MakeSpinner(STRINGS.UI.FORGEHISTORYPANEL.SORTERS.RUNS_TITLE, forge_runs_options, on_forge_runs_filter, "most_recent"))
	table.insert(items, MakeSpinner(STRINGS.UI.FORGEHISTORYPANEL.SORTERS.SORTER_TITLE, sorting_options, on_sorting_filter, "most_recent"))

	self.spinners = {}
	for i, v in ipairs(items) do
		local w = root:AddChild(v)
		w:SetPosition(-170 + 220 * (i - 1), - 75)
		table.insert(self.spinners, w.spinner)
	end

	-- Filters
	local filter_title = root:AddChild( Text(HEADERFONT, 36, STRINGS.UI.FORGEHISTORYPANEL.FILTERS.TITLE, UICOLOURS.BROWN_DARK) )
	filter_title:SetPosition(0,70)

	local divider_horiz = root:AddChild(Image("images/ui.xml", "line_horizontal_4.tex"))
    --divider_horiz:SetScale(.75, .75)
    divider_horiz:SetSize(400, 2)
	--divider_horiz:SetSize(max_filters_per_line * self.icon_sizes.filters[1] + (spacing + divider_spacing)* max_filter_categories, 2)
	divider_horiz:SetPosition(0, 60)
	divider_horiz:SetTint(107/255, 84/255, 58/255, 0.5)

	local right_button = root:AddChild( ImageButton("images/ui.xml", "crafting_inventory_arrow_r_hl.tex", nil, nil, nil, nil) )
	right_button:ForceImageSize(25,25)
	right_button:SetPosition(60, 70)

	local left_button = root:AddChild( ImageButton("images/ui.xml", "crafting_inventory_arrow_l_hl.tex", nil, nil, nil, nil) )
	left_button:ForceImageSize(25,25)
	left_button:SetPosition(-60, 70)

	right_button:SetOnClick(function()
		self:AdjustFilterDisplay(1)
	end)
	left_button:SetOnClick(function()
		self:AdjustFilterDisplay(-1)
	end)

	-- Sort the list initially
	self.spinners[2]:Changed(self.current_sorting_filter)
	self:UpdateForgeRunsList()
	--self:RefreshForgeRunDisplay() -- TODO is this needed?

	return root
end

function ServerLeaderboardPanel:AdjustFilterDisplay(index_shift)
	local new_filter_index = index_shift and (self.current_filter_index + index_shift) or 1
	-- Remove old filter display
	if self.filter_buttons then
		-- Check for invalid shift
		if new_filter_index <= 0 or new_filter_index > self.current_filter_index and (self.current_filter_index + self.filter_categories_displayed - 1) >= #self.filters then
			return
		end
		for cat,data in pairs(self.filter_buttons) do
			for i,button in pairs(data) do
				button:Kill()
				data[i] = nil
			end
			self.filter_buttons[cat] = nil
		end

		for _,divider in pairs(self.filter_dividers) do
			divider:Kill()
		end
	else
		self.filter_buttons = {}
		self.filter_dividers = {}
	end

	-- Setup
	local spacing = 5
	local divider_spacing = 10
	local filters_per_row = 3
	local starting_x_pos = -300
	local starting_y_pos = 50
	local current_x_pos = 0

	-- Calculate max width since different categories can have different widths
	local max_filter_width = 400
	local total_filter_width = 0
	local category_width = 0
	local current_categories_displayed = 0
	local total_filter_width = 0
	while total_filter_width < max_filter_width and new_filter_index + current_categories_displayed <= #self.filters do
		local filters_per_line = self.filters[new_filter_index + current_categories_displayed].options.filters_per_row or 3
		category_width = filters_per_line*(self.icon_sizes.filters[1] + spacing) - spacing + (current_categories_displayed > 0 and divider_spacing or 0)
		total_filter_width = total_filter_width + category_width
		current_categories_displayed = current_categories_displayed + 1
	end
	-- Save filter settings and adjust if max width was reached
	local width_cap_reached = total_filter_width > max_filter_width
	total_filter_width = total_filter_width - (width_cap_reached and category_width or 0)
	self.filter_categories_displayed = current_categories_displayed - (width_cap_reached and 1 or 0)
	self.current_filter_index = new_filter_index
	local current_max_filter_index = self.current_filter_index + self.filter_categories_displayed - 1 -- "-1" because exclusive
	local filter_per_row_count = 0
	-- Create Filter display for each category
	for index=self.current_filter_index,current_max_filter_index do
		local cat = self.filters[index]
		local name = cat.options.name
		local filter_count = 0
		local current_index = index - self.current_filter_index + 1
		-- Update position offsets
		local current_x_offset = 0
		local current_y_offset = 0
		local current_filters_per_row = (cat.options.filters_per_row or filters_per_row)
		current_x_pos = -total_filter_width/2 + filter_per_row_count*(self.icon_sizes.filters[1] + spacing) + (-spacing + divider_spacing)*(current_index - 1) + self.icon_sizes.filters[1]/2
		filter_per_row_count = filter_per_row_count + current_filters_per_row
		if index < current_max_filter_index then
			local divider_vert = self.filters_root:AddChild(Image("images/ui.xml", "line_vertical_2.tex"))
			divider_vert:SetScale(.5, .25)
			local div_vert_width, div_vert_height = divider_vert:GetSize()
			divider_vert:SetPosition(current_x_pos + current_filters_per_row * (self.icon_sizes.filters[1] + spacing) - spacing + divider_spacing/2 - self.icon_sizes.filters[1]/2, 60 - div_vert_height/2*.25)
			divider_vert:SetTint(107/255, 84/255, 58/255, 0.5)
			table.insert(self.filter_dividers, divider_vert)
		end

		if not self.filter_buttons[name] then
			self.filter_buttons[name] = {}
		end
		for i,filter in pairs(cat.options.order) do
			if not self.filter_buttons[name][filter] then
				if cat.options.source == "text" or cat[filter].force_source == "text" then
					self.filter_buttons[name][filter] = self.filters_root:AddChild( TextButton() )
					self.filter_buttons[name][filter]:SetText(cat[filter].str)
					self.filter_buttons[name][filter]:SetColour(unpack(cat[filter].is_on and {0.9,0.8,0.6,1} or UICOLOURS.BLACK)) -- on uses the default textbutton color
				else
					self.filter_buttons[name][filter] = self.filters_root:AddChild( ImageButton(cat[filter].force_source or cat.options.source, cat[filter].icon, nil, nil, nil, nil) )
					self.filter_buttons[name][filter]:ScaleImage(self.icon_sizes.filters[1],self.icon_sizes.filters[2])
					self.filter_buttons[name][filter].image:SetTint(unpack(cat[filter].is_on and {1,1,1,1} or {.5,.5,.5,1}))
				end
				self.filter_buttons[name][filter].on_hover_text = cat[filter].str .. ": " .. STRINGS.UI.FORGEHISTORYPANEL.FILTERS.ON
				self.filter_buttons[name][filter].off_hover_text = cat[filter].str .. ": " .. STRINGS.UI.FORGEHISTORYPANEL.FILTERS.OFF
				self.filter_buttons[name][filter]:SetHoverText(cat[filter].is_on and self.filter_buttons[name][filter].on_hover_text or self.filter_buttons[name][filter].off_hover_text)

				-- On Click Functions
				self.filter_buttons[name][filter]:SetOnClick(function()
					local function ToggleIcon(filter, filter_button, is_on)
						if cat.options.source == "text" or cat[filter].force_source == "text" then
							filter_button:SetColour(unpack(is_on and {0.9,0.8,0.6,1} or UICOLOURS.BLACK)) -- on uses the default textbutton color
						else
							filter_button.image:SetTint(unpack(is_on and {1,1,1,1} or {.5,.5,.5,1}))
						end
						filter_button:SetHoverText(is_on and filter_button.on_hover_text or filter_button.off_hover_text)
					end
					local function ToggleAllIcons(is_on)
						for filter,filter_button in pairs(self.filter_buttons[name]) do
							ToggleIcon(filter, filter_button, is_on)
						end
						for j,fil in pairs(self.filters[index]) do
							if j == filter then
								fil.is_on = true
							else
								fil.is_on = is_on
							end
						end
					end

					-- If shift is held down then toggle all filters off in the category except the selected filter
					if TheInput:IsKeyDown(KEY_SHIFT) then
						ToggleAllIcons(false)
					-- If Left Control is held down then toggle all filters on in the category
					elseif TheInput:IsKeyDown(KEY_LCTRL) then
						ToggleAllIcons(true)
					-- Only toggle the selected filter button
					else
						cat[filter].is_on = not cat[filter].is_on
					end

					-- Update selected filter icon
					ToggleIcon(filter, self.filter_buttons[name][filter], cat[filter].is_on)

					-- Apply Filters
					self:UpdateSpinners()
				end)
			else
				self.filter_buttons[name][filter]:Show()
			end
			filter_count = filter_count + 1
			self.filter_buttons[name][filter]:SetPosition(current_x_pos + ((i-1)%current_filters_per_row)*(self.icon_sizes.filters[1] + spacing), starting_y_pos + current_y_offset - divider_spacing/2)

			-- Update position offsets
			current_x_offset = current_x_offset + self.icon_sizes.filters[1]
			if filter_count % current_filters_per_row == 0 then
				current_y_offset = current_y_offset - self.icon_sizes.filters[2]
				current_x_offset = 0
			end
		end
	end
end

--
function ServerLeaderboardPanel:UpdateSpinners()
	self:ApplyFilters()
	local total_runs = #self.current_forge_runs
	local forge_runs_options = {}
	for i=1, total_runs, 1 do
		table.insert(forge_runs_options, {text = string.format(STRINGS.UI.FORGEHISTORYPANEL.SORTERS.RUN_COUNT, tostring(i), tostring(total_runs)), data = i})
	end
	if total_runs == 0 then
		table.insert(forge_runs_options, {text = STRINGS.UI.FORGEHISTORYPANEL.SORTERS.NO_RUNS, data = 1})
	end
	self.current_index = 1
	self.spinners[2]:Changed(self.current_sorting_filter)
	--self:UpdateCurrentRunStats(self.current_forge_runs[1])
	self.spinners[1]:SetOptions(forge_runs_options)
	self.spinners[1]:SetSelected(self.current_index)
end

--[[------------------------------
			Runs
---------------------------------]]
-- Creates a scrolling list of forge runs
function ServerLeaderboardPanel:BuildForgeRunsList()
	local forge_runs_list_width = self.total_row_width--650
	local FONT_SIZE = 35
	local dialog_width = forge_runs_list_width + (60*2) -- nineslice sides are 60px each
    --local row_width,row_height = dialog_width*0.9, 36 -- 60 height also works okay
	local row_width,row_height = self.total_row_width, 36 -- 60 height also works okay
    local detail_img_width = 26
    local can_fit_two_rows = (row_height / detail_img_width) > 2

    local function ScrollWidgetsCtor(context, index)
        local row = self.forge_runs_list_rows:AddChild(Widget("forge_runs_list_row"))
		row:SetPosition(0,0,0)

        local font_size = 15--math.floor(FONT_SIZE * .6)
        local y_offset = 0
        local y_offset_top = y_offset + 10
        if not can_fit_two_rows then
            y_offset_top = 0
        end

		-- TODO are these supposed to be set to index?
        -- The index within the filtered list
        row.display_index = -1
        -- The index within self.servers
        row.unfiltered_index = -1

		-- Mouse Hover
        row:SetOnGainFocus(function() self.forge_runs_list:OnWidgetFocus(row) end)

		-- Mouse Clicks
        local onclickdown = function() self:OnStartClickRunInList(row.display_index)  end -- TODO add sound?
        local onclickup   = function() self:OnFinishClickRunInList(index) end
        row.cursor = row:AddChild(TEMPLATES.ListItemBackground(
                row_width,
                row_height,
                onclickup
            ))
        -- Positioning within a row is unfortunate. This one should probably be centred or offset by its width, but fixing that doesn't seem worth it.
        --row.cursor:SetPosition( row_width/2-90, y_offset, 0)
		row.cursor:SetPosition( 0, y_offset, 0)
        row.cursor:SetOnDown(onclickdown)
        row.cursor:Hide()
		row.cursor.AllowOnControlWhenSelected = true
		row.cursor:SetImageNormalColour(  unpack({1,1,1,1}))

        -- Console Commands and Spamware
        local cheat_icons_x_pos = -self.total_row_width/2 + self.icon_sizes.list[1]/2
        row.SPAM = row:AddChild(Image("images/filter_icons.xml", "orig_forge.tex"))
        row.SPAM:SetPosition(cheat_icons_x_pos, y_offset_top)
        row.SPAM:ScaleToSize(self.icon_sizes.list, nil, true)
        row.COMMANDS = row:AddChild(Image("images/filter_icons.xml", "orig_forge.tex"))
        row.COMMANDS:SetPosition(cheat_icons_x_pos, y_offset_top)
        row.COMMANDS:ScaleToSize(self.icon_sizes.list, nil, true)

		-- Index
		row.INDEX = row:AddChild(Text(CHATFONT, font_size))
        row.INDEX:SetHAlign(ANCHOR_MIDDLE)
        row.INDEX:SetString("")
        row.INDEX._align =
        {
            maxwidth = 50,
            maxchars = 5,
            x = -row_width/2,--self.column_offsets.INDEX,
            y = y_offset_top,
        }
        row.INDEX:SetPosition(row.INDEX._align.x, row.INDEX._align.y, 0)

		-- Outcome
        row.OUTCOME = row:AddChild(Text(CHATFONT, font_size))
        row.OUTCOME:SetHAlign(ANCHOR_MIDDLE)
        row.OUTCOME:SetString("")
        row.OUTCOME._align =
        {
            maxwidth = 125,--200,
            maxchars = 25,
            x = self.column_offsets.OUTCOME - row_width/2,--self.column_offsets.OUTCOME,
            y = y_offset_top,
        }
        row.OUTCOME:SetPosition(row.OUTCOME._align.x, row.OUTCOME._align.y, 0)

		-- Characters (max is 6)
		row.CHARACTERS = {}
		for i = 1, 6, 1 do -- TODO constant!!!
			row.CHARACTERS[i] = row:AddChild(Image("images/avatars_resize.xml", "unknown.tex")) -- TODO default to wilson? use forge face?
			row.CHARACTERS[i]:Hide()
		end

		-- Time
		row.TIME = row:AddChild(Text(CHATFONT, font_size))
        row.TIME:SetHAlign(ANCHOR_MIDDLE)
        row.TIME:SetString("")
        row.TIME._align =
        {
            maxwidth = 80,
            maxchars = 10,
            x = self.column_offsets.TIME - row_width/2,--self.column_offsets.TIME,
            y = y_offset_top,
        }
        row.TIME:SetPosition(row.TIME._align.x, row.TIME._align.y, 0)

        local current_icon_x_pos = self.column_offsets.MODE - row_width/2
        local adjustment = self.icon_sizes.list[1]*2/3
		-- Mode
		row.MODE = row:AddChild(Image("images/filter_icons.xml", "orig_forge.tex"))
		row.MODE:SetPosition(current_icon_x_pos, y_offset_top)
		row.MODE:ScaleToSize(self.icon_sizes.list, nil, true)

        -- Difficulty
        current_icon_x_pos = current_icon_x_pos + adjustment
        row.DIFFICULTY = row:AddChild(Image("images/filter_icons.xml", "orig_forge.tex"))
        row.DIFFICULTY:SetPosition(current_icon_x_pos, y_offset_top)
        row.DIFFICULTY:ScaleToSize(self.icon_sizes.list, nil, true)

        -- Gametype
        current_icon_x_pos = current_icon_x_pos + adjustment
        row.GAMETYPE = row:AddChild(Image("images/filter_icons.xml", "orig_forge.tex"))
        row.GAMETYPE:SetPosition(current_icon_x_pos, y_offset_top)
        row.GAMETYPE:ScaleToSize(self.icon_sizes.list, nil, true)

        -- Waveset
        current_icon_x_pos = current_icon_x_pos + adjustment
        row.WAVESET = row:AddChild(Image("images/filter_icons.xml", "orig_forge.tex"))
        row.WAVESET:SetPosition(current_icon_x_pos, y_offset_top)
        row.WAVESET:ScaleToSize(self.icon_sizes.list, nil, true)

		-- Date
		row.DATE = row:AddChild(Text(CHATFONT, font_size))
        row.DATE:SetHAlign(ANCHOR_MIDDLE)
        row.DATE:SetString("")
        row.DATE._align = {
            maxwidth = 80,
            maxchars = 10,
            x = self.column_offsets.DATE - row_width/2,--self.column_offsets.DATE,
            y = y_offset_top,
        }
        row.DATE:SetPosition(row.DATE._align.x, row.DATE._align.y, 0)

        row.focus_forward = row.cursor

        return row
    end

    local function UpdateForgeRunsListWidget(context, widget, run, index)
		if not widget then return end

		-- If there are no runs hide everything
        if not run then
            widget.display_index = -1
            widget.SPAM:Hide()
            widget.COMMANDS:Hide()
            widget.INDEX:Hide()
			widget.OUTCOME:SetString("")
            widget.OUTCOME:SetPosition(widget.OUTCOME._align.x, widget.OUTCOME._align.y, 0)
			for i = 1, 6, 1 do -- TODO constant!!!
				widget.CHARACTERS[i]:Hide()
			end
			widget.TIME:SetString("")
            widget.TIME:SetPosition(widget.TIME._align.x, widget.TIME._align.y, 0)
			widget.MODE:Hide()
            widget.DIFFICULTY:Hide()
            widget.GAMETYPE:Hide()
            widget.WAVESET:Hide()
			widget.DATE:SetString("")
            widget.DATE:SetPosition(widget.DATE._align.x, widget.DATE._align.y, 0)
            widget.cursor:Hide()
            widget.cursor:Disable()
            widget:Disable()
        -- Add run to the list
		else
            widget:Enable()
            widget.cursor:Enable()

            widget.display_index = index
            --widget.unfiltered_index = serverdata.actualindex
			--[[
            if serverdata.actualindex == self.selected_index_actual then
                widget.cursor:Select()
            else
                widget.cursor:Unselect()
            end--]]
			widget.cursor:Show()

            -- Console Commands and Spamware
            local general_filters = self.filters[self.filter_keys.general]
            if run.scripts then
                local spam = general_filters.scripts_used
                widget.SPAM:SetTexture(spam.force_source or general_filters.options.source, spam.icon)
                widget.SPAM:ScaleToSize(self.icon_sizes.list, nil, true)
                widget.SPAM:SetHoverText(spam.str)
                widget.SPAM:Show()
            else
                widget.SPAM:Hide()
            end
            if run.commands then
                local commands = general_filters.commands_used
                widget.COMMANDS:SetTexture(commands.force_source or general_filters.options.source, commands.icon)
                widget.COMMANDS:ScaleToSize(self.icon_sizes.list, nil, true)
                widget.COMMANDS:SetHoverText(commands.str)
                widget.COMMANDS:Show()
            else
                widget.COMMANDS:Hide()
            end

			-- Index
            widget.INDEX:SetTruncatedString(tostring(index), widget.INDEX._align.maxwidth, widget.INDEX._align.maxchars, true)
            local w, h = widget.INDEX:GetRegionSize()
            widget.INDEX:SetPosition(widget.INDEX._align.x - w * .5 + self.max_column_widths.INDEX, widget.INDEX._align.y, 0)
			widget.INDEX:Show()

			-- Outcome
			widget.OUTCOME:SetTruncatedString(run.won and STRINGS.UI.WXP_DETAILS.WIN or STRINGS.UI.WXPLOBBYPANEL.LAVAARENA.TITLE_DEFEAT, widget.OUTCOME._align.maxwidth, widget.OUTCOME._align.maxchars, true)
			widget.OUTCOME:SetColour(run.won and WEBCOLOURS.SPRINGGREEN or UICOLOURS.RED)
			local w, h = widget.OUTCOME:GetRegionSize()
			widget.OUTCOME:SetPosition(widget.OUTCOME._align.x + w * .5, widget.OUTCOME._align.y, 0)

			-- TODO if more than 6 players display ... icon or string after the players
			-- TODO have arrows next to player heads (not on the scroll list) to shift the player heads by one
			-- Characters
			if run.players_stats then
				local player_count = 1
				for i,stats in pairs(run.players_stats) do
					if i < 7 then -- TODO quick fix...find another way
						local user_character = stats.character
                        local modded_character_info = TUNING.FORGE.CHARACTER_ICON_INFO[user_character]
						widget.CHARACTERS[i]:SetTexture(modded_character_info and modded_character_info.atlas or "images/avatars_resize.xml", modded_character_info and modded_character_info.tex or ((not modded_character_info and user_character or "unknown") .. ".tex")) -- TODO use forge faces? use field link table
						widget.CHARACTERS[i]:SetPosition(self.column_offsets.CHARACTERS + (i-1)*self.icon_sizes.list[1] - row_width/2, 0)
						widget.CHARACTERS[i]:ScaleToSize(self.icon_sizes.list, nil, true)
						widget.CHARACTERS[i]:Show()
						widget.CHARACTERS[i]:SetHoverText(
						tostring((stats.userid == TheNet:GetUserID() and TheNet:GetLocalUserName() or stats.name)),
						{
							font = NEWFONT_OUTLINE,
							offset_x = 10,
							offset_y = -28
						})
						player_count = player_count + 1
					end
				end
				-- Hide extra character icons
				for i=player_count, 6, 1 do -- TODO 6 is max players constant!!!
					widget.CHARACTERS[i]:Hide()
				end
			else
				Debug:Print("Characters not found for run " .. tostring(index) .. " and will not display any characters for this run.", "warning")
			end

			-- Time
			widget.TIME:SetTruncatedString(ConvertTotalSecondsToTime(tonumber(run.time) or 0), widget.TIME._align.maxwidth, widget.TIME._align.maxchars, true)
			local w, h = widget.TIME:GetRegionSize()
			widget.TIME:SetPosition(widget.TIME._align.x, widget.TIME._align.y, 0)

			-- Mode
			--[[REFORGED_DATA.modes) do
		mode_filters[mode] = {is_on = true, str = STRINGS.REFORGED.MODES[mode] or "TEST", force_source = data.icon.atlas, icon = data.icon.tex}--]]
            local mode_filter = self.filters[self.filter_keys.modes]
			widget.MODE:SetTexture(mode_filter[run.mode].force_source or mode_filter.options.source, mode_filter[run.mode].icon)
			widget.MODE:ScaleToSize(self.icon_sizes.list, nil, true)
			widget.MODE:SetHoverText(mode_filter[run.mode].str)
			widget.MODE:Show()

            -- Difficulty
            local difficulty_filter = self.filters[self.filter_keys.difficulties]
            widget.DIFFICULTY:SetTexture(difficulty_filter[run.difficulty].force_source or difficulty_filter.options.source, difficulty_filter[run.difficulty].icon)
            widget.DIFFICULTY:ScaleToSize(self.icon_sizes.list, nil, true)
            widget.DIFFICULTY:SetHoverText(difficulty_filter[run.difficulty].str)
            widget.DIFFICULTY:Show()

            -- Gametype
            local gametype_filter = self.filters[self.filter_keys.gametypes]
            widget.GAMETYPE:SetTexture(gametype_filter[run.gametype].force_source or gametype_filter.options.source, gametype_filter[run.gametype].icon)
            widget.GAMETYPE:ScaleToSize(self.icon_sizes.list, nil, true)
            widget.GAMETYPE:SetHoverText(gametype_filter[run.gametype].str)
            widget.GAMETYPE:Show()

            -- Waveset
            local waveset_filter = self.filters[self.filter_keys.wavesets]
            if waveset_filter[run.waveset] then
                widget.WAVESET:SetTexture(waveset_filter[run.waveset].force_source or waveset_filter.options.source, waveset_filter[run.waveset].icon)
                widget.WAVESET:ScaleToSize(self.icon_sizes.list, nil, true)
                widget.WAVESET:SetHoverText(waveset_filter[run.waveset].str)
                widget.WAVESET:Show()
            end

			-- Date
			local date_time_str = ParseString(run.date_time, " ")
			widget.DATE:SetTruncatedString(date_time_str[1], widget.DATE._align.maxwidth, widget.DATE._align.maxchars, true)
			local w, h = widget.DATE:GetRegionSize()
			widget.DATE:SetPosition(widget.DATE._align.x, widget.DATE._align.y, 0)
			--Debug:Print("Forge Run not found at index " .. tostring(index) .. " and will not display anything on this row.", "warning")
        end
    end

	self.forge_runs_list_rows = self:AddChild(Widget("forge_runs_list_rows"))

    local forge_runs_list = TEMPLATES.ScrollingGrid(
        self.current_forge_runs or {},
        {
            context = {},
            widget_width  = row_width, --dialog_width* 1.6,
            widget_height = row_height,
            num_visible_rows = 5,
            num_columns      = 1,
            item_ctor_fn = ScrollWidgetsCtor,
            apply_fn     = UpdateForgeRunsListWidget,
            scrollbar_offset = 20,
            scrollbar_height_offset = -60,
        })

	-- TODO figure out what this does, does it just move to first index?
	self.forge_runs_list_rows:MoveToFront()

	forge_runs_list.up_button:SetTextures("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_arrow_hover.tex")
    forge_runs_list.up_button:SetScale(0.5)

	forge_runs_list.down_button:SetTextures("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_arrow_hover.tex")
    forge_runs_list.down_button:SetScale(-0.5)

	forge_runs_list.scroll_bar_line:SetTexture("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_bar.tex")
	forge_runs_list.scroll_bar_line:SetScale(.3)

	forge_runs_list.position_marker:SetTextures("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_handle.tex")
	forge_runs_list.position_marker.image:SetTexture("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_handle.tex")
    forge_runs_list.position_marker:SetScale(.6)

    return forge_runs_list
end

--
function ServerLeaderboardPanel:OnStartClickRunInList(index)
	self.current_index = index
	self.spinners[1]:SetSelected(self.current_index)
	self:UpdateCurrentRunStats(self.current_forge_runs[self.current_index])
	self:RefreshForgeRunDisplay()
end

--
function ServerLeaderboardPanel:OnFinishClickRunInList(index)

end

return ServerLeaderboardPanel
