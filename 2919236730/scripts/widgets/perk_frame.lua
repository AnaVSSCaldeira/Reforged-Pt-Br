-- Wraps accountitem_frame anim so we can add new layers and they'll be
-- properly hidden and new behaviors will be consistently applied.
local Image = require "widgets/image"
local AccountItemFrame = require "widgets/redux/accountitemframe"

local PerkFrame = Class(AccountItemFrame, function(self)
    AccountItemFrame._ctor(self)

    self.perk_icon = self:AddChild(Image())
end)

function PerkFrame:SetPerk(name, character)
    assert(type(name) == "string", "Need a key suitable for indexing into item tables like MISC_ITEMS.")
    -- When changing the build, the other layers are probably incorrect.
    self:_HideExtraLayers()
    local perk_data = REFORGED_DATA.perks[character] and REFORGED_DATA.perks[character][name]  or REFORGED_DATA.perks.generic[name]
    if character and perk_data then
        self:_SetIcon(perk_data.icon)
    end
    --self:_SetRarity(GetRarityForItem(item_key))
    --self:_SetEventIcon(item_key)
end

function PerkFrame:_SetIcon(icon)
    if icon then
        self.perk_icon:Show()
        self.perk_icon:SetTexture(icon.atlas, icon.tex)
    end
end

function PerkFrame:_SetBuild(build)
    self:GetAnimState():OverrideSkinSymbol("SWAP_ICON", build, "SWAP_ICON")
end

function PerkFrame:_SetEventIcon(item_key)
    local event_icon = GetEventIconForItem(item_key)
    if event_icon ~= nil then
        self:GetAnimState():Show(event_icon)
    end
end

function PerkFrame:_HideExtraLayers()
    self:GetAnimState():Hide("TINT")
    self:GetAnimState():Hide("LOCK")
    self:GetAnimState():Hide("NEW")
    self.age_text:Hide()
    self:GetAnimState():Hide("SELECT")
    self:GetAnimState():Hide("FOCUS")
    self:GetAnimState():Hide("IC_WEAVE")
    for k,_ in pairs(EVENT_ICONS) do
        self:GetAnimState():Hide(k)
    end
    self:GetAnimState():Hide("DLC")
end

function PerkFrame:SetActivityState(is_active, is_unlockable)
    if is_active then
        self:GetAnimState():Show("SELECT")
    else
        self:GetAnimState():Hide("SELECT")
    end
    if is_unlockable then
        self:SetLocked()
    end
end

function PerkFrame:SetBlank()
    AccountItemFrame.SetBlank(self)
    self.perk_icon:Hide()
end

return PerkFrame
