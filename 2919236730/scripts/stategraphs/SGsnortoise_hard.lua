local snortoise_sg = deepcopy(require "stategraphs/SGsnortoise")
snortoise_sg.name = "snortoise_hard"
local tuning_values = TUNING.FORGE.SNORTOISE

----------
-- Spin -- Snortoise will trigger Spin for all nearby Snortoise. They will circle their target attacking in turns.
----------
local MAX_DASHES = 3
local attack_spin_state = snortoise_sg.states.attack_spin
local _oldSpinOnEnter = attack_spin_state.onenter
attack_spin_state.onenter = function(inst, data)
    _oldSpinOnEnter(inst, data)
    if not inst.components.teamattacker.inteam and not inst.components.teamattacker:SearchForTeam(true) then
        local leader = SpawnPrefab("teamleader")
        leader.components.teamleader.min_team_size = 1
        leader.components.teamleader.orig_radius = 5
        leader.components.teamleader.radius = 5
        leader.components.teamleader.orig_thetaincrement = 3
        leader.components.teamleader.thetaincrement = 3
        leader.components.teamleader.maxteam = 3
        leader.components.teamleader.duration = 30
        leader.components.teamleader.attack_target = false
        leader.components.teamleader:SetOnNewTeammateFN(function(member)
            --if not leader.components.teamleader:IsTeamFull() and not member.sg:HasStateTag("spinning") then
            if not member.sg:HasStateTag("spinning") then
                member.sg:GoToState("attack_spin")
            end
            leader.components.teamleader.inst:RemoveEventCallback("attacked", member.attackedfn, member)
        end)
        leader.components.teamleader:SetOnLostTeammateFN(function(member, changing_team)
            if not changing_team and inst.sg:HasStateTag("spinning") then
                member.sg:GoToState("attack_spin_stop")
            end
        end)
        leader.components.teamleader:SetUp(inst.sg.statemem.target, inst)
        leader.components.teamleader:BroadcastDistress(inst)
    end
end

local attack_spin_loop_state = snortoise_sg.states.attack_spin_loop
attack_spin_loop_state.tags.busy = nil -- this prevents movement
attack_spin_loop_state.tags.moving = true -- TODO check these tags to see if they are all needed
attack_spin_loop_state.tags.running = true
attack_spin_loop_state.tags.canrotate = true
local _oldSpinLoopOnEnter = attack_spin_state.onenter
attack_spin_loop_state.onenter = function(inst, data)
    --_oldSpinLoopOnEnter(inst, data)
    inst.components.health:SetAbsorptionAmount(1)
    ToggleOffCharacterCollisions(inst)
    inst.components.combat:StartAttack() -- TODO should this be on every attack order?
    inst.AnimState:PlayAnimation("attack2_loop")
    if inst.SoundEmitter:PlayingSound("shell_loop") then
        inst.SoundEmitter:KillSound("shell_loop")
    end
    inst.SoundEmitter:PlaySound(inst.sounds.attack2_LP, "shell_loop")
    inst.components.combat.battlecryenabled = false
end

local attack_spin_stop_forced = snortoise_sg.states.attack_spin_stop_forced
local _oldattackspinstop_forced = attack_spin_stop_forced.onexit
attack_spin_stop_forced.onexit = function(inst, data)
	_oldattackspinstop_forced(inst)
	inst.components.combat.battlecryenabled = true
	if inst.components.teamattacker.inteam then
        inst.components.teamattacker:LeaveTeam()
    end
end

local _oldSpinLoopOnUpdate = attack_spin_loop_state.onupdate
attack_spin_loop_state.onupdate = function(inst, data)
    --_oldSpinLoopOnUpdate(inst, data)
    inst.components.locomotor:RunForward()
    if inst.sg.mem.sleep_duration then
        inst.sg.statemem.end_spin = true
    end
end

local _oldSpinLoopOnExit = attack_spin_loop_state.onexit
attack_spin_loop_state.onexit = function(inst)
    _oldSpinLoopOnExit(inst)
    inst.components.combat.battlecryenabled = true
    if inst.components.teamattacker.inteam then
        inst.components.teamattacker:LeaveTeam()
    end
end

local _oldLocomoteFN = snortoise_sg.events.locomote.fn
snortoise_sg.events.locomote.fn = function(inst)
    if not inst.sg:HasStateTag("spinning") then
        _oldLocomoteFN(inst)
    end
end

COMMON_FNS.ApplyStategraphPostInits(snortoise_sg)
return snortoise_sg
