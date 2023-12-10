require("stategraphs/commonforgestates")
local tuning_values = TUNING.FORGE.ADULT_FLYTRAP

local events = {
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
}

local states = {
    State{
        name = "attack", -- TODO possibly use combat commonstate?
        tags = {"attack", "busy"},

        onenter = function(inst, target)
            inst.sg.statemem.target = target or inst.components.combat.target -- TODO somehow target was nil
            inst.sg.statemem.target_pos = inst.sg.statemem.target and inst.sg.statemem.target:GetPosition()
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk_pre")
            inst.AnimState:PushAnimation("atk", false)
            inst.AnimState:PushAnimation("atk_pst", false)
        end,

        timeline = {
            TimeEvent(5*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(inst.sounds.attack_pre)
            end),
            TimeEvent(8*FRAMES, function(inst)
                inst.sg.statemem.target_pos = inst.sg.statemem.target and inst.sg.statemem.target:GetPosition() or inst.sg.statemem.target_pos
                inst:ForceFacePoint(inst.sg.statemem.target_pos)
            end),
            TimeEvent(14*FRAMES, function(inst)
                inst.sg.statemem.target_pos = inst.sg.statemem.target and inst.sg.statemem.target:GetPosition() or inst.sg.statemem.target_pos
                inst:ForceFacePoint(inst.sg.statemem.target_pos)
                inst.SoundEmitter:PlaySound(inst.sounds.attack)
            end),
            TimeEvent(15*FRAMES, function(inst)
                inst.sg.statemem.target_pos = inst.sg.statemem.target and inst.sg.statemem.target:GetPosition() or inst.sg.statemem.target_pos
                COMMON_FNS.DoAOE(inst, nil, tuning_values.DAMAGE, {range = tuning_values.ATTACK_RADIUS, stimuli = tuning_values.STIMULI, target_pos = inst.sg.statemem.target_pos})
                inst:ForceFacePoint(inst.sg.statemem.target_pos)
            end),
        },

        events = {
            EventHandler("animqueueover", function(inst)
                if inst.components.combat.target and math.random()<0.3 then
                    inst.sg:GoToState("taunt")
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "hit",
        tags = {"busy", "hit"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("hit")
            inst.SoundEmitter:PlaySound(inst.sounds.breath_out)
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("attack")
            end),
        },
    },

    State{
        name = "grow", -- TODO leaving the grow states here for now until we figure out the spawning anim stuff...
        tags = {"busy"},

        onenter = function(inst, target)
            inst.Physics:Stop()
            inst.SoundEmitter:PlaySound(inst.sounds.breath_out)
            inst.SoundEmitter:PlaySound(inst.sounds.death_pre)
            inst.AnimState:PlayAnimation("transform_pre")
        end,

        timeline = {
            TimeEvent(5*FRAMES, function(inst)
                inst.components.buffable:AddBuff("transform", {{name = "scaler", type = "mult", val = inst.start_scale + inst.inc_scale}})
                inst.components.scaler:ApplyScale()
            end),
            TimeEvent(10*FRAMES, function(inst)
                inst.components.buffable:AddBuff("transform", {{name = "scaler", type = "mult", val = inst.start_scale + inst.inc_scale*2}})
                inst.components.scaler:ApplyScale()
            end),
            TimeEvent(15*FRAMES, function(inst)
                inst.components.buffable:AddBuff("transform", {{name = "scaler", type = "mult", val = inst.start_scale + inst.inc_scale*3}})
                inst.components.scaler:ApplyScale()
            end),
            TimeEvent(20*FRAMES, function(inst)
                inst.components.buffable:AddBuff("transform", {{name = "scaler", type = "mult", val = inst.start_scale + inst.inc_scale*4}})
                inst.components.scaler:ApplyScale()
            end),
            --[[TimeEvent(25*FRAMES, function(inst) TODO anim isn't this long, double check and remove this (klei had it...)
                inst.components.buffable:AddBuff("transform", {{name = "scaler", type = "mult", val = inst.start_scale + inst.inc_scale*5}})
                inst.components.scaler:ApplyScale()
            end),--]]
        },

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("grow_pst")
            end),
        },
    },

    State{
        name = "grow_pst",
        tags = {"busy"},

        onenter = function(inst, target)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("transform_pst")
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
}

CommonForgeStates.AddIdle(states, nil, "idle", {
    TimeEvent(9*FRAMES, function(inst)
        inst.SoundEmitter:PlaySound(inst.sounds.breath_out)
    end),
    TimeEvent(35*FRAMES, function(inst)
        inst.SoundEmitter:PlaySound(inst.sounds.breath_in)
    end),
})
CommonForgeStates.AddTauntState(states, {
    TimeEvent(10*FRAMES, function(inst)
        inst.SoundEmitter:PlaySound(inst.sounds.taunt)
    end),
})
CommonStates.AddDeathState(states, {
    TimeEvent(1*FRAMES, function(inst)
        inst.SoundEmitter:PlaySound(inst.sounds.death_pre, nil, .5) -- TODO what are these parameters?
    end),
    TimeEvent(10*FRAMES, function(inst)
        inst.SoundEmitter:PlaySound(inst.sounds.death)
    end),
})
CommonStates.AddFrozenStates(states)

return StateGraph("snaptooth_reforged", states, events, "grow")
