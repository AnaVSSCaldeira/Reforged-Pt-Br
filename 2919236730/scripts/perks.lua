local RF_DATA = _G.REFORGED_DATA
local UserCommands = require "usercommands"
RF_DATA.perks = {}
function AddPerk(character_prefab, name, fn, overrides, icon, order_priority)
    local perk_tbl = _G.EnsureTable(RF_DATA.perks, character_prefab)
    if perk_tbl[name] then
        _G.Debug:Print("Attempted to add the perk '" .. tostring(name) .."', but it already exists.", "error")
        return
    end
    local overrides = overrides or {}
    perk_tbl[name] = {
        fn = fn,
        overrides = {
            difficulty = overrides.difficulty, -- number value between 1 and 3
            health     = overrides.health,     -- number value
            inventory  = overrides.inventory,  -- table of prefabs, ex. {"forginghammer", "forge_woodarmor"}
            companions = overrides.companions, -- table of prefabs, ex. {"bernie"}
            portrait   = overrides.portrait,   -- {atlas = "bigportraits/example.xml", tex = "example.tex"}
        },
        icon           = icon or {atlas = "images/reforged.xml", tex = "p_unknown.tex"},
        order_priority = order_priority or 999,
    }
end
_G.AddPerk = AddPerk
-------------
-- Generic --
-------------
local function tank_fn(inst)
    inst.components.itemtyperestrictions:SetRestrictions({"darts", "staves", "books"})
end
local tank_overrides = {
    difficulty = 1,
    health     = 200,
    inventory  = {"forginghammer", "forge_woodarmor"},
}
local tank_icon = {atlas = "images/reforged.xml", tex = "p_def_tank.tex"}
AddPerk("generic", "tank", tank_fn, tank_overrides, tank_icon, 0)
local function dps_fn(inst)
    inst.components.itemtyperestrictions:SetRestrictions({"melees", "books"})
end
local dps_overrides = {
    difficulty = 2,
    health     = 150,
    inventory  = {"forgedarts", "featheredtunic"},
}
local dps_icon = {atlas = "images/reforged.xml", tex = "p_def_darts.tex"}
AddPerk("generic", "dps", dps_fn, dps_overrides, dps_icon, 0)
local function support_fn(inst)
    inst.components.itemtyperestrictions:SetRestrictions({"darts", "melees"})
end
local support_overrides = {
    difficulty = 3,
    health     = 125,
    inventory  = {"petrifyingtome", "reedtunic"},
}
local support_icon = {atlas = "images/reforged.xml", tex = "p_def_support.tex"}
AddPerk("generic", "support", support_fn, support_overrides, support_icon, 0)
---------------
-- Spectator --
---------------
local spectator_overrides = {
    difficulty = 0,
}
local spectator_icon = {atlas = "images/reforged.xml", tex = "p_unknown.tex"}
AddPerk("spectator", "spy", nil, spectator_overrides, spectator_icon, 0)
------------
-- Random -- TODO random tank? random support? random dps? How would you determine the role of a modded character?
------------ true random? random character, random perk, random starting items? Everything random and not specific to a character
-- NOTE: The fn for "random" gets the list of all valid playable characters (except for spectator) and expects a character string to be returned
-- If no character string is returned it will default to a random character.
local function GetRandomPerk(char)
    local perks = {}
    for name,_ in pairs(_G.REFORGED_DATA.perks[char] or _G.REFORGED_DATA.perks.generic or {}) do
        table.insert(perks, name)
    end
    return perks[math.random(#perks)]
end
local function full_random_fn(valid_characters)
    local char = valid_characters[math.random(#valid_characters)]
    local caller = _G.TheNet:GetClientTableForUser(_G.TheNet:GetUserID())
    if caller then
        UserCommands.RunUserCommand("updateuserscurrentperk", {current_perk = GetRandomPerk(char), original_perk = "full_random"}, caller)
    end
    return char
end
local full_random_icon = {atlas = "images/reforged.xml", tex = "p_full_random.tex"}
AddPerk("random", "full_random", full_random_fn, nil, full_random_icon, 0)
local original_perks = {
    wilson       = "revive",
    willow       = "bernie",
    wendy        = "abigail",
    wolfgang     = "mighty",
    wx78         = "shock",
    wickerbottom = "amplify",
    wes          = "aggro",
    waxwell      = "shadows",
    woodie       = "lucy",
    wathgrithr   = "battlecry",
    webber       = "baby_spiders",
    winona       = "cooldown",
    wortox       = "soul_drain",
    wormwood     = "bloom",
    warly        = "spices",
    wurt         = "wet",
    walter       = "woby",
}
local function base_random_fn(valid_characters)
    local char = valid_characters[math.random(#valid_characters)]
    UserCommands.RunUserCommand("updateuserscurrentperk", {current_perk = original_perks[char] or GetRandomPerk(char), original_perk = "base_random"}, _G.TheNet:GetClientTableForUser(_G.TheNet:GetUserID()))
    return char
end
local base_random_icon = {atlas = "images/reforged.xml", tex = "p_random.tex"}
AddPerk("random", "base_random", base_random_fn, nil, base_random_icon, 0)

------------
-- Wilson --
------------
local function revive_fn(inst)
    inst:AddComponent("corpsereviver")
    inst.components.corpsereviver:SetReviverSpeedMult(TUNING.FORGE.WILSON.BONUS_REVIVE_SPEED_MULTIPLIER)
    inst.components.corpsereviver:SetAdditionalReviveHealthPercent(TUNING.FORGE.WILSON.BONUS_HEALTH_ON_REVIVE_PERCENT)
    --inst.components.corpsereviver:SetReviveHealthPercentMult(TUNING.FORGE.WILSON.BONUS_HEALTH_ON_REVIVE_MULT)
end
local def_icon = {atlas = "images/reforged.xml", tex = "forge_icon.tex"}
local icon = {atlas = "images/reforged.xml", tex = "forge_icon.tex"}
AddPerk("wilson", "revive", revive_fn, nil, def_icon, 0)

------------
-- Willow --
------------

local function bernie_fn(inst)
    --inst.components.combat:AddDamageBuff("passive_explosive", {buff = 1.1, stimuli = "explosive"})
    --inst.components.combat:AddDamageBuff("passive_fire", {buff = 1.1, stimuli = "fire"})

    --Spawn Bernie
    inst:AddTag("bernie_reviver")
    local function SpawnBernie(inst)
        if inst.components.petleash.numpets == 0 then
            inst.components.petleash.petprefab = "forge_bernie"
            local pos = inst:GetPosition()
            local bernie = inst.components.petleash:SpawnPetAt(pos.x + math.random(-3, 3), 0, pos.z + math.random(-3, 3))
        end
        inst:RemoveEventCallback("player_portal_spawn", SpawnBernie)
    end
    inst:ListenForEvent("player_portal_spawn", SpawnBernie)
end
local icon = {atlas = "images/reforged.xml", tex = "unknown_icon.tex"}
AddPerk("willow", "bernie", bernie_fn, nil, def_icon, 0)
--------------------------------------------------------------------------
local function fire_fn(inst)
	inst.components.combat:AddDamageBuff("passive_explosive", {buff = 1.1, stimuli = "explosive"})
    inst.components.combat:AddDamageBuff("passive_fire", {buff = 1.1, stimuli = "fire"})
	inst.reforged_items = {[1] = {"infernalstaff"}}
end
local icon = {atlas = "images/reforged.xml", tex = "unknown_icon.tex"}
AddPerk("willow", "fire", fire_fn, nil, def_icon, 0)

-----------
-- Wendy --
-----------
local function abigail_fn(inst)
    --Spawn Abigail
    inst.components.petleash.maxpets = 2 --needed to be 2 to allow transitions between flower stage and ghost stage. TODO is this true?
    local function SpawnAbigail(inst)
        if not inst.abigail and inst.components.petleash.numpets == 0 then
            inst.components.petleash.petprefab = "forge_abigail"
            local pos = inst:GetPosition()
            local abigail = inst.components.petleash:SpawnPetAt(pos.x + math.random(-3, 3), 0, pos.z + math.random(-3, 3))
        end
        inst:RemoveEventCallback("player_portal_spawn", SpawnAbigail)
    end
    inst:ListenForEvent("player_portal_spawn", SpawnAbigail)
end
local icon = {atlas = "images/reforged.xml", tex = "unknown_icon.tex"}
AddPerk("wendy", "abigail", abigail_fn, nil, def_icon, 0)
--------------------------------------------------------------------------
local function baby_ben_fn(inst)
    --Spawn Baby Ben
    inst.components.petleash.maxpets = 1
    local function SpawnBabyBen(inst)
        if inst.components.petleash.numpets == 0 then
            inst.components.petleash.petprefab = "baby_ben"
            local pos = inst:GetPosition()
            local baby_ben = inst.components.petleash:SpawnPetAt(pos.x + math.random(-3, 3), 0, pos.z + math.random(-3, 3))
        end
        inst:RemoveEventCallback("player_portal_spawn", SpawnBabyBen)
    end
    inst:ListenForEvent("player_portal_spawn", SpawnBabyBen)
end
local icon = {atlas = "images/reforged.xml", tex = "p_wendy_daycare.tex"}
AddPerk("wendy", "baby_ben", baby_ben_fn, nil, icon, 1)
--------------
-- Wolfgang --
--------------

local function mighty_fn(inst)
    inst:AddComponent("passive_mighty")
end
local icon = {atlas = "images/reforged.xml", tex = "unknown_icon.tex"}
AddPerk("wolfgang", "mighty", mighty_fn, nil, def_icon, 0)
--------------------------------------------------------------------------
local function restore_fn(inst)
    inst.components.health:StartRegen(1, 2)
    inst:ListenForEvent("healthdelta", OnHealthDelta)
end

local icon = {atlas = "images/reforged.xml", tex = "unknown_icon.tex"}
AddPerk("wolfgang", "restore", restore_fn, nil, def_icon, 0)

------------
-- WX-78 --
------------
local function shock_fn(inst)
    inst.components.combat:AddDamageBuff("passive_electric", {buff = 1.5, stimuli = "electric"})
    inst:AddComponent("passive_shock")
	inst.components.health:AddHealthBuff(inst.prefab, 25, "flat")
end
local icon = {atlas = "images/reforged.xml", tex = "unknown_icon.tex"}
AddPerk("wx78", "shock", shock_fn, nil, def_icon, 0)
--------------------------------------------------------------------------
local function overcharge_fn(inst)
    inst.components.combat:AddDamageBuff("passive_electric", {buff = 0.5, stimuli = "electric"}, true)
	inst.components.revivablecorpse:SetReviveSpeedMult(0.8)
    inst:AddComponent("passive_overcharge")
end
local icon = {atlas = "images/reforged.xml", tex = "unknown_icon.tex"}
AddPerk("wx78", "overcharge", overcharge_fn, nil, def_icon, 1)

------------------
-- Wickerbottom --
------------------
local function amplify_fn(inst)
    inst:AddComponent("passive_amplify")
end
local icon = {atlas = "images/reforged.xml", tex = "forge_icon.tex"}
AddPerk("wickerbottom", "amplify", amplify_fn, nil, def_icon, 0)
-------------------------------------------------------------------------------
local function bookers_fn(inst)
	inst.components.buffable:AddBuff("rewind", {{name = "spell_duration", val = 1.40, type = "mult"}})
    inst.reforged_items = {[1] = {"bacontome"}}
	inst:AddComponent("corpsereviver")
	inst.components.corpsereviver:SetReviverSpeedMult(0.75)
	inst.components.itemtyperestrictions:SetRestrictions({"melees", "darts", "staves"})
end
local icon = {atlas = "images/reforged.xml", tex = "forge_icon.tex"}
AddPerk("wickerbottom", "bookers", bookers_fn, nil, def_icon, 1)

---------
-- Wes --
---------
local function aggro_fn(inst, name)
    --Revived twice as fast with half health buff
	inst.components.locomotor:SetExternalSpeedMultiplier(inst, "tankers", 1.1)
    inst.components.revivablecorpse:SetReviveSpeedMult(0.5)
    inst.components.buffable:AddBuff(name .. "_passive", {
        {name = "aggro_timer", val = TUNING.FORGE.WES.AGGRO_TIMER_MULT, type = "mult"},
        {name = "aggro_gain", val = TUNING.FORGE.WES.AGGRO_GAIN_MULT, type = "mult"}
    })
end
local icon = {atlas = "images/reforged.xml", tex = "unknown_icon.tex"}
AddPerk("wes", "aggro", aggro_fn, nil, def_icon, 0)

-------------
-- Maxwell --
-------------
local function shadows_fn(inst)
    inst:AddComponent("passive_shadows")
	inst.components.combat:AddDamageBuff("magedmgbuff", {buff = 1.10, damagetype = 2 }, false) --O damagetype = 2 (Magia)
end
local icon = {atlas = "images/reforged.xml", tex = "unknown_icon.tex"}
AddPerk("waxwell", "shadows", shadows_fn, nil, def_icon, 0)
---------------------------------------------------------------------------------------------
local function granmage_fn(inst)
    inst.components.combat:AddDamageBuff("magedmgbuff", {buff = 0.75}, false)
	inst.components.buffable:AddBuff("coldown_passive", {{name = "cooldown", val = -0.1, type = "add"}})
	inst.components.buffable:AddBuff("rewind", {{name = "spell_duration", val = 1.10, type = "mult"}})
	inst.components.buffable:AddBuff("heal_dealt", {{name = "heal_dealt", val = 1.10, type = "mult"}})
end
local icon = {atlas = "images/reforged.xml", tex = "unknown_icon.tex"}
AddPerk("waxwell", "granmage", granmage_fn, nil, def_icon, 0)

------------
-- Woodie --
------------
local function lucy_fn(inst) -- TODO ???
end
local icon = {atlas = "images/reforged.xml", tex = "unknown_icon.tex"}
AddPerk("woodie", "lucy", lucy_fn, nil, def_icon, 0)

-------------
-- Wigfrid --
-------------
local function battlecry_fn(inst, name)
    inst:AddComponent("passive_battlecry")
    inst.components.buffable:AddBuff(name .. "_passive", {
        {name = "aggro_gain", val = TUNING.FORGE.WATHGRITHR.AGGRO_GAIN_MULT, type = "mult"}
    })
    inst.reforged_items = {[3] = {"spiralspear"}} -- TODO should this be in the perk?
end
local icon = {atlas = "images/reforged.xml", tex = "unknown_icon.tex"}
AddPerk("wathgrithr", "battlecry", battlecry_fn, nil, def_icon, 0)

------------
-- Webber --
------------
local function NoHoles(pt)
    return not _G.TheWorld.Map:IsGroundTargetBlocked(pt)
end
local function baby_spiders_fn(inst)
    -- Spawn Baby Spiders
	inst.components.itemtyperestrictions:SetRestrictions({"melle", "staves", "books"})
    local max_baby_spiders = TUNING.FORGE.WEBBER.BABY_SPIDER_AMOUNT or 1
    inst.components.petleash.maxpets = max_baby_spiders
    inst.components.petleash.petprefab = "babyspider"
    local function SpawnBabySpiders(inst)
        for i = 1, max_baby_spiders do
            local theta = (i / max_baby_spiders) * 2 * _G.PI--math.random() * 2 * _G.PI
            local pt = inst:GetPosition()
            local radius = 1--math.random(3, 6) -- TODO constant radius
            local offset = _G.FindWalkableOffset(pt, theta, radius, 3, true, true, NoHoles) or {x = 0, y = 0, z = 0}
            local pet = inst.components.petleash:SpawnPetAt(pt.x + offset.x, 0, pt.z + offset.z)
        end
        inst:RemoveEventCallback("player_portal_spawn", SpawnBabySpiders)
    end
    inst:ListenForEvent("player_portal_spawn", SpawnBabySpiders)
	inst.components.itemtyperestrictions:SetRestrictions({"melees", "staves", "books"})
end
local icon = {atlas = "images/reforged.xml", tex = "unknown_icon.tex"}
AddPerk("webber", "baby_spiders", baby_spiders_fn, nil, def_icon, 0)
---------------------------------------------------------------------------
local function tankers_fn(inst, name)
	inst.components.health:AddHealthBuff(inst.prefab, 50, "flat")
	inst.components.locomotor:SetExternalSpeedMultiplier(inst, "tankers", 1.1)
	inst.components.itemtyperestrictions:SetRestrictions({"staves", "books"})
end
local icon = {atlas = "images/reforged.xml", tex = "unknown_icon.tex"}
AddPerk("webber", "tankers", tankers_fn, nil, def_icon, 0)

------------
-- Winona --
------------
local function cooldown_fn(inst, name)
    inst.components.buffable:AddBuff(name .. "_passive", {{name = "cooldown", val = -0.1, type = "add"}})
end
local icon = {atlas = "images/reforged.xml", tex = "unknown_icon.tex"}
AddPerk("winona", "cooldown", cooldown_fn, nil, def_icon, 0)

------------
-- Wortox --
------------
local function soul_drain_fn(inst)
    inst:AddComponent("passive_soul_drain")
    inst.reforged_items = {[2] = {"lavaarena_gauntlet"}}
end
local icon = {atlas = "images/reforged.xml", tex = "unknown_icon.tex"}
AddPerk("wortox", "soul_drain", soul_drain_fn, nil, def_icon, 0)

--------------
-- Wormwood --
--------------
local function bloom_fn(inst)
    inst:AddComponent("passive_bloom")
    inst.reforged_items = {[2] = {"lavaarena_seeddart2"}}
end
local icon = {atlas = "images/reforged.xml", tex = "unknown_icon.tex"}
AddPerk("wormwood", "bloom", bloom_fn, nil, def_icon, 0)

-----------
-- Warly --
-----------
local function spices_fn(inst, name)
    inst.components.buffable:AddBuff("heal_dealt", {{name = "heal_dealt", val = 1.20, type = "mult"}})
    inst.reforged_items = {["heal"] = {"spice_bomb"}}
end
local icon = {atlas = "images/reforged.xml", tex = "unknown_icon.tex"}
AddPerk("warly", "spices", spices_fn, nil, def_icon, 0)
--------------------------------------------------------------------------
local function cookpot_fn(inst, name)
    local tuning_values = TUNING.FORGE.WARLY
    inst.components.buffable:AddBuff(name .. "_passive", {
        {name = "cook_duration", val = tuning_values.COOK_DURATION_MULT, type = "mult"},
        {name = "food_duration", val = tuning_values.FOOD_DURATION_MULT, type = "mult"},
        {name = "food_damage",   val = tuning_values.FOOD_DAMAGE_MULT,   type = "mult"},
        {name = "food_defense",  val = tuning_values.FOOD_DEFENSE_MULT,  type = "mult"},
        {name = "food_regen",    val = tuning_values.FOOD_REGEN_MULT,    type = "mult"}
    })
    --inst.components.buffable:AddBuff("heal_dealt", {{name = "heal_dealt", val = 1.1, type = "mult"}}) -- TODO should this still be here?
    inst.reforged_items = {[1] = {"lavaarena_spatula"}, [2] = {"lavaarena_chefhat"}}
end
local icon = {atlas = "images/reforged.xml", tex = "p_warly_masterchef.tex"}
AddPerk("warly", "cookpot", cookpot_fn, nil, icon, 0)
----------
-- Wurt --
----------
local function wet_fn(inst)
    inst.reforged_items = {[2] = {"forge_trident"}}
    -- Target takes more damage from electric attacks and moves slightly slower
    local function ApplyWetDebuff(inst)
        if inst.components.debuffable then
            inst.components.debuffable:AddDebuff("debuff_wet", "debuff_wet")
        end
    end
    -- All attacks besides projeciles apply wet debuff
    inst:ListenForEvent("onhitother", function(inst, data)
        if data.target and not data.projectile then
            ApplyWetDebuff(data.target)
        end
    end)
    inst:ListenForEvent("attacked", function(inst, data)
        if data.attacker and not data.projectile then
            ApplyWetDebuff(data.attacker)
        end
    end)
end
local icon = {atlas = "images/reforged.xml", tex = "unknown_icon.tex"}
AddPerk("wurt", "wet", wet_fn, nil, def_icon, 0)
------------
-- Walter --
------------
local function woby_fn(inst)
    inst.components.petleash.maxpets = 1
    inst.components.petleash.petprefab = "forge_woby"
    local function SpawnWoby(inst)
        for i = 1, inst.components.petleash.maxpets do
            local theta = (i / inst.components.petleash.maxpets) * 2 * _G.PI--math.random() * 2 * _G.PI
            local pt = inst:GetPosition()
            local radius = 1--math.random(3, 6) -- TODO constant radius
            local offset = _G.FindWalkableOffset(pt, theta, radius, 3, true, true, NoHoles) or {x = 0, y = 0, z = 0}
            local pet = inst.components.petleash:SpawnPetAt(pt.x + offset.x, 0, pt.z + offset.z)
        end
        inst:RemoveEventCallback("player_portal_spawn", SpawnWoby)
    end
    inst:ListenForEvent("player_portal_spawn", SpawnWoby)
    inst.reforged_items = {[2] = {"forge_slingshot"}}
end
local icon = {atlas = "images/reforged.xml", tex = "unknown_icon.tex"}
AddPerk("walter", "woby", woby_fn, nil, def_icon, 0)
-----------
-- Wanda --
-----------
local function rewind_fn(inst)
    local function OnRevive(inst)
        local clock_fx = _G.SpawnPrefab("pocketwatch_ground_fx")
        clock_fx.Transform:SetPosition(inst:GetPosition():Get())
        inst.components.revivablecorpse:Revive(inst)
        inst.free_rez_cooldown = inst:DoTaskInTime(60, function()
            inst.components.revivablecorpse:AddCharge(inst, nil, OnRevive, 1)
            inst.free_rez_cooldown = nil
        end)
    end
    inst.components.revivablecorpse:AddCharge(inst, nil, OnRevive, 1)
    inst.components.buffable:AddBuff("rewind", {{name = "spell_duration", val = 1.1, type = "mult"}})
    inst.reforged_items = {[2] = {"pocketwatch_reforged"}}
end
local rewind_overrides = {
    difficulty = 1,
}
local icon = {atlas = "images/reforged.xml", tex = "unknown_icon.tex"}
AddPerk("wanda", "rewind", rewind_fn, rewind_overrides, def_icon, 0)
--------------------------------------------------------------------------
local function PlayAgingFx(inst, fx_name)
    if inst.components.rider ~= nil and inst.components.rider:IsRiding() then
        fx_name = fx_name .. "_mount"
    end

    local fx = _G.SpawnPrefab(fx_name) -- TODO should use createfx instead for scaling purposes?
    fx.entity:SetParent(inst.entity)
end

local function UpdateSkinMode(inst, mode, delay)
    if inst.queued_skinmode_task ~= nil then
        inst.updateskinmodetask:Cancel()
        inst.updateskinmodetask = nil
    end

    if delay then
        if inst.queued_skinmode ~= nil then
            inst.components.skinner:SetSkinMode(inst.queued_skinmode, "wilson")
        end
        inst.queued_skinmode = mode
        inst.updateskinmodetask = inst:DoTaskInTime(15*_G.FRAMES, UpdateSkinMode, mode)
    else
        inst.components.skinner:SetSkinMode(mode, "wilson")
        inst.queued_skinmode = nil
    end
end

local age_info = {
    young = {
        skin = "young_skin",
        event = "becomeyounger_wanda",
        sound = "younger_transition",
        talk_sound = "talk_young_LP",
        talker = "ANNOUNCE_WANDA_NORMALTOYOUNG",
        fx = {
            "oldager_become_younger_front_fx",
            "oldager_become_younger_back_fx",
        },
    },
    normal = {
        young = {
            skin = "normal_skin",
            event = "becomeolder_wanda",
            sound = "older_transition",
            talker = "ANNOUNCE_WANDA_YOUNGTONORMAL",
            fx = {
                "oldager_become_older_fx",
            },
        },
        old = {
            skin = "normal_skin",
            event = "becomeyounger_wanda",
            sound = "younger_transition",
            talker = "ANNOUNCE_WANDA_OLDTONORMAL",
            fx = {
                "oldager_become_younger_front_fx",
                "oldager_become_younger_back_fx",
            },
        },
    },
    old = {
        skin = "old_skin",
        event = "becomeolder_wanda",
        sound = "older_transition",
        talk_sound = "talk_old_LP",
        talker = "ANNOUNCE_WANDA_NORMALTOOLD",
        fx = {
            "oldager_become_older_fx",
        },
    },
}
local function AdjustAge(inst, age, silent)
    if inst.age_state == age then return end

    local current_info = age_info[age]
    current_info = age == "normal" and current_info[inst.age_state] or current_info
    inst.overrideskinmode = current_info.skin
    if not inst.sg:HasStateTag("ghostbuild") then
        UpdateSkinMode(inst, current_info.skin, not silent)
    end

    if not silent then
        inst.components.talker:Say(_G.GetString(inst, current_info.talker))
        inst.sg:PushEvent(current_info.event)
        inst.SoundEmitter:PlaySound("wanda2/characters/wanda/" .. current_info.sound)
        for _,fx in pairs(current_info.fx) do
            PlayAgingFx(inst, fx)
        end
    end

    inst.talksoundoverride = current_info.talk_sound and "wanda2/characters/wanda/" .. tostring(current_info.talk_sound) or nil
    inst.age_state = age
end

local AGE_THRESHOLDS = {0.33, 0.67, 1}
local AGES = {"old", "normal", "young"}
local function OnHealthDelta(inst, data, forcesilent)
    if inst.sg:HasStateTag("nomorph") or inst:HasTag("playerghost") or inst.components.health:IsDead() then return end

    local silent = inst.sg:HasStateTag("silentmorph") or not inst.entity:IsVisible() or forcesilent
    local health = inst.components.health ~= nil and inst.components.health:GetPercent() or 0

    for i,percent in pairs(AGE_THRESHOLDS) do
        if health <= percent then
            AdjustAge(inst, AGES[i], silent)
            break
        end
    end
end
--------------------------------------------------------------------------
local function age_fn(inst)
    inst.components.combat:AddDamageBuff("age_perk", {buff = function(attacker, victim, weapon, stimuli)
        local buff = (1 - inst.components.health:GetPercent()) / 2 -- 0.5 percent damage increase per health percent lost.
        return buff + 1
    end}, false)
    inst.components.health:StartRegen(-0.5, 2)
    inst:ListenForEvent("healthdelta", OnHealthDelta)
    inst.reforged_items = {[2] = {"portalstaff"}}
    inst.age_state = "young"
end
local age_overrides = {
    difficulty = 3,
}
local icon = {atlas = "images/reforged.xml", tex = "p_wanda_dps.tex"}
AddPerk("wanda", "age", age_fn, age_overrides, icon, 1)
