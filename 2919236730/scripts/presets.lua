local RF_DATA = _G.REFORGED_DATA
RF_DATA.presets = {}
function AddPreset(name, mode, difficulty, gametype, waveset, map, mutators, icon, order_priority)
    if RF_DATA.presets[name] then
        _G.Debug:Print("Attempted to add the preset '" .. tostring(name) .. "', but it already exists.", "error")
        return
    elseif mode and RF_DATA.modes[mode] == nil then
        _G.Debug:Print("Attempted to add the preset '" .. tostring(name) .. "', but the mode '" .. tostring(mode) .. "' does not exist.", "error")
        return
    elseif gametype and RF_DATA.gametypes[gametype] == nil then
        _G.Debug:Print("Attempted to add the preset '" .. tostring(name) .. "', but the gametype '" .. tostring(gametype) .. "' does not exist.", "error")
        return
    elseif waveset and RF_DATA.wavesets[waveset] == nil then
        _G.Debug:Print("Attempted to add the preset '" .. tostring(name) .. "', but the waveset '" .. tostring(waveset) .. "' does not exist.", "error")
        return
    elseif map and RF_DATA.maps[map] == nil then
        _G.Debug:Print("Attempted to add the preset '" .. tostring(name) .. "', but the map '" .. tostring(map) .. "' does not exist.", "error")
        return
    elseif waveset and map and RF_DATA.wavesets[waveset].spawners > RF_DATA.maps[map].spawners then
        _G.Debug:Print("Attempted to add the preset '" .. tostring(name) .. "', but the map '" .. tostring(map) .. "' does not have enough spawners for the waveset '" .. tostring(waveset) .. "'.", "error")
        return
    end
    RF_DATA.presets[name] = {
        name           = name,
        mutators       = mutators or {},
        mode           = mode or "reforged",
        difficulty     = difficulty or "normal",
        gametype       = gametype or "forge",
        waveset        = waveset or "swineclops",
        map            = map or "lavaarena",
        icon           = icon,
        order_priority = order_priority or 999,
    }
end
_G.AddPreset = AddPreset
AddPreset("forge_season_1", "forge_s01", nil, "forge", "classic", "lavaarena", nil, {atlas = "images/reforged.xml", tex = "preset_s1.tex",}, 1)
AddPreset("forge_season_2", "forge_s02", nil, "forge", "swineclops", "lavaarena", nil, {atlas = "images/reforged.xml", tex = "preset_s2.tex",}, 2)
AddPreset("half_the_wrath", "reforged", nil, "forge", "swineclops", "lavaarena", {mob_duplicator = 0.5, mob_damage_dealt = 0.5, mob_health = 0.5, mob_speed = 1.2, mob_size = 0.9}, {atlas = "images/reforged.xml", tex = "preset_s1.tex",}, 3)
AddPreset("double_trouble", "reforged", nil, "forge", "swineclops", "lavaarena", {mob_duplicator = 2}, {atlas = "images/reforged.xml", tex = "preset_s1.tex",}, 4)
AddPreset("triple_threat", "reforged", nil, "forge", "swineclops", "lavaarena", {mob_duplicator = 3}, {atlas = "images/reforged.xml", tex = "preset_s1.tex",}, 5)
AddPreset("quintuple_struggle", "reforged", nil, "forge", "swineclops", "lavaarena", {mob_duplicator = 5}, {atlas = "images/reforged.xml", tex = "preset_s1.tex",}, 6)
AddPreset("tenfold_terror", "reforged", nil, "forge", "swineclops", "lavaarena", {mob_duplicator = 10}, {atlas = "images/reforged.xml", tex = "preset_s1.tex",}, 7)
AddPreset("fast_but_weak", "reforged", nil, "forge", "swineclops", "lavaarena", {mob_damage_dealt = 0.75, mob_health = 0.75, mob_speed = 3, mob_attack_rate = 0.5}, {atlas = "images/reforged.xml", tex = "preset_s1.tex",}, 8)
--AddPreset("x2", "reforged", nil, "forge", "swineclops", "lavaarena", {mob_damage_dealt = 2, mob_health = 2, mob_speed = 2, battlestandard_efficiency = 2}, {atlas = "images/reforged.xml", tex = "preset_s1.tex",}, 9)
--AddPreset("x3", "reforged", nil, "forge", "swineclops", "lavaarena", {mob_damage_dealt = 3, mob_health = 3, mob_speed = 3, battlestandard_efficiency = 3}, {atlas = "images/reforged.xml", tex = "preset_s1.tex",}, 10)
AddPreset("half", "reforged", nil, "forge", "swineclops", "lavaarena", {mob_damage_dealt = 0.5, mob_health = 0.5, mob_speed = 0.5, battlestandard_efficiency = 0.5}, {atlas = "images/reforged.xml", tex = "preset_s1.tex",}, 11)
AddPreset("mutated", "reforged", nil, "forge", "swineclops", "lavaarena", {no_sleep = true, no_revives = true, no_hud = true, friendly_fire = true}, {atlas = "images/reforged.xml", tex = "preset_s1.tex",}, 12)
--AddPreset("double_doom", "reforged", nil, "forge", "double_trouble", "lavaarena", {no_revives = true, friendly_fire = true}, {atlas = "images/reforged.xml", tex = "preset_s1.tex",}, 13)
AddPreset("chaotic", "reforged", nil, "rlgl", "classic", "lavaarena", {no_revives = true, friendly_fire = true}, {atlas = "images/reforged.xml", tex = "preset_s1.tex",}, 14)
AddPreset("coffee", "reforged", nil, "forge", "swineclops", "lavaarena", {mob_speed = 2, no_sleep = true}, {atlas = "images/reforged.xml", tex = "preset_s1.tex",}, 15)
--AddPreset("double_half", "reforged", nil, "forge", "double_trouble", "lavaarena", {mob_health = 0.5, mob_damage_dealt = 0.5}, {atlas = "images/reforged.xml", tex = "preset_s1.tex",}, 16)
--AddPreset("half_double", "reforged", nil, "forge", "half_the_wrath", "lavaarena", {mob_health = 2, mob_damage_dealt = 2}, {atlas = "images/reforged.xml", tex = "preset_s1.tex",}, 17)
AddPreset("attack_of_titans", "reforged", nil, "forge", "swineclops", "lavaarena", {mob_damage_dealt = 2, mob_health = 1.5, mob_size = 1.5}, {atlas = "images/reforged.xml", tex = "preset_titans.tex",}, 18)
AddPreset("insanity", "reforged", nil, "forge", "swineclops", "lavaarena", {mob_damage_dealt = 3, mob_health = 3, mob_speed = 3, mob_defense = 3, battlestandard_efficiency = 3, no_sleep = true, no_revives = true, no_hud = true, friendly_fire = true}, {atlas = "images/reforged.xml", tex = "preset_insane.tex",}, 50)
AddPreset("custom", nil, nil, nil, nil, nil, nil, nil, 0)
