--[[
TODO
    Move Vote Dialog so that it's in the same position for all resolutions
        not sure if this is possible, doesn't seem to want to, must be missing a setting for the widget somewhere or use resolution ratio of some sort
    Countdown for world reset does not display the string for the first second when canceling an active timer
    Need to test vote count and make sure it displays properly
--]]
local function GetDefaultAnnouncement(result)
    return result and STRINGS.REFORGED.VOTE.SUCCESS or STRINGS.REFORGED.FAILED
end

local function OnAnnouncement(self, announcement)
    self.inst.replica.lobbyvote:SetAnnouncement(announcement)
end

local function OnTitle(self, title)
    self.inst.replica.lobbyvote:SetTitle(title)
end

local function OnCurrentVote(self, current_vote)
    self.inst.replica.lobbyvote:SetCurrentVote(current_vote)
end

local function OnCurrentResultsStr(self, current_results_str)
    self.inst.replica.lobbyvote:SetCurrentResultsStr(current_results_str)
end

local function OnSettingsStr(self, settings_str)
    self.inst.replica.lobbyvote:SetSettingsStr(settings_str)
end

local function OnInitiatorID(self, initiator_id)
    self.inst.replica.lobbyvote:SetInitiatorID(initiator_id)
end

local function OnIsVoteActive(self, vote_active)
    self.inst.replica.lobbyvote:SetIsVoteActive(vote_active)
end

local function OnResult(self, result)
    self.inst.replica.lobbyvote:SetResult(result)
end

local function OnTimer(self, time)
    self.inst.replica.lobbyvote:SetTimer(time)
end

local function OnWorldReset(self, reset)
    self.inst.replica.lobbyvote:SetWorldReset(reset)
end

local function OnClientLoad(inst, userid)
    local lobbyvote = inst.net.components.lobbyvote
    if lobbyvote.is_vote_active and lobbyvote.vote_results[userid] then
        lobbyvote.is_vote_active = true
        lobbyvote.current_results_str = lobbyvote.current_results_str
    end
end

local function CheckLoadingClient(userid)
    local player = TheNet:GetClientTableForUser(userid)
    return player and checkbit(player.userflags, USERFLAGS.IS_LOADING)
end

-- TODO test this
-- Removes the disconnected player from the current vote (if active and part of the vote) and checks the status of the vote.
local function OnClientDisconnect(inst, data)
    local lobbyvote = inst.net.components.lobbyvote
    if lobbyvote.is_vote_active and lobbyvote.vote_results[data.userid] then
        lobbyvote.vote_results[data.userid] = nil
        lobbyvote.total_voters = lobbyvote.total_voters - 1
        -- Cancel the vote if the target disconnects
        if lobbyvote.vote_params.target_id == data.userid then
            lobbyvote:CancelVote()
        else
            lobbyvote:CheckVote()
        end
    end
end

local LobbyVote = Class(function(self, inst)
    self.inst = inst
    self.announcement = ""
    self.title = ""
    self.settings_str = ""
    self.is_vote_active = false
    self.result = 0
    self.total_voters = 0
    self.players_loading = {}
    self.world_reset = false
    self.inst:ListenForEvent("ms_clientdisconnected", OnClientDisconnect, TheWorld)
end, nil, {
    announcement = OnAnnouncement,
    title = OnTitle,
    current_vote = OnCurrentVote,
    current_results_str = OnCurrentResultsStr,
    settings_str = OnSettingsStr,
    initiator_id = OnInitiatorID,
    is_vote_active = OnIsVoteActive,
    result = OnResult,
    timer = OnTimer,
    world_reset = OnWorldReset,
})

function LobbyVote:OnVoteStart(initiator_id, name, command_name, force_success, params, params_str)
    local command = VOTE_COMMANDS[command_name]
    if not command then return end
    Debug:Print(tostring(name) .. " has started a vote using " .. tostring(command) .. ".", "log") -- TODO string? this is a debug log for server owner so string or no string?
    self.vote_params = params
    self.settings_str = params_str
    self.current_vote = command_name
    self.title = type(command.display.title) == "function" and command.display.title(initiator_id, params) or command.display.title
    self.initiator_id = initiator_id
    self.is_vote_active = true
    -- Results Setup
    self.vote_results = {}
    self.total_voters = 0
    for _,data in pairs(GetPlayersClientTable()) do
        self.vote_results[data.userid] = {voted = false, vote = command.default_option or 1}
        self.total_voters = self.total_voters + 1
        if checkbit(data.userflags, USERFLAGS.IS_LOADING) then
            self.players_loading[data.userid] = true
        end
    end

    if force_success then
        self:CheckVote(true, true)
    else
        -- Start Vote
        if command.onstartfn then
            command.onstartfn(initiator_id, name, self.vote_results, params)
        end
        self.timeout = command.timeout or TUNING.FORGE.CHAT_VOTE.DEFAULT_TIMEOUT
        self.timer = self.timeout
        self.inst:StartWallUpdatingComponent(self)
        self:SubmitVote(initiator_id, 1) -- Initiator always votes yes
    end
end

function LobbyVote:IsVoter(userid)
    return self.vote_results[userid] ~= nil
end

-- TODO If a player leaves during a vote and joins back before the vote is over, any player that joins between this time will get the vote option after the player that left returns because they force update the vote.
function LobbyVote:SubmitVote(voter_id, vote)
    if self.vote_results[voter_id] and not self.vote_results[voter_id].voted then -- Don't let anyone vote who should not be part of it or has already voted.
        self.vote_results[voter_id].vote = vote
        self.vote_results[voter_id].voted = true
        self:CheckVote()
    end
end
--TheFrontEnd:GetGraphicsOptions:GetFullscreenDisplayRefreshRate()
-- Counts up the results of the current vote if all users have voted or the vote has timed out.
-- A success is determined by majority only. This means that if 2 options of a vote have the same count then the vote will fail.
function LobbyVote:CheckVote(complete, force_success)
    local vote_command = VOTE_COMMANDS[self.current_vote]
    -- Cancel vote if all voters have left the server or the vote failed validation.
    if self.total_voters <= 0 or not self.vote_results or vote_command.validate_vote and not vote_command.validate_vote(params) then
        self:CancelVote()
    else
        local vote_complete = true
        local results = {none = 0, total = 0}
        if not force_success then
            for _,data in pairs(self.vote_results) do
                -- Stop checking vote if not everyone has voted and the vote has not timed out
                if not complete and not data.voted then
                    vote_complete = false
                end
                if not data.voted then
                    results.none = results.none + 1
                end
                results[data.vote] = (results[data.vote] or 0) + 1
                results.total = results.total + 1
            end
            self.current_results_str = SerializeTable(results)
        end

        if not vote_complete then return end

        -- Find the option that had the most votes
        local result = {option = 0, count = 0, tie = false}
        for option,count in pairs(results) do
            if option ~= "none" and option ~= "total" then
                if result.count < count then
                    result.option = option
                    result.count = count
                end
                result.tie = result.option ~= option and result.count == count
            end
        end
        self.result = force_success and 1 or result.tie and 0 or result.option
        if vote_command.oncompletefn.server then
            local world_reset = vote_command.oncompletefn.server(self.result, results, self.vote_params)
            self.world_reset = world_reset ~= nil and world_reset
        end
        self:SetAnnouncement(type(vote_command.display.announcement) == "function" and vote_command.display.announcement(self.result, results, self.vote_params) or vote_command.display.announcement or GetDefaultAnnouncement(self.result))
        self:EndVote()
        if self.world_reset then
            self:WorldReset()
        end
    end
end

-- Ends the Active Vote
function LobbyVote:EndVote()
    self.vote_results = nil
    self.current_results_str = ""
    self.total_voters = 0
    self.vote_params = nil
    self.is_vote_active = false
    self.inst:StopWallUpdatingComponent(self)
end

-- Cancels the current vote and displays an announcement to all users.
function LobbyVote:CancelVote()
    if self:IsVoteActive() then
        self:SetAnnouncement(STRINGS.REFORGED.VOTE.CANCELED)
        self:EndVote()
    end
end

-- Starts the countdown for world reset.
function LobbyVote:WorldReset()
    TheWorld.net.components.worldcharacterselectlobby:CancelForceStart()
    self.timer = 5
    self.inst:StartWallUpdatingComponent(self)
end

function LobbyVote:IsVoteActive()
    return self.is_vote_active
end

function LobbyVote:IsWorldResetting()
    return self.world_reset
end

function LobbyVote:SetAnnouncement(str)
    self.announcement = str
end

local last_tick_seen = -1
local current_tick = 0
local FRAMES_PER_SECOND = 60
-- TODO dt seems to always be 0, would be nice to only do the checks every second instead of every update?
function LobbyVote:OnWallUpdate(dt)
    --local  = self.last_update_time + dt
    if self.timer > 0 then
        current_tick = current_tick + 1
        if current_tick >= FRAMES_PER_SECOND then
            self.timer = self.timer - 1
            current_tick = 0
        end
        -- Check Loading Clients and update their display once they finish loading if they are part of the current vote.
        for userid,_ in pairs(self.players_loading) do
            local is_loading = CheckLoadingClient(userid)
            self.players_loading[userid] = is_loading or nil
            if not is_loading then
                OnClientLoad(TheWorld, userid)
            end
        end
    elseif self.world_reset then
        self.inst:StopWallUpdatingComponent(self)
        _G.COMMON_FNS.ResetWorld()
    else
        self:CheckVote(true)
        current_tick = 0
        self.players_loading = {}
    end
end

return LobbyVote
