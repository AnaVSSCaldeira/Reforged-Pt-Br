local UserCommands = require "usercommands"
local function OnUsersExp(inst)
    local level_manager = inst.replica.levelmanager
    if level_manager then
        local exp_str = level_manager:GetUsersExpStr()
        level_manager.users_exp = exp_str and ConvertStringToTable(exp_str) or {}
        level_manager:UpdateUsersLevels()
    end
end

local LevelManager = Class(function(self, inst)
    self.inst           = inst
    self.users_exp      = {}
    self.users_levels   = {}
    self._users_exp_str = net_string(inst.GUID, "levelmanager._users_exp_str", "usersexp")
    if not TheNet:IsDedicated() then
        self.inst:ListenForEvent("usersexp", OnUsersExp)
        self:Initialize()
    end
end)

local function AddNewRunToExpLog(exp_history, exp_info)
    local new_run = {
        new_xp = exp_info.new_xp,
        match_xp = exp_info.match_xp,
        details = {},
        character = exp_info.character,
    }
    -- Only save the description and value of each detail
    for _,detail in pairs(exp_info.details) do
        table.insert(new_run.details, {desc = detail.desc, val = detail.val})
    end
    if not exp_history.total_exp then
        exp_history.total_exp = {}
    end
    exp_history.total_exp.overall = new_run.new_xp
    if new_run.character == "" then new_run.character = "unknown" end -- Blank strings break stuff
    exp_history.total_exp[new_run.character] = (exp_history.total_exp[new_run.character] or 0) + new_run.match_xp
    table.insert(exp_history.runs, new_run)
end

local HAVE_MAX_EXP = false
local MAX_MATCH_EXP = 150000 -- Adjust if needed
local MAX_OVERALL_EXP_DIFFERENCE = 100000
-- Validate Exp History
local function CheckExp(exp_history)
    if not HAVE_MAX_EXP then return end
    local total_exp = {overall = 0}
    local complete = false
    while not complete do
        complete = true
        total_exp = {overall = 0}
        for index,run in pairs(exp_history.runs) do
            total_exp[run.character] = (total_exp[run.character] or 0) + run.match_xp
            total_exp.overall = total_exp.overall + run.match_xp
            if run.match_xp >= MAX_MATCH_EXP then
                --return true
                Debug:Print("Removed run at index " .. tostring(index) .. ". Exp: " .. tostring(run.match_xp), "note")
                table.remove(exp_history.runs, index)
                complete = false
            end
        end
    end
    --print("Actual: ")
    --Debug:PrintTable(total_exp, 3)
    --print("Recorded: ")
    --Debug:PrintTable(exp_history.total_exp, 3)
    --print("DIFFERENCE: " .. tostring(math.abs(total_exp.overall - exp_history.total_exp.overall)))
    if math.abs(total_exp.overall - exp_history.total_exp.overall) > MAX_OVERALL_EXP_DIFFERENCE then
        Debug:Print("Invalid overall exp. Applying correct overall experience...", "warning")
        --exp_history.total_exp = total_exp
    end
    return false
end

local total_invalid_exp = {overall = -1}
for name,_ in pairs(STRINGS.CHARACTER_NAMES) do
    if not (name == "random" or name == "unknown") then
        total_invalid_exp[name] = -1
    end
end
function LevelManager:Initialize()
    local player_exp_info = deepcopy(Settings.match_results.wxp_data and Settings.match_results.wxp_data[TheNet:GetUserID()])
    local invalid_exp = false
    TheSim:GetPersistentString("reforged_exp", function(load_success, data)
        local exp_history = {runs = {}, total_exp = {}}
        if data then
            local status, old_exp_history = pcall( function() return json.decode(data) end )
            if status and exp_history then
                exp_history = old_exp_history
                invalid_exp = CheckExp(exp_history)
                if invalid_exp then -- TODO
                    Debug:Print("You are a cheater!", "warning")
                end
            else
                Debug:Print("Failed to retrieve exp history!", "warning")
            end
        end
        -- Save new exp to players exp log.
        if player_exp_info then
            local achievement_exp = 0
            for _,detail in pairs(player_exp_info.details or {}) do
                local name = detail.name
                local client_info = detail.client
                -- Only check server achievement progress
                achievement_exp = achievement_exp + (name and client_info and client_info.exp or 0)
            end
            player_exp_info.new_xp = player_exp_info.new_xp + achievement_exp
            player_exp_info.match_xp = player_exp_info.match_xp + achievement_exp
            local current_new_xp = player_exp_info.new_xp
            player_exp_info.new_xp = (exp_history.total_exp and exp_history.total_exp.overall or 0) + (player_exp_info.match_xp or 0) -- make sure new exp represents the clients total exp.
            AddNewRunToExpLog(exp_history, player_exp_info)
            TheSim:SetPersistentString("reforged_exp", json.encode(exp_history), false, function() Debug:Print("Experience Updated", "log") end)
            player_exp_info.new_xp = current_new_xp -- Revert back to current exp
        end
        -- Only send client exp if the server has it enabled.
        if not REFORGED_SETTINGS.display.server_level then
            UserCommands.RunUserCommand("updateuserexp", { total_exp = SerializeTable(invalid_exp and total_invalid_exp or exp_history.total_exp) }, TheNet:GetClientTableForUser(TheNet:GetUserID()))
        end
    end)
end

function LevelManager:GetUsersExpStr()
    return self._users_exp_str:value()
end

function LevelManager:SetUsersExpStr(str)
    self._users_exp_str:set(str)
end

function LevelManager:GetUsersExp(userid, character)
    local type = character or "overall"
    return self.users_exp[userid] and self.users_exp[userid][type] or 0
end

function LevelManager:UpdateUsersLevels()
    local users_levels = {}
    for userid,exp_info in pairs(self.users_exp) do
        users_levels[userid] = {}
        for type,exp in pairs(exp_info) do
            users_levels[userid][type] = wxputils.GetLevelForWXP(exp)
        end
    end
    self.users_levels = users_levels
end

function LevelManager:GetUsersLevel(userid, character)
    local type = character or "overall"
    return self.users_levels[userid] and self.users_levels[userid][type] or 1
end

return LevelManager
