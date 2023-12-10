local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"

local SpectatorCameraDisplay = Class(Widget, function(self, owner)
    Widget._ctor(self, "SpectatorCamera")
    self.owner = owner

    self:SetPosition(0, 59)

    --function(atlas, normal, focus, disabled, down, selected, scale, offset)
    self.left_arrow = self:AddChild(ImageButton("images/ui.xml", "crafting_inventory_arrow_l_hl.tex", nil, nil, nil, nil))
    self.left_arrow:ForceImageSize(50,50)
    self.left_arrow:SetPosition(-200, 0)
    self.left_arrow:SetOnClick(function()
        self:ShiftCameraTarget(-1)
    end)

    self.right_arrow = self:AddChild(ImageButton("images/ui.xml", "crafting_inventory_arrow_r_hl.tex", nil, nil, nil, nil))
    self.right_arrow:ForceImageSize(50,50)
    self.right_arrow:SetPosition(200, 0)
    self.right_arrow:SetOnClick(function()
        self:ShiftCameraTarget(1)
    end)

    self.camera_toggle = self:AddChild(ImageButton("images/reforged.xml", "spectator_toggle.tex", nil, nil, nil, nil))
    self.camera_toggle:ScaleImage(50,50)
    self.camera_toggle:SetPosition(0, 50)
    self.camera_toggle:SetHoverText(STRINGS.REFORGED.HUD.SPECTATOR_FREE_CAMERA_TOGGLE)
    self.camera_toggle:SetOnClick(function()
        self:ToggleFreeCamera(not self.is_free_camera)
    end)

    self.focus_text = self:AddChild(Text(HEADERFONT, 50, STRINGS.REFORGED.HUD.SPECTATOR_FREE_CAMERA))

    self.is_free_camera = self.owner.prefab == "spectator"
    if not self.is_free_camera then
        self.camera_toggle:Hide()
        self.focus_text:SetTruncatedString(self.owner.name, 300)
    else
        self.left_arrow:Disable()
        self.left_arrow:Hide()
        self.right_arrow:Disable()
        self.right_arrow:Hide()
    end

    self.target = nil
    self.target_index = 1

    self._ontargetremoved = function(target)
        local last_pos = target:GetPosition()
        self:UpdateCurrentSpectator(target, last_pos, true)
    end
end)

function SpectatorCameraDisplay:ShowCameraDisplay()
    self:Show()
end

function SpectatorCameraDisplay:HideCameraDisplay()
    TheFocalPoint.components.focalpoint:RemoveAllFocusSources(true)
    self:Hide()
end

local function GetNonSpectators(self, ignore_target)
    local non_spectators = {}
    for i,player in pairs(AllPlayers) do
        if player.prefab ~= "spectator" and player ~= ignore_target then
            table.insert(non_spectators, player)
            if self.target and self.target:IsValid() and self.target == player then
                self.target_index = #non_spectators
            end
        end
    end
    if not (self.target and self.target:IsValid()) then
        self.target = non_spectators[1]
        self.target_index = 1
    end
    return non_spectators
end

-- TODO if self.target ~= previous_target
function SpectatorCameraDisplay:UpdateCurrentSpectator(previous_target, last_pos, is_removing_previous_target)
    if not self.inst:IsValid() then return end
    -- Remove previous target
    if previous_target then
        self.owner:RemoveEventCallback("onremove", self._ontargetremoved, previous_target)
        TheFocalPoint.components.focalpoint:StopFocusSource(previous_target, "spectator_camera")
    end
    local non_spectators = GetNonSpectators(self, is_removing_previous_target and previous_target)
    -- New target
    if self.target and self.target:IsValid() and #non_spectators > 0 then
        self.owner:ListenForEvent("onremove", self._ontargetremoved, self.target)
        TheFocalPoint.components.focalpoint:StartFocusSource(self.target, "spectator_camera", nil, 999, 999, 3)
        self.focus_text:SetTruncatedString(self.target.name, 300)
    -- No target
    else
        self:ToggleFreeCamera(true, last_pos)
    end
end

function SpectatorCameraDisplay:ToggleFreeCamera(is_free_camera, last_pos)
    if self.is_free_camera ~= is_free_camera then
        local non_spectators = GetNonSpectators(self)
        if is_free_camera or #non_spectators <= 0 then
            if self.target and self.target:IsValid() then
                local pos = self.target and self.target:IsValid() and self.target:GetPosition() or last_pos -- TODO add player spawner pos as last default
                self.owner.Transform:SetPosition(pos.x,0,pos.z)
            end
            --TheFocalPoint.components.focalpoint:StopFocusSource(self.target, "spectator_camera")
            TheFocalPoint.components.focalpoint:RemoveAllFocusSources(true) -- TODO no_snap does what? use this or StopFocusSource?
            self.focus_text:SetString(STRINGS.REFORGED.HUD.SPECTATOR_FREE_CAMERA)
            self.left_arrow:Disable()
            self.right_arrow:Disable()
            self.left_arrow:Hide()
            self.right_arrow:Hide()
        else
            self:UpdateCurrentSpectator()
            self.left_arrow:Enable()
            self.right_arrow:Enable()
            self.left_arrow:Show()
            self.right_arrow:Show()
        end
        self.is_free_camera = is_free_camera or #non_spectators <= 0
    end
end

function SpectatorCameraDisplay:ShiftCameraTarget(amount)
    if amount ~= nil and amount ~= 0 then
        local previous_target = self.target
        local non_spectators = GetNonSpectators(self)
        if self.target and self.target:IsValid() then
            self.target_index = (self.target_index + amount - 1)%#non_spectators + 1
            self.target = non_spectators[self.target_index]
        else
            self.target_index = 1
            self.target = non_spectators[1]
        end
        self:UpdateCurrentSpectator(previous_target)
    end
end

return SpectatorCameraDisplay
