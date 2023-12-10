local STRINGS = _G.STRINGS
local RF_TUNING = _G.TUNING.FORGE
local RF_DATA = _G.REFORGED_DATA
RF_DATA.difficulties = {}
function AddDifficulty(name, fns, icon, exp_details, order_priority, reset)
    if RF_DATA.difficulties[name] then
        _G.Debug:Print("Attempted to add the difficulty '" .. tostring(name) .."', but it already exists.", "error")
        return
    end
    RF_DATA.difficulties[name] = {
        fns            = fns or {},
        icon           = icon,
        exp_details    = exp_details,
        order_priority = order_priority or 999,
        reset          = reset,
    }
end
_G.AddDifficulty = AddDifficulty
local normal_icon = {atlas = "images/reforged.xml", tex = "d_normal.tex"}
AddDifficulty("normal", nil, normal_icon, nil, 1)
local hard_mode_fns = require("hard_mode") -- TODO create a difficulty file instead? and then import each difficulty in that?
local hard_mode_icon = {atlas = "images/reforged.xml", tex = "d_hard.tex"}
local hard_mode_exp = {desc = "HARD_MODE", val = {mult = RF_TUNING.EXP.DIFFICULTIES.hard_mode}}
AddDifficulty("hard", hard_mode_fns, hard_mode_icon, hard_mode_exp, 2)
