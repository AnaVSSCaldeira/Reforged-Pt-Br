local function OnSyncStr(self, source, str, source_tbl)
    if str == "" or source_tbl == nil or self.complete[source] then return end
    if self.sync_info[source] == nil then
        self.sync_info[source] = {}
    end
    local sync_info = self.sync_info[source]
    -- Start of sources data
    if sync_info.str_count == nil then
        TheWorld:PushEvent("syncing_server_info", {source = source})
    end
    sync_info.str_count = sync_info.str_count or 0
    local parse_info = {}
    local parsed = false
    local index = 0
    local event_index = 0
    local current_str = ""
    while not parsed do
        index = index + 1
        local current_char = string.sub(str, index, index)
        if current_char == ":" then
            if parse_info.index == nil then
                parse_info.index = tonumber(current_str)
                -- Reset Sync information and source if corruption detected.
                if (sync_info.str_count + 1) ~= parse_info.index then
                    -- Raise error if index is ahead of current count and reset all syncing info due to corruption. If index is behind, then wait until it catches up.
                    if (sync_info.str_count + 1) < parse_info.index then
                        Debug:Print("Communication between server and client interrupted. Server Events String is now corrupted and will not display properly.", "error")
                        self.sync_info[source] = {}
                        source_tbl = {}
                    end
                    return
                else
                    sync_info.str_count = sync_info.str_count + 1
                end
            elseif parse_info.type == nil then
                -- Complete
                if current_str == "final" then
                    parse_info.is_final = true
                    self.sync_info[source] = {}
                    self.complete[source] = true
                else
                    parse_info.type = current_str
                    parsed = true
                end
            end
            current_str = ""
        else
            current_str = current_str .. current_char
        end
    end
    local update_str = string.sub(str, index + 1)
    if parse_info.type == "str" then
        source_tbl[#source_tbl] = source_tbl[#source_tbl] .. update_str
    else
        table.insert(source_tbl, update_str)
    end
    if self.complete[source] then
        TheWorld:PushEvent("new_server_info", {source = source})
    end
end

local ServerInfoManager = Class(function(self, inst)
    self.inst = inst
    self.complete   = {}
    self.sync_info  = {}
    self.event      = {}
    self.news       = {}
    self._event_str = net_string(inst.GUID, "serverinfomanager._event_str", "sync_event_str")
    self._news_str  = net_string(inst.GUID, "serverinfomanager._news_str", "sync_news_str")
    if not TheWorld.ismastersim then
        self.inst:ListenForEvent("sync_event_str", function()
            OnSyncStr(self, "event", self._event_str:value(), self.event)
        end)
        self.inst:ListenForEvent("sync_news_str", function()
            OnSyncStr(self, "news", self._news_str:value(), self.news)
        end)
    end
end)

function ServerInfoManager:GetTitle()
    return self._title:value()
end

function ServerInfoManager:SetTitle(val)
    self._title:set(val)
end

function ServerInfoManager:GetEventStr()
    return self._event_str:value()
end

function ServerInfoManager:SetEventStr(val)
    self._event_str:set_local(val)
    self._event_str:set(val)
end

function ServerInfoManager:GetEventInfo()
    return self.event
end

function ServerInfoManager:GetNewsStr()
    return self._news_str:value()
end

function ServerInfoManager:SetNewsStr(val)
    self._news_str:set_local(val)
    self._news_str:set(val)
end

function ServerInfoManager:GetNews()
    return self.news
end

function ServerInfoManager:IsEventSyncing()
    return self.sync_info.event.str_count ~= nil
end

function ServerInfoManager:IsNewsSyncing()
    return self.sync_info.news.str_count ~= nil
end

function ServerInfoManager:IsSyncing(source)
    return self.sync_info[source] and self.sync_info[source].str_count ~= nil
end

function ServerInfoManager:HasEvent()
    return self.complete.event
end

function ServerInfoManager:HasNews()
    return self.complete.news
end

function ServerInfoManager:HasInfo(source)
    return self.complete[source]
end

function ServerInfoManager:GetInfo(source)
    return self[source]
end

return ServerInfoManager
