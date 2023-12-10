local swineclops_sg = require "stategraphs/SGswineclops"
local tuning_values = TUNING.FORGE.SWINECLOPS

---------------------------
-- Update Attack Pattern --
---------------------------
local _oldDoAttack = swineclops_sg.events.doattack.fn
swineclops_sg.events.doattack.fn = function(inst, data)
    if not inst.components.health:IsDead() and (inst.sg:HasStateTag("hit") or not inst.sg:HasStateTag("busy")) then
        if inst.is_guarding then
            inst.sg:GoToState("jab", data.target)
        else
            if inst.attacks.body_slam and inst.attack_body_slam_ready then
                inst.sg:GoToState("body_slam", data.target)
            else
                inst.sg:GoToState("attack", data.target)
            end
        end
    end
end

----------
-- Idle -- Adds a check to get enraged
----------
--[[local idle_state = swineclops_sg.states.idle
local _oldOnEnter = idle_state.onenter
idle_state.onenter = function(inst, data)
    if inst.sg.mem.wants_to_enrage then -- TODO should this only happen in attack mode?
        inst.sg.mem.wants_to_enrage = nil
        inst.sg:GoToState("enraged_tantrum")
    else
        _oldOnEnter(inst, data)
    end
end--]]

return swineclops_sg
