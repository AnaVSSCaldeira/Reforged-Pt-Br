local Widget = require "widgets/widget"
local Image = require "widgets/image"

local DebuffDisplay = Class(Widget, function(self, owner, debuffs_per_row, add_icons_top_to_bottom)
    Widget._ctor(self, "DebuffDisplay")
    self.owner = owner
    self.debuffs_per_row = debuffs_per_row or 5
    self.add_icons_top_to_bottom = add_icons_top_to_bottom or add_icons_top_to_bottom == nil -- false means bottom to top
    self.icon_width = 50
    self.icon_height = 50
    self.spacing = 2
    self.icons = {}
    self.target = nil

    self._onclientdebuffdirty = function(inst)
        self:Update()
    end
end)

function DebuffDisplay:Update()
    if self.target and self.target.replica.debuffable then
        local debuffs = self.target.replica.debuffable:GetCurrentDebuffs()
        local count = 0
        local row = 1
        for name,_ in pairs(debuffs) do
            count = count + 1
            row = math.ceil(count/self.debuffs_per_row)
            if not self.icons[count] then
                self.icons[count] = self:AddChild(Image())
            end
            local icon_info = self:GetDebuffIconInfo(name)
            self.icons[count]:SetTexture(icon_info.atlas, icon_info.tex)
            self.icons[count]:SetHoverText(icon_info.hover_text)
            self.icons[count]:SetPosition((((count - 1) % self.debuffs_per_row) + 1 - 1) * (self.icon_width + self.spacing), (row - 1) * (self.icon_height + self.spacing) * (self.add_icons_top_to_bottom and -1 or 1))
            self.icons[count]:Show()
        end
        -- Hide extra icons
        if #self.icons > count then
            for i = count + 1, #self.icons do
                self.icons[i]:Hide()
            end
        end
    end
end

function DebuffDisplay:SetTarget(target, force_update)
    if target and self.target ~= target then
        if self.target ~= nil then
            self.inst:RemoveEventCallback("client_debuffs_update", self._onclientdebuffdirty, self.target)
        end
        self.inst:ListenForEvent("client_debuffs_update", self._onclientdebuffdirty, target) -- TODO does onremove get called on client? if so add it
        self.target = target
        self:Update()
    end
end

function DebuffDisplay:GetDebuffIconInfo(name)
    local icon_info = REFORGED_DATA.debuffs[name] and REFORGED_DATA.debuffs[name].icon or {}
    return {atlas = icon_info.atlas or "images/reforged.xml", tex = icon_info.tex or "unknown_icon.tex", hover_text = STRINGS.REFORGED.DEBUFFS[name] or STRINGS.REFORGED.unknown}
end

return DebuffDisplay
