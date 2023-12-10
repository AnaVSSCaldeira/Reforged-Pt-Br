local function OnPlayerSpawn(inst, player)
    local achievement_tracker = inst.components.achievement_tracker
    if achievement_tracker and not achievement_tracker:IsUserTracked(player.userid) then
        achievement_tracker.player_count = achievement_tracker:GetPlayerCount() + 1
    end
end

-- Removes any progress made towards achievements via a disconnected player.
local function OnClientDisconnect(inst, data)
    local achievement_tracker = inst.components.achievement_tracker
    if achievement_tracker and achievement_tracker.achievements and achievement_tracker.achievements[data.userid] then
       achievement_tracker.achievements[data.userid] = nil
    end
end

local AchievementTracker = Class(function(self, inst)
    self.inst = inst
    self:InitialSetup()

    self.inst:ListenForEvent("ms_forge_allplayersspawned", function(inst)
        self:PlayerSetup()

        self.inst:ListenForEvent("ms_playerspawn", OnPlayerSpawn)
    end)
    self.inst:ListenForEvent("ms_clientdisconnected", OnClientDisconnect)
end)

-- Initialize
function AchievementTracker:InitialSetup()
    self.achievements = {}
end

-- Setup each player to start tracking stats
function AchievementTracker:PlayerSetup()
    self.player_count = #AllPlayers
    self:GetAllPlayersData()
    for i,player in pairs(AllPlayers) do
        self:AddAchievementsTrackerToPlayer(player)
    end
end

-- Get all players user info on game start
function AchievementTracker:GetAllPlayersData()
    for i,player in pairs(GetPlayersClientTable()) do
        self.achievements[player.userid] = {}
    end
end

-- Adjust given stat by given number, if given stat is not already tracked then it is created and set to given value.
function AchievementTracker:UpdateAchievementProgress(achievement, userid, unlocked, new_progress, progress_override, force_lock)
    if userid == nil then
        Debug:Print("AchievementTracker - tried to update " .. tostring(achievement) .. " progress but userid is nil.", "error")
        return
    end
    local function UpdateProgress(source)
        if self.achievements[userid][achievement][source] == nil then return end
        local max_progress = REFORGED_DATA.achievements[achievement].max_progress
        local progress = max_progress and (progress_override or ((self.achievements[userid][achievement][source].progress or 0) + (new_progress or 0)))
        local unlocked = unlocked or max_progress and progress >= max_progress
        self.achievements[userid][achievement][source].unlocked = not force_lock and (unlocked or self.achievements[userid][achievement][source].unlocked)
        self.achievements[userid][achievement][source].progress = not force_lock and not unlocked and max_progress and math.min(progress, max_progress) or nil
    end
    if self.achievements[userid] then
        UpdateProgress("server")
        UpdateProgress("client")
    end
end

function AchievementTracker:IsAchievementUnlocked(achievement, userid, is_server)
    return self.achievements[userid][achievement][is_server and "server" or "client"] == nil or self.achievements[userid][achievement][is_server and "server" or "client"].unlocked or false
end

function AchievementTracker:GetAchievementProgress(achievement, userid, is_server)
    return self.achievements[userid][achievement][is_server and "server" or "client"] and self.achievements[userid][achievement][is_server and "server" or "client"].progress or 0
end

function AchievementTracker:IsUserTracked(userid)
    return self.achievements[userid] ~= nil
end

function AchievementTracker:GetPlayerCount()
    return self.player_count
end

function AchievementTracker:GetUsersTrackedAchievements(userid)
    return self.achievements[userid]
end

function AchievementTracker:AddAchievementsTrackerToPlayer(player)
    local players_achievements = self.inst.net.components.achievementmanager:GetUsersAchievements(player.userid) or {}
    for name,info in pairs(REFORGED_DATA.achievements) do
        local server_info = players_achievements.server and players_achievements.server[name] or {}
        local client_info = players_achievements.client and players_achievements.client[name] or {}
        if not (server_info.unlocked and client_info.unlocked) and self:CheckRequirementsForAchievement(name, player) and (not info.valid_fn or info.valid_fn(player)) then
            self.achievements[player.userid][name] = {server = not server_info.unlocked and {unlocked = server_info.unlocked or false, progress = server_info.progress or 0} or nil, client = not client_info.unlocked and {unlocked = client_info.unlocked or false, progress = client_info.progress or 0} or nil}
            if info.track_fn then
                info.track_fn(self, player, name, server_info.progress, client_info.progress)
            end
        end
    end
end

local function HasRequirement(requirements, val)
    --print("checking req...")
    for _,req in pairs(requirements) do
        --print("- req: " .. tostring(req))
        --print("- val: " .. tostring(val))
        if req == val then
            --print("- success")
            return true
        end
    end
    --print("- failed")
    return false
end
-- Returns true if all the given achievements requirements match the current settings.
-- Ignores requirements that have nil values not including mutators.
-- Mutator values that are not given will check to see if they have default value.
-- "ignore_mutators" will ignore all mutator settings that were not given as a requirement.
function AchievementTracker:CheckRequirementsForAchievement(name, player)
    local settings_key = {difficulty = "difficulties", gametype = "gametypes", map = "maps", mode = "modes", mutators = "mutators", preset = "presets", waveset = "wavesets"}
    --print("Checking Requirements for " .. tostring(name))
    local requirements = REFORGED_DATA.achievements[name].requirements
    if requirements.player_count and requirements.player_count < TheWorld.components.stat_tracker:GetTotalActivePlayerCount() or #requirements.presets > 0 and not HasRequirement(requirements.presets, REFORGED_SETTINGS.gameplay.preset) or #requirements.characters > 0 and not HasRequirement(requirements.characters, player.prefab) then
        return false
    -- Check settings if no preset is required.
    elseif #requirements.presets <= 0 then
        --print("Checking Gameplay Settings...")
        for setting,val in pairs(REFORGED_SETTINGS.gameplay) do
            --print("setting: " .. tostring(setting))
            --print("val: " .. tostring(val))
            if setting == "mutators" then
                local ignore_mutators = type(requirements.mutators) ~= "table" and requirements.mutators ~= nil -- Setting the mutator requirements to anything but a table of mutators will set it to ignore all mutator values.
                if not ignore_mutators then
                    for mutator,value in pairs(val) do
                        local values_match = requirements.mutators[mutator] and requirements.mutators[mutator] == value or nil
                        if requirements.mutators[mutator] ~= nil and not values_match or type(value) == "number" and REFORGED_DATA.mutators[mutator].default_value > value then
                            --print("- requirement failed")
                            --print("- - " .. tostring(mutator) .. ": " .. tostring(value))
                            return false
                        end
                    end
                end
            elseif requirements[settings_key[setting]] and #requirements[settings_key[setting]] > 0 and not HasRequirement(requirements[settings_key[setting]], val) then
                --print("- requirement failed")
                --print("- - " .. tostring(setting) .. ": " .. tostring(val))
                return false
            end
        end
    end
    --print("- requirements are met, tracking achievement " .. tostring(name))
    return true
end

return AchievementTracker
