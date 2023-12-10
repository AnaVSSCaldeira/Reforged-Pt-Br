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

local Assets = {
	Asset("ANIM", "anim/power_punch.zip"),
	Asset("ANIM", "anim/spectator.zip"), 
	-------------------------------------------------
	Asset("ANIM", "anim/lavaarena_doydoy.zip"),
	-------------------------------------------------
	Asset("SOUNDPACKAGE", "sound/reforge.fev"),
    Asset("SOUND", "sound/reforge.fsb"),
	-------------------------------------------------
	--Alt palettes for mobs, mostly for doubletrouble or other modding reasons.
	Asset("ANIM", "anim/lavaarena_beetletaur_alt1.zip"),
	Asset("ANIM", "anim/lavaarena_rhinodrill_alt1.zip"),
	Asset("ANIM", "anim/lavaarena_rhinodrill_clothed_alt1.zip"),
	Asset("ANIM", "anim/lavaarena_rhinodrill_damaged_alt1.zip"),
	Asset("ANIM", "anim/lavaarena_boaron_alt1.zip"),
	Asset("ANIM", "anim/lavaarena_boarrior_alt1.zip"),
	Asset("ANIM", "anim/lavaarena_trails_alt1.zip"),
	Asset("ANIM", "anim/lavaarena_turtillus_alt1.zip"),
	Asset("ANIM", "anim/lavaarena_peghook_alt1.zip"),
	Asset("ANIM", "anim/lavaarena_snapper_alt1.zip"),
	

	Asset("ANIM", "anim/lavaarena_banner_ping_build.zip"),
	Asset("ANIM", "anim/lavaarena_battlestandard_alt1.zip"),
	Asset("ANIM", "anim/lavaarena_battlestandard_attack_build_alt1.zip"),
	Asset("ANIM", "anim/lavaarena_battlestandard_heal_build_alt1.zip"),
	Asset("ANIM", "anim/lavaarena_battlestandard_speed_build.zip"),
	Asset("ANIM", "anim/lavaarena_battlestandard_speed_build_alt1.zip"),

	Asset("ANIM", "anim/lavaarena_boaron_hardmode.zip"),
	Asset("ANIM", "anim/lavaarena_snapper_hardmode.zip"),
	Asset("ANIM", "anim/lavaarena_turtillus_hardmode.zip"),
	Asset("ANIM", "anim/lavaarena_peghook_hardmode.zip"),
	Asset("ANIM", "anim/lavaarena_rhinodrill_hardmode.zip"),
	Asset("ANIM", "anim/lavaarena_rhinodrill_clothed_hardmode.zip"),
	Asset("ANIM", "anim/lavaarena_rhinodrill_damaged_hardmode.zip"),
	Asset("ANIM", "anim/lavaarena_beetletaur_hardmode.zip"),
	Asset("ANIM", "anim/lavaarena_beetletaur_hardmode_enraged.zip"),

	Asset("ANIM", "anim/lavaarena_fissure.zip"),
	Asset("ANIM", "anim/lavaarena_trap_spikes.zip"),
	Asset("ANIM", "anim/lavaarena_trap_beartrap.zip"),
	Asset("ANIM", "anim/campfire_fire_colorable.zip"),
	-------------------------------------------------

	Asset("ANIM", "anim/lavaarena_buff_build.zip"),
	Asset("ANIM", "anim/lavaarena_debuff_build.zip"),
	Asset("ANIM", "anim/lavaarena_bufficons.zip"),
	Asset("ANIM", "anim/lavaarena_buffindex.zip"),

	Asset("ANIM", "anim/lavaarena_seeddart.zip"),
	Asset("ANIM", "anim/lavaarena_seeddart2.zip"),
    Asset("ANIM", "anim/swap_lavaarena_seeddart.zip"),
	Asset("ANIM", "anim/swap_lavaarena_seeddart2.zip"),
	Asset("ANIM", "anim/lavaarena_spatula.zip"),
	Asset("ANIM", "anim/swap_lavaarena_spatula.zip"),
    Asset("ANIM", "anim/trident.zip"),
    Asset("ANIM", "anim/swap_trident.zip"),
    Asset("ANIM", "anim/teleport_staff.zip"),
    Asset("ANIM", "anim/swap_teleport_staff.zip"),
	Asset("ANIM", "anim/rf_time_staff.zip"),
	Asset("ANIM", "anim/swap_rf_time_staff.zip"),
	Asset("ANIM", "anim/lavaarena_gauntlet.zip"),
	Asset("ANIM", "anim/swap_lavaarena_gauntlet.zip"),
	Asset("ANIM", "anim/lavaarena_chefhat.zip"),

	Asset("ANIM", "anim/swap_lavaarena_spicebomb.zip"),
	Asset("ANIM", "anim/lavaarena_spicebomb.zip"),
	Asset("ANIM", "anim/lavaarena_spicebomb_normal_build.zip"),
	Asset("ANIM", "anim/lavaarena_spicebomb_def_build.zip"),
	Asset("ANIM", "anim/lavaarena_spicebomb_dmg_build.zip"),
	Asset("ANIM", "anim/lavaarena_spicebomb_speed_build.zip"),
	Asset("ANIM", "anim/lavaarena_spicebomb_regen_build.zip"),

	Asset("ANIM", "anim/food_projectile.zip"),
	
	Asset("ANIM", "anim/lavaarena_player_teleport_colorable.zip"),
	Asset("ANIM", "anim/forcefield_colorable.zip"),
	Asset("ANIM", "anim/lavaarena_boaron_undead_actions.zip"),
	Asset("ANIM", "anim/lavaarena_peghook_cultist_actions.zip"),
	Asset("ANIM", "anim/undead_ground_fx.zip"),

	Asset("ANIM", "anim/rf_generic_fossilized.zip"),
	Asset("ANIM", "anim/rf_generic_frozen.zip"),
	Asset("ANIM", "anim/rf_generic_frozen_med.zip"),

    -- Icon Assets
	Asset("ATLAS", "images/servericons.xml"),
	Asset("IMAGE", "images/servericons.tex"),

	Asset("ATLAS", "images/reforged.xml"),
	Asset("ATLAS", "images/maps.xml"),
	
	Asset("IMAGE", "images/rf_alt_icons.tex"),
	Asset("ATLAS", "images/rf_alt_icons.xml"),

	Asset("IMAGE", "images/level_badges.tex"),
	Asset("ATLAS", "images/level_badges.xml"),

	Asset("ATLAS", "images/force_start.xml"),
    Asset("IMAGE", "images/force_start.tex"),

    Asset("ATLAS", "images/level_badges.xml"),
    Asset("IMAGE", "images/level_badges.tex"),

    Asset("ATLAS", "images/avatars_resize.xml"),
    Asset("IMAGE", "images/avatars_resize.tex"),
    Asset("ATLAS", "images/filter_icons.xml"),
    Asset("IMAGE", "images/filter_icons.tex"),

    Asset("ATLAS", "bigportraits/spectator.xml"),
    Asset("IMAGE", "bigportraits/spectator.tex"),

    Asset("ATLAS", "images/rf_panel_assets.xml"),
    Asset("IMAGE", "images/rf_panel_assets.tex"),

    Asset("ATLAS", "images/rf_achievements.xml"),
    Asset("IMAGE", "images/rf_achievements.tex"),

	-- Colour Cubes
	-- Default
    Asset("IMAGE", "images/colour_cubes/day05_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/dusk03_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/night03_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/snow_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/snowdusk_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/night04_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/summer_day_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/summer_dusk_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/summer_night_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/spring_day_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/spring_dusk_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/spring_night_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/insane_day_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/insane_dusk_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/insane_night_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/purple_moon_cc.tex"),
	Asset("IMAGE", "images/colour_cubes/beaver_vision_cc.tex"),
	Asset("IMAGE", "images/colour_cubes/caves_default.tex"),
	Asset("IMAGE", "images/colour_cubes/fungus_cc.tex"),
	Asset("IMAGE", "images/colour_cubes/ghost_cc.tex"),
	Asset("IMAGE", "images/colour_cubes/identity_colourcube.tex"),
	Asset("IMAGE", "images/colour_cubes/mole_vision_off_cc.tex"),
	Asset("IMAGE", "images/colour_cubes/mole_vision_on_cc.tex"),
	Asset("IMAGE", "images/colour_cubes/ruins_dark_cc.tex"),
	Asset("IMAGE", "images/colour_cubes/ruins_dim_cc.tex"),
	Asset("IMAGE", "images/colour_cubes/ruins_light_cc.tex"),
	Asset("IMAGE", "images/colour_cubes/sinkhole_cc.tex"),

	-- Shipwrecked
    Asset("IMAGE", "images/colour_cubes/sw_mild_day_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/sw_wet_day_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/sw_green_day_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/sw_volcano_cc.tex"),

	-- Forge
	Asset("IMAGE", "images/colour_cubes/lavaarena2_cc.tex"),

	-- Gorge
	Asset("IMAGE", "images/colour_cubes/quagmire_cc.tex"),

    -- Shaders
    Asset("SHADER", "shaders/shadertest.ksh"),
    Asset("SHADER", "shaders/testing.ksh"),
}

local rf_characters = {"spectator"}

--automate the requiring of asset images for characters
local assetPaths = { "bigportraits/", "images/map_icons/", "images/avatars/avatar_", "images/avatars/avatar_ghost_" }
local assetTypes = { {"IMAGE", "tex"}, {"ATLAS", "xml"} }
for _, prefab in ipairs(rf_characters) do
	for _, path in ipairs(assetPaths) do
		for _, assetType in ipairs(assetTypes) do
			table.insert( Assets, Asset( assetType[1], path..prefab.."."..assetType[2] ) )
		end
	end
end

return Assets
