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

-- By Cunning Fox.
package.loaded["forge_compatibility"] = nil
local Debug = require "util/debug"
Debug:Print("Loading postinits...", "log")

local ModsTab = require("widgets/redux/modstab")
local ServerCreationScreen = require("screens/redux/servercreationscreen")
local PopupDialogScreen = require("screens/redux/popupdialog")
local TextListPopup = require "screens/redux/textlistpopup"

local _OnConfirmEnable = ModsTab.OnConfirmEnable
local _Create = ServerCreationScreen.Create

-- If the mod is incompatible with our mod then we'll need to show popup
ModsTab.OnConfirmEnable = function(self, restart, modname)
	local CurrentScreen = _G.TheFrontEnd:GetActiveScreen()
	if CurrentScreen and CurrentScreen.server_settings_tab then
		local fancy_name = modname and _G.KnownModIndex:GetModFancyName(modname) or nil
		
		-- If someone disabled our mod or unloaded all mods (nil).
		if modname == nil or fancy_name == MODENV.modinfo.name then
			CurrentScreen.server_settings_tab.game_mode.spinner:Enable()
			CurrentScreen.server_settings_tab.game_mode.spinner:SetOptions(_G.GetGameModesSpinnerData(_G.ModManager:GetEnabledServerModNames()))
			CurrentScreen.server_settings_tab.game_mode.spinner:SetSelectedIndex(1)
			CurrentScreen.server_settings_tab.game_mode.spinner:Changed()
		end
	end
	_OnConfirmEnable(self, restart, modname)
	
    local modinfo = KnownModIndex:GetModInfo(modname)
	
    if KnownModIndex:IsModEnabled(modname) and not modinfo.forge_compatible then
		TheFrontEnd:PushScreen(PopupDialogScreen(STRINGS.FORGE_PRELOADED.MOD_INCOMPATIBLE.TITLE, STRINGS.FORGE_PRELOADED.MOD_INCOMPATIBLE.BODY,
		{
			{text=STRINGS.UI.MODSSCREEN.OK, cb = function() TheFrontEnd:PopScreen() end }
		}))
    end
end

function ModsTab:GetIncompatibleEnabledMods()
    local incomp = {}
    local enabled = ModManager:GetEnabledServerModNames()

    for _, modname in pairs(enabled) do
		local modinfo = KnownModIndex:GetModInfo(modname)
        
        if not modinfo.forge_compatible then
            table.insert(incomp, modname)
        end
    end

    return incomp
end

ServerCreationScreen.Create = function(self, ...)
	local function BuildOptionalModLink(mod_name)
        if PLATFORM == "WIN32_STEAM" or PLATFORM == "LINUX_STEAM" or PLATFORM == "OSX_STEAM" then
            local link_fn, is_generic_url = ModManager:GetLinkForMod(mod_name)
            if is_generic_url then
                return nil
            else
                return link_fn
            end
        else
            return nil
        end
    end
	
	local function BuildModList(mod_ids)
        local mods = {}
        for i,v in ipairs(mod_ids) do
            table.insert(mods, {
                    text = KnownModIndex:GetModFancyName(v) or v,
                    -- Adding onclick with the idea that if you have a ton of
                    -- mods, you'd want to be able to jump to information about
                    -- the problem ones.
                    onclick = BuildOptionalModLink(v),
                })
        end
        return mods
    end
	
	-- Build the lost of mods that are enabled and also out of date
    local incompatiblemods = self.mods_tab:GetIncompatibleEnabledMods()
	
	if #incompatiblemods > 0 then -- pressed_continue is a dirty fix
		self.last_focus = TheFrontEnd:GetFocusWidget()
		local warning = TextListPopup(
			BuildModList(incompatiblemods),
			STRINGS.FORGE_PRELOADED.MOD_INCOMPATIBLE_BEFORE_GEN.TITLE,
			STRINGS.FORGE_PRELOADED.MOD_INCOMPATIBLE_BEFORE_GEN.BODY,
			{
				{
					text=STRINGS.UI.SERVERCREATIONSCREEN.CONTINUE,
					cb = function()
						TheFrontEnd:PopScreen()
						_Create(self, true, true, true)
					end,
					controller_control=CONTROL_MENU_MISC_1
				},
			}
		)
		
		TheFrontEnd:PushScreen(warning)
	else
		_Create(self, ...)
	end
end

local revert_changes = {
	ModsTab = {
		["OnConfirmEnable"] = _OnConfirmEnable,
		["GetIncompatibleEnabledMods"] = nil,
	},
	
	ServerCreationScreen = {
		["Create"] = _Create,
	},
}

return function(forge_name)
	forge_name = forge_name or "forge"
	
    local old_FrontendUnloadMod = ModManager.FrontendUnloadMod   
	ModManager.FrontendUnloadMod = function(self, modname)
		old_FrontendUnloadMod(self, modname)
		
		local fancy_name = modname and KnownModIndex:GetModFancyName(modname) or nil
		
		-- If someone disabled our mod or unloaded all mods (nil).
		if modname == nil or fancy_name == forge_name then
			Debug:Print("Unloading our postinits...", "log")
			for method, fn in pairs(revert_changes.ModsTab) do
				ModsTab[method] = function(self, ...) fn(self, ...) end
			end
			
			for method, fn in pairs(revert_changes.ServerCreationScreen) do
				ServerCreationScreen[method] = function(self, ...) fn(self, ...) end
			end
		end
	end
	
	Debug:Print("Postinits loaded!", "log")
end
