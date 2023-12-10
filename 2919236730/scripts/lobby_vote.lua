--[[
TODO
    need total players
    need to update total players on join
        update active votes to include players that join during a vote?
            if so reset timer for vote? or not?
        do new players count? if not then must dictate that?

Server Message
    have it say server and have a unique color
    move this to another file?

Settings
    Vote Timer
        for each type of vote?

Other
    Active Vote
        No vote can be started.
        Should admin commands be allowed?
    Player Joining/DC
        a player active in a vote will be removed from the vote(unless they are the initiator)?
        all players dcing that are a part of the current vote will end the vote in a failure immediately
        Needs Testing
    Update String File
        add all strings to the string file for translations later
    Admins
        Admins cannot start votes because they can just trigger the command.
        Buttons and all text should reflect that.
        Double check
    Only 1 player
        all votes will immediately pass.
        Disabled atm for testing
    Have a timer preventing vote spam?
        probably not...
--]]
-- TODO common function????? used in forge lobby, possibly in admin commands as well
local function SendCommand(fnstr)
    local x, _, z = _G.TheSim:ProjectScreenPos(_G.TheSim:GetPosition())
    local is_valid_time_to_use_remote = _G.TheNet:GetIsClient() and _G.TheNet:GetIsServerAdmin()
    if is_valid_time_to_use_remote then
        _G.TheNet:SendRemoteExecute(fnstr, x, z)
    else
        _G.ExecuteConsoleCommand(fnstr)
    end
end
-----------
-- Setup --
-----------
TUNING.FORGE.CHAT_VOTE = {
    DEFAULT_TIMEOUT = 30,
}
_G.VOTE_COMMANDS = {} -- TODO make accessible everywhere? different table location?
-- Display parameter format:
--{
--  announcement = fn or string,
--  title = fn or string,
--  options = {
--      [1] = {
--          description = "",
--      },
--      -- up to 6 (MAX_VOTE_OPTIONS)
--  },
--  info = {
--      fn = function() end,
--      hover_text = "",
--  },
--}
local function AddVoteCommand(command, opts, display_opts) -- TODO anything else?
    if _G.VOTE_COMMANDS[command] then
        _G.Debug:Print("Attempted to add the command '" .. tostring(command) .. "', but it already exists!", "error")
        return
    end

    local options = {
        default_option = 2,
    }
    _G.MergeTable(options, opts, true)

    local display_options = {
        announcement = function(result, results, settings)
            return result == 1 and _G.STRINGS.REFORGED.VOTE.SUCCESS or _G.STRINGS.REFORGED.VOTE.FAILED
        end,
        title = _G.STRINGS.REFORGED.VOTE.TITLE,
    }
    _G.MergeTable(display_options, display_opts, true)

    _G.VOTE_COMMANDS[command] = {
        onstartfn    = options.onstartfn,
        oncompletefn = {
            server   = options.oncompletefns.server,
            client   = options.oncompletefns.client,
        },
        is_valid_fn    = options.is_valid_fn,
        default_option = options.default_option, -- TODO add initiator_option?
        timeout        = options.timeout,
        display        = display_options,
    }
end
_G.AddVoteCommand = AddVoteCommand
--[[
TODO
    find a way to edit MAX_MESSAGES in lobbychatqueue (redux)
    create server messages using this function below
--]]
-- Enable Server messages through the chat side bar on the lobby screen
--[[local _oldNetworking_Say = _G.Networking_Say
_G.Networking_Say = function (guid, userid, name, prefab, message, colour, whisper, isemote, user_vanity)
    local is_server_message = string.sub(message,1,6) == "server" -- TODO how to do this with other languages since they will differ in length?
    if is_server_message then
        _oldNetworking_Say(guid, userid, "server", prefab, string.sub(message,7), _G.WEBCOLOURS.PINK, whisper, isemote, user_vanity)
    else
        _oldNetworking_Say(guid, userid, name, prefab, message, colour, whisper, isemote, user_vanity)
    end
end--]]
-----------------------------
-- Vote To Change Settings --
-----------------------------
local function settings_onstartfn(initiator_id, initiator_name, results, params)
    local str = string.format(_G.STRINGS.REFORGED.VOTE.SETTINGS_DESC, tostring(initiator_name))
end

local function settings_oncompletefn_client(result, settings)
    local reset = false
    if result == 1  and not _G.TheWorld.net.components.lavaarenaeventstate:IsInProgress() then
        local current_settings = _G.REFORGED_SETTINGS.gameplay
        -- Save and Apply all changed Settings
        for setting,value in pairs(settings) do
            if setting == "mutators" then
                for mutator,val in pairs(value) do
                    current_settings.mutators[mutator] = val
                    if not reset and _G.REFORGED_DATA.mutators[mutator].reset then
                        reset = true
                    end
                end
            else
                local prior_setting_info = _G.REFORGED_DATA[setting .. "s"] and _G.REFORGED_DATA[setting .. "s"][current_settings[setting]]
                current_settings[setting] = value
                local setting_info = _G.REFORGED_DATA[setting .. "s"] and _G.REFORGED_DATA[setting .. "s"][value]
                -- Reset if prior setting or current setting need a reset to be applied.
                if setting_info and setting_info.reset or prior_setting_info and prior_setting_info.reset then
                    reset = true
                end

				if setting_info and setting_info.forge_lord then
                    _G.TheWorld.net:UpdateForgeLord(prior_setting_info and prior_setting_info.forge_lord)
                end

                if setting == "gametype" and _G.TheWorld.ismastersim then
                    if prior_setting_info and prior_setting_info.fns.disable_server_fn then
                        prior_setting_info.fns.disable_server_fn(_G.TheWorld)
                    end
                    if setting_info and setting_info.fns.enable_server_fn then
                        setting_info.fns.enable_server_fn(_G.TheWorld)
                    end
                end
            end
        end
        --[[
local screen = _G.TheFrontEnd:GetScreen("LobbyScreen") if screen and screen.current_panel_index == 1 and screen.panel.eventbook.last_selected._tabindex == #(screen.panel.eventbook.tabs) - 1 then screen.panel.eventbook.panel.mutator_checkboxes["redlight_greenlight"].button.onclick() end
        --]]
        local screen = _G.TheFrontEnd:GetScreen("LobbyScreen")
        if screen and screen.panel.eventbook and screen.panel.eventbook.last_selected._tabindex == screen.panel.eventbook.game_settings_panel._tabindex then -- TODO need better check here, the stat screen would be the first screen after a match breaking this
            screen.panel.eventbook.panel:ChangeSettings(settings)
        elseif screen and screen.panel.waiting_for_players then
            screen.panel.waiting_for_players:UpdateGameSettingsDisplay()
        end
    end
    return reset
end

local function settings_oncompletefn(result, results, settings)
    -- Reset the server if a changed setting requires it to.
    return settings_oncompletefn_client(result, settings)
end

local function GetEventbookPanel()
    -- TODO this does not work but there still could be a way to do this besides hardcoding?
    --for i,panel in pairs(_G.TheFrontEnd:GetScreen("LobbyScreen").panels) do
        --if panel.eventbook then
            --return i
        --end
    --end
    --return 0
    local screen = _G.TheFrontEnd:GetScreen("LobbyScreen")
    return #(screen.panels) > 4 and 2 or 1
end

local settings_display = {
    announcement = function(result, results, settings)
        return result == 1 and _G.STRINGS.REFORGED.VOTE.SETTINGS_SUCCESS or _G.STRINGS.REFORGED.VOTE.SETTINGS_FAILED
    end,
    title = _G.STRINGS.REFORGED.VOTE.SETTINGS_TITLE,
    --options = {},
    info = {
        hover_text = _G.STRINGS.REFORGED.VOTE.SETTINGS_INFO,
        fn = function(inst)
            local settings = _G.TheWorld.net.replica.lobbyvote:GetSettings()
            local screen = _G.TheFrontEnd:GetScreen("LobbyScreen")
            if screen and settings then
                local eventbook_panel_index = GetEventbookPanel()
                -- Select the LavaArenaBook Panel
                if screen.current_panel_index ~= eventbook_panel_index then -- TODO need better check here, the stat screen would be the first screen after a match breaking this
                    -- Reset Character Selection
                    if screen.current_panel_index == #(screen.panels) then
                        screen.panel:OnBackButton()
                        screen.back_button:Enable()
                        screen.back_button:Show()
                    end
                    screen:ToNextPanel(eventbook_panel_index - screen.current_panel_index)
                end
                -- Select the Game Settings Panel
                local tab = screen.panel.eventbook.tabs[screen.panel.eventbook.game_settings_panel._tabindex + 1]
                tab.onclick()
                -- Display the settings being voted on
                local game_settings_tab = screen.panel.eventbook.panel
                game_settings_tab:ChangeSettings(settings)
            end
        end,
    },
}
local settings_opts = {
    onstartfn     = settings_onstartfn,
    oncompletefns = {
        server = settings_oncompletefn,
        client = settings_oncompletefn_client,
    },
    is_valid_fn    = nil,
    default_option = 2,
    timeout        = 30,
}
AddVoteCommand("settings", settings_opts, settings_display)
-------------------------
-- Vote To Kick Player --
-------------------------
local function kick_validatefn(caller, target_id)
    -- Target must be connected to the server or the vote is canceled.
    return target_id ~= nil and _G.TheNet:GetClientTableForUser(target_id) ~= nil
end

local function kick_oncompletefn(result, results, params)
    if result == 1 and params.target_id and _G.TheNet:GetClientTableForUser(params.target_id) ~= nil then
        --_G.TheNet:Kick(params.target_id)
        _G.Debug:Print("User '" .. tostring(params.target_id) .. "' has been kicked (banned for 60 seconds) due to a player vote or an admin.", "note")
        _G.TheNet:BanForTime(params.target_id, 60) -- TODO game setting?
    end
end

local kick_display = {
    announcement = function(result, results, params)
        local target = params.target_id and _G.TheNet:GetClientTableForUser(params.target_id) -- TODO connecting players are nil, need to get player name from somewhere else?
        return result == 1 and string.format(_G.STRINGS.REFORGED.VOTE.KICK_SUCCESS, tostring(target.name)) or string.format(_G.STRINGS.REFORGED.VOTE.KICK_FAILED, target and tostring(target.name) or _G.STRINGS.REFORGED.unknown)
    end,
    title = function(initiator, params)
        local target = params.target_id and _G.TheNet:GetClientTableForUser(params.target_id)
        return string.format(_G.STRINGS.REFORGED.VOTE.KICK_TITLE, tostring(target and target.name))
    end
}
local kick_opts = {
    oncompletefns = {
        server = kick_oncompletefn,
    },
    is_valid_fn    = kick_validatefn,
}
AddVoteCommand("kick", kick_opts, kick_display)
-------------------------
-- Vote To Force Start --
-------------------------
local force_start_display = {
    announcement = function(result, results, params)
        return result == 1 and _G.STRINGS.REFORGED.VOTE.FORCE_START_SUCCESS or _G.STRINGS.REFORGED.VOTE.FORCE_START_FAILED
    end,
    title = function(initiator, params)
        return _G.STRINGS.REFORGED.VOTE.FORCE_START_TITLE
    end
}
local cancel_force_start_display = {
    announcement = function(result, results, params)
        return result == 1 and _G.STRINGS.REFORGED.VOTE.CANCEL_FORCE_START_SUCCESS or _G.STRINGS.REFORGED.VOTE.CANCEL_FORCE_START_FAILED
    end,
    title = function(initiator, params)
        return _G.STRINGS.REFORGED.VOTE.CANCEL_FORCE_START_TITLE
    end
}
local function force_start_oncompletefn(result, results)
    if result == 1 and not _G.AreClientsLoading() and not _G.TheWorld.net.components.lavaarenaeventstate:IsInProgress() then
        _G.TheWorld.net.components.worldcharacterselectlobby:ForceStart(tostring(_G.REFORGED_SETTINGS.force_start_delay))
    end
end
local force_start_opts = {
    oncompletefns = {
        server = force_start_oncompletefn,
    },
}
AddVoteCommand("force_start", force_start_opts, force_start_display)

local function cancel_force_start_oncompletefn(result, results)
    if result == 1 then
        SendCommand("TheWorld.net.components.worldcharacterselectlobby:CancelForceStart()")
    end
end
local cancel_force_start_opts = {
    oncompletefns = {
        server = cancel_force_start_oncompletefn,
    },
}
AddVoteCommand("cancel_force_start", cancel_force_start_opts, cancel_force_start_display)
-------------------
-- User Commands --
-------------------
local MIN_TIMER = 5
AddUserCommand("lobbyvotestart", {
    prettyname = _G.STRINGS.REFORGED.USERCOMMANDS.START_VOTE_TITLE,
    desc = _G.STRINGS.REFORGED.USERCOMMANDS.START_VOTE_DESC,
    permission = _G.COMMAND_PERMISSION.USER,
    slash = false,
    usermenu = false,
    servermenu = false,
    params = {"command", "force_success", "params_str"},
    paramsoptional = {false, false, true},
    vote = false,
    canstartfn = function(command, caller, targetid)
        local lobby_vote = _G.TheWorld.net.replica.lobbyvote
        local screen = _G.TheFrontEnd:GetScreen("LobbyScreen")
        return lobby_vote and not (lobby_vote:IsVoteActive() or lobby_vote:IsWorldResetting() or (screen and screen.countdown_started and _G.TheWorld.net.components.worldcharacterselectlobby:GetTimer() <= MIN_TIMER)) and _G.REFORGED_SETTINGS.vote.game_settings_panel
    end,
    hasaccessfn = function(command, caller, targetid)
        return _G.COMMON_FNS.CheckCommand("lobbyvotestart", caller.userid)
    end,
    serverfn = function(params, caller)
        if _G.TheWorld then
            _G.TheWorld.net.components.command_manager:UpdateCommandCooldownForUser("lobbyvotestart", caller.userid)
            local lobby_vote = _G.TheWorld.net.components.lobbyvote
            local command = params and params.command and _G.VOTE_COMMANDS[params.command]
            if lobby_vote and (_G.REFORGED_SETTINGS.vote.game_settings_panel or caller.admin and params.force_success) and command ~= nil then
                local params_str = params.params_str
                local custom_params = params_str and _G.ConvertStringToTable(params_str) or {}
                if not command.is_valid_fn or command.is_valid_fn(caller, custom_params and custom_params.target_id) then
                    lobby_vote:OnVoteStart(caller.userid, caller.name, params.command, params.force_success and params.force_success == "true" and caller.admin, custom_params, params_str or "")
                end
            end
        end
    end,
})
local function LobbyVoteSubmitCondition(userid)
    local lobby_vote = _G.TheWorld.net.components.lobbyvote
    return lobby_vote and lobby_vote.vote_results and lobby_vote.vote_results[userid] and (lobby_vote.initiator_id == userid or not lobby_vote.vote_results[userid].voted)
end
AddUserCommand("lobbyvotesubmit", {
    prettyname = _G.STRINGS.REFORGED.USERCOMMANDS.SUBMIT_VOTE_TITLE,
    desc = _G.STRINGS.REFORGED.USERCOMMANDS.SUBMIT_VOTE_DESC,
    permission = _G.COMMAND_PERMISSION.USER,
    slash = false,
    usermenu = false,
    servermenu = false,
    params = {"vote"},
    vote = false,
    hasaccessfn = function(command, caller, targetid)
        return _G.COMMON_FNS.CheckCommand("lobbyvotesubmit", caller.userid, LobbyVoteSubmitCondition)
    end,
    serverfn = function(params, caller)
        if _G.TheWorld then
            _G.TheWorld.net.components.command_manager:UpdateCommandCooldownForUser("lobbyvotesubmit", caller.userid)
            local lobby_vote = _G.TheWorld.net.components.lobbyvote
            if lobby_vote and lobby_vote:IsVoteActive() then
                lobby_vote:SubmitVote(caller.userid, _G.tonumber(params.vote))
            end
        end
    end,
})

AddUserCommand("lobbyvotecancel", {
    prettyname = _G.STRINGS.REFORGED.USERCOMMANDS.CANCEL_VOTE_TITLE,
    desc = _G.STRINGS.REFORGED.USERCOMMANDS.CANCEL_VOTE_DESC,
    permission = _G.COMMAND_PERMISSION.USER,
    slash = false,
    usermenu = false,
    servermenu = false,
    params = {},
    vote = false,
    hasaccessfn = function(command, caller, targetid)
        return _G.COMMON_FNS.CheckCommand("lobbyvotecancel", caller.userid, LobbyVoteSubmitCondition)
    end,
    serverfn = function(params, caller)
        if _G.TheWorld then
            _G.TheWorld.net.components.command_manager:UpdateCommandCooldownForUser("lobbyvotecancel", caller.userid)
            local lobby_vote = _G.TheWorld.net.components.lobbyvote
            if lobby_vote and caller and caller.admin then
                lobby_vote:CancelVote()
            end
        end
    end,
})
