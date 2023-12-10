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
local tuning_values = TUNING.FORGE.PITPIG

local function DashCondition(inst)
    return inst and not inst.components.health:IsDead() and inst.sg.mem.dashing
end

local function DashAOE(inst)
    COMMON_FNS.DoAOE(inst, nil, tuning_values.DASH_DAMAGE, {offset = 1, range = 2, invulnerability_time = 1}) -- TODO tuning, adjust range values
end

local events = {
    CommonForgeHandlers.OnAttacked(),
	CommonForgeHandlers.OnKnockback(),
	CommonHandlers.OnDeath(),
    CommonForgeHandlers.OnSleep(),
    CommonHandlers.OnLocomote(true,false),
    CommonForgeHandlers.OnFreeze(),
	CommonForgeHandlers.OnFossilize(),
	CommonForgeHandlers.OnTimeLock(),
	EventHandler("doattack", function(inst, data)
		if not inst.components.health:IsDead() and (not (inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("hit")) or inst.sg:HasStateTag("canattack")) then -- TODO what is canattack??? create CommonForgeHandlers for "canattack" if needed
            if inst.components.combat:IsAttackReady("dash") and data.target and data.target:IsValid() and math.sqrt(inst:GetDistanceSqToInst(data.target)) > inst.components.combat:GetAttackRange() then
			    inst.sg:GoToState("attack_dash", data.target)
            else
                inst.sg:GoToState("attack", data.target)
            end
		end
	end),
}

local states = {
	State{
        name = "attack", -- TODO revert back to using combat common state if the event handler goes back to default
        tags = {"attack", "busy", "pre_attack"},

		 onenter = function(inst, target)
			inst.components.combat:StartAttack()
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("attack1")
		end,

		timeline = {
			TimeEvent(6*FRAMES, function(inst)
				if inst.components.combat.target then
					inst:ForceFacePoint(inst.components.combat.target:GetPosition())
				end
			end),
			TimeEvent(12*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boaron/attack_1")
			end),
            TimeEvent(12*FRAMES, function(inst)
				inst.components.combat:DoAttack(inst.components.combat.target)
                inst.sg:RemoveStateTag("pre_attack")
			end),
		},

        events = {
            EventHandler("animqueueover", function(inst)
					inst.sg:GoToState("idle")
			end),
        },
    },

	State {
        name = "attack_dash",
        tags = {"attack", "busy", "keepmoving", "pre_attack"},

		onenter = function(inst, target)
			inst.Transform:SetEightFaced()
            inst.components.combat:SetRange(tuning_values.ATTACK_RANGE, tuning_values.HIT_RANGE) -- Reset Attack Range
            inst.components.combat:StartAttack()
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("attack2")
        end,

        onexit = function(inst)
			inst.sg.mem.dashing = false
            inst.components.combat:StartCooldown("dash")
			inst.Transform:SetSixFaced()
        end,

        timeline = {
            TimeEvent(10*FRAMES, function(inst)
                if inst.components.combat.target then
                    inst:ForceFacePoint(inst.components.combat.target:GetPosition()) -- TODO angle it to one side slightly?
                end
            end),
            TimeEvent(18*FRAMES, function(inst)
				inst.sg.mem.dashing = true
                inst.Physics:SetMotorVel(35, 0, 0)
                inst.sg:RemoveStateTag("pre_attack")
                CreateConditionThread(inst, "attack_dash_aoe", 0, FRAMES, DashCondition, DashAOE)
            end),
            TimeEvent(20*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.attack_2)
            end),
            TimeEvent(26*FRAMES, function(inst)
				inst.sg.mem.dashing = false
                inst.Physics:ClearMotorVelOverride()
                inst.components.locomotor:Stop()
            end),
        },

        events = {
            EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
			end),
        },
    },
}

CommonForgeStates.AddIdle(states)
CommonStates.AddRunStates(states, {
	runtimeline = {
		TimeEvent(0, PlayFootstep),
	},
})
CommonForgeStates.AddSleepStates(states, {
	sleeptimeline = {
		TimeEvent(0, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.sleep)
		end),
		TimeEvent(20*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.sleep)
		end),
    },
})
CommonForgeStates.AddHitState(states)
CommonForgeStates.AddDeathState(states, nil, nil, nil, {
    onenter = function(inst)
		inst.SoundEmitter:PlaySound(inst.sounds.death)
    end,
})
local taunt_timeline = {
	TimeEvent(6*FRAMES, function(inst)
		if inst.sg:HasStateTag("taunting") then --Leo: Pitpigs do not move in the spawn state
			local dir = (math.random(1,2)*2)-3
			local speed = math.random(2,3)
			inst.Physics:SetMotorVel(speed * dir, 0, speed * dir)
			--inst.components.combat:ResetBattleCryCooldown() -- TODO this happens inside BattleCry, why was this needed?
		end
	end),
	TimeEvent(10*FRAMES, function(inst)
		inst.SoundEmitter:PlaySound(inst.sounds.taunt)
	end),
	TimeEvent(18*FRAMES, function(inst)
		inst.Physics:ClearMotorVelOverride()
		inst.components.locomotor:Stop()
	end),
}
CommonForgeStates.AddTauntState(states, taunt_timeline)
CommonForgeStates.AddSpawnState(states, taunt_timeline, nil, nil, {
	onexit = function(inst)
		--pitpig applies dashcooldown in onexit of spawn state
        inst.components.combat:StartCooldown("dash")
	end,
})
CommonForgeStates.AddKnockbackState(states)
CommonForgeStates.AddStunStates(states)
--CommonStates.AddFrozenStates(states) -- TODO should we add these? --Leo: We'll need to make a custom freezeoverride or a unique freeze fx, but yes, we should.
CommonForgeStates.AddFossilizedStates(states)
CommonForgeStates.AddTimeLockStates(states)

return StateGraph("pitpig", states, events, "spawn")
