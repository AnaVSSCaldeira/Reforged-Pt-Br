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
Summary
Rounds/Waves
    5 Rounds
    Random number of waves, max number of 5
    Random chance for a timer that queues the next wave. (Does not occur on the final wave of a round)
    Random chance for a health trigger that queues the next wave. (Does not occur on the final wave of a round)
        Only higher tier mobs can have health triggers.
        Only one specific type of enemy will have the health triggers for any given wave.
            ex. All boarillas will have the trigger OR all rhinocebros will have the trigger.
Mobs
    All mobs have their own weight. Each round/wave have their own total weight value and will add mobs to the wave until total weight is reached.
    Distributed randomly over all spawners.
    Random chance for a valid commander to have minions. (Low tier mobs near it will be attached.)
Items
    Same as mobs.
    Random heal item spawns randomly during round 1.
    Character specific item drops are part of the item pool regardless if the character is present.
    Starting items can drop.
    Armor, Helm, and Weapons each have their own separate weight so that a mix of items will drop and not just all one type.

Normal Waveset for reference:
Round 1
    Wave 1
        Mobs - Pitpig (3) 1*3 = 3
    Wave 2
        Mobs  - Pitpig (6) 1*6 = 6
        Items - Barbed Helm
    Wave 3
        Mobs  - Pitpig (9) 1*9 = 9
        Items - Living Staff, Crytal Tiara
    Wave 4
        Mobs  - Pitpig (12) 1*12 = 12
        Items - Jagged Armor
    Item Summary
        3 Armor (2 Helm + 1 Armor) + 1 Heal
Round 2:
    Wave 1
        Mobs  - Pitpig (6) + Crocommander (2) 1*6 + 4*2 = 14
        Items - Silken Armor, Firebomb
    Wave 2
        Mobs  - Pitpig (6) + Crocommander (2) 1*6 + 4*2 = 14
        Items - Molten Darts, Feathered Wreath, Splintmail, Whispering Grand Armor
    Item Summary
        4 Armor + 2 Weapons
Round 3:
    Wave 1
        Mobs  - Snortoise (7) 3*7 = 21
        Items - Nox Helm, Silken Grand Armor, Steadfast Armor, Infernal Staff, Flower Headband
    Item Summary
        4 Armor (2 Helm + 2 Armor) + 1 Weapons
Round 4:
    Wave 1
        Mobs  - Scorpeon (7) 5*7 = 35
        Items - Woven Garland, Jagged Grand Armor
    Wave 2
        Mobs  - Snortoise (2) + Scorpeon (2) 3*2 + 5*2 = 16
        Items - Steadfast Grand Armor, Clairvoyant Crown, Golem, Blacksmith's Edge, Molten Darts
    Wave 3
        Mobs - Boarilla (1) [15 seconds after previous wave or death] 10*1 = 10
    Item Summary
        4 Armor (2 Helm + 2 Armor) + 3 Weapons
Round 5:
    Wave 1
        Mobs - Boarilla (2) 10*2 = 20
    Wave 2
        Mobs  - Pitpig (2) + Crocommander (1) [when first Boarilla hits 40% health or when cumulative Boarilla health hits 120%] 2*2 + 4*1 = 8
        Items - Resplendent Nox Helm
    Wave 3
        Mobs - Pitpig (2) + Crocommander (1) + Snortoise (2) + Scorpeon (2) [when first Boarilla dies or when cumulative Boarilla health hits 40%] 2*2 + 4*1 + 3*2 + 5*2 = 24
    Wave 4
        Mobs    - Boarrior (1) [when cumulative Boarilla health hits 20%] 20*1 = 20
        Special - Pitpig (12) [when Boarrior hits half health]
        Items   - Jagged Grand Armor, Silken Grand Armor, Blossomed Wreath
    Item Summary
        4 Armor (2 Helm + 2 Armor)
Round 6:
    Wave 1
        Mobs - Rhinocebro (2) 10*2 = 20
Round 7:
    Wave 1
        Mobs - Swineclops (1) 30*1 = 30
--]]

-----------
-- SETUP --
-----------
local _W = _G.UTIL.WAVESET
local DIALOGUE = "REFORGED.FORGELORD_DIALOGUE.RANDOMIZED"

local max_rounds = 5
local max_waves = 5
local weight_limits = {
    [1] = {mob = {min = 3, max= 15, total = 25},   item = {armor = 2, helms = 2, weapons = 0},},
    [2] = {mob = {min = 6, max= 20, total = 50},   item = {armor = 8, helms = 0, weapons = 4},},
    [3] = {mob = {min = 9, max= 25, total = 75},   item = {armor = 7, helms = 4, weapons = 3},},
    [4] = {mob = {min = 12, max= 30, total = 100}, item = {armor = 8, helms = 5, weapons = 7},},
    [5] = {mob = {min = 15, max= 40, total = 150}, item = {armor = 8, helms = 6, weapons = 0},},
}
local min_weight_per_wave = 5
local round_weight = {}
for round=1,max_rounds do
    local round_weight_limit = weight_limits[round]
    local min_waves = math.ceil(round_weight_limit.mob.total/round_weight_limit.mob.max)
    local total_waves = min_waves > max_waves and min_waves or math.random(min_waves, max_waves)
    -- Generate Mob Weight
    local mob_weight_per_wave = {}
    local total_mob_weight_left = round_weight_limit.mob.total
    for wave=1,total_waves do
        if wave == total_waves then
            table.insert(mob_weight_per_wave, total_mob_weight_left)
        else
            local mob_weight = math.random(round_weight_limit.mob.min, math.min(round_weight_limit.mob.max, total_mob_weight_left - round_weight_limit.mob.min*(total_waves - wave)))
            total_mob_weight_left = total_mob_weight_left - mob_weight
            table.insert(mob_weight_per_wave, mob_weight)
        end
    end

    -- Sort weights from lowest to highest so later waves have more weight
    table.sort(mob_weight_per_wave, function(a,b)
        return a < b
    end)

    -- Set Round Weight
    local current_round_weight = {}
    for wave=1,total_waves do
        table.insert(current_round_weight, {mob = mob_weight_per_wave[wave]})
    end
    table.insert(round_weight, current_round_weight)
end

---------------
-- SPAWN FNS --
---------------
local function GetValidEnts(type, total_weight, max_ent_weight, ents)
    local valid_ents = ents or {}
    local max_ent_weight = max_ent_weight or total_weight
    -- Generate new valid ents
    if not ents then
        for mod_id,prefabs in pairs(AllForgePrefabs[type]) do
            for name,prefab in pairs(prefabs) do
                local tuning = TUNING[mod_id][string.upper(name)]
                local weight = tuning and tuning.WEIGHT or 1
                if weight <= math.min(total_weight, max_ent_weight) and not (type == "WEAPONS" and tuning and (tuning.IS_HEAL or tuning.IS_STARTING_ITEM)) and not (tuning and tuning.WIP) then
					--print("Adding "..name.." to Randomizer")
                    table.insert(valid_ents, {prefab = prefab, weight = weight})
                end
            end
        end
        -- Sort valid ents by weight
        table.sort(valid_ents, function(a,b)
            return a.weight < b.weight
        end)
    -- Only regenerate valid ents if the last ent in given ents has a higher weight than the total weight
    elseif ents and ents[#ents].weight > total_weight then
        for i=#valid_ents,1,-1 do
            if valid_ents[i].weight > total_weight then
                table.remove(valid_ents)
            else
                break
            end
        end
    end
    return valid_ents
end
local function GenerateEnts(type, total_weight, max_ent_weight, valid_ents, ents)
    local ents = ents or {}
    -- No more weight
    if total_weight <= 0 then
        return ents
    -- Randomly get another ent
    else
        local valid_ents = GetValidEnts(type, total_weight, max_ent_weight, valid_ents)
        local ent = valid_ents[math.random(#valid_ents)]
        ents[ent.prefab] = (ents[ent.prefab] or 0) + 1
        return GenerateEnts(type, total_weight - ent.weight, max_ent_weight, valid_ents, ents)
    end
end
--[[
TODO
should distance and rotation be random as well for the preset?
--]]
local function GenerateSpawns(mobs)
    -- Split mobs between the spawners
    local spawners = {}
    for prefab,count in pairs(mobs) do
        for i=1,count do
            table.insert(EnsureTable(spawners, math.random(#TheWorld.spawners)), prefab.name)
        end
    end

    -- Set Spawn
    local spawns = {}
    for spawner,mob_data in pairs(spawners) do
        local current_mobs = _W.CreateMobList(mob_data)
        local preset = _W.CreateMobSpawnFromPreset("random", current_mobs)
        table.insert(spawns, {_W.CreateSpawn(preset), {spawner}})
    end
    return _W.SetSpawn(unpack(spawns))
end

-------------------
-- ITEM DROP FNS --
-------------------
-- Returns a list of the item types that none of the selected characters can use.
local function GetRestrictedItemTypes()
    local restricted_item_types = {}
    for _,player in pairs(_G.AllPlayers) do
        local restrictions = player.components.itemtyperestrictions.restrictions
        if #restricted_item_types <= 0 then
            restricted_item_types = _G.deepcopy(restrictions)
        else
            for type,val in pairs(restricted_item_types) do
                if not restrictions[type] or not val then
                    restricted_item_types[type] = nil
                end
            end
        end
    end
    return restricted_item_types
end

-- Returns valid healing items, if no healing items are valid then returns any healing item.
local heal_round = 1
local function GetRandomHealingItem()
    local heal_items = {}
    local valid_heal_items = {}
    local restricted_item_types = GetRestrictedItemTypes()
    for mod_id,prefabs in pairs(AllForgePrefabs.WEAPONS) do
        for name,prefab in pairs(prefabs) do
            local tuning = TUNING[mod_id][string.upper(name)]
            if tuning and tuning.IS_HEAL and not tuning.WIP then
                local is_invalid = false
                for _,type in pairs(type(tuning.ITEM_TYPE) == "table" and tuning.ITEM_TYPE or {tuning.ITEM_TYPE}) do
                    is_invalid = is_invalid or restricted_item_types[type]
                end
                if not is_invalid then
                    table.insert(valid_heal_items, prefab)
                end
                table.insert(heal_items, prefab)
            end
        end
    end
    heal_items = #valid_heal_items > 0 and valid_heal_items or heal_items
    return {[heal_items[math.random(#heal_items)]] = 1}
end
local item_types = {"armor", "helms", "weapons"}
local drop_types = {"random_mob","final_mob","round_end"}
local function GenerateItemDrops(item_drops, item_type, total_weight, waves, final_round, is_heal)
    local items = is_heal and GetRandomHealingItem() or GenerateEnts(string.upper(item_type), total_weight)
    for prefab,count in pairs(items) do
        for i=1,count do
            local drop_type = drop_types[math.random(#drop_types - (final_round and 1 or 0))]
            table.insert(drop_type == "round_end" and EnsureTable(item_drops, drop_type) or EnsureTable(item_drops, math.random(waves - (final_round and 1 or 0)), drop_type), prefab.name)
        end
    end
end

----------------
-- CUSTOM FNS --
----------------
local function IsWaveMutatorActive(odds) -- TODO name?
    return math.random(odds.total) <= odds.val
end

local odds = {
    commander = {total = 2, val = 1},
    health    = {total = 1, val = 1},
    timer     = {total = 100, val = 1},
}
local max_weight_triggers = {
    commander = 5,
    minion = 2
}
local timer_mult = 6 -- seconds per mob weight
local function OnSpawningFinished(self, spawned_mobs) -- TODO need to pass more data through to this function?
    local total_weight = 0
    local commanders = {}
    local minions = {}
    local mob_count = {} -- for non duped mobs only
    local health_mobs = {}
    local health_link = {}
    local duplicated_mobs = {}
    for spawner,mob_list in pairs(spawned_mobs or {}) do
        for mob,_ in pairs(mob_list) do
            local prefab = mob.prefab
            local mob_weight = TUNING.FORGE[string.upper(mob.prefab)] and TUNING.FORGE[string.upper(mob.prefab)].WEIGHT or 1
            total_weight = total_weight + mob_weight

            -- Only high tier mobs can be part of a health trigger
            if mob_weight > max_weight_triggers.commander then -- TODO should this be based on weight or health of mob?
                if not health_mobs[prefab] then
                    health_mobs[prefab] = {}
                    table.insert(health_link, prefab)
                end
                table.insert(health_mobs[prefab], mob)
            -- Only mid tier mobs can be a commander
            elseif mob_weight > max_weight_triggers.minion and mob.components.leader then -- TODO should this be based on weight? should all mobs have leader component?
                table.insert(commanders, mob)
            -- Only low tier mobs can be minions
            else
                table.insert(minions, mob) -- TODO should this be based on weight?
            end

            -- Variations
            if mob.duplicator_source and mob.SetVariation then
                table.insert(duplicated_mobs, mob)
            else
                mob_count[prefab] = (mob_count[prefab] or 0) + 1
                if mob.SetVariation then
                    mob:SetVariation(mob_count[prefab])
                end
            end
        end
    end

    -- Commanders
    if #commanders > 0 and #minions > 0 and IsWaveMutatorActive(odds.commander) then
        -- Randomly give commanders minions
        for _,minion in pairs(minions) do
            _W.LeashMobs(commanders[math.random(#commanders)], {minion})
        end
    end

    -- Health Triggers
    local health_string = tostring(self.current_round) .. "_" .. tostring(self.current_wave)
    if #self.current_round_data.waves ~= self.current_wave and #health_link > 0 and IsWaveMutatorActive(odds.health) then
        local health_prefab = health_link[math.random(#health_link)]
        local health_trigger_mobs = health_mobs[health_prefab]
        local total_percent = 0.6 * #health_trigger_mobs
        local intro_percent = (1 - total_percent)*0.75 + total_percent   --= 0.75 - 0.75*total_percent + total_percent = 0.75 + 0.25*total_percent = 0.25(3 + total_percent)
        local warning_percent = (1 - total_percent)*0.25 + total_percent --= 0.25 - 0.25*total_percent + total_percent = 0.25 + 0.75*total_percent = 0.25(1 + 3*total_percent)
        local str_par = SerializeTable({"NAMES." .. tostring(string.upper(health_trigger_mobs[1].nameoverride or health_prefab))})
        self.health_triggers[health_string] = {
            [1] = {total_percent = intro_percent,   all_percent = 0.9, fn = function() -- Intro
                self:DoSpeech(DIALOGUE .. ".HEALTH_INTRO_BANTER", nil, true, nil, nil, str_par)
            end},
            [2] = {total_percent = warning_percent, all_percent = 0.65, fn = function() -- Warning
                self:DoSpeech(DIALOGUE .. ".HEALTH_WARNING_BANTER", nil, true, nil, nil, str_par)
            end},
            [3] = {total_percent = total_percent,   all_percent = 0.4, fn = function()
                self:QueueWave(self.current_wave + 1)
            end},
        }
        _W.AddHealthTriggers(self.health_triggers[health_string], unpack(health_trigger_mobs))
    end

    -- Wave Timers
    -- Remove any timers to queue next wave
    RemoveTask(self.timers.queue_next_wave)
    if #self.waveset_data[self.current_round].waves > self.current_wave and IsWaveMutatorActive(odds.timer) then
        local total_time = total_weight * timer_mult
        -- Intro Timer
        self.timers.queue_next_wave = self.inst:DoTaskInTime(total_time * 0.1, function()
            self:DoSpeech(DIALOGUE .. ".TIME_INTRO_BANTER", nil, true)
            -- Warning Timer
            self.timers.queue_next_wave = self.inst:DoTaskInTime(total_time * 0.45, function()
                self:DoSpeech(DIALOGUE .. ".TIME_WARNING_BANTER", nil, true)
                -- Next Wave Timer
                self.timers.queue_next_wave = self.inst:DoTaskInTime(total_time * 0.45, function()
                    -- Remove health trigger for given wave
                    if self.health_triggers[health_string] then
                        self.health_triggers[health_string] = nil
                    end
                    self:QueueWave(self.current_wave + 1)
                end)
            end)
        end)
    end
end

------------------
-- WAVESET DATA --
------------------
local waveset_data = {
    item_drops = {},
    endgame_speech = {
        victory = {
            speech = "BOARLORD_ROUND7_PLAYER_VICTORY",
        },
        defeat = {
            speech = "BOARLORD_PLAYERS_DEFEATED_BATTLECRY",
        },
    }
}

for round,waves in pairs(round_weight) do
    waveset_data[round] = {
        waves = {},
        wavemanager = {
            dialogue = {
                [1]      = {pred_delay = 0, speech = DIALOGUE .. ".ROUND_" .. tostring(round) .. "_START"},
                [#waves] = {pre_delay = 0, speech = DIALOGUE .. ".ROUND_" .. tostring(round) .. "_FINAL_BANTER", is_banter = true},
            },
            onspawningfinished = {}
        }
    }
    waveset_data.item_drops[round] = {}
    -- Generate Mob Spawns
    for wave,weight in pairs(waves) do
        table.insert(waveset_data[round].waves, GenerateSpawns(GenerateEnts("ENEMIES", weight.mob)))
        waveset_data[round].wavemanager.onspawningfinished[wave] = OnSpawningFinished
    end
    -- Generate Item Drops
    for _,type in pairs(item_types) do
        GenerateItemDrops(waveset_data.item_drops[round], type, weight_limits[round].item[type], #waves, #round_weight == round)
    end
    -- Generate Healing Item
    if round == 1 then
        GenerateItemDrops(waveset_data.item_drops[round], nil, nil, #waves, nil, true)
    end
end

return waveset_data
