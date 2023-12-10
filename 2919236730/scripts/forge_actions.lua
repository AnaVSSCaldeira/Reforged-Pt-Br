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
local ACTIONS = _G.ACTIONS
-- Add extra options when casting aoe's through extra key presses (force_trade, force_attack(force_stack), force_inspect)
local function DecodePressedControls()
    -- Shift
    return _G.TheInput:IsControlPressed(_G.CONTROL_FORCE_TRADE) and 2 or
    -- Ctrl
    _G.TheInput:IsControlPressed(_G.CONTROL_FORCE_ATTACK) and 3 or
    -- Alt
    _G.TheInput:IsControlPressed(_G.CONTROL_FORCE_INSPECT) and 4 or
    -- None
    1
end
ACTIONS.CASTAOE.strfn = function(act)
    local ability_strings = act.invobject and act.invobject.ability_strings
    return act.invobject ~= nil and (ability_strings and ability_strings[DecodePressedControls()] or string.upper(act.invobject.nameoverride ~= nil and act.invobject.nameoverride or act.invobject.prefab)) or nil
end
ACTIONS.CASTAOE.fn = function(act)
    local act_pos = act:GetActionPoint()
    if act.invobject ~= nil and act.invobject.components.aoespell ~= nil and act.invobject.components.aoespell:CanCast(act.doer, act_pos) then
        act.invobject.components.aoespell:CastSpell(act.doer, act_pos, act.options)
        return true
    end
end

--fix actionqueue being able to spam weapon alts
ACTIONS.CASTAOE.validfn = function(act)
    return (act.doer and act.invobject and act.invobject.components.rechargeable and act.invobject.components.rechargeable:IsReady())
end

_oldLookAtFN = ACTIONS.LOOKAT.fn
ACTIONS.LOOKAT.fn = function(act)
    local target = act.target or act.invobject
    local player = act.doer
    if player == _G.ThePlayer and player.HUD.controls.target_badge then
        player.HUD.controls.target_badge:SetTarget(target ~= nil and target.replica.health and not _G.COMMON_FNS.IsAlly(player, target) and target)
    end

    return _oldLookAtFN(act)
end
