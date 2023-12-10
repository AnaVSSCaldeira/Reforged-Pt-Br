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
local _G = GLOBAL
local require = _G.require
local package = _G.package
local STRINGS = _G.STRINGS

modimport("scripts/map/reforged_tiles")
modimport("scripts/map/reforged_layouts")

mods = _G.rawget(_G,"mods")
if not mods then
	mods = {}
	_G.rawset(_G, "mods", mods)
end

local IsTheFrontEnd = _G.rawget(_G, "TheFrontEnd")

STRINGS.FORGE_PRELOADED = {
	MOD_INCOMPATIBLE = {
		TITLE = "Warning!",
		BODY = "This mod is not compatible with The Forge mod. We are not able to help you should issues arise while using mods. Please proceed with caution.",
	},

	MOD_INCOMPATIBLE_BEFORE_GEN = {
		TITLE = "Incompatible mods!",
        BODY = "Those mods are not compatible with The Forge mod. Are you sure want to continue?",
	},
}

if mods.RussianLanguagePack then
	STRINGS.FORGE_PRELOADED.MOD_INCOMPATIBLE.TITLE = "Внимание!"
	STRINGS.FORGE_PRELOADED.MOD_INCOMPATIBLE.BODY = "Этот мод несовместим с модом \"The Forge\". Мы не сможем помочь вам в решении проблем с ним, поэтому используйте его на свой страх и риск."

	STRINGS.FORGE_PRELOADED.MOD_INCOMPATIBLE_BEFORE_GEN.TITLE = "Несовместимые моды"
	STRINGS.FORGE_PRELOADED.MOD_INCOMPATIBLE_BEFORE_GEN.BODY = "Эти моды несовместимы с модом \"The Forge\". Вы уверены, что хотите продолжить?"
end

_G.rawset(_G, "MODENV", env)

if IsTheFrontEnd then
	package.loaded["forge_compatibility"] = nil
	local forge_compatibility = require "forge_compatibility"
	forge_compatibility(modinfo.name)

	local CurrentScreen = _G.TheFrontEnd:GetActiveScreen()
	if CurrentScreen and CurrentScreen.server_settings_tab and CurrentScreen.server_settings_tab.game_mode.spinner.enabled then
		CurrentScreen.server_settings_tab.game_mode.spinner:SetOptions(_G.GetGameModesSpinnerData(_G.ModManager:GetEnabledServerModNames()))
		CurrentScreen.server_settings_tab.game_mode.spinner:SetSelected("lavaarena")
        CurrentScreen.server_settings_tab.game_mode.spinner:Changed()
        CurrentScreen.server_settings_tab.game_mode.spinner:Disable()
	end
else

end
