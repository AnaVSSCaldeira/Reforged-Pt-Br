local function CallMutatorFN(inst, mutator_fns, val)
    if _G.TheWorld.ismastersim and mutator_fns then
        if val and mutator_fns.enable_server_fn then
            mutator_fns.enable_server_fn(inst)
        elseif not val and mutator_fns.disable_server_fn then
            mutator_fns.disable_server_fn(inst)
        end
    else
        if val and mutator_fns.enable_client_fn then
            mutator_fns.enable_client_fn(inst)
        elseif not val and mutator_fns.disable_client_fn then
            mutator_fns.disable_client_fn(inst)
        end
    end
end

local function OnMutators(inst)
    local mutator_manager = inst.replica.mutatormanager
    if mutator_manager then
        local mutators = ConvertStringToTable(mutator_manager:GetMutatorsStr())
        local ents = TheSim:FindEntities(0, 0, 0, 255) -- TODO tags?
        -- Save and Apply all changed Mutators
        for mutator,val in pairs(mutators) do
            _G.REFORGED_SETTINGS.gameplay.mutators[mutator] = val
            local mutator_info = _G.REFORGED_DATA.mutators[mutator]
            if mutator_info then
                for _,ent in pairs(ents) do
                    local prefab = ent.prefab
                    if mutator_info.is_valid_fn and mutator_info.is_valid_fn(ent, prefab) then
                        CallMutatorFN(ent, mutator_info.mutator_fns, val)
                    end
                    if mutator_info.prefab_fns and mutator_info.prefab_fns[prefab] then
                        CallMutatorFN(ent, mutator_info.prefab_fns[prefab], val)
                    end
                end
                if mutator_info.reset then -- TODO might not be needed anymore since mutators should be designed to be changed midgame
                    Debug:Print("Mutator '" .. tostring(mutator) .. "' has been enabled midgame, but requires a reset to function properly.", "warning")
                end
            end
        end
        -- Update Mutator Display
        if not _G.TheNet:IsDedicated() and ThePlayer then
            ThePlayer.HUD.controls:BuildMutatorDisplay()
        end
    end
end

local MutatorManager = Class(function(self, inst)
    self.inst          = inst
    self._mutators_str = net_string(inst.GUID, "mutatormanager._mutators_str", "mutators")
    self.inst:ListenForEvent("mutators", OnMutators)
end)

function MutatorManager:GetMutatorsStr()
    return self._mutators_str:value()
end

function MutatorManager:SetMutatorsStr(str)
    self._mutators_str:set(str)
end

return MutatorManager
