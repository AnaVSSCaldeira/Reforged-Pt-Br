local pitpig_sg = deepcopy(require "stategraphs/SGpitpig")
pitpig_sg.name = "pitpig_hard"
local tuning_values = TUNING.FORGE.PITPIG

----------
-- Dash -- Pitpig will continue to dash if a target is hit up to a max of 3 dashes.
----------
local MAX_DASHES = 3
local attack_dash_state = pitpig_sg.states.attack_dash
local _oldOnEnter = attack_dash_state.onenter
attack_dash_state.onenter = function(inst, data)
    _oldOnEnter(inst, data)
    ToggleOffCharacterCollisions(inst)
    inst.sg.statemem.dash_count = (data.dash_count or 0) + 1
end
attack_dash_state.events.animqueueover.fn = function(inst)
    if inst.sg.statemem.dash_count >= MAX_DASHES or not inst.sg.statemem.target_hit then
        inst.sg:GoToState("idle")
    else
        inst.sg:GoToState("attack_dash", {dash_count = inst.sg.statemem.dash_count})
    end
end
local _oldOnExit = attack_dash_state.onexit
attack_dash_state.onexit = function(inst)
    _oldOnExit(inst)
    ToggleOnCharacterCollisions(inst)
end
attack_dash_state.events.onhitother = EventHandler("onhitother", function(inst)
    inst.sg.statemem.target_hit = true
end)

COMMON_FNS.ApplyStategraphPostInits(pitpig_sg)
return pitpig_sg
