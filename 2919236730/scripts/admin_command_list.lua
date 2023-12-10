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

require("admin_command")
require("admin_commands")

-- name, type, admin_fn, atlas, image

-- Used to replace the default spinner fns for AdminCommands
local function EmptyFN() end

-- GENERAL
AdminCommand("super_god_mode", "GENERAL", function(self, data) SuperGodMode(data.player) end, "images/inventoryimages.xml", "ruinshat.tex")
AdminCommand("revive", "GENERAL", function(self, data) RevivePlayer(data.player) end, "images/reforged.xml", "reviveplayer.tex")
AdminCommand("change_character", "GENERAL", function(self, data) ChangeCharacter(data.player) end, "images/avatars.xml", "avatar_unknown.tex")
AdminCommand("kill_all_mobs", "GENERAL", function(self) KillAllMobs() end, "images/servericons.xml", "pvp.tex", EmptyFN)
AdminCommand("petrify_mobs", "GENERAL", function(self, data) SpawnPetrifyCircle(self, data.player) end, "images/inventoryimages.xml", "book_fossil.tex") -- TODO fossil type icon?
AdminCommand("reset_to_save", "GENERAL", function(self) ResetToSave() end, "images/inventoryimages.xml", "book_brimstone.tex", EmptyFN) -- TODO scouter icon?
AdminCommand("debug_select", "GENERAL", function(self, data) DebugSelect(data.player) end, "images/inventoryimages.xml", "blueprint.tex")

local function CreateSpinnerData(min_num, max_num)
    local spinner_data = {}
    for i = min_num,max_num do
        local current_data = {text = tostring(i), data = i}
        spinner_data[i] = current_data
    end
    return spinner_data
end

local function ForceRoundSpinnerFN(self)
    self:EnsureSpinnersExist(2)
    local round_spinner = self.spinners[1]
    local wave_spinner = self.spinners[2]
    round_spinner:SetOptions(CreateSpinnerData(1, TheWorld.net:GetTotalRounds()))
    wave_spinner:SetOptions(CreateSpinnerData(1, TheWorld.net:GetTotalWaves(1)))
    round_spinner:SetOnChangedFn(function(selected, old)
        if self.item and self.item.name == "force_round" and wave_spinner then
            wave_spinner:SetOptions(CreateSpinnerData(1, TheWorld.net:GetTotalWaves(selected)))
        end
    end)
    round_spinner:SetPosition(270, 75, 0)
    wave_spinner:SetPosition(370, 75, 0)
    round_spinner:SetScale(1,1,1)
    round_spinner.width = 100
    round_spinner:Layout()
    wave_spinner:SetScale(1,1,1)
    wave_spinner.width = 100
    wave_spinner:Layout()
    round_spinner:Show()
    wave_spinner:Show()
    if round_spinner.fgimage then
        round_spinner.fgimage:Hide()
    end
    if wave_spinner.fgimage then
        wave_spinner.fgimage:Hide()
    end
end

local function ForceRoundButtonFN(self)
    self:EnsureButtonsExist(1)
    local button = self.buttons[1]
    local round_spinner = self.spinners[1]
    local wave_spinner = self.spinners[2]
    button:SetScale(1,1,1)
    button:SetPosition(320, -105, 0)
    button:SetText(STRINGS.UI.ADMINMENU.BUTTONS.ACTIVATE)
    button:SetOnClick(function()
        self.item:admin_fn({round = round_spinner:GetSelectedData(), wave = wave_spinner:GetSelectedData()})
    end)
    button:Show()
end

-- FORGE
AdminCommand("force_round", "FORGE", function(self, data) SelectRoundAndWave(data.round, data.wave) end, "images/reforged.xml", "forceround.tex", ForceRoundSpinnerFN, ForceRoundButtonFN)
AdminCommand("restart_forge", "FORGE", function(self) RestartForge() end, "images/reforged.xml", "restartround.tex")
AdminCommand("restart_current_round", "FORGE", function(self) RestartCurrentWave() end, "images/reforged.xml", "restartround.tex")
AdminCommand("enable_rounds", "FORGE", function(self) EnableWaves() end, "images/reforged.xml", "enablerounds.tex")
AdminCommand("disable_rounds", "FORGE", function(self) DisableWaves() end, "images/reforged.xml", "disablerounds.tex")
AdminCommand("end_forge", "FORGE", function(self) EndForge() end, "images/reforged.xml", "endround.tex")

-- BUFFS
AdminCommand("activate_battlecry", "BUFFS", function(self, data) ActivateBattleCry(data.player) end, "images/reforged.xml", "passive_buff.tex") -- TODO image
AdminCommand("give_battlecry", "BUFFS", function(self, data) GiveBattleCry(data.player) end, "images/reforged.xml", "wigfrid_buff.tex") -- TODO image
AdminCommand("activate_amplify", "BUFFS", function(self, data) ActivateAmplify(data.player) end, "images/reforged.xml", "passive_orbs.tex") -- TODO image
AdminCommand("activate_mighty", "BUFFS", function(self, data) ActivateMighty(data.player) end, "images/reforged.xml", "passive_mighty.tex") -- TODO image
AdminCommand("activate_shadows", "BUFFS", function(self, data) ActivateShadows(data.player) end, "images/reforged.xml", "passive_shadows.tex") -- TODO image
AdminCommand("activate_shock", "BUFFS", function(self, data) ActivateShock(data.player) end, "images/reforged.xml", "passive_shock.tex") -- TODO image
AdminCommand("over_9000", "BUFFS", function(self, data) Over9000(data.player) end, "images/reforged.xml", "over9000.tex") -- TODO scouter icon?
AdminCommand("no_cooldown", "BUFFS", function(self, data) NoCoolDown(data.player) end, "images/reforged.xml", "debuff_wobybuff.tex") -- TODO scouter icon?
AdminCommand("scorpeon_dot", "BUFFS", function(self, data) SpawnPoison(data.player) end, "images/reforged.xml", "scorpeon_icon.tex")

Debug:Print("", "log", "AllAdminCommands")
for _, admin_command in ipairs(AllAdminCommands) do
	print(" - " .. tostring(admin_command.name))
end
