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
env._G = GLOBAL
env.require = _G.require
env.STRINGS = _G.STRINGS

local gamemode = _G.TheNet:GetServerGameMode()
if gamemode ~= "" and gamemode ~= "lavaarena" then
	print("[RF.ERROR] Forge mod was disabled because of not correct GameMode")
	return
end
--------------------------
-- Load Server Settings --
--------------------------
local function GetKeyFromConfig(config, get_local_config)
    local key = GetModConfigData(config, get_local_config)
    return key and (type(key) == "number" and key or _G[key])
end
_G.REFORGED_SETTINGS = {
	mod_root                = MODROOT,
	force_start_delay       = GetModConfigData("FORCE_START_DELAY_TIME"),
	display = { -- Display Options
		damage_numbers            = GetModConfigData("DAMAGE_NUMBER_OPTIONS", true),
		damage_numbers_players    = GetModConfigData("DAMAGE_NUMBER_PLAYERS", true),
		damage_number_font_size   = GetModConfigData("DAMAGE_NUMBER_FONT_SIZE", true),
	    damage_number_height      = GetModConfigData("DAMAGE_NUMBER_HEIGHT", true),
		only_show_nonzero_stats   = GetModConfigData("ONLY_SHOW_NONZERO_STATS", true),
		display_colored_stats     = GetModConfigData("DISPLAY_COLORED_STATS", true),
		default_rotation          = GetModConfigData("DEFAULT_ROTATION", true),
		rotation                  = GetModConfigData("ROTATION", true),
		hide_indicators           = GetModConfigData("HIDE_INDICATORS", true),
		ADJ_FILTER_KEY            = GetKeyFromConfig("ADJUST_FILTER", true),
		default_filter            = GetModConfigData("DEFAULT_FILTER", true),
		gift_side                 = GetModConfigData("GIFT_SIDE", true),
		server_level              = GetModConfigData("SERVER_LEVEL"),
		server_achievements       = GetModConfigData("SERVER_ACHIEVEMENTS"),
		lobby_gear                = GetModConfigData("LOBBY_GEAR", true),
		spectator_on_death        = GetModConfigData("SPECTATOR_ON_DEATH", true),
		player_debuff_display     = GetModConfigData("PLAYER_DEBUFF_DISPLAY", true),
		display_teammates_debuffs = GetModConfigData("DISPLAY_TEAMMATES_DEBUFFS", true),
		display_target_badge      = GetModConfigData("DISPLAY_TARGET_BADGE", true),
		ping_keybind              = GetKeyFromConfig("PING_KEYBIND", true),
		ping_transparency         = GetModConfigData("PING_TRANSPARENCY", true),
		event_tracking			  = GetModConfigData("EVENT_TRACKING", true),
		default_lobby_tab         = GetModConfigData("DEFAULT_LOBBY_TAB", true),
	},
	gameplay = { --TEMPORARY CONFIG OPTIONS FOR MODIFIERS (Will be migrated into worldgen params UNLESS we make our UI modify modconfig params)
		map        = GetModConfigData("MAP") or "lavaarena", -- TODO
		mode       = GetModConfigData("MODE"),
		gametype   = GetModConfigData("GAMETYPE"),
		preset     = GetModConfigData("PRESET"),
		waveset    = GetModConfigData("WAVESET"),
		difficulty = GetModConfigData("DIFFICULTY"),
		mutators   = {
			mob_damage_dealt          = GetModConfigData("MOB_DAMAGE_DEALT"),
			mob_damage_received       = GetModConfigData("MOB_DAMAGE_TAKEN"),
			mob_health                = GetModConfigData("MOB_HEALTH"),
			mob_speed                 = GetModConfigData("MOB_SPEED"),
			mob_attack_rate           = GetModConfigData("MOB_ATTACK_RATE"),
			mob_size                  = GetModConfigData("MOB_SIZE"),
			battlestandard_efficiency = GetModConfigData("BATTLESTANDARD_EFFICIENCY"),
			no_sleep                  = GetModConfigData("NO_SLEEP"),
			no_revives                = GetModConfigData("NO_REVIVES"),
			no_hud                    = GetModConfigData("NO_HUD"),
			friendly_fire             = GetModConfigData("FRIENDLY_FIRE"),
			--unbreakable_shields       = GetModConfigData("UNBREAKABLE_SHIELDS"),
			mob_duplicator            = GetModConfigData("MOB_DUPLICATOR"),
		},
	},
	vote = {
		kick                = GetModConfigData("VOTE_KICK"),
		force_start         = GetModConfigData("VOTE_FORCE_START"),
		game_settings_panel = GetModConfigData("VOTE_GAME_SETTINGS"), -- TODO add this check to where it is needed
	},
	performance = { -- TODO have option for each individual fx?
		all_fx         = GetModConfigData("ALL_FX", true),
		environment_fx = GetModConfigData("ENVIRONMENT_FX", true), -- TODO use to remove all fx that spawn with the map.
		--attack_fx      = GetModConfigData("ATTACK_FX", true), -- TODO need a table of all attack fx to know if it should be disabled?
	},
	other = {
		joinable_midmatch     = GetModConfigData("JOINABLE_MIDMATCH"),
		spectators_only       = GetModConfigData("SPECTATORS_ONLY"),
		reserve_slots         = GetModConfigData("RESERVE_SLOTS"),
		command_spam_ban_time = GetModConfigData("COMMAND_SPAM_BAN_TIME"),
		enable_sandbox        = GetModConfigData("SANDBOX"),
	},
}
----------------
-- Load Debug --
----------------
--[[if GetModConfigData("DEBUG") then
	_G.CHEATS_ENABLED = true
	_G.FORGE_DBG = true
	_G.require("debugkeys")
end--]]
-----------------
-- Load Assets --
-----------------
_G.TUNING.FORGE = require("forge_tuning")
modimport("scripts/forge_strings.lua")
modimport("scripts/forge_actions.lua")
PrefabFiles = require("forge_prefabs")
Assets = require("forge_assets")
modimport("scripts/fx_display.lua")
---------------
-- Load Util --
---------------
_G.Debug = require "util/debug"
_G.Debug:SetDebugMode(false)
require("forge_util")
_G.UTIL = {}
_G.UTIL.WAVESET = require "util/waveset" -- TODO put in common fns instead? it is util though, hmmm
_G.FORGE_TEAM_TAGS = {}
_G.FORGE_TARGETING = require("forge_targeting")
_G.COMMON_FNS = require "_common_functions"
_G.COMMON_FNS.EQUIPMENT = require "_common_equipment_functions"

for i, v in ipairs(PrefabFiles) do
	_G.TUNING.WINTERS_FEAST_LOOT_EXCLUSION[string.upper(v)] = true
end
--------------
-- Load Mod --
--------------
modimport("scripts/forge_main.lua")

--TODO put this in a more organized spot


