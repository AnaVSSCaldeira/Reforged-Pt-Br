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
    CommonHandlers.OnSleep(),
	CommonHandlers.OnLocomote(true,false),
	EventHandler("updatepetmastery", function(inst, data)
		inst.sg:GoToState("taunt", data)
	end),
}

local states = {
    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        ontimeout = function(inst) -- TODO understand when this is called, might be what we need for all mobs?
            inst.sg:GoToState("taunt")
        end,

        onenter = function(inst, start_anim)
            inst.Physics:Stop()
            local animname = "idle"
            if math.random() < .3 then
                inst.sg:SetTimeout(math.random()*2 + 2)
            end

            if start_anim then
                inst.AnimState:PlayAnimation(start_anim)
                inst.AnimState:PushAnimation("idle", true)
            else
                inst.AnimState:PlayAnimation("idle", true)
            end
        end,
    },

    State{ -- TODO possibly use commonforgestates
        name = "taunt",
        tags = {"busy"},

        onenter = function(inst, data)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
            inst.SoundEmitter:PlaySound(inst.sounds.scream)
			if data and data.level then
				inst:UpdatePetLevel(data.level, data.force) -- TODO push event for this? klei pushes event in abby so maybe?
			end
        end,

        events = {
            EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
        },
    },
}

CommonStates.AddRunStates(states, {
	starttimeline = {
		TimeEvent(3*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.walk)
		end),
	},
	runtimeline = {
		TimeEvent(0, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.walk)
		end),
		TimeEvent(3*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.walk)
		end),
		TimeEvent(7*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.walk)
		end),
		TimeEvent(12*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.walk)
		end),
	},
},{ -- Spiders seem to use walk anims but use locomotor:RunForward()
	startrun = "walk_pre",
	run = "walk_loop",
	stoprun = "walk_pst",
})
CommonForgeStates.AddCombatStates(states, {
	attacktimeline = {
		TimeEvent(10*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.attack)
			inst.SoundEmitter:PlaySound(inst.sounds.attack_grunt)
		end),
		TimeEvent(25*FRAMES, function(inst)
			inst.components.combat:DoAttack(inst.sg.statemem.target)
		end),
    },
}, nil, nil, {
    onenter_death = function(inst)
        inst.SoundEmitter:PlaySound(inst.sounds.death)
    end,
})
CommonStates.AddSleepStates(states, {
    starttimeline = {
        TimeEvent(0, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.fall_asleep)
		end),
    },
    sleeptimeline = {
        TimeEvent(35*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.sleeping)
		end),
    },
    waketimeline = {
        TimeEvent(0, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.wake_up)
		end),
    },
})

return StateGraph("babyspider", states, events, "idle") -- TODO default state taunt?
