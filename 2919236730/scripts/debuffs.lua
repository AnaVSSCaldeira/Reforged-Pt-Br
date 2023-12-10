local RF_DATA = _G.REFORGED_DATA
local UserCommands = require "usercommands"
RF_DATA.debuffs = {}
function AddDebuff(name, icon, order_priority)
    local perk_tbl = _G.EnsureTable(RF_DATA.perks, character_prefab)
    if RF_DATA.debuffs[name] then
        Debug:Print("Attempted to add the debuff '" .. tostring(name) .."', but it already exists.", "error")
        return
    end
    RF_DATA.debuffs[name] = {
        icon           = icon or {atlas = "images/reforged.xml", tex = "unknown_icon.tex"},
        order_priority = order_priority or 999,
    }
end
_G.AddDebuff = AddDebuff
AddDebuff("healingcircle_regenbuff", {atlas = "images/reforged.xml", tex = "debuff_heal.tex"})
AddDebuff("debuff_armorbreak", {atlas = "images/reforged.xml", tex = "debuff_armorbreak.tex"})
AddDebuff("debuff_fire", {atlas = "images/reforged.xml", tex = "debuff_onfire.tex"})
AddDebuff("debuff_haunt", {atlas = "images/reforged.xml", tex = "debuff_haunted.tex"})
AddDebuff("debuff_wet", {atlas = "images/reforged.xml", tex = "debuff_wet.tex"})
AddDebuff("spatula_food_buff", {atlas = "images/reforged.xml", tex = "lavaarena_spatula.tex"}) -- TODO: make proper icon! 
AddDebuff("debuff_mfd", {atlas = "images/reforged.xml", tex = "debuff_mfd.tex"})
AddDebuff("trap_snare_debuff", nil)
AddDebuff("buff_woby", {atlas = "images/reforged.xml", tex = "debuff_wobybuff.tex"})
AddDebuff("scorpeon_dot", {atlas = "images/reforged.xml", tex = "debuff_scorpeon_dot.tex"})
AddDebuff("debuff_shield", {atlas = "images/reforged.xml", tex = "debuff_generic_def_up.tex"})
AddDebuff("debuff_spice_dmg", {atlas = "images/reforged.xml", tex = "debuff_spice_red.tex"})
AddDebuff("debuff_spice_def", {atlas = "images/reforged.xml", tex = "debuff_spice_blue.tex"})
AddDebuff("debuff_spice_speed", {atlas = "images/reforged.xml", tex = "debuff_spice_white.tex"})
AddDebuff("debuff_spice_regen", {atlas = "images/reforged.xml", tex = "debuff_spice_green.tex"})
AddDebuff("debuff_pollen", {atlas = "images/reforged.xml", tex = "debuff_pollen.tex"})
AddDebuff("shield_buff", {atlas = "images/reforged.xml", tex = "debuff_def_banner.tex"})
AddDebuff("damager_buff", {atlas = "images/reforged.xml", tex = "debuff_atk_banner.tex"})
AddDebuff("healer_buff", {atlas = "images/reforged.xml", tex = "debuff_heal_banner.tex"})
AddDebuff("speed_buff", {atlas = "images/reforged.xml", tex = "debuff_speed_banner.tex"})
