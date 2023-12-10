local Widget = require "widgets/widget"
local VoteDialog = require "widgets/votedialog"
local Text = require "widgets/text"
local ImageButton = require "widgets/imagebutton"
local Image = require "widgets/image"
local ThreeSlice = require "widgets/threeslice"
local ControllerVoteScreen = require "screens/controllervotescreen"
local UserCommands = require "usercommands"

--NOTE: some of these constants are copied to controllervotescreen.lua
--      (make sure to keep them in sync!)
local VOTE_ROOT_SCALE = .75
local LABEL_SCALE = .8
local BUTTON_SCALE = 1.2
local DROP_SPEED = -400
local DROP_ACCEL = 750
local UP_ACCEL = 2000
local BOUNCE_ABSORB = .25
local SETTLE_SPEED = 25

local CONTROLLER_POP_SPEED = .1
local CONTROLLER_OPEN_SCALE = .95
local CONTROLLER_OPEN_POS = Vector3(0, -56, 0)
local CONTROLLER_CLOSE_POS = Vector3(0, 0, 0)

local function empty()
end

local LobbyVoteDialog = Class(VoteDialog, function(self, owner)
    Widget._ctor(self, "LobbyVoteDialog")

    self.owner = owner

    self.controller_mode = TheInput:ControllerAttached()
    self.controller_hint_delay = 0
    self.controllervotescreen = nil
    self.controllerselection = nil
    self.controllerscaling = 0

    self.root = self:AddChild(Widget("root"))
    self.root:SetScale(VOTE_ROOT_SCALE)

    self.dialogroot = self.root:AddChild(Widget("dialogroot"))

    self.bg = self.dialogroot:AddChild(ThreeSlice("images/ui.xml", "votewindow_top.tex", "votewindow_middle.tex", "votewindow_bottom.tex"))

    self.starter = self.dialogroot:AddChild(Text(TALKINGFONT, 35))

    self.title = self.dialogroot:AddChild(Text(BUTTONFONT, 35))
    self.title:SetColour(0, 0, 0, 1)

    self.timer = self.dialogroot:AddChild(Text(BUTTONFONT, 35))
    self.timer:SetColour(0, 0, 0, 1)

    self.instruction = self.dialogroot:AddChild(Text(TALKINGFONT, 28))
    self.instruction:SetScale(1 / VOTE_ROOT_SCALE)

    self.left_bar = self.dialogroot:AddChild(Image("images/ui.xml", "scrollbarline.tex"))
    self.left_bar:SetPosition(-75, 200)
    self.left_bar:SetTint(0, 0, 0, 1)
    self.left_bar:SetScale(1.5, 1, 1)
    self.left_bar:MoveToBack()

    self.right_bar = self.dialogroot:AddChild(Image("images/ui.xml", "scrollbarline.tex"))
    self.right_bar:SetPosition(75, 200)
    self.right_bar:SetTint(0, 0, 0, 1)
    self.right_bar:SetScale(-1.5, 1, 1)
    self.right_bar:MoveToBack()

    self.options_root = self.dialogroot:AddChild(Widget("root"))
    self.num_options = 0
    self.buttons = {}
    self.labels_desc = {}
    for index = 1, MAX_VOTE_OPTIONS do
        local desc = self.options_root:AddChild(Text(BUTTONFONT, 35))
        desc:SetColour(0, 0, 0, 1)
        desc:SetScale(LABEL_SCALE)
        desc:Hide()
        table.insert(self.labels_desc, desc)

        local btn = self.options_root:AddChild(ImageButton("images/ui.xml", "checkbox_off.tex", "checkbox_off_highlight.tex", "checkbox_off_disabled.tex", "checkbox_off.tex", nil, { 1, 1 }, { 0, 0 }))
        btn:SetFont(BUTTONFONT)
        btn:SetScale(BUTTON_SCALE)
        btn:SetOnClick(function()
            local userid = TheNet:GetUserID()
            if not self.initiator_id ~= userid then
                UserCommands.RunUserCommand("lobbyvotesubmit", {vote = index}, TheNet:GetClientTableForUser(userid))
            end
            self:UpdateSelection(index, false)
        end)
        btn:Hide()
        btn.GetHelpText = empty
        table.insert(self.buttons, btn)

        if index > 1 then
            btn:SetFocusChangeDir(MOVE_UP, self.buttons[index - 1])
            self.buttons[index - 1]:SetFocusChangeDir(MOVE_DOWN, btn)
        end
    end

    self.info_button = self.dialogroot:AddChild(ImageButton("images/button_icons.xml", "announcement.tex"))
    self.info_button:Hide()

    self.start_root_y_pos = 0
    self.target_root_y_pos = 0
    self.current_root_y_pos = 0
    self.current_speed = 0
    self.started = false
    self.settled = false
    self.canvote = false
    self:Hide()

    self.inst:ListenForEvent("showlobbyvotedialog", function(world, data) self:ShowDialog(data) end)
    self.inst:ListenForEvent("hidelobbyvotedialog", function() self:HideDialog() end)
    self.inst:ListenForEvent("lobbyvotertick", function(world, data) self:UpdateTimer(data.time) end)
    -- TODO are these needed?
    self.inst:ListenForEvent("votecountschanged", function(world, data) self:UpdateOptions(data) end, TheWorld)
    self.inst:ListenForEvent("playervotechanged", function(owner, data) self:UpdateSelection(data.selection, data.canvote) end, self.owner)
    self.inst:ListenForEvent("continuefrompause", function()
        self.controller_mode = TheInput:ControllerAttached()
        self:RefreshLayout()
    end, TheWorld)
end)

function LobbyVoteDialog:ShowDialog(option_data)
    if option_data == nil then
        return
    end

    self.started = true
    self.settled = false
    self.canvote = false
    self.controllerselection = nil
    self:StartUpdating()
    self:Show()

    if self:IsVisible() then
        TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/skin_drop_slide_gift_DOWN")
    end

    -- Update Layout
    self:UpdateOptions(option_data, true)
    self:RefreshLayout()
    self.current_root_y_pos = self.start_root_y_pos
    self.current_speed = DROP_SPEED
    self.root:SetPosition(0, self.current_root_y_pos, 0)
    local lobbyvote = TheWorld.net.replica.lobbyvote
    self:UpdateTimer(lobbyvote and lobbyvote:GetTimer())

    -- Display Info Button
    if option_data.info then
        local timer_pos = self.timer:GetPosition()
        self.info_button:SetPosition(115, timer_pos.y, timer_pos.z)
        self.info_button:SetHoverText(option_data.info.hover_text)
        self.info_button:SetOnClick(option_data.info.fn)
        self.info_button:Show()
        self.info_button:Enable()
    else
        self.info_button:Hide()
        self.info_button:Disable()
    end

    self:UpdateSelection(nil, true)
end

function LobbyVoteDialog:UpdateOptions(option_data, norefresh)
    if not self.started then
        return
    end

    -- Initiator Name
    self.initiator_id = option_data.initiator_id
    local initiator = option_data.initiator_id and TheNet:GetClientTableForUser(option_data.initiator_id) or nil
    local initiator_name = initiator ~= nil and self:GetDisplayName(initiator) or ""
    if initiator_name ~= "" then
        self.starter:SetColour(unpack(initiator.colour or { 0, 0, 0, 1 }))
        self.starter:SetTruncatedString(initiator_name..":", 260, 40, "..:")
    else
        self.starter:SetString("")
    end

    -- Title/Description
    self.title:SetMultilineTruncatedString(option_data.title, 2, 260, 55, true)

    -- Options
    local options = option_data.options
    local old_num_options = self.num_options
    self.num_options = math.min(MAX_VOTE_OPTIONS, options ~= nil and #options)
    for i = 1, self.num_options do
        local option = options and options[i]
        local label = self.labels_desc[i]
        label:Show()
        self.buttons[i]:Show()
        if not option then
            label:SetString(STRINGS.REFORGED.unknown)
        elseif option.vote_count == nil or option.vote_count <= 0 then
            label:SetTruncatedString(option.description, 260, 55, true)
        else
            local str = option.description .. string.format(" (%d)", option.vote_count)
            label:SetTruncatedString(str, 260, 55, false)
            if label:GetString():len() < str:len() then
                label:SetTruncatedString(option.description, 260, 55, string.format("...(%d)", option.vote_count))
            end
        end
    end

    -- Hide any options that are not being used in the current vote
    if old_num_options ~= self.num_options then
        for i = self.num_options + 1, old_num_options do
            self.labels_desc[i]:Hide()
            self.buttons[i]:Hide()
        end

        if not norefresh then
            --The only point of norefresh is so we don't refresh
            --twice in a row when we are called from ShowDialog.
            self:RefreshLayout()
        end
    end
end

return LobbyVoteDialog
