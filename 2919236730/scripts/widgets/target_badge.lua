local Badge = require "widgets/badge"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"
local DebuffDisplay = require("widgets/debuff_display")

local function OnEffigyDeactivated(inst)
    if inst.AnimState:IsCurrentAnimation("effigy_deactivate") then
        inst.widget:Hide()
    end
end

local TargetBadge = Class(Badge, function(self, owner, art)
    Badge._ctor(self, "lavaarena_health", owner, { 174 / 255, 21 / 255, 21 / 255, 1 }, "status_health")

    self.anim:GetAnimState():Show("frame")
    self.anim:GetAnimState():HideSymbol("heart")
    self.anim:GetAnimState():SetPercent("anim", 0)

    self.target_icon = self.underNumber:AddChild(Image())
    self.target_icon:ScaleToSize(100, 100, true)

    self.debuff_display = self:AddChild(DebuffDisplay(owner))
    self.debuff_display:SetPosition(100, 50)
end) -- ThePlayer.HUD.controls.target_badge:SetTarget(c_sel())

function TargetBadge:SetPercent(val, max, penaltypercent)
    Badge.SetPercent(self, val, max)

    penaltypercent = penaltypercent or 0
    self.topperanim:GetAnimState():SetPercent("anim", 1 - penaltypercent)
end

function TargetBadge:SetTarget(target)
    local function RemoveTargetHUD(inst)
        self:SetTarget(nil)
    end
    if target and target:IsValid() then
        self.current_target = target
        local prefab_info = GetValidForgePrefab(target.prefab)
        self.target_icon:SetTexture(prefab_info and prefab_info.atlas or "images/reforged.xml", prefab_info and prefab_info.atlas and prefab_info.image or "unknown_icon.tex")
        self.target_icon:ScaleToSize(100, 100, true)
        self.debuff_display:SetTarget(target)
        self:Show()
        target:ListenForEvent("onremove", RemoveTargetHUD)
    else
        if self.current_target and self.current_target:IsValid() then
            self.current_target:RemoveEventCallback("onremove", RemoveTargetHUD)
        end
        self.current_target = nil
        self:Hide()
    end
end

return TargetBadge
