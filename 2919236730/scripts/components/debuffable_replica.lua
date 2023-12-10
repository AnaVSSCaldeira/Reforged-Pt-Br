local function OnNewDebuff(inst)
    local debuffable = inst.replica.debuffable
    if debuffable then
        local current_debuffs_str = debuffable:GetCurrentDebuffsStr()
        debuffable.current_debuffs = current_debuffs_str and ConvertStringToTable(current_debuffs_str) or {}
        inst:PushEvent("client_debuffs_update")
    end
end

local Debuffable = Class(function(self, inst)
    self.inst = inst
    self.current_debuffs = {}
    self._current_debuffs_str = net_string(inst.GUID, "debuffable._current_debuffs_str", "newdebuff")
    if not TheNet:IsDedicated() then
        self.inst:ListenForEvent("newdebuff", OnNewDebuff)
    end
end)

function Debuffable:GetCurrentDebuffsStr()
    return self._current_debuffs_str:value()
end

function Debuffable:SetCurrentDebuffsStr(str)
    self._current_debuffs_str:set(str)
end

function Debuffable:GetCurrentDebuffs()
    return self.current_debuffs
end

return Debuffable
