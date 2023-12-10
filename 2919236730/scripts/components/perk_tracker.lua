local function OnUsersCurrentPerksStr(self, users_current_perks_str)
    self.inst.replica.perk_tracker:SetUsersCurrentPerksStr(users_current_perks_str)
end

local PerkTracker = Class(function(self, inst)
    self.inst = inst
    self.current_perks = {}
    self.users_current_perks_str = ""
end, nil, {
    users_current_perks_str = OnUsersCurrentPerksStr,
})

function PerkTracker:SetCurrentPerk(userid, current, original)
    if not userid then return end
    self.current_perks[userid] = {current = current, original = original}
    self.users_current_perks_str = SerializeTable(self.current_perks)
end

function PerkTracker:GetCurrentPerk(userid, force_original)
    return self.current_perks[userid] and (force_original and self.current_perks[userid].original or self.current_perks[userid].current)
end

function PerkTracker:GetCurrentPerkOptions(userid, character, force_original)
    local perk_options = REFORGED_DATA.perks[character] or REFORGED_DATA.perks.generic
    local perk = self.current_perks[userid] and (force_original and self.current_perks[userid].original or self.current_perks[userid].current)
    return perk and perk_options[perk]
end

return PerkTracker
