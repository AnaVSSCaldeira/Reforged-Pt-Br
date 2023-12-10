require("stategraphs/commonforgestates")

local events = {
	CommonHandlers.OnAttack(),
	CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
	CommonForgeHandlers.OnSleep(),
	CommonHandlers.OnLocomote(true,false),
	CommonForgeHandlers.OnFreeze(),
	EventHandler("updatepetmastery", function(inst, data)
        if not inst.components.health:IsDead() then
    		if data and data.level > 0 then
    			inst.sg:GoToState("buff", data)
    		else
    			inst.sg:GoToState("debuff", data)
    		end
        end
	end),
}

local states = {
	State{
        name = "buff",
        tags = { "busy" },

        onenter = function(inst, data)
            inst.Physics:Stop()
            if data and data.level then
				inst:UpdatePetLevel(data.level, data.force) -- TODO push event for this? klei pushes event in abby so maybe?
			end
			inst.AnimState:PlayAnimation("transform_pre")
            local fx = SpawnPrefab("merm_splash")
            inst.SoundEmitter:PlaySound("dontstarve/characters/wurt/merm/buff")
            fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        end,

        timeline = {
            TimeEvent(9*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(inst.sounds.buff)
            end),
        },

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "debuff",
        tags = { "busy" },

        onenter = function(inst, data)
            inst.Physics:Stop()
            if data and data.level then
				inst:UpdatePetLevel(data.level, data.force) -- TODO push event for this? klei pushes event in abby so maybe?
			end
            inst.AnimState:PlayAnimation("debuff")
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
}

CommonStates.AddIdle(states)
CommonStates.AddCombatStates(states, {
    attacktimeline = {
        TimeEvent(0, function(inst)
        	inst.SoundEmitter:PlaySound(inst.sounds.attack)
        end),
        TimeEvent(0, function(inst)
        	inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
        end),
        TimeEvent(20*FRAMES, function(inst)
        	inst.components.combat:DoAttack()
        end),
    },
    hittimeline = {
        TimeEvent(0, function(inst)
        	inst.SoundEmitter:PlaySound(inst.sounds.hit)
        end),
    },
    deathtimeline = {
        TimeEvent(0*FRAMES, function(inst)
        	inst.SoundEmitter:PlaySound(inst.sounds.death)
        end),
    },
})
CommonStates.AddWalkStates(states, {
	walktimeline = {
		TimeEvent(0, PlayFootstep),
		TimeEvent(12*FRAMES, PlayFootstep),
	},
})
CommonStates.AddRunStates(states, {
	runtimeline = {
		TimeEvent(0, PlayFootstep),
		TimeEvent(10*FRAMES, PlayFootstep),
	},
})
CommonStates.AddSleepStates(states, {
	sleeptimeline = {
		TimeEvent(35*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.sleep)
		end),
	},
})
CommonStates.AddFrozenStates(states)
CommonStates.AddHopStates(states, true, {pre = "boat_jump_pre", loop = "boat_jump_loop", pst = "boat_jump_pst"})

return StateGraph("merm_guard_reforged", states, events, "idle")
