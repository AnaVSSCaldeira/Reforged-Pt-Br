require("stategraphs/commonforgestates")

local events = {
    CommonHandlers.OnLocomote(true, true),
    EventHandler("updatepetmastery", function(inst, data)
        -- Update queued_level if in the middle of leveling
        if inst.sg.statemem.queued_level then
            inst.sg.statemem.queued_level = inst.sg.statemem.queued_level + (data and data.level or 0)
        elseif not inst.components.health:IsDead()then
            if data.level > 0 then
                inst.sg:GoToState("levelup", data)
            else
                inst.sg:GoToState("dissipate", data)
            end
        end
    end),
    EventHandler("give_shield", function(inst, data)
        inst.sg:GoToState("shield", data)
    end),
    EventHandler("death", function(inst)
        inst.sg:GoToState("dissipate")
    end),
}

local states = {
    State{
        name = "idle",
        tags = { "idle", "canrotate" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("idle")
        end,

        events = {
            CommonForgeHandlers.IdleOnAnimOver(),
        },
    },
    State{
        name = "appear",

        onenter = function(inst)
            inst.AnimState:PlayAnimation("appear")
        end,

        timeline = {
            TimeEvent(7*FRAMES, function(inst)
                if inst.components.talker ~= nil then
                    inst.components.talker:Say(STRINGS.SMALLGHOST_TALK[math.random(#STRINGS.SMALLGHOST_TALK)])
                end
                inst.SoundEmitter:PlaySound(inst.sounds.howl)
            end),
        },

        events = {
            CommonForgeHandlers.IdleOnAnimOver(),
        },
    },
    State{
        name = "levelup",
        tags = {"busy", "nointerrupt"},

        onenter = function(inst, data)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("quest_completed")
            if data and data.level then
                inst.sg.statemem.queued_level = data.level
                inst.sg.statemem.force_level = data.force
                inst.components.locomotor:Stop()
            else
                inst.Physics:Stop()
            end
        end,

        onexit = function(inst)
            if inst.sg.statemem.queued_level then
                inst:UpdatePetLevel(inst.sg.statemem.queued_level, inst.sg.statemem.force_level)
                inst.sg.statemem.queued_level = nil
                inst.sg.statemem.force_level = nil
            end
        end,

        timeline = {
            TimeEvent(5*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(inst.sounds.howl)
            end),
        },

        events = {
            CommonForgeHandlers.IdleOnAnimOver(),
        },
    },
    State{
        name = "dissipate",
        tags = {"busy", "nointerrupt"},

        onenter = function(inst, data)
            if data and data.level then
                inst.sg.statemem.queued_level = data.level
                inst.sg.statemem.force_level = data.force
                inst.components.locomotor:Stop()
            else
                inst.Physics:Stop()
            end
            inst.AnimState:PlayAnimation("sad")
            inst.AnimState:PushAnimation("dissipate")
        end,

        onexit = function(inst)
            if inst.sg.statemem.queued_level or inst.sg.statemem.force_level then
                inst:UpdatePetLevel(inst.sg.statemem.queued_level, inst.sg.statemem.force_level) -- TODO pushevent? klei did pushevent
                inst.sg.statemem.queued_level = nil
                inst.sg.statemem.force_level = nil
            end
        end,

        timeline = {
            TimeEvent((42 + 5)*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(inst.sounds.howl)
            end),
        },

        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    if inst.sg.statemem.queued_level then
                        inst.sg:GoToState("appear")
                    elseif not inst._playerlink then
                        inst:PushEvent("detachchild")
                        inst:Remove()
                    end
                end
            end)
        },
    },
    State{
        name = "shield",
        tags = { "busy", "noattack", "nointerrupt" },

        onenter = function(inst, data)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("small_happy")
            inst.sg.statemem.target = data and data.target
        end,

        timeline = {
            TimeEvent(3*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(inst.sounds.joy)
                inst:GiveShield(inst.sg.statemem.target)
            end),
        },

        events = {
            CommonForgeHandlers.IdleOnAnimOver(),
        },
    },
}

local HOWL_CHANCE = 0.5
CommonStates.AddSimpleWalkStates(states, "idle",{
    starttimeline = {
        TimeEvent(FRAMES, function(inst)
            if math.random() < HOWL_CHANCE then
                inst.SoundEmitter:PlaySound(inst.sounds.howl)
            end
        end),
    },
})
CommonStates.AddSimpleRunStates(states, "idle")

return StateGraph("baby_ben", states, events, "appear")
