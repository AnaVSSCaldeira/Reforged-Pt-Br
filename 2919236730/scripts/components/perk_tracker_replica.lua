local function OnUsersPerk(inst)
    local perk_tracker = inst.replica.perk_tracker
    if perk_tracker then
        local perks_str = perk_tracker:GetUsersCurrentPerksStr()
        perk_tracker.current_perks = perks_str and ConvertStringToTable(perks_str) or {}
    end
end

local PerkTracker = Class(function(self, inst)
    self.inst = inst
    self.current_perks = {}
    self._current_users_perks_str = net_string(inst.GUID, "perktracker._current_users_perks_str", "usersperk")
    if not TheNet:IsDedicated() then
        self.inst:ListenForEvent("usersperk", OnUsersPerk)
    end
end)

function PerkTracker:GetUsersCurrentPerksStr()
    return self._current_users_perks_str:value()
end

function PerkTracker:SetUsersCurrentPerksStr(str)
    self._current_users_perks_str:set(str)
end

function PerkTracker:GetCurrentPerk(userid, force_original)
    return self.current_perks[userid] and (force_original and self.current_perks[userid].original or self.current_perks[userid].current)
end

function PerkTracker:GetCurrentPerkOptions(userid, character, force_original)
    local perk_options = REFORGED_DATA.perks[character] or REFORGED_DATA.perks.generic
    local current_perks = self.current_perks[userid]
    if current_perks == nil then
        Debug:Print("Current Perks for " .. tostring(userid) .. " (" .. tostring(character) ..") does not exist or has not been received.", "warning")
    end
    return current_perks and (perk_options[force_original and current_perks.original or current_perks.current])
end

return PerkTracker
