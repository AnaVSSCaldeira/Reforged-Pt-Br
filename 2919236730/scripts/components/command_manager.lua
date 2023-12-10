local function OnClientConnect(inst, data)
    local command_manager = inst.net.components.command_manager
    if command_manager then
        command_manager:RemoveUser(data.userid)
    end
end

local function OnClientDisconnect(inst, data)
    local command_manager = inst.net.components.command_manager
    if command_manager then
       command_manager:AddUser(data.userid)
    end
end

local CommandManager = Class(function(self, inst)
    self.inst = inst
    self.command_history = {}-- local UserCommands = require "usercommands" UserCommands.RunUserCommand("updateusersfriends", {total_friends = 1}, TheNet:GetClientTableForUser(TheNet:GetUserID()))
    self.cooldown = {updateuserscurrentperk = 1, lobbyvotesubmit = 1, common = 5}
    self.ban_time = (REFORGED_SETTINGS.other.command_spam_ban_time or 1)*60
    self.spam_limit = {updateuserscurrentperk = 10, updateusersfriends = 10, common = 3}
    self.ignored_commands = {pinglocation = true, playerreadytostart = true, lobbyvotestart = true, updateuserscurrentperk = true, updateusersachievements = true}

    self.inst:ListenForEvent("ms_clientauthenticationcomplete", OnClientConnect, TheWorld)
    self.inst:ListenForEvent("ms_clientdisconnected", OnClientDisconnect, TheWorld)
end)

function CommandManager:AddUser(userid)
    self.command_history[userid] = {}
end

function CommandManager:RemoveUser(userid)
    self.command_history[userid] = nil
end

function CommandManager:IsCommandReadyForUser(command_name, userid, conditional_fn)
    local command_info = EnsureTable(self.command_history, userid, command_name)
    local is_ready = self.ignored_commands[command_name] or (GetTimeRealSeconds() - (command_info.time or 0)) > (self.cooldown[command_name] or self.cooldown.common)
    if not is_ready then
        command_info.spam = (command_info.spam or 0) + 1
        if command_info.spam > (self.spam_limit[command_name] or self.spam_limit.common) then
            Debug:Print("User '" .. tostring(userid) .. "' has been banned for " .. tostring(self.ban_time) .. " seconds due to spamming the command '" .. tostring(command_name) .."'", "warning")
            TheNet:BanForTime(userid, self.ban_time)
        end
    end
    if conditional_fn and not conditional_fn(userid) then
        Debug:Print("User '" .. tostring(userid) .. "' has been banned for " .. tostring(self.ban_time) .. " seconds due to attempting to run the command '" .. tostring(command_name) .."' when they shouldn't.", "warning")
        TheNet:BanForTime(userid, self.ban_time)
    end
    return is_ready
end

function CommandManager:UpdateCommandCooldownForUser(command_name, userid, time)
    if self.command_history[userid] then
        EnsureTable(self.command_history, userid, command_name).time = time or GetTimeRealSeconds()
        self.command_history[userid][command_name].spam = 0
    end
end

return CommandManager
