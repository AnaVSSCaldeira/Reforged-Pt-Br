local RF_DATA = _G.REFORGED_DATA
RF_DATA.wavesets = {}
 -- TODO is there a way to scan folder for all waveset files and their names? if so then don't need this function, just need to loop through and pull all the wavesets into a table.
function AddWaveset(name, spawners, icon, exp_details, forge_lord, order_priority, reset) -- TODO what does this need?
    if RF_DATA.wavesets[name] then
        _G.Debug:Print("Attempted to add the mode '" .. tostring(name) .."', but it already exists.", "error")
        return
    end
    RF_DATA.wavesets[name] = {
        spawners       = spawners or 3,
        icon           = icon, -- {atlas = ".xml", tex = ".tex"}
        exp_details    = exp_details, -- {desc = "", val = 0, atlas = ".xml", tex = ".tex"}
        forge_lord     = forge_lord or "boarlord",
        order_priority = order_priority or 999,
        reset          = reset,
    }
end
_G.AddWaveset = AddWaveset
-------------
-- Classic --
-------------
local classic_icon = {atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_5.tex"}
local classic_exp_details = {
    {desc = "LAB_MILESTONE_1", val = TUNING.FORGE.EXP.WAVESETS.ROUND_1, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_1.tex"},
    {desc = "LAB_MILESTONE_2", val = TUNING.FORGE.EXP.WAVESETS.ROUND_2, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_2.tex"},
    {desc = "LAB_MILESTONE_3", val = TUNING.FORGE.EXP.WAVESETS.ROUND_3, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_3.tex"},
    {desc = "LAB_MILESTONE_4", val = TUNING.FORGE.EXP.WAVESETS.ROUND_4, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_4.tex"},
    {desc = "LAB_WIN", val = TUNING.FORGE.EXP.WAVESETS.VICTORY, atlas = "images/lavaarena_quests.xml", tex = "lab_win.tex"},
}
AddWaveset("classic", nil, classic_icon, classic_exp_details, nil, 2)
--------------
-- Boarilla --
--------------
local boarilla_icon = {atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_4.tex"}
local boarilla_exp_details = {
    {desc = "LAB_MILESTONE_1", val = TUNING.FORGE.EXP.WAVESETS.ROUND_1, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_1.tex"},
    {desc = "LAB_MILESTONE_2", val = TUNING.FORGE.EXP.WAVESETS.ROUND_2, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_2.tex"},
    {desc = "LAB_MILESTONE_3", val = TUNING.FORGE.EXP.WAVESETS.ROUND_3, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_3.tex"},
    {desc = "LAB_WIN", val = TUNING.FORGE.EXP.WAVESETS.VICTORY, atlas = "images/lavaarena_quests.xml", tex = "lab_win.tex"},
}
AddWaveset("boarilla", nil, boarilla_icon, boarilla_exp_details,  nil, 1)
---------------
-- Boarillas --
---------------
local boarillas_icon = {atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_4.tex"}
local boarillas_exp_details = {
    {desc = "LAB_MILESTONE_1", val = TUNING.FORGE.EXP.WAVESETS.ROUND_1, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_1.tex"},
    {desc = "LAB_MILESTONE_2", val = TUNING.FORGE.EXP.WAVESETS.ROUND_2, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_2.tex"},
    {desc = "LAB_MILESTONE_3", val = TUNING.FORGE.EXP.WAVESETS.ROUND_3, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_3.tex"},
    {desc = "LAB_MILESTONE_4", val = TUNING.FORGE.EXP.WAVESETS.ROUND_4, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_4.tex"},
    {desc = "LAB_WIN", val = TUNING.FORGE.EXP.WAVESETS.VICTORY, atlas = "images/lavaarena_quests.xml", tex = "lab_win.tex"},
}
AddWaveset("boarillas", nil, boarillas_icon, boarillas_exp_details,  nil, 1)
----------------
-- Rinocebros --
----------------
local rhinocebros_icon = {atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_6.tex"}
local rhinocebros_exp_details = {
    {desc = "LAB_MILESTONE_1", val = TUNING.FORGE.EXP.WAVESETS.ROUND_1, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_1.tex"},
    {desc = "LAB_MILESTONE_2", val = TUNING.FORGE.EXP.WAVESETS.ROUND_2, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_2.tex"},
    {desc = "LAB_MILESTONE_3", val = TUNING.FORGE.EXP.WAVESETS.ROUND_3, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_3.tex"},
    {desc = "LAB_MILESTONE_4", val = TUNING.FORGE.EXP.WAVESETS.ROUND_4, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_4.tex"},
    {desc = "LAB_MILESTONE_5", val = TUNING.FORGE.EXP.WAVESETS.ROUND_5, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_5.tex"},
    {desc = "LAB_WIN", val = TUNING.FORGE.EXP.WAVESETS.VICTORY, atlas = "images/lavaarena_quests.xml", tex = "lab_win.tex"},
}
AddWaveset("rhinocebros", nil, rhinocebros_icon, rhinocebros_exp_details,  nil, 3)
----------------
-- Swineclops --
----------------
local swineclops_icon = {atlas = "images/filter_icons.xml", tex = "beetletaur.tex"}
local swineclops_exp_details = {
    {desc = "LAB_MILESTONE_1", val = TUNING.FORGE.EXP.WAVESETS.ROUND_1, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_1.tex"},
    {desc = "LAB_MILESTONE_2", val = TUNING.FORGE.EXP.WAVESETS.ROUND_2, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_2.tex"},
    {desc = "LAB_MILESTONE_3", val = TUNING.FORGE.EXP.WAVESETS.ROUND_3, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_3.tex"},
    {desc = "LAB_MILESTONE_4", val = TUNING.FORGE.EXP.WAVESETS.ROUND_4, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_4.tex"},
    {desc = "LAB_MILESTONE_5", val = TUNING.FORGE.EXP.WAVESETS.ROUND_5, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_5.tex"},
    {desc = "LAB_MILESTONE_6", val = TUNING.FORGE.EXP.WAVESETS.ROUND_6, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_6.tex"},
    {desc = "LAB_WIN", val = TUNING.FORGE.EXP.WAVESETS.VICTORY, atlas = "images/lavaarena_quests.xml", tex = "lab_win.tex"},
}
AddWaveset("swineclops", nil, swineclops_icon, swineclops_exp_details,  nil, 4)
--------------------
-- Double Trouble --
--------------------
local dt_exp_mult = 4
local double_trouble_icon = {atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_4.tex"}
local double_trouble_classic_exp_details = {
    {desc = "LAB_MILESTONE_1", val = TUNING.FORGE.EXP.WAVESETS.ROUND_1 * dt_exp_mult, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_1.tex"},
    {desc = "LAB_MILESTONE_2", val = TUNING.FORGE.EXP.WAVESETS.ROUND_2 * dt_exp_mult, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_2.tex"},
    {desc = "LAB_MILESTONE_3", val = TUNING.FORGE.EXP.WAVESETS.ROUND_3 * dt_exp_mult, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_3.tex"},
    {desc = "LAB_MILESTONE_4", val = TUNING.FORGE.EXP.WAVESETS.ROUND_4 * dt_exp_mult, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_4.tex"},
    {desc = "LAB_WIN", val = TUNING.FORGE.EXP.WAVESETS.VICTORY * dt_exp_mult, atlas = "images/lavaarena_quests.xml", tex = "lab_win.tex"},
}
--AddWaveset("double_trouble_classic", nil, double_trouble_icon, double_trouble_classic_exp_details,  nil, 5)
local double_trouble_exp_details = {
    {desc = "LAB_MILESTONE_1", val = TUNING.FORGE.EXP.WAVESETS.ROUND_1 * dt_exp_mult, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_1.tex"},
    {desc = "LAB_MILESTONE_2", val = TUNING.FORGE.EXP.WAVESETS.ROUND_2 * dt_exp_mult, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_2.tex"},
    {desc = "LAB_MILESTONE_3", val = TUNING.FORGE.EXP.WAVESETS.ROUND_3 * dt_exp_mult, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_3.tex"},
    {desc = "LAB_MILESTONE_4", val = TUNING.FORGE.EXP.WAVESETS.ROUND_4 * dt_exp_mult, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_4.tex"},
    {desc = "LAB_MILESTONE_5", val = TUNING.FORGE.EXP.WAVESETS.ROUND_5 * dt_exp_mult, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_5.tex"},
    {desc = "LAB_MILESTONE_6", val = TUNING.FORGE.EXP.WAVESETS.ROUND_6 * dt_exp_mult, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_6.tex"},
    {desc = "LAB_WIN", val = TUNING.FORGE.EXP.WAVESETS.VICTORY * dt_exp_mult, atlas = "images/lavaarena_quests.xml", tex = "lab_win.tex"},
}
--AddWaveset("double_trouble", nil, double_trouble_icon, double_trouble_exp_details,  nil, 6)
--------------------
-- Half the Wrath --
--------------------
local half_the_wrath_icon = {atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_1.tex"}
local half_the_wrath_exp_details = {
    {desc = "LAB_MILESTONE_1", val = TUNING.FORGE.EXP.WAVESETS.ROUND_1 * 0.5, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_1.tex"},
    {desc = "LAB_MILESTONE_2", val = TUNING.FORGE.EXP.WAVESETS.ROUND_2 * 0.5, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_2.tex"},
    {desc = "LAB_MILESTONE_3", val = TUNING.FORGE.EXP.WAVESETS.ROUND_3 * 0.5, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_3.tex"},
    {desc = "LAB_MILESTONE_4", val = TUNING.FORGE.EXP.WAVESETS.ROUND_4 * 0.5, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_4.tex"},
    {desc = "LAB_MILESTONE_5", val = TUNING.FORGE.EXP.WAVESETS.ROUND_5 * 0.5, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_5.tex"},
    {desc = "LAB_MILESTONE_6", val = TUNING.FORGE.EXP.WAVESETS.ROUND_6 * 0.5, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_6.tex"},
    {desc = "LAB_WIN", val = TUNING.FORGE.EXP.WAVESETS.VICTORY * 0.5, atlas = "images/lavaarena_quests.xml", tex = "lab_win.tex"},
}
AddWaveset("half_the_wrath", nil, half_the_wrath_icon, half_the_wrath_exp_details,  nil, 7)
-------------
-- Sandbox --
-------------
local sandbox_icon = {atlas = "images/inventoryimages.xml", tex = "bundle_large.tex"}
AddWaveset("sandbox", nil, sandbox_icon, nil, nil, 9999)

----------------
-- Randomized --
----------------
local randomized_icon = {atlas = "images/reforged.xml", tex = "unknown_icon.tex"}
local randomized_exp_details = {
    {desc = "LAB_MILESTONE_1", val = TUNING.FORGE.EXP.WAVESETS.ROUND_1 * 0.75, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_1.tex"},
    {desc = "LAB_MILESTONE_2", val = TUNING.FORGE.EXP.WAVESETS.ROUND_2 * 0.75, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_2.tex"},
    {desc = "LAB_MILESTONE_3", val = TUNING.FORGE.EXP.WAVESETS.ROUND_3 * 0.75, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_3.tex"},
    {desc = "LAB_MILESTONE_4", val = TUNING.FORGE.EXP.WAVESETS.ROUND_4 * 0.75, atlas = "images/lavaarena_quests.xml", tex = "lab_milestone_4.tex"},
    {desc = "LAB_WIN", val = TUNING.FORGE.EXP.WAVESETS.VICTORY * 0.75, atlas = "images/lavaarena_quests.xml", tex = "lab_win.tex"},
}
AddWaveset("randomized", nil, randomized_icon, randomized_exp_details)
