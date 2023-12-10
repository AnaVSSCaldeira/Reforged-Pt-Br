local function RemoveFX(inst, name)
    local fxnetwork = inst.replica.fxnetwork
    -- Check for custom Remove function
    if fxnetwork.tracker[name].RemoveFX then -- This function should always call the original Remove function within it.
        fxnetwork.tracker[name]:RemoveFX()
    else
        fxnetwork.tracker[name]:Remove()
    end
end

local function CreateFX(inst, prefab, name, target, source, persistent)
    local fxnetwork = inst.replica.fxnetwork
    Debug:Print("Creating fx for " .. tostring(prefab) .. "...", "log")
    if PrefabExists(prefab) then
        if true then -- TODO add settings check for client_side_fx
            local fx = SpawnPrefab(prefab)
            if fx.OnSpawn then
                fx:OnSpawn({target = inst, target = target, source = source})
            end
            if persistent then
                -- Remove existing FX with the same name.
                if fxnetwork.tracker[name] then
                    RemoveFX(inst, name)
                end
                -- Start tracking FX
                fxnetwork.tracker[name] = fx
                -- Make sure FX is no longer tracked after being removed
                local _oldRemove = fx.Remove
                fx.Remove = function(fx_inst)
                    fxnetwork.tracker[name] = nil
                    _oldRemove(fx_inst)
                end
            end
        end
        print(" - success!")
    end
end

local function CreateNewFX(inst)
    local fxnetwork = inst.replica.fxnetwork
    CreateFX(inst, fxnetwork:GetFX(), fxnetwork:GetName(), fxnetwork:GetTarget(), fxnetwork:GetSource(), fxnetwork:GetPersistent())
end

local function ForceRemoveFX(inst)
    local fxnetwork = inst.replica.fxnetwork
    local name = fxnetwork:GetFXQueuedForRemoval()
    -- Remove the syncing FX to prevent the FX from being created after it has been removed.
    fxnetwork.sync_fx[name] = nil
    if name and fxnetwork.tracker[name] then
        RemoveFX(inst, name)
    end
end

local function UpdateSyncFX(inst)
    local fxnetwork = inst.replica.fxnetwork
    fxnetwork.sync_fx = ConvertStringToTable(fxnetwork:GetSettingsStr())
end

local function SyncFX(inst)
    local fxnetwork = inst.replica.fxnetwork
    local name = fxnetwork:GetSyncFXName()
    if fxnetwork.sync_fx[name] then
        CreateFX(inst, fxnetwork:GetSyncFXPrefab(), name, fxnetwork:GetSyncFXTarget(), fxnetwork:GetSyncFXSource(), true)
        fxnetwork.sync_fx[name] = nil
    end
end

local FXNetwork = Class(function(self, inst)
    self.inst            = inst
    self.tracker         = {}
    self.removing_fx     = {}
    self.sync_fx         = {}
    self._persistent     = net_bool(inst.GUID, "fxnetwork.persistent")
    self._source         = net_entity(inst.GUID, "fxnetwork.source")
    self._target         = net_entity(inst.GUID, "fxnetwork.target")
    self._fx             = net_string(inst.GUID, "fxnetwork.createfx")--, "createfx")
    self._name           = net_string(inst.GUID, "fxnetwork.name", "createfx")
    self._remove_fx      = net_string(inst.GUID, "fxnetwork.removefx", "removefx")
    self._sync_fx_str    = net_string(inst.GUID, "fxnetwork.syncfxstr", "updatesyncfx")
    self._sync_fx_name   = net_string(inst.GUID, "fxnetwork.syncfxname")
    self._sync_fx_source = net_entity(inst.GUID, "fxnetwork.syncfxsource")
    self._sync_fx_target = net_entity(inst.GUID, "fxnetwork.syncfxtarget")
    self._sync_fx_prefab = net_string(inst.GUID, "fxnetwork.syncfxprefab", "syncfx")
    if not TheNet:IsDedicated() then
        inst:ListenForEvent("createfx", CreateNewFX) -- TODO OnRemove should delete these listeners right? need to see how klei did it on their replicas...
        inst:ListenForEvent("removefx", ForceRemoveFX)
        inst:ListenForEvent("updatesyncfx", UpdateSyncFX)
        inst:ListenForEvent("syncfx", SyncFX)
    end
end)

function FXNetwork:GetSource()
    return self._source:value()
end

function FXNetwork:SetSource(val)
    self._source:set(val)
end

function FXNetwork:GetTarget()
    return self._target:value()
end

function FXNetwork:SetTarget(val)
    self._target:set(val)
end

function FXNetwork:GetFX()
    return self._fx:value()
end

function FXNetwork:SetFX(val)
    self._fx:set_local(val)
    self._fx:set(val)
end

function FXNetwork:GetPersistent()
    return self._persistent:value()
end

function FXNetwork:SetPersistent(val)
    self._persistent:set(val)
end

function FXNetwork:GetName()
    return self._name:value()
end

function FXNetwork:SetName(val)
    self._name:set(val)
end

function FXNetwork:GetFXQueuedForRemoval()
    return self._remove_fx:value()
end

function FXNetwork:QueueFXForRemoval(val)
    self._remove_fx:set_local(val)
    self._remove_fx:set(val)
end

function FXNetwork:GetSyncFX()
    return self._sync_fx_str:value()
end

function FXNetwork:SyncFX(val)
    self._sync_fx_str:set(val)
end

function FXNetwork:GetSyncFXName()
    return self._sync_fx_name:value()
end

function FXNetwork:SyncFXName(val)
    self._sync_fx_name:set(val)
end

function FXNetwork:GetSyncFXSource()
    return self._sync_fx_source:value()
end

function FXNetwork:SyncFXSource(val)
    self._sync_fx_source:set(val)
end

function FXNetwork:GetSyncFXTarget()
    return self._sync_fx_target:value()
end

function FXNetwork:SyncFXTarget(val)
    self._sync_fx_target:set(val)
end

function FXNetwork:GetSyncFXPrefab()
    return self._sync_fx_prefab:value()
end

function FXNetwork:SyncFXPrefab(val)
    self._sync_fx_prefab:set(val)
end

return FXNetwork
