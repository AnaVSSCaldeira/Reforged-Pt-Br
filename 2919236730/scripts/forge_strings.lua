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
local STRINGS = _G.STRINGS

--Temp fix because Klei accidentally deleted her description. TODO: Delete when fixed.
STRINGS.LAVAARENA_CHARACTER_DESCRIPTIONS.winona    = "*All ability cooldowns are 10% faster.\n\n\nExpertise:\nMelee, Darts, Staves"
STRINGS.LAVAARENA_CHARACTER_DESCRIPTIONS.warly     = "*Brings bags of spice that can induce multiple effects to enemies!\n*Master Chef.\n*Deals 20% more healing.\nExpertise:\nMelee, Staves"
STRINGS.LAVAARENA_CHARACTER_DESCRIPTIONS.wortox    = "*Spawns with a soul hopping Soul Scepter.\n*Passively sucks the souls of his foes.\n\n\nExpertise:\nMelee"
STRINGS.LAVAARENA_CHARACTER_DESCRIPTIONS.wormwood  = "*Spawns with a plant-based blowdart.\n*Blossoms over time as long as he avoids damage.\n\nExpertise:\nDarts, Staves"
STRINGS.LAVAARENA_CHARACTER_DESCRIPTIONS.wurt      = "*Can use every weapon available.\n*Melee attacks makes foes wet, making them slow and vulnerable to electric damage.\nExpertise:\nMelee, Darts, Staves, Books"
STRINGS.LAVAARENA_CHARACTER_DESCRIPTIONS.walter    = "*Brings his friend Woby.\n*Woby can reduce cooldowns as support.\n\nExpertise:\nDarts, Books"
STRINGS.LAVAARENA_CHARACTER_DESCRIPTIONS.spectator = "*Free Camera.\n*Camera can follow specific players."
STRINGS.CHARACTER_NAMES.spectator = "Spectator"
--STRINGS.CHARACTER_QUOTES.spectator = ""
STRINGS.CHARACTER_TITLES.spectator = "The Spy"
--[[ Character Describe Strings Template
STRINGS.CHARACTERS.WAXWELL.DESCRIBE.A      = ""
STRINGS.CHARACTERS.WAXWELL.DESCRIBE.A      = ""
STRINGS.CHARACTERS.WOLFGANG.DESCRIBE.A     = ""
STRINGS.CHARACTERS.WX78.DESCRIBE.A         = ""
STRINGS.CHARACTERS.WILLOW.DESCRIBE.A       = ""
STRINGS.CHARACTERS.WENDY.DESCRIBE.A        = ""
STRINGS.CHARACTERS.WOODIE.DESCRIBE.A       = ""
STRINGS.CHARACTERS.WICKERBOTTOM.DESCRIBE.A = ""
STRINGS.CHARACTERS.WATHGRITHR.DESCRIBE.A   = ""
STRINGS.CHARACTERS.WEBBER.DESCRIBE.A       = ""
STRINGS.CHARACTERS.WINONA.DESCRIBE.A       = ""
STRINGS.CHARACTERS.WORTOX.DESCRIBE.A       = ""
STRINGS.CHARACTERS.WORMWOOD.DESCRIBE.A     = ""
STRINGS.CHARACTERS.WARLY.DESCRIBE.A        = ""
STRINGS.CHARACTERS.WURT.DESCRIBE.A         = ""
--]]
local function SetItemsDescribeStrings(item_name, strings)
	for character,str in pairs(strings) do
		STRINGS.CHARACTERS[string.upper(character)].DESCRIBE[string.upper(item_name)] = str
	end
end

local LAVAARENA_SEEDDARTS_STRINGS = {
	GENERIC      = "It fires seeds and grows sentient plants.",
	WAXWELL      = "I'm not putting my mouth to that!",
	WOLFGANG     = "It breaks in Wolfgang's mighty grip.",
	WX78         = "USELESS ORGANIC DART",
	WILLOW       = "Hey, that's not fire!",
	WENDY        = "An instrument of life and death.",
	WOODIE       = "I'm not too big on plants, eh?",
	WICKERBOTTOM = "It's not for me, I'm afraid.",
	WATHGRITHR   = "A weapon blessed by Idunn!",
	WEBBER       = "We like this one, it makes a friend!",
	WINONA       = "That gets the job done!",
	WORTOX       = "A gnarled weed to shoot some seeds!",
	WORMWOOD     = "Ptoo ptoo ptoo!",
	WARLY        = "Weaponized seeds?",
	WURT         = "Not a vegetable...?",
}
STRINGS.NAMES.LAVAARENA_SEEDDARTS = "Seedling Darts"
STRINGS.ACTIONS.CASTAOE.LAVAARENA_SEEDDARTS = "Plant Seedling"
SetItemsDescribeStrings("LAVAARENA_SEEDDARTS", LAVAARENA_SEEDDARTS_STRINGS)

local MEAN_FLYTRAP_STRINGS = {
	GENERIC      = "A plant! The boar's natural predator.",
	WAXWELL      = "He serves us, for now.",
	WOLFGANG     = "Is plant friend.",
	WX78         = "A PLANT MINION FROM THE PLANT MINION",
	WILLOW       = "How does a dumb plant grow here?",
	WENDY        = "You too shall perish soon.",
	WOODIE       = "'Ey, he's on our side!",
	WICKERBOTTOM = "Flora of this structure can't last long here, sadly.",
	WATHGRITHR   = "Will you fight alongside me, plant?",
	WEBBER       = "Hello! What's your name?",
	WINONA       = "Look at the set of chompers on him!",
	WORTOX       = "Grown from seeds to do our deeds!",
	WORMWOOD     = "Brought friend along",
	WARLY        = "The produce bites back!",
	WURT         = "It's a leaf friend! Glort!",
}
STRINGS.NAMES.MEAN_FLYTRAP = "Seedling"
SetItemsDescribeStrings("MEAN_FLYTRAP", MEAN_FLYTRAP_STRINGS)

local LAVAARENA_SEEDDART2_STRINGS = {
	GENERIC      = "It fires a triple volley of seeds.",
	WAXWELL      = "You have to be kidding me.",
	WOLFGANG     = "Wolfgang's punches mightier than little twig!",
	WX78         = "THIS IS OF NO USE TO ME",
	WILLOW       = "Three shots at once? I'll take that!",
	WENDY        = "Death in seed form.",
	WOODIE       = "My plant buddy is afraid to let me have it.",
	WICKERBOTTOM = "Wormwood has an interesting taste in weaponry.",
	WATHGRITHR   = "I will fight many enemies with this!",
	WEBBER       = "It can hit a lot of things at once, just like us!",
	WINONA       = "I'll give it a shot. Ha!",
	WORTOX       = "Seeds that bloom shall spell your doom!",
	WORMWOOD     = "Dart shaped like friend!",
	WARLY        = "I must blow thrice as hard for this one.",
	WURT         = "Should be careful with this. Not gonna.",
}
STRINGS.NAMES.LAVAARENA_SEEDDART2 = "Scattertooth"
STRINGS.ACTIONS.CASTAOE.LAVAARENA_SEEDDART2 = "Plant Snaptooth"
SetItemsDescribeStrings("LAVAARENA_SEEDDART2", LAVAARENA_SEEDDART2_STRINGS)

local ADULT_FLYTRAP_STRINGS = {
	GENERIC      = "His bark is just as bad as his bite!",
	WAXWELL      = "I'm smarter than to move near that thing.",
	WOLFGANG     = "Scary plant friend.",
	WX78         = "EAT MY ENEMIES, MINION",
	WILLOW       = "Stay back, Bernie. He looks vicious!",
	WENDY        = "Grown to life to reap death...",
	WOODIE       = "I know better than to chop him, eh?",
	WICKERBOTTOM = "It recognizes us as allies, thankfully.",
	WATHGRITHR   = "Feast like a true warrior, plant!",
	WEBBER       = "We're afraid he'll eat my friends.",
	WINONA       = "He's definitely no flytrap I've ever seen.",
	WORTOX       = "F-fear me! I'm a scary imp!",
	WORMWOOD     = "Help, friend!",
	WARLY        = "He appears to have a very carnivorous diet.",
	WURT         = "No bite me!",
}
STRINGS.NAMES.ADULT_FLYTRAP = "Snaptooth"
SetItemsDescribeStrings("ADULT_FLYTRAP", ADULT_FLYTRAP_STRINGS)

local LAVAARENA_SPATULA_STRINGS = {
	GENERIC      = "I can cook up a hearty meal for everyone with this!",
	WAXWELL      = "There's a time and place for cooking, and this is not it.",
	WOLFGANG     = "Wolfgang cook mighty meal for his friends!",
	WX78         = "I WILL DEAL HIGH DEGREES OF PAIN WITH THIS",
	WILLOW       = "I'm not using a dumb spatula!",
	WENDY        = "A tool unfit for combat.",
	WOODIE       = "I can whip up some mean poutine in a pinch.",
	WICKERBOTTOM = "I am a tad starved, but I cannot prepare a meal right now.",
	WATHGRITHR   = "To fight and to feast!",
	WEBBER       = "Oh! Are we gonna have a barbeque?",
	WINONA       = "Stay back! I'll cook you into a nice boar burger!",
	WORTOX       = "These mortals can never stop eating.",
	WORMWOOD     = "Food time?",
	WARLY        = "Ah, oui! Just the tool for the job, non?",
	WURT         = "Food fight, florpt!",
}
STRINGS.NAMES.LAVAARENA_SPATULA = "Spatula"
STRINGS.ACTIONS.CASTAOE.LAVAARENA_SPATULA = "Summon Cookpot"
SetItemsDescribeStrings("LAVAARENA_SPATULA", LAVAARENA_SPATULA_STRINGS)

local FORGE_COOKPOT_STRINGS = {
	GENERIC      = "It's keeping us fed on the field.",
	WAXWELL      = "The coming meal shall keep me energized.",
	WOLFGANG     = "Food is cooking!",
	WX78         = "IT IS AN UPGRADE IN PROGRESS",
	WILLOW       = "That's a good use for all the fire around here!",
	WENDY        = "At least I won't die hungry...",
	WOODIE       = "I work better on a full stomach, eh?",
	WICKERBOTTOM = "A good meal will keep us energized.",
	WATHGRITHR   = "There's always time for meat!",
	WEBBER       = "Thank you for the food!",
	WINONA       = "I'll take mine to-go!",
	WORTOX       = "Mortal food shall induce a little boost! Hyuyu!",
	WORMWOOD     = "Yum!",
	WARLY        = "I'm in my element!",
	WURT         = "Food for us soon!",
}
STRINGS.NAMES.FORGE_COOKPOT = "Crockpot"
SetItemsDescribeStrings("FORGE_COOKPOT", FORGE_COOKPOT_STRINGS)

STRINGS.NAMES.SPICE_BOMB = "Spice Bomb"
STRINGS.ACTIONS.CASTAOE.SPICE_BOMB_HEAL    = "Heal Bomb"
STRINGS.ACTIONS.CASTAOE.SPICE_BOMB_ATTACK  = "Attack Bomb"
STRINGS.ACTIONS.CASTAOE.SPICE_BOMB_DEFENSE = "Defense Bomb"
STRINGS.ACTIONS.CASTAOE.SPICE_BOMB_SPEED   = "Speed Bomb"

local TELEPORT_STAFF_STRINGS = {
	GENERIC      = "I can hop out of trouble with this.",
	WAXWELL      = "A dangerous tool like this should be used sparingly.",
	WOLFGANG     = "Wolfgang does not run from fight!",
	WX78         = "I WILL NOT STRIKE FEAR BY RUNNING AWAY",
	WILLOW       = "Bet you can't hit me!",
	WENDY        = "My life ebbs away more with each use.",
	WOODIE       = "I'll never leave you, Luce.",
	WICKERBOTTOM = "Those brutes best stay away!",
	WATHGRITHR   = "This tool is not fit for a warrior!",
	WEBBER       = "We don't understand that.",
	WINONA       = "That can keep me safe in a pinch.",
	WORTOX       = "My weapon's not whole, for it sucks my soul!",
	WORMWOOD     = "Poof stick",
	WARLY        = "This magic is deuced unsettling.",
	WURT         = "It tickles to use, flort!",
}
STRINGS.NAMES.TELEPORT_STAFF = "Soul Scepter"
STRINGS.ACTIONS.CASTAOE.TELEPORT_STAFF = "Teleport"
SetItemsDescribeStrings("TELEPORT_STAFF", TELEPORT_STAFF_STRINGS)

local GAUNTLET_STRINGS = {
	GENERIC      = "This will push my foes out of the way.",
	WAXWELL      = "It's been a while since I ruled with an iron fist.",
	WOLFGANG     = "Mighty punches knock puny foes away!",
	WX78         = "THIS DOES PUT A SMILE ON MY FACE",
	WILLOW       = "That glove is too heavy for me.",
	WENDY        = "It's too big for my hand to fit inside.",
	WOODIE       = "How's this work?",
	WICKERBOTTOM = "I'm not strong enough to brute force enemies away.",
	WATHGRITHR   = "I will push thee back to Hel, beasts!",
	WEBBER       = "It doesn't fit on our hand.",
	WINONA       = "Ha! They can't even touch me!",
	WORTOX       = "The perfect prank pulling gauntlet!",
	WORMWOOD     = "Heavy",
	WARLY        = "What a heavy oven mitt.",
	WURT         = "We can use the gont-lit.",
}
STRINGS.NAMES.GAUNTLET = "Gauntlet"
STRINGS.ACTIONS.CASTAOE.LAVAARENA_GAUNTLET = "Charged Punch"
SetItemsDescribeStrings("GAUNTLET", GAUNTLET_STRINGS)

local TRIDENT_STRINGS = {
	GENERIC      = "Three prongs means triple the power.",
	WAXWELL      = "How improper.",
	WOLFGANG     = "Wolfgang likes the pokey wet stick.",
	WX78         = "TRIPLE TERMINATION SEQUENCE: ENGAGED",
	WILLOW       = "Boring and gross!",
	WENDY        = "It's slippery...",
	WOODIE       = "I can use it if no one else will.",
	WICKERBOTTOM = "I'll leave this for someone else.",
	WATHGRITHR   = "It harnesses the power of Aegir!",
	WEBBER       = "Wurt knows how to use that better than us.",
	WINONA       = "Triple efficiency!",
	WORTOX       = "A sturdy rod I'll use to prod!",
	WORMWOOD     = "Pokey poke poke!",
	WARLY        = "Boar skewers, perhaps?",
	WURT         = "A weapon of the merfolk.",
}
STRINGS.NAMES.FORGE_TRIDENT = "Trident" --TODO Leo: We should probably rename this now that trident actually exists in game.
STRINGS.ACTIONS.CASTAOE.FORGE_TRIDENT = "Summon Merm Guard"
SetItemsDescribeStrings("FORGE_TRIDENT", TRIDENT_STRINGS)

local MERM_GUARD_STRINGS = {
	GENERIC      = "It's fighting for us this time.",
	WAXWELL      = "I still don't know where your kind came from.",
	WOLFGANG     = "Punch many things, friend!",
	WX78         = "OBEY MY COMMAND, MINION. DESTROY EVERYONE",
	WILLOW       = "Go keep those jerks away from us!",
	WENDY        = "How do you do?",
	WOODIE       = "Hey, fish bud. Come to help us out?",
	WICKERBOTTOM = "The piscean biped is on our side, thanks to little Wurt.",
	WATHGRITHR   = "A true warrior of the fish tribe!",
	WEBBER       = "Hey, he's helping us!",
	WINONA       = "As long as he's punching the uglies and not us, I'm fine.",
	WORTOX       = "He's got horns, that's how we know he's good.",
	WORMWOOD     = "Slimy friend",
	WARLY        = "What a fearsome fishmonger.",
	WURT         = "Fight, for king!",
}
STRINGS.NAMES.MERM_GUARD = "Merm Guard"
SetItemsDescribeStrings("MERM_GUARD", MERM_GUARD_STRINGS)

local PORTALSTAFF_STRINGS = {
	GENERIC      = "With this kind of science, we can't possibly lose!",
	WAXWELL      = "Its right up my alley.",
	WOLFGANG     = "Tiny clock on stick.",
	WX78         = "I WANT TO DESTROY MY ENEMIES BEFORE THEY BECOME A THREAT",
	WILLOW       = "It doesn't shoot fire so its inferior.",
	WENDY        = "If only I had this back then...",
	WOODIE       = "Fancy lookin staff, but not my style.",
	WICKERBOTTOM = "Manipulating time should prove to be quite useful for us.",
	WATHGRITHR   = "Now is not the time to look at clocks.",
	WEBBER       = "Is it really safe to mess with time like that?",
	WINONA       = "I'll look into the innerworkings once we're out of here.",
	WORTOX       = "This is copy right infringement, silly mortal.",
	WORMWOOD     = "Tick tock tick tock.",
	WARLY        = "Can it act as a kitchen timer?",
	WURT         = "I must resist chewing on this one for now.",
}
STRINGS.NAMES.PORTALSTAFF = "Backtrek Staff"
STRINGS.ACTIONS.CASTAOE.PORTAL_ACTIVATE = "Teleport"
STRINGS.ACTIONS.CASTAOE.PORTAL_TARGET   = "Set Teleport Location"
SetItemsDescribeStrings("PORTALSTAFF", PORTALSTAFF_STRINGS)

--TODO Leo: Why are these here?
STRINGS.NAMES.PITPIG   = STRINGS.NAMES.BOARON
STRINGS.NAMES.BOARILLA = STRINGS.NAMES.TRAILS
STRINGS.NAMES.SCORPEON = STRINGS.NAMES.PEGHOOK
STRINGS.NAMES.MODDED_CHARACTER = "Modded Character"
STRINGS.NAMES.CHEATER = "CHEATER"

STRINGS.NAMES.CROCOMMANDER_RAPIDFIRE = "Crocommancer"
STRINGS.NAMES.BATTLESTANDARD_SPEED   = "Battle Standard"
STRINGS.NAMES.LAVAARENA_CHEFHAT = "Chapéu do Chef"
STRINGS.NAME_DETAIL_EXTENTION.LAVAARENA_CHEFHAT = "Master Chef Buff\n+20% Red. Recarga"

STRINGS.NAMES.SCORPEON_ACID = "Scorpeon Acid"
STRINGS.NAMES.DEBUFF_FIRE   = "Fire"
STRINGS.NAMES.DEBUFF_POISON = "Poison"
STRINGS.NAMES.NOLIGHT       = "No Light"
STRINGS.NAMES.GREENLIGHT    = "The Green Light"
STRINGS.NAMES.REDLIGHT      = "The Red Light"
STRINGS.NAMES.ORANGELIGHT   = "The Orange Light"
STRINGS.NAMES.BLUELIGHT     = "The Blue Light"

STRINGS.NAMES.FORGEDARTS      = STRINGS.NAMES.BLOWDART_LAVA
STRINGS.NAMES.FORGINGHAMMER   = STRINGS.NAMES.HAMMER_MJOLNIR
STRINGS.NAMES.RILEDLUCY       = STRINGS.NAMES.LAVAARENA_LUCY
STRINGS.NAMES.PITHPIKE        = STRINGS.NAMES.SPEAR_GUNGNIR
STRINGS.NAMES.PETRIFYINGTOME  = STRINGS.NAMES.BOOK_FOSSIL
STRINGS.NAMES.REEDTUNIC       = STRINGS.NAMES.LAVAARENA_ARMORLIGHT
STRINGS.NAMES.FEATHEREDTUNIC  = STRINGS.NAMES.LAVAARENA_ARMORLIGHTSPEED
STRINGS.NAMES.FORGE_WOODARMOR = STRINGS.NAMES.LAVAARENA_ARMORMEDIUM
STRINGS.NAMES.BABYSPIDER      = STRINGS.NAMES.WEBBER_SPIDER_MINION
STRINGS.NAMES.FORGE_ABIGAIL   = STRINGS.NAMES.ABIGAIL
STRINGS.NAMES.FORGE_BERNIE    = STRINGS.NAMES.LAVAARENA_BERNIE
STRINGS.NAMES.FORGE_WOBY      = STRINGS.NAMES.WOBYSMALL
STRINGS.NAMES.BABY_BEN        = "Baby Ben"

STRINGS.CHARACTER_DETAILS.FORGE_STARTING_ITEMS_TITLE = "Enters the Forge With"

STRINGS.UI.LOBBYSCREEN.FORCESTART      = "Force Start"
STRINGS.UI.LOBBYSCREEN.CANCELSTART     = "Cancel Start"
STRINGS.UI.LOBBYSCREEN.SAYSTART        = "Forcing Start in %s seconds. If you don't have a character selected before the countdown is over, then a random character will be selected for you."
STRINGS.UI.LOBBYSCREEN.SAYCANCEL       = "Canceling Start."
STRINGS.UI.LOBBYSCREEN.FORCESTARTTITLE = "Confirm Force Start"
STRINGS.UI.LOBBYSCREEN.FORCESTARTDESC  = "Are you sure you want to force start the match in %s seconds?"
STRINGS.UI.LOBBYSCREEN.SERVER_ANNOUNCEMENT_NAME = "SERVER"

STRINGS.UI.WXPLOBBYPANEL.LEVEL    = "Level {val}"
STRINGS.UI.WXPLOBBYPANEL.MULT_VAL = "{name} x{val}"
STRINGS.UI.WXPLOBBYPANEL.ADD_VAL  = "{name} + x{val}"
STRINGS.UI.WXPLOBBYPANEL.MUTATOR_VAL = "x{val}"
STRINGS.UI.WXPLOBBYPANEL.TOTAL_ROUNDS_COMPLETED = "Total Rounds Completed: {rounds}"
STRINGS.UI.WXPLOBBYPANEL.TOTAL_EXP_GAINED       = "Total Experience Gained: {exp}"
STRINGS.UI.WXP_DETAILS.SAME_CHARACTERS        = "Same Characters" -- TODO better string?
STRINGS.UI.WXP_DETAILS.RANDOM_CHARACTER       = "Random Character"
STRINGS.UI.WXP_DETAILS.RANDOM_CHARACTERS_TEAM = "Random Characters (Team)"
STRINGS.UI.WXP_DETAILS.NO_ABILITIES      = "No Abilities Used" -- TODO better string?
STRINGS.UI.WXP_DETAILS.NO_ABILITIES_TEAM = "No Abilities Used (Team)" -- TODO better string?
STRINGS.UI.WXP_DETAILS.CONSECUTIVE_WIN   = "Unbeatable" -- TODO better string?
STRINGS.UI.WXP_DETAILS.PARTY_SIZE        = "Small Party" -- TODO better string?
STRINGS.UI.WXP_DETAILS.MOB_KILLS         = "Monster Hunter"
STRINGS.UI.WXP_DETAILS.MOB_DAMAGE        = "Damage Mutator" -- TODO better string?
STRINGS.UI.WXP_DETAILS.MOB_DEFENSE       = "Defense Mutator" -- TODO better string?
STRINGS.UI.WXP_DETAILS.MOB_HEALTH        = "Health Mutator" -- TODO better string?
STRINGS.UI.WXP_DETAILS.MOB_SPEED         = "Speed Mutator" -- TODO better string?
STRINGS.UI.WXP_DETAILS.MOB_ATTACK_RATE   = "Attack Rate Mutator" -- TODO better string?
STRINGS.UI.WXP_DETAILS.MOB_SIZE          = "Size Mutator" -- TODO better string?
STRINGS.UI.WXP_DETAILS.BATTLESTANDARD_EFFICIENCY = "Battlestandard Efficiency" -- TODO better string?
STRINGS.UI.WXP_DETAILS.NO_SLEEP        = "Insomniac"
STRINGS.UI.WXP_DETAILS.NO_REVIVES      = "Mortal" -- TODO better string?
STRINGS.UI.WXP_DETAILS.NO_HUD          = "No HUD" -- TODO better string?
STRINGS.UI.WXP_DETAILS.FRIENDLY_FIRE   = "Friendly Fire" -- TODO better string?
STRINGS.UI.WXP_DETAILS.SCRIPTS         = "Spamware" -- TODO better string?
STRINGS.UI.WXP_DETAILS.COMMANDS        = "Console Commander" -- TODO better string?
STRINGS.UI.WXP_DETAILS.HARD_MODE       = "Hard Mode" -- TODO better string?
STRINGS.UI.WXP_DETAILS.CLASSIC_RLGL    = "Classic RLGL" -- TODO better string?
STRINGS.UI.WXP_DETAILS.RLGL            = "RLGL" -- TODO better string?
STRINGS.UI.WXP_DETAILS.ENDLESS         = "Endless" -- TODO better string?
STRINGS.UI.WXP_DETAILS.MOB_DUPLICATOR  = "Duplicator Mutator" -- TODO better string?
STRINGS.UI.WXP_DETAILS.JOINED_MIDMATCH = "Late Bloomer" -- TODO better string?

STRINGS.UI.DETAILEDSUMMARYSCREEN = {
	STATS = {
		TITLES = {
			attack        = "Attack Stats:",
			crowd_control = "Crowd Control Stats:",
			defense       = "Defense Stats:",
			healing       = "Healing Stats:",
			other         = "Other Stats:",
		},
	},
	TITLE = "Detailed Match Summary",
	TEAMSTATS = {
		TITLE = "Detailed Team Stats",
		SHOW = "View Team Stats",
		HIDE = "Go Back to MVP Badges", -- TODO better text for this?
		BACK = "Back",
		STATHEADERS = {
			deaths            = "Deaths",
			total_damagedealt = "Total Damage Dealt",
			kills             = "Killing Blows",
			aggroheld         = "Aggro Time (seconds)",
			corpsesrevived    = "Allies Revived",
			healingdone       = "Health Restored",
			total_damagetaken = "Damage Taken",
			attacks           = "Swings Landed",
			turtillusflips    = "Snortoises Flipped",
			spellscast        = "Spells Cast",
			altattacks        = "Special Attacks Used",
			stepcounter       = "Steps Taken",
			blowdarts         = "Dart hits",
			standards         = "Battle Standards Destroyed",
			numcc             = "Enemies Immobilized",
			guardsbroken      = "Enemy Guards Broken",
			healingreceived   = "Healing Recieved",
			pet_damagetaken   = "Pet Damage Taken",
			player_damagedealt = "Player Damage Dealt",
			player_damagetaken = "Player Damage Taken",
			cctime             = "Seconds of Crowd Control",
			petdeaths          = "Pet Deaths",
			ccbroken           = "Crowd Control Broken",
			pet_damagedealt    = "Pet Damage Dealt",
			unknown            = "UNKNOWN",
			parry              = "Damage Parried",
			perfect_parry      = "Perfect Parries",
			total_friendly_fire_damage_dealt = "Total Friendly Fire Damage Dealt",
			total_friendly_fire_damage_taken = "Total Friendly Fire Damage Taken",
		},
	},
}

STRINGS.UI.ADMINMENU = {
	TABS = {
		ENEMIES    = "Spawn Enemy",
		WEAPONS    = "Spawn Weapon",
		HELMS      = "Spawn Helm",
		ARMOR      = "Spawn Armor",
		PETS       = "Spawn Pet",
		STRUCTURES = "Spawn Structure",
		BUFFS      = "Spawn Buff",
		MUTATORS   = "Adjust Mutators",
		FORGE      = "Forge Admin Commands",
		GENERAL    = "General Admin Commands",
	},
	BUTTONS = {
		SPAWN       = "Spawn",
		ACTIVATE    = "Activate",
		ABILITIES   = "Abilities",
		DESCRIPTION = "Description",
		EQUIP       = "Equip",
		APPLY       = "Apply",
		ENABLE      = "Enable",
		DISABLE     = "Disable",
	},
	NO_ABILITIES = "No abilities",
	STATS = {
		DAMAGE              = "Damage",
		COOLDOWN            = "Cooldown",
		SPEEDMULT           = "Speed",
		BONUSDAMAGE         = "Damage",
		BONUS_COOLDOWNRATE  = "Cooldown",
		HEALINGRECEIVEDMULT = "Healing Received",
		HEALINGDEALTMULT    = "Healing Dealth",
		MAGE_BONUSDAMAGE    = "Magic Damage",
		DEFENSE             = "Defense",
		HEALTH              = "Health",
		RUNSPEED            = "Speed",
	},
}

STRINGS.UI.GAME_SETTINGS_PANEL = {
	TAB        = "Configurações da Partida",
	TITLE      = "Opções de Gameplay",
	PRESET     = "Preset",
	MODE       = "Modo",
	GAMETYPE   = "Gametype",
	WAVESET    = "Waveset",
	MAP        = "Arena",
	DIFFICULTY = "Dificuldade",
	VOTE       = "Vote to Change Settings",
	FORCE      = "Salvar Configurações",
	RESET      = "Resetar Configurações",
}
STRINGS.UI.LEADERBOARD_PANEL = {
	TAB = "Server Leaderboard",
}
STRINGS.UI.FORGEHISTORYPANEL = { -- TODO rename to LEADERBOARDPANEL?
	TAB = "History",
	FILTERS = {
		TITLE = "Filters",
		ON = "On",
		OFF = "Off",

		-- General
		VICTORIES         = "Victories Only",
		LEADERBOARD       = "Leaderboard Runs",
		DEATHLESS         = "Team Deathless",
		PLAYER_DEATHLESS  = "Player Deathless",
		RANDOM_CHARACTERS = "Random Characters",
		UNIQUE_CHARACTERS = "Unique Characters",
		AFK_RUNS          = "AFK Runs",
		COMMANDS          = "Commands Used",
		SCRIPTS           = "Spamware",
		IS_YOU            = "Your Personal Runs",

		-- Modes
		BOARILLA     = "Boarilla",
		BOARRIOR     = "Boarrior",
		RHINODRILL   = "Rhinobros",
		BEETLETAUR   = "Swineclops",
		ORIG_FORGE   = "Original Forge",
		FORGED_FORGE = "Forged Forge",
	},
	SORTERS = {
		MOST_RECENT           = "Recente",
		FASTEST_TIME          = "Mais Rápido",
		LONGEST_TIME          = "Mais Lento",
		RUN_COUNT             = "%s of %s",
		RUNS_TITLE            = "Partidas",
		SORTER_TITLE          = "Sort By",
		NO_RUNS               = "0 Partidas Encontradas",
	},
	AVERAGE_STATS = {
		TITLE                = "Average Stats",
		WIN_RATE             = "Win Rate",
		TOTAL_TIME           = "Total Time",
		AVERAGE_TIME         = "Average Time",
		FASTEST_SLOWEST_TIME = "Fastest/Slowest",
		TOTAL_DEATHS         = "Total Deaths",
		CHARACTER_USAGE      = "Character Usage",
		BUTTON               = "Toggle Average Stats",
		MOST_PLAYED_TITLE    = "Most Played",
	},
	RUN = {
		VICTORY            = "Vitória!",
		DEFEAT             = "Derrota! :(",
		NA                 = "N/A",
		NONE               = "No Run Found",
		EMPTY_LIST         = "No Forge Runs To Display!",
		PLAYER_STATS_TITLE = "%s's Stats",
		BACK_BUTTON        = "Go Back To Team Stats",
	},
}
STRINGS.UI.ACHIEVEMENTS_PANEL = {
	TAB = "Achievements",
}
STRINGS.UI.NEWS_PANEL = {
	TAB = "News",
	SERVER = {
		TITLE = "Server",
		BODY = "Welcome to my ReForged server. Be respectful and Forge On.",
	},
	EVENTS = {
		--TITLE = STRINGS.UI.CUSTOMIZATIONSCREEN.SPECIALEVENT,
		TITLE = "Mod Contest",
		--BODY = "There are currently no active events.",
		BODY = "Klei is currently running an event where users can vote for their favorite spooky themed mod. If you like Hallowed Forge and want to help us win, then go to their discord and vote for us! Be sure to check out the other mods that have been submitted and feel free to vote for whichever you want, but remember you only get one vote (You can change your vote at any time though).\n_________________________________\nVote Here: discord:klei",
	},
	PATCH_NOTES = "Patch Notes",
}

local lavaarena_titles = STRINGS.UI.MVP_LOADING_WIDGET.LAVAARENA.TITLES
lavaarena_titles.player_damagedealt = "Merciless"
lavaarena_titles.player_damagetaken = "Protector"
lavaarena_titles.pet_damagedealt    = "Zookeeper"
lavaarena_titles.pet_damagetaken    = "Loyal Guardian"
lavaarena_titles.cctime             = "Immobilizer"
lavaarena_titles.ccbroken           = "Disruptor"
lavaarena_titles.petdeaths          = "Veterinarian"
lavaarena_titles.healingreceived    = "Spoiled"
lavaarena_titles.total_friendly_fire_damage_dealt = "Traitor"

local lavaarena_desc = STRINGS.UI.MVP_LOADING_WIDGET.LAVAARENA.DESCRIPTIONS
lavaarena_desc.healingreceived    = "cura recebida"
lavaarena_desc.pet_damagetaken    = "dano sofrido por pets"
lavaarena_desc.player_damagedealt = "dano causado"
lavaarena_desc.player_damagetaken = "dano recebido"
lavaarena_desc.cctime             = "segs de controle coletivo"
lavaarena_desc.petdeaths          = "morte de pets"
lavaarena_desc.ccbroken           = "quebra de controle coletivo"
lavaarena_desc.pet_damagedealt    = "dano causado por pets"
lavaarena_desc.unknown            = "DESCONHECIDO"
lavaarena_desc.parry              = "dano defendido"
lavaarena_desc.attack_interrupt   = "ataques interrompidos"
lavaarena_desc.cheater            = "Eu assumo que usei hack..."
lavaarena_desc.total_friendly_fire_damage_dealt = "dano causado em amigos"
lavaarena_desc.total_friendly_fire_damage_taken = "dano recebido de amigos"

STRINGS.REFORGED = {
	-----------
	-- STATS --
	-----------
	STATS = {
		HEALTH = {
			ICON = "half_health",
		},
		DAMAGE = {
			ICON = "spear",
		},
		MAGIC_DAMAGE = {
			ICON = "firestaff_meteor",
		},
		SPEED = {
			ICON = "cane",
		},
		--ELEMENT -- TODO
		DEFENSE = {
			ICON = "lavaarena_armorextraheavy",
		},
		COOLDOWN = {
			ICON = "torch",
		},
		KNOCKBACK = {
			ICON = "torch",
		},
	},
	-------------
	-- ENEMIES --
	-------------
	ENEMIES = { -- TODO if different skins then add that so ENEMIES.BOARON."skin_name".NAME etc default: ENEMIES.BOARON.DEFAULT.NAME
		PITPIG = {
			NAME = "Pit Pig",
			DESC = "The footsoldier of the forge. Is quick but very frail.",
			ABILITIES = {
				LUNGE = {
					NAME = "Lunge",
					DESC = "Lunge that does x damage.",
				},
			},
		},
		CROCOMMANDER = {
			NAME = "Crocommander",
			DESC = "Experienced commander who can inspire allies to be more formidable.",
			ABILITIES = {
				BANNER_DEF = {
					NAME = "Defense Banner",
					DESC = "Increases the armor of allies nearby.",
				},
				BANNER_ATK = {
					NAME = "Attack Banner",
					DESC = "Increases the damage of allies nearby.",
				},
				BANNER_HEAL = {
					NAME = "Regen Banner",
					DESC = "Gives nearby allies health regeneration.",
				},
			},
		},
		CROCOMMANDER_RAPIDFIRE = {
			NAME = STRINGS.NAMES.CROCOMMANDER_RAPIDFIRE,
			DESC = "This croc thinks he's too cool for attack periods.",
			ABILITIES = {
				BANNER_SPEED = {
					NAME = "Speed Banner",
					DESC = "Increases the speed of allies nearby",
				},
			},
		},
		SNORTOISE = {
			NAME = "Tortuguita",
			DESC = "He might be slow, but he can soak up a lot of damage.",
			ABILITIES = {
				BUNKER = {
					NAME = "Bunker",
					DESC = "Retreats into its shell for x seconds unless interrupted by an ability.",
				},
				SPIN = {
					NAME = "Spin",
					DESC = "Retreats into its shell and starts spinning while sliding towards its target for x seconds unless interrupted by an ability.",
				},
			},
		},
		SCORPEON = {
			NAME = "Scorpeon",
			DESC = "He's slow but deadly, he will melt you away with his acid.",
			ABILITIES = {
				POISON = {
					NAME = "Acid Lob",
					DESC = "Lobs a acid ball with its tail. The acid lasts for x seconds.",
				},
			},
		},
		BOARILLA = {
			NAME = "Macacu",
			DESC = "This brute, while not intelligent, can really pack a punch.",
			ABILITIES = {
				BUNKER = {
					NAME = "Bunker",
					DESC = "Bunkers into his armor for x seconds resisting all basic damage.",
				},
				SLAM = {
					NAME = "Slam",
					DESC = "Jumps into the air and slams down on target doing damage in an area.",
				},
			},
		},
		BOARRIOR = {
			NAME = "Boarrior",
			DESC = "A champion who has experience to match with his strength.",
			ABILITIES = {
				SPIN = {
					NAME = "Spin",
					DESC = "Spins like a top damaging all nearby enemies.",
				},
				SLAM = {
					NAME = "Slam",
					DESC = "Slams the ground tearing up the ground that damages any enemy in its path.",
				},
				REINFORCEMENTS = {
					NAME = "Summon Reinforcements",
					DESC = "Claps his weapons together summoning pitpig reinforcements with banners.",
				},
				DASH = {
					NAME = "Dash",
					DESC = "If target is too far away then Boarrior dashes towards them.",
				},
			},
		},
		RHINOCEBRO = {
			NAME = "Agora ou Nunca",
			DESC = "Would probably steal your lunch money.",
			ABILITIES = {
				CHEER = {
					NAME = "Bro Cheer",
					DESC = "Cheers his bro, Flatbrim, to gain a permanent +25 damage boost.",
				},
				RAM = {
					NAME = "Ram",
					DESC = "Charges forward with his horn doing damage in a large radius.",
				},
			},
		},
		RHINOCEBRO2 = {
			NAME = "Rinocimorte",
			DESC = "Would probably stuff you in a locker.",
			ABILITIES = {
				CHEER = {
					NAME = "Bro Cheer",
					DESC = "Cheers his bro, Snapback, to gain a permanent +25 damage boost.",
				},
				RAM = {
					NAME = "Ram",
					DESC = "Charges forward with his horn doing damage in a large radius.",
				},
			},
		},
		RHINOCEBROS = {
			NAME = "Rhinocebros",
			DESC = "Spawn the two as a pair, linked and everything.",
			ABILITIES = {
				CHEER = {
					NAME = "Bro Cheer",
					DESC = "Cheer each other to gain a permanent +25 damage boost.",
				},
				RAM = {
					NAME = "Ram",
					DESC = "Charges forward with his horn doing damage in a large radius.",
				},
			},
		},
		SWINECLOPS = {
			NAME = "Infernal Swineclops",
			DESC = "Pugna's last resort, a ferocious beast imprisoned for how deadly he is.",
			ABILITIES = { --
				DEFENSIVE_STANCE = {
					NAME = "Defensive Stance",
					DESC = "Moves faster, takes 50% less damage, but can only do one attack.",
				},
				OFFENSIVE_STANCE = {
					NAME = "Offensive Stance",
					DESC = "Can combo punches, can buff itself, can use bellyflop, but moves slower.",
				},
			},
		}
	},
	----------
	-- PETS --
	----------
	PETS = { -- TODO if different skins then add that so ENEMIES.BOARON."skin_name".NAME etc default: ENEMIES.BOARON.DEFAULT.NAME
		GOLEM = {
			NAME = "Golem",
			DESC = "Continously throws fireballs at nearby mobs. Can't move though.",
		},
		BABYSPIDER = {
			NAME = "Arainha",
			DESC = "These cute lil fellas will help you take down foes. They can't be targeted or killed.",
		},
		MERM_GUARD = {
			NAME = "Sapão Cabra",
			DESC = "From the swamp comes the menacing merm guards. They will die from overheating after awhile.",
		},
		MEAN_FLYTRAP = {
			NAME = "Planta Carnívora",
			DESC = "Wormwood's friends have come to lend a tooth or two. They will die from the heat after awhile.",
		},
		ADULT_FLYTRAP = {
			NAME = "Armadilha Carnívora",
			DESC = "This fiend will take large bites out of the competition. They will die from the heat after awhile.",
		},
		FORGE_ABIGAIL = {
			NAME = "Abigail",
			DESC = "Wendy's sister has come to throw the game. Respawns quite awhile after death.",
		},
		FORGE_BERNIE = {
			NAME = "Bernie",
			DESC = "He will draw aggro away from you when you're in danger. Can be revived when fallen.",
		},
		FORGE_WOBY = {
			NAME = "Woby",
			DESC = "Bark Bark", -- TODO
		},
		BABY_BEN = {
			NAME = "Bebê Ben",
			DESC = "Wendy's brother wants to play too!",
		},
	},
	----------------
	-- STRUCTURES --
	----------------
	STRUCTURES = {

	},
	-----------
	-- ARMOR --
	-----------
	ARMOR = {
		REEDTUNIC = {
			NAME = "Túnica de Bamboo",
			DESC = "Reeds aren't the best form of defense.",
		},
        FEATHEREDTUNIC = {
			NAME = "Túnica de Bamboo Rápida",
			DESC = "A feather got stuck in your tunic. It makes you run slightly faster.",
		},
        FORGE_WOODARMOR = {
			NAME = "Armadura de Madeira",
			DESC = "Simple yet effective defense.",
		},
        JAGGEDARMOR = {
			NAME = "Jagged Wood Armor",
			DESC = "Decked out in monster teeth, this armor protects AND attacks.",
		},
        SILKENARMOR = {
			NAME = "Silken Wood Armor",
			DESC = "This very simple sash wrapped around wood grants faster cooldowns.",
		},
        SPLINTMAIL = {
			NAME = "Malha de Pedra",
			DESC = "Light stone armor that grants higher defense than wood.",
		},
        STEADFASTARMOR = {
			NAME = "Peitoral de Pedras",
			DESC = "Too many rocks! This heavy armor slows you down, but makes you harder to push around.",
		},
		--Forge Season 2
		STEADFASTGRANDARMOR = {
			NAME = "Steadfast Grand Armor",
			DESC = "Become the ultimate tank!",
		},
		WHISPERINGGRANDARMOR = {
			NAME = "Whispering Grand Armor",
			DESC = "Boost your companions with ancient power!",
		},
		SILKENGRANDARMOR = {
			NAME = "Silken Grand Armor",
			DESC = "The supreme stamina booster!",
		},
		JAGGEDGRANDARMOR = {
			NAME = "Jagged Grand Armor",
			DESC = "Rip and tear through your foes with this armor!",
		},
	},
	-----------
	-- HELMS --
	-----------
	HELMS = {
		FEATHEREDWREATH = {
			NAME = "Feathered Wreath",
			DESC = "Have feet as light as a feather and have the hat to match!",
		},
        FLOWERHEADBAND = {
			NAME = "Flower Headband",
			DESC = "Wear a healing flower on your head! When healed, gain 25% more health.",
		},
        BARBEDHELM = {
			NAME = "Barbed Helm",
			DESC = "Feel the wrath of Barb! Physical attacks deal 10% more damage.",
		},
        NOXHELM = {
			NAME = "Nox Helm",
			DESC = "More horns always means more damage. Specifically, 15% damage.",
		},
        WOVENGARLAND = {
			NAME = "Girlanda do Curandeiro",
			DESC = "Imbued with the power of a mythical dryad, this increases healing dealt by 20%.",
		},
        CLAIRVOYANTCROWN = {
			NAME = "Clairvoyant Crown",
			DESC = "Become a minister of magic! Deal more magic damage, have faster cooldowns and movement speed.",
		},
        CRYSTALTIARA = {
			NAME = "Tiara de Cristal",
			DESC = "Apparently healing crystals aren't a sham! Gain 10% faster cooldowns.",
		},
        BLOSSOMEDWREATH = {
			NAME = "Guirlanda do Regenerador",
			DESC = "Put a miniature healing circle right on your head! Heals 2 HP/sec.",
		},
        RESPLENDENTNOXHELM = {
			NAME = "Resplendent Nox Helm",
			DESC = "This excessive amount of horns grants high physical damage, faster cooldowns and movement speed.",
		},
		LAVAARENA_CHEFHAT = {
			NAME = "Chapéu de Chef",
			DESC = "Wearing this, everyone will believe that you're a master chef, so you no longer need to watch your own food cook.",
		},
	},
	-------------
	-- WEAPONS --
	-------------
	WEAPONS = {
		FORGEDARTS = {
			NAME = "Dardos Simples",
			DESC = "A simple yet powerful blowdart.",
			ABILITIES = {
				BARRAGE = {
					NAME = "Metralha",
					DESC = "Shoot a flurry of darts in one direction.",
				},
			},
		},
		MOLTENDARTS = {
			NAME = "Dardos Derretidos",
			DESC = "Don't burn your tongue!",
			ABILITIES = {
				FIRE_BLAST = {
					NAME = "Tiro Explosivo",
					DESC = "Shoot a single fiery blast of magma at your foes!",
				},
			},
		},
		INFERNALSTAFF = {
			NAME = "Cajado Infernal",
			DESC = "Harness the power of fire!",
			ABILITIES = {
				METEOR = {
					NAME = "Meteoro",
					DESC = "Call down a giant meteor from the heavens!",
				},
			},
		},
		FORGINGHAMMER = {
			NAME = "Martelo Forge",
			DESC = "Bash some skulls in with this heavy hammer.",
			ABILITIES = {
				SLAM = {
					NAME = "Pancada",
					DESC = "Shake the ground at your feet, hitting everything at once.",
				},
			},
		},
		LIVINGSTAFF = {
			NAME = "Cajado de Cura",
			DESC = "A very useful tool to keep you and your allies alive.",
			ABILITIES = {
				HEALING_CIRCLE = {
					NAME = "Círculo Curativo",
					DESC = "Spawn a magical circle of blossoming healing flowers.",
				},
			},
		},
		PITHPIKE = {
			NAME = "Lança",
			DESC = "Wigfrid's go-to weapon for battle.",
			ABILITIES = {
				CHARGE = {
					NAME = "Atravessar",
					DESC = "Dash through your foes, and flip some Snortoises while you're at it.",
				},
			},
		},
		SPIRALSPEAR = {
			NAME = "Lança Espiral",
			DESC = "Keep the pointy end away from you!",
			ABILITIES = {
				SLAM = {
					NAME = "Aterrissar",
					DESC = "Jump high into the sky and SLAM down on the enemy!",
				},
			},
		},
		RILEDLUCY = {
			NAME = "Lucy",
			DESC = "This Lucy is a lot more quiet and ready to fight.",
			ABILITIES = {
				THROW = {
					NAME = "Arremessar",
					DESC = "Throw Woodie's beloved axe headfirst into an enemy.",
				},
			},
		},
		BACONTOME = {
			NAME = "Tomo do Golem",
			DESC = "Summon an ancient ally.",
			ABILITIES = {
				SUMMON_GOLEM = {
					NAME = "Gerar Golem",
					DESC = "Spawns a rock golem from the depths of the Forge.",
				},
			},
		},
		PETRIFYINGTOME = {
			NAME = "Tomo Petrificante",
			DESC = "Makes your enemies scared stiff.",
			ABILITIES = {
				PETRIFY = {
					NAME = "Petrificar",
					DESC = "Encase your foes in a tomb of rocks. Not all of them will stay though.",
				},
			},
		},
        FIREBOMB = {
            NAME = "Cristais Flamejantes",
            DESC = "Don't shake it!",
            ABILITIES = {
                THROW = {
                    NAME = "Arremessar",
                    DESC = "Throw these at the enemy and watch them explode!",
                },
            },
        },
        BLACKSMITHSEDGE = {
            NAME = "Espada de Animê",
            DESC = "You can lift that?!",
            ABILITIES = {
                PARRY = {
                    NAME = "Defender",
                    DESC = "Nothing can get through this blade's heavy hilt!",
                },
            },
        },
		SEEDLINGTOME = { -- TODO
			NAME = "Seedling Tome",
			DESC = "",
			ABILITIES = {
				SUMMON_SEEDLING = {
					NAME = "Summon Seedling",
					DESC = "",
				},
			},
		},
		FLYTRAPTOME = {
			NAME = "Flytrap Tome",
			DESC = "",
			ABILITIES = {
				SUMMON_FLYTRAP = {
					NAME = "Summon Flytrap",
					DESC = "",
				},
			},
		},
		LAVAARENA_SEEDDARTS = {
			NAME = "Dardos de Semente",
			DESC = "Wormwood put his heart into this. And his other limbs.",
			ABILITIES = {
				PLANT_SEEDLING = {
					NAME = "Gerar Planta",
					DESC = "Hastily grow an organic ally.",
				},
			},
		},
		LAVAARENA_SEEDDART2 = {
			NAME = "Dardo Triplo",
			DESC = "Shoot 3 darts at once!",
			ABILITIES = {
				PLANT_SNAPTOOTH = {
					NAME = "Plantar Armadilha",
					DESC = "Grow a rooted Snaptooth to chew up your enemies.",
				},
			},
		},
		TELEPORT_STAFF = {
			NAME = "Machado de Teleporte",
			DESC = "Escape certain doom! For a price...",
			ABILITIES = {
				TELEPORT = {
					NAME = "Teleporte",
					DESC = "Travel wherever your puny heart desires.",
				},
			},
		},
		LAVAARENA_SPATULA = {
			NAME = "Espatula",
			DESC = "Not great as a weapon, but it'll do with a pinch of salt.",
			ABILITIES = {
				COOK = {
					NAME = "Cozinhar",
					DESC = "Cook food for all nearby players and feed them when ready.",
				},
			},
		},
		SPICE_BOMB = {
            NAME = "Bomba Tômpero",
            DESC = "What a pleasant aroma!",
            ABILITIES = {
                THROW = {
                    NAME = "Buff Tômpero",
                    DESC = "Throw these at your allies to make them smelly!",
                },
            },
        },
		FORGE_TRIDENT = {
			NAME = "Tridente",
			DESC = "Don't let the rickety look fool you, this trident packs a punch!",
			ABILITIES = {
				CALL_GUARDS = {
					NAME = "Gerar Sapão Cabra",
					DESC = "Spawn a loyal Merm Guard to fight alongside you.",
				},
			},
		},
		GAUNTLET = {
			NAME = "Manoplana",
			DESC = "Punch through foes with these Hands of Doom.",
			ABILITIES = {
				CHARGED_PUNCH = {
					NAME = "Soco Carregado",
					DESC = "Lean into your punch to knockback anything in your path.",
				},
			},
		},
		FORGE_SLINGSHOT = {
			NAME = "Estilingue",
			DESC = "A simple yet powerful slingshot.", --TODO unique desc
			ABILITIES = {
				POWERSHOT = {
					NAME = "Tiro Incapacitante", --TODO not final name.
					DESC = "Fling an explosive seed at the enemy.", --TODO not final either
				},
			},
		},
		PORTALSTAFF = {
			NAME = "Cajado do Tempo",
			DESC = "Time travel on demand with this fancy staff.",
			ABILITIES = {
				SET_DESTINATION = {
					NAME = "Set Destination", 
					DESC = "This is where you'll time travel too.", 
				},
				SUMMON_RIFT = {
					NAME = "Summon Rift", 
					DESC = "Rip a hole in the fabric of time.", 
				},
			},
		},
		POCKETWATCH_REFORGED = {
			NAME = "Relógio Amaldiçoado",
			DESC = "Let's see if time can heal these wounds.",
			ABILITIES = {
				STOP_TIME = {
					NAME = "Parar o Tempo", 
					DESC = "Freeze your enemies in their most embarrasing moments.", 
				},
			},
		},
	},
	---------------
	-- CHARACTER --
	---------------
	CHARACTER = {
		COOKING = { -- TODO edit/add strings for this or use speech strings if we find one we like
			WARLY = "Order up!",
			OTHER = "Food is Ready!",
		},
	},
	-----------
	-- BUFFS --
	-----------
	BUFFS = {
		BATTLESTANDARD_DAMAGER = {
			NAME = "Damage Banner",
			DESC = "Increases the damage of all mobs by x%.",
		},
		BATTLESTANDARD_SHIELD = {
			NAME = "Shield Banner",
			DESC = "Decreases all damage done to mobs by x%.",
		},
		BATTLESTANDARD_HEAL = {
			NAME = "Heal Banner",
			DESC = "Gives all mobs a regen of x%.",
		},
		BATTLESTANDARD_SPEED = {
			NAME = "Speed Banner",
			DESC = "Increases the speed of all mobs by x%.",
		},
		ACTIVATE_BATTLECRY = {
			NAME = "Activate Battlecry",
			DESC = "If you yell loudly enough everyone around you can hit harder.",
		},
		GIVE_BATTLECRY = {
			NAME = "Give Battlecry",
			DESC = "If you yell at yourself you can hit harder.",
		},
		ACTIVATE_AMPLIFY = {
			NAME = "Activate Amplify",
			DESC = "Make yourself sparkly!",
		},
		ACTIVATE_MIGHTY = {
			NAME = "Activate Mighty",
			DESC = "Tremble before my might!",
		},
		ACTIVATE_SHADOWS = {
			NAME = "Activate Shadows",
			DESC = "Shadows will aid your next attack.",
		},
		ACTIVATE_SHOCK = {
			NAME = "Activate Shock",
			DESC = "Fully charged and ready to shock the next attacker.",
		},
		OVER_9000 = {
			NAME = "Over 9000!!!",
			DESC = "His power level is over 9000!!!!!!",
		},
		NO_COOLDOWN = {
			NAME = "No Cooldown",
			DESC = "Patience is for losers",
		},
		SCORPEON_DOT = {
			NAME = "Spawn Scorpeon Poison",
			DESC = "Poison yourself!",
		},
	},
	-----------
	-- FORGE -- TODO better name? maybe put all command related strings in a table to better organize this
	-----------
	FORGE = {
		FORCE_ROUND = {
			NAME = "Force Round",
			DESC = "Select the round and wave you want to fight.",
		},
		RESTART_FORGE = {
			NAME = "Restart Forge",
			DESC = "Reloads the server to completely restart the Forge.",
		},
		RESTART_CURRENT_ROUND = {
			NAME = "Restart Current Round",
			DESC = "Restarts the current round and wave.",
		},
		DISABLE_ROUNDS = {
			NAME = "Disable Rounds",
			DESC = "Rounds/Waves will not automatically start after killing all mobs.",
		},
		ENABLE_ROUNDS = {
			NAME = "Enable Rounds",
			DESC = "Rounds/Waves will automatically start after killing all mobs.",
		},
		END_FORGE = {
			NAME = "End Forge",
			DESC = "Ends the match immediately.",
		},
	},
	-------------
	-- GENERAL --
	-------------
	GENERAL = {
		CHANGE_CHARACTER = {
			NAME = "Change Character",
			DESC = "Return to character select screen.",
		},
		SUPER_GOD_MODE = {
			NAME = "Super God Mode",
			DESC = "What's better than god mode? SUPER GOD MODE!",
		},
		KILL_ALL_MOBS = {
			NAME = "Kill All Mobs",
			DESC = "Care to snap your fingers?",
		},
		PETRIFY_MOBS = {
			NAME = "Petrify",
			DESC = "Petrify all mobs around you. This has the same radius as the Petrifying Tome.",
		},
		RESET_TO_SAVE = {
			NAME = "Reset to Save",
			DESC = "Resets server to last save. Quick for testing out new builds!",
		},
		DEBUG_SELECT = {
			NAME = "Debug Select",
			DESC = "Select the chosen entity to be displayed in the debug screen. Hit backspace to access the debug screen.",
		},
		REVIVE = {
			NAME = "Revive Player",
			DESC = "Give the selected player mouth to mouth? Pfft, I'll just poke their body with a stick.",
		},
	},
	-----------------
	-- BUFF WIDGET --
	-----------------
	BUFF_WDGT = { -- TODO what strings are these? seem more like variable names
		SCORPEON_DOT            = "SCORPEON_DOT",
		HEALINGCIRCLE_REGENBUFF = "HEALINGCIRCLE_REGENBUFF",
		DAMAGER_BUFF            = "DAMAGER_BUFF",
		WICK_BUFF               = "WICK_BUFF",
	},
	------------------
	-- DIFFICULTIES --
	------------------
	DIFFICULTIES = {
		normal = {
			name = "Normal",
			desc = "Moderately fun!"
		},
		hard   = {
			name = "Hard",
			desc = "Good luck!"
		},
	},
	---------------
	-- GAMETYPES --
	---------------
	GAMETYPES = {
		forge = {
			name = "Forge",
			desc = "Defeat all enemies to Forge a path to victory!"
		},
		classic_rlgl = {
			name = "Redlight/Greenlight",
			desc = "The original RLGL from Forged Forge."
		},
		rlgl = {
			name = "RLGLBLOL",
			desc = "I want a blue light, an orange light, all of the lights!"
		},
	},
	-----------
	-- MAPS --
	-----------
	MAPS = {
		lavaarena = {
			name = "Lava Arena",
			desc = "Home to pitpigs!"
		},
		reforged_tiles_arena = {
		    name = "ReForged Tiles",
		    desc = "Available Tiles!"
		},
		--lavaarena_test = "ReForged",
	},
	-----------
	-- MODES --
	-----------
	MODES = {
		forge    = { -- TODO remove
			name = "Forge",
			desc = "The original event."
		},
		forge_s01 = {
			name = "Forge S01",
			desc = "The original event."
		},
		forge_s02 = {
			name = "Forge S02",
			desc = "Forge has returned with rolling Boarillas!"
		},
		reforged = {
			name = "ReForged",
			desc = "Our own version of the Forge!"
		},
		forged_forge = {
			name = "Forged Forge",
			desc = "Currently in beta."
		},
	},
	--------------
	-- MUTATORS --
	--------------
	MUTATORS = { -- TODO change to table for name and desc
		-- Mob Stats
		mob_damage_dealt = {
			name = "Dano Inimigo",
			desc = "Adjust the damage of all mobs."
		},
		mob_damage_received = {
			name = "Defesa Inimiga",
			desc = "Adjust the defense of all mobs."
		},
		mob_health = {
			name = "Vida Inimiga",
			desc = "Adjust the health of all mobs."
		},
		mob_speed = {
			name = "Velocidade Inimiga",
			desc = "Adjust the speed of all mobs."
		},
		mob_attack_rate = {
			name = "Vel. Ataque Inimiga",
			desc = "Adjust the attack rate of all mobs."
		},
		mob_size = {
			name = "Altura Inimiga",
			desc = "Adjust the size of all mobs."
		},
		-- Structure Stats
		battlestandard_efficiency = {
			name = "Mult dos Banners",--"Battlestandard Efficiency",
			desc = "Adjust the multiplier of all battlestandards."
		},
		-- Other
		no_sleep = {
			name = "No Sleep",
			desc = "Who needs sleep? Mobs sure don't!"
		},
		no_revives = {
			name = "No Revives",
			desc = "Did you die? Git Gud."
		},
		no_hud = {
			name = "No Hud",
			desc = "How much health do I have?"
		},
		friendly_fire = {
			name = "Friendly Fire",
			desc = "Have you ever wanted to hit your friend? Well...now you can!"
		},
		unbreakable_shields = {
			name = "Unbreakable Shields",
			desc = "Thought bunkered enemies were tough before?"
		},
		endless = {
			name = "Endless",
			desc = "It just keeps going and going and going... well... until you die!"
		},
		mob_duplicator = {
			name = "Duplicator",
			desc = "Adjust the number of mobs that spawn.",
		}
	},
	--------------
	-- PRESETS --
	--------------
	PRESETS = {
		forge_season_1     = "Forge S01",
		forge_season_2     = "Forge S02",
		half_the_wrath     = "Half The Wrath",
		double_trouble     = "Double Trouble",
		triple_threat      = "Triple Threat",
		quintuple_struggle = "Quintuple Struggle",
		tenfold_terror     = "Tenfold Terror",
		fast_but_weak  = "Fast/Weak",
		x2             = "x2",
		x3             = "x3",
		half           = "1/2",
		mutated        = "Mutated",
		double_doom    = "Double Doom",
		chaotic        = "Chaotic",
		coffee         = "Coffee'd",
		double_half    = "Double 1/2",
		half_double    = "Half x2",
		attack_of_titans = "Attack of Titans",
		insanity       = "Insanity",
		custom         = "Custom",
	},
	--------------
	-- WAVESETS --
	--------------
	WAVESETS = {
		classic = {
			name = "Classic",
			desc = "Take on the original forge and try to defeat the Grand Forge Boarrior!"
		},
		boarilla = {
			name = "Boarilla", -- TODO better name?
			desc = "A mighty Boarilla joins the fight!"
		},
		boarillas = {
			name = "Twin Boarillas", -- TODO better name?
			desc = "Boarillas have rolled in to prevent your victory!"
		},
		rhinocebros = {
			name = "Rhinocebros",-- TODO better name?
			desc = "Two brothers arrive after hearing the Grand Forge Boarrior was defeated!"
		},
		swineclops = {
			name = "Swineclops", -- TODO better name?
			desc = "After the defeat of the Grand Forge Boarrior and the Rhinobros, a new enemy arrives to prevent your victory."
		},
		default = {
			name = "Swineclops", -- TODO remove
			desc = "After the defeat of the Grand Forge Boarrior new enemies arrive to prevent your victory."
		},
		double_trouble_classic = {
			name = "DT Classic",
			desc = "Duplication science has been discovered!"
		},
		double_trouble = {
			name = "Double Trouble",
			desc = "Duplication science has expanded to Swineclops!"
		},
		half_the_wrath = {
			name = "Half The Wrath",
			desc = "All boss enemies have been smallified and the spawns are cut in half! Can you defeat them?"
		},
		sandbox = {
			name = "Sandbox",
			desc = "Play around with all the mobs and items in the Forge!"
		},
		randomized = {
			name = "Randomized",
			desc = "Who knows how this run will turn out!"
		},
	},
	----------
	-- RLGL --
	----------
	RLGL = {
		GREENLIGHT                = "GREEN LIGHT!",
		GREENLIGHT_SPEECH         = {"VIVO!"},
		GREENLIGHT_FAKEOUT_BANTER = { "GREEN FLIGHT", "GREEN SIGHT", "GREEN FIGHT", "GREEN LITE", "GREEN MIGHT", "GREEN RIGHT", "GREEN KITE", "GREEN WHITE" },
		REDLIGHT                = "RED LIGHT!",
		REDLIGHT_SPEECH         = {"MORTO!"},
		REDLIGHT_FAKEOUT_BANTER = { "RED FLIGHT", "RED SIGHT", "RED FIGHT", "RED LITE", "RED MIGHT", "RED RIGHT", "RED KITE", "RED WHITE" },
		ORANGELIGHT                = "ORANGE LIGHT!",
		ORANGELIGHT_SPEECH         = {"ORANGE LIGHT!"},
		ORANGELIGHT_FAKEOUT_BANTER = { "ORANGE FLIGHT", "ORANGE SIGHT", "ORANGE FIGHT", "ORANGE LITE", "ORANGE MIGHT", "ORANGE RIGHT", "ORANGE KITE", "ORANGE WHITE" },
		BLUELIGHT                = "BLUE LIGHT!",
		BLUELIGHT_SPEECH         = {"BLUE LIGHT!"},
		BLUELIGHT_FAKEOUT_BANTER = { "BLUE FLIGHT", "BLUE SIGHT", "BLUE FIGHT", "BLUE LITE", "BLUE MIGHT", "BLUE RIGHT", "BLUE KITE", "BLUE WHITE" },
		NOLIGHT                = "NO LIGHT!",
		NOLIGHT_SPEECH         = {"NO LIGHT!"},
		NOLIGHT_FAKEOUT_BANTER = { "NO FLIGHT", "NO SIGHT", "NO FIGHT", "NO LITE", "NO MIGHT", "NO RIGHT", "NO KITE", "NO WHITE" },
	},
	------------------
	-- USERCOMMANDS --
	------------------
	USERCOMMANDS = {
		START_VOTE_TITLE      = "Start Vote",
		START_VOTE_DESC       = "Make a decision as a group!",
		SUBMIT_VOTE_TITLE     = "Submit Vote",
		SUBMIT_VOTE_DESC      = "Let your voice be heard in the active vote!",
		CANCEL_VOTE_TITLE     = "Cancel Vote",
		CANCEL_VOTE_DESC      = "Silence everyones voices by canceling the active vote!",
		UPDATE_USER_EXP_TITLE = "Update User Exp",
		UPDATE_USER_EXP_DESC  = "Let the server know what your total exp is!",
		UPDATE_USERS_FRIENDS_TITLE      = "Update Users Friend Count",
		UPDATE_USERS_FRIENDS_DESC       = "Let the server know how many of your friends are here!",
		UPDATE_USERS_CURRENT_PERK_TITLE = "Update Users Current Perk",
		UPDATE_USERS_CURRENT_PERK_DESC  = "Let the server know which perk you chose.",
	},
	----------
	-- VOTE --
	----------
	VOTE = {
		TITLE   = "Vote Now!",
		FAILED  = "Vote Failed!",
		SUCCESS = "Vote Succeeded!",
		CANCELED = "Vote has been canceled!",
		SETTINGS_DESC    = "%s wants to make these changes to the settings:",
		SETTINGS_INFO    = "View Settings!",
		SETTINGS_TITLE   = "Vote to change settings!",
		SETTINGS_FAILED  = "Settings have not been changed!",
		SETTINGS_SUCCESS = "Settings have been changed!",
		KICK_TITLE   = "Vote to kick %s",
		KICK_FAILED  = "%s was not kicked!",
		KICK_SUCCESS = "%s has been kicked!",
		FORCE_START_TITLE   = "Vote to Force Start",
		FORCE_START_FAILED  = "Match Will Not Force Start!",
		FORCE_START_SUCCESS = "Forcing Match To Start!",
		CANCEL_FORCE_START_TITLE   = "Vote to Cancel Force Start",
		CANCEL_FORCE_START_FAILED  = "Force Start Not Canceled!",
		CANCEL_FORCE_START_SUCCESS = "Force Start Canceled!",
	},
	--------------------
	-- ADMIN COMMANDS --
	--------------------
	ADMIN_COMMANDS = { -- TODO should this be in the admin menu section???
		SPAWNING_ENT         = "Spawning %d %s.",
		EQUIPPING_ITEM       = "Equipping %s.",
		ACTIVATING_BATTLECRY = "Hear me ROAR!",
		GIVING_BATTLECRY     = "I must roar too!", -- TODO
		OVER_9000            = "My power level is OVER 9000!",
		UNDER_9000           = "I feel so weak.", -- TODO
		SUPER_GOD_MODE       = "I have become a GOD!",
		MORTAL_MODE          = "I am only human.",
		MIGHTY               = "You made me ANGRY!",
		AMPLIFY              = "I'm all sparkly!",
		SHADOWS              = "Arise my minions!",
		SHOCK                = "Don't touch me!",
		PETRIFY              = "Giving you that cold as stone look!",
		REVIVE               = "My soul returns!",
		ROUND_AND_WAVE_SELECT = "Starting Round %d, Wave %d",
		RESTART_ROUND        = "Restarting Round %d",
		ENABLE_WAVES         = "Enabling Waves",
		DISABLE_WAVES        = "Disabling Waves",
		KILL_ALL_MOBS        = "Killing all mobs",
		POISON               = "Someone has poisoned me!",
		ADJUST_MUTATOR       = "Adjusting %s to %s",
	},
	FORGELORD_DIALOGUE = {
		RANDOMIZED = {
			ROUND_1_START = {
				"Round 1 Start!",
			},
			ROUND_1_FINAL_BANTER = {
				"Round 1 Final Wave",
			},
			ROUND_2_START = {
				"Round 2 Start!",
			},
			ROUND_2_FINAL_BANTER = {
				"Round 2 Final Wave",
			},
			ROUND_3_START = {
				"Round 3 Start!",
			},
			ROUND_3_FINAL_BANTER = {
				"Round 3 Final Wave",
			},
			ROUND_4_START = {
				"Round 4 Start!",
			},
			ROUND_4_FINAL_BANTER = {
				"You only delay what is inevitable!",
				"Round 4 Final Wave",
			},
			ROUND_5_START = {
				"Round 5 Start!",
			},
			ROUND_5_FINAL_BANTER = {
				"ENOUGH! Release all who are left!",
				"No more games, your fun is ending now!",
			},
			HEALTH_INTRO_BANTER = {
				"Those %s sure are tanky!",
        		"Drive the interlopers back!",
        		"Do not hold back! Kill them!",
			},
			HEALTH_WARNING_BANTER = {
				"The %s are getting tired!",
        		"You've hurt my %s!",
        		"Those %s don't have much left in them!",
			},
			TIME_INTRO_BANTER = {
				"Better be quick!",
        		"Reinforcements are on their way!",
        		"Take your time, your end is soon!",
			},
			TIME_WARNING_BANTER = {
				"Times ticking!",
        		"The clocks almost broken!",
        		"Tick Tock Tick Tock!",
			},

		},
	},
	--[[
	TODO
		another option would be to make another component status_effect
			have debuffable call it
			have other sources call it
				battlecry
				sleep
				petrify
					sleep and petrify could be added through commonstates
	--]]
	DEBUFFS = { -- TODO all of them? should they have name and desc?
		healingcircle_regenbuff = "Cura",
		debuff_armorbreak = "Armadura Quebrada",
		debuff_fire = "TA PEGANDO FOGO BIXO",
		debuff_haunt = "Haunted",
		debuff_wet = "Molhado",
		spatula_food_buff = "Alimentado",
		debuff_mfd = "Marked",
		trap_snare_debuff = "Trapped",
		buff_woby = "Quem é um bom garoto?!",
		scorpeon_dot = "Veneno",
		debuff_spice_dmg = "Força+",
		debuff_spice_def = "Defesa+",
		debuff_spice_speed = "Velocidade+",
		debuff_spice_regen = "Regeneração",
		debuff_shield = "Protegido",
		shield_buff = "Defense Banner",
		damager_buff = "Attack Banner",
		healer_buff = "Heal Banner",
		speed_buff = "Speed Banner",
	},
	PERKS = {
		generic = {
			tank = {
				TITLE       = "Tank",
				DESCRIPTION = "Tank buster",
			},
			dps = {
				TITLE       = "DPS",
				DESCRIPTION = "Damage Dealer",
			},
			support = {
				TITLE       = "Support",
				DESCRIPTION = "Supporter",
			},
		},
		spectator = {
			spy = {
				TITLE       = "O Espião",
				DESCRIPTION = "*Câmera livre.\n*Pode focar em um jogador para a câmera segui-lo.\n",
				STARTING_HEALTH = "∞",
			},
		},
		random = {
			full_random = {
				TITLE       = "Totalmente Aleatório",
				DESCRIPTION = "Escolhe um personagem e perk aleatórios",
				STARTING_ITEMS = "Os itens iniciais variam dependendo do personagem.",
			},
			base_random = {
				TITLE       = "Aleatório",
				DESCRIPTION = "Escolhe um personagem aleatório com seu perk original do Forge!",
				STARTING_ITEMS = "Os itens iniciais variam dependendo do personagem.",
			},
		},
		wilson = {
			revive = {
				TITLE       = "O Cientista Frustrado",
				DESCRIPTION = "*Revive aliados 50% mais rápido.\n*Recupera mais vida de aliados revividos.\n\nEspecialidades: \nCorpo a Corpo, Dardos e Cajados.",
			},
		},
		willow = {
			bernie = {
				TITLE       = "Bernie Builder",
				DESCRIPTION = "*Protegida por Bernie, o urso de pelúcia.\n*Bernie só pode ser ressussitado por Willow.\n\nEspecialidades: \nDardos e Cajados.",
			},
			fire = {
				TITLE       = "A Maga Infernal",
				DESCRIPTION = "*Um Cajado Infernal extra aparecerá na batalha.\n*+10% Dano de fogo e explosivo.\n\nEspecialidades: \nDardos e Cajados.",
			},
		},
		wendy = {
			abigail = {
				TITLE       = "A jovem de luto",
				DESCRIPTION = "*Protegida por sua irmã gêmia, Abigail.\n*Abigail é revivida automaticamente.\n\nEspecialidades: \n Dardos e Cajados.",
			},
			baby_ben = {
				TITLE       = "A Babá",
				DESCRIPTION = "*Acompanhada de seu irmão Bebê Ben.\n*Bebê Ben dá escudo a aliados atingidos.\n\nEspecialidade:\nDardos e Cajados.",
			},
		},
		woodie = {
			lucy = {
				TITLE       = "O Lenhador",
				DESCRIPTION = "*Lucy retorna ao Woodie após arremessada, gerando bastante agressividade.\n*Maior velocidade de ataque com Lucy.\n\nEspecialidade: \nCorpo a Corpo.",
			},
		},
		wolfgang = {
			mighty = {
				TITLE       = "O Halterofilista",
				DESCRIPTION = "*Fica Poderoso quando está com pouca vida, aumentando seu ataque, defesa e velocidade de movimento por 20 seg.\n\nEspecialidade: \nCorpo a Corpo.",
			},
			restore = {
				TITLE       = "O Regenerador",
				DESCRIPTION = "*Tem uma pequena regeneração de vida constante.\n\nEspecialidade: \nCorpo a Corpo.",
			},
		},
		wx78 = {
			shock = {
				TITLE       =  "O Robô Eletrificado",
				DESCRIPTION = "*Dá choque nos inimigos próximos após ser atacado 3 vezes.\n*+50% Dano Elétrico.\n*Vida Máxima aumentada para 175.\n\nEspecialidades: \nCorpo a Corpo e Cajados.",
			},
			overcharge = {
				TITLE       = "O Robô Sobrecarregado",
				DESCRIPTION = "*Fica Sobrecarregado ao receber ataques elétricos, ganhando vida, luz e +20% Velocidade de movimento.\n*È revivido 20% mais rápido.\n\nEspecialidades: \nCorpo a Corpo e Cajados.",
			},
		},
		wickerbottom = {
			amplify = {
				TITLE       =  "Anciã Amplificada",
				DESCRIPTION = "*Ganha uma bônus depois de causar certo dano.\n*O bônus se aplica para Feitiços, os amplificando.\n\nEspecialidades: \nCajados e Livros.",
			},
			bookers = {
				TITLE       =  "A Bibliotecária",
				DESCRIPTION = "*Um Livro Golem extra aparecerá na batalha.\n*+40% Duração de Feitiços.\n*Revive aliados 25% mais rápido.\n\nEspecialidade: \nLivros.",
			},
		},
		wes = {
			aggro = {
				TITLE       =  "A Isca Humana",
				DESCRIPTION = "*É revivido 50% mais rápido.\n*Gera menos agressividade quando ataca mas é difícil perde-la dos inimigos.\n*+20% Velocidade de movimento\n\nEspecialidades: \nCorpo a Corpo, Dardos e Cajados.",
			},
		},
		waxwell = {
			shadows = {
				TITLE       =  "O Mestre das Sombras",
				DESCRIPTION = "*Invoca duelistas das sombras depois de causar muito dano num único alvo.\n*+10% Dano Mágico.\n\nEspecialidades: \nCajados e Livros.",
			},
			granmage = {
				TITLE       =  "O Mago Implacável",
				DESCRIPTION = "*+10% Redução de Recarga.\n*+10% Duração de Feitiços.\n*Dá +10% de Cura.\n*Causa 25% meno Dano Base.\n\nEspecialidades: \nCajados e Livros.",
			},
		},
		wathgrithr = {
			battlecry = {
				TITLE       =  "A Guerreira Nórdica",
				DESCRIPTION = "*Começa a batalha com sua Lança.\n*Solta Gritos de Guerra ao causar certo dano, dando +25% dano a aliados próximos.\n*Recebe menos agressividade ao atacar.\n*Receberá a Lança Espiral.\n\nEspecialidades: \nCorpo a Corpo e Dardos",
			},
		},
		webber = {
			baby_spiders = {
				TITLE       = "O Líder das Aranhas",
				DESCRIPTION = "*Acompanhado pelas suas aranhas.\n*As aranhas não sofrem dano algum, sendo imortais.\n\nEspecialidade: \nDardos.",
			},
			tankers = {
				TITLE       = "O Mutante",
				DESCRIPTION = "*Vida Máxima aumentada para 200 \n*+10% Velocidade de movimento\n\nEspecialidades: \nCorpo a Corpo e Dardos.",
			},
		},
		winona = {
			cooldown = {
				TITLE       =  "A Multitarefa",
				DESCRIPTION = "*+10% de Redução de Recarga de ataques especiais.\n\nEspecialidades: \nCorpo a Corpo, Dardos e Cajados.",
			},
		},
		wortox = {
			soul_drain = {
				TITLE       =  "O Demônio Faminto",
				DESCRIPTION = "*Começa com seu Machado de Teleporte.\n*Cause dano e regenere sua vida e de aliados próximos.\n*Receberá as Manóplas.\n\nEspecialidade: \nCorpo a Corpo.",
			},
		},
		wormwood = {
			bloom = {
				TITLE       =  "O Jardineiro",
				DESCRIPTION = "*Começa a batalha com seu Dardo de Sementes.\n*Florece caso evite dano, ganhando Velocide de movimento e solta polén que enfraquece inimigos.\n*Receberá o Dardo de Super Sementes.\n\nEspecialidade: \nDardos e Cajados.",
			},
		},
		warly = {
			spices = {
				TITLE       = "'Lhe Falta Tômpero'",
				DESCRIPTION = "*O Cajado de Cura é trocado pelo Saco de Tômpero que pode aplicar vários buffs em aliados e debuffs em inimigos.\n*Dá +20% de Cura.\n\nEspecialidades: \nCorpo a Corpo e Cajados.",
			},
			cookpot = {
				TITLE       = "O Master Chef",
				DESCRIPTION = "*A Espátula cozinha hambúrgueres que dão bônus a aliados e regeram vida.\n*O Chapéu de Chef o permite andar/atacar enquanto prepara os hambúrgueres.\n\nEspecialidades:\nCorpo a Corpo e Cajados.",
			},
		},
		wurt = {
			wet = {
				TITLE       = "A Sapa Cabra",
				DESCRIPTION = "*Pode deixar inimigos molhados, reduzindo sua velocidade de movimento e amplificando ataques elétricos.\nReceberá o Tridente.\n\nEspecialidades: \nCorpo a Corpo, Dardos, Cajados e Livros.",
			},
		},
		walter = {
			woby = {
				TITLE       = "O Escoteiro Destemido",
				DESCRIPTION = "*Acompanhado de seu melhor amigo, Woby.\n*Interagir com Woby beneficia aliados próximos com redução de recarga.\n*Receberá o Estilingue.\n\nEspecialidades: \nDardos e Livros.",
			},
		},
		wanda = {
			rewind = {
				TITLE       = "A Imortal",
				DESCRIPTION = "*Pode se reviver automaticamente.\n*+15% Duração de Feitiços.\n*Receberá o Cajado de Portais.\n\nEspecialidades: \nCorpo a Corpo, Cajados e Livros.",
			},
			age = {
				TITLE       = "A Anciã do Tempo",
				DESCRIPTION = "*Perde vida sem parar.\n*Até +50% dano com baixa vida.\n*Receberá o Relógio Amaldiçoado que volta a vida de aliados e congela inimigos.\n\nEspecialidades: \nCorpo a Corpo, Cajados e Livros.",
			},
		},
		UNKNOWN = "Unknown Perk",
	},
	ACHIEVEMENTS = {
		common = {
			TITLE = "Common",
			DESCRIPTION = "Common Test. This is a test to see how long descriptions are displayed in the descriptions box on the achievements panel. Hopefully it positions itself inside the box.",
		},
		classy = {
			TITLE = "Classy",
			DESCRIPTION = "Classy Test",
		},
		spiffy = {
			TITLE = "Spiffy",
			DESCRIPTION = "Spiffy Test",
		},
		distinguished = {
			TITLE = "Distinguished",
			DESCRIPTION = "Distinguished Test",
		},
		elegant = {
			TITLE = "Elegant",
			DESCRIPTION = "Elegant Test",
		},
		loyal = {
			TITLE = "Loyal",
			DESCRIPTION = "Loyal Test",
		},
		timeless = {
			TITLE = "Timeless",
			DESCRIPTION = "Timeless Test",
		},
		event = {
			TITLE = "Event",
			DESCRIPTION = "Event Test",
		},
		victory = {
			TITLE = "Victory",
			DESCRIPTION = "Beat the Forge!",
		},
		defeat = {
			TITLE = "Defeat",
			DESCRIPTION = "The Forge beat you!",
		},
		swineclops_reforged = {
			TITLE = "Normie Knockout",
			DESCRIPTION = "Defeat the Swineclops in Reforged.",
		},
		swineclops_hard = {
			TITLE = "Hard Head",
			DESCRIPTION = "Defeat the Swineclops on hard difficulty.",
		},
		dt_normal = {
			TITLE = "Double Trouble",
			DESCRIPTION = "Defeat the Swineclops waveset with Duplicator on 2.",
		},
		dt_normal_6 = {
			TITLE = "Double Dent",
			DESCRIPTION = "Defeat the Swineclops waveset with Duplicator on 2, with a team of 6 or less people.",
		},
		dt_hard = {
			TITLE = "Double Danger",
			DESCRIPTION = "Defeat the Swineclops waveset with Duplicator on 2, with a team of 6 or less people on hard difficulty.",
		},
		tt_normal = {
			TITLE = "Triple Threat",
			DESCRIPTION = "Defeat the Swineclops waveset with Duplicator on 3",
		},
		tt_normal_6 = {
			TITLE = "Triple Class",
			DESCRIPTION = "Defeat the Swineclops waveset with Duplicator on 3, with a team of 6 or less people.",
		},
		tt_hard = {
			TITLE = "Triple Tyrant",
			DESCRIPTION = "Defeat the Swineclops waveset with Duplicator on 3, with a team of 6 or less people on hard difficulty.",
		},
		quad_normal = {
			TITLE = "Quadruple Cunning",
			DESCRIPTION = "Defeat the Swineclops waveset with Duplicator on 4.",
		},
		quin_normal = {
			TITLE = "Quintuple Struggle",
			DESCRIPTION = "Defeat the Swineclops waveset with Duplicator on 5.",
		},
		ten_normal = {
			TITLE = "Tenfold Terror",
			DESCRIPTION = "Defeat the Swineclops waveset with Duplicator on 10.",
		},
		insanity = {
			TITLE = "Insane Lane",
			DESCRIPTION = "Defeat the 'Insanity' preset with a team of 6 or less people.",
		},
		titans = {
			TITLE = "The Survey Corps",
			DESCRIPTION = "Defeat the 'Attack of Titans' preset with a team of 6 or less people.",
		},
		late = {
			TITLE = "Late Arrival",
			DESCRIPTION = "Join a game within 5 minutes after it has started and win the match.",
		},
		plane = {
			TITLE = "Plane Departing",
			DESCRIPTION = "Join a 12 player game within 5 minutes after it has started and then continue to the end and win.",
		},
		rlgl_normal = {
			TITLE = "Lights Up",
			DESCRIPTION = "Beat the Swineclops waveset in 'Red-Light Green-Light' mode.",
		},
		rlglolbl_normal = {
			TITLE = "Traffic Stopper",
			DESCRIPTION = "Beat the Swineclops waveset in 'Red-Light Green-Light Orange-Light Blue-Light' mode.",
		},
		rainbow_normal = {
			TITLE = "Over The Rainbow",
			DESCRIPTION = "Beat the Swineclops waveset in 'Rainbow-Lights' mode.",
		},
		rlgl_hard = {
			TITLE = "Light Imp",
			DESCRIPTION = "Beat the Swineclops waveset in 'Red-Light Green-Light' mode on hard difficulty.",
		},
		rlglolbl_hard = {
			TITLE = "Traffic Demon",
			DESCRIPTION = "Beat the Swineclops waveset in 'Red-Light Green-Light Orange-Light Blue-Light' mode on hard difficulty.",
		},
		rainbow_hard = {
			TITLE = "Hell Raver",
			DESCRIPTION = "Beat the Swineclops waveset in 'Rainbow-Lights' mode on hard difficulty.",
		},
		rlgl_no_deaths = {
			TITLE = "What A Lighty",
			DESCRIPTION = "Without any teammates dying, beat the Swineclops waveset in 'Red-Light Green-Light' mode.",
		},
		rlglolbl_no_deaths = {
			TITLE = "Pulses Lights",
			DESCRIPTION = "Without any teammates dying, beat the Swineclops waveset in 'Red-Light Green-Light Orange-Light Blue-Light' mode.",
		},
		rainbow_no_deaths = {
			TITLE = "Shine On Me",
			DESCRIPTION = "Without any teammates dying, beat the Swineclops waveset in 'Rainbow-Lights' mode.",
		},
		endless = {
			TITLE = "The Neverending Story",
			DESCRIPTION = "Beat at least 3 full rounds of the Swineclops waveset in endless.",
		},
		no_revives = {
			TITLE = "Big Boy's Club",
			DESCRIPTION = "Beat the Swineclops waveset with the 'No Revives' mutator enabled.",
		},
		no_hud = {
			TITLE = "Eyes on the Road",
			DESCRIPTION = "Beat the Swineclops waveset with the 'No Hud' mutator enabled.",
		},
		no_sleep = {
			TITLE = "Sleepless In Seattle",
			DESCRIPTION = "Beat the Swineclops waveset with the 'No Sleep' mutator enabled.",
		},
		friendly_fire = {
			TITLE = "Don't Trust Anyone",
			DESCRIPTION = "Beat the Swineclops waveset with the 'Friendly Fire' mutator enabled.",
		},
		no_friendly_fire = {
			TITLE = "True Friends",
			DESCRIPTION = "While in a team of 6 or less people, defeat the Swineclops waveset with the 'Friendly Fire' mutator enabled without anyone taking damage from a teammate.",
		},
		no_damage = {
			TITLE = "Damage Free",
			DESCRIPTION = "While in a team of 6 or less people, defeat the Swineclops waveset without taking any damage.",
		},
		no_damage_double = {
			TITLE = "Damage Ghost",
			DESCRIPTION = "With the Duplicator mutator set to 2, defeat the Swineclops waveset without taking any damage.",
		},
		low_team_damage = {
			TITLE = "Damage Demons",
			DESCRIPTION = "Defeat the Swineclops waveset without any player taking more than 200 damage.",
		},
		no_team_deaths_boarilla = {
			TITLE = "Hard to Kill",
			DESCRIPTION = "While in a team of 6 or less people, defeat the Boarilla waveset without any players dying once.",
		},
		no_team_deaths_boarrior = {
			TITLE = "Just Wont Die",
			DESCRIPTION = "While in a team of 6 or less people, defeat the Classic waveset without any players dying once.",
		},
		no_deaths_swineclops = {
			TITLE = "Solo Survivor",
			DESCRIPTION = "While in a team of 6 or less people, defeat the Swineclops waveset without dying once.",
		},
		no_team_deaths_swineclops = {
			TITLE = "Team Survivor",
			DESCRIPTION = "While in a team of 6 or less people, defeat the Swineclops waveset without any players dying once.",
		},
		unique_team = {
			TITLE = "Survival of Misfits",
			DESCRIPTION = "While in a team of 6 unique characters, defeat the Swineclops waveset without any players dying once.",
		},
		random_team_6_no_deaths = {
			TITLE = "Survival of the Randoms",
			DESCRIPTION = "While in a team of 6 or less people, have everyone choose the 'Random' character and defeat the Swineclops waveset without any players dying once.",
		},
		random_team_no_deaths = {
			TITLE = "Throw the Dice",
			DESCRIPTION = "Have everyone choose the 'Random' character and defeat the Swineclops waveset without any players dying once.",
		},
		team_5_swinelcops = {
			TITLE = "Not Missing Much",
			DESCRIPTION = "Defeat the Swineclops waveset within a team of 5 or less people.",
		},
		team_4_swinelcops = {
			TITLE = "Elite 4",
			DESCRIPTION = "Defeat the Swineclops waveset within a team of 4 or less people.",
		},
		team_3_swinelcops = {
			TITLE = "Impatient Trio",
			DESCRIPTION = "Defeat the Swineclops waveset within a team of 3 or less people.",
		},
		team_2_swinelcops = {
			TITLE = "Teamless Duo",
			DESCRIPTION = "Defeat the Swineclops waveset within a team of 2 or less people.",
		},
		bronze_speed_run = {
			TITLE = "Bronze Speed Run",
			DESCRIPTION = "Defeat the Swineclops waveset within 25 minutes.",
		},
		silver_speed_run = {
			TITLE = "Silver Speed Run",
			DESCRIPTION = "Defeat the Swineclops waveset within 20 minutes.",
		},
		gold_speed_run = {
			TITLE = "Gold Speed Run",
			DESCRIPTION = "Defeat the Swineclops waveset within 15 minutes.",
		},
		plat_speed_run = {
			TITLE = "Platinum Speed Run",
			DESCRIPTION = "Defeat the Swineclops waveset within 10 minutes.",
		},
		double_bronze_speed_run = {
			TITLE = "Double Trouble Bronze Speed Run",
			DESCRIPTION = "While the duplicator mutator is set to 2, defeat the Swineclops waveset within 35 minutes.",
		},
		double_silver_speed_run = {
			TITLE = "Double Trouble Silver Speed Run",
			DESCRIPTION = "While the duplicator mutator is set to 2, defeat the Swineclops waveset within 30 minutes.",
		},
		double_gold_speed_run = {
			TITLE = "Double Trouble Gold Speed Run",
			DESCRIPTION = "While the duplicator mutator is set to 2, defeat the Swineclops waveset within 25 minutes.",
		},
		double_plat_speed_run = {
			TITLE = "Double Trouble Platinum Speed Run",
			DESCRIPTION = "While the duplicator mutator is set to 2, defeat the Swineclops waveset within 20 minutes.",
		},
		pitpig_silver = {
			TITLE = "Down But Not Snout",
			DESCRIPTION = "While playing any of the original forge wavesets, finish the Pitpig round having taken less than 800 teamwide damage.",
		},
		pitpig_gold = {
			TITLE = "Pig on a Spit",
			DESCRIPTION = "While playing any of the original forge wavesets, finish the Pitpig round having taken less than 600 teamwide damage.",
		},
		croc = {
			TITLE = "Crocs before Pigs",
			DESCRIPTION = "While playing any of the original forge wavesets, finish the Crocommander round without killing any Pitpigs before Crocommanders.",
		},
		snortoise_silver = {
			TITLE = "Big Wheel",
			DESCRIPTION = "While playing any of the original forge wavesets, finish the Snortoise round without allowing Snortoises to perform more than 3 spins.",
		},
		snortoise_gold = {
			TITLE = "Unspun Hero",
			DESCRIPTION = "While playing any of the original forge wavesets, finish the Snortoise round without allowing any Snortoises to spin.",
		},
		no_deaths_acid = {
			TITLE = "Basic Solution",
			DESCRIPTION = "While playing any of the original forge wavesets, finish the Scorpeon round without anyone dying to acid.",
		},
		cc_breaker = {
			TITLE = "%&*@#!",
			DESCRIPTION = "Be 'That' guy and break 100 enemies out of fossillize in a single match.",
		},
		revive_bronze = {
			TITLE = "Medic!",
			DESCRIPTION = "As Wilson, revive another player.",
		},
		revive_silver = {
			TITLE = "Team Carrier",
			DESCRIPTION = "As Wilson, revive 10 players in a single game.",
		},
		revive_gold = {
			TITLE = "Pro Pub Reviver",
			DESCRIPTION = "As Wilson, revive 20 players in a single game.",
		},
		teleport_silver = {
			TITLE = "Jump Save",
			DESCRIPTION = "As Wilson, teleport with the Soul Scepter once.",
		},
		teleport_gold = {
			TITLE = "Jump Clutch",
			DESCRIPTION = "As Wilson, teleport with the Soul Scepter 10 times.",
		},
		wilson_tank = {
			TITLE = "Wilson Best Tank",
			DESCRIPTION = "As Wilson, use Parry against Swineclops.",
		},
		wilson_swineclops = {
			TITLE = "Wilson Victory",
			DESCRIPTION = "As Wilson, beat the Swineclops waveset.",
		},
		kills_bronze = {
			TITLE = "Pig Farmer",
			DESCRIPTION = "Kill over 100 enemies in your forge career.",
		},
		kills_silver = {
			TITLE = "Butcher",
			DESCRIPTION = "Kill over 1000 enemies in your forge career.",
		},
		kills_gold = {
			TITLE = "Swine Slayer",
			DESCRIPTION = "Kill over 10000 enemies in your forge career.",
		},
		solo_boarilla = {
			TITLE = "Boarilla Basher",
			DESCRIPTION = "Defeat a Boarilla by yourself with no other teammates dealing damage to it.",
		},
		SORT_ID             = "ID",
		PLAYER_COUNT        = "Player Count <= %d",
		PROGRESS            = "Progress: %d of %d",
		REWARD              = "Reward: %d Experience",
		REQUIREMENTS        = "Requirements:",
		COMPLETION          = "Completion: %d/%d",
		MODS_FILTER         = "Mods Filter: {mode}",
		UNLOCKED_FILTER     = "Unlocked Filter: {mode}",
		CHARACTERS_FILTER   = "Character Filter: {mode}",
		WAVESETS_FILTER     = "Waveset Filter: {mode}",
		GAMETYPES_FILTER    = "Gametype Filter: {mode}",
		MODES_FILTER        = "Mode Filter: {mode}",
		DIFFICUTLIES_FILTER = "Difficulty Filter: {mode}",
		UNLOCKED      = "Unlocked",
		LOCKED        = "Locked",
		DATE_UNLOCKED = "Date Unlocked",
	},
	MODS = {
		DEFAULT = "ReForged",
	},
	HUD = {
		SPECTATOR_FREE_CAMERA        = "Free Camera",
		SPECTATOR_FREE_CAMERA_TOGGLE = "Toggle Free Camera",
	},
	PING_GROUP = "Group Up Here!",
	INGAME = "[󰀘] ",
	-- Error
	unknown = "Unknown String",
}
