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

local actionhandlers = { }

local function IsBannerReady(inst)
    return inst.components.combat.target and inst.components.combat:IsAttackReady("banner") and GetTime() - inst.components.combat.lastwasattackedtime > 1
end

local events = {
	CommonForgeHandlers.OnAttacked(), -- TODO crocs hit recovery was hardcoded to 1?
	CommonForgeHandlers.OnKnockback(),
	EventHandler("locomote", function(inst)
        local is_moving = inst.sg:HasStateTag("moving")
        local is_running = inst.sg:HasStateTag("running")
        local is_idling = inst.sg:HasStateTag("idle")

        local should_move = inst.components.locomotor:WantsToMoveForward()
        local should_run = inst.components.locomotor:WantsToRun()
        local wants_to_banner = IsBannerReady(inst) and false
        if is_moving and (not should_move or wants_to_banner) then
            inst.sg:GoToState(wants_to_banner and "build" or "run_stop")
        elseif (is_idling and should_move) then
            if inst.components.combat.target then
    			-- Do not run if currently in ranged (spit) mode unless an attack is ready.
                if (inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) and not inst.components.combat:InCooldown() and inst.components.combat.target) or not inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)then
    				inst.sg:GoToState("run_start")
                end
            else
                inst.sg:GoToState("run_start")
            end
        end
    end),
	--CommonHandlers.OnLocomote(true,false),
	CommonHandlers.OnDeath(),
	CommonForgeHandlers.OnSleep(),
    CommonForgeHandlers.OnFreeze(),
    CommonForgeHandlers.OnFossilize(),
	CommonForgeHandlers.OnTimeLock(),
	EventHandler("doattack", function(inst, data)
        if not inst.components.health:IsDead() and (inst.sg:HasStateTag("canattack") or not inst.sg:HasStateTag("busy")) and data then -- TODO canattack tag
            if inst.components.combat.target and not (inst.weapon and inst.weapon.components.equippable:IsEquipped()) then
                inst.sg:GoToState("attack", data.target)
            else
                inst.sg:GoToState("spit", data.target)
            end
        end
    end),
    EventHandler("reinforcements", function(inst, data)
        -- Summon a banner if off cd, previous state was an attack, and not recently attacked (1 second)
        if not inst.components.health:IsDead() and inst.components.combat:IsAttackReady("banner") and inst.sg.laststate and inst.sg.laststate.tags.attack and GetTime() - inst.components.combat.lastwasattackedtime > 1 then
            inst.sg:GoToState("build")
        end
    end),
}

local function SpawnBanner(inst)
    local options = {
        theta = math.random() * 2 * PI,
        pos = inst:GetPosition(),
        radius = math.random(1, 2),
        max_banners = 1,
        banners = inst.banners,
    }
    -- Load custom options
    MergeTable(options, inst.components.combat:GetAttackOptions("banner"), true)
    inst.components.combat:ToggleAttack("banner", false)
    local angle_diff = 2 * PI / options.max_banners
    for i = 1, options.max_banners do
        local offset = FindWalkableOffset(options.pos, options.theta + angle_diff * i, options.radius, 2, true, true)
    	local banner = SpawnPrefab(options.banners[i%#(options.banners) + 1])
    	banner.owner = inst
    	banner.Transform:SetPosition((offset and (options.pos + offset) or options.pos):Get())
    	banner:ListenForEvent("death", function(banner_inst)
            inst.active_banners = inst.active_banners - 1
            -- Only reset banner summon if all banners have been destroyed
            if inst.active_banners <= 0 then
                inst.components.combat:ToggleAttack("banner", true)
                inst.components.combat:StartCooldown("banner")
            end
    	end)
        inst.active_banners = (inst.active_banners or 0) + 1
    end
end

local states = {
	State{
        name = "spit",
        tags = {"attack", "busy", "pre_attack"},

		onenter = function(inst, target)
			inst.components.locomotor:Stop()
			inst.components.combat:StartAttack()
			inst.AnimState:PlayAnimation("spit")
		end,

		timeline = {
			TimeEvent(5*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.spit)
			end),
			TimeEvent(13*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.spit2)
				inst.components.combat:DoAttack()
				inst.altattack = false
                inst.sg:RemoveStateTag("pre_attack")
			end),
		},

        events = {
            EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
			end),
        },
    },

	State{
		name = "spawn",
        tags = {"busy", "canattack"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
        end,

		timeline = {
			TimeEvent(0*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.taunt)
			end),
        },

        events = {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
        },
    },

	State{
		name = "build",
        tags = {"busy"},

        onenter = function(inst, data)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("banner_summon")
			inst.SoundEmitter:PlaySound(inst.sounds.taunt_2)
        end,

		timeline = {
			TimeEvent(20*FRAMES, PlayFootstep), -- TODO put in the same timeevent??? does that affect anything?
			TimeEvent(20*FRAMES, SpawnBanner),
        },

		onexit = function(inst) -- TODO remove if remains empty
		end,

        events = {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
        },
    },
}

CommonForgeStates.AddIdle(states, nil, nil, {
	TimeEvent(0, function(inst)
        --[[
		-- Summon a banner if off cd, previous state was an attack, and not recently attacked (1 second)
		if inst.banner_ready and inst.sg.laststate.tags.attack and GetTime() - inst.components.combat.lastwasattackedtime > 1 then
			inst.sg:GoToState("build")
		end--]]
        inst:PushEvent("reinforcements")
	end),
})
CommonStates.AddRunStates(states, {
	runtimeline = {
		TimeEvent(0*FRAMES, PlayFootstep ),
		TimeEvent(10*FRAMES, PlayFootstep ),
	},
}, nil, nil, nil, {
    runonupdate = function(inst)
        if IsBannerReady(inst) then
            inst.sg:GoToState("build")
        end
    end,
})
CommonForgeStates.AddSleepStates(states, {
	sleeptimeline = {
		TimeEvent(0, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.sleep)
		end),
    },
})
CommonForgeStates.AddCombatStates(states, {
	attacktimeline = { -- Bite
		TimeEvent(10*FRAMES, function(inst)
			inst.components.combat:DoAttack()
            inst.sg:RemoveStateTag("pre_attack")
		end),
	},
}, {
	attack = "attack",
}, nil, {
    onenter_attack = function(inst)
        inst.SoundEmitter:PlaySound(inst.sounds.attack)
    end,
    onenter_death = function(inst)
        inst.SoundEmitter:PlaySound(inst.sounds.death)
    end,
})
CommonForgeStates.AddTauntState(states, {
    TimeEvent(0, function(inst)
		-- Summon a banner if off cd and not recently attacked (1 second)
		if IsBannerReady(inst) then -- TODO should the build state be part of the taunt state?
			inst.sg:GoToState("build")
		end
		inst.SoundEmitter:PlaySound(inst.AnimState:IsCurrentAnimation("taunt") and inst.sounds.taunt or inst.sounds.taunt_2) -- TODO better way?
	end),
}, function(inst)
	return math.random(2) == 1 and "taunt" or "taunt_2"
end)
CommonForgeStates.AddSpawnState(states, nil, nil, nil, {
    onenter = function(inst)
        inst.SoundEmitter:PlaySound(inst.sounds.taunt)
    end,
})
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
CommonForgeStates.AddActionState(states) -- TODO what is this?
CommonForgeStates.AddFossilizedStates(states)
CommonForgeStates.AddTimeLockStates(states)

return StateGraph("crocommander", states, events, "spawn", actionhandlers)
