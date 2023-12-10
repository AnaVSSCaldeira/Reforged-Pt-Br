local function OnUsersAchievementsStr(self, users_achievements_str)
    self.inst.replica.achievementmanager:SetUsersAchievementsStr(users_achievements_str)
end

local function OnClientConnect(inst, data)
    local achievementmanager = inst.net.components.achievementmanager
    if achievementmanager then
        achievementmanager.users_achievements[data.userid] = {}
        achievementmanager:RetrieveUserServerAchievements(data.userid)
    end
end

-- Removes the disconnected player from the achievements list
local function OnClientDisconnect(inst, data) -- TODO
    local achievementmanager = inst.net.components.achievementmanager
    if achievementmanager and achievementmanager.users_achievements[data.userid] then
       achievementmanager.users_achievements[data.userid] = nil
       achievementmanager.users_retrieved[data.userid] = nil
    end
end

local AchievementManager = Class(function(self, inst)
    self.inst = inst
    self.syncing = false
    self.sync_delay = 180*FRAMES
    self.achievements_queue = {}
    self.users_achievements = {}
    self.users_achievements_str = ""
    self.users_retrieved = {}
    self.inst:ListenForEvent("ms_clientauthenticationcomplete", OnClientConnect, TheWorld)
    self.inst:ListenForEvent("ms_clientdisconnected", OnClientDisconnect, TheWorld)

    self:Initialize()
end, nil, {
    users_achievements_str = OnUsersAchievementsStr,
})

function AchievementManager:Initialize()
    local current_users = GetPlayerClientTable()
    local users_achievements = {}
    for _,data in pairs(current_users) do
        users_achievements[data.userid] = {}
    end

    local new_users_achievements = Settings.match_results.wxp_data or {}
    TheSim:GetPersistentString("reforged_achievements_server", function(load_success, data)
        local achievements = {}
        if data then
            local status, old_achievements = pcall( function() return json.decode(data) end )
            if status and old_achievements then
                achievements = old_achievements
            else
                Debug:Print("Failed to retrieve servers achievements!", "warning")
            end
        end
        local should_update_file = false
        for userid,info in pairs(achievements) do
            -- TODO remove this when reenabled
            if achievements[userid].low_team_damage then
                achievements[userid].low_team_damage = nil
                should_update_file = true
            end
        end
        -- Update servers achievements file with the new achievements earned.
        if new_users_achievements then
            for userid,exp_info in pairs(new_users_achievements) do
                if not achievements[userid] then
                    achievements[userid] = {}
                end
                for _,detail in pairs(exp_info.details or {}) do
                    local name = detail.name
                    local server_info = detail.server
                    -- Only check server achievement progress
                    if name and server_info then
                        -- Only update if achievement has new progress
                        if achievements[userid][name] and not achievements[userid][name].unlocked and (server_info.unlocked or (achievements.progress or 0) < (server_info.progress or 0)) or achievements[userid][name] == nil then
                            achievements[userid][name] = {unlocked = server_info.unlocked, progress = server_info.progress, date = server_info.unlocked and os.date("%x") or nil, time = server_info.unlocked and os.date("%X") or nil}
                            should_update_file = true
                        end
                    end
                end
            end
            TheSim:SetPersistentString("reforged_achievements_server", json.encode(achievements), false, function() Debug:Print("Achievements Progress Saved", "log") end)
        -- TODO remove this when reenabled
        elseif should_update_file then
            TheSim:SetPersistentString("reforged_achievements_server", json.encode(achievements), false, function() Debug:Print("Achievements Progress Saved", "log") end)
        end
        -- Set each users server achievement for displaying
        for userid,info in pairs(users_achievements) do
            users_achievements[userid].server = achievements[userid] or {}
        end
    end)
    self.users_achievements = users_achievements
    if REFORGED_SETTINGS.display.server_achievements then
        for userid,info in pairs(self.users_achievements) do
            self:UpdateAchievementQueue(userid, info.server)
        end
    end
end

function AchievementManager:GetUsersAchievements(userid)
    return self.users_achievements[userid] or {}
end

function AchievementManager:AreUsersQueued()
    return next(self.achievements_queue) ~= nil
end

function AchievementManager:UpdateUsersClientAchievements(userid, achievements)
    EnsureTable(self.users_achievements, userid).client = {}
    for name,val in pairs(achievements or {}) do
        self.users_achievements[userid].client[name] = {unlocked = val == true, progress = val ~= true and val}
    end
    self.users_retrieved[userid] = true
    --self.users_achievements_str = SerializeTable(self.users_achievements) -- TODO technically don't need to sync client achievements?
end

-- Retrieves the given users server exp directly from file.
function AchievementManager:RetrieveUserServerAchievements(userid)
    TheSim:GetPersistentString("reforged_achievements_server", function(load_success, data)
        local achievements = {}
        if data then
            local status, old_achievements = pcall( function() return json.decode(data) end )
            if status and old_achievements then
                achievements = old_achievements
            else
                Debug:Print("Failed to retrieve Achievements!", "warning")
            end
        end
        EnsureTable(self.users_achievements, userid).server = achievements[userid] or {}
        if REFORGED_SETTINGS.display.server_achievements then
            self:UpdateAchievementQueue(userid, achievements[userid])
        end
    end)
end

function AchievementManager:SyncClient()
    if #self.achievements_queue > 0 then
        local current_achievements = table.remove(self.achievements_queue, 1)
        while(not self.users_achievements[current_achievements.userid] and #self.achievements_queue > 0) do
            current_achievements = table.remove(self.achievements_queue, 1)
        end
        -- Only sync achievements to users who are still in the lobby
        if self.users_achievements[current_achievements.userid] then
            self.users_achievements_str = SerializeTable(current_achievements)
            self.timer = self.sync_delay
        else
            self.syncing = false
        end
    else
        self.syncing = false
    end
end

function AchievementManager:UpdateAchievementQueue(userid, achievements)
    table.insert(self.achievements_queue, {userid = userid, achievements = achievements})
    if not self.syncing then
        self.syncing = true
        --self:SyncClient()
        self.timer = self.sync_delay
        self.inst:StartWallUpdatingComponent(self)
    end
end

local last_tick_seen = -1
local current_tick = 0
local FRAMES_PER_SECOND = 60
local tick_time = 1/FRAMES_PER_SECOND
function AchievementManager:OnWallUpdate(dt)
    if self.syncing then
        if self.timer > 0 then
            self.timer = self.timer - tick_time
        else
            self:SyncClient()
        end
    else
        self.inst:StopWallUpdatingComponent(self)
    end
end

return AchievementManager
