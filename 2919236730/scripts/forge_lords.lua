local RF_DATA = _G.REFORGED_DATA
RF_DATA.forge_lords = {}
function AddForgeLord(name, bank, build, stategraph, opts, order_priority, reset)
    if RF_DATA.forge_lords[name] then
        Debug:Print("Attempted to add the Forge Lord '" .. tostring(name) .."', but it already exists.", "error")
        return
    end
    local options = opts or {}
    RF_DATA.forge_lords[name] = {
        nameoverride       = options.nameoverride,
        bank               = bank or "boarlord",
        build              = build or "boarlord",
        stategraph         = stategraph or "SGboarlord",
        scale              = options.scale or {-1,1},
        avatar             = options.avatar, -- {build = build, font = font, colour = colour}
        on_changed_to_fn   = options.on_changed_to_fn,
        on_changed_from_fn = options.on_changed_from_fn,
        order_priority     = order_priority or 999,
        reset              = reset,
    }
end
function GetForgeLord(name, current)
    local current = current and RF_DATA.wavesets[_G.REFORGED_SETTINGS.gameplay.waveset].forge_lord
    return RF_DATA.forge_lords[current or name]
end
_G.AddForgeLord = AddForgeLord
_G.GetForgeLord = GetForgeLord
--------------
-- BoarLord --
--------------
local function BoarlordOnChangedTo(inst)
end
local function BoarlordOnChangedFrom(inst)
end
local boarlord_opts = {
    nameoverride = "lavaarena_boarlord",
    scale = {-1,1},
    --on_changed_to_fn   = BoarlordOnChangedTo,
    --on_changed_from_fn = BoarlordOnChangedFrom,
}
AddForgeLord("boarlord", "boarlord", "boarlord", "SGboarlord", boarlord_opts, 1)
