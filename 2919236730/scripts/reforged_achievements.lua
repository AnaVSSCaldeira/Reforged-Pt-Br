local RF_DATA = _G.REFORGED_DATA
local UserCommands = require "usercommands"
RF_DATA.achievements = {}

local LEVEL_XP = 20000
local function SetLevelXP(xp)
	return math.floor(LEVEL_XP*(xp or 1))
end

function AddAchievement(name, is_valid_fn, track_fn, on_match_complete_fn, max_progress, requirements, exp, tier, icon, id, mod)
    if RF_DATA.achievements[name] then
        Debug:Print("Attempted to add the achievement '" .. tostring(name) .."', but it already exists.", "error")
        return
    end
    local req = {
        player_count = nil,
        characters   = {},
        difficulties = {},
        gametypes    = {},
        maps         = {},
        modes        = {},
        mutators     = {},
        presets      = {},
        wavesets     = {},
    }
    _G.MergeTable(req, requirements or {}, true)
    RF_DATA.achievements[name] = {
        is_valid_fn          = is_valid_fn,
        track_fn             = track_fn,
        on_match_complete_fn = on_match_complete_fn,
        max_progress         = max_progress,
        requirements         = req,
        exp     = exp or 1000,
        tier    = tier,
        icon    = icon or {atlas = "images/reforged.xml", tex = "p_unknown.tex"},
        id      = id,
        mod     = mod,
    }
end
_G.AddAchievement = AddAchievement
--------------------------------------------------------------------------
-- Defeat the Game
--------------------------------------------------------------------------
local victory_id = "victory"
local function IsNonSpectator(player)
    return player.prefab ~= "spectator"
end
local function VictoryOnMatchComplete(lavaarenaevent, userid, achievement_name)
    if lavaarenaevent.victory then
        local achievement_tracker = _G.TheWorld.components.achievement_tracker
        achievement_tracker:UpdateAchievementProgress(achievement_name, userid, true)
    end
end
local function NoDeathsOnMatchComplete(lavaarenaevent, userid, achievement_name)
    if lavaarenaevent.victory then
        local stat_tracker = _G.TheWorld.components.stat_tracker
        local deaths = stat_tracker:GetStatTotal("deaths", userid)
        if deaths <= 0 then
            local achievement_tracker = _G.TheWorld.components.achievement_tracker
            achievement_tracker:UpdateAchievementProgress(achievement_name, userid, true)
        end
    end
end
---------------------
-- Normie Knockout --
---------------------
local swineclops_reforged_req = {
    player_count = 6,
    gametypes    = {"forge"},
    modes        = {"reforged"},
    wavesets     = {"swineclops"},
}
local swineclops_reforged_icon = {atlas = "images/rf_achievements.xml", tex = "ach_swineclops_defeat.tex"}
AddAchievement("swineclops_reforged", IsNonSpectator, nil, VictoryOnMatchComplete, nil, swineclops_reforged_req, SetLevelXP(1), 2, swineclops_reforged_icon, victory_id, "DEFAULT")
---------------------
-- TODO --
---------------------
local swineclops_hard_req = {
    player_count = 6,
    difficulties = {"hard"},
    gametypes    = {"forge"},
    wavesets     = {"swineclops"},
}
local swineclops_hard_icon = {atlas = "images/rf_achievements.xml", tex = "ach_hardmode_win.tex"}
AddAchievement("swineclops_hard", IsNonSpectator, nil, VictoryOnMatchComplete, nil, swineclops_hard_req, SetLevelXP(5), 3, swineclops_hard_icon, victory_id, "DEFAULT")
-----------------
-- Double Dent --
-----------------
local dt_normal_6_req = {
    player_count = 6,
    gametypes    = {"forge"},
    wavesets     = {"swineclops"},
    mutators = {
        mob_duplicator = 2,
    },
}
local dt_normal_6_icon = {atlas = "images/rf_achievements.xml", tex = "ach_double_trouble_win.tex"}
AddAchievement("dt_normal_6", IsNonSpectator, nil, VictoryOnMatchComplete, nil, dt_normal_6_req, SetLevelXP(2.5), 3, dt_normal_6_icon, victory_id, "DEFAULT")
-------------------
-- Double Danger --
-------------------
local dt_hard_req = {
    player_count = 6,
    difficulties = {"hard"},
    gametypes    = {"forge"},
    wavesets     = {"swineclops"},
    mutators = {
        mob_duplicator = 2,
    },
}
local dt_hard_icon = {atlas = "images/rf_achievements.xml", tex = "ach_double_trouble_hard_win.tex"}
AddAchievement("dt_hard", IsNonSpectator, nil, VictoryOnMatchComplete, nil, dt_hard_req, SetLevelXP(12), 4, dt_hard_icon, victory_id, "DEFAULT")
---------------------
-- TODO --
---------------------
local dt_normal_req = {
    gametypes    = {"forge"},
    wavesets     = {"swineclops"},
    mutators = {
        mob_duplicator = 2,
    },
}
local dt_normal_icon = {atlas = "images/rf_achievements.xml", tex = "ach_double_trouble_win.tex"}
AddAchievement("dt_normal", IsNonSpectator, nil, VictoryOnMatchComplete, nil, dt_normal_req, SetLevelXP(1.5), 2, dt_normal_icon, victory_id, "DEFAULT")
------------------
-- Triple Class --
------------------
local tt_normal_6_req = {
    player_count = 6,
    gametypes    = {"forge"},
    wavesets     = {"swineclops"},
    mutators = {
        mob_duplicator = 3,
    },
}
local tt_normal_6_icon = {atlas = "images/rf_achievements.xml", tex = "ach_triple_threat_win.tex"}
AddAchievement("tt_normal_6", IsNonSpectator, nil, VictoryOnMatchComplete, nil, tt_normal_6_req, SetLevelXP(7), 3, tt_normal_6_icon, victory_id, "DEFAULT")
-------------------
-- Triple Tyrant --
-------------------
local tt_hard_req = {
    player_count = 6,
    difficulties = {"hard"},
    gametypes    = {"forge"},
    wavesets     = {"swineclops"},
    mutators = {
        mob_duplicator = 3,
    },
}
local tt_hard_icon = {atlas = "images/rf_achievements.xml", tex = "ach_triple_threat_hard_win.tex"}
AddAchievement("tt_hard", IsNonSpectator, nil, VictoryOnMatchComplete, nil, tt_hard_req, SetLevelXP(20), 4, tt_hard_icon, victory_id, "DEFAULT")
---------------------
-- TODO --
---------------------
local tt_normal_req = {
    gametypes    = {"forge"},
    wavesets     = {"swineclops"},
    mutators = {
        mob_duplicator = 3,
    },
}
local tt_normal_icon = {atlas = "images/rf_achievements.xml", tex = "ach_triple_threat_win.tex"}
AddAchievement("tt_normal", IsNonSpectator, nil, VictoryOnMatchComplete, nil, tt_normal_req, SetLevelXP(4), 3, tt_normal_icon, victory_id, "DEFAULT")
-----------------------
-- Quadruple Cunning --
-----------------------
local quad_normal_req = {
    gametypes    = {"forge"},
    wavesets     = {"swineclops"},
    mutators = {
        mob_duplicator = 4,
    },
}
local quad_normal_icon = {atlas = "images/rf_achievements.xml", tex = "ach_quadruple_win.tex"}
AddAchievement("quad_normal", IsNonSpectator, nil, VictoryOnMatchComplete, nil, quad_normal_req, SetLevelXP(10), 4, quad_normal_icon, victory_id, "DEFAULT")
------------------------
-- Quintuple Struggle --
------------------------
local quin_normal_req = {
    gametypes    = {"forge"},
    wavesets     = {"swineclops"},
    mutators = {
        mob_duplicator = 5,
    },
}
local quin_normal_icon = {atlas = "images/rf_achievements.xml", tex = "ach_quintuple_win.tex"}
AddAchievement("quin_normal", IsNonSpectator, nil, VictoryOnMatchComplete, nil, quin_normal_req, SetLevelXP(20), 4, quin_normal_icon, victory_id, "DEFAULT")
---------------------
-- Tenfold Triumph --
---------------------
local ten_normal_req = {
    gametypes    = {"forge"},
    wavesets     = {"swineclops"},
    mutators = {
        mob_duplicator = 10,
    },
}
local ten_normal_icon = {atlas = "images/rf_achievements.xml", tex = "ach_tenfold_terror_win.tex"}
AddAchievement("ten_normal", IsNonSpectator, nil, VictoryOnMatchComplete, nil, ten_normal_req, SetLevelXP(50), 5, ten_normal_icon, victory_id, "DEFAULT")
-----------------
-- Insane Lane --
-----------------
local insanity_req = {
    player_count = 6,
    presets    = {"insanity"},
}
local insanity_icon = {atlas = "images/rf_achievements.xml", tex = "ach_insanity.tex"}
AddAchievement("insanity", IsNonSpectator, nil, VictoryOnMatchComplete, nil, insanity_req, SetLevelXP(100), 5, insanity_icon, victory_id, "DEFAULT")
----------------------
-- The Survey Corps --
----------------------
local titans_req = {
    player_count = 6,
    presets    = {"attack_of_titans"},
}
local titans_icon = {atlas = "images/rf_achievements.xml", tex = "ach_titan_slayer.tex"}
AddAchievement("titans", IsNonSpectator, nil, VictoryOnMatchComplete, nil, titans_req, SetLevelXP(2), 2, titans_icon, victory_id, "DEFAULT")
-----------------
--Late Arrival -- TODO
-----------------
local late_req = {
    player_count = 6,
}
local late_icon = {atlas = "images/rf_achievements.xml", tex = "ach_tenfold_terror_win.tex"}
--AddAchievement("late", IsNonSpectator, nil, VictoryOnMatchComplete, nil, late_req, 1000, 1, late_icon, victory_id, "DEFAULT")
---------------------
-- Plane Departing -- TODO
---------------------
local plane_req = {
}
local plane_icon = {atlas = "images/rf_achievements.xml", tex = "ach_tenfold_terror_win.tex"}
--AddAchievement("plane", IsNonSpectator, nil, VictoryOnMatchComplete, nil, plane_req, 1000, 1, plane_icon, victory_id, "DEFAULT")
--------------------------------------------------------------------------
-- Red Light Green Light
--------------------------------------------------------------------------
local rlgl_id = "rlgl"
---------------
-- Lights Up --
---------------
local rlgl_normal_req = {
    player_count = 6,
    gametypes    = {"classic_rlgl"},
    wavesets     = {"swineclops"},
}
local rlgl_normal_icon = {atlas = "images/rf_achievements.xml", tex = "ach_rlgl.tex"}
AddAchievement("rlgl_normal", IsNonSpectator, nil, VictoryOnMatchComplete, nil, rlgl_normal_req, SetLevelXP(2), 2, rlgl_normal_icon, rlgl_id, "DEFAULT")
--------------------
-- Traffic Stopper --
--------------------
local rlglolbl_normal_req = {
    player_count = 6,
    gametypes    = {"rlgl"},
    wavesets     = {"swineclops"},
}
local rlglolbl_normal_icon = {atlas = "images/rf_achievements.xml", tex = "ach_rlglolbl.tex"}
AddAchievement("rlglolbl_normal", IsNonSpectator, nil, VictoryOnMatchComplete, nil, rlglolbl_normal_req, SetLevelXP(4), 3, rlglolbl_normal_icon, rlgl_id, "DEFAULT")
----------------------
-- Over The Rainbow -- TODO
----------------------
local rainbow_normal_req = {
    player_count = 6,
    gametypes    = {"rainbow_lights"},
    wavesets     = {"swineclops"},
}
local rainbow_normal_icon = {atlas = "images/rf_achievements.xml", tex = "ach_rainbowlight.tex"}
--AddAchievement("rainbow_normal", IsNonSpectator, nil, VictoryOnMatchComplete, nil, rainbow_normal_req, 1000, 1, rainbow_normal_icon, rlgl_id, "DEFAULT")
---------------
-- Light Imp --
---------------
local rlgl_hard_req = {
    player_count = 6,
    difficulties = {"hard"},
    gametypes    = {"classic_rlgl"},
    wavesets     = {"swineclops"},
}
local rlgl_hard_icon = {atlas = "images/rf_achievements.xml", tex = "ach_rlgl_hard.tex"}
AddAchievement("rlgl_hard", IsNonSpectator, nil, VictoryOnMatchComplete, nil, rlgl_hard_req, SetLevelXP(6), 3, rlgl_hard_icon, rlgl_id, "DEFAULT")
-------------------
-- Traffic Demon --
-------------------
local rlglolbl_hard_req = {
    player_count = 6,
    difficulties = {"hard"},
    gametypes    = {"rlgl"},
    wavesets     = {"swineclops"},
}
local rlglolbl_hard_icon = {atlas = "images/rf_achievements.xml", tex = "ach_rlglolbl_hard.tex"}
AddAchievement("rlglolbl_hard", IsNonSpectator, nil, VictoryOnMatchComplete, nil, rlglolbl_hard_req, SetLevelXP(15), 4, rlglolbl_hard_icon, rlgl_id, "DEFAULT")
----------------
-- Hell Raver -- TODO
----------------
local rainbow_hard_req = {
    player_count = 6,
    difficulties = {"hard"},
    gametypes    = {"rainbow_lights"},
    wavesets     = {"swineclops"},
}
local rainbow_hard_icon = {atlas = "images/rf_achievements.xml", tex = "ach_raindbowlight_hard.tex"}
--AddAchievement("rainbow_hard", IsNonSpectator, nil, VictoryOnMatchComplete, nil, rainbow_hard_req, 1000, 1, rainbow_hard_icon, rlgl_id, "DEFAULT")
-------------------
-- What A Lighty --
-------------------
local rlgl_no_deaths_req = {
    player_count = 6,
    gametypes    = {"classic_rlgl"},
    wavesets     = {"swineclops"},
}
local rlgl_no_deaths_icon = {atlas = "images/rf_achievements.xml", tex = "ach_rlgl_deathless.tex"}
AddAchievement("rlgl_no_deaths", IsNonSpectator, nil, NoDeathsOnMatchComplete, nil, rlgl_no_deaths_req, SetLevelXP(4), 3, rlgl_no_deaths_icon, rlgl_id, "DEFAULT")
-------------------
-- Pulses Lights --
-------------------
local rlglolbl_no_deaths_req = {
    player_count = 6,
    gametypes    = {"rlgl"},
    wavesets     = {"swineclops"},
}
local rlglolbl_no_deaths_icon = {atlas = "images/rf_achievements.xml", tex = "ach_rlglolbl_deathless.tex"}
AddAchievement("rlglolbl_no_deaths", IsNonSpectator, nil, NoDeathsOnMatchComplete, nil, rlglolbl_no_deaths_req, SetLevelXP(10), 4, rlglolbl_no_deaths_icon, rlgl_id, "DEFAULT")
-----------------
-- Shine On Me -- TODO
-----------------
local rainbow_no_deaths_req = {
    player_count = 6,
    gametypes    = {"rainbow_lights"},
    wavesets     = {"swineclops"},
}
local rainbow_no_deaths_icon = {atlas = "images/rf_achievements.xml", tex = "ach_rainbowlightl_deathless.tex"}
--AddAchievement("rainbow_no_deaths", IsNonSpectator, nil, NoDeathsOnMatchComplete, nil, rainbow_no_deaths_req, 1000, 1, rainbow_no_deaths_icon, rlgl_id, "DEFAULT")
--------------------------------------------------------------------------
-- Mutators
--------------------------------------------------------------------------
local mutator_id = "mutator"
---------------------------
-- The Neverending Story --
---------------------------
local endless_req = {
    player_count = 6,
    wavesets     = {"swineclops"},
    mutators = {
        endless = true,
    }
}
local function EndlessOnMatchComplete(lavaarenaevent, userid, achievement_name)
    if lavaarenaevent.total_rounds_completed >= 21 then
        local achievement_tracker = _G.TheWorld.components.achievement_tracker
        achievement_tracker:UpdateAchievementProgress(achievement_name, userid, true)
    end
end
local endless_icon = {atlas = "images/rf_achievements.xml", tex = "ach_endless.tex"}
AddAchievement("endless", IsNonSpectator, nil, EndlessOnMatchComplete, nil, endless_req, SetLevelXP(6), 2, endless_icon, mutator_id, "DEFAULT")
--------------------
-- Cry Me A River --
--------------------
local no_revives_req = {
    player_count = 6,
    wavesets     = {"swineclops"},
    mutators = {
        no_revives = true,
    }
}
local no_revives_icon = {atlas = "images/rf_achievements.xml", tex = "ach_no_revives.tex"}
AddAchievement("no_revives", IsNonSpectator, nil, VictoryOnMatchComplete, nil, no_revives_req, SetLevelXP(2), 2, no_revives_icon, mutator_id, "DEFAULT")
-------------
-- Hudless --
-------------
local no_hud_req = {
    player_count = 6,
    wavesets     = {"swineclops"},
    mutators = {
        no_hud = true,
    }
}
local no_hud_icon = {atlas = "images/rf_achievements.xml", tex = "ach_nohud.tex"}
AddAchievement("no_hud", IsNonSpectator, nil, VictoryOnMatchComplete, nil,no_hud_req, SetLevelXP(1.5), 2, no_hud_icon, mutator_id, "DEFAULT")
--------------------------
-- Sleepless In Seattle --
--------------------------
local no_sleep_req = {
    player_count = 6,
    wavesets     = {"swineclops"},
    mutators = {
        no_sleep = true,
    }
}
local no_sleep_icon = {atlas = "images/rf_achievements.xml", tex = "ach_sleepless.tex"}
AddAchievement("no_sleep", IsNonSpectator, nil, VictoryOnMatchComplete, nil, no_sleep_req, SetLevelXP(4), 3, no_sleep_icon, mutator_id, "DEFAULT")
------------------------------
-- Do You Feel Lucky, Punk? --
------------------------------
local friendly_fire_req = {
    player_count = 6,
    wavesets     = {"swineclops"},
    mutators = {
        friendly_fire = true,
    }
}
local friendly_fire_icon = {atlas = "images/rf_achievements.xml", tex = "ach_friendlyfire.tex"}
AddAchievement("friendly_fire", IsNonSpectator, nil, VictoryOnMatchComplete, nil, friendly_fire_req, SetLevelXP(1.5), 2, friendly_fire_icon, mutator_id, "DEFAULT")
---------------------------------
-- Friends don’t Shoot Friends --
---------------------------------
local function NoFriendlyFireOnMatchComplete(lavaarenaevent, userid, achievement_name)
    local stat_tracker = _G.TheWorld.components.stat_tracker
    local friendly_fire_damage = stat_tracker:GetStatTotal("total_friendly_fire_damage_dealt")
    if lavaarenaevent.victory and friendly_fire_damage <= 0 then
        local achievement_tracker = _G.TheWorld.components.achievement_tracker
        achievement_tracker:UpdateAchievementProgress(achievement_name, userid, true)
    end
end
local no_friendly_fire_icon = {atlas = "images/rf_achievements.xml", tex = "ach_true_friends.tex"}
AddAchievement("no_friendly_fire", IsNonSpectator, nil, NoFriendlyFireOnMatchComplete, nil, friendly_fire_req, SetLevelXP(7.5), 3, no_friendly_fire_icon, mutator_id, "DEFAULT")
--------------------------------------------------------------------------
-- Control The Damage
--------------------------------------------------------------------------
local damage_id = "damage"
-----------------
-- Damage Free --
-----------------
local no_damage_req = {
    player_count = 6,
    gametypes    = {"forge"},
    wavesets     = {"swineclops"},
}
local function NoDamageOnMatchComplete(lavaarenaevent, userid, achievement_name)
    local stat_tracker = _G.TheWorld.components.stat_tracker
    local damage_taken = stat_tracker:GetStatTotal("player_damagetaken", userid)
    if lavaarenaevent.victory and damage_taken <= 0 then
        local achievement_tracker = _G.TheWorld.components.achievement_tracker
        achievement_tracker:UpdateAchievementProgress(achievement_name, userid, true)
    end
end
local no_damage_icon = {atlas = "images/rf_achievements.xml", tex = "ach_damageless.tex"}
AddAchievement("no_damage", IsNonSpectator, nil, NoDamageOnMatchComplete, nil, no_damage_req, SetLevelXP(3), 2, no_damage_icon, damage_id, "DEFAULT")
------------------
-- Damage Ghost --
------------------
local no_damage_double_req = {
    gametypes = {"forge"},
    wavesets  = {"swineclops"},
    mutators = {
        mob_duplicator = 2,
    }
}
local no_damage_double_icon = {atlas = "images/rf_achievements.xml", tex = "ach_doubletrouble_damageless.tex"}
AddAchievement("no_damage_double", IsNonSpectator, nil, NoDamageOnMatchComplete, nil, no_damage_double_req, SetLevelXP(6), 3, no_damage_double_icon, damage_id, "DEFAULT")
-------------------
-- Damage Demons --
-------------------
local function LowTeamDamageOnMatchComplete(lavaarenaevent, userid, achievement_name)
    local stat_tracker = _G.TheWorld.components.stat_tracker
    local team_low_damage = true
    for id,_ in pairs(stat_tracker.stats) do
        local damage_taken = stat_tracker:GetStatTotal("player_damagetaken", id)
        if damage_taken > 200 then
            team_low_damage = false
            break
        end
    end
    if lavaarenaevent.victory and team_low_damage then
        local achievement_tracker = _G.TheWorld.components.achievement_tracker
        achievement_tracker:UpdateAchievementProgress(achievement_name, userid, true)
    end
end
local low_team_damage_icon = {atlas = "images/rf_achievements.xml", tex = "ach_team_damageless.tex"}
--AddAchievement("low_team_damage", IsNonSpectator, nil, LowTeamDamageOnMatchComplete, nil, no_damage_req, SetLevelXP(15), 4, low_team_damage_icon, damage_id, "DEFAULT")
--------------------------------------------------------------------------
-- Survive The Fire
--------------------------------------------------------------------------
local survive_id = "survive"
local function NoTeamDeathsOnMatchComplete(lavaarenaevent, userid, achievement_name)
    local stat_tracker = _G.TheWorld.components.stat_tracker
    local total_deaths = stat_tracker:GetStatTotal("deaths")
    if lavaarenaevent.victory and total_deaths <= 0 then
        local achievement_tracker = _G.TheWorld.components.achievement_tracker
        achievement_tracker:UpdateAchievementProgress(achievement_name, userid, true)
    end
end
------------------
-- Hard To Kill --
------------------
local no_team_deaths_boarilla_req = {
    player_count = 6,
    wavesets = {"boarilla"},
}
local no_team_deaths_boarilla_icon = {atlas = "images/rf_achievements.xml", tex = "ach_boarilla_defeat2.tex"}
AddAchievement("no_team_deaths_boarilla", IsNonSpectator, nil, NoTeamDeathsOnMatchComplete, nil, no_team_deaths_boarilla_req, SetLevelXP(0.5), 1, no_team_deaths_boarilla_icon, survive_id, "DEFAULT")
------------------
--Just Wont Die --
------------------
local no_team_deaths_boarrior_req = {
    player_count = 6,
    wavesets = {"classic"},
}
local no_team_deaths_boarrior_icon = {atlas = "images/rf_achievements.xml", tex = "ach_boarrior_defeat.tex"}
AddAchievement("no_team_deaths_boarrior", IsNonSpectator, nil, NoTeamDeathsOnMatchComplete, nil, no_team_deaths_boarrior_req, SetLevelXP(2), 2, no_team_deaths_boarrior_icon, survive_id, "DEFAULT")
-------------------
-- Solo Survivor --
-------------------
local no_deaths_swineclops_req = {
    player_count = 6,
    wavesets = {"swineclops"},
}
local function NoDeathsSwineclopsOnMatchComplete(lavaarenaevent, userid, achievement_name)
    local stat_tracker = _G.TheWorld.components.stat_tracker
    local total_deaths = stat_tracker:GetStatTotal("deaths", userid)
    if lavaarenaevent.victory and total_deaths <= 0 then
        local achievement_tracker = _G.TheWorld.components.achievement_tracker
        achievement_tracker:UpdateAchievementProgress(achievement_name, userid, true)
    end
end
local no_deaths_swineclops_icon = {atlas = "images/rf_achievements.xml", tex = "ach_solo_survivor.tex"}
AddAchievement("no_deaths_swineclops", IsNonSpectator, nil, NoDeathsSwineclopsOnMatchComplete, nil, no_deaths_swineclops_req, SetLevelXP(2), 2, no_deaths_swineclops_icon, survive_id, "DEFAULT")
-------------------
-- Team Survivor --
-------------------
local no_team_deaths_swineclops_req = {
    player_count = 6,
    wavesets = {"swineclops"},
}
local no_team_deaths_swineclops_icon = {atlas = "images/rf_achievements.xml", tex = "ach_team_survivor.tex"}
AddAchievement("no_team_deaths_swineclops", IsNonSpectator, nil, NoTeamDeathsOnMatchComplete, nil, no_team_deaths_swineclops_req, SetLevelXP(3), 2, no_team_deaths_swineclops_icon, survive_id, "DEFAULT")
-------------------------
-- Survival of Misfits --
-------------------------
local unique_team_req = {
    player_count = 6,
    wavesets = {"swineclops"},
}
local unique_team_icon = {atlas = "images/rf_achievements.xml", tex = "ach_unique_deathless.tex"}
AddAchievement("unique_team", IsNonSpectator, nil, NoTeamDeathsOnMatchComplete, nil, unique_team_req, SetLevelXP(1.5), 2, unique_team_icon, survive_id, "DEFAULT")
-----------------------------
-- Survival Of The Randoms --
-----------------------------
local random_team_6_no_deaths_req = {
    player_count = 6,
    wavesets = {"swineclops"},
}
local function IsAllRandomTeam(player)
    local stat_tracker = _G.TheWorld.components.stat_tracker
    for userid,_ in pairs(stat_tracker.stats) do
        if not stat_tracker.random_characters[userid] then
            return false
        end
    end
    return true
end
local function NoTeamDeathsAllRandomOnMatchComplete(lavaarenaevent, userid, achievement_name)
    local stat_tracker = _G.TheWorld.components.stat_tracker
    local total_deaths = stat_tracker:GetStatTotal("deaths")
    if lavaarenaevent.victory and total_deaths <= 0 and IsAllRandomTeam() then
        local achievement_tracker = _G.TheWorld.components.achievement_tracker
        achievement_tracker:UpdateAchievementProgress(achievement_name, userid, true)
    end
end
local random_team_6_no_deaths_icon = {atlas = "images/rf_achievements.xml", tex = "ach_random_deathless.tex"}
AddAchievement("random_team_6_no_deaths", IsAllRandomTeam, nil, NoTeamDeathsAllRandomOnMatchComplete, nil, random_team_6_no_deaths_req, SetLevelXP(4), 3, random_team_6_no_deaths_icon, survive_id, "DEFAULT")
--------------------
-- Throw The Dice --
--------------------
local random_team_no_deaths_req = {
    wavesets = {"swineclops"},
}
local random_team_no_deaths_icon = {atlas = "images/rf_achievements.xml", tex = "ach_team_random_deathless.tex"}
AddAchievement("random_team_no_deaths", IsAllRandomTeam, nil, NoTeamDeathsAllRandomOnMatchComplete, nil, random_team_no_deaths_req, SetLevelXP(3), 2, random_team_no_deaths_icon, survive_id, "DEFAULT")
--------------------------------------------------------------------------
-- Less Is More
--------------------------------------------------------------------------
local player_count_id = "player_count"
--------------
-- Fast Run --
--------------
local team_5_swinelcops_req = {
    player_count = 5,
    wavesets = {"swineclops"},
}
local team_5_swinelcops_icon = {atlas = "images/rf_achievements.xml", tex = "ach_5man.tex"}
AddAchievement("team_5_swinelcops", IsNonSpectator, nil, VictoryOnMatchComplete, nil, team_5_swinelcops_req, SetLevelXP(1.5), 2, team_5_swinelcops_icon, player_count_id, "DEFAULT")
----------------
-- Quick Four --
----------------
local team_4_swinelcops_req = {
    player_count = 4,
    wavesets = {"swineclops"},
}
local team_4_swinelcops_icon = {atlas = "images/rf_achievements.xml", tex = "ach_4man.tex"}
AddAchievement("team_4_swinelcops", IsNonSpectator, nil, VictoryOnMatchComplete, nil, team_4_swinelcops_req, SetLevelXP(3), 3, team_4_swinelcops_icon, player_count_id, "DEFAULT")
--------------------------
-- Fastest Trio In Town --
--------------------------
local team_3_swinelcops_req = {
    player_count = 3,
    wavesets = {"swineclops"},
}
local team_3_swinelcops_icon = {atlas = "images/rf_achievements.xml", tex = "ach_3man.tex"}
AddAchievement("team_3_swinelcops", IsNonSpectator, nil, VictoryOnMatchComplete, nil, team_3_swinelcops_req, SetLevelXP(10), 4, team_3_swinelcops_icon, player_count_id, "DEFAULT")
-----------------
-- Dynamic Duo --
-----------------
local team_2_swinelcops_req = {
    player_count = 2,
    wavesets = {"swineclops"},
}
local team_2_swinelcops_icon = {atlas = "images/rf_achievements.xml", tex = "ach_2man.tex"}
AddAchievement("team_2_swinelcops", IsNonSpectator, nil, VictoryOnMatchComplete, nil, team_2_swinelcops_req, SetLevelXP(30), 5, team_2_swinelcops_icon, player_count_id, "DEFAULT")
--------------------------------------------------------------------------
-- Runners Arena
--------------------------------------------------------------------------
local speed_run_id = "speed_run"
local speed_run_req = {
    player_count = 6,
    wavesets = {"swineclops"},
}
local double_speed_run_req = {
    player_count = 6,
    wavesets = {"swineclops"},
    mutators = {
        mob_duplicator = 2,
    }
}
local function SpeedRunOnMatchComplete(lavaarenaevent, userid, achievement_name, time)
    if lavaarenaevent.victory and lavaarenaevent.duration <= time then
        local achievement_tracker = _G.TheWorld.components.achievement_tracker
        achievement_tracker:UpdateAchievementProgress(achievement_name, userid, true)
    end
end
----------------------
-- Bronze Speed Run --
----------------------
local function BronzeSpeedRunOnMatchComplete(lavaarenaevent, userid, achievement_name)
    SpeedRunOnMatchComplete(lavaarenaevent, userid, achievement_name, 1500) -- 25 minutes
end
local bronze_speed_run_icon = {atlas = "images/rf_achievements.xml", tex = "ach_time_bronze.tex"}
AddAchievement("bronze_speed_run", IsNonSpectator, nil, BronzeSpeedRunOnMatchComplete, nil, speed_run_req, SetLevelXP(1.5), 2, bronze_speed_run_icon, speed_run_id, "DEFAULT")
----------------------
-- Silver Speed Run --
----------------------
local function SilverSpeedRunOnMatchComplete(lavaarenaevent, userid, achievement_name)
    SpeedRunOnMatchComplete(lavaarenaevent, userid, achievement_name, 1200) -- 20 minutes
end
local silver_speed_run_icon = {atlas = "images/rf_achievements.xml", tex = "ach_time_silver.tex"}
AddAchievement("silver_speed_run", IsNonSpectator, nil, SilverSpeedRunOnMatchComplete, nil, speed_run_req, SetLevelXP(2.5), 2, silver_speed_run_icon, speed_run_id, "DEFAULT")
----------------------
-- Gold Speed Run --
----------------------
local function GoldSpeedRunOnMatchComplete(lavaarenaevent, userid, achievement_name)
    SpeedRunOnMatchComplete(lavaarenaevent, userid, achievement_name, 900) -- 15 minutes
end
local gold_speed_run_icon = {atlas = "images/rf_achievements.xml", tex = "ach_time_gold.tex"}
AddAchievement("gold_speed_run", IsNonSpectator, nil, GoldSpeedRunOnMatchComplete, nil, speed_run_req, SetLevelXP(3.5), 2, gold_speed_run_icon, speed_run_id, "DEFAULT")
------------------------
-- Platinum Speed Run --
------------------------
local function PlatSpeedRunOnMatchComplete(lavaarenaevent, userid, achievement_name)
    SpeedRunOnMatchComplete(lavaarenaevent, userid, achievement_name, 600) -- 10 minutes
end
local plat_speed_run_icon = {atlas = "images/rf_achievements.xml", tex = "ach_time_platinum.tex"}
AddAchievement("plat_speed_run", IsNonSpectator, nil, PlatSpeedRunOnMatchComplete, nil, speed_run_req, SetLevelXP(10), 3, plat_speed_run_icon, speed_run_id, "DEFAULT")
-----------------------------
-- Double Bronze Speed Run --
-----------------------------
local function DoubleBronzeSpeedRunOnMatchComplete(lavaarenaevent, userid, achievement_name)
    SpeedRunOnMatchComplete(lavaarenaevent, userid, achievement_name, 2100) -- 35 minutes
end
local double_bronze_speed_run_icon = {atlas = "images/rf_achievements.xml", tex = "ach_time_bronze_doubletrouble.tex"}
AddAchievement("double_bronze_speed_run", IsNonSpectator, nil, DoubleBronzeSpeedRunOnMatchComplete, nil, double_speed_run_req, SetLevelXP(2), 2, double_bronze_speed_run_icon, speed_run_id, "DEFAULT")
-----------------------------
-- Double Silver Speed Run --
-----------------------------
local function DoubleSilverSpeedRunOnMatchComplete(lavaarenaevent, userid, achievement_name)
    SpeedRunOnMatchComplete(lavaarenaevent, userid, achievement_name, 1800) -- 30 minutes
end
local double_silver_speed_run_icon = {atlas = "images/rf_achievements.xml", tex = "ach_time_silver_doubletrouble.tex"}
AddAchievement("double_silver_speed_run", IsNonSpectator, nil, DoubleSilverSpeedRunOnMatchComplete, nil, double_speed_run_req, SetLevelXP(2.5), 2, double_silver_speed_run_icon, speed_run_id, "DEFAULT")
---------------------------
-- Double Gold Speed Run --
---------------------------
local function DoubleGoldSpeedRunOnMatchComplete(lavaarenaevent, userid, achievement_name)
    SpeedRunOnMatchComplete(lavaarenaevent, userid, achievement_name, 1500) -- 25 minutes
end
local double_gold_speed_run_icon = {atlas = "images/rf_achievements.xml", tex = "ach_time_gold_doubletrouble.tex"}
AddAchievement("double_gold_speed_run", IsNonSpectator, nil, DoubleGoldSpeedRunOnMatchComplete, nil, double_speed_run_req, SetLevelXP(3.5), 3, double_gold_speed_run_icon, speed_run_id, "DEFAULT")
-------------------------------
-- Double Platinum Speed Run --
-------------------------------
local function DoublePlatSpeedRunOnMatchComplete(lavaarenaevent, userid, achievement_name)
    SpeedRunOnMatchComplete(lavaarenaevent, userid, achievement_name, 1200) -- 20 minutes
end
local double_plat_speed_run_icon = {atlas = "images/rf_achievements.xml", tex = "ach_time_platinum_doubletrouble.tex"}
AddAchievement("double_plat_speed_run", IsNonSpectator, nil, DoublePlatSpeedRunOnMatchComplete, nil, double_speed_run_req, SetLevelXP(10), 3, double_plat_speed_run_icon, speed_run_id, "DEFAULT")
--------------------------------------------------------------------------
-- Master of Mobs
--------------------------------------------------------------------------
local mob_id = "mob"
------------------------
-- Down But Not Snout --
------------------------
local pitpig_silver_req = {
    gametypes = {"forge"},
    wavesets  = {"boarilla", "boarillas", "classic", "rhinocebros", "swineclops"},
}
local function PitpigSilverTrack(achievement_tracker, player, achievement_name, server_progress, client_progress)
    local function CheckPitpigSilverProgress(world, data)
        if data.round == 1 then
            local stat_tracker = _G.TheWorld.components.stat_tracker
            local team_damage_taken = stat_tracker:GetStatTotal("player_damagetaken")
            if team_damage_taken <= 800 then
                local achievement_tracker = _G.TheWorld.components.achievement_tracker
                achievement_tracker:UpdateAchievementProgress(achievement_name, player.userid, true)
            end
        end
        world:RemoveEventCallback("round_complete", CheckPitpigSilverProgress)
    end
    _G.TheWorld:ListenForEvent("round_complete", CheckPitpigSilverProgress)
end
local pitpig_silver_icon = {atlas = "images/rf_achievements.xml", tex = "ach_pitpig_silver.tex"}
AddAchievement("pitpig_silver", IsNonSpectator, PitpigSilverTrack, nil, nil, pitpig_silver_req, SetLevelXP(0.5), 1, pitpig_silver_icon, mob_id, "DEFAULT")
-------------------
-- Pig On A Spit --
-------------------
local pitpig_gold_req = {
    gametypes = {"forge"},
    wavesets  = {"boarilla", "boarillas", "classic", "rhinocebros", "swineclops"},
}
-- This function is nearly identical to pitpig_silver, but they need to be separate so that the EventListeners do not remove each other by mistake.
local function PitpigGoldTrack(achievement_tracker, player, achievement_name, server_progress, client_progress)
    local function CheckPitpigGoldProgress(world, data)
        if data.round == 1 then
            local stat_tracker = _G.TheWorld.components.stat_tracker
            local team_damage_taken = stat_tracker:GetStatTotal("player_damagetaken")
            if team_damage_taken <= 600 then
                local achievement_tracker = _G.TheWorld.components.achievement_tracker
                achievement_tracker:UpdateAchievementProgress(achievement_name, player.userid, true)
            end
        end
        world:RemoveEventCallback("round_complete", CheckPitpigGoldProgress)
    end
    _G.TheWorld:ListenForEvent("round_complete", CheckPitpigGoldProgress)
end
local pitpig_gold_icon = {atlas = "images/rf_achievements.xml", tex = "ach_pitpig_gold.tex"}
AddAchievement("pitpig_gold", IsNonSpectator, PitpigGoldTrack, nil, nil, pitpig_gold_req, SetLevelXP(0.75), 1, pitpig_gold_icon, mob_id, "DEFAULT")
-----------------------
-- Crocs Before Pigs -- TODO need to make it both rounds
-----------------------
local croc_req = {
    difficulties = {"normal"},
    gametypes    = {"forge"},
    wavesets     = {"boarilla", "boarillas", "classic", "rhinocebros", "swineclops"},
}
local function CrocTrack(achievement_tracker, player, achievement_name, server_progress, client_progress)
    local function CheckCrocProgress(world, data)
        local lavaarenaevent = _G.TheWorld.components.lavaarenaevent
        if lavaarenaevent.current_round == 2 then
            local pitpig_died = false
            local croc_death_count = 0
            local mobs = _G.UTIL.WAVESET.OrganizeAllMobs(world.components.forgemobtracker.live_mobs[lavaarenaevent.current_round][lavaarenaevent.current_wave])
            for _,pitpig in pairs(mobs.pitpig) do
                pitpig:ListenForEvent("death", function()
                    pitpig_died = true
                end)
            end
			for _,croc in pairs(mobs.crocommander) do
				croc:ListenForEvent("death", function()
				croc_death_count = croc_death_count + 1
					if not pitpig_died and croc_death_count >= #mobs.crocommander then
						achievement_tracker:UpdateAchievementProgress(achievement_name, player.userid, nil, 1)
					elseif pitpig_died then
						achievement_tracker:UpdateAchievementProgress(achievement_name, player.userid, nil, nil, 0)
					end
				end)
			end
        elseif lavaarenaevent.current_round > 2 then
            world:RemoveEventCallback("spawningfinished", CheckCrocProgress)
        end
    end
    _G.TheWorld:ListenForEvent("spawningfinished", CheckCrocProgress)
end
local croc_icon = {atlas = "images/rf_achievements.xml", tex = "ach_crocommander.tex"}
AddAchievement("croc", IsNonSpectator, CrocTrack, nil, 2, croc_req, SetLevelXP(0.75), 1, croc_icon, mob_id, "DEFAULT")
---------------
-- Big Wheel --
---------------
local snortoise_silver_req = {
    gametypes = {"forge"},
    wavesets  = {"boarilla", "boarillas", "classic", "rhinocebros", "swineclops"},
}
local function SnortoiseSilverTrack(achievement_tracker, player, achievement_name, server_progress, client_progress)
    local function CheckSnortoiseProgress(world, data)
        local lavaarenaevent = _G.TheWorld.components.lavaarenaevent
        if lavaarenaevent.current_round == 3 then
            local spin_count = 0
            local mobs = _G.UTIL.WAVESET.OrganizeAllMobs(world.components.forgemobtracker.live_mobs[lavaarenaevent.current_round][lavaarenaevent.current_wave])
            local function UpdateSpinCount(inst, data)
                if inst.sg.laststate and inst.sg.laststate.name == "attack_spin" and data.statename == "attack_spin_loop" then
                    spin_count = spin_count + 1
                    if spin_count > 3 then
                        for _,snortoise in pairs(mobs.snortoise) do
                            if snortoise:IsValid() then
                                snortoise:RemoveEventCallback("newstate", UpdateSpinCount)
                            end
                        end
                        world:RemoveEventCallback("spawningfinished", CheckSnortoiseProgress)
                    end
                end
            end
            for _,snortoise in pairs(mobs.snortoise) do
                snortoise:ListenForEvent("newstate", UpdateSpinCount)
            end
            local function CheckSpinCount(world, data)
                if data.round == 3 then
                    if spin_count <= 3 then
                        local achievement_tracker = _G.TheWorld.components.achievement_tracker
                        achievement_tracker:UpdateAchievementProgress(achievement_name, player.userid, true)
                        world:RemoveEventCallback("spawningfinished", CheckSnortoiseProgress)
                    end
                    world:RemoveEventCallback("round_complete", CheckSpinCount)
                end
            end
            world:ListenForEvent("round_complete", CheckSpinCount)
        elseif lavaarenaevent.current_round > 3 then
            world:RemoveEventCallback("spawningfinished", CheckSnortoiseProgress)
        end
    end
    _G.TheWorld:ListenForEvent("spawningfinished", CheckSnortoiseProgress)
end
local snortoise_silver_icon = {atlas = "images/rf_achievements.xml", tex = "ach_snortoise_silver.tex"}
AddAchievement("snortoise_silver", IsNonSpectator, SnortoiseSilverTrack, nil, nil, snortoise_silver_req, SetLevelXP(0.75), 1, snortoise_silver_icon, mob_id, "DEFAULT")
-----------------
-- Unspun Hero --
-----------------
local snortoise_gold_req = {
    gametypes = {"forge"},
    wavesets  = {"boarilla", "boarillas", "classic", "rhinocebros", "swineclops"},
}
-- This function is nearly identical to the silver version, but are separate to prevent any conflict of removing event listeners.
local function SnortoiseGoldTrack(achievement_tracker, player, achievement_name, server_progress, client_progress)
    local function CheckSnortoiseProgress(world, data)
        local lavaarenaevent = _G.TheWorld.components.lavaarenaevent
        if lavaarenaevent.current_round == 3 then
            local spin_count = 0
            local mobs = _G.UTIL.WAVESET.OrganizeAllMobs(world.components.forgemobtracker.live_mobs[lavaarenaevent.current_round][lavaarenaevent.current_wave])
            local function UpdateSpinCount(inst, data)
                if inst.sg.laststate and inst.sg.laststate.name == "attack_spin" and data.statename == "attack_spin_loop" then
                    spin_count = spin_count + 1
                    if spin_count >= 1 then
                        for _,snortoise in pairs(mobs.snortoise) do
                            if snortoise:IsValid() then
                                snortoise:RemoveEventCallback("newstate", UpdateSpinCount)
                            end
                        end
                        world:RemoveEventCallback("spawningfinished", CheckSnortoiseProgress)
                    end
                end
            end
            for _,snortoise in pairs(mobs.snortoise) do
                snortoise:ListenForEvent("newstate", UpdateSpinCount)
            end
            local function CheckSpinCount(world, data)
                if data.round == 3 then
                    if spin_count < 1 then
                        local achievement_tracker = _G.TheWorld.components.achievement_tracker
                        achievement_tracker:UpdateAchievementProgress(achievement_name, player.userid, true)
                        world:RemoveEventCallback("spawningfinished", CheckSnortoiseProgress)
                    end
                    world:RemoveEventCallback("round_complete", CheckSpinCount)
                end
            end
            world:ListenForEvent("round_complete", CheckSpinCount)
        elseif lavaarenaevent.current_round > 3 then
            world:RemoveEventCallback("spawningfinished", CheckSnortoiseProgress)
        end
    end
    _G.TheWorld:ListenForEvent("spawningfinished", CheckSnortoiseProgress)
end
local snortoise_gold_icon = {atlas = "images/rf_achievements.xml", tex = "ach_snortoise_gold.tex"}
AddAchievement("snortoise_gold", IsNonSpectator, SnortoiseGoldTrack, nil, nil, snortoise_gold_req, SetLevelXP(1), 2, snortoise_gold_icon, mob_id, "DEFAULT")
-------------------
-- Basic Solution --
-------------------
local no_deaths_acid_req = {
    gametypes = {"forge"},
    wavesets  = {"boarilla", "boarillas", "classic", "rhinocebros", "swineclops"},
}
-- This function is nearly identical to the silver version, but are separate to prevent any conflict of removing event listeners.
local function ScorpeonAcidTrack(achievement_tracker, player, achievement_name, server_progress, client_progress)
    local function CheckAcidProgress(world, data)
        local lavaarenaevent = _G.TheWorld.components.lavaarenaevent
        if lavaarenaevent.current_round == 4 then
            local acid_death = false
            local function CheckAcidDeath(world, data)
                if data.inst.userid and data.cause == "poison_dot" then
                    acid_death = true
                    world:RemoveEventCallback("entity_death", CheckAcidDeath)
                end
            end
            world:ListenForEvent("entity_death", CheckAcidDeath)
            local function CheckAcidDeaths(world, data)
                if data.wave >= 2 then
                    if not acid_death then
                        local achievement_tracker = _G.TheWorld.components.achievement_tracker
                        achievement_tracker:UpdateAchievementProgress(achievement_name, player.userid, true)
                    end
                    world:RemoveEventCallback("new_wave", CheckAcidDeaths)
                end
            end
            world:ListenForEvent("new_wave", CheckAcidDeaths)
        elseif lavaarenaevent.current_round > 4 then
            world:RemoveEventCallback("spawningfinished", CheckAcidProgress)
        end
    end
    _G.TheWorld:ListenForEvent("spawningfinished", CheckAcidProgress)
end
local no_deaths_acid_icon = {atlas = "images/rf_achievements.xml", tex = "ach_scorpeon.tex"}
AddAchievement("no_deaths_acid", IsNonSpectator, ScorpeonAcidTrack, nil, nil, no_deaths_acid_req, SetLevelXP(1), 2, no_deaths_acid_icon, mob_id, "DEFAULT")
--------------------
-- Boarilla Basher -- TODO make new event for whenever any mob spawns
--------------------
local solo_boarilla_req = {
    gametypes = {"forge"},
    wavesets  = {"boarilla", "boarillas", "classic", "rhinocebros", "swineclops"},
}
-- This function is nearly identical to the silver version, but are separate to prevent any conflict of removing event listeners.
local function SoloBoarillaTrack(achievement_tracker, player, achievement_name, server_progress, client_progress)
    local boarilla_tracker = {}
    local boarilla_fns = {}
    boarilla_fns.BoarillaOnDeath = function (inst, data)
        if boarilla_tracker[inst] and data.afflicter == player then
            boarilla_tracker[inst] = nil
            local achievement_tracker = _G.TheWorld.components.achievement_tracker
            achievement_tracker:UpdateAchievementProgress(achievement_name, player.userid, true)
            -- Remove tracking of all currently tacked boarillas
            for boarilla,_ in pairs(boarilla_tracker) do
                boarilla:RemoveEventCallback("attacked", boarilla_fns.TrackBoarillaDamageTaken)
                boarilla:RemoveEventCallback("death", boarilla_fns.BoarillaOnDeath)
            end
            _G.TheWorld:RemoveEventCallback("on_spawned_mob", boarilla_fns.IsBoarilla)
        end
    end
    boarilla_fns.TrackBoarillaDamageTaken = function (inst, data)
        if data.attacker ~= player then
            boarilla_tracker[inst] = nil
            inst:RemoveEventCallback("attacked", boarilla_fns.TrackBoarillaDamageTaken)
            inst:RemoveEventCallback("death", boarilla_fns.BoarillaOnDeath)
        end
    end
    boarilla_fns.IsBoarilla = function(world, data)
        local boarilla = data.mob
        if boarilla.prefab == "boarilla" then
            boarilla_tracker[boarilla] = true
            boarilla:ListenForEvent("attacked", boarilla_fns.TrackBoarillaDamageTaken)
            boarilla:ListenForEvent("death", boarilla_fns.BoarillaOnDeath)
        end
    end
    _G.TheWorld:ListenForEvent("on_spawned_mob", boarilla_fns.IsBoarilla)
end
local solo_boarilla_icon = {atlas = "images/rf_achievements.xml", tex = "ach_boarilla_defeat.tex"}
AddAchievement("solo_boarilla", IsNonSpectator, SoloBoarillaTrack, nil, nil, solo_boarilla_req, SetLevelXP(0.75), 2, solo_boarilla_icon, mob_id, "DEFAULT")
--------------------------------------------------------------------------
-- Character Chemistry
--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Any
--------------------------------------------------------------------------
local player_id = "player"
------------
-- %&*@#! --
------------
local function CCBreakerMatchComplete(lavaarenaevent, userid, achievement_name)
    local stat_tracker = _G.TheWorld.components.stat_tracker
    local cc_broken = stat_tracker:GetStatTotal("ccbroken", userid)
    if cc_broken >= 100 then
        local achievement_tracker = _G.TheWorld.components.achievement_tracker
        achievement_tracker:UpdateAchievementProgress(achievement_name, userid, true)
    end
end
local cc_breaker_icon = {atlas = "images/rf_achievements.xml", tex = "ach_hammer.tex"}
AddAchievement("cc_breaker", IsNonSpectator, nil, CCBreakerMatchComplete, nil, nil, SetLevelXP(0.33), 1, cc_breaker_icon, player_id, "DEFAULT")
--------------------------------------------------------------------------
-- Stats
--------------------------------------------------------------------------
local kills_req = {
}
local function KillsMatchComplete(lavaarenaevent, userid, achievement_name, total_revives)
    local stat_tracker = _G.TheWorld.components.stat_tracker
    local kills = stat_tracker:GetStatTotal("kills", userid)
	local achievement_tracker = _G.TheWorld.components.achievement_tracker
	achievement_tracker:UpdateAchievementProgress(achievement_name, userid, nil, kills)
end
local kills_bronze_icon = {atlas = "images/rf_achievements.xml", tex = "ach_kills_bronze.tex"}
AddAchievement("kills_bronze", IsNonSpectator, nil, KillsMatchComplete, 100, nil, SetLevelXP(1), 1, kills_bronze_icon, player_id, "DEFAULT")

local kills_silver_icon = {atlas = "images/rf_achievements.xml", tex = "ach_kills_silver.tex"}
AddAchievement("kills_silver", IsNonSpectator, nil, KillsMatchComplete, 1000, nil, SetLevelXP(5), 3, kills_silver_icon, player_id, "DEFAULT")

local kills_gold_icon = {atlas = "images/rf_achievements.xml", tex = "ach_kills_gold.tex"}
AddAchievement("kills_gold", IsNonSpectator, nil, KillsMatchComplete, 10000, nil, SetLevelXP(10), 4, kills_gold_icon, player_id, "DEFAULT")
--------------------------------------------------------------------------
-- Wilson
--------------------------------------------------------------------------
local wilson_id = "wilson"
local wilson_req = {
    characters = {"wilson"},
}
local function ReviveMatchComplete(lavaarenaevent, userid, achievement_name, total_revives)
    local stat_tracker = _G.TheWorld.components.stat_tracker
    local revives = stat_tracker:GetStatTotal("corpsesrevived", userid)
    if revives >= total_revives then
        local achievement_tracker = _G.TheWorld.components.achievement_tracker
        achievement_tracker:UpdateAchievementProgress(achievement_name, userid, true)
    end
end
---------------------
-- Revive A Friend --
---------------------
local function ReviveBronzeMatchComplete(lavaarenaevent, userid, achievement_name)
    ReviveMatchComplete(lavaarenaevent, userid, achievement_name, 1)
end
local revive_bronze_icon = {atlas = "images/rf_achievements.xml", tex = "ach_revive.tex"}
--AddAchievement("revive_bronze", IsNonSpectator, nil, ReviveBronzeMatchComplete, nil, wilson_req, SetLevelXP(0.33), 1, revive_bronze_icon, wilson_id, "DEFAULT")
---------------------
-- Revive A Friend --
---------------------
local function ReviveSilverMatchComplete(lavaarenaevent, userid, achievement_name)
    ReviveMatchComplete(lavaarenaevent, userid, achievement_name, 10)
end
local revive_silver_icon = {atlas = "images/rf_achievements.xml", tex = "ach_reviver_silver.tex"}
--AddAchievement("revive_silver", IsNonSpectator, nil, ReviveSilverMatchComplete, nil, wilson_req, SetLevelXP(0.45), 1, revive_silver_icon, wilson_id, "DEFAULT")
---------------------
-- Revive A Friend --
---------------------
local function ReviveGoldMatchComplete(lavaarenaevent, userid, achievement_name)
    ReviveMatchComplete(lavaarenaevent, userid, achievement_name, 20)
end
local revive_gold_icon = {atlas = "images/rf_achievements.xml", tex = "ach_reviver_gold.tex"}
--AddAchievement("revive_gold", IsNonSpectator, nil, ReviveGoldMatchComplete, nil, wilson_req, SetLevelXP(1), 2, revive_gold_icon, wilson_id, "DEFAULT")
---------------
-- Jump Save --
---------------
local function TeleportTrack(achievement_tracker, player, achievement_name, server_progress, client_progress)
    local function UpdateTeleportCount(inst, data)
        if data.weapon and data.weapon.prefab == "" then
            achievement_tracker:UpdateAchievementProgress(achievement_name, userid, nil, 1)
            if achievement_tracker:IsAchievementUnlocked(achievement_name, player.userid, true) and achievement_tracker:IsAchievementUnlocked(achievement_name, player.userid) then
                player:RemoveEventCallback("spell_complete", UpdateTeleportCount)
            end
        end
    end
    player:ListenForEvent("spell_complete", UpdateTeleportCount)
end
local function TeleportOnMatchComplete(lavaarenaevent, userid, achievement_name)
    local achievement_tracker = _G.TheWorld.components.achievement_tracker
    achievement_tracker:UpdateAchievementProgress(achievement_name, userid, nil, nil, 0)
end
local teleport_silver_icon = {atlas = "images/rf_achievements.xml", tex = "ach_teleport_staff.tex"}
--AddAchievement("teleport_silver", IsNonSpectator, TeleportTrack, TeleportOnMatchComplete, 1, wilson_req, SetLevelXP(0.33), 1, teleport_silver_icon, wilson_id, "DEFAULT")
-----------------
-- Jump Clutch --
-----------------
local teleport_gold_icon = {atlas = "images/rf_achievements.xml", tex = "ach_teleport_staff.tex"}
--AddAchievement("teleport_gold", IsNonSpectator, TeleportTrack, TeleportOnMatchComplete, 10, wilson_req, SetLevelXP(0.75), 1, teleport_gold_icon, wilson_id, "DEFAULT")
-----------------
-- Wilson Tank --
-----------------
local function WilsonTankTrack(achievement_tracker, player, achievement_name, server_progress, client_progress)
    local function CheckSwineParry(inst, data)
        if inst.sg:HasStateTag("parrying") and data.attacker and data.attacker.prefab == "swineclops" then
            achievement_tracker:UpdateAchievementProgress(achievement_name, userid, true)
            player:RemoveEventCallback("attacked", CheckSwineParry)
        end
    end
    player:ListenForEvent("attacked", CheckSwineParry)
end
local wilson_tank_icon = {atlas = "images/rf_achievements.xml", tex = "ach_blacksmithedge.tex"}
--AddAchievement("wilson_tank", IsNonSpectator, WilsonTankTrack, nil, nil, wilson_req, SetLevelXP(0.5), 1, wilson_tank_icon, wilson_id, "DEFAULT")
-------------------------
-- Standard Deviations -- TODO
-------------------------
--[[]]
local function WilsonHealerMatchComplete(lavaarenaevent, userid, achievement_name)
    local stat_tracker = _G.TheWorld.components.stat_tracker
    local healing_dealt = stat_tracker:GetStatTotal("healingdone", userid)
    if healing_dealt >= 20000 then
        local achievement_tracker = _G.TheWorld.components.achievement_tracker
        achievement_tracker:UpdateAchievementProgress(achievement_name, userid, true)
    end
end
local wilson_healer_icon = {atlas = "images/rf_achievements.xml", tex = "ach_heals.tex"}
--AddAchievement("wilson_healer", IsNonSpectator, nil, WilsonHealerMatchComplete, nil, wilson_req, 1000, 1, wilson_healer_icon, wilson_id, "DEFAULT")
----------------------
-- ReForged Victory --
----------------------
local wilson_swineclops_req = {
    characters = {"wilson"},
    wavesets   = {"swineclops"},
}
local wilson_swineclops_icon = {atlas = "images/rf_achievements.xml", tex = "ach_wilson.tex"}
--AddAchievement("wilson_swineclops", IsNonSpectator, nil, VictoryOnMatchComplete, nil, wilson_swineclops_req, SetLevelXP(1), 2, wilson_swineclops_icon, wilson_id, "DEFAULT")
--------------------------------------------------------------------------
-- Willow
--------------------------------------------------------------------------
local willow_id = "willow"
--[[local willow_req = {
    characters = {"willow"},
}
local function ReviveMatchComplete(lavaarenaevent, userid, achievement_name, total_revives)
    local stat_tracker = _G.TheWorld.components.stat_tracker
    local revives = stat_tracker:GetStatTotal("corpsesrevived", userid)
    if revives >= total_revives then
        local achievement_tracker = _G.TheWorld.components.achievement_tracker
        achievement_tracker:UpdateAchievementProgress(achievement_name, userid, true)
    end
end
---------------------
-- Bernie The Tank --
---------------------
local function ReviveBronzeMatchComplete(lavaarenaevent, userid, achievement_name)
    ReviveMatchComplete(lavaarenaevent, userid, achievement_name, 1)
end
local revive_bronze_icon = {atlas = "images/rf_achievements.xml", tex = "ach_revive.tex"}
AddAchievement("revive_bronze", IsNonSpectator, nil, ReviveBronzeMatchComplete, nil, wilson_req, 1000, 1, revive_bronze_icon, willow_id, "DEFAULT")
------------------
-- Taunt Master --
------------------
local function ReviveSilverMatchComplete(lavaarenaevent, userid, achievement_name)
    ReviveMatchComplete(lavaarenaevent, userid, achievement_name, 10)
end
local revive_silver_icon = {atlas = "images/rf_achievements.xml", tex = "ach_reviver_silver.tex"}
AddAchievement("revive_silver", IsNonSpectator, nil, ReviveSilverMatchComplete, nil, wilson_req, 1000, 1, revive_silver_icon, willow_id, "DEFAULT")
-----------------
-- Taunt Fiend --
-----------------
local function ReviveGoldMatchComplete(lavaarenaevent, userid, achievement_name)
    ReviveMatchComplete(lavaarenaevent, userid, achievement_name, 20)
end
local revive_gold_icon = {atlas = "images/rf_achievements.xml", tex = "ach_reviver_gold.tex"}
AddAchievement("revive_gold", IsNonSpectator, nil, ReviveGoldMatchComplete, nil, wilson_req, 1000, 1, revive_gold_icon, willow_id, "DEFAULT")
-------------------
-- Heat Stricken --
-------------------
local function TeleportTrack(achievement_tracker, player, achievement_name, server_progress, client_progress)
    local function UpdateTeleportCount(inst, data)
        if data.weapon and data.weapon.prefab == "" then
            achievement_tracker:UpdateAchievementProgress(achievement_name, userid, nil, 1)
            if achievement_tracker:IsAchievementUnlocked(achievement_name, player.userid, true) and achievement_tracker:IsAchievementUnlocked(achievement_name, player.userid) then
                player:RemoveEventCallback("spell_complete", UpdateTeleportCount)
            end
        end
    end
    player:ListenForEvent("spell_complete", UpdateTeleportCount)
end
local teleport_silver_icon = {atlas = "images/rf_achievements.xml", tex = "ach_teleport_staff.tex"}
AddAchievement("teleport_silver", IsNonSpectator, TeleportTrack, nil, 1, wilson_req, 1000, 1, teleport_silver_icon, willow_id, "DEFAULT")
--------------------------
-- This Girl Is On Fire --
--------------------------
local teleport_gold_icon = {atlas = "images/rf_achievements.xml", tex = "ach_teleport_staff.tex"}
AddAchievement("teleport_gold", IsNonSpectator, TeleportTrack, nil, 10, wilson_req, 1000, 1, teleport_gold_icon, willow_id, "DEFAULT")
-------------------
-- Roasted Rhino --
-------------------
local function WilsonTankTrack(achievement_tracker, player, achievement_name, server_progress, client_progress)
    local function CheckSwineParry(inst, data)
        if inst.sg:HasStateTag("parrying") and data.attacker and data.attacker.prefab == "swineclops" then
            achievement_tracker:UpdateAchievementProgress(achievement_name, userid, true)
            player:RemoveEventCallback("attacked", CheckSwineParry)
        end
    end
    player:ListenForEvent("attacked", CheckSwineParry)
end
local wilson_tank_icon = {atlas = "images/rf_achievements.xml", tex = "ach_blacksmithedge.tex"}
AddAchievement("wilson_tank", IsNonSpectator, WilsonTankTrack, nil, nil, wilson_req, 1000, 1, wilson_tank_icon, willow_id, "DEFAULT")
------------------
-- Ring Of Fire --
------------------
local function WilsonHealerMatchComplete(lavaarenaevent, userid, achievement_name)
    local stat_tracker = _G.TheWorld.components.stat_tracker
    local healing_dealt = stat_tracker:GetStatTotal("healingdone", userid)
    if healing_dealt >= 20000 then
        local achievement_tracker = _G.TheWorld.components.achievement_tracker
        achievement_tracker:UpdateAchievementProgress(achievement_name, userid, true)
    end
end
local wilson_healer_icon = {atlas = "images/rf_achievements.xml", tex = "ach_heals.tex"}
AddAchievement("wilson_healer", IsNonSpectator, nil, WilsonHealerMatchComplete, nil, wilson_req, 1000, 1, wilson_healer_icon, willow_id, "DEFAULT")
----------------------
-- ReForged Victory --
----------------------
local willow_swineclops_req = {
    characters = {"willow"},
    wavesets   = {"swineclops"},
}
local willow_swineclops_icon = {atlas = "images/rf_achievements.xml", tex = "ach_not_the_sequel_we_deserve.tex"}
AddAchievement("willow_swineclops", IsNonSpectator, nil, VictoryOnMatchComplete, nil, willow_swineclops_req, 1000, 1, willow_swineclops_icon, willow_id, "DEFAULT")--]]
--------------------------------------------------------------------------
-- Wolfgang
--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Wendy
--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- WX-78
--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Wickerbottom
--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Woodie
--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Wes
--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Maxwell
--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Wigfrid
--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Webber
--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Winona
--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Warly
--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Wortox
--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Wormwood
--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Wurt
--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Walter
--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Wanda
--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Random
--------------------------------------------------------------------------

--[[
swineclops_reforged
swineclops_hard
dt_normal_6
dt_hard
dt_normal
tt_normal_6
tt_hard
tt_normal
quad_normal
quin_normal
ten_normal
insanity
titans
rlgl_normal
rlglolbl_normal
rlgl_hard
rlglolbl_hard
rlgl_no_deaths
rlglolbl_no_deaths
endless
no_revives
no_hud
no_sleep
friendly_fire
no_friendly_fire
no_damage
no_damage_double
low_team_damage
no_team_deaths_boarilla
no_team_deaths_boarrior
no_deaths_swineclops
no_team_deaths_swineclops
unique_team
random_team_6_no_deaths
random_team_no_deaths
team_5_swinelcops
team_4_swinelcops
team_3_swinelcops
team_2_swinelcops
bronze_speed_run
silver_speed_run
gold_speed_run
plat_speed_run
double_bronze_speed_run
double_silver_speed_run
double_gold_speed_run
double_plat_speed_run
pitpig_silver
pitpig_gold
croc
snortoise_silver
snortoise_gold
no_deaths_acid
cc_breaker
revive_bronze
revive_silver
revive_gold
teleport_silver
teleport_gold
wilson_tank
wilson_swineclops
--]]
