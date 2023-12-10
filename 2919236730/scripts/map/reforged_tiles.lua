--setfenv(1, _G.WM.env)
local _G = GLOBAL
local require = _G.require
--local TileManager = require("tilemanager")

local run_sound_loc = "dontstarve/movement/run_"
local walk_sound_loc = "dontstarve/movement/walk_"
local sounds = {
    carpet = "carpet", -- walk/run
    dirt   = "dirt",   -- walk/run
    grass  = "grass",  -- walk/run
    ice    = "ice",    -- run
    marble = "marble", -- walk/run
    marsh  = "marsh",  -- walk/run
    meteor = "meteor", -- run
    moss   = "moss",   -- run
    mud    = "mud",    -- run
    pebblebeach = "pebblebeach", -- run
    rock        = "marble",      -- walk/run TODO rock
    sand        = "dirt",        -- walk/run TODO sand
    snow        = "snow",         -- run
    tallgrass   = "tallgrass",   -- walk/run
    wood        = "wood",        -- walk/run
    woods       = "woods",       -- walk/run
}
local function GetSoundLoc(sound, is_walk)
    return (is_walk and walk_sound_loc or run_sound_loc) .. sounds[sound]
end
local texture_loc = "levels/textures/"
local function GetTextureLoc(name)
    return texture_loc .. name .. ".tex"
end
local land_tiles = {
    {
        id    = "PVP",
        name  = "pvp",
        specs = {
            name          = "cave",
            noise_texture = "noise_pvp",
            flooring      = true,
            hard          = true,
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "mini_noise_pvp",
        },
    },
    -----------------
    -- Shipwrecked --
    -----------------
    {
        id    = "BEACH",
        name  = "beach",
        specs = {
            name          = "beach",
            noise_texture = "ground_noise_sand",
            runsound      = GetSoundLoc("sand"),
            walksound     = GetSoundLoc("sand", true),
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "mini_beach_noise",
        },
    },{
        id    = "JUNGLE",
        name  = "jungle",
        specs = {
            name          = "jungle",
            noise_texture = "ground_noise_jungle",
            runsound      = GetSoundLoc("woods"),
            walksound     = GetSoundLoc("woods", true),
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "mini_jungle_noise",
        },
    },{
        id    = "SWAMP",
        name  = "swamp",
        specs = {
            name          = "swamp",
            noise_texture = "ground_noise_swamp",
            runsound  = GetSoundLoc("marsh"),
            walksound = GetSoundLoc("marsh", true),
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "mini_swamp_noise",
        },
    },{
        id    = "MAGMAFIELD",
        name  = "magmafield",
        specs = {
            name          = "cave",
            noise_texture = "ground_noise_magmafield",
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "mini_magmafield_noise",
        },
    },{
        id    = "TIDALMARSH",
        name  = "tidalmarsh",
        specs = {
            name          = "tidalmarsh",
            noise_texture = "ground_noise_tidalmarsh",
            runsound      = GetSoundLoc("marsh"),
            walksound     = GetSoundLoc("marsh", true),
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "mini_tidalmarsh_noise",
        },
    },{
        id    = "MEADOW",
        name  = "meadow",
        specs = {
            name          = "jungle",
            noise_texture = "ground_noise_savannah_detail",
            runsound      = GetSoundLoc("tallgrass"),
            walksound     = GetSoundLoc("tallgrass", true),
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "mini_savannah_noise",
        },
    },{
        id    = "VOLCANO",
        name  = "volcano",
        specs = {
            name          = "cave",
            noise_texture = "ground_lava_rock",
            runsound      = GetSoundLoc("rock"),
            walksound     = GetSoundLoc("rock", true),
            hard          = true,
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "mini_ground_lava_rock",
        },
    },{
        id    = "ASH",
        name  = "ash",
        specs = {
            name          = "cave",
            noise_texture = "ground_ash",
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "mini_ash",
        },
    },{
        id    = "VOLCANO_ROCK",
        name  = "volcano_rock",
        specs = {
            name          = "rocky",
            noise_texture = "ground_volcano_noise",
            runsound      = GetSoundLoc("rock"),
            walksound     = GetSoundLoc("rock", true),
            hard          = true,
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "mini_ground_volcano_noise",
        },
    },{
        id    = "SNAKESKIN",
        name  = "snakeskin",
        specs = {
            name          = "carpet",
            noise_texture = "noise_snakeskinfloor",
            runsound      = GetSoundLoc("carpet"),
            walksound     = GetSoundLoc("carpet", true),
            flooring      = true,
            hard          = true,
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "noise_snakeskinfloor",
        },
    },

    ------------
    -- Hamlet --
    ------------
    {
        id    = "DEEPRAINFOREST",
        name  = "deep_rain_forest",
        specs = {
            name          = "jungle_deep",
            noise_texture = "ground_noise_jungle_deep",
            runsound      = GetSoundLoc("woods"),
            walksound     = GetSoundLoc("woods", true),
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "mini_noise_jungle_deep",
        },
    },{
        id    = "FOUNDATION",
        name  = "foundation",
        specs = {
            name          = "blocky",
            noise_texture = "noise_ruinsbrick_scaled",
            runsound      = GetSoundLoc("grass"),
            walksound     = GetSoundLoc("grass", true),
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "mini_ruinsbrick_noise",
        },
    },{
        id    = "COBBLEROAD",
        name  = "cobbleroad",
        specs = {
            name          = "stoneroad",
            noise_texture = "ground_noise_cobbleroad",
            runsound      = GetSoundLoc("rock"),
            walksound     = GetSoundLoc("rock", true),
            flooring      = true,
            hard          = true,
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "noise_snakeskinfloor",
        },
    },{
        id    = "LAWN",
        name  = "lawn",
        specs = {
            name          = "pebble",
            noise_texture = "ground_noise_checkeredlawn",
            runsound      = GetSoundLoc("grass"),
            walksound     = GetSoundLoc("grass", true),
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "mini_checker_noise",
        },
    },{
        id    = "GASJUNGLE",
        name  = "gas_jungle",
        specs = {
            name          = "jungle_deep",
            noise_texture = "ground_noise_gas",
            runsound      = GetSoundLoc("moss"),
            walksound     = GetSoundLoc("moss", true),
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "mini_gasbiome_noise",
        },
    },{
        id    = "RAINFOREST",
        name  = "rain_forest",
        specs = {
            name          = "rain_forest",
            noise_texture = "ground_noise_rainforest",
            runsound      = GetSoundLoc("woods"),
            walksound     = GetSoundLoc("woods", true),
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "mini_noise_rainforest",
        },
    },{
        id    = "FIELDS",
        name  = "fields",
        specs = {
            name          = "jungle",
            noise_texture = GetTextureLoc("noise_farmland"),
            runsound      = GetSoundLoc("woods"),
            walksound     = GetSoundLoc("woods", true),
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "mini_noise_farmland",
        },
    },{
        id    = "SUBURB",
        name  = "suburb",
        specs = {
            name          = "deciduous",
            noise_texture = "noise_mossy_blossom",
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "mini_noise_mossy_blossom",
        },
    },{
        id    = "PIGRUINS",
        name  = "pig_ruins",
        specs = {
            name          = "blocky",
            noise_texture = "ground_ruins_slab",
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "mini_ruins_slab",
        },
    },{
        id    = "BATTLEGROUND",
        name  = "battleground",
        specs = {
            name          = "jungle_deep",
            noise_texture = "ground_battlegrounds",
            runsound      = GetSoundLoc("woods"),
            walksound     = GetSoundLoc("woods", true),
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "mini_battlegrounds_noise",
        },
    },{
        id    = "PLAINS",
        name  = "plains",
        specs = {
            name          = "jungle",
            noise_texture = "ground_plains",
            runsound      = GetSoundLoc("tallgrass"),
            walksound     = GetSoundLoc("tallgrass", true),
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "mini_plains_noise",
        },
    },{
        id    = "PAINTED",
        name  = "painted",
        specs = {
            name          = "swamp",
            noise_texture = "ground_bog",
            runsound      = GetSoundLoc("sand"),
            walksound     = GetSoundLoc("sand", true),
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "mini_bog_noise",
        },
    },{
        id    = "BEARDRUG",
        name  = "beardrug",
        specs = {
            name          = "carpet",
            noise_texture = "ground_beard_hair",
            runsound      = GetSoundLoc("carpet"),
            walksound     = GetSoundLoc("carpet", true),
            flooring      = true,
            hard          = true,
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "mini_leakproofcarpet_noise",
        },
    },{
        id    = "MANGROVE",
        name  = "mangrove",
        specs = {
            name          = "water_medium",
            noise_texture = "ground_water_mangrove",
            runsound      = GetSoundLoc("marsh"),
            walksound     = GetSoundLoc("marsh", true),
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "mini_water_mangrove",
        },
        --colors = COASTAL_SHORE_OCEAN_COLOR,
        --ocean_depth = "SHALLOW",
    },
}
local COASTAL_SHORE_OCEAN_COLOR = {
    primary_color        = {220, 240, 255,  60},
    secondary_color      = { 21,  96, 110, 140},
    secondary_color_dusk = {  0,   0,   0,  50},
    minimap_color        = { 23,  51,  62, 102},
}
local ROUGH_OCEAN_COLOR = {
    primary_color        = { 10, 200, 220,  30},
    secondary_color      = {  1,  20,  45, 230},
    secondary_color_dusk = {  5,  20,  25, 230},
    minimap_color        = { 19,  20,  40, 230},
}
local CUSTOM_COLOR = {
    primary_color        = {255,   0,  0, 255},
    secondary_color      = {250, 140,  0, 255},
    secondary_color_dusk = {  5,  20, 25, 230},
    minimap_color        = { 19,  20, 40, 230},
}
local WAVETINTS = {
    shallow   = {0.8,  0.9,  1},
    rough     = {0.65, 0.84, 0.94},
    swell     = {0.65, 0.84, 0.94},
    brinepool = {0.65, 0.92, 0.94},
    hazardous = {0.40, 0.50, 0.62},
}
local ocean_tiles = {
    -----------------
    -- Shipwrecked --
    -----------------
    {
        id    = "OCEAN_SHALLOW",
        name  = "ocean_shallow",
        specs = {
            name          = "water_medium",
            noise_texture = "ground_noise_water_shallow",
            colors        = CUSTOM_COLOR,
            wavetint      = WAVETINTS.shallow,
            ocean_depth   = "SHALLOW",
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "mini_watershallow_noise",
        },
    },{
        id    = "OCEAN_MEDIUM",
        name  = "ocean_medium",
        specs = {
            name          = "water_medium",
            noise_texture = "ground_noise_water_medium",
            ocean_depth   = "NORMAL",
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "mini_watermedium_noise",
        },
    },{
        id    = "OCEAN_DEEP",
        name  = "ocean_deep",
        specs = {
            name          = "water_medium",
            noise_texture = "ground_noise_water_deep",
            ocean_depth   = "DEEP",
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "mini_waterdeep_noise",
        },
    },{
        id    = "OCEAN_CORAL",
        name  = "ocean_coral",
        specs = {
            --name          = "water_medium",
            name          = "cave",
            noise_texture = "ground_water_coral",
            ocean_depth   = "NORMAL",
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "mini_water_coral",
        },
    },{
        id    = "OCEAN_SHIPGRAVEYARD",
        name  = "ocean_ship_graveyard",
        specs = {
            name          = "water_medium",
            noise_texture = "ground_water_graveyard",
            ocean_depth   = "NORMAL",
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "mini_water_graveyard",
        },
    },{
        id    = "RIVER",
        name  = "river",
        specs = {
            name          = "river",
            noise_texture = "ground_noise_water_river",
            is_shoreline  = true,
            ocean_depth   = "SHALLOW",
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "mini_watershallow_noise",
        },
    },
    ------------
    -- HAMLET --
    ------------
    {
        id    = "LILYPOND",
        name  = "lilypond",
        specs = {
            name          = "water_medium",
            noise_texture = "ground_lilypond2",
            is_shoreline  = true,
            ocean_depth   = "SHALLOW",
        },
        minispecs = {
            name          = "map_edge",
            noise_texture = "mini_lilypond_noise",
        },
    },
}
--[[
Priority Order
BEACH, QUAGMIRE_GATEWAY, QUAGMIRE_CITYSTONE, QUAGMIRE_PARKFIELD, QUAGMIRE_PARKSTONE, QUAGMIRE_PEATFOREST, QUAGMIRE_SOIL, ROAD, PEBBLEBEACH, MARSH, ROCKY, SAVANNA, FOREST, GRASS, DIRT, DECIDUOUS, DESERT_DIRT, VOLCANO_ROCK, VOLCANO, ASH, JUNGLE, SWAMP, MAGMAFIELD, TIDALMARSH, MEADOW, CAVE, FUNGUS, FUNGUSRED, FUNGUSGREEN, SINKHOLE, UNDERROCK, MUD, PIGRUINS, PAINTED, PLAINS, RAINFOREST, DEEPRAINFOREST, BATTLEGROUND, FIELDS, SUBURB, IFOUNDATON, LAWN, COBBLEROAD, GASJUNGLE, BRICK_GLOW, BRICK, TILES_GLOW, TILES, TRIM_GLOW, TRIM, METEOR, SCALE, WOODFLOOR, CHECKER, SNAKESKIN, CARPET, BEARDRUG, LAVAARENA_TRIM, LAVAARENA_FLOOR
priority_id = GROUNDS.DIRT,
move_before = true,
--]]
--[[
TODO
figure out why new ocean tiles are all white regardless if using base game ocean specs
--]]
local function AddNewTiles(tiles, tile_range)
    for _,tile in pairs(tiles) do
        --AddTile(tile_name, tile_range, tile_data, ground_tile_def, minimap_tile_def, turf_def)
        AddTile(tile.id, tile_range, {ground_name = tile.name}, tile.specs, tile.minispecs)
    end
end
AddNewTiles(land_tiles, "LAND")
AddNewTiles(ocean_tiles, "OCEAN")
local priority_list = {
    --{tile = "OCEAN_SHALLOW",       target_tile = "OCEAN_BRINEPOOL_SHORE"},
    --{tile = "OCEAN_MEDIUM",        target_tile = "OCEAN_BRINEPOOL"},
    --{tile = "OCEAN_DEEP",          target_tile = "OCEAN_MEDIUM"},
    --{tile = "OCEAN_CORAL",         target_tile = "OCEAN_DEEP"},
    --{tile = "OCEAN_SHIPGRAVEYARD", target_tile = "OCEAN_CORAL"},
    --{tile = "RIVER",               target_tile = "OCEAN_SHIPGRAVEYARD"},
    --{tile = "MANGROVE",            target_tile = "RIVER"},
    {tile = "BEACH",               target_tile = "QUAGMIRE_GATEWAY", move_before = true},
    {tile = "VOLCANO_ROCK",        target_tile = "DESERT_DIRT"},
    {tile = "VOLCANO",             target_tile = "VOLCANO_ROCK"},
    {tile = "ASH",                 target_tile = "VOLCANO"},
    {tile = "JUNGLE",              target_tile = "ASH"},
    {tile = "SWAMP",               target_tile = "JUNGLE"},
    {tile = "MAGMAFIELD",          target_tile = "SWAMP"},
    {tile = "TIDALMARSH",          target_tile = "MAGMAFIELD"},
    {tile = "MEADOW",              target_tile = "TIDALMARSH"},
    {tile = "PIGRUINS",            target_tile = "MEADOW"},
    {tile = "PAINTED",             target_tile = "PIGRUINS"},
    {tile = "PLAINS",              target_tile = "PAINTED"},
    {tile = "RAINFOREST",          target_tile = "PLAINS"},
    {tile = "DEEPRAINFOREST",      target_tile = "RAINFOREST"},
    {tile = "BATTLEGROUND",        target_tile = "DEEPRAINFOREST"},
    {tile = "FIELDS",              target_tile = "BATTLEGROUND"},
    {tile = "SUBURB",              target_tile = "FIELDS"},
    {tile = "FOUNDATION",          target_tile = "SUBURB"},
    {tile = "LAWN",                target_tile = "FOUNDATION"},
    {tile = "COBBLEROAD",          target_tile = "LAWN"},
    {tile = "GASJUNGLE",           target_tile = "COBBLEROAD"},
    {tile = "SNAKESKIN",           target_tile = "CHECKER"},
    {tile = "BEARDRUG",            target_tile = "CARPET"},
}
for _,data in pairs(priority_list) do
    ChangeTileRenderOrder(WORLD_TILES[data.tile], WORLD_TILES[data.target_tile], not data.move_before)
end

-- TODO this should be applied on a map per map basis. hmmm
if _G.TileGroups.LandTilesNotDock then

end
