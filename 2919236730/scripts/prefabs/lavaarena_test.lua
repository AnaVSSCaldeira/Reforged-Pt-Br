require("prefabs/world")
local GroundTiles = require "worldtiledefs"
--local map_data = REFORGED_DATA.maps[REFORGED_SETTINGS.gameplay.map]

local prefabs = {
    "lavaarena_portal",
    "lavaarena_network",
    "lavaarena_crowdstand",
    "lavaarena_groundtargetblocker",
    "lavaarena_boarlord",
    "lavaarena_center",
    "lavaarena_spawner",
    "lavaarena_floorgrate",
    "lavaarena_battlestandard_damager",
    "lavaarena_battlestandard_shield",
    "lavaarena_battlestandard_heal",

    "lavaarenastage_attack",
    "lavaarenastage_delay",
    "lavaarenastage_dialog",
    "lavaarenastage_allplayersspawned",
    "lavaarenastage_startround",
    "lavaarenastage_wait",
    "lavaarenastage_endofround",
    "lavaarenastage_endofmatch",
    "lavaarenastage_resetgame",

    "boaron",
    "boarrior",
    "peghook",
    "turtillus",
    "trails",
    "snapper",
    "rhinodrill",
    "rhinodrill2",
    "beetletaur",

    "lavaarena_lootbeacon",
    "damagenumber",

    "book_fossil",
    "book_elemental",
    "fireballstaff",
    "healingstaff",
    "hammer_mjolnir",
    "spear_gungnir",
    "spear_lance",
    "blowdart_lava",
    "blowdart_lava2",

    "lavaarena_armorlight",
    "lavaarena_armorlightspeed",
    "lavaarena_armormedium",
    "lavaarena_armormediumdamager",
    "lavaarena_armormediumrecharger",
    "lavaarena_armorheavy",
    "lavaarena_armorextraheavy",

    "lavaarena_feathercrownhat",
    "lavaarena_healingflowerhat",
    --"lavaarena_extraheavyhat",
    "lavaarena_lightdamagerhat",
    "lavaarena_strongdamagerhat",
    "lavaarena_tiaraflowerpetalshat",
    "lavaarena_eyecirclethat",
    "lavaarena_rechargerhat",
    "lavaarena_healinggarlandhat",
    "lavaarena_crowndamagerhat",

    -- Lavaarena season 2
    "lavaarena_armor_hpextraheavy",
    "lavaarena_armor_hppetmastery",
    "lavaarena_armor_hprecharger",
    "lavaarena_armor_hpdamager",

    "lavaarena_firebomb",
    "lavaarena_heavyblade",

    "wave_shimmer",
    "wave_shore",
}

local assets = {
    Asset("SCRIPT", "scripts/prefabs/world.lua"),

    Asset("SOUND", "sound/lava_arena.fsb"),
    Asset("SOUND", "sound/forge2.fsb"),

    Asset("IMAGE", "images/lavaarena_wave.tex"),

    Asset("IMAGE", "images/wave.tex"),
    Asset("IMAGE", "images/wave_shadow.tex"),

    Asset("IMAGE", "levels/tiles/lavaarena_falloff.tex"),
    Asset("FILE", "levels/tiles/lavaarena_falloff.xml"),

    Asset("IMAGE", "images/colour_cubes/day05_cc.tex"), --default CC at startup
    Asset("IMAGE", "images/colour_cubes/lavaarena2_cc.tex"), --override CC
    Asset("IMAGE", "images/colour_cubes/insane_day_cc.tex"), --default insanity CC
    Asset("IMAGE", "images/colour_cubes/lunacy_regular_cc.tex"), --default lunacy CC

    Asset("ANIM", "anim/progressbar_tiny.zip"),
}

local function common_preinit(inst)
    --GroundTiles.underground[1][2].name = "lavaarena_falloff"
    local map_data = REFORGED_DATA.maps[REFORGED_SETTINGS.gameplay.map]
    MapLayerManager:SetSampleStyle(map_data.sample_style)
    if map_data.common_preinit_fn then
        map_data.common_preinit_fn(inst)
    end
end

local function common_postinit(inst)
    local map_data = REFORGED_DATA.maps[REFORGED_SETTINGS.gameplay.map]
    --Initialize lua components
    inst:AddComponent("ambientlighting")
    --inst:PushEvent("overrideambientlighting", Point(200 / 255, 200 / 255, 200 / 255))
    ------------------------------------------
    inst:AddComponent("lavaarenamobtracker")
    ------------------------------------------
    --Dedicated server does not require these components
    --NOTE: ambient lighting is required by light watchers
    if not TheNet:IsDedicated() then
        ------------------------------------------
        inst:AddComponent("ambientsound")
        inst.components.ambientsound:SetReverbPreset(map_data.ambient_sound)
        inst.components.ambientsound:SetWavesEnabled(false) -- TODO what is this?
        inst:PushEvent("overrideambientsound", { tile = GROUND.IMPASSABLE, override = GROUND.LAVAARENA_FLOOR })
        ------------------------------------------
        inst:AddComponent("colourcube")
        inst:PushEvent("overridecolourcube", map_data.colour_cube or "images/colour_cubes/lavaarena2_cc.tex")
        ------------------------------------------
        inst:ListenForEvent("playeractivated", function(inst, player)
            if ThePlayer == player then
                TheNet:UpdatePlayingWithFriends()
            end
        end)
    end
    ------------------------------------------
    if map_data.common_postinit_fn then
        map_data.common_postinit_fn(inst)
    end
end

local function master_postinit(inst)
    local map_data = REFORGED_DATA.maps[REFORGED_SETTINGS.gameplay.map]
    event_server_data("lavaarena", "prefabs/lavaarena").master_postinit(inst)
    if map_data.master_postinit_fn then
        map_data.master_postinit_fn(inst)
    end
end

return MakeWorld("lavaarena", prefabs, assets, common_postinit, master_postinit, { "lavaarena" }, {common_preinit = common_preinit})
