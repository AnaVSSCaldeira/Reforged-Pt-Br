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
require "stategraphs/commonforgestates"

local function ondeathfn(inst, data)
    if not inst.sg:HasStateTag("deactivating") then
        inst.sg:GoToState("death", data)
    end
end

local events = {
    CommonHandlers.OnLocomote(false, true),
	 EventHandler("attacked", function(inst, data)
		if not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") then
			inst.sg:GoToState("hit")
		end
	end),
	EventHandler("knockback", function(inst, data)
		if not inst.components.health:IsDead() and not inst.sg:HasStateTag("inactive") then
			inst.sg:GoToState("knockback", data)
		end
	end),
    EventHandler("death", ondeathfn),
	EventHandler("updatepetmastery", function(inst, data)
		if not inst.components.health:IsDead() then
			inst.sg:GoToState("activate", data)
		end
		if data and data.level then
			inst:UpdatePetLevel(data.level, data.force)
		end
	end),
	EventHandler("respawnfromcorpse", function(inst, reviver)
		inst.sg:GoToState("corpse_rebirth", reviver)
	end),
}

local function UpdateTaunt(inst)
	inst.taunt_start_time = GetTime()
	inst.sg:GoToState("taunt")
end

local states = {
	State{ -- TODO use commonforgestates??? currently creates a spawn state but if that is ever changed definitely convert this to use commonforgestates
        name = "taunt",
        tags = { "busy", "taunting"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
        end,

        timeline = {
			TimeEvent(3*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.taunt)
			end),
			TimeEvent(10*FRAMES, PlayFootstep),
			TimeEvent(12*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.taunt)
			end),
			TimeEvent(20*FRAMES, function(inst)
				inst.sg:RemoveStateTag("busy")
				PlayFootstep(inst)
			end),
			TimeEvent(21*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.taunt)
			end),
			TimeEvent(28*FRAMES, PlayFootstep),
			TimeEvent(30*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.taunt)
			end),
			TimeEvent(36*FRAMES, PlayFootstep),
        },

        events = {
            EventHandler("animover", function(inst)
				if GetTime() - inst.taunt_start_time > TUNING.FORGE.FORGE_BERNIE.TAUNT_DURATION then
					inst.sg:GoToState("idle")
				else
					inst.sg:GoToState("taunt")
				end
			end),
        },
    },

    State{
        name = "activate",
        tags = { "busy" }, -- TODO buff had nointerrupt tag, should it? should activate as well? if not can if buff then addstatetag nointerrupt

        onenter = function(inst, data)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("activate")
			inst:RemoveTag("notarget")

        end,

        timeline = {
            TimeEvent(5*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(inst.sounds.sit_up)
            end),
        },

        events = {
            EventHandler("animover", function(inst)
				if inst.taunt_start_time and (GetTime() - inst.taunt_start_time) <= TUNING.FORGE.FORGE_BERNIE.TAUNT_DURATION then
					inst.sg:GoToState("taunt")
				else
					inst.sg:GoToState("idle")
				end
			end),
        },
    },

	State{
        name = "deactivate",
        tags = { "busy", "deactivating", "inactive" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("deactivate")
			inst.components.health:SetInvincible(true)
			inst:AddTag("notarget")
        end,

		onexit = function(inst)
			inst:RemoveTag("notarget")
			inst.components.health:SetInvincible(false)
		end,

        timeline = {
            TimeEvent(5*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/sit_down")
            end),
        },

        events = {
            --EventHandler("animover", function(inst) inst:GoInactive() end),
        },
    },


	State{
        name = "corpse_rebirth",
        tags = { "busy", "noattack", "nopredict", "nomorph" },

        onenter = function(inst)
			inst.components.revivablecorpse:SetCorpse(false)
			--inst.components.health:SetInvincible(true) -- TODO test without, delete if confirmed not needed.
			--inst:RemoveTag("notarget")
			inst.AnimState:PlayAnimation("activate")
            if TheWorld.components.lavaarenaevent and not TheWorld.components.lavaarenaevent:IsIntermission() then
                inst:AddTag("NOCLICK")
            end
        end,

        timeline = {
			TimeEvent(5*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(inst.sounds.sit_up)
            end),
        },

        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
			--inst.components.health:SetInvincible(false)
			inst.components.health:SetPercent(1)
			inst:RemoveTag("notarget")
			ChangeToCharacterPhysics(inst)
        end,
    },
}

CommonStates.AddIdle(states) -- inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength()) TODO is this needed? what does timeout do?
CommonStates.AddWalkStates(states, {
    walktimeline = {
        TimeEvent(10*FRAMES, function(inst)
            PlayFootstep(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.walk)
        end),
        TimeEvent(30*FRAMES, function(inst)
            PlayFootstep(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.walk)
        end),
    },
    endtimeline = {
        TimeEvent(3*FRAMES, function(inst)
            PlayFootstep(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.walk)
        end),
    },
})
--CommonForgeStates.AddTauntState(states, {})
CommonForgeStates.AddHitState(states, nil, nil, {
    EventHandler("animover", UpdateTaunt),
})
CommonForgeStates.AddDeathState(states, nil, nil, nil, {
    onenter = function(inst) -- TODO "deactivating", "death" state tags needed?
        inst:AddTag("corpse") -- TODO needed?
        inst:RemoveTag("NOCLICK")
        inst.SoundEmitter:PlaySound(inst.sounds.death)
    end,
})
CommonForgeStates.AddKnockbackState(states, nil, "knockback", {
	anim = function(inst)
		inst.AnimState:PlayAnimation("activate")
		inst.AnimState:SetTime(10* FRAMES) -- TODO needed? this is commented out in all of the other stategraphs...
	end,
	animover = UpdateTaunt,
})

return StateGraph("bernie_reforged", states, events, "activate")
