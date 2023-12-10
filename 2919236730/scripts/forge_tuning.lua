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
--[[ TODO adjust new characters health
current total health count (not counting the new characters)
75  = 1
100 = 1
125 = 3
150 = 4
200 = 3
--]]
TUNING.LAVAARENA_SURVIVOR_DIFFICULTY.WARLY    = 2
TUNING.LAVAARENA_SURVIVOR_DIFFICULTY.WORMWOOD = 2
TUNING.LAVAARENA_SURVIVOR_DIFFICULTY.WORTOX   = 1
TUNING.LAVAARENA_SURVIVOR_DIFFICULTY.WURT     = 1
TUNING.LAVAARENA_SURVIVOR_DIFFICULTY.WALTER   = 1
TUNING.LAVAARENA_SURVIVOR_DIFFICULTY.WANDA    = 2

TUNING.LAVAARENA_STARTING_HEALTH.WORTOX   = 150
TUNING.LAVAARENA_STARTING_HEALTH.WORMWOOD = 125
TUNING.LAVAARENA_STARTING_HEALTH.WARLY    = 125
TUNING.LAVAARENA_STARTING_HEALTH.WURT     = 150
TUNING.LAVAARENA_STARTING_HEALTH.WALTER   = 125
TUNING.LAVAARENA_STARTING_HEALTH.WANDA    = 100

TUNING.GAMEMODE_STARTING_COMPANIONS = {}
TUNING.GAMEMODE_STARTING_COMPANIONS.LAVAARENA = {
	-- Perk Variants
	baby_spiders = {"babyspider", "babyspider", "babyspider"},
	abigail      = {"forge_abigail"},
	bernie       = {"forge_bernie"},
	baby_ben     = {"baby_ben"},
	woby         = {"forge_woby"},
}
local REFORGED_TUNING = {
	------------------------
	--==   Characters   ==--
	------------------------
	SHADOWS = {
		DAMAGE      = 30,
		LUNGE_SPEED = 30,
	},
	WATHGRITHR = {
		AGGRO_GAIN_MULT = 2,
	},
	WEBBER = {
		BABY_SPIDER_AMOUNT = 3,
	},
	WES = {
		AGGRO_GAIN_MULT = 2,
		AGGRO_TIMER_MULT = 2,
		REVIVE_SPEED_MULTIPLIER = 0.5,
	},
	WILSON = {
		BONUS_HEALTH_ON_REVIVE_PERCENT = 0.4,
		BONUS_HEALTH_ON_REVIVE_MULT    = 3,
		BONUS_REVIVE_SPEED_MULTIPLIER  = 0.5,
	},
	WINONA = {
		BONUS_COOLDOWN_RATE = 0.1,
		MAX_HEALTH          = 200, -- TODO is this used?
	},
	WOODIE = {
		MAX_HEALTH = 200, -- TODO is this used?
	},
	WOLFGANG = {
		MAX_HEALTH = 200, -- TODO is this used?
	},
	WORTOX = {
	},
	WORMWOOD = {
	},
	WARLY = {
		COOK_DURATION_MULT = 0.5,
		FOOD_DURATION_MULT = 1.1,
		FOOD_DAMAGE_MULT   = 1.1,
		FOOD_DEFENSE_MULT  = 0.9,
		FOOD_REGEN_MULT    = 1.1,
	},
	WURT = {
		WET_DEBUFF_DURATION = 5,
		WET_DEBUFF_ELECTRIC = 1.5, -- TODO better name?
		WET_DEBUFF_MOVEMENT = 0.9, -- TODO better name?
	},
	HEALTH_ON_REVIVE = 0.2,

	------------------
	--==   Pets   ==--
	------------------
	FORGE_ABIGAIL = {
		HEALTH       = 450,
		DAMAGE       = 6,
		RESPAWN_TIME = 90,
		WALKSPEED    = 2.5,
		RUNSPEED     = 5,
		ENTITY_TYPE  = "PETS",
	},
	BABYSPIDER = {
		AMOUNT        = 3,
		ATTACK_PERIOD = 3,
		ATTACK_RANGE  = 3, -- TODO multiply by scale? or in prefab?
		DAMAGE        = 9,
		HEALTH        = 100, -- invincible so health value does not matter
		RUNSPEED      = 10,
		ENTITY_TYPE   = "PETS",
	},
	FORGE_BERNIE = {
		HEALTH            = 1000,
		REVIVE_SPEED_MULT = 0.5, -- default rez time is 6 seconds, 0.5*6 = 3 seconds
		WALKSPEED         = 1,
		TAUNT_DURATION    = 5, -- TODO adjust 4 or 5
		TAUNT_RADIUS      = 16, -- TODO adjust, we had 10, testing 16
		ENTITY_TYPE       = "PETS",
	},
	GOLEM = {
		HEALTH        = 1,
		RUNSPEED      = 0,
		DAMAGE        = 25,
		ATTACK_RANGE  = 9,
		ATTACK_PERIOD = 0,
		LIFE_TIME     = 10,
		PROJECTILE    = "forge_fireball_projectile",
		ENTITY_TYPE   = "PETS",
	},
	MEAN_FLYTRAP = {
		HEALTH        = 250,
		DAMAGE        = 15,
		RUNSPEED      = 4,
		ATTACK_PERIOD = 2,
		ATTACK_RANGE  = 2,
		HIT_RANGE     = 3,
		LIFE_TIME     = 30,
		ENTITY_TYPE   = "PETS",
	},
	ADULT_FLYTRAP = {
		HEALTH        = 400,
		DAMAGE        = 30,
		ATTACK_PERIOD = 4,
		ATTACK_RANGE  = 4,
		ATTACK_RADIUS = 2,
		HIT_RANGE     = 6,
		STIMULI       = "strong",
		LIFE_TIME     = 20,
		ENTITY_TYPE   = "PETS",
	},
	COOKPOT = { --TODO balance tuning
		COOK_TIME        = 5,
		RANGE            = 10,
		LAUNCH_DELAY     = 1,
		SPIT_DELAY       = 0.25,
		FOOD_HIT_RANGE   = 2,
		HORIZONTAL_SPEED = 15,
		GRAVITY          = -20,
		VECTOR           = {0.2, 2.5, 0},
		BUFF_DURATION    = 10,
		DAMAGE_BUFF      = 1.1,
		DEFENSE_BUFF     = 0.9,
		REGEN_TICK_RATE  = _G.FRAMES,
		REGEN_TICK_VALUE = 0.1, -- 15 health base heal
	},
	TRAP_SPIKES = {
		DAMAGE = 40,
		HIT_RANGE = 2,
		ACTIVATE_TIME = 5,
		DEACTIVATE_TIME = 3,
	},
	MERM_GUARD = {
		HEALTH        = 200,
		DAMAGE        = 20,
		RUNSPEED      = 8,
		WALKSPEED     = 3,
		ATTACK_PERIOD = 3,
		ATTACK_RANGE  = 3,
		HIT_RANGE     = 3,
		LIFE_TIME     = 30,
		ENTITY_TYPE   = "PETS",
	},
	WOBY = {
		RUNSPEED      = 6,
		WALKSPEED	  = 6,
		BUFF_RANGE	  = 15,
		BUFF_DURATION = 10,
		BUFF_COOLDOWN = 20,
		BUFF_MULT	  = 0.8,
		HEALTH        = 100, -- invincible so health value does not matter
		ENTITY_TYPE   = "PETS",
	},
	BABY_BEN = {
		HEALTH       = 100, -- invincible so health value does not matter
		WALKSPEED    = 2.5,
		RUNSPEED     = 5,
		ENTITY_TYPE  = "PETS",
	},

	------------------
	--==   Mobs   ==--
	------------------
	TAUNT_CD              = 8, --Leo: This is to prevent explosive-to-taunt spam. Not sure if its 100% accurate but there is evidence to prove that explosive indeed doesn't always stun. TODO need to figure this out
	STUN_TIME             = 1, --This only applies to the electric stun, all other stuns just end the stun when the animation ends. TODO this stun time might be inaccurate.
	HIT_RECOVERY          = 0.75, -- TODO this should be 1
	KEEP_AGGRO_MELEE_DIST = 2, --the range for determining when a target is too close to draw away from under normal circumstances.
	PITPIG = {
		HEALTH        = 340,
		RUNSPEED      = 7.1/0.8, --divided by 0.8 because of the 0.8 scaling.
		DASHSPEED     = 20,
		DAMAGE        = 20,
		ATTACK_RANGE  = 2,
		HIT_RANGE     = 3,
		DASH_DAMAGE   = 25,
		DASH_RANGE    = 3,
		ATTACK_PERIOD = 2,
		DASH_CD       = 10,
		BATTLECRY_CD  = 4,
		ENTITY_TYPE   = "ENEMIES",
		WEIGHT        = 1,
	},
	CROCOMMANDER = {
		HEALTH                 = 1350,
		RUNSPEED               = 7.1,
		DAMAGE                 = 40,
		ATTACK_PERIOD          = 1.5,
		ATTACK_RANGE           = 2,
		HIT_RANGE              = 3,
		SPIT_DAMAGE            = 40,
		SPIT_PROJECTILE        = "forge_gooball_projectile",
		SPIT_ATTACK_PERIOD     = 4,
		SPIT_ATTACK_RANGE      = 5,
		SWAP_ATTACK_MODE_RANGE = 7,
		BANNER_CD              = 10,
		ENTITY_TYPE            = "ENEMIES",
		WEIGHT                 = 4,
	},
	CROCOMMANDER_RAPIDFIRE = {
		HEALTH                 = 1350,
		RUNSPEED               = 8,
		DAMAGE                 = 20,
		ATTACK_PERIOD          = 1.5,
		ATTACK_RANGE           = 2,
		HIT_RANGE              = 4,
		SPIT_DAMAGE            = 40,
		SPIT_PROJECTILE        = "forge_fireball_projectile_fast",
		SPIT_ATTACK_PERIOD     = 0.2, -- TODO Can't attack this fast because the attack state is longer than this period, it also prevents the croc from switching to melee, because it can't switch if in the middle of attacking.
		SPIT_ATTACK_RANGE      = 5,
		SWAP_ATTACK_MODE_RANGE = 7,
		ENTITY_TYPE            = "ENEMIES",
		WEIGHT                 = 4,
	},
	BATTLESTANDARD = {
		HEALTH            = 30,
		PULSE_TICK        = 0.1,
		DEF_BUFF          = 0.5,
		ATK_BUFF          = 0.5,
		HEALTH_PER_TICK   = 0.34,
		HEALTH_TICK       = 1/30,
		SPEED_BUFF        = 1.5,
		PULSE_TIME 		  = 5, --for visual pulses
		MIN_INDICATOR_RANGE = 20,
	},
	SNORTOISE = {
		HEALTH            = 2550,
		RUNSPEED          = 2,
		WALKSPEED         = 2,
		DAMAGE            = 50,
		SPIN_MULT         = 0.5,
		ATTACK_RANGE      = 2,
		HIT_RANGE         = 3,
		SPIN_TRIGGER      = 0.3,
		SPIN_HIT_RANGE    = 2,
		ATTACK_PERIOD     = 3,
		SPIN_CD           = 25,
		SHIELD_CD         = 6, -- 7, -- TODO check value
		FLIP_TIME		  = 10,
		ENTITY_TYPE       = "ENEMIES",
		WEIGHT            = 3,
	},
	SCORPEON = {
		HEALTH                = 3400,
		RUNSPEED              = 3,
		WALKSPEED             = 3, -- TODO not used?
		DAMAGE                = 70,
		SPIT_DAMAGE           = 10,
		ACID_DAMAGE_TOTAL     = 64,
		ACID_WEAROFF_TIME     = 8,
		ACID_DAMAGE_TICK      = .2,
		ATTACK_RANGE          = 2,
		HIT_RANGE             = 3,
		ENRAGED_TRIGGER       = 0.75,
		SPIT_ATTACK_RANGE     = 3,
		SPIT_SPEED            = 6,
		SPIT_MAX_Y            = 3,
		ATTACK_PERIOD         = 3,
		ATTACK_PERIOD_ENRAGED = 1.5,
		SPIT_CD               = 6,
		ENTITY_TYPE           = "ENEMIES",
		WEIGHT                = 5,
	},
	BOARILLA = {
		HEALTH            = 7700,
		--Leo: Please test the speeds before changing them, boarilla doesn't run at a flat speed. He has slow movements and fast movements in different parts of the runstate.
		--also these get multiplied by 1.2 due to scaling.
		RUNSPEED          = 9, --Runner speed is 7.2 with +20 speed boost
		WALKSPEED         = 6,
		DAMAGE            = 150,
		ATTACK_RANGE      = 3,
		HIT_RANGE         = 3,
		AOE_HIT_RANGE     = 2.25, -- TODO used?
		FRONT_AOE_OFFSET  = 3,
		ROLL_TRIGGER_1    = 0.9,
		ROLL_TRIGGER_2    = 0.8,
		ROLL_TRIGGER_3    = 0.6,
		SLAM_TRIGGER      = 0.5,
		JUMP_ATTACK_RANGE = 8, -- TODO used?
		JUMP_HIT_RANGE    = 4, -- TODO used?
		ATTACK_PERIOD     = 3.33,
		ROLL_DURATION     = 5,
		ROLL_CD           = 20, -- TODO might be 18
		SLAM_CD           = 10,
		BATTLECRY_CD      = 20, -- TODO could be 10 or even 5 still hmmm
		SHEILD_CD         = 7, -- TODO rename to SHIELD_CD
		FOSSIL_TIME       = 1, -- TODO adjust to real value
		--Leo: Normally knockback is handled automatically via the knockback event, however these values are meant for entities that don't have a knockback listener.
		ATTACK_KNOCKBACK  = 20, --was 25.
		ENTITY_TYPE       = "ENEMIES",
		WEIGHT            = 10,
	},
	BOARRIOR = {
		HEALTH                = 34000,
		WALKSPEED             = 5,
		DAMAGE                = 200,
		SLAM_DAMAGE           = 150,
		SLAM_RANGE            = 2,
		ATTACK_RANGE          = 3,--3.5,
		HIT_RANGE             = 6,
		ATTACK_SLAM_MIN_RANGE = 4,
		ATTACK_SLAM_MAX_RANGE = 9,--8,
		AOE_HIT_RANGE         = 3,--4,
		FRONT_AOE_OFFSET      = 2,
		ATTACK_PERIOD         = 3.33,--3.5,
		ATTACK_RANDOM_SLAM_CD = 6,
		PHASE1_TRIGGER        = 0.9,
		PHASE2_TRIGGER        = 0.75,
		PHASE3_TRIGGER        = 0.5,
		PHASE4_TRIGGER        = 0.25,
		FOSSIL_TIME           = 2, -- TODO adjust to real value
		--Leo: Normally knockback is handled automatically via the knockback event, however these values are meant for entities that don't have a knockback listener.
		ATTACK_KNOCKBACK      = 12,
		SPIN_KNOCKBACK        = 6,
		MAX_BANNERS           = 4,
		ENTITY_TYPE           = "ENEMIES",
		WEIGHT                = 20,
	},
	RHINOCEBRO = {
		HEALTH               = 12750,
		REV_PERCENT          = 0.20, --2560
		RUNSPEED             = 7, --guesstimate, gets multiplied by 1.15 because of scale.
		DAMAGE               = 150,
		CHEER_CD             = 15,
		CHEER_TIMEOUT        = 5,
		BUFF_DAMAGE_INCREASE = 25,
		MAX_BUFFS            = 7, -- 4, -- TODO klei had 7 in their prefab, need to cross reference with vids to confirm
		ATTACK_RANGE         = 3.5, --either 2 or 3, will tune this later.
		HIT_RANGE            = 4.5, --need more information on hitranges (can you even dodge it?)
		--Leo: these are no longer used since the ram activates via the running states now.
		CHARGE_HIT_RANGE     = 3,
		------------------------------
		FRONT_AOE_OFFSET     = 3,
		AOE_HIT_RANGE        = 3,
		ATTACK_PERIOD        = 3,
		CHARGE_CD            = 1.5, --5, -- TODO need more verification, possibly range issue?
		DAMAGED_TRIGGER      = 0.2, --apply damaged builds at 20% HP.
		FOSSIL_TIME          = 6, -- TODO adjust to real value
		ATTACK_KNOCKBACK     = 2,
		ENTITY_TYPE          = "ENEMIES",
		WEIGHT               = 10,
	},
	RHINOCEBROS = {
		ENTITY_TYPE = "ENEMIES",
		WEIGHT      = 20,
	},
	SWINECLOPS = {
		HEALTH              = 42500, --Pretty sure this is exact
		GUARD_TIME          = 12,
		--speed gets multiplied by 1.05 due to scaling.
		RUNSPEED            = 10,
		WALKSPEED           = 4,
		DAMAGE              = 200, -- confirmed to be the base. when buffed this increases to 250.
		TAUNT_CD            = 10, -- almost certain that its determined by battlecry.
		BODY_SLAM_CD        = 3,
		BATTLECRY_BUFF      = 1.25, -- TODO correct value? was hardcoded to 1.5?
		GUARD_BUFF          = 0.5,
		ATTACK_RANGE        = 3, -- TODO either 2 or 3, will tune this later.
		HIT_RANGE           = 3, -- TODO need more information on hitranges.
		AOE_HIT_RANGE       = 6,
		GROUNDPOUND_RANGE 	= 7,
		ATTACK_BODY_SLAM_RANGE = 8,
		ATTACK_PERIOD       = 2,
		ATTACK_GUARD_PERIOD = 1.3, -- TODO the data we collected ranges from 0.9 to 1.5
		--These are for determining the max -- TODO what is this comment referring to?
    	ATTACK_MODE_TRIGGER           = 0.9,
    	ATTACK_AND_GUARD_MODE_TRIGGER = 0.8,
    	COMBO_2_TRIGGER               = 0.5,
    	INFINITE_COMBO_TRIGGER        = 0.25,
    	GUARD_DAMAGE_TRIGGER          = 3000, -- TODO adjust
		FOSSIL_TIME                   = 1, -- TODO adjust to real value
		ATTACK_KNOCKBACK              = 2,
		GUARD_HIT_RECOVERY            = 0,
		ENTITY_TYPE                   = "ENEMIES",
		WEIGHT                        = 30,
	},

	---------------------
	--==   Weapons   ==--
	---------------------
	--Elec said that adding 0.1 for every 4 in radius tuning resulted in a more accurate radius
	FORGEDARTS = {
		DAMAGE           = 20,
		ALT_DAMAGE       = 20, -- TODO needed?
		COOLDOWN 	     = 18,
		DAMAGE_TYPE      = 1, -- Physical
		ITEM_TYPE        = "darts",
		ENTITY_TYPE      = "WEAPONS",
		ATTACK_RANGE     = 10,
		HIT_RANGE        = 20,
		ALT_RANGE        = 30,
		IS_STARTING_ITEM = true,
		WEIGHT           = 1,
		RET = {
			PREFAB      = "reticulelongmulti",
			PING_PREFAB = "reticulelongmultiping",
			TYPE        = "directional",
			LENGTH      = 6.5,
		},
	},
	FORGINGHAMMER = {
		DAMAGE      = 20,
		ALT_DAMAGE  = 30,
		ALT_RADIUS  = 4.1, -- TODO change to 4 and test
		COOLDOWN    = 18,
		ALT_STIMULI = "electric",
		DAMAGE_TYPE = 1, -- Physical
		ITEM_TYPE   = "melees",
		ENTITY_TYPE = "WEAPONS",
		IS_STARTING_ITEM = true,
		WEIGHT           = 1,
		RET = {
			DATA   = {"aoehostiletarget", 0.9},
			TYPE   = "aoe",
			LENGTH = 7,
		},
	},
	RILEDLUCY = {
		DAMAGE        = 20,
		ALT_DAMAGE    = 30,
		ALT_DIST      = 10, -- TODO was hardcoded to 12???
		ALT_HIT_RANGE = 3,
		ALT_STIMULI   = "strong",
		DAMAGE_TYPE = 1, -- Physical
		ITEM_TYPE   = "melees",
		ENTITY_TYPE = "WEAPONS",
		IS_STARTING_ITEM = true,
		WEIGHT           = 1,
		RET = {
			TYPE   = "directional",
			LENGTH = 6.5,
		},
	},
	PITHPIKE = {
		DAMAGE      = 25,
		ALT_DAMAGE  = 30,
		ALT_DIST    = 6.5,
		ALT_WIDTH   = 2,-- TODO 3.25 was old value, why? 2 seems to fit better, but might be a little too big, 1.5 would make ALT_RANGE 8 hmmm
		ALT_RANGE   = 6.5 + 2, -- ALT_DIST + ALT_WIDTH
		ALT_STIMULI = "explosive",
		COOLDOWN    = 12,
		DAMAGE_TYPE = 1, -- Physical
		ITEM_TYPE   = "melees",
		ENTITY_TYPE = "WEAPONS",
		IS_STARTING_ITEM = true,
		WEIGHT           = 1,
		RET = {
			PREFAB       = "reticuleline",
			PING_PREFAB  = "reticulelineping",
			TYPE         = "directional",
			LENGTH       = 6.5,
			ALWAYS_VALID = false,
		},
	},
	LIVINGSTAFF = {
		DAMAGE       = 10,
		COOLDOWN     = 24,
		DURATION     = 10,
		HEAL_RATE    = 6,
		RANGE        = 4.1, -- Change to 4 and test, also should it be ALT_RADIUS?
		SPELL_TYPES  = {"heal","crowd_control",},
		SCALE_RNG    = {30, 40},
		DAMAGE_TYPE  = 2, -- Magic
		ITEM_TYPE    = {"staves", "healers"},
		ENTITY_TYPE  = "WEAPONS",
		ATTACK_RANGE = 10,
		HIT_RANGE    = 20,
		IS_HEAL      = true,
		WEIGHT       = 3,
		RET = {
			DATA          = {"aoefriendlytarget", 0.9}, --TODO: Leo: Do we even need this?
			TYPE          = "aoe",
			LENGTH        = 6,
			VALID_COLOR   = {0, 1, .5, 1}, -- TODO what color? leave comment here for it, is the color in constants already?
			INVALID_COLOR = {0, .4, 0, 1}, -- what color?
			PING_PREFAB   = "reticuleaoefriendlytarget",
		},
	},
	MOLTENDARTS = {
		DAMAGE       = 25,
		ALT_DAMAGE   = 50,
		COOLDOWN     = 18,
		DAMAGE_TYPE  = 1, -- Physical
		ITEM_TYPE    = "darts",
		ENTITY_TYPE  = "WEAPONS",
		ATTACK_RANGE = 10,
		HIT_RANGE    = 15,
		ALT_RANGE    = 30,
		ALT_STIMULI  = "explosive",
		WEIGHT       = 2,
		RET = {
			TYPE   = "directional",
			LENGTH = 6.5,
		},
	},
	INFERNALSTAFF = {
		DAMAGE          = 25,
		ALT_DAMAGE      = 200,
		ALT_CENTER_MULT = 0.25, --Damage increases as the targets get closer to the center
		ALT_RADIUS      = 4,--4.1, TODO double check then remove this comment
		COOLDOWN        = 24,
		SPELL_TYPES     = {"damage",},
		DAMAGE_TYPE     = 2, -- Magic
		ALT_DAMAGE_TYPE = 2,
		STIMULI         = "fire",
		ALT_STIMULI     = "explosive",
		ITEM_TYPE       = "staves",
		ENTITY_TYPE     = "WEAPONS",
		ATTACK_RANGE    = 10,
		HIT_RANGE       = 20,
		WEIGHT          = 3,
		RET = {
			DATA   = {"aoehostiletarget", 0.7},
			TYPE   = "aoe",
			LENGTH = 7,
		},
	},
	SPIRALSPEAR = {
		DAMAGE      = 30,
		ALT_DAMAGE  = 75,
		ALT_RANGE   = 16,
		ALT_RADIUS  = 2.05, -- TODO change to 2 and test
		ALT_STIMULI = "explosive",
		COOLDOWN    = 12,
		DAMAGE_TYPE = 1, -- Physical
		ITEM_TYPE   = "melees",
		ENTITY_TYPE = "WEAPONS",
		WEIGHT      = 3,
		RET = {
			DATA        = {"aoesmallhostiletarget", 1},
			PREFAB      = "reticuleaoesmall",
			PING_PREFAB = "reticuleaoesmallping",
			TYPE        = "aoe",
			LENGTH      = 5,
		},
	},
	PETRIFYINGTOME = {
		DAMAGE      = 15,
		COOLDOWN    = 18,
		DURATION    = 12,
		ALT_RADIUS  = 4.1, -- TODO change to 4 and test
		SPELL_TYPES = {"crowd_control",},
		ITEM_TYPE   = "books",
		ENTITY_TYPE = "WEAPONS",
		IS_STARTING_ITEM = true,
		WEIGHT           = 1,
		RET = {
			PREFAB      = "reticuleaoe",
			PING_PREFAB = "reticuleaoecctarget",
			TYPE        = "aoe",
			LENGTH      = 7,
		},
	},
	BACONTOME = {
		DAMAGE      = 15,
		COOLDOWN    = 18,
		DURATION    = 10,
		SPELL_TYPES = {"summon"},
		ITEM_TYPE   = "books",
		ENTITY_TYPE = "WEAPONS",
		WEIGHT      = 2,
		RET = {
			PREFAB      = "reticuleaoesummon",
			PING_PREFAB = "reticuleaoesummontarget",
			TYPE        = "aoe",
			LENGTH      = 7,
		},
	},
	FIREBOMB = {
		DAMAGE              = 15,
		ALT_DAMAGE          = 75,
		PROC_DAMAGE         = 100,
		COOLDOWN            = 6,
		ALT_RANGE 			= 2,
		PASSIVE_RANGE       = 0.5,
		HORIZONTAL_SPEED    = 20,
		VECTOR              = {.25, 1, 0},
		GRAVITY             = -30,
		CHARGE_HITS_1       = 7,
		CHARGE_HITS_2       = 10,
		MAXIMUM_CHARGE_HITS = 13,
		CHARGE_DECAY_TIME   = 5,
		DAMAGE_TYPE         = 1, -- Physical
		STIMULI             = "fire",
		ALT_STIMULI         = "explosive",
		ITEM_TYPE           = "darts",
		ENTITY_TYPE         = "WEAPONS",
		ALT_ATTACK_RANGE    = 10,
		ALT_HIT_RANGE       = 20,
		WEIGHT              = 2,
		RET = {
			PREFAB      = "reticuleaoesmall",
			PING_PREFAB = "reticuleaoesmallhostiletarget",
			TYPE        = "aoe",
			LENGTH      = 5,
		},
	},
	BLACKSMITHSEDGE = {
		DAMAGE           = 30,
		HELMSPLIT_DAMAGE = 100, -- this is multiplied by the battlecry and any shieldbreak mult.
		PARRY_DURATION   = 5,
		COOLDOWN         = 12,
		DAMAGE_TYPE      = 1, -- Physical
		ITEM_TYPE        = "melees",
		ENTITY_TYPE      = "WEAPONS",
		WEIGHT           = 3,
		RET = {
			PREFAB      = "reticulearc",
			PING_PREFAB = "reticulearcping",
			TYPE        = "directional",
			LENGTH      = 6.5,
		},
	},
	SEEDLINGTOME = {
		DAMAGE      = 15,
		COOLDOWN    = 18,
		DURATION    = 10,
		SPELL_TYPES = {"summon"},
		ITEM_TYPE   = "books",
		ENTITY_TYPE = "WEAPONS",
		WEIGHT      = 1,
		RET = {
			PREFAB      = "reticuleaoesummon",
			PING_PREFAB = "reticuleaoesummontarget",
			TYPE        = "aoe",
			LENGTH      = 7,
		},
		WIP = true
	},
	FLYTRAPTOME = {
		DAMAGE      = 15,
		COOLDOWN    = 18,
		DURATION    = 10,
		SPELL_TYPES = {"summon"},
		ITEM_TYPE   = "books",
		ENTITY_TYPE = "WEAPONS",
		WEIGHT      = 1,
		RET = {
			PREFAB      = "reticuleaoesummon",
			PING_PREFAB = "reticuleaoesummontarget",
			TYPE        = "aoe",
			LENGTH      = 7,
		},
		WIP = true
	},
	LAVAARENA_SEEDDARTS = {
		DAMAGE       = 20,
		COOLDOWN 	 = 18,
		DAMAGE_TYPE  = 1, -- Physical
		SPELL_TYPES  = {"summon"},
		ITEM_TYPE    = "darts",
		ENTITY_TYPE  = "WEAPONS",
		ATTACK_RANGE = 10,
		HIT_RANGE    = 20,
		IS_STARTING_ITEM = true,
		WEIGHT           = 1,
		RET = {
			DATA        = {"aoesmallhostiletarget", 1},
			PREFAB      = "reticuleaoesmall",
			PING_PREFAB = "reticuleaoesmallping",
			TYPE        = "aoe",
			LENGTH      = 5,
		},
	},
	LAVAARENA_SEEDDART2 = {
		DAMAGE       = 12,
		COOLDOWN 	 = 18,
		DAMAGE_TYPE  = 1, -- Physical
		SPELL_TYPES  = {"summon"},
		ITEM_TYPE    = "darts",
		ENTITY_TYPE  = "WEAPONS",
		ATTACK_RANGE = 5,
		HIT_RANGE    = 10,
		HIT_WEIGHT   = 0.5,
		WEIGHT       = 3,
		RET = {
			DATA        = {"aoesmallhostiletarget", 1},
			PREFAB      = "reticuleaoesmall",
			PING_PREFAB = "reticuleaoesmallping",
			TYPE        = "aoe",
			LENGTH      = 5,
		},
	},
	LAVAARENA_GAUNTLET = { -- TODO
		DAMAGE      = 25,
		ALT_DAMAGE  = 40,
		ALT_DIST    = 6.5,
		ALT_WIDTH   = 2,-- TODO 3.25 was old value, why? 2 seems to fit better, but might be a little too big, 1.5 would make ALT_RANGE 8 hmmm
		ALT_RANGE   = 6.5 + 2, -- ALT_DIST + ALT_WIDTH
		ALT_STIMULI = "explosive",
		COOLDOWN    = 12,
		DAMAGE_TYPE = 1, -- Physical
		ITEM_TYPE   = "melees",
		ENTITY_TYPE = "WEAPONS",
		WEIGHT      = 2,
		RET = {
			PREFAB       = "reticuleline",
			PING_PREFAB  = "reticulelineping",
			TYPE         = "directional",
			LENGTH       = 6.5,
			ALWAYS_VALID = false,
		},
	},
	TELEPORT_STAFF = {
		DAMAGE      = 20,
		ALT_RANGE   = 30,
		COOLDOWN    = 1,
		DAMAGE_TYPE = 1, -- Physical
		SPELL_TYPES = {"utility"},
		ITEM_TYPE   = "melees",
		ENTITY_TYPE = "WEAPONS",
		IS_STARTING_ITEM = true,
		WEIGHT           = 1,
		RET = {
			DATA        = {"aoesmallhostiletarget", 1},
			PREFAB      = "reticuleaoesmall",
			PING_PREFAB = "reticuleaoesmallping",
			TYPE        = "aoe",
			LENGTH      = 5,
		},
	},
	LAVAARENA_SPATULA = {
		DAMAGE      = 25,
		ALT_RANGE   = 1,
		COOLDOWN    = 36,
		DAMAGE_TYPE = 1, -- Physical
		SPELL_TYPES = {"heal"},
		ITEM_TYPE   = "melees",
		ENTITY_TYPE = "WEAPONS",
		WEIGHT      = 2,
		RET = {
			PREFAB      = "reticuleaoesmall",
			PING_PREFAB = "reticuleaoesmalltarget",
			TYPE        = "aoe",
			LENGTH      = 7,
		},
	},
	SPICE_BOMB = {
		IMPACT_DURATION     = 1,
		LINGERING_DURATION  = 1,
		DURATION            = 10,
		LINGERING_MULT      = 0.7,
		DAMAGE              = 10,
		COOLDOWN            = 24,
		AOE_RADIUS 			= 1,
		ALT_RADIUS          = 4,--4.1, TODO double check then remove this comment
		HORIZONTAL_SPEED    = 20,--15,
		VECTOR              = {.25, 1, 0},
		GRAVITY             = -35,
		ALT_HORIZONTAL_SPEED = 20,
		ALT_VECTOR           = {.25, 1, 0},
		ALT_GRAVITY          = -30,
		DAMAGE_TYPE         = 1, -- Physical
		ITEM_TYPE           = "darts",
		ENTITY_TYPE         = "WEAPONS",
		ATTACK_RANGE        = 3,
		HIT_RANGE           = 5,
		ALT_ATTACK_RANGE    = 10,
		ALT_HIT_RANGE       = 20,
		IS_HEAL             = true,
		WEIGHT              = 3,
		ABILITIES           = 4,
		RET = {
			PREFAB       = "reticuleaoe",
			PING_PREFAB  = "forge_reticule",--"reticuleaoefriendlytarget",
			TYPE         = "aoe",
			LENGTH       = 6,
			VALID_COLORS = {{0, 1, .5, 1}, {1, 0, 0, 1}, {0, 0, 1, 1}, {1, 1, 0, 1}},
			ICONS        = {
				{atlas = "images/rf_alt_icons.xml", tex = "alt_spice_heal.tex"},
				{atlas = "images/rf_alt_icons.xml", tex = "alt_spice_dmg.tex"},
				{atlas = "images/rf_alt_icons.xml", tex = "alt_spice_def.tex"},
				{atlas = "images/rf_alt_icons.xml", tex = "alt_spice_speed.tex"},
			},
		},
	},
	FORGE_TRIDENT = {
		DAMAGE      = 30,
		COOLDOWN    = 18,
		DAMAGE_TYPE = 1, -- Physical
		SPELL_TYPES = {"summon"},
		ITEM_TYPE   = "melees",
		ENTITY_TYPE = "WEAPONS",
		WEIGHT      = 2,
		RET = {
			DATA        = {"aoesmallhostiletarget", 1},
			PREFAB      = "reticuleaoesmall",
			PING_PREFAB = "reticuleaoesmallping",
			TYPE        = "aoe",
			LENGTH      = 5,
		},
	},
	FORGE_SLINGSHOT = {
		DAMAGE       = 30,
		ALT_DAMAGE   = 50,
		COOLDOWN 	 = 18,
		DAMAGE_TYPE  = 1, -- Physical
		ITEM_TYPE    = "darts",
		ENTITY_TYPE  = "WEAPONS",
		ATTACK_RANGE = 10,
		HIT_RANGE    = 20,
		ALT_RANGE    = 30,
		ALT_RADIUS   = 4,
		WEIGHT       = 1,
		RET = {
			PREFAB      = "reticulelongmulti",
			PING_PREFAB = "reticulelongmultiping",
			TYPE        = "directional",
			LENGTH      = 6.5,
		},
	},
	BALLOON = {
		DAMAGE       = 15,
		ALT_DAMAGE   = 25, --balloon explosion damage
		COOLDOWN 	 = 3,
		DAMAGE_TYPE  = 1, -- Physical
		ITEM_TYPE    = "darts",

		MAX_BALLOONS = 100,
		AOE_RADIUS = 3,
		AGGRO_RADIUS = 6,
		TICK_RATE = 0.5,

		RET = {
			PREFAB      = "reticuleaoesmall",
			PING_PREFAB = "reticuleaoesmalltarget",
			TYPE        = "aoe",
			LENGTH      = 7,
		},
	},
	POCKETWATCH_REFORGED = {
		DAMAGE       = 25,
		COOLDOWN     = 18,
		DAMAGE_TYPE  = 1, -- Physical
		SPELL_TYPES  = {"utility"},
		ITEM_TYPE    = "melees",
		ENTITY_TYPE  = "WEAPONS",
		ATTACK_RANGE = 2,
		HIT_RANGE    = 2,
		RANGE        = 4.1,
		WEIGHT       = 2,
		RET = {
			DATA   = {"aoehostiletarget", 0.7},
			TYPE   = "aoe",
			LENGTH = 7,
		},
	},
	PORTALSTAFF = {
		DAMAGE          = 25,
		ALT_DAMAGE      = 200,
		ALT_CENTER_MULT = 0.25, --Damage increases as the targets get closer to the center
		ALT_RADIUS      = 4,--4.1, TODO double check then remove this comment
		COOLDOWN        = 24,
		SPELL_TYPES     = {"damage",},
		DAMAGE_TYPE     = 2, -- Magic
		ALT_DAMAGE_TYPE = 2,
		STIMULI         = "fire",
		ALT_STIMULI     = "explosive",
		ITEM_TYPE       = "staves",
		ENTITY_TYPE     = "WEAPONS",
		ATTACK_RANGE    = 10,
		HIT_RANGE       = 20,
		WEIGHT          = 2,
		ABILITIES       = 2,
		RET = {
			DATA   = {"aoehostiletarget", 0.7},
			TYPE   = "aoe",
			LENGTH = 7,
			ICONS  = {
				{atlas = "images/rf_alt_icons.xml", tex = "alt_portal_activate.tex"},
				{atlas = "images/rf_alt_icons.xml", tex = "alt_portal_target.tex"},
			},
		},
	},
	BALLOON_REFORGED = {
		DAMAGE              = 10,
		COOLDOWN            = 24,
		AOE_RADIUS 			= 1,
		HORIZONTAL_SPEED    = 20,--15,
		VECTOR              = {.25, 1, 0},
		GRAVITY             = -35,
		DAMAGE_TYPE         = 1, -- Physical
		ITEM_TYPE           = "darts",
		ENTITY_TYPE         = "WEAPONS",
		ATTACK_RANGE        = 3,
		HIT_RANGE           = 5,
		WEIGHT              = 2,
		RET = {
			DATA        = {"aoesmallhostiletarget", 1},
			PREFAB      = "reticuleaoesmall",
			PING_PREFAB = "reticuleaoesmallping",
			TYPE        = "aoe",
			LENGTH      = 5,
		},
		WIP = true
	},


	--------------------
	--==   Debuffs  ==-- --TODO move all debuff tunings to here
	--------------------
	MFD = { --marked for death
		DURATION = 10,
		MULT = 1.15,
	},
	--------------------
	--==   Equips   ==--
	--------------------
	--Forge Season 1
	FEATHEREDWREATH    = {ENTITY_TYPE = "HELMS", WEIGHT = 1, SPEEDMULT = 1.2},
	BARBEDHELM         = {ENTITY_TYPE = "HELMS", WEIGHT = 1, BONUSDAMAGE = 1.1},
	CRYSTALTIARA       = {ENTITY_TYPE = "HELMS", WEIGHT = 1, BONUS_COOLDOWNRATE = -0.1},
	FLOWERHEADBAND     = {ENTITY_TYPE = "HELMS", WEIGHT = 2, HEALINGRECEIVEDMULT = 1.25},
	WOVENGARLAND       = {ENTITY_TYPE = "HELMS", WEIGHT = 2, HEALINGDEALTMULT = 1.2},
	NOXHELM            = {ENTITY_TYPE = "HELMS", WEIGHT = 2, BONUSDAMAGE = 1.15},
	RESPLENDENTNOXHELM = {ENTITY_TYPE = "HELMS", WEIGHT = 3, BONUSDAMAGE = 1.15, SPEEDMULT = 1.1, BONUS_COOLDOWNRATE = -0.1},
	BLOSSOMEDWREATH    = {ENTITY_TYPE = "HELMS", WEIGHT = 3, REGEN = {period = 0.5, delta = 1, limit = 0.8}, SPEEDMULT = 1.1, BONUS_COOLDOWNRATE = -0.1},
	CLAIRVOYANTCROWN   = {ENTITY_TYPE = "HELMS", WEIGHT = 3, MAGE_BONUSDAMAGE = 1.25, SPEEDMULT = 1.1, BONUS_COOLDOWNRATE = -0.1},

	REEDTUNIC              = {ENTITY_TYPE = "ARMOR", WEIGHT = 1, DEFENSE = 0.5, BONUS_COOLDOWNRATE = -0.05},
	FEATHEREDTUNIC         = {ENTITY_TYPE = "ARMOR", WEIGHT = 1, DEFENSE = 0.6, SPEEDMULT = 1.1},
	FORGE_WOODARMOR        = {ENTITY_TYPE = "ARMOR", WEIGHT = 1, DEFENSE = 0.75},
	JAGGEDARMOR            = {ENTITY_TYPE = "ARMOR", WEIGHT = 2, DEFENSE = 0.75, BONUSDAMAGE = 1.1},
	SILKENARMOR            = {ENTITY_TYPE = "ARMOR", WEIGHT = 2, DEFENSE = 0.75, BONUS_COOLDOWNRATE = -0.1},
	SPLINTMAIL             = {ENTITY_TYPE = "ARMOR", WEIGHT = 2, DEFENSE = 0.85},
	STEADFASTARMOR         = {ENTITY_TYPE = "ARMOR", WEIGHT = 3, DEFENSE = 0.9, SPEEDMULT = 0.85},
	KNOCKBACK_RESIST_SPEED = 2,

	--Forge Season 2
	STEADFASTGRANDARMOR  = {ENTITY_TYPE = "ARMOR", WEIGHT = 4, DEFENSE = 0.9, MAX_HP = 100},
	WHISPERINGGRANDARMOR = {ENTITY_TYPE = "ARMOR", WEIGHT = 4, DEFENSE = 0.8, MAX_HP = 75, PET_LEVEL_UP = 1},
	SILKENGRANDARMOR     = {ENTITY_TYPE = "ARMOR", WEIGHT = 4, DEFENSE = 0.8, MAX_HP = 50, BONUS_COOLDOWNRATE = -0.15},
	JAGGEDGRANDARMOR     = {ENTITY_TYPE = "ARMOR", WEIGHT = 4, DEFENSE = 0.8, MAX_HP = 50, BONUSDAMAGE = 1.2},

	-- Custom
	LAVAARENA_CHEFHAT = {ENTITY_TYPE = "HELMS", WEIGHT = 1, COOK_BUFF = 1.5},

	-------------------
	--==   Other   ==--
	-------------------
	--used for aggroholds on "onattacked" targeting functions for mobs.
	AGGROTIMER_LUCY = 1,
	AGGROTIMER_STUN = 2,

	ROUND_3_DELAY = 15,
	BOARILLA_SPAWN_DELAY = 15,

	STUN_STIMULI = {
		electric = true,
		explosive = true,
	},
	FORCED_HIT_STIMULI = {
		strong = true,
	},
	IGNORE_ABSORB_STIMULI = {
		electric = true,
		explosive = true,
		acid = true,
	},

	BUFFS_DATA = {
		SCORPEON_DOT            = {SYMBOL = "ACID", BUFF = false},
		HEALINGCIRCLE_REGENBUFF = {SYMBOL = "HEALING", BUFF = true},
		DAMAGER_BUFF            = {SYMBOL = "WATHGRITHR", BUFF = true},
		WICK_BUFF               = {SYMBOL = "WICKERBOTTOM", BUFF = true},
		--Generic Battlestandard Buffs--
		HEALER_BUFF				= {SYMBOL = "HEALING", BUFF = true}, --TODO make unique icons for all of these, perhaps more fitting for generic icons
		DAMAGER_BUFF            = {SYMBOL = "WATHGRITHR", BUFF = true},
		SHIELD_BUFF            = {SYMBOL = "WATHGRITHR", BUFF = true},
		SPEED_BUFF            = {SYMBOL = "WATHGRITHR", BUFF = true},
	},

	SPELL_TYPES = {
		CROWD_CONTROL = "crowd_control",
		HEAL          = "heal",
		DAMAGE        = "damage",
		SUMMON        = "summon",
	},

	PLAYER_EXCLUDE_TAGS = {"player", "companion", "ally"},

	CASTAOE_TAG_TO_STATE = { -- TODO better name?
		default = "castspell",
		[1] = {
			must_tags = {"aoeweapon_lunge"},
			state = "combat_lunge_start",
		},
		[2] = {
			must_tags = {"aoeweapon_leap"},
			cant_tags = {"superjump"},
			state = "combat_leap_start",
		},
		[3] = {
			must_tags = {"aoeweapon_leap", "superjump"},
			state = "combat_superjump_start",
		},
		[4] = {
			must_tags = {"blowdart"},
			cant_tags = {"plant_seed"},
			state = "blowdart_special",
		},
		[5] = {
			must_tags = {"throw_line"},
			state = "throw_line",
		},
		[6] = {
			must_tags = {"book"},
			state = "book",
		},
		[7] = {
			must_tags = {"parryweapon"},
			state = "parry_pre",
		},
		[8] = {
			must_tags = {"plant_seed"},
			state = "dolongaction",
		},
		[9] = {
			must_tags = {"soulstealer"},
			state = "portal_jumpin_pre",
		},
		[10] = {
			must_tags = {"slingshot"},
			state = "slingshot_shoot_alt", --temporary
		},
		[11] = {
			must_tags = {"punch"},
			state = "combat_punch",
		},
		[12] = {
			must_tags = {"pocketwatch"},
			state = "pocketwatch_castspell",
		}
	},
	ATTACK_TAG_TO_STATE = { -- TODO better name
		default = "attack",
		[1] = {
			must_tags = {"blowdart"},
			state = "blowdart",
		},
		[2] = {
			must_tags = {"thrown"},
			state = "throw",
		},
		[3] = {
			must_tags = {"propweapon"},
			state = "attack_prop_pre",
		},
		[4] = {
			must_tags = {"multithruster"},
			state = "multithrust_pre",
			server_only = true,
		},
		[5] = {
			must_tags = {"helmsplitter"},
			state = "helmsplitter_pre",
			server_only = true,
		},
		[6] = {
			must_tags = {"slingshot"},
			state = "slingshot_shoot_quick",
		},
	},

	CUSTOM_PICKUP_TAGS = { -- Short is default so no tag needed
		domediumaction = {"trap"},
		dolongaction   = {},
	},


	-- Used for displaying runs on the history panel
	CHARACTER_ICON_INFO = {}, -- ex. wilson = {atlas = "images/avatars_resize.xml", tex = "wilson.tex"}
	-- Use your mod id as an index, these icons will be used to label any content that comes from a specific mod.
	MOD_ICONS = {DEFAULT = {atlas = "images/reforged.xml", tex = "reforged_icon.tex"}},

	-------------------
	--==   Stats   ==--
	-------------------
	DEFAULT_FORGE_STATS = {"healingreceived","pet_damagetaken","altattacks","total_damagetaken","kills","turtillusflips","player_damagedealt","player_damagetaken","guardsbroken","cctime","healingdone","corpsesrevived","spellscast","petdeaths","deaths","total_damagedealt","attacks","ccbroken","pet_damagedealt","standards","blowdarts","stepcounter","aggroheld","numcc"},

	CUSTOM_STATS = {"attack_interrupt", "parry", "total_friendly_fire_damage_taken", "total_friendly_fire_damage_dealt"},

	DEFAULT_FORGE_TITLES = {
		altattacks        = {priority = 4,},
		total_damagetaken = {priority = 10, tier2 = 2000,},
		kills             = {priority = 5, tier2 = 20,},
		turtillusflips    = {priority = 9,},
		guardsbroken      = {priority = 8,},
		healingdone       = {priority = 3, tier2 = 3500,},
		corpsesrevived    = {priority = 13,},
		spellscast        = {priority = 2,},
		deaths            = {priority = 15,},
		total_damagedealt = {priority = 1, tier2 = 18000,},
		attacks           = {priority = 11,},
		standards         = {priority = 14,},
		blowdarts         = {priority = 12, tier2 = 1000,},
		stepcounter       = {priority = 16,},
		aggroheld         = {priority = 6, tier2 = 1000,},
		numcc             = {priority = 7,},
		player_damagedealt = {priority = 10,},
		player_damagetaken = {priority = 10,},
		pet_damagedealt    = {priority = 7,},
		pet_damagetaken    = {priority = 10,},
		cctime             = {priority = 6,},
		ccbroken           = {priority = 10,},
		petdeaths          = {priority = 10,},
		healingreceived    = {priority = 7,},
		total_friendly_fire_damage_dealt = {priority = 8,},
		none               = {priority = 99999,}
	},

	STAT_CATEGORIES = {
		total_damagedealt  = {category = "attack", priority = 1,},
		player_damagedealt = {category = "attack", priority = 2,},
		pet_damagedealt    = {category = "attack", priority = 3,},
		kills              = {category = "attack", priority = 4,},
		attacks            = {category = "attack", priority = 5,},
		altattacks         = {category = "attack", priority = 6,},
		blowdarts          = {category = "attack", priority = 7,},
		spellscast         = {category = "attack", priority = 8,},
		guardsbroken       = {category = "attack", priority = 9,},
		attack_interrupt   = {category = "attack", priority = 10,},
		total_friendly_fire_damage_dealt = {category = "attack", priority = 11,},
		total_friendly_fire_damage_taken = {category = "attack", priority = 12,},
		cctime             = {category = "crowd_control", priority = 1,},
		numcc              = {category = "crowd_control", priority = 2,},
		turtillusflips     = {category = "crowd_control", priority = 3,},
		ccbroken           = {category = "crowd_control", priority = 4,},
		total_damagetaken  = {category = "defense", priority = 1,},
		player_damagetaken = {category = "defense", priority = 2,},
		pet_damagetaken    = {category = "defense", priority = 3,},
		deaths             = {category = "defense", priority = 4,},
		petdeaths          = {category = "defense", priority = 5,},
		parry              = {category = "defense", priority = 6,},
		healingdone        = {category = "healing", priority = 1,},
		healingreceived    = {category = "healing", priority = 2,},
		corpsesrevived     = {category = "healing", priority = 3,},
		aggroheld          = {category = "other", priority = 1,},
		stepcounter        = {category = "other", priority = 2,},
		standards          = {category = "other", priority = 3,},
	},

	AFK_TIME = 600, -- TODO

	------------------------
	--==   Experience   ==--
	------------------------
	EXP = {
		GENERAL = { -- TODO adjust values
			UNIQUE_CHARACTERS = 2,--2000,--500, -- 250
			SAME_CHARACTERS   = {--2000,--500,
				WILSON       = 2,
				WILLOW       = 2,
				WENDY        = 2,
				WOLFGANG     = 3,
				WX78         = 3,
				WICKERBOTTOM = 3,
				WES          = 5,
				WAXWELL      = 4,
				WOODIE       = 3,
				WATHGRITHR   = 4,
				WEBBER       = 4,
				WINONA       = 2,
				WORTOX       = 3,
				WARLY        = 2,
				WORMWOOD     = 3,
				WURT         = 3,
				UNKNOWN      = 2,
			},
			RANDOM_CHARACTER       = 1,--1000,--200,
			RANDOM_CHARACTERS_TEAM = 5,--5000,--2000,
			NO_DEATHS         = 1,--1000,--800, -- 750 ?800?
			NO_DEATHS_TEAM    = 5,--5000,--2000, -- 750
			NO_ABILITIES      = 0.5,--200,
			NO_ABILITIES_TEAM = 10,--10000,
			CONSECUTIVE_MATCH = 500,--200,
			CONSECUTIVE_WIN   = 2000,--400,
			MAX_TIME          = 7200, -- for 6 players, will scale up for less players based on this value
			--PARTY_SIZE        = 25600, -- exponential decay for each party member up to 5 members
			PER_FRIEND        = 500,
			MAX_FRIENDS       = 2500,
			MAX_TIME_FRIENDS  = 1800, -- 30 minutes
		},
		MOB = {
			pitpig       = 5, -- 58?, 290
			crocommander = 10, -- 6, 60
			snortoise    = 20, -- 11, 220
			scorpeon     = 30, -- 11, 330
			boarilla     = 50, -- 3, 150
			boarrior     = 100, -- 1, 100
			rhinobros    = 75, -- 2, 150
			swineclops   = 150, -- 1, 150
		},
		DIFFICULTIES = {
			hard_mode = 5,--10,--10000,
		},
		GAMETYPES = {
			classic_rlgl = 2,--2000,
			rlgl         = 3,--5,--5000,
		},
		MUTATORS = { -- TODO adjust values
			MOB_STAT_STARTING_EXP           = 1000,
			MOB_STAT_SCALE                  = 5,--5000, -- scale is points per value, applied when value > 1
			MOB_DAMAGE_SCALE                = 1000, -- ^^^ only MOB_STAT_SCALE is used since they are all
			MOB_DEFENSE_SCALE               = 1000, -- ^^^ currently the same value
			MOB_SPEED_SCALE                 = 1000, -- ^^^
			BATTLESTANDARD_EFFICIENCY_SCALE = 5, -- ^^^
			NO_SLEEP      = 3,--5,--5000,
			NO_REVIVES    = 2,--5,--5000,
			NO_HUD        = 2,--2000,
			FRIENDLY_FIRE = 2,--2000,
			--ENDLESS       = 1000,
		},
		WAVESETS = {
			ROUND_1 = 100,
			ROUND_2 = 125,
			ROUND_3 = 150,
			ROUND_4 = 200,
			ROUND_5 = 400,
			ROUND_6 = 600,
			VICTORY = 1000,
		},
	},
	EMOTES = {},
}
REFORGED_TUNING.RHINOCEBRO2 = REFORGED_TUNING.RHINOCEBRO

return REFORGED_TUNING
