local crocommander_sg = deepcopy(require "stategraphs/SGcrocommander")
crocommander_sg.name = "crocommander_hard"
local tuning_values = TUNING.FORGE.CROCOMMANDER

---------------------------
-- Update Attack Pattern -- Crocommander now calls for reinforcements when taunting if it is available.
---------------------------
local _oldReinforcements = crocommander_sg.events.reinforcements.fn
crocommander_sg.events.reinforcements.fn = function(inst, data)
    if inst.components.combat:IsAttackReady("reinforcements") and not inst.components.health:IsDead() then
        inst.sg:GoToState("build")
    else
        _oldReinforcements(inst, data)
    end
end

-----------
-- Build -- Crocommander can now summon reinforcements and banners during taunts
-----------
local REINFORCEMENTS_CD = 30 -- TODO adjust
local build_state = crocommander_sg.states.build
local banner_fn = build_state.timeline[2].fn
local banner_time = build_state.timeline[2].time
build_state.timeline[2] = TimeEvent(banner_time, function(inst, data)
    if inst.reinforcements.isready_fn(inst) then -- TODO need reinforcement message to appear at top so group knows
        TheWorld.components.lavaarenaevent:QueueWave(nil, true, inst.reinforcements.wave, inst) -- TODO should this be an event pushed instead of a function call?
        inst.components.combat:StartCooldown("reinforcements")
    end
    if inst.components.combat:IsAttackReady("banner") then
        banner_fn(inst)
    end
end)

COMMON_FNS.ApplyStategraphPostInits(crocommander_sg)
return crocommander_sg
