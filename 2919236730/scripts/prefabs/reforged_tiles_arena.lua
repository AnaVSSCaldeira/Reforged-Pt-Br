require("prefabs/world")
local prefabs = { -- TODO add to common fns?
    "lavaarena_portal",
    "reforged_tiles_arena_network",
    "lavaarena_groundtargetblocker",
    "lavaarena_center",
    "lavaarena_spawner",

    "wave_shimmer", -- TODO needed?
    "wave_shore",
}
local assets = { -- TODO which assets are needed? add to common fns?
    Asset("SCRIPT", "scripts/prefabs/world.lua"),

    Asset("SOUND", "sound/lava_arena.fsb"),
    Asset("SOUND", "sound/forge2.fsb"),

    Asset("IMAGE", "images/lavaarena_wave.tex"),

    Asset("IMAGE", "images/wave.tex"),
    Asset("IMAGE", "images/wave_shadow.tex"),

    Asset("IMAGE", "levels/tiles/lavaarena_falloff.tex"),
    Asset("FILE", "levels/tiles/lavaarena_falloff.xml"),

    Asset("IMAGE", "images/colour_cubes/day05_cc.tex"), --default CC at startup
    Asset("IMAGE", "images/colour_cubes/snow_cc.tex"), --override CC
    Asset("IMAGE", "images/colour_cubes/insane_day_cc.tex"), --default insanity CC
    Asset("IMAGE", "images/colour_cubes/lunacy_regular_cc.tex"), --default lunacy CC

    Asset("ANIM", "anim/progressbar_tiny.zip"),
}
--------------------------------------------------------------------------
local function tile_physics_init(inst)
    inst.Map:AddTileCollisionSet(
        COLLISION.LAND_OCEAN_LIMITS,
        TileGroups.ImpassableTiles, true,
        TileGroups.ImpassableTiles, false,
        0.25, 64
    )
end
--------------------------------------------------------------------------
local map_values = {
    name = "reforged_tiles_arena",
    colour_cube  = "images/colour_cubes/snow_cc.tex",
    sample_style = MAP_SAMPLE_STYLE.NINE_SAMPLE,
}
--------------------------------------------------------------------------
local function common_preinit(inst)
    COMMON_FNS.MapPreInit(inst, map_values)
    if AddShoreline ~= nil then
        print("Shore line changed")
        AddShoreline = function() print("custom shore line") end
    end
end
--------------------------------------------------------------------------
local function common_postinit(inst)
    COMMON_FNS.MapPostInit(inst, map_values)
    inst:AddComponent("wavemanager")
    inst.Map:SetTransparentOcean(true)

    -- print(tostring(TheWorld.Map:GetTileAtPoint(ThePlayer:GetPosition():Get()))
    if not TheNet:IsDedicated() then
        print("OCEAN COLOR UPDATING")
        --inst.components.oceancolor:Initialize(true)
        inst.Map:DoOceanRender(true)
    end
end
--------------------------------------------------------------------------
local function master_postinit(inst)
    COMMON_FNS.MapMasterPostInit(inst)
end
--------------------------------------------------------------------------
local function fn()
    return COMMON_FNS.NetworkInit()
end
--------------------------------------------------------------------------
return MakeWorld(map_values.name, prefabs, assets, common_postinit, master_postinit, { "lavaarena" }, {common_preinit = common_preinit, tile_physics_init = tile_physics_init}), Prefab(map_values.name .. "_network", fn)
