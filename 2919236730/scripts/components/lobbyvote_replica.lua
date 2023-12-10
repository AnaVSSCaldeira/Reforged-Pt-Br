local Text = require "widgets/text"

local DEFAULT_VOTE_OPTIONS = {{description = STRINGS.UI.OPTIONS.YES}, {description = STRINGS.UI.OPTIONS.NO}}

local function GetCurrentVoteDisplayOptions(inst)
    local lobbyvote = inst.replica.lobbyvote
    local command_options = deepcopy(VOTE_COMMANDS[lobbyvote:GetCurrentVote()].display)
    command_options.title = lobbyvote:GetTitle()
    command_options.initiator_id = lobbyvote:GetInitiatorID()

    -- Load default options
    if not command_options.options then
        command_options.options = deepcopy(DEFAULT_VOTE_OPTIONS)
    end

    -- Update vote count
    local current_results = lobbyvote:GetCurrentResults()
    if current_results then
        for option,data in pairs(command_options.options) do
            data.vote_count = current_results[option] or 0
        end
    end

    return command_options
end

-- Displays the Vote Dialog with the current vote settings or hides the Vote Dialog if no vote is active.
local function OnToggleVote(inst)
    local screen = TheFrontEnd:GetScreen("LobbyScreen")
    local lobbyvote = inst.replica.lobbyvote
    if screen then
        if lobbyvote:IsVoteActive() and not screen.vote_menu.started then
            screen.vote_menu:ShowDialog(GetCurrentVoteDisplayOptions(inst))
            if inst.replica.lobbyvote:GetInitiatorID() == TheNet:GetUserID() then
                screen.vote_menu.buttons[1].onclick()
            end
            --inst:PushEvent("showlobbyvotedialog", option_data)
        elseif not lobbyvote:IsVoteActive() then
            screen.vote_menu:HideDialog()
            --inst:PushEvent("hidelobbyvotedialog")
        end
    end
end

-- Updates the vote dialog to display the current results
local function UpdateVoteResults(inst)
    local screen = TheFrontEnd:GetScreen("LobbyScreen")
    local lobbyvote = inst.replica.lobbyvote
    if screen and lobbyvote then
        lobbyvote.current_results = ConvertStringToTable(lobbyvote:GetCurrentResultsStr())
        screen.vote_menu:UpdateOptions(GetCurrentVoteDisplayOptions(inst))
    end
end

-- Displays an announcement on the lobby screen
local function OnAnnouncement(inst)
    local lobbyvote = inst.replica.lobbyvote
    local screen = TheFrontEnd:GetScreen("LobbyScreen")
    if screen then
        screen:DisplayAnnouncement(lobbyvote:GetAnnouncement())
    end
end

-- Converts the serialized settings string back to a table.
local function UpdateSettings(inst)
    local lobbyvote = inst.replica.lobbyvote
    lobbyvote.settings = ConvertStringToTable(lobbyvote:GetSettingsStr())
end

local function OnVoteComplete(inst)
    local lobbyvote = inst.replica.lobbyvote
    local command = VOTE_COMMANDS[lobbyvote:GetCurrentVote()]
    local result = lobbyvote:GetResult()
    if TheWorld and not TheWorld.ismastersim and command and command.oncompletefn and command.oncompletefn.client then
        command.oncompletefn.client(result, lobbyvote:GetSettings())
    end
end

-- Updates the timer for the vote
local function OnTick(inst)
    local lobbyvote = inst.replica.lobbyvote
    local screen = TheFrontEnd:GetScreen("LobbyScreen")
    if screen then
        if lobbyvote:IsWorldResetting() then
            screen.spawndelaytext:SetString(string.format(STRINGS.REFORGED.WORLD_RESET, lobbyvote:GetTimer()))
            screen.spawndelaytext:Show()
        else
            screen.vote_menu:UpdateTimer(lobbyvote:GetTimer())
        end
    end
end

-- Prepares for World Reset
local function OnWorldReset(inst)
    local screen = TheFrontEnd:GetScreen("LobbyScreen")
    if screen then
        screen.world_reset = true
        screen.vote_menu:HideDialog()
    end
end

local LobbyVote = Class(function(self, inst)
    self.inst = inst
    --self.settings = nil
    --self.current_results = nil
    self._title               = net_string(inst.GUID, "lobbyvote._title")
    self._announcement        = net_string(inst.GUID, "lobbyvote._announcement", "voteannouncement")
    self._current_vote        = net_string(inst.GUID, "lobbyvote._current_vote")
    self._initiator_id        = net_string(inst.GUID, "lobbyvote._initiator_id")
    self._current_results_str = net_string(inst.GUID, "lobbyvote._current_results_str", "updatevoteresults")
    self._settings_str        = net_string(inst.GUID, "lobbyvote._settings_str", "updatesettings")
    self._is_vote_active      = net_bool(inst.GUID, "lobbyvote._is_vote_active", "togglevote")
    self._result              = net_tinybyte(inst.GUID, "lobbyvote._result", "votecomplete")
    self._timer               = net_int(inst.GUID, "lobbyvote._timer", "lobbyvotertick")
    self._world_reset         = net_bool(inst.GUID, "lobbyvote._world_reset", "startworldreset")
    if not TheNet:IsDedicated() then
        self.inst:ListenForEvent("voteannouncement", OnAnnouncement)
        self.inst:ListenForEvent("updatesettings", UpdateSettings)
        self.inst:ListenForEvent("togglevote", OnToggleVote)
        self.inst:ListenForEvent("updatevoteresults", UpdateVoteResults)
        self.inst:ListenForEvent("votecomplete", OnVoteComplete)
        self.inst:ListenForEvent("lobbyvotertick", OnTick)
        self.inst:ListenForEvent("startworldreset", OnWorldReset)
    end
end)

function LobbyVote:GetTitle()
    return self._title:value()
end

function LobbyVote:SetTitle(val)
    self._title:set(val)
end

function LobbyVote:GetAnnouncement()
    return self._announcement:value()
end

function LobbyVote:SetAnnouncement(val)
    self._announcement:set_local(val)
    self._announcement:set(val)
end

function LobbyVote:GetCurrentVote()
    return self._current_vote:value()
end

function LobbyVote:SetCurrentVote(val)
    self._current_vote:set(val)
end

function LobbyVote:GetCurrentResultsStr()
    return self._current_results_str:value()
end

function LobbyVote:GetCurrentResults()
    return self.current_results
end

function LobbyVote:SetCurrentResultsStr(val)
    val = val or ""
    self._current_results_str:set_local(val)
    self._current_results_str:set(val)
end

function LobbyVote:GetSettingsStr()
    return self._settings_str:value()
end

function LobbyVote:SetSettingsStr(val)
    self._settings_str:set(val)
end

function LobbyVote:GetSettings()
    return self.settings
end

function LobbyVote:GetInitiatorID()
    return self._initiator_id:value()
end

function LobbyVote:SetInitiatorID(val)
    self._initiator_id:set(val)
end

function LobbyVote:IsVoteActive()
    return self._is_vote_active:value()
end

function LobbyVote:SetIsVoteActive(val)
    self._is_vote_active:set_local(val)
    self._is_vote_active:set(val)
end

function LobbyVote:GetResult()
    return self._result:value()
end

function LobbyVote:SetResult(val)
    self._result:set_local(val)
    self._result:set(val)
end

function LobbyVote:GetTimer()
    return self._timer:value()
end

function LobbyVote:SetTimer(val)
    self._timer:set(val)
end

function LobbyVote:IsWorldResetting()
    return self._world_reset:value()
end

function LobbyVote:SetWorldReset(val)
    self._world_reset:set_local(val)
    self._world_reset:set(val)
end

return LobbyVote
