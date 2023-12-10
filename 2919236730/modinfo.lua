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
--[[
TODO
    Is there a way to retrieve strings from a string file? Wondering if there is a way to translate these strings? if it's the same as in the main files?
 --]]
name = "ReForged - PT BR"
version = "1.0"

description = "Fight the system! Play the Forge on your own server!\n\nVersion: "..version

author = "Vector & ReForged Team"

forumthread = "/topic/114488-reforged-forged-forge-reworked/"

api_version = 10
api_version_dst = 10

dont_starve_compatible = false
reign_of_giants_compatible = false
dst_compatible = true

all_clients_require_mod = true
client_only_mod = false

forge_compatible = true

icon_atlas = "images/modicon.xml"
icon = "modicon.tex"

mim_assets = {
	custom_menus = {
		["Forge Menu"] = {desc = "Make your menu Forge themed!", script = "forgemenu"}
	}
}

folder_name = folder_name or "workshop-"
if not folder_name:find("workshop-") then
    name = name.." - GitLab Ver."
end

priority = 2147483646

server_filter_tags = {
    "reforged",
    "the forged forge",
}

game_modes = {
	{
        name = "lavaarena",
		label = "The Forge",
		settings = {
			level_type = "LAVAARENA",
			spawn_mode = "fixed",
			resource_renewal = false,
			ghost_sanity_drain = false,
			ghost_enabled = false,
			revivable_corpse = true,
			spectator_corpse = true,
			portal_rez = false,
			reset_time = nil,
			invalid_recipes = nil,
			--
			override_item_slots = 0,
            drop_everything_on_despawn = true,
			no_air_attack = true,
			no_crafting = true,
			no_minimap = true,
			no_hunger = true,
			no_sanity = true,
			no_avatar_popup = true,
			no_morgue_record = true,
			override_normal_mix = "lavaarena_normal",
			override_lobby_music = "dontstarve/music/lava_arena/FE2",
			cloudcolour = { .4, .05, 0 },
			cameraoverridefn = function(camera)
				camera.mindist = 20
				camera.mindistpitch = 32
				camera.maxdist = 55
				camera.maxdistpitch = 60
				camera.distancetarget = 32
			end,
			lobbywaitforallplayers = true,
			hide_worldgen_loading_screen = true,
			hide_received_gifts = false,
			skin_tag = "LAVA",
		},
	}
}

local function AddCustomConfig(name, label, hover, options, default)
    return {name = name, label = label, hover = hover or "", options = options, default = default}
end

local function AddSectionTitle(title)
    return AddCustomConfig(title, title, "", {{description = "", data = 0}}, 0)
end

local function BuildBooleanConfig(desc_str, hover_str)
    return {
        {description = desc_str and desc_str.off or "No", hover = hover_str and hover_str.off or "", data = false},
        {description = desc_str and desc_str.on or "Yes", hover = hover_str and hover_str.on or "", data = true}
    }
end

local function BuildNumConfig(startNum, endNum, step, percent)
    local numTable = {}
    local iterator = 1
    local suffix = percent and "%" or ""
    for i = startNum, endNum, step or 1 do
        numTable[iterator] = {description = i..suffix, data = percent and i / 100 or i}
        iterator = iterator + 1
    end
    return numTable
end

local string = ""
local keys = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12","LAlt","RAlt","LCtrl","RCtrl","LShift","RShift","Tab","Capslock","Space","Minus","Equals","Backspace","Insert","Home","Delete","End","Pageup","Pagedown","Print","Scrollock","Pause","Period","Slash","Semicolon","Leftbracket","Rightbracket","Backslash","Up","Down","Left","Right"}
local keylist = {}
for i = 1, #keys do
    keylist[i] = {description = keys[i], data = "KEY_"..string.upper(keys[i])}
end
keylist[#keylist + 1] = {description = "Disabled", data = false}

local filters = {"Forge","Fall Day","Fall Dusk","Fall Night","Snow Day","Snow Dusk","Snow Night","Summer Day","Summer Dusk","Summer Night","Spring Day","Spring Dusk","Spring Night","Insane Day","Insane dusk","Insane Night","Purple Moon","SW Mild Day","SW Wet Day","SW Green Day","SW Volcano","Beaver Vision","Caves","Fungus","Ghost","Identity","Mole Vision Off","Mole Vision On","Ruins Dark","Ruins Dim","Ruins Light","Sinkhole","Gorge"}
local filter_list = {}
for i = 1, #filters do
	filter_list[i] = {description = filters[i], data = i}
end

local lobby_tabs = {
    {description = "News", data = "news"},
    {description = "Game Settings", data = "settings"},
    {description = "Achievements", data = "achievements"},
    {description = "History", data = "history"},
}
local difficulties = {
    {description = "Normal", data = "normal", hover = "Normal!"},
    {description = "Hard", data = "hard", hover = "A more difficult Forge experience!"},
}
local gametypes = {
    {description = "Forge", data = "forge", hover = "Forge!"},
    {description = "Redlight/Greenlight", data = "classic_rlgl", hover = "Classic RedLight GreenLight!"},
    {description = "RLGLBLOL", data = "rlgl", hover = "RedLight GreenLight, but with more lights!"},
}
local modes = {
    {description = "Forge S01", data = "forge_s01", hover = "The original Forge experience!"},
    {description = "Forge S02", data = "forge_s02", hover = "The second year of Forge!"},
    {description = "ReForged", data = "reforged", hover = "Rebalanced Forged by the ReForged team!"},
}
local wave_sets = {
    {description = "Forge 2018", data = "swineclops", hover = "The 2018 Forge experience!"},
    {description = "Forge Classic", data = "classic", hover = "The OG Forge experience!"},
	{description = "Rhinocebros", data = "rhinocebros", hover = "Play up to the rhinocebros"},
	{description = "Boarillas", data = "boarillas", hover = "Play up to the double boarilla wave"},
    {description = "Half the Wrath", data = "half_the_wrath", hover = "An easier Forge 2018 experience"},
	{description = "Sandbox", data = "sandbox", hover = "Nothing spawns, free to do whatever you want, useful for testing!"},
}

configuration_options = {
	AddSectionTitle("Lobby Options"),
	AddCustomConfig("FORCE_START_DELAY_TIME", "Force Start Delay", "Choose how long the force start delay timer is.", BuildNumConfig(5, 12 * 5, 5), 30),
    AddCustomConfig("SERVER_LEVEL", "Display Players Server Level", "Displays the players server level. If false then the players client level will be displayed.", BuildBooleanConfig(), false),
    AddCustomConfig("SERVER_ACHIEVEMENTS", "Display Server Achievements", "Displays the players server achievements. If false then the players client achievements will be displayed.", BuildBooleanConfig(), false),
    AddCustomConfig("LOBBY_GEAR", "Lobby Character Gear", "Lobby characters wear their starting gear if enabled.", BuildBooleanConfig(), true),
    AddCustomConfig("DEFAULT_LOBBY_TAB", "Default Lobby Tab", "Choose which lobby tab is selected by default.", lobby_tabs, "news"),

	AddSectionTitle("Player HUD Options"),
	AddCustomConfig("HIDE_INDICATORS", "Hide Player Indicators", "Disable player indicators from showing at all.", BuildBooleanConfig(), true),
	AddCustomConfig("SPECTATOR_ON_DEATH", "Spectator On Death", "On death player gains spectator controls.", BuildBooleanConfig(), false),
	AddCustomConfig("GIFT_SIDE", "Gift Location", "Location of the gift item icon.", {{description = "Top Left", data = "left"},{description = "Top Right", data = "right"},}, "right"),
	AddCustomConfig("PLAYER_DEBUFF_DISPLAY", "Choose Debuff Display", "Choose how player debuffs are displayed.", {{description = "None", data = "none"},{description = "Mini icons", data = "mini"},}, "mini"),
	AddCustomConfig("DISPLAY_TEAMMATES_DEBUFFS", "Toggle Team Debuffs", "Display teammates active debuffs.", BuildBooleanConfig(), false),
	AddCustomConfig("DISPLAY_TARGET_BADGE", "Display Targets Badge", "Display current targets badge.", BuildBooleanConfig(), true),
	AddCustomConfig("PING_KEYBIND", "Ping Location", "Assign the key you want to ping a location.", keylist, "KEY_R"),
	AddCustomConfig("PING_TRANSPARENCY", "Ping Transparency", "Affects the transparency of ping banners.", BuildNumConfig(5, 100, 5, true), 100),
    AddCustomConfig("MAX_MESSAGES", "Max Chat Messages", "Set how many messages are saved at one time.", BuildNumConfig(20, 200, 10), 100),
    AddCustomConfig("SHOW_CHAT_ICON", "Show Player Avatar In Chat", "Shows players avatar next to their chat messages.", BuildBooleanConfig(), false),

	AddSectionTitle("Damage Number Options"),
	AddCustomConfig("DAMAGE_NUMBER_OPTIONS", "Damage Number Display", "Options for which damage numbers to display.", {{description = "Default", data = "default"},{description = "Elemental", data = "elemental"},{description = "Off", data = "off"},}, "default"),
    AddCustomConfig("DAMAGE_NUMBER_PLAYERS", "Teammates Damage Numbers", "Display damage numbers for damage done to players.", BuildBooleanConfig({off = "Off", on = "On"}), false),
	AddCustomConfig("DAMAGE_NUMBER_FONT_SIZE", "Damage Number Font Size", "Choose the size of the font for damage numbers. 32 is default.", BuildNumConfig(1, 100), 32),
	AddCustomConfig("DAMAGE_NUMBER_HEIGHT", "Damage Number Height", "Choose how high damage numbers are displayed above the target. 40 is default.", BuildNumConfig(1, 100), 40),

	AddSectionTitle("Visual Options"),
	AddCustomConfig("DEFAULT_FILTER", "Default Filter", "Set the default filter (aka changes the colour cube used).", filter_list, 1),
	AddCustomConfig("ADJUST_FILTER", "Changes the current filter", "Assign the key you want to change the current filter.", keylist, false),
	AddCustomConfig("EVENT_TRACKING", "Event Arenas", "Allows certain arenas to change depending on the current event.", BuildBooleanConfig({off = "Off", on = "On"}), true),

	AddSectionTitle("Detailed Summary Options"),
	AddCustomConfig("ONLY_SHOW_NONZERO_STATS", "Display Nonzero Stats Only", "Only displays stats from a match that have a value greater than zero", BuildBooleanConfig(), true),
	AddCustomConfig("DISPLAY_COLORED_STATS", "Display Colored Stats", "Colors the stat text gold, silver, bronze, or white based on your team stat ranking.", BuildBooleanConfig(), true),
	AddCustomConfig("DEFAULT_ROTATION", "Mvp Badge default rotation", "The MVP badge will have the same rotation on both default summary screen and the detailed summary screen", BuildBooleanConfig(), false),
	AddCustomConfig("ROTATION", "MVP badge custom rotation", "Adjusts the rotation of the MVP badge on the detailed summary screen if default rotation is false", BuildNumConfig(-10, 10), 0),

    AddSectionTitle("Gameplay Settings"),
    AddCustomConfig("DIFFICULTY", "Difficulty", "Change the difficulty!", difficulties, "normal"),
    AddCustomConfig("GAMETYPE", "Gametype", "Change the gametype!", gametypes, "forge"),
    AddCustomConfig("MODE", "Mode", "Change the mode!", modes, "reforged"),
    AddCustomConfig("WAVESET", "Wave Set", "Change the wave data to something NEW!", wave_sets, "swineclops"),

    AddSectionTitle("Mutators"),
	AddCustomConfig("MOB_DAMAGE_DEALT", "Mob Damage Dealt", "Modify how much damage the mobs deal.", BuildNumConfig(50, 200, 25, true), 1),
	AddCustomConfig("MOB_DAMAGE_TAKEN", "Mob Damage Received", "Modify how much damage the mobs take.", BuildNumConfig(50, 200, 25, true), 1),
	AddCustomConfig("MOB_HEALTH", "Total Mob Health Multiplier", "Modify how much health the mobs have.", BuildNumConfig(50, 200, 25, true), 1),
	AddCustomConfig("MOB_SPEED", "Mob Speed Multiplier", "Modify the movement speed of mobs.", BuildNumConfig(50, 200, 25, true), 1),
    AddCustomConfig("MOB_ATTACK_RATE", "Mob Attack Rate Multiplier", "Modify the attack rate of mobs.", BuildNumConfig(0, 200, 10, true), 1),
    AddCustomConfig("MOB_SIZE", "Mob Size Multiplier", "Modify the size of mobs.", BuildNumConfig(50, 200, 25, true), 1),
	AddCustomConfig("BATTLESTANDARD_EFFICIENCY", "Battlestandard Effectiveness", "Modify how effective battlestandards are.", BuildNumConfig(50, 200, 25, true), 1),
	AddCustomConfig("NO_SLEEP", "Enemies Don't Sleep", "Enemies can no longer be put to sleep.", BuildBooleanConfig({off = "Off", on = "On"}), false),
    AddCustomConfig("NO_REVIVES", "No Revives", "Players cannot revive each other.", BuildBooleanConfig({off = "Off", on = "On"}), false),
    AddCustomConfig("NO_HUD", "No Player HUD", "Cannot see any players health bar or inventory.", BuildBooleanConfig({off = "Off", on = "On"}), false),
    AddCustomConfig("FRIENDLY_FIRE", "Friendly Fire", "Players can now hurt each other.", BuildBooleanConfig({off = "Off", on = "On"}), false),
	--AddCustomConfig("UNBREAKABLE_SHIELDS", "Shields Can't Be Broken", "Alt attacks won't break shields anymore.", BuildBooleanConfig({off = "Off", on = "On"}), false),
    AddCustomConfig("MOB_DUPLICATOR", "Mob Duplicator Multiplier", "Modify the number of mobs that spawn.", BuildNumConfig(1, 10, 1), 1),

	--AddSectionTitle("Performance"),
    --AddCustomConfig("ALL_FX", "Enable FX", "Enables FX to be created.", BuildBooleanConfig({off = "Off", on = "On"}), true),
    --AddCustomConfig("ENVIRONMENT_FX", "Enable Environment FX", "Enables environment FX to be created.", BuildBooleanConfig({off = "Off", on = "On"}), true),
    --AddCustomConfig("ATTACK_FX", "Enable Attack FX", "Enables attack FX to be created.", BuildBooleanConfig({off = "Off", on = "On"}), true),

    AddSectionTitle("Vote"),
    AddCustomConfig("VOTE_KICK", "Enable Vote to Kick", "Allows non admins to vote to kick other players.", BuildBooleanConfig({off = "Off", on = "On"}), true),
    AddCustomConfig("VOTE_FORCE_START", "Enable Vote to Force Start", "Allows non admins to vote to force start the game.", BuildBooleanConfig({off = "Off", on = "On"}), true),
    AddCustomConfig("VOTE_GAME_SETTINGS", "Enable Game Settings Voting", "Allows players to vote to change game settings.", BuildBooleanConfig({off = "Off", on = "On"}), true),

    AddSectionTitle("Other"),
    AddCustomConfig("JOINABLE_MIDMATCH", "Joinable Midmatch", "Allows players to join midmatch.", BuildBooleanConfig({off = "Off", on = "On"}), true),
    AddCustomConfig("SPECTATORS_ONLY", "Only Spectators Join Midmatch", "Allows players to join midmatch as spectators only.", BuildBooleanConfig({off = "Off", on = "On"}), true),
    AddCustomConfig("RESERVE_SLOTS", "Reserve Slots", "Non spectators who disconnect during a match will have their slot reserved for them.", BuildBooleanConfig({off = "Off", on = "On"}), true),
    AddCustomConfig("COMMAND_SPAM_BAN_TIME", "Command Spam Ban Time", "How long a user is banned for spamming commands to the server (minutes).", BuildNumConfig(0, 60, 5), 10),
    AddCustomConfig("SANDBOX", "Enable Sandbox", "Adds the sandbox waveset to the wavesets list.", BuildBooleanConfig({off = "Off", on = "On"}), false),
    AddCustomConfig("DEBUG", "Enable debug mode", "Adds debug keys and some other things for easier debugging.", BuildBooleanConfig({off = "Off", on = "On"}), false),
}
