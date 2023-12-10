local function OnEventStr(self, event_str)
    self.inst.replica.serverinfomanager:SetEventStr(event_str)
end

local function OnNewsStr(self, news_str)
    self.inst.replica.serverinfomanager:SetNewsStr(news_str)
end

local function OnClientConnect(inst, data)
    local serverinfomanager = inst.net.components.serverinfomanager
    if serverinfomanager then
        serverinfomanager:SyncClient(data.userid)
    end
end

local function OnClientDisconnect(inst, data)
    local serverinfomanager = inst.net.components.serverinfomanager
    if serverinfomanager then
        serverinfomanager:RemoveClientToSync(data.userid)
    end
end

local ServerInfoManager = Class(function(self, inst)
    self.inst = inst
    self.event_str = ""
    self.news_str = ""
    self.sources = {}
    self.sync_info = {}
    self.inst:ListenForEvent("ms_clientauthenticationcomplete", OnClientConnect, TheWorld)
    self.inst:ListenForEvent("ms_clientdisconnected", OnClientDisconnect, TheWorld)

    -- Load strings to sync
    self:LoadStrToSync("reforged_server_event.txt", "event")
    self.inst.replica.serverinfomanager.event_info = self.sources.event or {}
    self.inst.replica.serverinfomanager.complete.event = true
    self:LoadStrToSync("reforged_server_info.txt", "news")
    self.inst.replica.serverinfomanager.news = self.sources.news or {}
    self.inst.replica.serverinfomanager.complete.news = true

    -- Start Syncing to players who are here on load.
    local current_users = {}
    for _,data in pairs(GetPlayersClientTable()) do
        if TheNet:IsDedicated() or TheNet:GetUserID() ~= data.userid then
            current_users[data.userid] = true
        end
    end
    self:SyncClients(current_users)
end, nil, {
    event_str = OnEventStr,
    news_str = OnNewsStr,
})

-- Sometimes lines have the return character at the end of a line, erase it so that it does not mess up spacing.
local function EraseReturnCharactersAtEndOfLine(str_tbl)
    for i,str in pairs(str_tbl) do
        if string.sub(str, -1) == "\r" then
            str_tbl[i] = string.sub(str, 1, string.len(str) - 1)
        end
    end
end

function ServerInfoManager:LoadStrToSync(filename, source_name)
    TheSim:GetPersistentString(filename, function(load_success, file_info)
        if load_success and file_info then
            self.sources[source_name] = ParseString(file_info,"\n")
            EraseReturnCharactersAtEndOfLine(self.sources[source_name])
        else
            Debug:Print("Failed to load file " .. tostring(filename), "warning")
        end
    end)
end

function ServerInfoManager:SyncClient(userid)
    self:SyncClients({[userid] = true})
end

function ServerInfoManager:SyncClients(clients)
    -- Only sync if there is a source to sync
    if next(self.sources) == nil or next(clients) == nil then return end
    for source_name,_ in pairs(self.sources) do
        if self.sync_info[source_name] then
            MergeTable(self.sync_info[source_name].queued_clients, clients)
        else
            self:StartSync(source_name, clients)
        end
    end
end

function ServerInfoManager:HasActiveClients(source_name)
    return self.sync_info[source_name] and next(self.sync_info[source_name].active_clients) ~= nil
end

function ServerInfoManager:HasQueuedClients(source_name)
    return self.sync_info[source_name] and next(self.sync_info[source_name].queued_clients) ~= nil
end

function ServerInfoManager:RemoveClientToSync(userid)
    if next(self.sources) == nil then return end
    for _,info in pairs(self.sync_info) do
        info.active_clients[userid] = nil
        info.queued_clients[userid] = nil
    end
end

local MAX_NET_STRING_LENGTH = 200
local SYNC_DELAY = 10*FRAMES
function ServerInfoManager:SyncNewLine(source_name)
    local sync_info = self.sync_info[source_name]
    local source = self.sources[source_name]
    sync_info.index = (sync_info.index or 0) + 1
    local current_str = source[sync_info.index]
    if string.len(source[sync_info.index]) > MAX_NET_STRING_LENGTH then
        current_str = string.sub(source[sync_info.index], 1, MAX_NET_STRING_LENGTH)
        sync_info.substr_count = 1
    end
    local is_final = #source <= sync_info.index and sync_info.substr_count <= 0
    local prefix = tostring(sync_info.count) .. ":" .. (is_final and "final:" or "") .. "line:"
    self:SetSourceStr(source_name .. "_str", prefix .. current_str)

    return is_final
end

function ServerInfoManager:SyncSplitStr(source_name)
    local sync_info = self.sync_info[source_name]
    local source = self.sources[source_name]
    local current_str = string.sub(source[sync_info.index], MAX_NET_STRING_LENGTH*sync_info.substr_count + 1, MAX_NET_STRING_LENGTH*(sync_info.substr_count + 1))
    local is_line_end = string.len(source[sync_info.index]) <= MAX_NET_STRING_LENGTH * (sync_info.substr_count + 1)
    local is_final = #source >= sync_info.index and is_line_end
    local prefix = tostring(sync_info.count) .. ":" .. (is_final and "final:" or "") .. "str:"
    sync_info.substr_count = is_line_end and 0 or (sync_info.substr_count + 1)
    self:SetSourceStr(source_name .. "_str", prefix .. current_str)

    return is_final
end

function ServerInfoManager:SetSourceStr(source, str)
    if self[source] then
        self[source] = str
    end
end

function ServerInfoManager:SyncNewStr(source_name)
    local sync_info = self.sync_info[source_name]
    local is_final = false
    sync_info.count = (sync_info.count or 0) + 1
    if sync_info.substr_count > 0 then
        is_final = self:SyncSplitStr(source_name)
    else
        is_final = self:SyncNewLine(source_name)
    end

    if not is_final then
        sync_info.timer = SYNC_DELAY
    else
        -- Reset
        sync_info.index = 0
        sync_info.count = 0
        sync_info.substr_count = 0
        -- Check if any users still require the events str
        if next(sync_info.queued_clients) ~= nil then
            sync_info.active_clients = deepcopy(sync_info.queued_clients)
            sync_info.queued_clients = {}
            sync_info.timer = SYNC_DELAY
        else
            sync_info.active_clients = {}
        end
    end
end

function ServerInfoManager:StartSync(source_name, active_clients)
    if self.sources[source_name] == nil or (self.sync_info[source_name] ~= nil and not self.sync_info[source_name].loading_clients) or active_clients == nil or next(active_clients) == nil then return end

    self.sync_info[source_name] = {
        index = 0,
        count = 0,
        substr_count = 0,
        active_clients = active_clients,
        queued_clients = {},
        timer = SYNC_DELAY,
        loading_clients = AreClientsLoading(active_clients),
    }
    self.inst:StartWallUpdatingComponent(self)
end
--
local last_tick_seen = -1
local current_tick = 0
local FRAMES_PER_SECOND = 60
local tick_time = 1/FRAMES_PER_SECOND
function ServerInfoManager:OnWallUpdate(dt)
    local active = false
    local remove_sync = {}
    for source_name,info in pairs(self.sync_info) do
        if info.loading_clients then
            active = true
            self:StartSync(source_name, info.active_clients)
        else
            -- Continue sending
            if self:HasActiveClients(source_name) then
                active = true
                if info.timer > 0 then
                    info.timer = info.timer - tick_time
                else
                    self:SyncNewStr(source_name)
                end
            -- Restart
            elseif self:HasQueuedClients(source_name) then
                self:StartSync(source_name, info.queued_clients)
            else
                table.insert(remove_sync, source_name)
            end
        end
    end
    for _,source_name in pairs(remove_sync) do
        self.sync_info[source_name] = nil
    end
    -- Stop sending
    if not active then
        self.inst:StopWallUpdatingComponent(self)
    end
end

return ServerInfoManager
