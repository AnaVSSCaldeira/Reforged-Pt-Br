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
			inst.sg:GoToState("grow", data)
		end
	end),
}

local states = {
	State{
		name = "attack", -- TODO anyway we can use combat batch in commonstates? pushanimation could be placed in 0 FRAMES, but hit can't be used since it needs the custom sound...hmmm
		tags = {"attack", "busy"},

		onenter = function(inst, target)
			inst.sg.statemem.target = target
			inst.Physics:Stop()
			inst.components.combat:StartAttack()
			inst.AnimState:PlayAnimation("atk_pre")
			inst.AnimState:PushAnimation("atk", false)
			inst.AnimState:PushAnimation("atk_pst", false)
		end,

		timeline = {
			TimeEvent(8*FRAMES, function(inst)
				if inst.components.combat.target then
					inst:ForceFacePoint(inst.components.combat.target:GetPosition())
				end
			end),
			TimeEvent(14*FRAMES, function(inst)
				if inst.components.combat.target then
					inst:ForceFacePoint(inst.components.combat.target:GetPosition())
				end
				inst.SoundEmitter:PlaySound(inst:GetSound("attack"))
			end),
			TimeEvent(15*FRAMES, function(inst)
				inst.components.combat:DoAttack(inst.sg.statemem.target)
				if inst.components.combat.target then
					inst:ForceFacePoint(inst.components.combat.target:GetPosition())
				end
			end),
		},

		events = {
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},

	State{
		name = "hit",
		tags = {"busy", "hit"},

		onenter = function(inst, cb)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("hit")
			inst.SoundEmitter:PlaySound(inst:GetSound("breath_out"))
		end,

		events = {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},

	State{
		name = "grow",
		tags = {"busy"},

		onenter = function(inst, data)
			inst.Physics:Stop()
			if data and data.level then
				inst:UpdatePetLevel(data.level, data.force) -- TODO push event for this? klei pushes event in abby so maybe?
			end
			inst.AnimState:PlayAnimation("transform_pre")
		end,

		timeline = {
			TimeEvent(1*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst:GetSound("death_pre"))
			end),
			TimeEvent(5*FRAMES, function(inst)
				inst.components.buffable:AddBuff("pet_level", {{name = "scaler", type = "mult", val = inst.start_scale + inst.inc_scale}})
        		inst.components.scaler:ApplyScale()
			end),
			TimeEvent(10*FRAMES, function(inst)
				inst.components.buffable:AddBuff("pet_level", {{name = "scaler", type = "mult", val = inst.start_scale + inst.inc_scale*2}})
        		inst.components.scaler:ApplyScale()
			end),
			TimeEvent(15*FRAMES, function(inst)
				inst.components.buffable:AddBuff("pet_level", {{name = "scaler", type = "mult", val = inst.start_scale + inst.inc_scale*3}})
        		inst.components.scaler:ApplyScale()
			end),
			TimeEvent(20*FRAMES, function(inst)
				inst.components.buffable:AddBuff("pet_level", {{name = "scaler", type = "mult", val = inst.start_scale + inst.inc_scale*4}})
        		inst.components.scaler:ApplyScale()
			end),
			--[[TimeEvent(25*FRAMES, function(inst) -- TODO anim is not this long, double check and remove this (klei had this in theirs...)
				inst.components.buffable:AddBuff("pet_level", {{name = "scaler", type = "mult", val = inst.start_scale + inst.inc_scale*5}})
        		inst.components.scaler:ApplyScale()
			end),--]]
		},

		onexit = function(inst, target)
			inst.AnimState:SetBuild(inst.build)
		end,

		events = {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle", "transform_pst")
			end),
		},
	},

}

CommonForgeStates.AddIdle(states, nil, "idle", {
	TimeEvent(9*FRAMES, function(inst)
		inst.SoundEmitter:PlaySound(inst:GetSound("breath_out"))
	end),
	TimeEvent(35*FRAMES, function(inst)
		inst.SoundEmitter:PlaySound(inst:GetSound("breath_in"))
	end),
})
CommonForgeStates.AddTauntState(states, {
	TimeEvent(10*FRAMES, function(inst)
		inst.SoundEmitter:PlaySound(inst:GetSound("taunt"))
	end),
})
CommonForgeStates.AddSpawnState(states, {
	TimeEvent(0, function(inst)
		inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/mole/emerge")
		inst.SoundEmitter:PlaySound(inst:GetSound("death_pre"))
	end),
}, "enter", nil, {
	onexit = function(inst)
		if inst.wants_to_become_adult then
			inst:BecomeAdult()
		end
	end,
})
CommonStates.AddDeathState(states, {
    TimeEvent(1*FRAMES, function(inst)
		inst.SoundEmitter:PlaySound(inst:GetSound("death_pre", nil, .5)) -- TODO what are these parameters
	end),
	TimeEvent(13*FRAMES, function(inst)
		inst.SoundEmitter:PlaySound(inst:GetSound("death"))
	end),
})
CommonStates.AddSleepStates(states, {
	starttimeline ={
		TimeEvent(14*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst:GetSound("step"))
		end),
	},
	sleeptimeline = {
		TimeEvent(8*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst:GetSound("breath_in"))
		end),
		TimeEvent(20*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst:GetSound("breath_out"))
		end),
	},
	waketimeline ={
		TimeEvent(5*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst:GetSound("wake")) -- TODO this sound does not exist?
		end),
	},
})
local function GetRunAnim(inst)
	return inst:HasTag("usefastrun") and "run_loop_fast" or "run_loop"
end
CommonStates.AddRunStates(states, {
	runtimeline = {
		---fast
		TimeEvent(5*FRAMES, function(inst)
			if inst:HasTag("usefastrun") then
				inst.SoundEmitter:PlaySound(inst:GetSound("breath_out"))
			end
		end),
		TimeEvent(12*FRAMES, function(inst)
			if inst:HasTag("usefastrun") then
				inst.SoundEmitter:PlaySound(inst:GetSound("step"))
			end
		end),
		---slow
		TimeEvent(19*FRAMES, function(inst)
			if not inst:HasTag("usefastrun") then
				inst.SoundEmitter:PlaySound(inst:GetSound("step"))
			end
		end),
		TimeEvent(7*FRAMES, function(inst)
			if not inst:HasTag("usefastrun") then
				inst.SoundEmitter:PlaySound(inst:GetSound("breath_out"))
			end
		end),
	}
},{
	run = GetRunAnim,
})
CommonStates.AddFrozenStates(states)

return StateGraph("flytrap_reforged", states, events, "spawn")
