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
    CommonHandlers.OnAttack(),
	CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
}

local states = {
	State{
		name = "spawn",
        tags = {"busy"},

        onenter = function(inst, cb)
            inst:AddTag("notarget")
			inst.Physics:Stop()
            inst.AnimState:PlayAnimation("spawn")
			inst.SoundEmitter:PlaySound("dontstarve/common/lava_arena/spell/elemental/enter")
            if inst.Physics:GetCollisionGroup() == COLLISION.CHARACTERS then
                ToggleOffCharacterCollisions(inst)
            end
        end,

		timeline = {
			TimeEvent(0*FRAMES, function(inst) --made this a timeline thing because onenter is done right on spawn where Launchitems doesn't work.
                COMMON_FNS.LaunchItems(inst, 2)
            end)
		},

        onexit = function(inst)
            if inst.Physics:GetCollisionGroup() == COLLISION.CHARACTERS then
                ToggleOnCharacterCollisions(inst)
            end
        end,

        events = {
			EventHandler("animover", function(inst)
				inst:RemoveTag("notarget")
				inst.sg:GoToState("idle")
			end),
        },
    },
}

CommonStates.AddIdle(states, nil, "idle", {
	TimeEvent(0, function(inst)
        if inst.SoundEmitter:PlayingSound("idle_LP") then
            inst.SoundEmitter:KillSound("idle_LP")
        end
        inst.SoundEmitter:PlaySound(inst.sounds.idle, "idle_LP")
	end),
})
CommonStates.AddCombatStates(states, {
    attacktimeline = {
        TimeEvent(5*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.attack)
			inst.components.combat:DoAttack(inst.components.combat.target)
		end),
        TimeEvent(16*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.attack)
			inst.components.combat:DoAttack(inst.components.combat.target)
		end),
    },
    deathtimeline = {
        TimeEvent(0, function(inst)
            RemoveTask(inst.death_timer)
            inst.SoundEmitter:PlaySound(inst.sounds.death)
			inst.SoundEmitter:KillSound("idle_LP")
			if inst.sg.statemem.wants_to_die then
				inst.SoundEmitter:KillSound(inst.sounds.attack)
            end
        end),
		TimeEvent(20*FRAMES, function(inst)
            inst.DynamicShadow:Enable(false)
        end),
    },
},{
    attack = "attack",
})
CommonForgeStates.AddActionState(states, nil, "idle")

return StateGraph("golem", states, events, "spawn")
