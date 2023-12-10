local function OnMutatorsStr(self, mutators_str)
    self.inst.replica.mutatormanager:SetMutatorsStr(mutators_str)
end

local MutatorManager = Class(function(self, inst)
    self.inst = inst
    self.users_exp = {}
    self.mutators_str = ""
end, nil, {
    mutators_str = OnMutatorsStr,
})

function MutatorManager:UpdateMutators(mutators)
    self.mutators_str = SerializeTable(mutators)
end

return MutatorManager
