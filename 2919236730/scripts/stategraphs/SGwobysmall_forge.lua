require("stategraphs/commonstates")
local tuning_values = TUNING.FORGE.WOBY

local actionhandlers =
{
}

local events =
{
    CommonHandlers.OnSleepEx(),
    CommonHandlers.OnWakeEx(),
    CommonHandlers.OnLocomote(false,true),
    CommonHandlers.OnHop(),
	CommonHandlers.OnSink(),

	EventHandler("transform", function(inst, data)
		if inst.sg.currentstate.name ~= "transform" then
			inst.sg:GoToState("transform")
		end
	end),
}

local states =
{
	State{
        name="idle",
        tags = {"idle"},

        onenter = function(inst, data)
			if inst.buff_ready then
				inst.sg:GoToState("buff_ready_pre")
			end
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("idle_loop")
        end,

        -- timeline =
        -- {

        -- },

		events =
		{
			EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
					inst.sg:GoToState(inst.buff_ready and "buff_ready_pre" or "idle")
				end
			end)
		},
    },

	State{
        name="emote_pet", --Woby get sent to this when pet, so run any pet related things here.
        tags = {"busy"},

		onenter = function(inst)
			if inst.buff_ready then
				inst:BuffAllies()
			end
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("emote_pet")
		end,

		timeline = {
			TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.tail) end),
			TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.tail) end),
			TimeEvent(16*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.tail) end),
			TimeEvent(24*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.tail) end),
		},

		events =
		{
			EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
				end
			end)
		},

		-- onexit = function(inst)

		-- end,
    },

	State{
        name = "buff_ready_pre",
        tags = {"idle"},

        onenter = function(inst, pushanim)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("emote_combat_pre")
        end,

		timeline = {
			TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.bark) end),
		},

        events =
		{
			EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
					inst.sg:GoToState(inst.buff_ready and "buff_ready" or "idle")
				end
			end)
		},
    },

	State{
        name = "buff_ready",
        tags = {"idle"},

        onenter = function(inst, pushanim)
            inst.components.locomotor:StopMoving()
			inst.AnimState:PlayAnimation("emote_combat_loop")
        end,

		timeline = {
			TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.bark) end),
			TimeEvent(26*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.pant) end),
			TimeEvent(34*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.pant) end),
			TimeEvent(48*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.bark) end),
		},

        events =
		{
			EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
					inst.sg:GoToState(inst.buff_ready and "buff_ready" or "idle")
				end
			end)
		},
    },

}

CommonStates.AddWalkStates(states,
	{
		starttimeline =
		{
			TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.pant) end), --TODO if this is frame 0 it causes a crash because inst.sounds isn't getting set fast enough???
			TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.pant) end),
		},
		walktimeline =
		{
			TimeEvent(1*FRAMES, function(inst) PlayFootstep(inst, 0.25) end),
			TimeEvent(4*FRAMES, function(inst) PlayFootstep(inst, 0.25) end),
		},
	})
CommonStates.AddSleepExStates(states,
	{
		starttimeline =
		{
			TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.growl) end),
		},
		sleeptimeline =
		{
			TimeEvent(14*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.sleep) end),
		},
	})


CommonStates.AddHopStates(states, true)
CommonStates.AddSinkAndWashAsoreStates(states)

return StateGraph("SGforge_woby", states, events, "idle", actionhandlers)
