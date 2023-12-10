--[[
Copyright (C) 2018 Forged Forge

This file is part of Forged Forge.

The source code of this program is shared under the RECEX
SHARED SOURCE LICENSE (version 1.0).
The source code is shared for referrence and academic purposes
with the hope that people can read and learn from it. This is not
Free and Open Source software, and code is not redistributable
without permission of the author. Read the RECEX SHARED
SOURCE LICENSE for details
The source codes does not come with any warranty including
the implied warranty of merchandise.
You should have received a copy of the RECEX SHARED SOURCE
LICENSE in the form of a LICENSE file in the root of the source
directory. If not, please refer to
<https://raw.githubusercontent.com/Recex/Licenses/master/SharedSourceLicense/LICENSE.txt>
]]

require "class"
require "util"

local function MenuResetFN(self)
    if self.highlight and self.has_ents then
        --print("Hide data: " .. tostring(self.spinner_ents:GetSelectedData()))
        local selected = self.spinners[1]:GetSelectedData()
        if selected:HasTag("inspectable") then
            selected.AnimState:SetHighlightColour()
            self.highlight = false
            self.has_ents = false
        end
    end
end

local function MenuRefreshFN(self)
    local category = self.item.type
    -- Spinners
    if self.item.menu_spinner_fn then
        self.item.menu_spinner_fn(self)
    elseif category ~= "FORGE" then
        self:EnsureSpinnersExist(1)

        -- Ent Spinner
        local ent_spinner = self.spinners[1]
        ent_spinner:SetScale(1,1,1)
        ent_spinner:SetPosition(320, 75, 0)
        local ent_spinner_opts = {}
        local player_pos = ThePlayer:GetPosition()
        local ents = self.item.name == "debug_select" and TheSim:FindEntities(player_pos.x,player_pos.y,player_pos.z,100,{"inspectable"}) or AllPlayers
        for _,ent in pairs(ents) do
            local atlas = (ent:HasTag("player") and (softresolvefilepath("images/avatars/avatar_"..ent.prefab..".xml") and "images/avatars/avatar_"..ent.prefab..".xml" or "images/avatars.xml"))
            or (ent.components.inventoryitem and "images/inventoryimages.xml")
            or (ent:HasTag("LA_mob") and "images/reforged.xml") or self.item.atlas

            local tex = (ent:HasTag("player") and ("avatar_" .. tostring(ent.prefab) .. ".tex")) or
            (ent.components.inventoryitem and ent.components.inventoryitem.imagename ~= nil and ent.components.inventoryitem.imagename .. ".tex") or
            (ent:HasTag("LA_mob") and tostring(ent.prefab) .. "_icon.tex") or self.item.image or
            "poop.tex"

            -- Set the player as the first entity in the spinner.
            if ent == ThePlayer then
                table.insert(ent_spinner_opts, 1, {data = ent, image = {atlas, tex}, hover_text = ent.name})
            else
                table.insert(ent_spinner_opts, {data = ent, image = {atlas, tex}, hover_text = ent.name})
            end
            self.has_ents = true
        end
        ent_spinner:SetOptions(ent_spinner_opts)
        ent_spinner:SetSelected(ThePlayer)
        local init_sel = ent_spinner:GetSelectedData()
        ent_spinner:SetHoverText(init_sel:HasTag("player") and tostring(init_sel.name) or tostring(init_sel.prefab) .. "_" .. tostring(init_sel.GUID))
        init_sel.AnimState:SetHighlightColour(255/255, 109/255, 100/255, 0)
        self.highlight = true
        ent_spinner.fgimage:Show()
        ent_spinner:SetOnChangedFn(function(selected, old)
            if ent_spinner.fgimage then
                ent_spinner:SetHoverText(selected:HasTag("player") and tostring(selected.name) or tostring(selected.prefab) .. "_" .. tostring(selected.GUID))
            end
            selected.AnimState:SetHighlightColour(255/255, 109/255, 100/255, 0)
            old.AnimState:SetHighlightColour()
            self.highlight = true
        end)
        ent_spinner.width = 150
        ent_spinner:Layout()
        ent_spinner:Show()
    end

    -- Buttons
    if self.item.menu_button_fn then
        self.item.menu_button_fn(self)
    else
        self:EnsureButtonsExist(1)
        local button = self.buttons[1]
        local ent_spinner = self.spinners[1]
        button:SetScale(1,1,1)
        button:SetPosition(320, -105, 0)
        button:SetText(STRINGS.UI.ADMINMENU.BUTTONS.ACTIVATE)
        button:SetOnClick(function()
            self.item:admin_fn({player = ent_spinner and ent_spinner:GetSelectedData() or ThePlayer})
        end)
        button:Show()
    end
end

local num = 0
AllAdminCommands = {}
AdminCommand = Class(function(self, name, category, admin_fn, atlas, image, menu_spinner_fn, menu_button_fn, menu_reset_fn)
    self.name 			 = name
    self.type 			 = category
    self.menu_refresh_fn = MenuRefreshFN
    self.menu_spinner_fn = menu_spinner_fn
    self.menu_button_fn  = menu_button_fn
    self.menu_reset_fn   = menu_reset_fn or MenuResetFN

    self.atlas	 		= (atlas and resolvefilepath(atlas)) or resolvefilepath("images/inventoryimages.xml")
    self.imagefn 		= type(image) == "function" and image or nil
    self.image 			= self.imagefn == nil and image or ("torch.tex")

	self.admin_fn = admin_fn

    self.sortkey 		= num

    num = num + 1
    AllAdminCommands[name] = self
end)

function GetValidAdminCommand(name)
    return AllAdminCommands[name]
end

function IsAdminCommandValid(name)
    return GetValidAdminCommand(name) ~= nil
end

function RemoveAllAdminCommands()
    AllAdmincommands = {}
    num = 0
end
