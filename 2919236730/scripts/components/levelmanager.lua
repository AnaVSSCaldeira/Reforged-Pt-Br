local CURRENT_CAP = 999999999
local function OnUsersExpStr(self, users_exp_str)
    self.inst.replica.levelmanager:SetUsersExpStr(users_exp_str)
end

local function OnClientConnect(inst, data)
    local levelmanager = inst.net.components.levelmanager
    if levelmanager then
        levelmanager:RetrieveUserServerExp(data.userid)
    end
end

-- Removes the disconnected player from the exp list
local function OnClientDisconnect(inst, data)
    local levelmanager = inst.net.components.levelmanager
    if levelmanager and levelmanager.users_exp[data.userid] then
       levelmanager.users_exp[data.userid] = nil
       levelmanager.users_retrieved[data.userid] = nil
    end
end

local LevelManager = Class(function(self, inst)
    self.inst = inst
    self.users_exp = {}
    self.users_exp_str = ""
    self.users_retrieved = {}
    self.inst:ListenForEvent("ms_clientauthenticationcomplete", OnClientConnect, TheWorld)
    self.inst:ListenForEvent("ms_clientdisconnected", OnClientDisconnect, TheWorld)

    self:Initialize()
end, nil, {
    users_exp_str = OnUsersExpStr,
})

local function AddNewRunToExpLog(exp_history, exp_info)
    if not exp_history.total_exp then
        exp_history.total_exp = {}
    end
    exp_history.total_exp.overall = exp_info.new_xp
    if exp_info.character == "" then exp_info.character = "unknown" end -- Blank strings break stuff
    exp_history.total_exp[exp_info.character] = (exp_history.total_exp[exp_info.character] or 0) + exp_info.match_xp
end

local function CheckTotalExp(total_exp, userid)
    if total_exp == nil or type(total_exp) ~= "table" then
        Debug:Print(tostring(userid) .. " has a corrupt exp values with a value of '" .. tostring(total_exp) .. "' (" .. tostring(type(total_exp)) .. ")", "warning")
        total_exp = {overall = 0}
    else
        total_exp.overall = total_exp.overall or 0
        for source,exp in pairs(total_exp) do
            if type(exp) == "number" then
                total_exp[source] = exp > CURRENT_CAP and -1 or exp
            else
                Debug:Print(tostring(userid) .. " has a corrupt exp value for '" .. tostring(source) .. "' with a value of '" .. tostring(exp) .. "' (" .. tostring(type(exp)) .. ")", "warning")
            end
        end
    end
    return total_exp
end

function LevelManager:Initialize()
    local current_users = GetPlayerClientTable()
    local users_exp = {}
    for _,data in pairs(current_users) do
        users_exp[data.userid] = {overall = 1}
    end

    local users_exp_info = deepcopy(Settings.match_results.wxp_data)
    TheSim:GetPersistentString("reforged_exp_server", function(load_success, data)
        local exp_history = {}
        if data then
            local status, old_exp_history = pcall( function() return json.decode(data) end )
            if status and exp_history then
                exp_history = old_exp_history
            else
                Debug:Print("Failed to retrieve exp history!", "warning")
            end
        end

        -- Update servers exp file with the new exp
        if users_exp_info then
            for userid,exp_info in pairs(users_exp_info) do
                if not exp_history[userid] then
                    exp_history[userid] = {runs = {}, total_exp = {}}
                end
                local achievement_exp = 0
                for _,detail in pairs(exp_info.details) do
                    local name = detail.name
                    local server_info = detail.server
                    -- Only check server achievement progress
                    achievement_exp = achievement_exp + (name and server_info and server_info.exp or 0)
                end
                exp_info.new_xp = exp_info.new_xp + achievement_exp
                exp_info.match_xp = exp_info.match_xp + achievement_exp
                local current_new_xp = exp_info.new_xp
                exp_info.new_xp = (exp_history[userid].total_exp and exp_history[userid].total_exp.overall or 0) + exp_info.match_xp -- make sure new exp represents the servers total exp.
                AddNewRunToExpLog(exp_history[userid], exp_info)
                exp_info.new_xp = current_new_xp -- Revert the exp value back
                if not REFORGED_SETTINGS.display.server_level then
                    users_exp[userid] = CheckTotalExp({overall = exp_info.new_xp}, userid)
                end
            end
            TheSim:SetPersistentString("reforged_exp_server", json.encode(exp_history), false, function() Debug:Print("Experience Updated", "log") end)
        end
        -- Only retrieve server exp if the server has it enabled.
        if REFORGED_SETTINGS.display.server_level then
            -- Set each users server experience for displaying
            for userid,info in pairs(users_exp) do
                users_exp[userid] = CheckTotalExp(exp_history[userid] and exp_history[userid].total_exp or {overall = 1}, userid)
            end
        else

        end
    end)
    self.users_exp = users_exp
    self.users_exp_str = SerializeTable(self.users_exp)
end

function LevelManager:GetUsersExp(userid, character)
    local type = character or "overall"
    return self.users_exp[userid] and ((self.users_exp[userid][type] or 0) <= CURRENT_CAP and self.users_exp[userid][type] or (self.users_exp[userid][type] or 0) > CURRENT_CAP and -1) or 0
end

function LevelManager:UpdateUserExp(userid, total_exp)
    if Settings.match_results.wxp_data and Settings.match_results.wxp_data[userid] and Settings.match_results.wxp_data[userid].new_xp and total_exp and total_exp.overall and Settings.match_results.wxp_data[userid].new_xp > total_exp.overall then
        local player_name = userid
        for _,player in pairs(GetPlayerClientTable() or {}) do
            if userid == player.userid then
                player_name = player.name
                break
            end
        end
        Debug:Print("User '" .. tostring(player_name) .. "' (" .. tostring(userid) .. ") has attempted to send invalid experience data and will be ignored.", "warning")
        self.users_exp[userid] = CheckTotalExp({overall = -1}, userid)
    else
        self.users_exp[userid] = CheckTotalExp(total_exp, userid)
    end
    self.users_exp_str = SerializeTable(self.users_exp)
    self.users_retrieved[userid] = true
end

-- Retrieves the given users server exp directly from file.
function LevelManager:RetrieveUserServerExp(userid)
    if REFORGED_SETTINGS.display.server_level then
        local users_exp_info = Settings.match_results.wxp_data
        TheSim:GetPersistentString("reforged_exp_server", function(load_success, data)
            local exp_history = {}
            if data then
                local status, old_exp_history = pcall( function() return json.decode(data) end )
                if status and exp_history then
                    exp_history = old_exp_history
                else
                    Debug:Print("Failed to retrieve exp history!", "warning")
                end
            end
            self.users_exp[userid] = CheckTotalExp(exp_history[userid] and exp_history[userid].total_exp or {overall = 1}, userid)
            self.users_exp_str = SerializeTable(self.users_exp)
        end)
    end
end

return LevelManager
