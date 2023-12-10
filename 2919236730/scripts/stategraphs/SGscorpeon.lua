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
		if not inst.components.health:IsDead() and (inst.sg:HasStateTag("hit") or not inst.sg:HasStateTag("busy")) then
			if inst.components.combat:IsAttackReady("spit") then
				inst.sg:GoToState("attack_spit", data.target)
			else
				inst.sg:GoToState("attack", data.target)
			end
		end
	end),
}

-- Creates the Acid Spit projectile and launches it to the targets position.
local function AcidSpit(inst)
    local target = inst.components.combat.target
    if target then
    	local x, y, z = inst.Transform:GetWorldPosition()
    	local angle = -inst:GetAngleToPoint(target:GetPosition():Get()) * DEGREES
    	local offset = 4.25 -- TODO tuning???
    	local target_pos = Point(x + (offset * math.cos(angle)), 0, z + (offset * math.sin(angle)))
    	local spit = SpawnPrefab("scorpeon_projectile")
    	spit.Transform:SetPosition(inst:GetPosition():Get())
    	spit.thrower = inst
    	spit.components.complexprojectile:Launch(target_pos, inst)
    end
end

local states = {
	State{
        name = "attack_spit",
        tags = {"attack", "busy", "pre_attack"},

        onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.components.combat:StartAttack()
			inst.AnimState:PlayAnimation("attack_pre")
            inst.AnimState:PushAnimation("spit", false)
        end,

        onexit = function(inst)
            inst.components.combat:StartCooldown("spit")
        end,

        timeline = {
			TimeEvent(0, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.grunt)
			end),
            TimeEvent(12*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(inst.sounds.taunt)
            end),
            TimeEvent(15*FRAMES, function(inst)
				AcidSpit(inst)
                inst.SoundEmitter:PlaySound(inst.sounds.spit)
                inst.sg:RemoveStateTag("pre_attack")
            end),
			TimeEvent(17*FRAMES, function(inst) -- TODO is this correct?
				inst.sg:RemoveStateTag("busy") --TODO: Check other mob's attack states to see if they can be ended early like this.
				inst.sg:RemoveStateTag("attack")
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
		TimeEvent(1*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
		TimeEvent(8*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
		TimeEvent(12*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
		TimeEvent(15*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
		TimeEvent(20*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
		TimeEvent(25*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
		TimeEvent(30*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
		TimeEvent(36*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
		TimeEvent(44*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
	},
})
CommonForgeStates.AddSleepStates(states, {
	starttimeline = {
		TimeEvent(0, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.taunt)
		end),
		TimeEvent(45*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
		end),
	},
	sleeptimeline = {
		TimeEvent(0, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.sleep_in)
		end),
		TimeEvent(20*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.sleep_out)
		end),
    },
	waketimeline = {
		TimeEvent(1*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
	},
})
CommonForgeStates.AddCombatStates(states, {
    attacktimeline = {
		TimeEvent(12*FRAMES, function(inst)
				if inst.components.combat.target then
					inst:ForceFacePoint(inst.components.combat.target:GetPosition())
				end
			end),
		TimeEvent(12*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.attack)
		end),
		TimeEvent(15*FRAMES, function(inst)
			inst.components.combat:DoAttack()
            inst.sg:RemoveStateTag("pre_attack")
		end),
		TimeEvent(17*FRAMES, function(inst)
			inst.sg:RemoveStateTag("busy") --TODO: Check other mob's attack states to see if they can be ended early like this.
			inst.sg:RemoveStateTag("attack")
		end),
    },
    deathtimeline = {
        TimeEvent(0, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.death)
        end),
		TimeEvent(5*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.bodyfall)
		end),
    },
},{
    attack = "attack_pre",
}, nil, {
    onenter_attack = function(inst)
        inst.SoundEmitter:PlaySound(inst.sounds.grunt)
        inst.AnimState:PushAnimation("attack", false)
    end,
    onenter_death = function(inst)
        inst.SoundEmitter:PlaySound(inst.sounds.death)
    end,
})

local taunt_timeline = {
	TimeEvent(0, function(inst)
		inst.SoundEmitter:PlaySound(inst.sounds.taunt)
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
})
--CommonStates.AddFrozenStates(states)
CommonForgeStates.AddFossilizedStates(states)
CommonForgeStates.AddTimeLockStates(states)

return StateGraph("scorpeon", states, events, "spawn")
