require("stategraphs/commonstates")

CommonForgeStates = {}
CommonForgeHandlers = {}
--[[
Common Forge Handlers:
	OnAttacked
	OnKnockback
Common Forge States:
	AddStunStates
	AddTauntState
	AddKnockbackState
	AddActionState
	AddFossilizedStates
	AddFlipStates
	AddHideStates
--]]
--------------------------------------------------------------------------
local function CheckForAttackInterrupt(inst, data)
    local stat_tracker = TheWorld and TheWorld.components.stat_tracker
    if inst.sg:HasStateTag("pre_attack") and stat_tracker and data.attacker then
        stat_tracker:AdjustStat("attack_interrupt", data.attacker, 1)
    end
end

local function CheckForCCBroken(inst, data)
    local stat_tracker = TheWorld and TheWorld.components.stat_tracker
    local is_cc = inst.sg:HasStateTag("flipped") or inst.sg:HasStateTag("sleeping") and not inst.sg:HasStateTag("unwakeable")
    -- inst.components.sleeper and inst.components.sleeper:IsAsleep()
    if stat_tracker and data.attacker and is_cc then
        stat_tracker:AdjustStat("ccbroken", data.attacker, 1)
    end
end

local function CheckForGuardBreaks(inst, data)
    local stat_tracker = TheWorld and TheWorld.components.stat_tracker
    local is_hiding = inst.sg:HasStateTag("hiding")
    local will_break_guard = data.stimuli == "electric" or data.stimuli == "explosive"
    if stat_tracker and data.attacker and is_hiding and will_break_guard then
        stat_tracker:AdjustStat("guardsbroken", data.attacker, 1)
    end
end
local function CheckStats(inst, data)
    CheckForAttackInterrupt(inst, data)
    CheckForCCBroken(inst, data)
    CheckForGuardBreaks(inst, data)
end
local function onattacked(inst, data)
    if inst.components.health:IsDead() then return end
	if TUNING.FORGE.STUN_STIMULI[data.stimuli] and inst.sg:HasState("stun") and not inst.sg:HasStateTag("nostun") then
        CheckStats(inst, data)
		inst.sg:GoToState("stun", data)
	elseif inst.sg:HasStateTag("spinning") and TUNING.FORGE.FORCED_HIT_STIMULI[data.stimuli] then --TODO: Does all strong stimuli stop spin?
        CheckStats(inst, data)
		inst.sg:GoToState("attack_spin_stop_forced")
	elseif inst.sg:HasStateTag("hiding") and inst.sg:HasState("hide_hit") and not inst.sg:HasStateTag("nointerrupt") then -- Shield Hit
        CheckStats(inst, data)
		inst.sg:GoToState("hide_hit")
	elseif inst.sg:HasStateTag("flipped") then
        CheckStats(inst, data)
        inst.sg:GoToState("flip_stop", data.attacker)
	elseif TUNING.FORGE.FORCED_HIT_STIMULI[data.stimuli] and not inst.sg:HasStateTag("nointerrupt") -- Forced Hit
	or ((not inst.sg.mem.last_hit_time or inst.sg.mem.last_hit_time + (inst.hit_recovery or TUNING.FORGE.HIT_RECOVERY) < GetTime()) and not (inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("nointerrupt"))) and data.damage > 0 then -- Hit Cooldown Check
        CheckStats(inst, data)
        inst.sg:GoToState("hit")
	end
end

CommonForgeHandlers.OnAttacked = function()
    return EventHandler("attacked", onattacked)
end
--------------------------------------------------------------------------
local function onknockback(inst, data)
	if not inst.components.health:IsDead() and not (inst.sg:HasStateTag("hiding") or inst.sg:HasStateTag("rolling") or inst.sg:HasStateTag("charging") or inst.sg:HasStateTag("nostun") or inst.sg:HasStateTag("nointerrupt")) and (not inst:HasTag("largecreature") or inst:HasTag("largecreature") and data.knocker and data.knocker.epicknockback or true) then -- TODO boarillas and rhinos knockback was added to this but this needs to be looked at for upcoming content since all mobs should have a knockback state of some sort.
		inst.sg:GoToState("knockback", data)
	end
end

CommonForgeHandlers.OnKnockback = function()
    return EventHandler("knockback", onknockback)
end
--------------------------------------------------------------------------
local function onentershield(inst, data) -- TODO should this set a wants to variable? what happens if this does not gotostate? does the brain push the event again?
	if not inst.sg:HasStateTag("busy") and not inst.components.health:IsDead() then
		inst.sg:GoToState("hide_start")
	end
end

CommonForgeHandlers.OnEnterShield = function()
    return EventHandler("entershield", onentershield)
end
--------------------------------------------------------------------------
local function onexitshield(inst, data)
	if not inst.components.health:IsDead() and not (inst.sg:HasStateTag("hit") or inst.sg:HasStateTag("stunned")) and not inst.sg:HasStateTag("fossilized") then -- TODO is this if correct?
		inst.sg:GoToState("hide_stop")
	end
end

CommonForgeHandlers.OnExitShield = function()
    return EventHandler("exitshield", onexitshield)
end
--------------------------------------------------------------------------
local function onfreeze(inst)
    if not (inst.components.health ~= nil and inst.components.health:IsDead()) and (not inst.components.debuffable or inst.components.debuffable:CanBeDebuffedByDebuff("freeze")) then
        inst.sg:GoToState("frozen")
    end
end

CommonForgeHandlers.OnFreeze = function()
    return EventHandler("freeze", onfreeze)
end
--------------------------------------------------------------------------
CommonForgeHandlers.OnFossilize = function(is_generic)
    return EventHandler("fossilize", function(inst, data)
        if not (inst.components.health ~= nil and inst.components.health:IsDead() or inst.sg:HasStateTag("fossilized")) and (not inst.components.debuffable or inst.components.debuffable:CanBeDebuffedByDebuff("petrify")) then
            if inst.sg:HasStateTag("nofreeze") then
                inst.components.fossilizable:OnSpawnFX()
            else
                data.is_generic = is_generic
                inst.sg:GoToState("fossilized", data)
            end
        end
    end)
end
--------------------------------------------------------------------------
function onsleep(inst, data)
     if not inst.components.debuffable or inst.components.debuffable:CanBeDebuffedByDebuff("sleep") then
    	if inst.sg:HasStateTag("nosleep") then -- nointerrupt???
    		inst.sg.mem.sleep_duration = 3-- TODO data.duration
    	elseif inst.sg.currentstate.name ~= "sleep" then
    		inst.sg:GoToState(inst.sg.currentstate == "sleeping" and "sleeping" or "sleep")
    	end
    end
end

CommonForgeHandlers.OnSleep = function()
	return EventHandler("gotosleep", onsleep)
end
--------------------------------------------------------------------------
local function ontimelock(inst, data)
    if not (inst.components.health ~= nil and inst.components.health:IsDead() or inst.sg:HasStateTag("timelocked") or inst.sg:HasStateTag("nointerrupt") or inst.sg:HasStateTag("nofreeze")) and (not inst.components.debuffable or inst.components.debuffable:CanBeDebuffedByDebuff("time_lock")) then
        inst.sg:GoToState("time_locked", data)
    end
end

CommonForgeHandlers.OnTimeLock = function()
    return EventHandler("time_locked", ontimelock)
end
--------------------------------------------------------------------------
local function ontalk(inst, data)
	if not inst.sg:HasStateTag("talking") then
		inst.sg:GoToState("talk_pre", data)
	end
end

CommonForgeHandlers.OnTalk = function()
    return EventHandler("ontalk", ontalk)
end
--------------------------------------------------------------------------
local function onvictorypose(inst, data)
    if not inst.sg:HasStateTag("busy") then
        inst.sg:GoToState("pose")
    end
end

CommonForgeHandlers.OnVictoryPose = function()
    return EventHandler("victorypose", onvictorypose) -- TODO why check for busy? this could break it if Rhino is busy when event is pushed since event is only pushed once
end
--------------------------------------------------------------------------
local function ontruedeath(inst, data)
    -- truedeath should only be pushed after death which means corpse could still be running so queue death if not a corpse
    if inst:HasTag("corpse") then
        COMMON_FNS.FadeOut(inst, 2)
    else
        inst.sg.mem.is_true_death = true
    end
end

CommonForgeHandlers.OnTrueDeath = function()
    return EventHandler("truedeath", ontruedeath)
end
--------------------------------------------------------------------------
local function idleonanimover(inst)
    if inst.AnimState:AnimDone() then
        inst.sg:GoToState("idle")
    end
end

CommonForgeHandlers.IdleOnAnimOver = function() -- TODO add these where needed
    return EventHandler("animover", idleonanimover)
end

CommonForgeHandlers.IdleOnAnimQueueOver = function()
    return EventHandler("animqueueover", idleonanimover)
end
--------------------------------------------------------------------------
local function GetOverride(inst, override, default)
    return override and (type(override) == "function" and override(inst) or override) or default
end

local function PlayAnims(inst, anims, pushanim, no_loop)
    local anims = type(anims) == "table" and anims or {anims}
    inst.AnimState:PlayAnimation(pushanim or anims[1], not (no_loop or pushanim) and 1 == #anims)
    for i,anim in pairs(anims) do
        if pushanim or i > 1 then
            inst.AnimState:PushAnimation(anim, not no_loop and i == #anims)
        end
    end
end
--------------------------------------------------------------------------
CommonForgeStates.AddIdle = function(states, funny_idle_state, anim_override, timeline, events, fns)
    local fns = fns or {}
    table.insert(states, State {
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst, pushanim) -- TODO add wants_to_taunt check and replace idle for all mobs
            if inst.components.sleeper and inst.components.sleeper:IsAsleep() and inst.sg:HasState("sleep") then
                inst.sg:GoToState("sleep")
            elseif inst.sg.mem.wants_to_taunt and inst.sg:HasState("taunt") then
                inst.sg:GoToState("taunt")
            elseif inst.sg.mem.sleep_duration and inst.components.sleeper then
				inst.components.sleeper:GoToSleep(inst.sg.mem.sleep_duration, inst.components.sleeper.caster)
				inst.sg.mem.sleep_duration = nil
            else
                if inst.components.locomotor then
                    inst.components.locomotor:StopMoving()
                end

                local anim = GetOverride(inst, anim_override, "idle_loop")

                PlayAnims(inst, anim, pushanim)

                if fns.onenter then
                    fns.onenter(inst, pushanim)
                end
            end
        end,

        onexit = function(inst)
            inst.sg.mem.wants_to_taunt = nil
            if fns.onexit then
                fns.onexit(inst)
            end
        end,

        timeline = timeline,

        events = events or {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState(math.random() < .1 and funny_idle_state or "idle")
                end
            end),
        },
    })
end
--------------------------------------------------------------------------
CommonForgeStates.AddStunStates = function(states, timelines, anims, sounds, fns, events, opts)
	table.insert(states, State {
		name = "stun",
		tags = {"busy", "nofreeze"},

		onenter = function(inst, data)
			inst.Physics:Stop()
			inst.sg.statemem.stimuli = data.stimuli or nil
			if data.stimuli and data.stimuli == "electric" then
				inst.AnimState:PlayAnimation(GetOverride(inst, anims and anims.stun, "stun_loop"), true)
				inst.sg:SetTimeout(TUNING.FORGE.STUN_TIME)
                local sound = sounds and sounds.stun and inst.sounds[sounds.stun] or inst.sounds.stun or inst.sounds.hit or inst.sounds.hurt
                if sound then
				    inst.SoundEmitter:PlaySound(sound)
                end
			else
				inst.AnimState:PlayAnimation(GetOverride(inst, anims and anims.stun, "stun_loop"))
                local hit_sound = sounds and sounds.hit and inst.sounds[sounds.hit] or inst.sounds.hit
				if hit_sound then
                    inst.SoundEmitter:PlaySound(hit_sound)
                end
			end

			if fns and fns.onstun then
				fns.onstun(inst, data)
			end
		end,

		timeline = timelines and timelines.stuntimeline,

		ontimeout = function(inst)
			inst.sg:GoToState("stun_stop", inst.sg.statemem.stimuli)
		end,

		events = {
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("stun_stop", inst.sg.statemem.stimuli)
			end),
		},

		onexit = function(inst)
			if fns and fns.onexitstun then
				fns.onexitstun(inst)
			end
		end,
	})

	table.insert(states, State {
		name = "stun_stop",
        tags = {"busy", "nofreeze"},

        onenter = function(inst, stimuli)
            inst.Physics:Stop()
			if stimuli and stimuli == "explosive" and (not inst.last_taunt_time or (inst.last_taunt_time + TUNING.FORGE.TAUNT_CD < GetTime())) then -- TODO figure out check, taunts do not always occur on an explosive stun so need to double check this duration
				inst.last_taunt_time = GetTime()
                inst.sg.mem.wants_to_taunt = true
			end
            if not (opts and opts.no_stun_anim) then
                inst.AnimState:PlayAnimation(GetOverride(inst, anims and anims.stopstun, "stun_pst"))
            end
			if fns and fns.onstopstun then
				fns.onstopstun(inst)
			end
            if opts and opts.no_stun_anim and not opts.dont_force_idle then
                inst.sg:GoToState("idle")
            end
        end,

		timeline = timelines and timelines.endtimeline,

        events = events and events.stopstun or {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
        },
    })
end
--------------------------------------------------------------------------
CommonForgeStates.AddTauntState = function(states, timeline, anim, events, fns)
	table.insert(states, State {
		name = "taunt",
        tags = {"busy", "taunting", "keepmoving"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation(GetOverride(inst, anim, "taunt"))
            if fns and fns.onenter then
                fns.onenter(inst)
            end
        end,

        onupdate = fns and fns.onupdate,

		timeline = timeline,

        events = events or {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
        },

		onexit = fns and fns.onexit or nil,
    })
end

CommonForgeStates.AddSpawnState = function(states, timeline, anim, events, fns)
    local fns = fns or {}
	table.insert(states, State {
		name = "spawn",
        tags = {},

        onenter = function(inst)
            inst.sg.statemem.battlecryenabled = inst.components.combat.battlecryenabled -- save previous setting
			inst.components.combat.battlecryenabled = false
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation(GetOverride(inst, anim, "taunt"))
            if fns.onenter then
                fns.onenter(inst)
            end
        end,

		timeline = timeline,

        events = events or {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
        },

		onexit = function(inst)
			inst.components.combat.battlecryenabled = inst.sg.statemem.battlecryenabled -- apply previous setting
            if fns.onexit then
                fns.onexit(inst)
            end
		end,
    })
end
--------------------------------------------------------------------------
-- TODO need to make a post state for this to have a longer delay before the mob gets back up, maybe add a timeout for the knockback state to last a set time? probably just a post state would work and add a 1 second time on that?
CommonForgeStates.AddKnockbackState = function(states, timeline, anim, fns, ignoremass)
	table.insert(states, State {
        name = "knockback",
        tags = {"busy", "nopredict", "nomorph", "nodangle", "keepmoving", "knockback"},

        onenter = function(inst, data)
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()

			if fns and fns.anim then
				fns.anim(inst)
			else
				inst.AnimState:PlayAnimation(GetOverride(inst, anim, "stun_loop"), false)
				inst.AnimState:PushAnimation(GetOverride(inst, anim, "stun_loop"), false)
				inst.SoundEmitter:PlaySound(inst.sounds.hit)
				--inst.AnimState:SetTime(10* FRAMES)
			end

            if data and data.radius and data.knocker and data.knocker:IsValid() then
                local x, y, z = data.knocker.Transform:GetWorldPosition()
                local distsq = inst:GetDistanceSqToPoint(x, y, z)
                local rangesq = data.radius * data.radius
                local rot = inst.Transform:GetRotation()
                local rot1 = distsq > 0 and inst:GetAngleToPoint(x, y, z) or data.knocker.Transform:GetRotation() + 180
                local drot = math.abs(rot - rot1)
                while drot > 180 do
                    drot = math.abs(drot - 360)
                end
                local k = distsq < rangesq and .3 * distsq / rangesq - 1 or -.7
                inst.sg.statemem.speed = (data.strengthmult or 1) * 12 * k / ((ignoremass and 50 or inst.Physics:GetMass()) / 50)
                inst.sg.statemem.dspeed = 0
                if drot > 90 then
                    inst.sg.statemem.reverse = true
                    inst.Transform:SetRotation(rot1 + 180)
                    inst.Physics:SetMotorVel(-inst.sg.statemem.speed, 0, 0)
                else
                    inst.Transform:SetRotation(rot1)
                    inst.Physics:SetMotorVel(inst.sg.statemem.speed, 0, 0)
                end
            end
        end,

        onupdate = function(inst)
            if inst.sg.statemem.speed then
                inst.sg.statemem.speed = inst.sg.statemem.speed + inst.sg.statemem.dspeed
                if inst.sg.statemem.speed < 0 then
                    inst.sg.statemem.dspeed = inst.sg.statemem.dspeed + .075 -- TODO abigail had a + 1 instead of + 0.75? check if that was a mistake or not
                    inst.Physics:SetMotorVel(inst.sg.statemem.reverse and -inst.sg.statemem.speed or inst.sg.statemem.speed, 0, 0)
                else
					if not (fns and fns.anim) then -- TODO Bandaid for bernie and abigail common knockdown state
						inst.AnimState:PlayAnimation("stun_pst")
					end
                    inst.sg.statemem.speed = nil
                    inst.sg.statemem.dspeed = nil
                    inst.Physics:Stop()
                end
            end
        end,

        timeline = timeline,

        events = {
            EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					if fns and fns.animover then
						fns.animover(inst)
					else
						inst.sg:GoToState("idle")
					end
                end
            end),
        },

        onexit = function(inst)
            if inst.sg.statemem.speed then
                inst.Physics:Stop()
            end
			if fns and fns.onexit then
				fns.onexit(inst)
			end
        end,
    })
end
--------------------------------------------------------------------------
--Leo: Action state will most likely never be used by us but it might be useful for modders? maybe?
CommonForgeStates.AddActionState = function(states, timeline, anim)
	table.insert(states, State {
		name = "action",
        tags = {"busy"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
			inst:PerformBufferedAction()
            inst.AnimState:PlayAnimation(GetOverride(inst, anim, "run_pst"))
        end,

		timeline = timeline,

        events = {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
        },
    })
end
--------------------------------------------------------------------------
 -- This prevents infinite sleep if entity got here without being set to sleep
local function EnsureSleep(inst)
    local sleeper = inst.components.sleeper
    if not sleeper.isasleep then
        sleeper.isasleep = true
        sleeper:GoToSleep(inst.sg.mem.sleep_duration or 3, sleeper.caster)
    end
end
CommonForgeStates.AddSleepStates = function(states, timelines, fns, anims)
    local fns = fns or {}
    local _oldOnSleep = fns.onsleep
    fns.onsleep = function(inst)
        local sleeper = inst.components.sleeper
        sleeper.sleep_start = GetTime()
        -- Update numcc stat
        if sleeper.caster and TheWorld and TheWorld.components.stat_tracker then
            TheWorld.components.stat_tracker:AdjustStat("numcc", sleeper.caster, 1)
        end
        EnsureSleep(inst)
        if _oldOnSleep then
            _oldOnSleep(inst)
        end
    end
    -- Add sleep check to the "sleeping" state to prevent infinite sleep
    table.insert(EnsureTable(timelines, "sleeptimeline"), TimeEvent(0, function(inst)
        EnsureSleep(inst)
    end))
    --CommonStates.AddSleepStates(states, timelines, fns)
    local function sleeponanimover(inst)
        if inst.AnimState:AnimDone() then
            inst.sg:GoToState("sleeping")
        end
    end
    local function onwakeup(inst)
        if not inst.sg:HasStateTag("nowake") then
            inst.sg:GoToState("wake")
        end
    end
    table.insert(states, State{
        name = "sleep",
        tags = { "busy", "sleeping" },

        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation(anims and anims.sleep_pre or "sleep_pre")
            if fns and fns.onsleep then
                fns.onsleep(inst)
            end
        end,

        timeline = timelines and timelines.starttimeline or nil,

        events = {
            EventHandler("animqueueover", sleeponanimover),
            EventHandler("onwakeup", onwakeup),
        },
    })
    table.insert(states, State{
        name = "sleeping",
        tags = { "busy", "sleeping" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation(anims and anims.sleep_loop or "sleep_loop")
            if fns and fns.sleeping then
                fns.sleeping(inst)
            end
        end,

        timeline = timelines and timelines.sleeptimeline or nil,

        events = {
            EventHandler("animover", sleeponanimover),
            EventHandler("onwakeup", onwakeup),
        },
    })
    table.insert(states, State{
        name = "wake",
        tags = { "busy", "waking" },

        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation(anims and anims.sleep_pst or "sleep_pst")
            if inst.components.sleeper and inst.components.sleeper:IsAsleep() then
                inst.components.sleeper:WakeUp()
            end
            if fns and fns.onwake then
                fns.onwake(inst)
            end
        end,

        timeline = timelines and timelines.waketimeline or nil,

        events = {
            EventHandler("animover", idleonanimover),
        },
    })
end
--------------------------------------------------------------------------
local function ClearStatusAilments(inst)
    if inst.components.freezable ~= nil and inst.components.freezable:IsFrozen() then
        inst.components.freezable:Unfreeze()
    end
    if inst.components.pinnable ~= nil and inst.components.pinnable:IsStuck() then
        inst.components.pinnable:Unstick()
    end
end

CommonForgeStates.AddFossilizedStates = function(states, timelines, anims, sounds, fns)
    table.insert(states, State{
        name = "fossilized",
        tags = { "busy", "fossilized", "caninterrupt" },

        onenter = function(inst, data)
            ClearStatusAilments(inst)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            if data.is_generic then
                inst.sg.mem.generic_fossil_fx = COMMON_FNS.CreateFX("rf_generic_fossilized", nil, inst)--, {position = inst:GetPosition()})
                inst.sg.mem.generic_fossil_fx.entity:SetParent(inst.entity)
                if anims and anims.fossilized then
                    inst.AnimState:PlayAnimation(anims.fossilized, false)
                else
                    inst.AnimState:Pause()
                end
            else
                PlayAnims(inst, GetOverride(inst, anims ~= nil and anims.fossilized, "fossilized"), nil, true)
            end
            inst.SoundEmitter:PlaySound(sounds ~= nil and sounds.fossilized or "dontstarve/common/lava_arena/fossilized_pre_1")
            inst.components.fossilizable:OnFossilize(data ~= nil and data.duration or nil, data ~= nil and data.doer or nil)
            if fns ~= nil and fns.fossilized_onenter ~= nil then
                fns.fossilized_onenter(inst)
            end
        end,

        timeline = timelines ~= nil and timelines.fossilizedtimeline or nil,

        events = {
            EventHandler("fossilize", function(inst, data)
                inst.components.fossilizable:OnExtend(data ~= nil and data.duration or nil, data ~= nil and data.doer or nil)
            end),
            EventHandler("unfossilize", function(inst)
                inst.sg.statemem.unfossilizing = true
                inst.sg:GoToState("unfossilizing")
            end),
        },

        onexit = function(inst)
            inst.components.fossilizable:OnUnfossilize()
            if not inst.sg.statemem.unfossilizing then
                --Interrupted
                inst.components.fossilizable:OnSpawnFX()
            end
            if fns ~= nil and fns.fossilized_onexit ~= nil then
                fns.fossilized_onexit(inst)
            end
        end,
    })
    table.insert(states, State{
        name = "unfossilizing",
        tags = { "busy", "caninterrupt" },

        onenter = function(inst)
            if inst.sg.mem.generic_fossil_fx ~= nil then
                inst.sg.mem.generic_fossil_fx.AnimState:PlayAnimation("fossilized_shake")
                if anims and anims.unfossilizing then
                    inst.AnimState:PlayAnimation(anims.unfossilizing, false)
                else
                    local function GoToUnFossilized(fossil_fx)
                        if fossil_fx.AnimState:AnimDone() then
                            inst.sg.statemem.unfossilized = true
                            fossil_fx:RemoveEventCallback("animover", GoToUnFossilized)
                            inst.sg:GoToState("unfossilized")
                        end
                    end
                    inst.sg.mem.generic_fossil_fx:ListenForEvent("animover", GoToUnFossilized)
                end
            else
                PlayAnims(inst, GetOverride(inst, anims ~= nil and anims.unfossilizing, "fossilized_shake"))
            end
            if inst.SoundEmitter:PlayingSound("shakeloop") then
                inst.SoundEmitter:KillSound("shakeloop")
            end
            inst.SoundEmitter:PlaySound(sounds ~= nil and sounds.unfossilizing or "dontstarve/common/lava_arena/fossilized_shake_LP", "shakeloop")
            if fns ~= nil and fns.unfossilizing_onenter ~= nil then
                fns.unfossilizing_onenter(inst)
            end
        end,

        timeline = timelines ~= nil and timelines.unfossilizingtimeline or nil,

        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg.statemem.unfossilized = true
                    inst.sg:GoToState("unfossilized")
                end
            end),
        },

        onexit = function(inst)
            if not inst.sg.statemem.unfossilized then
                --Interrupted
                inst.components.fossilizable:OnSpawnFX()
            end
            inst.SoundEmitter:KillSound("shakeloop")
            inst.components.fossilizable:SpawnUnfossilizeFx()
            if fns ~= nil and fns.unfossilizing_onexit ~= nil then
                fns.unfossilizing_onexit(inst)
            end
        end,
    })
    table.insert(states, State{
        name = "unfossilized",
        tags = { "busy", "caninterrupt" },

        onenter = function(inst)
            if inst.sg.mem.generic_fossil_fx then
                inst.sg.mem.generic_fossil_fx.AnimState:PlayAnimation("fossilized_shake")
                if anims and anims.unfossilized then
                    inst.AnimState:PlayAnimation(anims.unfossilized, false)
                else
                    local function EndUnfossilized(fossil_fx)
                        if fossil_fx.AnimState:AnimDone() then
                            fossil_fx:RemoveEventCallback("animover", EndUnfossilized)
                            inst.AnimState:Resume()
                            inst.sg:GoToState("idle")
                        end
                    end
                    inst.sg.mem.generic_fossil_fx:ListenForEvent("animover", EndUnfossilized)
                end
            else
                PlayAnims(inst, GetOverride(inst, anims ~= nil and anims.unfossilized, "fossilized_pst"), nil, true)
            end
            inst.SoundEmitter:PlaySound(sounds ~= nil and sounds.fossilized or "dontstarve/impacts/lava_arena/fossilized_break")
            inst.components.fossilizable:OnSpawnFX()
            if fns ~= nil and fns.unfossilized_onenter ~= nil then
                fns.unfossilized_onenter(inst)
            end
        end,

        timeline = timelines ~= nil and timelines.unfossilizedtimeline or nil,

        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            if inst.sg.mem.generic_fossil_fx then
                inst.sg.mem.generic_fossil_fx:Remove()
                inst.sg.mem.generic_fossil_fx = nil
            end
            if fns ~= nil and fns.unfossilized_onexit then
                fns.unfossilized_onexit(inst)
            end
        end,
    })
end
--------------------------------------------------------------------------
CommonForgeStates.AddFlipStates = function(states, flipduration, timelines, anims, fns, exit)
	table.insert(states, State {
		name = "flip_start",
        tags = {"busy", "nosleep"},

        onenter = function(inst, cb) -- TODO cb?
			if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation(GetOverride(inst, anims and anims.startflip, "flip_pre"))
			if fns and fns.onflipstart then
				fns.onflipstart(inst, cb)
			end
        end,

		onexit = exit and exit.flipstart or function(inst)
				inst:DoTaskInTime(flipduration or TUNING.FORGE.SNORTOISE.FLIP_TIME, function(inst)
				if inst.sg:HasStateTag("flipped") then
					inst.sg:GoToState("flip_stop")
				end
			end)
		end,

		timeline = timelines and timelines.starttimeline,

        events = {
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("flip")
			end),
        },
    })

	table.insert(states, State{
		name = "flip",
        tags = {"busy", "flipped"},

        onenter = function(inst, cb) -- TODO cb?
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation(GetOverride(inst, anims and anims.fliploop, "flip_loop"))
        end,

		timeline = timelines and timelines.fliptimeline,

        events = {
			EventHandler("animover", function(inst)
                inst.sg:GoToState("flip")
            end),
        },

		onexit = exit and exit.flip or nil,
    })

	table.insert(states, State{
		name = "flip_stop",
        tags = {"busy", "nosleep"},

        onenter = function(inst, attacker)
            inst.Physics:Stop() -- TODO test without this
            inst.AnimState:PlayAnimation(GetOverride(inst, anims and anims.stopflip, "flip_pst"))
			if fns and fns.onflipstop then
				fns.onflipstop(inst, attacker)
			end
        end,

		timeline = timelines and timelines.endtimeline,

        events = {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
        },

		onexit = exit and exit.flipstop or nil,

    })

	table.insert(states, State{
		name = "flip_hit",
        tags = {"busy", "nosleep"},

        onenter = function(inst, cb)
            inst.Physics:Stop() -- TODO test without this
            inst.AnimState:PlayAnimation(GetOverride(inst, anims and anims.fliphit, "flip_hit"))
        end,

		timeline = timelines and timelines.hittimeline,

        events = {
			EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    })
end
--------------------------------------------------------------------------
CommonForgeStates.AddHideStates = function(states, timelines, anims, fns)
	table.insert(states, State {
		name = "hide_start",
        tags = {"busy", "nosleep", "hide_pre"}, -- TODO better tag name for hide_pre, used in shield behavior

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation(GetOverride(inst, anims and anims.starthiding, "hide_pre"))
        end,

		timeline = timelines and timelines.starttimeline,

		onexit = function(inst)
			--Leo: Adding this here incase mobs (like snortoise) become "invincible" mid state and it gets interrupted.
			inst.components.health:SetAbsorptionAmount(0)
			inst.components.sleeper:SetResistance(1)
		end,

        events = {
			EventHandler("animover", function(inst)
                inst.sg:GoToState("hiding")
            end),
        },
    })

	table.insert(states, State {
		name = "hiding",
        tags = {"busy", "hiding"},

        onenter = function(inst, cb)
			inst.components.debuffable:RemoveDebuff("shield_buff", "shield_buff")
			inst.components.sleeper:SetResistance(9999)
            inst.components.health:SetAbsorptionAmount(inst.hide_absorption or 1)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation(GetOverride(inst, anims and anims.hideloop, "hide_loop"))
        end,

		timeline = timelines and timelines.hidetimeline,

		onexit = function(inst)
			inst.components.health:SetAbsorptionAmount(0)
			inst.components.sleeper:SetResistance(1)
		end,

        events = {
			EventHandler("animover", function(inst)
                inst.sg:GoToState("hiding")
            end),
        },
    })

	table.insert(states, State {
		name = "hide_stop",
        tags = {"busy", "nobuff", "nosleep"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation(GetOverride(inst, anims and anims.stophiding, "hide_pst"))
        end,

		timeline = timelines and timelines.endtimeline,

		onexit = function(inst)
			if fns and fns.onhidestopexit then
				fns.onhidestopexit(inst)
			end
        end,

        events = {
			EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    })

	table.insert(states, State {
		name = "hide_hit",
        tags = {"busy", "hiding"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation(GetOverride(inst, anims and anims.hidehit, "hide_hit"))
			if inst.sounds.shell_impact then
                inst.SoundEmitter:PlaySound(inst.sounds.shell_impact) -- TODO add to snortoise prefab and boarilla
            end
            inst.components.sleeper:SetResistance(9999)
            inst.components.health:SetAbsorptionAmount(inst.hide_absorption or 1)
            inst.sg.mem.last_hit_time = GetTime()
        end,

        timeline = timelines and timelines.hittimeline,

        onexit = function(inst)
            inst.components.health:SetAbsorptionAmount(0)
            inst.components.sleeper:SetResistance(1)
        end,

        events = {
			EventHandler("animover", function(inst)
                inst.sg:GoToState("hiding")
            end),
        },
    })
end
--------------------------------------------------------------------------
CommonForgeStates.AddTalkStates = function(states, timelines, anims, sounds)
	table.insert(states, State {
		name = "talk_pre",
        tags = {"idle"},

        onenter = function(inst, data)
			if inst.SoundEmitter:PlayingSound("talk") then
				inst.SoundEmitter:KillSound("talk")
			end
            inst.sg.statemem.noanim = data and data.noanim
            if not inst.sg.statemem.noanim then
                inst.AnimState:PlayAnimation(anims and anims.starttalking or "yell_pre")
            end
        end,

		timeline = timelines and timelines.starttimeline,

        events = {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("talk_loop", {noanim = inst.sg.statemem.noanim})
			end),
        },
    })

	table.insert(states, State {
		name = "talk_loop",
        tags = {"talking"},

        onenter = function(inst, data)
			if inst.SoundEmitter:PlayingSound("talk") then --TODO: Check to see if onexit is a more reliable fix, if it fixes it at all.
				inst.SoundEmitter:KillSound("talk")
			end
            inst.SoundEmitter:PlaySound(inst.sounds and inst.sounds.talk or sounds and sounds.talk, "talk")
            inst.sg.statemem.noanim = data and data.noanim
            if not inst.sg.statemem.noanim then
                inst.AnimState:PlayAnimation(anims and anims.talking or "yell_loop", true)
            end
        end,

		onexit = function(inst)
			if inst.SoundEmitter:PlayingSound("talk") then
				inst.SoundEmitter:KillSound("talk")
			end
		end,

		timeline = timelines and timelines.talktimeline,

        events = {
			EventHandler("donetalking", function(inst)
				inst.sg:GoToState("talk_pst", {noanim = inst.sg.statemem.noanim})
			end),
        },
    })

	table.insert(states, State {
		name = "talk_pst",
        tags = {"idle"},

        onenter = function(inst, data)
			if inst.SoundEmitter:PlayingSound("talk") then
				inst.SoundEmitter:KillSound("talk")
			end
            inst.sg.statemem.noanim = data and data.noanim
            if not inst.sg.statemem.noanim then
                inst.AnimState:PlayAnimation(anims and anims.stoptalking or "yell_pst")
            end
        end,

		timeline = timelines and timelines.stoptimeline,

        events = {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
        },
    })
end
--------------------------------------------------------------------------
CommonForgeStates.AddHitState = function(states, timeline, anim, events, fns, sounds)
    local fns = fns or {}
    local sounds = sounds or {}
    table.insert(states, State{
        name = "hit",
        tags = {"hit", "busy"},

        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end

            local anim = GetOverride(inst, anim, "hit")
            inst.AnimState:PlayAnimation(anim)

            local sound = not sounds.disable and inst.SoundEmitter and GetOverride(inst, sounds.override, inst.sounds and (inst.sounds.hit or inst.sounds.hurt))
            if sound then
                inst.SoundEmitter:PlaySound(sound)
            end
            inst.sg.mem.last_hit_time = GetTime()
            if fns.onenter then
                fns.onenter(inst)
            end
        end,

        onexit = fns.onexit,

        timeline = timeline,

        events = events or {CommonForgeHandlers.IdleOnAnimOver()},
    })
end
CommonForgeStates.AddAttackState = function(states, timeline, anim, events, fns)
    local fns = fns or {}
    table.insert(states, State{
        name = "attack",
        tags = {"attack", "busy", "pre_attack"},

        onenter = function(inst, target)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            local anim = GetOverride(inst, anim, "atk")
            inst.AnimState:PlayAnimation(anim)
            inst.components.combat:StartAttack()
            inst.sg.statemem.target = target
            if fns.onenter then
                fns.onenter(inst)
            end
        end,

        onexit = fns.onexit,

        timeline = timeline,

        events = events or {CommonForgeHandlers.IdleOnAnimOver()},
    })
end
CommonForgeStates.AddDeathState = function(states, timeline, anim, events, fns)
    local fns = fns or {}
    table.insert(states, State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            local anim = GetOverride(inst, anim, "death")
            inst.AnimState:PlayAnimation(anim)
            if inst.Physics then
                RemovePhysicsColliders(inst)
            end
            if inst.components.lootdropper then
                inst.components.lootdropper:DropLoot(inst:GetPosition())
            end
            if inst.components.armorbreak_debuff then -- TODO should be an remove all debuffs
                inst.components.armorbreak_debuff:RemoveDebuff()
            end
            if fns.onenter then
                fns.onenter(inst)
            end
        end,

        timeline = timeline,

        events = events,
    })
end
CommonForgeStates.AddCombatStates = function(states, timelines, anims, events, fns, sounds)
    local timelines = timelines or {}
    local anims = anims or {}
    local events = events or {}
    local fns = fns or {}
    local sounds = sounds or {}
    CommonForgeStates.AddHitState(states, timelines.hittimeline, anims.hit, events.hit, {onenter = fns.onenter_hit, onexit = fns.onexit_hit}, {override = sounds.hit, disable = sounds.disable_hit})
    CommonForgeStates.AddAttackState(states, timelines.attacktimeline, anims.attack, events.attack, {onenter = fns.onenter_attack, onexit = fns.onexit_attack})
    CommonForgeStates.AddDeathState(states, timelines.deathtimeline, anims.death, nil, {onenter = fns.onenter_death})
end
--------------------------------------------------------------------------
CommonForgeStates.AddTimeLockStates = function(states, timelines, anims, sounds, fns, events, opts)
    table.insert(states, State {
        name = "time_locked",
        tags = {"busy", "nofreeze","timelocked"},

        onenter = function(inst, data)
            inst.Physics:Stop()
            inst.AnimState:Pause()
            if inst.components.health then
                inst.components.health:SetAbsorptionAmount(1)
            end
            if inst.components.sleeper then
                inst.components.sleeper:SetResistance(999)
            end
            inst.components.timelockable:OnTimeLock(data ~= nil and data.duration or nil, data ~= nil and data.doer or nil)
            if fns and fns.onenter then
                fns.onenter(inst, data)
            end
        end,

        timeline = timelines and timelines.timelocktimeline,

        events = {
            EventHandler("time_locked", function(inst, data)
                inst.components.timelockable:OnExtend(data ~= nil and data.duration or nil, data ~= nil and data.doer or nil)
            end),
            EventHandler("time_unlocked", function(inst)
				local fx = SpawnPrefab("rf_timebreak_fx")
				fx.Transform:SetPosition(inst:GetPosition():Get())
				local fxscale = inst:HasTag("epic") and 1 or 0.5
				fx.AnimState:SetScale(fxscale, fxscale)
                inst.sg:GoToState("idle")
            end),
        },

        onexit = function(inst)
            inst.AnimState:Resume()
            if inst.components.health then
                inst.components.health:SetAbsorptionAmount(0)
            end
            if inst.components.sleeper then
                inst.components.sleeper:SetResistance(1)
            end
            if fns and fns.onexit then
                fns.onexit(inst)
            end
        end,
    })
end
