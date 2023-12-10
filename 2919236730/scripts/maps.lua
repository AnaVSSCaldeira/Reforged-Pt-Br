local RF_DATA = _G.REFORGED_DATA
RF_DATA.maps = {}
function AddMap(name, level_id, spawners, icon, minimap, order_priority)
    if RF_DATA.maps[name] then
        _G.Debug:Print("Attempted to add the map '" .. tostring(name) .."', but it already exists.", "error")
        return
    elseif level_id == nil then
        _G.Debug:Print("Attempted to add the map '" .. tostring(name) .."', but no level_id assigned.", "error")
        return
    end
    RF_DATA.maps[name] = {
        level_id = level_id,
        spawners = spawners or 3,
        icon     = icon or {atlas = "images/reforged.xml", tex = "map_unknown.tex"},    -- {atlas = ".xml", tex = ".tex"}
        minimap  = minimap or {atlas = "images/maps.xml", tex = "map_unknown.tex"}, -- {atlas = ".xml", tex = ".tex"}
        order_priority = order_priority or 999,
        reset = true,
    }
end
_G.AddMap = AddMap
local GroundTiles = require "worldtiledefs"
----------------
-- Lava Arena --
----------------
local icon = {atlas = "images/reforged.xml", tex = "map_forge.tex"}
local minimap = {atlas = "images/maps.xml", tex = "map_forge.tex"}

if _G.rawget(_G, "FORGE_DBG") then
    AddMap("reforged_tiles_arena", "REFORGEDTILES", 3, nil, nil, 0) -- TODO highest or lowest priority?
end
AddMap("lavaarena", "LAVAARENA", 3, icon, minimap, 1) -- TODO level id for default?
--str = "Volcanic Arena" -- TODO remove when done testing
--AddMap("lavaarena_test", "TESTING", 3) -- TODO remove when done testing
