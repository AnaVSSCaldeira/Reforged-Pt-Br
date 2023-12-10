local _G = GLOBAL
local Layouts = _G.require("map/layouts").Layouts
local StaticLayout = _G.require("map/static_layout")

_G.REFORGED_GROUND_TYPES = {
    --Translates tile type index from constants.lua into tiled tileset.
    --Order they appear here is the order they will be used in tiled.
    -- Don't Starve
    -- Terrain
    WORLD_TILES.IMPASSABLE,   WORLD_TILES.ROAD,          WORLD_TILES.ROCKY,       WORLD_TILES.DIRT,        -- 1,   2,  3,  4
    WORLD_TILES.SAVANNA,      WORLD_TILES.GRASS,         WORLD_TILES.FOREST,      WORLD_TILES.MARSH,       -- 5,   6,  7,  8
    WORLD_TILES.DESERT_DIRT,  WORLD_TILES.UNDERROCK,     WORLD_TILES.DECIDUOUS,   WORLD_TILES.PEBBLEBEACH, -- 9,  10, 11, 12
    WORLD_TILES.METEOR,       WORLD_TILES.SHELLBEACH,    WORLD_TILES.ARCHIVE,     WORLD_TILES.FUNGUSMOON,  -- 13, 14, 15, 16
    WORLD_TILES.FARMING_SOIL, WORLD_TILES.MONKEY_GROUND, WORLD_TILES.MONKEY_DOCK,                          -- 17, 18, 19
    -- Flooring
    WORLD_TILES.WOODFLOOR, WORLD_TILES.CARPET, WORLD_TILES.CHECKER, WORLD_TILES.SCALE, -- 20, 21, 22, 23
    -- Cave
    WORLD_TILES.CAVE,     WORLD_TILES.FUNGUS,     WORLD_TILES.FUNGUSRED, WORLD_TILES.FUNGUSGREEN, -- 24, 25, 26, 27
    WORLD_TILES.SINKHOLE, WORLD_TILES.MUD,        WORLD_TILES.BRICK,     WORLD_TILES.BRICK_GLOW,  -- 28, 29, 30, 31
    WORLD_TILES.TILES,    WORLD_TILES.TILES_GLOW, WORLD_TILES.TRIM,      WORLD_TILES.TRIM_GLOW,   -- 32, 33, 34, 35
    -- Forge
    WORLD_TILES.DIRT, WORLD_TILES.DIRT,
    --WORLD_TILES.LAVAARENA_FLOOR, WORLD_TILES.LAVAARENA_TRIM, -- 36, 37
    -- Gorge
    WORLD_TILES.QUAGMIRE_GATEWAY,   WORLD_TILES.QUAGMIRE_SOIL, WORLD_TILES.QUAGMIRE_PARKSTONE, WORLD_TILES.QUAGMIRE_PARKFIELD, -- 38, 39, 40, 41
    WORLD_TILES.QUAGMIRE_CITYSTONE, WORLD_TILES.QUAGMIRE_PEATFOREST, -- 42, 43
    -- Ocean
    WORLD_TILES.OCEAN_COASTAL,   WORLD_TILES.OCEAN_COASTAL_SHORE,   WORLD_TILES.OCEAN_SWELL,     WORLD_TILES.OCEAN_ROUGH,    -- 44, 45, 46, 47
    WORLD_TILES.OCEAN_BRINEPOOL, WORLD_TILES.OCEAN_BRINEPOOL_SHORE, WORLD_TILES.OCEAN_HAZARDOUS, WORLD_TILES.OCEAN_WATERLOG, -- 48, 49, 50, 51
    -- Shipwrecked
    -- Terrain
    WORLD_TILES.BEACH,        WORLD_TILES.JUNGLE, WORLD_TILES.SWAMP,   WORLD_TILES.MAGMAFIELD, -- 52, 53, 54, 55
    WORLD_TILES.TIDALMARSH,   WORLD_TILES.MEADOW, WORLD_TILES.VOLCANO, WORLD_TILES.ASH,        -- 56, 57, 58, 59
    WORLD_TILES.VOLCANO_ROCK, WORLD_TILES.SNAKESKIN, -- 60, 61
    -- Ocean
    --WORLD_TILES.OCEAN_SHALLOW, WORLD_TILES.OCEAN_MEDIUM, WORLD_TILES.OCEAN_DEEP, WORLD_TILES.OCEAN_CORAL, -- 62, 63, 64, 65
    --WORLD_TILES.OCEAN_SHIPGRAVEYARD, WORLD_TILES.RIVER, WORLD_TILES.MANGROVE, -- 66, 67, 68
    -- Hamlet
    WORLD_TILES.DEEPRAINFOREST, WORLD_TILES.FOUNDATION,        WORLD_TILES.COBBLEROAD, WORLD_TILES.LAWN,    -- 62, 63, 64, 65 -- 69, 70, 71, 72
    WORLD_TILES.GASJUNGLE,      WORLD_TILES.RAINFOREST,        WORLD_TILES.FIELDS,     WORLD_TILES.SUBURB,  -- 66, 67, 68, 69 -- 73, 74, 75, 76
    WORLD_TILES.PIGRUINS,       WORLD_TILES.BATTLEWORLD_TILES, WORLD_TILES.PLAINS,     WORLD_TILES.PAINTED, -- 70, 71, 72, 73 -- 77, 78, 79, 80
    WORLD_TILES.BEARDRUG, -- 74 -- 81
    --WORLD_TILES.LILYPOND, -- 78
    WORLD_TILES.OCEAN_CORAL, OCEAN_SHALLOW,
}
--------------------
-- ReForged Tiles --
--------------------
Layouts["ReForgedTiles_Layout"] = StaticLayout.Get("map/static_layouts/ReForgedTiles", {
    start_mask        = _G.PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    fill_mask         = _G.PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    layout_position   = _G.LAYOUT_POSITION.CENTER,
    disable_transform = true,
})
Layouts["ReForgedTiles_Layout"].ground_types = _G.REFORGED_GROUND_TYPES,
_G.AddStartLocation("ReForgedTiles", {
    name           = _G.STRINGS.UI.SANDBOXMENU.DEFAULTSTART,
    location       = "reforged_tiles_arena",
    start_setpeice = "ReForgedTiles_Layout",
    start_node     = "Blank",
})
_G.AddLocation({
    location  = "reforged_tiles_arena",
    version   = 2,
    overrides = {
        task_set                           = "lavaarena_taskset",
        start_location                     = "ReForgedTiles",
        season_start                       = "default",
        world_size                         = "default",
        layout_mode                        = "RestrictNodesByKey",
        wormhole_prefab                    = nil,
        roads                              = "never",
        keep_disconnected_tiles            = true,
        no_wormholes_to_disconnected_tiles = true,
        no_joining_islands                 = true,
        --has_ocean                          = true,
    },
    required_prefabs = {
        "lavaarena_portal",
    },
})
_G.AddWorldGenLevel(_G.LEVELTYPE.LAVAARENA, {
    id       = "REFORGEDTILES",
    name     = "ReForged Tiles",
    desc     = "All tiles available for making maps.", -- TODO strings
    location = "reforged_tiles_arena", -- this is actually the prefab name
    version  = 4,
    overrides = {
        boons          = "never",
        touchstone     = "never",
        traps          = "never",
        poi            = "never",
        protected      = "never",
        --task_set       = "lavaarena_taskset",
        --start_location = "ReForgedTiles",
        --season_start   = "default",
        --world_size     = "small",
        --layout_mode    = "RestrictNodesByKey",
        --keep_disconnected_tiles = true,
        --wormhole_prefab = nil,
        --roads           = "never",
        --has_ocean       = true,
    },
    --required_prefabs = {
        --"lavaarena_portal",
    --},
    background_node_range = {0,1},
})
_G.AddSettingsPreset(LEVELTYPE.LAVAARENA, {
    id        = "REFORGEDTILES",
    name      = "ReForged Tiles",
    desc      = "All tiles available for making maps.", -- TODO strings
    location  = "reforged_tiles_arena", -- this is actually the prefab name
    version   = 1,
    overrides = {},
})
