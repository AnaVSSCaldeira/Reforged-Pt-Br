require("stategraphs/commonforgestates")

local function startaura(inst)
    if inst.components.health:IsDead() or inst.sg:HasStateTag("dissipate") then
        return
    end

	inst.AnimState:PlayAnimation("attack_loop", true)

    inst.Light:SetColour(255/255, 32/255, 32/255)
    inst.SoundEmitter:PlaySound("dontstarve/characters/wendy/abigail/attack_LP", "angry")
    inst.AnimState:SetMultColour(207/255, 92/255, 92/255, 1)

    local attack_anim = "attack" .. tostring(inst.attack_level or 1)

    inst.attack_fx = SpawnPrefab("abigail_attack_fx")
    inst:AddChild(inst.attack_fx)
    inst.attack_fx.AnimState:PlayAnimation(attack_anim .. "_pre")
    inst.attack_fx.AnimState:PushAnimation(attack_anim .. "_loop", true)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        inst.attack_fx.AnimState:OverrideItemSkinSymbol("flower", skin_build, "flower", inst.GUID, "abigail_attack_fx" )
    end

    inst.attack_fx_ground = SpawnPrefab("abigail_attack_fx_ground")
    inst:AddChild(inst.attack_fx_ground)
    inst.attack_fx_ground.AnimState:PlayAnimation(attack_anim .. "_ground_pre")
    inst.attack_fx_ground.AnimState:PushAnimation(attack_anim .. "_ground_loop", true)
end

local function stopaura(inst)
    inst.Light:SetColour(180/255, 195/255, 225/255)
    inst.SoundEmitter:KillSound("angry")
    inst.AnimState:SetMultColour(1, 1, 1, 1)

    if inst.attack_fx then
        inst.attack_fx:kill_fx(inst.attack_level or 1)
        inst.attack_fx = nil
    end

    if inst.attack_fx_ground then
        inst.attack_fx_ground:kill_fx(inst.attack_level or 1)
        inst.attack_fx_ground = nil
    end
end

local events = {
    CommonHandlers.OnLocomote(true, true),
    EventHandler("startaura", startaura),
    EventHandler("stopaura", stopaura),
    EventHandler("attacked", function(inst)
        if not (inst.sg:HasStateTag("jumping") or inst.components.health:IsDead() or inst.sg:HasStateTag("nointerrupt")) then -- TODO jumping is a tag in kleis knockback should we add that tag???
            inst.sg:GoToState("hit")
        end
    end),
    CommonForgeHandlers.OnKnockback(),
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
    EventHandler("death", function(inst)
        inst.sg:GoToState("dissipate")
    end),
	EventHandler("dance", function(inst)
        if not (inst.sg:HasStateTag("dancing") or inst.sg:HasStateTag("busy") or
                inst.components.health:IsDead() or inst.sg:HasStateTag("dissipate")) then
            inst.sg:GoToState("dance")
        end
    end),
}

local function getidleanim(inst)
    return inst.components.aura.applying and "attack_loop"
        or (math.random() < 0.1 and "idle_custom" or "idle")
end

local states = {
    State
    {
        name = "idle",
        tags = { "idle", "canrotate" },

        onenter = function(inst)
            local anim = getidleanim(inst)
            if anim ~= nil then
                inst.AnimState:PlayAnimation(anim)
            end
        end,

        onupdate = function(inst)

        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
            EventHandler("startaura", function(inst)
                inst.sg:GoToState("attack_start")
            end),
        },

    },

	State
    {
        name = "attack_start",
        tags = { "busy", "canrotate" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("attack_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

	State{
        name = "dance",
        tags = {"idle", "dancing"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()
            inst.AnimState:PushAnimation("dance", true)
        end,
    },

    State{
        name = "appear",

        onenter = function(inst)
            inst.AnimState:PlayAnimation("appear")
            inst.SoundEmitter:PlaySound(inst.sounds.howl)
            inst:PushEvent("exitlimbo")
        end,

        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
			inst.components.health:SetInvincible(false)
            inst.components.aura:Enable(true)
        end,
    },

    State{
        name = "hit",
        tags = { "busy" },

        onenter = function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.howl)
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()
        end,

        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "levelup",
        tags = {"busy", "nointerrupt"},

        onenter = function(inst, data)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("flower_change")
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
            TimeEvent(9*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(inst.current_level >= 3 and "dontstarve/characters/wendy/abigail/level_change/2" or "dontstarve/characters/wendy/abigail/level_change/1")
            end),
            TimeEvent(10*FRAMES, function(inst)
                local fx = SpawnPrefab("abigaillevelupfx")
                fx.entity:SetParent(inst.entity)
                fx.Transform:SetRotation(inst.Transform:GetRotation())

                local skin_build = inst:GetSkinBuild()
                if skin_build ~= nil then
                    fx.AnimState:OverrideItemSkinSymbol("flower", skin_build, "flower", inst.GUID, "abigail_attack_fx" )
                end
                inst:UpdatePetLevel(inst.sg.statemem.queued_level, inst.sg.statemem.force_level)
                inst.sg.statemem.queued_level = nil
                inst.sg.statemem.force_level = nil
            end),
        },

        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "dissipate",
        tags = {"busy", "nointerrupt", "notarget"},

        onenter = function(inst, data)
            if data and data.level then
				inst.sg.statemem.queued_level = data.level
                inst.sg.statemem.force_level = data.force
				inst.components.locomotor:Stop()
				--inst.components.health:SetInvincible(true)
				inst.components.aura:Enable(false)
			else
				inst.Physics:Stop()
			end
            inst.AnimState:PlayAnimation("dissipate")
            inst.SoundEmitter:PlaySound(inst.sounds.howl)
            inst:PushEvent("enterlimbo")
        end,

        onexit = function(inst)
            if inst.sg.statemem.queued_level or inst.sg.statemem.force_level then
                inst:UpdatePetLevel(inst.sg.statemem.queued_level, inst.sg.statemem.force_level) -- TODO pushevent? klei did pushevent
                inst.sg.statemem.queued_level = nil
                inst.sg.statemem.force_level = nil
            end
        end,

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
}

CommonStates.AddSimpleWalkStates(states, getidleanim)
CommonStates.AddSimpleRunStates(states, getidleanim)
CommonForgeStates.AddKnockbackState(states, nil, "knockback", { -- TODO was set to go to state "hit" on event animover, needed? since this is our own custom state?
	anim = function(inst)
		inst.SoundEmitter:PlaySound(inst.sounds.howl)
        inst.AnimState:PlayAnimation("brace")
	end,
}, true)

return StateGraph("abigail_reforged", states, events, "appear")
