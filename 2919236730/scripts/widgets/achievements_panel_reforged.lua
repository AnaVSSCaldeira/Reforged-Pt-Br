--[[
TODO
Achievement Icon
    Top left of icon is the mod icon
Achievement Name
    to the right of the icon
Progress
    Below Name
Completion Date
    Goes where progress is and progress is hidden.
Description
    Goes below icon and name
Reward?
    currently only exp
Requirements
    icons of requirements
    how to show mutators off?
--]]
local Text = require "widgets/text"
local AchievementFrame = require "widgets/achievement_frame"
local Widget = require "widgets/widget"
local TEMPLATES = require "widgets/redux/templates"

local AchievementsPanel = Class(Widget, function(self)
    ------------------ NO TOUCHY ------------------
    Widget._ctor(self, "AchievementsPanel")

    self.current_achievement = "" -- TODO use this instead?
    self.selected_achievement_index = 1
    self.current_achievements = {}
    self.current_unlocked_achievements = 0

    local panel_root = self
    -----------
    self.top_root = self:AddChild(Widget("top_root"))
    self.top_root:SetPosition(0, 100)
    self.top_root:SetScale(.66)

    self.bottom_root = self:AddChild(Widget("bottom_root"))
    self.bottom_root:SetScale(.66)

    self.achievement_display = self:AddChild( self:BuildAchievementDisplay() )
    self.achievement_display:SetPosition(-200, 0)
    --self.achievement_display:SetScale(.66)

    -- Place between these 2 widgets
    --[[local line_break = self:AddChild(Image("images/lavaarena_unlocks.xml", "divider.tex"))
    local line_break_width, line_break_height = line_break:GetSize()
    line_break:SetPosition(0, -line_break_height/2)
    line_break:SetScale(.68)--]]

    -- Make BuildForgeRunsList method
    -- TODO put with bottom widget? that way you can move them as a group at once?
    self.achievements_list_menu = self.bottom_root:AddChild( self:BuildAchievementListMenu() )
    self.achievements_list_menu:SetPosition(325, 0)

    self.parent_default_focus = self

    self:ApplyFilters()
    -- Set the initial display
    local achievement_widgets = self.achievements_list:GetListWidgets()
    if achievement_widgets and achievement_widgets[1] then
        achievement_widgets[1].onclick()
    end
end)

--[[------------------------------
        Achievement Display
---------------------------------]]
-- Displays achievement icon, mod (source) icon, name, progress/date completed, and description
function AchievementsPanel:BuildAchievementDisplay()
    local outcome_root = Widget("outcome_root")

    local y_spacing = 35
    local current_y = 175
    -- Title/Name
    self.title_bg = outcome_root:AddChild(Image("images/rf_panel_assets.xml", "bg_title_1.tex"))
    self.title_bg:SetPosition(50, current_y)
    self.title_bg:SetSize(240,50)
    self.title = outcome_root:AddChild(Text(HEADERFONT, 25, "", UICOLOURS.BROWN_DARK))
    self.title:SetPosition(50,current_y - 5)
    --self.description:SetHAlign(ANCHOR_LEFT)

    current_y = current_y - y_spacing
    -- Progress or Date/Time Completion text
    self.progress = outcome_root:AddChild(Text(HEADERFONT, 18, "", UICOLOURS.BROWN_DARK))
    self.progress:SetPosition(50,current_y)
	
	self.progress_status = outcome_root:AddChild(TEMPLATES.LargeScissorProgressBar())
    self.progress_status:SetPosition(50,current_y-25)
    self.progress_status:SetScale(0.38, 0.6)

    current_y = current_y - y_spacing/2
    -- Reward text
    self.reward = outcome_root:AddChild(Text(HEADERFONT, 14, "", UICOLOURS.BROWN_DARK))
    self.reward:SetPosition(-110,205)

    -- Description
    local description_bg = outcome_root:AddChild(Image("images/rf_panel_assets.xml", "desc_box_big.tex"))
    description_bg:SetSize(400,200)
    --description_bg:SetPosition(-200,0)
    self.description = outcome_root:AddChild(Text(HEADERFONT, 21, "", UICOLOURS.BROWN_DARK))
    self.description:SetHAlign(ANCHOR_LEFT)

    --[[
    TODO
        need characters
    --]]

    -- Requirements
	--local requirements_bg = outcome_root:AddChild(Image("images/lavaarena_unlocks.xml", "box1.tex"))
	local requirements_bg = outcome_root:AddChild(Image("images/rf_panel_assets.xml", "bg_title_1.tex"))
    requirements_bg:SetSize(360,50)
	requirements_bg:SetPosition(0, -115)
	
    self.requirements_text = outcome_root:AddChild(Text(HEADERFONT, 14, STRINGS.REFORGED.ACHIEVEMENTS.REQUIREMENTS, UICOLOURS.BROWN_DARK))
    self.requirements_text:SetPosition(-120,-90)
    self.requirements = self.requirements_text:AddChild(Widget())
    self.requirements.icons = {}
	local reqicon_xpos = -40
    self.requirements.UpdateRequirements = function(inst, req)
        local characters = {wilson = true, willow = true, wolfgang = true, wendy = true, wx78 = true, wickerbottom = true, woodie = true, wes = true, waxwell = true, wathgrithr = true, webber = true, winona = true, wortox = true, warly = true, wormwood = true, wurt = true, walter = true, wanda = true}
        local function AddIcon(count, icon_info, hover_text)
            local icon_size = 30
            local spacing = 2
            local icon = inst.icons[count]
            if not icon then
                icon = inst:AddChild(Image())
            end
            icon:SetPosition(reqicon_xpos + ((count - 1) * (icon_size + spacing)), -27)
            icon:SetTexture(icon_info.atlas, icon_info.tex)
            icon:ScaleToSize(icon_size, icon_size, true)
            icon:SetHoverText(hover_text)
            icon:Show()
            inst.icons[count] = icon
        end
        local count = 1
        for category,settings in pairs(req or {}) do
            if category == "player_count" then
                AddIcon(count, {atlas = "images/reforged.xml", tex = "playercountmulti.tex"}, string.format(STRINGS.REFORGED.ACHIEVEMENTS.PLAYER_COUNT, settings))
                count = count + 1
            else
                for i,setting in pairs(settings) do
                    local current_setting = category == "mutators" and i or setting
                    local icon = category == "characters" and {atlas = "images/avatars_resize.xml", tex = (characters[current_setting] and tostring(current_setting) or "unknown") .. ".tex"} or REFORGED_DATA[category][current_setting].icon
                    local hover_text = (category == "characters" and (STRINGS.CHARACTER_NAMES[current_setting] or STRINGS.REFORGED.unknown)) or (category == "presets" and STRINGS.REFORGED[string.upper(category)][current_setting] or STRINGS.REFORGED[string.upper(category)][current_setting].name) .. (category == "mutators" and type(current_setting) ~= "boolean" and (": " .. tostring(setting)) or "")
                    AddIcon(count, icon, hover_text)
                    count = count + 1
                end
            end
        end
        for i=count,#inst.icons do
            inst.icons[i]:Hide()
        end
    end
    self.requirements:SetPosition(0,0)

    -- Completion Status
	local completion_bg = outcome_root:AddChild(Image("images/rf_panel_assets.xml", "bg_content_box.tex"))
    completion_bg:SetSize(400,80)
	completion_bg:SetPosition(0,-180)
	
    self.completion_text = outcome_root:AddChild(Text(HEADERFONT, 25, string.format(STRINGS.REFORGED.ACHIEVEMENTS.COMPLETION, self.current_unlocked_achievements, #self.current_achievements), UICOLOURS.BROWN_DARK))
    self.completion_text:SetPosition(0,-175)

    self.completion_status = outcome_root:AddChild(TEMPLATES.LargeScissorProgressBar())
    self.completion_status:SetPosition(0,-200)
    self.completion_status:SetScale(0.6)
    self.completion_status:SetPercent(self.current_unlocked_achievements/#self.current_achievements)	
	
	-- Achievement Icon
    self.achievement_icon = outcome_root:AddChild(AchievementFrame())
    self.achievement_icon:SetPosition(-125, 145)
    self.achievement_icon:SetScale(0.8)
    self.achievement_icon:SetClickable(false)
    --self.achievement_icon:SetInteractionState(false)
    --self.achievement_icon:SetSize(self.icon_sizes.list)

    return outcome_root
end

function AchievementsPanel:RefreshAchievementDisplay()
    local achievement_info = self.current_achievements_name_key[self.current_achievement]
    if achievement_info then
        self.achievement_icon:SetAchievement(achievement_info.name, achievement_info.unlocked, true)
        --self.achievement_icon:ApplyDataToWidget({}, achievement_info, self.selected_achievement_index)

        local achievement_data = REFORGED_DATA.achievements[achievement_info.name]

        local string_info = STRINGS.REFORGED.ACHIEVEMENTS[achievement_info.name] or {}
        self.title:SetMultilineTruncatedString(string_info.TITLE or STRINGS.REFORGED.unknown, 1, 225, nil, nil, true)

        local max_progress = achievement_data.max_progress
        local date_completion_string = achievement_info.date and (achievement_info.date .. " " .. (achievement_info.time or ""))
        local progress_string = max_progress and string.format(STRINGS.REFORGED.ACHIEVEMENTS.PROGRESS, achievement_info.progress or 0, max_progress) or "" -- TODO date string
        self.progress:SetString(date_completion_string or progress_string)
		if achievement_info.unlocked then
			self.progress_status:SetPercent(1/1)	
		else
			self.progress_status:SetPercent((achievement_info.progress or 0)/(max_progress or 1))	
		end

        self.reward:SetString(string.format(STRINGS.REFORGED.ACHIEVEMENTS.REWARD, achievement_data.exp))

        self.description:SetMultilineTruncatedString(string_info.DESCRIPTION, 20, 350)
        local desc_w, desc_h = self.description:GetRegionSize()
        self.description:SetPosition(-165 + 0.5 * desc_w, 80 - 0.5 * desc_h)

        self.requirements:UpdateRequirements(achievement_data.requirements)
    end
end

--[[------------------------------
        Achievements List Menu
---------------------------------]]
function AchievementsPanel:BuildAchievementListMenu()
    local menu_root = Widget("menu_root")

    local border_buffer = 20

    --[[local bg = menu_root:AddChild(Image("images/lavaarena_unlocks.xml", "box1.tex"))
    bg:SetScale(1, 1.3)
    local bg_width, bg_height = bg:GetSize()
    bg:SetPosition(0, 0)--]]

    local x = 0
    local y = -50
    local achievements_list_bg = menu_root:AddChild(Image("images/rf_panel_assets.xml", "list_box_big.tex"))
    achievements_list_bg:SetSize(565,650)
    achievements_list_bg:SetPosition(x, y)
    self.achievements_list = menu_root:AddChild( self:BuildAchievementsList() )
    self.achievements_list:SetPosition(x, y)
    --[[local list_scale = 1.3
    self.achievements_list:SetScale(list_scale)
    self.achievements_list.empty_list = self.achievements_list:AddChild( Text(HEADERFONT, 40, STRINGS.UI.FORGEHISTORYPANEL.RUN.EMPTY_LIST, UICOLOURS.BROWN_DARK) )
    local grid_w, grid_h = self.achievements_list:GetScrollRegionSize()
    self.achievements_list:SetPosition(-bg_width/2 + grid_w/2*list_scale + border_buffer, 0)
    self.achievements_list.empty_list:Hide()--]]

    self.filters_root = menu_root:AddChild(self:BuildFilterPanel())
    self.filters_root:SetPosition(0, 400)

    return menu_root
end

--[[------------------------------
            FILTERS
---------------------------------]]
-- Change index of current meal and update display
function AchievementsPanel:ApplyFilters()
    self:ScanAchievements()
    self:UpdateAchievementsList()
    self:RefreshAchievementDisplay()
    --self:_DoFocusHookups() -- what did I use this for??? TODO
end

local function CheckFilter(current_filter, requirements)
    if current_filter == "any"then
        return true
    elseif requirements == nil or #requirements <= 0 then
        return false
    end
    for _,requirement in pairs(requirements) do
        if current_filter == requirement then
            return true
        end
    end
    return false
end

function AchievementsPanel:ScanAchievements()
    if TheWorld.net.replica.achievementmanager == nil then
        Debug:Print("client does not have \"achievementmanager\" replica! Achievement data will be unable to display properly.", "warning")
    end
    self.current_achievements = {}
    self.current_achievements_name_key = {}
    self.current_unlocked_achievements = 0
    for name,info in pairs(REFORGED_DATA.achievements or {}) do -- TODO check filters AND saved achievements
        local filters = info.filters or {}
        local requirements = info.requirements
        local users_achievement_info = TheWorld.net.replica.achievementmanager and TheWorld.net.replica.achievementmanager:GetUsersAchievement(name, REFORGED_SETTINGS.display.server_achievements) or {}
        if CheckFilter(self.mod_filter:GetCurrentMode(), {info.mod}) and CheckFilter(self.character_filter:GetCurrentMode(), requirements.characters) and CheckFilter(self.waveset_filter:GetCurrentMode(), requirements.wavesets) and CheckFilter(self.gametype_filter:GetCurrentMode(), requirements.gametypes) and CheckFilter(self.mode_filter:GetCurrentMode(), requirements.modes) and CheckFilter(self.difficulty_filter:GetCurrentMode(), requirements.difficulties) and CheckFilter(self.unlocked_filter:GetCurrentMode(), {users_achievement_info.unlocked and "unlocked" or "locked"}) then
            table.insert(self.current_achievements, {name = name, tier = info.tier, unlocked = users_achievement_info.unlocked, progress = users_achievement_info.progress, date = users_achievement_info.date, time = users_achievement_info.time, id = info.id})
            self.current_achievements_name_key[name] = self.current_achievements[#self.current_achievements]
            if users_achievement_info.unlocked then
                self.current_unlocked_achievements = self.current_unlocked_achievements + 1
            end
        end
    end
    if self.completion_status then
        self.completion_text:SetString(string.format(STRINGS.REFORGED.ACHIEVEMENTS.COMPLETION, self.current_unlocked_achievements, #self.current_achievements))
        self.completion_status:SetPercent(self.current_unlocked_achievements/#self.current_achievements)
    end
    if self.sorter then
        self.sorter.onclick(true)
    end
end

function AchievementsPanel:UpdateAchievementsList()
    if self.current_achievements and #self.current_achievements > 0 then
        self.achievements_list:SetItemsData(self.current_achievements)
        --self.achievements_list.empty_list:Hide()
    else
        self.achievements_list:SetItemsData()
        --self.achievements_list.empty_list:Show()
    end
end

function AchievementsPanel:BuildFilterPanel()
    local root = Widget("filter_root")
    root:SetScale(1.5)

    local function SortByName(a,b)
        local string_a = STRINGS.REFORGED.ACHIEVEMENTS[a.name] and STRINGS.REFORGED.ACHIEVEMENTS[a.name].TITLE or STRINGS.REFORGED.unknown
        local string_b = STRINGS.REFORGED.ACHIEVEMENTS[b.name] and STRINGS.REFORGED.ACHIEVEMENTS[b.name].TITLE or STRINGS.REFORGED.unknown
        return string_a < string_b and 0 or string_a == string_b and 1 or 2
    end
    local function SortByRarity(a,b, descending)
        local num_a = tonumber(a.tier)
        local num_b = tonumber(b.tier)
        return (descending and num_a < num_b or not descending and num_a > num_b) and 0 or num_a == num_b and 1 or 2
    end
    local function SortByID(a,b)
        return a.id > b.id and 0 or a.id == b.id and 1 or 2
    end
    local function CompareDateTime(a, b, a_date_time, b_date_time, current_index)
        local current_index = current_index or 1
        if current_index > #a_date_time or current_index > #b_date_time then
            local sort_val = SortByRarity(a,b)
            if sort_val == 1 then
                sort_val = SortByName(a,b)
            end
            return sort_val == 0
        else
            return a_date_time[current_index] > b_date_time[current_index] or a_date_time[current_index] == b_date_time[current_index] and CompareDateTime(a, b, a_date_time, b_date_time, current_index + 1)
        end
    end
    local function OnSortingFilter(filter)
        local function ConvertStringListToNum(strings)
            local numbers = {}
            for i,j in pairs(strings) do
                numbers[i] = tonumber(j)
            end

            return numbers
        end
        local sort_fns = {
            id = function(a,b)
                local sort_val = SortByID(a,b)
                if sort_val == 1 then
                    sort_val = SortByRarity(a,b, true)
                    if sort_val == 1 then
                        sort_val = SortByName(a,b)
                    end
                end
                return sort_val == 0
            end,
            name = function(a,b)
                local sort_val = SortByName(a,b)
                if sort_val == 1 then
                    sort_val = SortByRarity(a,b)
                end
                return sort_val == 0
            end,
            rarity = function(a,b)
                local sort_val = SortByRarity(a,b)
                if sort_val == 1 then
                    sort_val = SortByName(a,b)
                end
                return sort_val == 0
            end,
            most_recent = function(a,b)
                local a_date = a and a.date and ConvertStringListToNum(ParseString(a.date, "/")) or {}
                local a_time = a and a.time and ConvertStringListToNum(ParseString(a.time, ":")) or {}
                local a_date_time = {a_date[3], a_date[1], a_date[2]}
                TableConcat(a_date_time,a_time)
                local b_date = b and b.date and ConvertStringListToNum(ParseString(b.date, "/")) or {}
                local b_time = b and b.time and ConvertStringListToNum(ParseString(b.time, ":")) or {}
                local b_date_time = {b_date[3], b_date[1], b_date[2]}
                TableConcat(b_date_time,b_time)
                local test = #a_date_time == #b_date_time and CompareDateTime(a, b, a_date_time, b_date_time) or #a_date_time ~= #b_date_time and #a_date_time == 6
                return test
            end,
        }
        self.current_sorting_filter = filter
        table.sort(self.current_achievements, sort_fns[filter])
        self:UpdateAchievementsList()
        self:RefreshAchievementDisplay()
    end

    local function MakeButton(modes, hover_text, onclick_fn)
        local btn = root:AddChild(TEMPLATES.IconButton(modes[1].icon.atlas, modes[1].icon.tex))
        btn.icon:SetScale(1)
        btn.icon:ScaleToSize(50, 50, true)
        btn:SetScale(0.68)
        btn.mode = 1
        btn.modes = modes
        btn:SetHoverText(subfmt(hover_text, {mode = btn.modes[btn.mode].hover_text}))
        btn.SetSortType = function(_,sort_mode)
        end
        btn.GetCurrentMode = function()
            return btn.modes[btn.mode].name
        end
        local function onclick(no_update)
            if not no_update then
                btn.mode = btn.mode % #btn.modes + 1
                local current_mode = btn.modes[btn.mode]
                btn:SetHoverText(subfmt(hover_text, {mode = current_mode.hover_text})) -- TODO modes should contain strings?
                local icon = current_mode.icon
                btn.icon:SetTexture(icon.atlas, icon.tex)
                btn.icon:ScaleToSize(50, 50, true)
            end
            if onclick_fn then
                onclick_fn(btn)
            else
                self:ApplyFilters()
            end
        end
        btn:SetOnClick(onclick)
        return btn
    end

    local sorter_modes = {
        [1] = {
            name       = "id",
            icon       = {atlas = "images/reforged.xml", tex = "filter_id.tex"},
            hover_text = STRINGS.REFORGED.ACHIEVEMENTS.SORT_ID,
        },
        [2] = {
            name       = "name",
            icon       = {atlas = "images/button_icons.xml", tex = "sort_name.tex"},
            hover_text = STRINGS.UI.WARDROBESCREEN.SORT_NAME,
        },
        [3] = {
            name       = "rarity",
            icon       = {atlas = "images/button_icons.xml", tex = "sort_rarity.tex"},
            hover_text = STRINGS.UI.WARDROBESCREEN.SORT_RARITY,
        },
        [4] = {
            name       = "most_recent",
            icon       = {atlas = "images/button_icons.xml", tex = "sort_release.tex"},
            hover_text = STRINGS.REFORGED.ACHIEVEMENTS.DATE_UNLOCKED, -- TODO different string?
        },
    }
    local x_spacing = 46
    local x_offset = -160
    local y_offset = -65
    self.sorter = MakeButton(sorter_modes, STRINGS.UI.WARDROBESCREEN.SORT_MODE_FMT, function() OnSortingFilter(self.sorter:GetCurrentMode()) end)
    self.sorter:SetPosition(x_offset, y_offset)
    x_offset = x_offset + x_spacing
    local mod_filters = {}
    local character_filters = {}
    local waveset_filters = {}
    local gametype_filters = {}
    local mode_filters = {}
    local difficulty_filters = {}
    for name,info in pairs(REFORGED_DATA.achievements) do
        local requirements = info.requirements
        if info.mod then
            mod_filters[info.mod] = true
        end
        for _,character in pairs(requirements.characters) do
            character_filters[character] = true
        end
        for _,gametype in pairs(requirements.gametypes) do
            gametype_filters[gametype] = true
        end
        for _,mode in pairs(requirements.modes) do
            mode_filters[mode] = true
        end
        for _,difficulty in pairs(requirements.difficulties) do
            difficulty_filters[difficulty] = true
        end
        for _,waveset in pairs(requirements.wavesets) do
            waveset_filters[waveset] = true
        end
    end
    local function CreateOpts(filters, opts, type, atlas_override, string_tbl_override, icon_override)
        for filter,_ in pairs(filters) do
            table.insert(opts, {name = filter, icon = icon_override and icon_override[filter] or REFORGED_DATA[type] and REFORGED_DATA[type][filter] and REFORGED_DATA[type][filter].icon or {atlas = atlas_override, tex = tostring(filter) .. ".tex"}, hover_text = string_tbl_override and string_tbl_override[filter] or type and STRINGS.REFORGED[string.upper(type)] and STRINGS.REFORGED[string.upper(type)][filter] and STRINGS.REFORGED[string.upper(type)][filter].name or STRINGS.REFORGED.unknown})
        end
    end
    ----------------
    -- Mod Filter --
    ----------------
    local mod_opts = {
        [1] = {
            name       = "any",
            icon       = {atlas = "images/reforged.xml", tex = "filter_any.tex"},
            hover_text = STRINGS.UI.INTENTION.ANY,
        },
    }
    --[[for name,icon in pairs(TUNING.FORGE.MOD_ICONS) do
        table.insert(mod_opts, {
            name = name,
            icon = icon,
            hover_text = STRINGS.REFORGED.MODS[name],
        })
    end--]]
    CreateOpts(mod_filters, mod_opts, nil, "images/avatars_resize.xml", STRINGS.REFORGED.MODS, TUNING.FORGE.MOD_ICONS)
    self.mod_filter = MakeButton(mod_opts, STRINGS.REFORGED.ACHIEVEMENTS.MODS_FILTER)
    self.mod_filter:SetPosition(x_offset, y_offset)
    x_offset = x_offset + x_spacing
    ---------------------
    -- Unlocked Filter --
    ---------------------
    local unlocked_opts = {
        [1] = {
            name       = "any",
            icon       = {atlas = "images/reforged.xml", tex = "filter_any.tex"},
            hover_text = STRINGS.UI.INTENTION.ANY,
        },
        [2] = {
            name       = "unlocked",
            icon       = {atlas = "images/button_icons.xml", tex = "owned_filter_on.tex"},
            hover_text = STRINGS.REFORGED.ACHIEVEMENTS.UNLOCKED,
        },
        [3] = {
            name       = "locked",
            icon       = {atlas = "images/button_icons.xml", tex = "owned_filter_off.tex"},
            hover_text = STRINGS.REFORGED.ACHIEVEMENTS.LOCKED,
        },
    }
    self.unlocked_filter = MakeButton(unlocked_opts, STRINGS.REFORGED.ACHIEVEMENTS.UNLOCKED_FILTER)
    self.unlocked_filter:SetPosition(x_offset, y_offset)
    x_offset = x_offset + x_spacing
    ----------------------
    -- Character Filter --
    ----------------------
    local character_opts = {
        [1] = {
            name       = "any",
            icon       = {atlas = "images/reforged.xml", tex = "filter_any.tex"},
            hover_text = STRINGS.UI.INTENTION.ANY,
        },
    }
    CreateOpts(character_filters, character_opts, nil, "images/avatars_resize.xml", STRINGS.CHARACTER_NAMES)
    self.character_filter = MakeButton(character_opts, STRINGS.REFORGED.ACHIEVEMENTS.CHARACTERS_FILTER, nil, true)
    self.character_filter:SetPosition(x_offset, y_offset)
    x_offset = x_offset + x_spacing
    ---------------------
    -- Waveset Filter --
    ---------------------
    local waveset_opts = {
        [1] = {
            name       = "any",
            icon       = {atlas = "images/reforged.xml", tex = "filter_any.tex"},
            hover_text = STRINGS.UI.INTENTION.ANY,
        },
    }
    CreateOpts(waveset_filters, waveset_opts, "wavesets")
    self.waveset_filter = MakeButton(waveset_opts, STRINGS.REFORGED.ACHIEVEMENTS.WAVESETS_FILTER)
    self.waveset_filter:SetPosition(x_offset, y_offset)
    x_offset = x_offset + x_spacing
    ---------------------
    -- Gametype Filter --
    ---------------------
    local gametype_opts = {
        [1] = {
            name       = "any",
            icon       = {atlas = "images/reforged.xml", tex = "filter_any.tex"},
            hover_text = STRINGS.UI.INTENTION.ANY,
        },
    }
    CreateOpts(gametype_filters, gametype_opts, "gametypes")
    self.gametype_filter = MakeButton(gametype_opts, STRINGS.REFORGED.ACHIEVEMENTS.GAMETYPES_FILTER)
    self.gametype_filter:SetPosition(x_offset, y_offset)
    x_offset = x_offset + x_spacing
    -----------------
    -- Mode Filter --
    -----------------
    local mode_opts = {
        [1] = {
            name       = "any",
            icon       = {atlas = "images/reforged.xml", tex = "filter_any.tex"},
            hover_text = STRINGS.UI.INTENTION.ANY,
        },
    }
    CreateOpts(mode_filters, mode_opts, "modes")
    self.mode_filter = MakeButton(mode_opts, STRINGS.REFORGED.ACHIEVEMENTS.MODES_FILTER)
    self.mode_filter:SetPosition(x_offset, y_offset)
    x_offset = x_offset + x_spacing
    -----------------------
    -- Difficulty Filter --
    -----------------------
    local difficulty_opts = {
        [1] = {
            name       = "any",
            icon       = {atlas = "images/reforged.xml", tex = "filter_any.tex"},
            hover_text = STRINGS.UI.INTENTION.ANY,
        },
    }
    CreateOpts(difficulty_filters, difficulty_opts, "difficulties")
    self.difficulty_filter = MakeButton(difficulty_opts, STRINGS.REFORGED.ACHIEVEMENTS.DIFFICUTLIES_FILTER)
    self.difficulty_filter:SetPosition(x_offset, y_offset)
    x_offset = x_offset + x_spacing

    -- Sort the list initially
    self:UpdateAchievementsList()

    return root
end
--[[------------------------------
            Achievements
---------------------------------]]
-- Creates a scrolling list of achievements
function AchievementsPanel:BuildAchievementsList()
    local spacing = 5
    local width = 100
    local height = 100

    local function InitializeAchievementWidget(context, index)
        local achievement_widget = AchievementFrame()
        achievement_widget.data = {}
        achievement_widget.scroll_index = index

        local x = width - spacing
        local y = height - spacing

        achievement_widget:ScaleToSize(x,y)
        achievement_widget.ongainfocusfn = function()
            self.achievements_list:OnWidgetFocus(achievement_widget)
        end
        achievement_widget:SetOnClick(function()
            local name = achievement_widget.data.name
            if name and not self.current_achievements_name_key[name].is_active then
                if self.current_achievements_name_key[self.current_achievement] then
                    self.current_achievements_name_key[self.current_achievement].is_active = false
                end
                self.current_achievement = name
                self.current_achievements_name_key[self.current_achievement].is_active = true
                for _,widget in pairs(self.achievements_list:GetListWidgets()) do
                    widget:SetSelectionState(widget.data and widget.data.is_active)
                end
                self:RefreshAchievementDisplay()
            end
        end)

        return achievement_widget
    end

    local function UpdateAchievementListWidget(context, widget, achievement_data, index)
        if not widget then return end

        -- data will sometimes be nil!
        if achievement_data then
            widget.data = achievement_data
            widget:SetAchievement(achievement_data.name, achievement_data.unlocked)
            widget:SetClickable(true)
            if self.current_achievement == achievement_data.name then
                widget:SetSelectionState(true)
            else
                widget:SetSelectionState(false)
            end
        else
            widget.data = {}
            widget:SetBlank()
            widget:SetClickable(false)
        end

        if achievement_data then
            --widget:UpdateSelectionState()
        end
    end

    local achievements_list = TEMPLATES.ScrollingGrid(self.current_achievements or {},{
        context = {},
        widget_width  = width,
        widget_height = height,
        num_visible_rows = 5,
        num_columns      = 5,
        item_ctor_fn = InitializeAchievementWidget,
        apply_fn     = UpdateAchievementListWidget,
        scrollbar_offset = 20,
        --scrollbar_height_offset = -60,
        scissor_pad = width*0.18,
        peek_percent = 0.25,
    })

    achievements_list.up_button:SetTextures("images/plantregistry.xml", "plantregistry_recipe_scroll_arrow.tex")--"images/quagmire_recipebook.xml", "quagmire_recipe_scroll_arrow_hover.tex")
    achievements_list.up_button:SetScale(0.5)

    achievements_list.down_button:SetTextures("images/plantregistry.xml", "plantregistry_recipe_scroll_arrow.tex")--"images/quagmire_recipebook.xml", "quagmire_recipe_scroll_arrow_hover.tex")
    achievements_list.down_button:SetScale(-0.5)

    achievements_list.scroll_bar_line:SetTexture("images/plantregistry.xml", "plantregistry_recipe_scroll_bar.tex")--"images/quagmire_recipebook.xml", "quagmire_recipe_scroll_bar.tex")
    achievements_list.scroll_bar_line:SetScale(1.1)

    achievements_list.position_marker:SetTextures("images/plantregistry.xml", "plantregistry_recipe_scroll_handle.tex")--"images/quagmire_recipebook.xml", "quagmire_recipe_scroll_handle.tex")
    achievements_list.position_marker.image:SetTexture("images/plantregistry.xml", "plantregistry_recipe_scroll_handle.tex")--"images/quagmire_recipebook.xml", "quagmire_recipe_scroll_handle.tex")
    achievements_list.position_marker:SetScale(.6)

    return achievements_list
end

return AchievementsPanel
