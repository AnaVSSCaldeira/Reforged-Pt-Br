local PerkFrame = require "widgets/perk_frame"
local Button = require "widgets/button"
local Text = require "widgets/text"
local Image = require "widgets/image"
local ItemImage = require "widgets/redux/itemimage"

-- Expects to be used in a ScrollingList. Call SetItem to populate with data.
local PerkImage = Class(ItemImage, function(self, user_profile, screen, character)
    ItemImage._ctor(self)
    self._base = self._base._base

    self.character = character

    self.frame:KillAllChildren()

    self.frame = self:AddChild(PerkFrame())
    self.frame:MoveToBack()
    self.frame:GetAnimState():SetRayTestOnBB(true);
    self.frame:SetScale(self.image_scale)
end)

function PerkImage:SetPerk(name)
    -- Display an empty frame if there's no data
    if not name then
        self:ClearFrame()
        return
    end

    self.name = name

    --self.rarity = GetRarityForItem( name )
    self.frame:SetPerk(name, self.character)
    --self.frame:SetAge(is_new)
end

function PerkImage:ClearFrame()
    self.frame:SetBlank()
    self.type = nil
    self.name = "empty"
    self.rarity = "common"
end

function PerkImage:ApplyDataToWidget(context, widget_data, data_index)
    local list_widget = self
    local screen = context.screen
    if widget_data then
        list_widget:SetPerk(widget_data.name)
        list_widget:Show()

        if screen and screen.show_hover_text then
            local hover_text = "Item Name Hover"
            list_widget:SetHoverText( hover_text, { font = NEWFONT_OUTLINE, offset_x = 0, offset_y = 60, colour = {1,1,1,1}})
            if list_widget.focus then --make sure we force the hover text to appear on the default focused item
                list_widget:_GainFocus_Internal()
            end
        end
    else
        list_widget:SetPerk(nil)
        if list_widget.focus then --maintain focus on the widget
            list_widget:_GainFocus_Internal()
        end
        if screen and screen.show_hover_text then
            list_widget:ClearHoverText()
        end
    end
end

return PerkImage

