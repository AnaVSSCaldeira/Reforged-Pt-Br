local UserCommands = require "usercommands"
local function OnUsersAchievements(inst)
    local achievement_manager = inst.replica.achievementmanager
    if achievement_manager then
        local achievements_str = achievement_manager:GetUsersAchievementsStr()
        local achievements_data = achievements_str and ConvertStringToTable(achievements_str) or {}
        if achievements_data.userid == TheNet:GetUserID() then
            achievement_manager.users_achievements.server = achievements_data.achievements
        end
    end
end

local AchievementManager = Class(function(self, inst)
    self.inst = inst
    self.users_achievements = {client = {}, server = {}}
    self._users_achievements_str = net_string(inst.GUID, "achievementmanager._users_achievements_str", "usersachievements")
    if not TheNet:IsDedicated() then
        self.inst:ListenForEvent("usersachievements", OnUsersAchievements)
        self:Initialize()
    end
end)

function AchievementManager:Initialize()
    local player_achievements = Settings.match_results.wxp_data and Settings.match_results.wxp_data[TheNet:GetUserID()] and Settings.match_results.wxp_data[TheNet:GetUserID()].details or {}
    TheSim:GetPersistentString("reforged_achievements", function(load_success, data)
        local achievements = {}
        if data then
            local status, old_achievements = pcall( function() return json.decode(data) end )
            if status and old_achievements then
                achievements = old_achievements
            else
                Debug:Print("Failed to retrieve clients achievements!", "warning")
            end
        end

        local should_update_file = false
        -- TODO remove this when reenabled
        if achievements.low_team_damage then
            achievements.low_team_damage = nil
            should_update_file = true
        end

        -- Save new achievements to players achievements log.
        if player_achievements then
            -- Update any achievements that have more progress than before.
            for _,detail in pairs(player_achievements or {}) do
                local name = detail.name
                local client_info = detail.client
                -- Only check client achievement progress
                if name and client_info then
                    -- Only update if achievement has new progress
                    if achievements[name] and not achievements[name].unlocked and (client_info.unlocked or (achievements.progress or 0) < (client_info.progress or 0)) or achievements[name] == nil then
                        achievements[name] = {unlocked = client_info.unlocked, progress = client_info.progress, date = client_info.unlocked and os.date("%x"), time = client_info.unlocked and os.date("%X")}
                        should_update_file = true
                    end
                end
            end
            if should_update_file then
                --Debug:PrintTable(achievements)
                TheSim:SetPersistentString("reforged_achievements", json.encode(achievements), false, function() Debug:Print("Achievements Progress Saved", "log") end)
            end
        --TODO remove this when reenabled
        elseif should_update_file then
            TheSim:SetPersistentString("reforged_achievements", json.encode(achievements), false, function() Debug:Print("Achievements Progress Saved", "log") end)
        end
        if not REFORGED_SETTINGS.display.server_achievements then
            self.users_achievements.client = achievements
        end
        -- Send client achievements so that the server can accurately track them.
        local client_achievements = {}
        for name,data in pairs(achievements) do
            client_achievements[name] = data.unlocked or data.progress
        end
        UserCommands.RunUserCommand("updateusersachievements", {achievements = SerializeTable(client_achievements)}, TheNet:GetClientTableForUser(TheNet:GetUserID()))
    end)
end

function AchievementManager:GetUsersAchievementsStr()
    return self._users_achievements_str:value()
end

function AchievementManager:SetUsersAchievementsStr(str)
    self._users_achievements_str:set(str)
end

function AchievementManager:GetUsersAchievements(is_server)
    return self.users_achievements and self.users_achievements[is_server and "server" or "client"] or {}
end

function AchievementManager:GetUsersAchievement(achievement, is_server)
    local achievements = self:GetUsersAchievements(is_server)
    return achievements and achievements[achievement]
end

return AchievementManager
