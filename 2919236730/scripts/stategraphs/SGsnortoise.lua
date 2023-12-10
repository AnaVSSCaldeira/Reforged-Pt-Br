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
require("stategraphs/commonforgestates")
local tuning_values = TUNING.FORGE.SNORTOISE
local MAX_SPEED = 30 -- TODO adjust?
local ACCELERATION = MAX_SPEED/12 -- TODO how was this determined?
local DISTANCE_BUFFER = 10 -- TODO magic number? Not used anymore, leaving here for reference for Leo if he needs it for adjusting values.
local MAX_SPIN_RAMS = 12 -- TODO tuning?
local MAX_RAM_TIME = 3 -- Ends a Ram if the current Ram has lasted longer than this value.
-----------------------------------------------------
local function ShakeSmall(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, .1, .01, .3, inst, 20)
end

local function SpinningCondition(inst)
    return inst.sg:HasStateTag("spinning")
end

local IMMORTALITY_DURATION = 0.5 -- 0.2 TODO adjust
local function SpinAOE(inst)
    COMMON_FNS.DoAOE(inst, nil, nil, {range = tuning_values.SPIN_HIT_RANGE, invulnerability_time = IMMORTALITY_DURATION})
end

local function EndSpin(inst)
    inst.components.combat:RemoveDamageBuff("spinning") -- TODO is this correct?
end

local function DisableSpinAttack(inst)
	inst.components.combat:StartCooldown("spin")
	inst.components.combat.ignorehitrange = nil
end

local function SpinSetup(inst)
    inst.components.item_launcher:Enable(true)
    inst.components.health:SetAbsorptionAmount(1)
    inst.components.combat:AddDamageBuff("spinning", tuning_values.SPIN_MULT) -- TODO is this correct?
    CreateConditionThread(inst, "attack_spin_aoe", 0, 0.15, SpinningCondition, SpinAOE, EndSpin)
    if inst.Physics:GetCollisionGroup() == COLLISION.CHARACTERS then
        ToggleOffCharacterCollisions(inst)
    end
end

local function SpinRamSetup(inst, target)
    local target = target or inst.components.combat.target
    if target then
        -- Spin Setup
        inst.sg.statemem.spin_state = "accelerating"
        inst.sg.statemem.current_speed = 0
        inst.components.locomotor:Stop()
        -- Calculate Target Position to Spin towards
        local target_pos = target:GetPosition()
        inst:ForceFacePoint(target_pos)
        inst.Physics:SetMotorVel(inst.sg.statemem.current_speed, 0, 0)
        --local offset = (target_pos - inst:GetPosition()):GetNormalized()*5 -- TODO magic number? -- TODO remove when confirmed new spinning method works
        inst.sg.statemem.target_pos = target_pos-- + offset -- TODO remove offset when new spinning method has been confirmed
        inst.sg.statemem.ram_start_time = GetTime()
    -- Queue Spin to End if No Target
    else
        inst.sg.statemem.end_spin = true
    end
end

local function OnSpinComplete(inst)
    inst.components.sleeper:SetResistance(1)
    if inst.Physics:GetCollisionGroup() == COLLISION.CHARACTERS then
        ToggleOnCharacterCollisions(inst)
    end
    inst.components.item_launcher:Enable(false)
    DisableSpinAttack(inst)
end
-----------------------------------------------------
local events = {
	CommonForgeHandlers.OnKnockback(),
	CommonForgeHandlers.OnAttacked(),
	CommonForgeHandlers.OnEnterShield(),
	CommonForgeHandlers.OnExitShield(),
    CommonForgeHandlers.OnSleep(),
    CommonHandlers.OnDeath(),
	CommonHandlers.OnLocomote(false,true),
	CommonForgeHandlers.OnFossilize(),
    CommonForgeHandlers.OnFreeze(),
    CommonForgeHandlers.OnTimeLock(),
	EventHandler("flipped", function(inst, data) -- TODO common handler?
		if not inst.components.health:IsDead() then
			inst.sg:GoToState("flip_start")
			if TheWorld and TheWorld.components.stat_tracker and data.flipper then
				TheWorld.components.stat_tracker:AdjustStat("turtillusflips", data.flipper, 1)
			end
		end
	end),
    EventHandler("doattack", function(inst, data)
		if not inst.components.health:IsDead() and (not inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("hit")) then
			if inst.components.combat:IsAttackReady("spin") then
				inst.sg:GoToState("attack_spin", data.target)
			else
				inst.sg:GoToState("attack", data.target)
			end
		end
	end),
}

local states = {
	State {
        name = "attack_spin",
        tags = {"attack", "busy", "nofreeze", "spinning", "keepmoving"},

		onenter = function(inst, target)
            inst.components.combat:StartAttack()
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("attack2_pre")
            inst.sg.statemem.target = target or inst.components.combat.target
        end,

        timeline = {
			TimeEvent(0, function(inst)
                inst.SoundEmitter:PlaySound(inst.sounds.hide_pre)
			end),
			TimeEvent(13*FRAMES, function(inst)
                inst.sg:AddStateTag("nointerrupt")
            end),
			TimeEvent(20*FRAMES, function(inst) -- TODO spinning starts here, including damage and movement. Maybe just go straight to the attack loop state? Or should we create condition thread here and whatnot?
				inst.SoundEmitter:PlaySound(inst.sounds.shell_impact)
                ShakeSmall(inst)
                SpinSetup(inst)
				--inst.sg:GoToState("attack_spin_loop", {target = inst.sg.statemem.target})
            end),
        },

		onexit = function(inst)
            -- End Spin if not going to the spin loop state.
            if not inst.sg.statemem.spinning then -- TODO is it possible this check fails? as in somehow this variable gets set to true and the snortoise is forced out of state before this is called?
                OnSpinComplete(inst)
            end
            inst.components.health:SetAbsorptionAmount(0)
		end,

        events = {
            EventHandler("animqueueover", function(inst)
                inst.sg.statemem.spinning = true
                inst.sg:GoToState("attack_spin_loop", {target = inst.sg.statemem.target})
            end),
        },
    },

	State {
        name = "attack_spin_loop",
        tags = {"attack", "busy", "nointerrupt", "spinning", "nobuff", "nofreeze", "delaysleep", "keepmoving", "hiding"}, -- TODO nobuff?
		onenter = function(inst, data)
            inst.components.health:SetAbsorptionAmount(1)
            inst.components.debuffable:RemoveDebuff("shield_buff", "shield_buff") -- TODO what is this?
            inst.sg.statemem.ram_attempt = (data and data.ram_attempt or 0) + 1
            if inst.Physics:GetCollisionGroup() == COLLISION.CHARACTERS then
                ToggleOffCharacterCollisions(inst)
            end
            inst.components.combat:StartAttack() -- TODO should this be on every strafe? if so add to SpinRamSetup
            inst.AnimState:PlayAnimation("attack2_loop")
            if inst.SoundEmitter:PlayingSound("shell_loop") then
                inst.SoundEmitter:KillSound("shell_loop")
            end
            inst.SoundEmitter:PlaySound(inst.sounds.attack2_LP, "shell_loop")
            SpinRamSetup(inst, data and data.target)
        end,

        onupdate = function(inst)
            if not inst.sg.statemem.end_spin then
                if inst.sg.statemem.spin_state == "accelerating" then
                    inst.sg.statemem.current_speed = math.min(inst.sg.statemem.current_speed + ACCELERATION, MAX_SPEED)
                    if inst.sg.statemem.current_speed >= MAX_SPEED then
                        inst.sg.statemem.spin_state = "moving" -- TODO better name?
                    end
                elseif inst.sg.statemem.spin_state == "decelerating" then
                    inst.sg.statemem.current_speed = math.max(inst.sg.statemem.current_speed - ACCELERATION, 0)
                    if inst.sg.statemem.current_speed <= 0 then
                        inst.sg.statemem.spin_state = "stopped"
                    end
                elseif inst.sg.statemem.spin_state == "moving" and (math.abs(anglediff(inst:GetAngleToPoint(inst.sg.statemem.target_pos), inst:GetRotation())) >= 90 or GetTime() - inst.sg.statemem.ram_start_time > MAX_RAM_TIME) then
                    inst.sg.statemem.spin_state = "decelerating"
                elseif inst.sg.statemem.spin_state == "stopped" then
                    -- Stop spinning if reached max amount of rams or if sleep is queued
                    if inst.sg.statemem.ram_attempt >= MAX_SPIN_RAMS or inst.sg.mem.sleep_duration then
                        inst.sg.statemem.end_spin = true
                    else
                        inst.sg.statemem.ram_attempt = inst.sg.statemem.ram_attempt + 1
                        SpinRamSetup(inst)
                    end
                end
                inst.Physics:SetMotorVel(inst.sg.statemem.current_speed, 0, 0)
            end
        end,

        onexit = function(inst)
            inst.SoundEmitter:KillSound("shell_loop")
            OnSpinComplete(inst)
            inst.components.health:SetAbsorptionAmount(0)
        end,

        timeline = {},

        events = {
			EventHandler("attacked", function(inst)
                inst.SoundEmitter:PlaySound(inst.sounds.shell_impact)
            end),
            EventHandler("animover", function(inst)
                if inst.sg.statemem.end_spin then
                    inst.sg:GoToState("attack_spin_stop")
                else
                    inst.AnimState:PlayAnimation("attack2_loop")
                end
            end),
        },
    },

	State {
		name = "attack_spin_stop",
        tags = {"busy", "delaysleep", "keepmoving"},

        onenter = function(inst, data)
            inst.components.health:SetAbsorptionAmount(1)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("attack2_pst")
			inst.SoundEmitter:PlaySound(inst.sounds.hide_pst)
        end,

        onexit = function(inst)
            inst.components.health:SetAbsorptionAmount(0)
            DisableSpinAttack(inst)
        end,

		timeline = {
			TimeEvent(11*FRAMES, function(inst)
                inst.components.health:SetAbsorptionAmount(0)
            end),
		},

        events = {
			CommonForgeHandlers.IdleOnAnimOver(),
        },
    },

	State {
		name = "attack_spin_stop_forced", -- TODO better way? go through hit state?
        tags = {"busy"},

        onenter = function(inst, data)
            inst.components.health:SetAbsorptionAmount(1)
            inst.Physics:Stop()
			inst.AnimState:PlayAnimation("hide_hit")
            inst.AnimState:PushAnimation("hide_pst", false)
			inst.SoundEmitter:PlaySound(inst.sounds.shell_impact)
        end,

        onexit = function(inst)
            inst.components.health:SetAbsorptionAmount(0)
            DisableSpinAttack(inst)
        end,

		timeline = {
			TimeEvent(11*FRAMES, function(inst) -- TODO hide hit has this at 10
                inst.SoundEmitter:PlaySound(inst.sounds.hide_pst)
            end),
			TimeEvent(22*FRAMES, function(inst)
                inst.components.health:SetAbsorptionAmount(0)
            end),
        },

        events = {
			CommonForgeHandlers.IdleOnAnimOver(),
        },
    },
}

CommonForgeStates.AddIdle(states)
CommonStates.AddWalkStates(states, {
	walktimeline = {
		TimeEvent(0, function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.shell_walk)
            inst.SoundEmitter:PlaySound(inst.sounds.step)
        end),
        TimeEvent(12*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.shell_walk)
            inst.SoundEmitter:PlaySound(inst.sounds.step)
        end),
	},
})
CommonForgeStates.AddSleepStates(states, {
	starttimeline = {
		TimeEvent(19*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.shell_impact)
		end),
	},
	sleeptimeline = {
		TimeEvent(0, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.sleep)
		end),
    },
	waketimeline = {
		TimeEvent(1*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
	},
},{
	onsleep = function(inst)
        if inst.Physics:GetCollisionGroup() == COLLISION.CHARACTERS then
            ToggleOnCharacterCollisions(inst) --TODO Fixes sliding, find out the real fix
        end
	end,
})
CommonForgeStates.AddCombatStates(states, {
    attacktimeline = {
		TimeEvent(12*FRAMES, function(inst)
            inst.components.combat:DoAreaAttack(inst, inst.components.combat.hitrange, nil, nil, nil, COMMON_FNS.GetAllyTags(inst))
			inst.SoundEmitter:PlaySound(inst.sounds.attack1b)
            inst.sg:RemoveStateTag("pre_attack")
		end),
    },
    deathtimeline = {
		TimeEvent(18*FRAMES, function(inst)
			ShakeSmall(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.death)
		end),
    },
},{
    attack = "attack1",
}, nil, {
    onenter_attack = function(inst)
        inst.SoundEmitter:PlaySound(inst.sounds.attack_pre)
        inst.SoundEmitter:PlaySound(inst.sounds.attack1a)
    end,
})
local taunt_timeline = {
	TimeEvent(0, function(inst)
        inst.should_taunt = false -- TODO what uses this?
    end),
    TimeEvent(10*FRAMES, function(inst)
		-- TODO screenshakes here
		inst.SoundEmitter:PlaySound(inst.sounds.taunt)
        ShakeSmall(inst)
	end),
}
CommonForgeStates.AddTauntState(states, taunt_timeline)
CommonForgeStates.AddSpawnState(states, taunt_timeline)
CommonForgeStates.AddKnockbackState(states)
CommonForgeStates.AddStunStates(states, {
	stuntimeline = {
		TimeEvent(5*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.stun)
		end),
		TimeEvent(10*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.stun)
		end),
		TimeEvent(15*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.stun)
		end),
		TimeEvent(20*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.stun)
		end),
		TimeEvent(25*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.stun)
		end),
		TimeEvent(30*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.stun)
		end),
		TimeEvent(35*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.stun)
		end),
		TimeEvent(40*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.stun)
		end),
	},
	endtimeline = {
		TimeEvent(4*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
			ShakeSmall(inst)
		end),
	},
}, nil, nil, {
    onstun = function(inst)
        inst.components.health:SetAbsorptionAmount(0)
    end,
})
CommonForgeStates.AddFlipStates(states, TUNING.FORGE.SNORTOISE.FLIP_TIME, {
    starttimeline = {
        TimeEvent(10*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.shell_walk)
			ShakeSmall(inst)
            --inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_mech_med_sharp")
        end),
    },
    fliptimeline = {
        TimeEvent(0*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.grunt)
        end),
    },
    endtimeline = {
		TimeEvent(15*FRAMES, function(inst)
			if inst.sg.statemem.flip_interrupted then -- TODO correct?
				inst.SoundEmitter:PlaySound(inst.sounds.shell_walk)
				inst.SoundEmitter:PlaySound(inst.sounds.step)
				ShakeSmall(inst)
			end
        end),
        TimeEvent(45*FRAMES, function(inst)
			if not inst.sg.statemem.flip_interrupted then -- TODO correct?
				inst.SoundEmitter:PlaySound(inst.sounds.shell_walk)
				inst.SoundEmitter:PlaySound(inst.sounds.step)
				ShakeSmall(inst)
			end
        end),
    },
    hittimeline = {
        TimeEvent(10*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.hide_pst) -- TODO change name, hide_pst to stop_hiding?
        end),
    },
}, nil, {
    onflipstop = function(inst, attacker)
        if attacker then
			inst.sg.statemem.flip_interrupted = true -- TODO better way?
            inst.AnimState:SetTime(30*FRAMES) -- TODO is this correct?
        end
    end,
},{
	flipstop = function(inst)
		if inst.sg.statemem.flip_interrupted then
			inst.sg.statemem.flip_interrupted = nil
		end
	end,
})
CommonForgeStates.AddHideStates(states, {
    starttimeline = {
        TimeEvent(5*FRAMES, function(inst)
            inst.sg:AddStateTag("nointerrupt")
            inst.components.health:SetAbsorptionAmount(1)
        end),
        TimeEvent(10*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.hide_pre) -- TODO change name, hide_pre to start_hiding?
            --inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_mech_med_sharp")
        end),
    },
    endtimeline = {
        TimeEvent(10*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.hide_pst) -- TODO change name, hide_pst to stop_hiding?
        end),
    },
},{
	hideloop = "hide_idle",
})
CommonForgeStates.AddActionState(states, nil, "walk_pst") -- TODO what is this?
--CommonStates.AddFrozenStates(states)
CommonForgeStates.AddFossilizedStates(states)
CommonForgeStates.AddTimeLockStates(states)

return StateGraph("snortoise", states, events, "spawn")
