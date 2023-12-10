--[[local function OnLoadedRun(inst)
    local leaderboard_manager = inst.replica.leaderboardmanager
    if leaderboard_manager and not leaderboard_manager.test then
        leaderboard_manager.test = true
        table.insert(leaderboard_manager.loaded_runs, loadstring("return " .. leaderboard_manager:GetLoadedRunStr())())
        print("Added Run...")
        leaderboard_manager.test = false
    else
        print("Cannot add run, busy loading previous run...")
    end
end--]]

local function OnLoadedRuns(inst)
    local leaderboard_manager = inst.replica.leaderboardmanager
    if leaderboard_manager then
        leaderboard_manager.loaded_runs = ConvertStringToTable(leaderboard_manager:GetLoadedRunsStr())
    end
end

local LeaderboardManager = Class(function(self, inst)
    self.inst            = inst
    self.loaded_runs     = {}
    --self.loaded_run_str = net_string(inst.GUID, "leaderboardmanager._loaded_run_str", "loadedrun")
    self.loaded_runs_str = net_string(inst.GUID, "leaderboardmanager._loaded_runs_str", "loadedruns")
    if not TheNet:IsDedicated() then
        self.inst:ListenForEvent("loadedruns", OnLoadedRuns)
        --self.inst:ListenForEvent("loadedrun", OnLoadedRun)
    end
end)
--[[
function LeaderboardManager:GetLoadedRunStr()
    return self.loaded_run_str:value()
end

function LeaderboardManager:SetLoadedRunStr(str)
    self.loaded_run_str:set(str)
end--]]

function LeaderboardManager:GetLoadedRunsStr()
    return self.loaded_runs_str:value()
end

function LeaderboardManager:SetLoadedRunsStr(str)
    self.loaded_runs_str:set(str)
end

function LeaderboardManager:GetLoadedRuns()
    return self.loaded_runs
end

return LeaderboardManager
