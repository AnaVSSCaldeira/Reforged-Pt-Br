--[[
TODO
	Can this file be named util.lua or will that override kleis?
	Add all util functions that should be global here
--]]
----------------
-- Table Util --
----------------
-- Takes a table and key names ordered by depth and returns the value at the index.
-- Returns nil if any of the given keys for the table return nil
-- Optional:
--    Keys can be given in order of access to check further into the table.
function CheckTable(tab, ...)
	local keys = {...}
	while tab and #keys > 0 do
		tab = tab[table.remove(keys, 1)]
	end
	return tab
end

-- If the given table does not exist it sets it to an empty table
-- Returns the table of the last index given
-- Optional:
--    Keys can be given in order of access to check further into the table.
function EnsureTable(tab, ...)
    if not tab then tab = {} end
    local keys = {...}
	for i = 1, #keys do
		if not tab[keys[i]] then
			tab[keys[i]] = {}
		end
		tab = tab[keys[i]]
	end
    return tab
end

-- Appends the second table to the end of the first table
function TableConcat(t1,t2)
	for i=1,#t2 do
		t1[#t1+1] = t2[i]
	end
end

-- Appends the second table to the end of the first table without duplicating any values.
-- The first table is assumed to have no duplicate values.
-- If no val link is given then the first table will be used to generate one
function TableConcatNoDupeValues(t1,t2,val_link)
    local current_val_link = val_link or {}
    if val_link == nil then
        for i,val in pairs(t1) do
            current_val_link[val] = true
        end
    end
    for i,val in pairs(t2) do
        if not current_val_link[val] then
            table.insert(t1, val)
            current_val_link[val] = true
        end
    end
end

-- Merges 2 tables together, first table given is the base table and the other table will be merged to it.
-- The 2nd table will still exist and be unaffected.
-- Any table values that have a string version of nil: "nil" will set that option to nil. This is only checked in table 2 since it is being merged into table 1.
-- Optional:
-- "override_values" = false (default): Duplicate indices will be ignored.
-- "override_values" = true: will cause the second table to override any duplicate indices.
function MergeTable(tbl_1, tbl_2, override_values)
    for i,j in pairs(tbl_2) do
        if override_values or not tbl_1[i] then
            tbl_1[i] = j ~= "nil" and j
        end
    end
end

-- Checks to see if the table
function GetTableFromKeys(base, keys)
    local tbl = base
    for _,key in pairs(keys) do
        if base[key] then
            base = base[key]
        else
            return base
        end
    end
    return base
end

-- is_sorted - will assume the table is sorted by numbered keys.
function GetRandomValuesFromTable(tbl,amount,is_sorted)
    local random_values = {}
    local tbl_link = is_sorted and tbl or {}
    if not is_sorted then
        for key,val in pairs(tbl) do
            table.insert(tbl_link, key)
        end
    end
    for i=1,amount do
        if #tbl_link > 0 then
            local rand = math.random(1, #tbl_link)
            table.insert(random_values, is_sorted and tbl_link[rand] or tbl[tbl_link[rand]])
            table.remove(tbl_link, rand)
        else
            break
        end
    end
    return random_values
end

-- Checks if the given table path and function exist, then calls the functions and returns the result
function CheckFunction(fn_name, fn_params, tab, ...)
    local tab = CheckTable(tab, ...)
    if tab and tab[fn_name] then
        return tab[fn_name](tab, unpack(fn_params or {}))
    end
    return nil
end

-- string split function by parse
function ParseString(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    local i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            t[i] = str
            i = i + 1
    end
    return t
end

-- Returns a string representation of the given table. Useful for sending tables between servers and clients.
function SerializeTable(val, name, depth)
    depth = depth or 0
    local tmp = string.rep("", depth)

    if name then
        if type(name) == "number" then
            name = "\[" .. name .. "\]"
        else
            name = "\[\"" .. name .. "\"\]"
        end
        tmp = tmp .. name .. "="
    end

    if type(val) == "table" then
        tmp = tmp .. "{"
        for k,v in pairs(val) do
            tmp =  tmp .. SerializeTable(v, k, depth + 1) .. ","
        end
        tmp = tmp .. string.rep("", depth) .. "}"
    elseif type(val) == "number" or type(val) == "boolean" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    else
        tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
    end

    return tmp
end

local function ConvertStringToType(str)
    if not str then return end
    if str:sub(1,1) == "\"" then
        return str:sub(2, #str - 1)
    else
        local num = tonumber(str)
        if num then
            return num
        else
            return str == "true"
        end
    end
end

-- Quick, Rough first draft
function ConvertStringToTable(str, index)
    local tab = {}
    local key
    local val
    local current_str
    local function CheckForPair()
        val = ConvertStringToType(current_str)
        if key then
            --print("- " .. tostring(key) .. " = " .. tostring(val))
            tab[key] = val
            key = nil
            val = nil
        end
        current_str = nil
    end
    local i = index or 0
    --print("Starting conversion...")
    --print("- str: " .. tostring(str))
    --print("- index: " .. tostring(index))
    while i ~= nil and i < #str do
        i = i + 1
        local char = str:sub(i,i)
        if char == "{" then
            --print("- found '{'")
            local tbl, next_index = ConvertStringToTable(str, i)
            if key then
                --print("- " .. tostring(key) .. " = " .. tostring(val))
                tab[key] = tbl
                key = nil
            elseif tbl ~= nil then
                table.insert(tab, tbl)
            end
            i = next_index
        elseif char == "}" then
            --print("- found '}'")
            CheckForPair()
            return tab, i
        elseif char == "=" then
            --print("- found '='")
            key = ConvertStringToType(current_str)
            current_str = nil
        elseif char == "," then
            --print("- found ','")
            CheckForPair()
        elseif char ~= "[" and char ~= "]" then
            --print("- found other")
            current_str = (current_str or "") .. char
        end
    end
    return tab[1]
end

function IsNumberValid(val)
    return val ~= nil and type(val) == "number"
end
function ConvertTableToPoint(tab)
    if tab == nil or type(tab) ~= "table" then return end
    local x = tab.x or tab[1]
    local y = tab.y or tab[2]
    local z = tab.z or tab[3]
    return IsNumberValid(x) and IsNumberValid(y) and IsNumberValid(z) and _G.Point(x, y, z)
end

-----------------
-- Player Util --
-----------------
-- Returns true if a player is playing the given character prefab
function HasCharacter(character)
	for _,player in pairs(AllPlayers) do
		if player.prefab == character then
			return true
		end
	end
	return false
end

function AreAllPlayersDead(ignored_players)
    local ignored_players = ignored_players or {}
	for _,player in pairs(AllPlayers) do
		if not (player.components.health:IsDead() or player.components.revivablecorpse:IsReviving() or player.prefab == "spectator" or ignored_players[player.userid]) then
			return false
		end
	end
	return true
end

function GetPlayer(userid)
    for _,player in pairs(AllPlayers) do
        if player.userid == userid then
            return player
        end
    end
end

function GetPlayersClientTable()
    local clients = TheNet:GetClientTable() or {}
    if not TheNet:GetServerIsClientHosted() then
        for i, v in ipairs(clients) do
            if v.performance ~= nil then
                table.remove(clients, i) -- remove "host" object
                break
            end
        end
    end
    return clients
end

function AreClientsLoading(userids)
    for _,player in pairs(GetPlayerClientTable()) do
        if (userids == nil or userids[player.userid]) and checkbit(player.userflags, USERFLAGS.IS_LOADING) then
            return true
        end
    end
    return false
end

function IsUserAdmin(userid)
    local user = TheNet:GetClientTableForUser(userid)
    return user and user.admin == true
end

--------------
-- Ent Util --
--------------
-- TODO need dynamic range check based on map size
-- TODO need to remake this so you give prefabs and kill only the ents with the given prefabs
--	_G.MAPSIZE or something like that?
-- Kills all entities, can specify what entities to kill by prefab
function KillAll(...)
	local ents = TheSim:FindEntities(0, 0, 0, 500, {...})
	for k, v in pairs(ents) do
		if v and v:IsValid() and v.components.health then
			v.components.health:Kill()
		end
	end
end

----------------
-- Other Util --
----------------
-- Round to the given value based on the given decimal value.
-- dec_val: should be 1, 10, 100, 1000, etc.
function Round(val, dec_pos)
    local dec_pos = dec_pos or 1
    return math.floor((val + 0.5)*dec_pos)/dec_pos
end

-- Returns a list of the given item repeated a given amount of times
function RepeatItem(item, amount)
	local repeated_item = {}
	for i = 1, amount, 1 do
		table.insert(repeated_item, item)
	end
	return repeated_item
end

-- Cancels the given task. If a table is given as a task with a task param then it will cancel the task and remove it from the table.
function RemoveTask(task, param)
	if task then
        if param ~= nil and task[param] then
             task[param]:Cancel()
             task[param] = nil
        elseif param == nil then
            task:Cancel()
        end
	end
end

local function ClearThread(thread)
	if thread then
		KillThreadsWithID(thread.id)
		thread:SetList(nil)
		thread = nil
	end
end

local function DoesThreadExist(id)
	for _,task in pairs(scheduler.tasks) do
		if task.id == id then
			return true
		end
	end
	return false
end

-- Creates a thread that will continue to run a given task until the given condition is not met
-- Notes:
-- If no condition given then the thread will continue to run until the entity is no longer valid.
-- If no task given then no thread is created.
-- The GUID of the given ent is attached to the given id to differentiate between ents attempting to use the same id.
function CreateConditionThread(inst, id, initial_delay, period, condition_fn, task_fn, onexit_fn, data)
	local id = id .. "_" .. tostring(inst.GUID)
	if not task_fn then
		Debug:Print("Attempted to create a condition thread with no task.", "warning")
		return
	elseif DoesThreadExist(id) then -- TODO remove the print in this later, because this will be spammed in a lot of cases...
		Debug:Print("Attempted to create a duplicate thread with the id " .. tostring(id), "warning")
		return
	end
	local thread
	thread = StartThread(function()
        Sleep(initial_delay or 0)
		while(inst:IsValid() and condition_fn and condition_fn(inst, data)) do
			task_fn(inst, data)
			Sleep(period or 1)
		end
		if onexit_fn then
			onexit_fn(inst, data)
		end
		ClearThread(thread)
	end, id)
	return thread
end

-- Keep in mind that it uses updatelooper component.
-- Returns OnUpdate fn (so it can be stopped if needed)
-- package.loaded["forge_util"] = nil require("forge_util")
-- DoColourBlooming(ThePlayer, 1, 2, {1, 0, 0, 0}, false, function() print("fadein_onfone") end, function() print("fadeout_onfone") end)
function DoColourBlooming(inst, fadein_dur, fadeout_dur, clr, nofadeout, fadein_onfone, fadeout_onfone)
    if not inst.components.colouradder then
        Debug:Print("Tried to do blooming without colouradder component!\n", debugstack(), "warning")
        return
    end

    fadeout_dur = fadeout_dur or fadein_dur

    if not inst.components.updatelooper then
        inst:AddComponent("updatelooper")
    end

    local function OnUpdate(inst, dt)
        local percent = 0

        inst._t = inst._t + dt

        if inst._fadeout then
            if inst._t > fadeout_dur or nofadeout then
                percent = 0
            else
                percent = math.max(1 - inst._t / fadeout_dur, 0)
            end
        else
            if inst._t <= fadein_dur then
                percent = inst._t/fadein_dur
            else
                percent = 1
                inst._fadeout = true
                inst._t = 0
                if fadein_onfone then
                    fadein_onfone(inst)
                end
            end
        end

        if percent == 0 then
            inst._t = nil
            inst._fadeout = nil
            inst.components.colouradder:PopColour("clr_bloom")
            inst.components.updatelooper:RemoveOnWallUpdateFn(OnUpdate)

            if fadeout_onfone then
                fadeout_onfone(inst)
            end
        else
            inst.components.colouradder:PushColour("clr_bloom", clr[1] * percent, clr[2] * percent, clr[3] * percent, clr[4] * percent)
        end
    end

    -- Since we're on server it should'n matter if we're in OnUpdate or OnWallUpdate
    -- I'll talk to Zark and update it when I find out
    inst._t = 0
    inst._fadeout = false
    inst.components.updatelooper:AddOnWallUpdateFn(OnUpdate)

    return OnUpdate
end

function SaveEventMatchStats(is_server, match_results)
    local player_stats = match_results and match_results.player_stats or _G.Settings.match_results.player_stats or _G.TheFrontEnd.match_results.player_stats
    if player_stats and #player_stats.data > 0 then
        local str = "\nstats_type,".. tostring(player_stats.gametype)
        str = str .. "\nsession," .. tostring(player_stats.session)
        str = str .. "\nserver_date," .. os.date("%c")
        str = str .. "\ncommands," .. tostring(player_stats.commands)
        str = str .. "\nscripts," .. tostring(player_stats.scripts)

        local outcome = match_results and match_results.outcome or _G.Settings.match_results.outcome or _G.TheFrontEnd.match_results.outcome
        if outcome then
            str = str .. "\nversion," .. tostring(outcome.version)
            str = str .. "\nwon," .. (outcome.won and "true" or "false")
            str = str .. "\nround," .. tostring(outcome.round)
            str = str .. "\ntime," .. tostring(math.floor(outcome.time))
            if TheNet:GetServerGameMode() == "quagmire" then
                str = str .. "\nscore," .. tostring(outcome.score)
                str = str .. "\ntributes_success," .. tostring(outcome.tributes_success)
                str = str .. "\ntributes_failed," .. tostring(outcome.tributes_failed)
            else
                str = str .. "\ntotal_deaths," .. tostring(outcome.total_deaths)
                str = str .. "\ntotal_rounds_completed," .. tostring(outcome.total_rounds_completed)
                str = str .. "\npreset," .. tostring(outcome.preset)
                str = str .. "\nmode," .. tostring(outcome.mode)
                str = str .. "\ngametype," .. tostring(outcome.gametype)
                str = str .. "\ndifficulty," .. tostring(outcome.difficulty)
                str = str .. "\nwaveset," .. tostring(outcome.waveset)
                str = str .. "\nmap," .. tostring(outcome.map)
                local mutator_fields_str = "\nmutator_fields"
                local mutator_values_str = "\nmutator_values"
                for mutator,val in pairs(outcome.mutators or {}) do
                    if type(val) == "number" and val ~= 1 or val then
                        mutator_fields_str = mutator_fields_str .. "," .. mutator
                        mutator_values_str = mutator_values_str .. "," .. tostring(val)
                    end
                end
                str = str .. mutator_fields_str
                str = str .. mutator_values_str
            end
        end

        local userid_index = 0
        str = str .. "\nfields"
        for i,v in ipairs(player_stats.fields) do
            str = str .. "," .. tostring(v)
        end

        for j, player in ipairs(player_stats.data) do
            str = str .. "\nplayer"..j
            for i,v in ipairs(player) do
                str = str .. "," .. tostring(v)
            end
        end
        print(str)

        str = str .. "\nendofmatch"

        print("Logging Match Statistics") -- TODO put gametype instead so if playing double trouble? Or add gamemode to what prints?
        local stats_file = "event_match_stats/".. GetActiveFestivalEventStatsFilePrefix() .. (is_server and "_server_" or "_") .. string.gsub(os.date("%x"), "/", "-") .. ".csv"
        TheSim:GetPersistentString(stats_file, function(load_success, old_str)
            if old_str ~= nil then
                str = str .. "\n" .. old_str
            end
            TheSim:SetPersistentString(stats_file, str, false, function() print("Done Logging Match Statistics") end)
        end)
    end
end

function ConvertEscapeCharactersToString(str)
    local newstr = string.gsub(str, "\n", "\\n")
    newstr = string.gsub(newstr, "\r", "\\r")
    newstr = string.gsub(newstr, "\"", "\\\"")

    return newstr
end

local function GenerateTitleBorder(length)
    local border_str = ""
    for i=1,length do
        border_str = border_str .. "-"
    end
    return border_str .. "\n"
end

local function GenerateTitle(str)
    local title_str = "# -- " .. str .. " --\n"
    local title_border = GenerateTitleBorder(string.len(title_str) - 1)
    return title_border .. title_str .. title_border .. "\n"
end

local function GetStringFromTable(str_loc, name, titles, language, current_str)
    local current_str = current_str or ""
    local titles = titles or {}
    if titles[name] then
        current_str = current_str .. GenerateTitle(tostring(titles[name]))
    end
    if type(str_loc) == "string" then
        return current_str .. "#. " .. name .. "\nmsgctxt \"" .. name .. "\"\nmsgid \"" .. ConvertEscapeCharactersToString(str_loc) .. "\"\nmsgstr \"" .. ConvertEscapeCharactersToString(tostring(language and _G.LanguageTranslator:GetTranslatedString(name, language) or "")) .. "\"\n\n"
    else
        for i,val in pairs(str_loc) do
            if titles[i] then
                current_str = current_str .. GenerateTitle(tostring(titles[i]))
            end
            current_str = GetStringFromTable(val, name .. "." .. tostring(i), titles, language, current_str)
        end
    end
    return current_str
end

-- Returns a table of strings that have been set up for a language pot file.
local function GetStringsFromTable(str_loc, name, titles, language, current_strings)
    local current_strings = current_strings or {}
    local titles = titles or {}
    if type(str_loc) == "string" then
        return "#. " .. name .. "\nmsgctxt \"" .. name .. "\"\nmsgid \"" .. ConvertEscapeCharactersToString(str_loc) .. "\"\nmsgstr \"" .. ConvertEscapeCharactersToString(tostring(language and _G.LanguageTranslator:GetTranslatedString(name, language) or "")) .. "\"\n\n"
    else
        for i,val in pairs(str_loc) do
            if titles[i] then
                current_strings[i] = {}
                GetStringsFromTable(val, name .. "." .. tostring(i), titles, current_strings[i])
            else
                table.insert(current_strings, GetStringsFromTable(val, name .. "." .. tostring(i), titles, current_strings))
            end
        end
    end
    return current_strings
end

----------------------------------------
-- Generate ReForged Strings POT File --
----------------------------------------
local reforged_str_info = {}
-- Character Descriptions
local character_desc_list = {"winona", "warly", "wortox", "wormwood", "wurt", "walter", "spectator"}
for i,char in pairs(character_desc_list) do
    table.insert(reforged_str_info, {
        str_loc = STRINGS.LAVAARENA_CHARACTER_DESCRIPTIONS[char],
        name = "STRINGS.LAVAARENA_CHARACTER_DESCRIPTIONS." .. char,
    })
end
table.insert(reforged_str_info, {
    str_loc = STRINGS.CHARACTER_NAMES.spectator,
    name = "STRINGS.CHARACTER_NAMES.spectator",
})
table.insert(reforged_str_info, {
    str_loc = STRINGS.CHARACTER_TITLES.spectator,
    name = "STRINGS.CHARACTER_TITLES.spectator",
})
-- Items
local prefabs = {"LAVAARENA_SEEDDARTS", "MEAN_FLYTRAP", "LAVAARENA_SEEDDART2", "ADULT_FLYTRAP", "LAVAARENA_SPATULA", "FORGE_COOKPOT", "SPICE_BOMB", "TELEPORT_STAFF", "LAVAARENA_GAUNTLET", "FORGE_TRIDENT", "MERM_GUARD", "PORTALSTAFF"}
local characters = {"GENERIC", "WAXWELL", "WOLFGANG", "WX78", "WILLOW", "WENDY", "WOODIE", "WICKERBOTTOM", "WATHGRITHR", "WEBBER", "WINONA", "WORTOX", "WORMWOOD", "WARLY", "WURT", "WALTER", "WANDA"}
local mult_cast_aoe = {
    SPICE_BOMB = {"SPICE_BOMB_HEAL", "SPICE_BOMB_ATTACK", "SPICE_BOMB_DEFENSE", "SPICE_BOMB_SPEED"},
    PORTALSTAFF = {"PORTAL_ACTIVATE", "PORTAL_TARGET"},
}
for i,item_name in pairs(prefabs) do
    table.insert(reforged_str_info, {
        str_loc = STRINGS.NAMES[item_name],
        name = "STRINGS.NAMES." .. item_name,
        titles = {["STRINGS.NAMES." .. item_name] = item_name},
    })
    if STRINGS.ACTIONS.CASTAOE[item_name] then
        for _,aoe_name in pairs(mult_cast_aoe[item_name] or {item_name}) do
            table.insert(reforged_str_info, {
                str_loc = STRINGS.ACTIONS.CASTAOE[aoe_name],
                name = "STRINGS.ACTIONS.CASTAOE." .. aoe_name,
            })
        end
    end
    for j,char in pairs(characters) do
        local describe_str = STRINGS.CHARACTERS[char] and STRINGS.CHARACTERS[char].DESCRIBE[item_name]
        if describe_str then
            table.insert(reforged_str_info, {
                str_loc = describe_str,
                name = "STRINGS.CHARACTERS." .. char .. ".DESCRIBE." .. item_name,
            })
        end
    end
end
-- Other Names
local names = {"PITPIG", "BOARILLA", "SCORPEON", "MODDED_CHARACTER", "CHEATER", "CROCOMMANDER_RAPIDFIRE", "BATTLESTANDARD_SPEED", "LAVAARENA_CHEFHAT", "SCORPEON_ACID", "DEBUFF_FIRE", "DEBUFF_POISON", "NOLIGHT", "GREENLIGHT", "REDLIGHT", "ORANGELIGHT", "BLUELIGHT", "FORGEDARTS", "FORGINGHAMMER", "RILEDLUCY", "PITHPIKE", "PETRIFYINGTOME", "REEDTUNIC", "FEATHEREDTUNIC", "FORGE_WOODARMOR", "BABYSPIDER", "FORGE_ABIGAIL", "FORGE_BERNIE", "FORGE_WOBY", "BABY_BEN"}
for i,name in pairs(names) do
    table.insert(reforged_str_info, {
        str_loc = STRINGS.NAMES[name],
        name = "STRINGS.NAMES." .. name,
        titles = i == 1 and {["STRINGS.NAMES." .. name] = "NAMES"} or {},
    })
end
local extended_names = {"LAVAARENA_CHEFHAT"}
for i,name in pairs(extended_names) do
    table.insert(reforged_str_info, {
        str_loc = STRINGS.NAME_DETAIL_EXTENTION[name],
        name = "STRINGS.NAME_DETAIL_EXTENTION." .. name,
        titles = i == 1 and {["STRINGS.NAME_DETAIL_EXTENTION." .. name] = "EXTENDED NAMES"} or {},
    })
end
table.insert(reforged_str_info, {
    str_loc = STRINGS.CHARACTER_DETAILS.FORGE_STARTING_ITEMS_TITLE,
    name = "STRINGS.CHARACTER_DETAILS.FORGE_STARTING_ITEMS_TITLE",
    titles = {["STRINGS.CHARACTER_DETAILS.FORGE_STARTING_ITEMS_TITLE"] = "UI"},
})
-- UI
local ui_strings = {"FORCESTART", "CANCELSTART", "SAYSTART", "SAYCANCEL", "FORCESTARTTITLE", "FORCESTARTDESC", "SERVER_ANNOUNCEMENT_NAME"}
for _,ui_str in pairs(ui_strings) do
    table.insert(reforged_str_info, {
        str_loc = STRINGS.UI.LOBBYSCREEN[ui_str],
        name = "STRINGS.UI.LOBBYSCREEN." .. ui_str,
    })
end
-- XP Screen
local xp_lobby_names = {"LEVEL", "MULT_VAL", "ADD_VAL", "MUTATOR_VAL", "TOTAL_ROUNDS_COMPLETED", "TOTAL_EXP_GAINED"}
for i,name in pairs(xp_lobby_names) do
    table.insert(reforged_str_info, {
        str_loc = STRINGS.UI.WXPLOBBYPANEL[name],
        name = "STRINGS.UI.WXPLOBBYPANEL." .. name,
        titles = i == 1 and {["STRINGS.UI.WXPLOBBYPANEL." .. name] = "XP SCREEN"} or {},
    })
end
local xp_detail_names = {"SAME_CHARACTERS", "RANDOM_CHARACTER", "RANDOM_CHARACTERS_TEAM", "NO_ABILITIES", "NO_ABILITIES_TEAM", "CONSECUTIVE_WIN", "PARTY_SIZE", "MOB_KILLS", "MOB_DAMAGE", "MOB_DEFENSE", "MOB_HEALTH", "MOB_SPEED", "MOB_ATTACK_RATE", "MOB_SIZE", "BATTLESTANDARD_EFFICIENCY", "NO_SLEEP", "NO_REVIVES", "NO_HUD", "FRIENDLY_FIRE", "SCRIPTS", "COMMANDS", "HARD_MODE", "CLASSIC_RLGL", "RLGL", "ENDLESS", "MOB_DUPLICATOR", "JOINED_MIDMATCH"}
for i,name in pairs(xp_detail_names) do
    table.insert(reforged_str_info, {
        str_loc = STRINGS.UI.WXP_DETAILS[name],
        name = "STRINGS.UI.WXP_DETAILS." .. name,
    })
end
-- Detailed Summary Screen
table.insert(reforged_str_info, {
    str_loc = STRINGS.UI.DETAILEDSUMMARYSCREEN,
    name = "STRINGS.UI.DETAILEDSUMMARYSCREEN",
    titles = {
        ["STRINGS.UI.DETAILEDSUMMARYSCREEN"] = "DETAILED SUMMARY SCREEN",
    },
})
-- Admin Menu
table.insert(reforged_str_info, {
    str_loc = STRINGS.UI.ADMINMENU,
    name = "STRINGS.UI.ADMINMENU",
    titles = {
        ["STRINGS.UI.ADMINMENU"] = "ADMIN MENU",
    },
})
-- Panels
table.insert(reforged_str_info, {
    str_loc = STRINGS.UI.GAME_SETTINGS_PANEL,
    name = "STRINGS.UI.GAME_SETTINGS_PANEL",
    titles = {
        ["STRINGS.UI.GAME_SETTINGS_PANEL"] = "GAME SETTINGS PANEL",
    },
})
table.insert(reforged_str_info, {
    str_loc = STRINGS.UI.LEADERBOARD_PANEL,
    name = "STRINGS.UI.LEADERBOARD_PANEL",
    titles = {
        ["STRINGS.UI.LEADERBOARD_PANEL"] = "LEADERBOARD PANEL",
    },
})
table.insert(reforged_str_info, {
    str_loc = STRINGS.UI.FORGEHISTORYPANEL,
    name = "STRINGS.UI.FORGEHISTORYPANEL",
    titles = {
        ["STRINGS.UI.FORGEHISTORYPANEL"] = "HISTORY PANEL",
    },
})
table.insert(reforged_str_info, {
    str_loc = STRINGS.UI.ACHIEVEMENTS_PANEL,
    name = "STRINGS.UI.ACHIEVEMENTS_PANEL",
    titles = {
        ["STRINGS.UI.ACHIEVEMENTS_PANEL"] = "ACHIEVEMENTS PANEL",
    },
})
table.insert(reforged_str_info, {
    str_loc = STRINGS.UI.NEWS_PANEL,
    name = "STRINGS.UI.NEWS_PANEL",
    titles = {
        ["STRINGS.UI.NEWS_PANEL"] = "NEWS PANEL",
    },
})
-- MVP Titles
local stat_titles = {"player_damagedealt", "player_damagetaken", "pet_damagedealt", "pet_damagetaken", "cctime", "ccbroken", "petdeaths", "healingreceived", "total_friendly_fire_damage_dealt"}
for i,name in pairs(stat_titles) do
    table.insert(reforged_str_info, {
        str_loc = STRINGS.UI.MVP_LOADING_WIDGET.LAVAARENA.TITLES[name],
        name = "STRINGS.UI.MVP_LOADING_WIDGET.LAVAARENA.TITLES." .. name,
        titles = i == 1 and {["STRINGS.UI.MVP_LOADING_WIDGET.LAVAARENA.TITLES." .. name] = "MVP TITLES"} or {},
    })
end
local stat_descs = {"healingreceived", "pet_damagetaken", "player_damagedealt", "player_damagetaken", "cctime", "petdeaths", "ccbroken", "pet_damagedealt", "unknown", "parry", "attack_interrupt", "cheater", "total_friendly_fire_damage_dealt", "total_friendly_fire_damage_taken"}
for i,name in pairs(stat_descs) do
    table.insert(reforged_str_info, {
        str_loc = STRINGS.UI.MVP_LOADING_WIDGET.LAVAARENA.DESCRIPTIONS[name],
        name = "STRINGS.UI.MVP_LOADING_WIDGET.LAVAARENA.DESCRIPTIONS." .. name,
    })
end
-- ReForged Strings
local reforged_titles = {
    ENEMIES            = "ENEMIES",
    PETS               = "PETS",
    STRUCTURES         = "STRUCTURES",
    ARMOR              = "ARMOR",
    HELMS              = "HELMS",
    WEAPONS            = "WEAPONS",
    CHARACTER          = "CHARACTER",
    BUFFS              = "BUFF COMMANDS", -- TODO
    FORGE              = "FORGE COMMANDS", -- TODO Move to admin commands?
    GENERAL            = "GENERAL COMMANDS", -- TODO section it there?
    DIFFICULTIES       = "DIFFICULTIES",
    GAMETYPES          = "GAMETYPES",
    MAPS               = "MAPS",
    MODES              = "MODES",
    MUTATORS           = "MUTATORS",
    PRESETS            = "PRESETS",
    WAVESETS           = "WAVESETS",
    RLGL               = "RED LIGHT GREEN LIGHT",
    USERCOMMANDS       = "USER COMMANDS",
    VOTE               = "VOTE",
    ADMIN_COMMANDS     = "ADMIN COMMANDS",
    FORGELORD_DIALOGUE = "FORGE LORD DIALOGUE",
    DEBUFFS            = "DEBUFFS",
    PERKS              = "PERKS",
    ACHIEVEMENTS       = "ACHIEVEMENTS",
    MODS               = "MODS",
    HUD                = "HUD",
    --PING_GROUP = true,
}
table.insert(reforged_str_info, {
    str_loc = STRINGS.REFORGED,
    name = "STRINGS.REFORGED", -- TODO a way to get this as a string from the table itself?
    titles = reforged_titles,
})
--[[
Generate a string pot file for the given strings in the given language. If no string info is given it generates a string pot file for reforged.
str_info = {
    {
        str_loc = tab,     -- Starting String table
        name = name,       -- String representation of the given table
        titles = {},       -- Titles for specific table indices
        sort_fn = sort_fn, -- Sort the strings with a custom fn, must return their own string
    }
}
ex.
GenerateStringPotFileForTables("string_pot_test", {{str_loc = STRINGS.REFORGED, name = "STRINGS.REFORGED", titles = {ACHIEVEMENTS = true, PERKS = true}}})
--]]
function GenerateStringPotFileForTables(name, str_info, language)
    local str_info = str_info or reforged_str_info
    local pot_str = ""
    for _,info in pairs(str_info) do
        pot_str = pot_str .. (info.sort_fn and info.sort_fn(GetStringsFromTable(info.str_loc, info.name, info.titles, language)) or GetStringFromTable(info.str_loc, info.name, info.titles, language))
    end
    local file_name = name .. (language and ("_" .. language) or "")
    _G.TheSim:SetPersistentString(file_name .. ".pot", pot_str, false, function() Debug:Print("String Pot File Generated (" .. file_name .. ".pot)") end, "log")
    --[[local file = io.open(file_name .. ".pot", "w")
    if file ~= nil then
        file:write(pot_str)
        Debug:Print("String Pot File Generated (" .. file_name .. ".pot)", "log")
        file:close()
    end--]]
end
--GenerateStringPotFileForTables("string_achievements", achievement_info_test)
--GenerateStringPotFileForTables("korean_new", nil, "zh")
-- local file = io.open("testing.pot", "w") file:write(LanguageTranslator:ConvertEscapeCharactersToString("This\n is\n\\n\n\n a \\n test!\n!")) file:close()
-- local function Test(str) local newstr = string.gsub(str, "\n", "\\n") newstr = string.gsub(newstr, "\r", "\\r") newstr = string.gsub(newstr, "\"", "\\\"") newstr = string.gsub(newstr, "\\", "\\\\") return newstr end local file = io.open("testing.pot", "w") file:write(Test("This\n is\n\\n\n\n a \\n test!\n!")) file:close()
--[[
TODO
add a load language files in the generate function?
--]]
