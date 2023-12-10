-- Wraps accountitem_frame anim so we can add new layers and they'll be
-- properly hidden and new behaviors will be consistently applied.
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"

local AchievementFrame = Class(ImageButton, function(self, atlas, normal, focus, disabled, down, selected, scale, offset)
    ImageButton._ctor(self, atlas or "images/rf_achievements.xml", normal or "ach_empty.tex", focus, disabled, down, selected, scale, offset)

    --self.icon = self.image:AddChild(Image())
    self.frame           = self.image:AddChild(Image())
    self.selection_frame = self.image:AddChild(Image("images/rf_achievements.xml", "ach_selection.tex"))
    self.selection_frame:Hide()
    self.mod_source_icon = self.image:AddChild(Image()) -- TODO
    self.mod_source_icon:SetPosition(-40, 40)
    self.mod_source_icon:SetScale(0.3,0.3)
    self.lock            = self.image:AddChild(Image("images/rf_achievements.xml", "ach_lock.tex"))
    self.lock:SetPosition(-40, -40)
    self.rarity_icons = {
        classy        = {atlas = "images/rf_achievements.xml", tex = "ach_frame_classy.tex"},
        common        = {atlas = "images/rf_achievements.xml", tex = "ach_frame_common.tex"},
        distinguished = {atlas = "images/rf_achievements.xml", tex = "ach_frame_distinguished.tex"},
        elegant       = {atlas = "images/rf_achievements.xml", tex = "ach_frame_elegant.tex"},
        spiffy        = {atlas = "images/rf_achievements.xml", tex = "ach_frame_spiffy.tex"},
    }
    self.is_active = false
end)

local tiers = {"common", "classy", "spiffy", "distinguished", "elegant", "loyal", "timeless", "event"}
function AchievementFrame:SetAchievement(name, is_unlocked, force_texture)
    local achievement_data = REFORGED_DATA.achievements[name]
    if achievement_data then
        self:SetIcon(achievement_data.icon, force_texture)
        local mod_icon = achievement_data.mod and achievement_data.mod ~= "DEFAULT" and TUNING.FORGE.MOD_ICONS[achievement_data.mod]
        if mod_icon then
            self.mod_source_icon:SetTexture(mod_icon.atlas, mod_icon.tex)
            self.mod_source_icon:Show()
        else
            self.mod_source_icon:Hide()
        end
    end
    self:SetRarity(tiers[achievement_data.tier])
    --self:SetEventIcon(item_key)
    if is_unlocked then
        self.lock:Hide()
        self.image:SetTint(1,1,1,1)
		self.frame:SetTint(1,1,1,1)
    else
        self.lock:Show()
		local lt = 0.3
        self.image:SetTint(lt,lt,lt,1)
		self.frame:SetTint(lt,lt,lt,1)
    end
end

function AchievementFrame:SetIcon(icon, force_texture)
    if icon then
        if force_texture then
            self.image:SetTexture(icon.atlas, icon.tex)
        else
            self:SetTextures(icon.atlas, icon.tex)
        end
    end
end

function AchievementFrame:SetRarity(rarity)
    local icon = self.rarity_icons[rarity] or self.rarity_icons.common
    self.frame:SetTexture(icon.atlas, icon.tex)
end

function AchievementFrame:SetEventIcon(item_key)
    local event_icon = GetEventIconForItem(item_key)
    if event_icon ~= nil then
        self:GetAnimState():Show(event_icon)
    end
end

function AchievementFrame:SetActivityState(is_active, is_unlocked)
    if false then
		if is_active then
			self:GetAnimState():Show("SELECT")
		else
			self:GetAnimState():Hide("SELECT")
		end
		if is_unlocked then
			self:SetLocked()
		end
    end
end

function AchievementFrame:SetBlank()
    self:SetTextures("images/rf_achievements.xml", "ach_empty.tex")
    self:SetRarity(1)
    self.mod_source_icon:Hide()
    self.lock:Hide()
    local lt = 0.2
    self.image:SetTint(lt,lt,lt,1)
	self.frame:SetTint(0, 0, 0, 1)
    self.is_active = false
    self.selection_frame:Hide()
end

function AchievementFrame:ScaleToSize(side)
    -- All flash for ItemImage has the same dimensions: 192x192
    local side0 = 192
    side0 = side0 * 0.7 -- 1080 -> 720 conversion
    side0 = side0 - 11  -- reduce to actual size (don't know why math is wrong)
    local scale = side / side0
    self:SetScale(scale, scale, 1)
    self.image_scale = scale
end

function AchievementFrame:SetSelectionState(is_active)
    self.is_active = is_active
    if self.is_active then
        self.selection_frame:Show()
    else
        self.selection_frame:Hide()
    end
end

return AchievementFrame
