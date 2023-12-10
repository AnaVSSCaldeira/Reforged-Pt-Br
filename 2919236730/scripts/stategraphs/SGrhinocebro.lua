require("stategraphs/commonforgestates")

local tuning_values = TUNING.FORGE.RHINOCEBRO
local CHARGE_MAX_ROTATION = 5 -- TODO boarillas roll is currently 3.5, this probably needs to be adjusted
--------------------------------------------------------------------------
local actionhandlers = {
	ActionHandler(ACTIONS.REVIVE_CORPSE, "reviving_bro"),
}
--------------------------------------------------------------------------
local function ShakeIfClose(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, 0.5, .02, .3, inst, 10)
end

local function FootShake(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, .2, .01, .1, inst, 8)
end

local function ChargingCondition(inst)
	return inst.sg:HasStateTag("charging")
end

local charge_aoe_offset = 0
local invulnerability_time = 1
local function ChargeAOE(inst)
	COMMON_FNS.DoAOE(inst, nil, tuning_values.DAMAGE, {offset = charge_aoe_offset, range = tuning_values.CHARGE_HIT_RANGE, invulnerability_time = invulnerability_time})
end

local bump_scale = 5
local bump_radius = 3 --TODO range is not verified, but it is rather small. Might require some tuning. Also tuning value?
local function DoChestBumpAoe(inst) -- TODO point between rhinos is currently wrong
    local pos = inst:GetPosition()
    local bro_pos = inst.bro:GetPosition()
    local distance_to_bro = distsq(pos, bro_pos)
    local dist = math.sqrt(distance_to_bro) / 2
    local angle = -inst:GetAngleToPoint(bro_pos) * DEGREES
    local offset = Point(dist*math.cos(angle), 0, dist*math.sin(angle))
    local bump_pos = pos + offset
    COMMON_FNS.DoAOE(inst, nil, tuning_values.DAMAGE, {range = bump_radius, target_pos = bump_pos})
end

local function GetNearbyTargets(inst)
	local pos = inst:GetPosition()
	local targets = {}
	local ents = TheSim:FindEntities(pos.x, 0, pos.z, TUNING.FORGE.RHINOCEBRO.AOE_HIT_RANGE, { "player"}, inst:HasTag("brainwashed") and {"INLIMBO", "playerghost", "notarget", "companion", "player", "brainwashed"} or { "LA_mob", "fossil", "shadow", "playerghost", "INLIMBO" })
	for _,ent in ipairs(ents) do
		if ent ~= inst and inst.components.combat:IsValidTarget(ent) and ent.components.health and ent ~= inst.components.combat.target then
			table.insert(targets, ent)
		end
	end
	return #targets
end

local function FaceBro(inst)
	if inst.bro and not inst.bro.components.health:IsDead() then
		local pos = inst.bro:GetPosition()
		inst:ForceFacePoint(pos:Get())
	end
end
--------------------------------------------------------------------------
local events = {
	CommonForgeHandlers.OnAttacked(),
	CommonForgeHandlers.OnKnockback(),
    CommonForgeHandlers.OnVictoryPose(),
	CommonHandlers.OnAttack(), -- TODO create CommonForgeHandlers for "canattack" if needed
    CommonForgeHandlers.OnSleep(),
    CommonHandlers.OnLocomote(true,false),
	CommonForgeHandlers.OnFossilize(),
	CommonForgeHandlers.OnTimeLock(),
	EventHandler("startcheer", function(inst)
		if not inst.sg:HasStateTag("cheering") and TheWorld.components.lavaarenaevent.victory == nil then
			if not (inst.sg:HasStateTag("attack") or inst.sg:HasStateTag("frozen") or inst.sg:HasStateTag("busy")) then
				inst.sg:GoToState("cheer_pre")
			else
				inst.sg.mem.wants_to_cheer = true
				if inst.sg:HasStateTag("sleeping") then -- TODO This is handled here and not in sleep. Not sure if we want to change that (if so maybe make custom forge state that accepts new handlers?). Also do other cc's get affected? Like what if one rhino is petrified and the other cheers?
					inst.sg:GoToState("wake")
				end
			end
		end
	end),
    EventHandler("death", function(inst, data)
		inst.sg:GoToState("corpse")
    end),
    EventHandler("truedeath", function(inst, data)
    	-- Delay here since there seems to be a delay in the check in the original forge.
    	local true_death_delay = inst.bro and (inst.bro.sg.currentstate == "death" or inst.bro.sg.mem.is_true_death) and 1 or inst.bro and 1.5 or 0
        inst:DoTaskInTime(true_death_delay, function()
	    	if inst:HasTag("corpse") then
	    		inst.sg:GoToState("death")
	    	else
	    		inst.sg.mem.is_true_death = true
	    	end
	    end)
	end),
	EventHandler("respawnfromcorpse", function(inst, reviver)
		if inst:HasTag("corpse") and reviver then
			inst.sg:GoToState("death_post", reviver)
		end
	end),
	EventHandler("chest_bump", function(inst, data)
		inst.sg:GoToState("chest_bump", data)
	end),
}

local states = {
    State{ -- TODO no eventhandler? this will probably have stuff added later, leaving it like this for now
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst, playanim) -- TODO somehow convert to common forge state
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle_loop", true)
			if inst.sg.mem.wants_to_cheer then
				if inst.bro.sg:HasStateTag("cheering") then -- Only start cheering if bro was not interrupted yet.
					inst.sg:GoToState("cheer_pre")
				else -- If bro was interrupted before cheering started then reset cheer.
					inst.sg.mem.wants_to_cheer = nil
                    inst.components.combat:StartCooldown("cheer")
				end
            end
        end,
    },

    State{
        name = "attack",
        tags = {"attack", "busy", "pre_attack"},

		onenter = function(inst, target)
			inst.components.combat:StartAttack()
			inst.components.locomotor:Stop()
			inst.SoundEmitter:PlaySound(inst.sounds.attack_2)
			inst.AnimState:PlayAnimation("attack")
		end,

		timeline = {
			TimeEvent(13*FRAMES, function(inst)
				COMMON_FNS.DoAOE(inst, nil, tuning_values.DAMAGE, {offset = tuning_values.FRONT_AOE_OFFSET, range = tuning_values.AOE_HIT_RANGE})
                inst.sg:RemoveStateTag("pre_attack")
			end),
		},

        events = {
            EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
        },
    },

	State{
        name = "run_start",
        tags = { "moving", "running", "canrotate" },

        onenter = function(inst)
			if inst.components.combat:IsAttackReady("charge") and inst.components.combat.target and not (inst.bro and inst.bro:HasTag("corpse")) and not inst.components.combat:IsAttackReady("cheer") and inst.components.combat:IsValidTarget(inst.components.combat.target) then -- TODO should not check if bro is dead, that should be in the brain, should not check cheer either?
				inst.sg:GoToState("charge", inst.components.combat.target)
			else
				inst.components.locomotor:RunForward()
				inst.AnimState:PlayAnimation("run_pre")
			end
        end,

        events = {
            EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("run")
			end),
        },
    },

	State{
        name = "run",
        tags = { "moving", "running", "canrotate" },

        onenter = function(inst)
			inst.Transform:SetEightFaced()
			if inst.components.combat:IsAttackReady("charge") and inst.components.combat.target and not (inst.bro and inst.bro:HasTag("corpse")) and not inst.components.combat:IsAttackReady("cheer") and inst.components.combat:IsValidTarget(inst.components.combat.target) then -- TODO should not check if bro is dead, that should be in the brain, should not check cheer either?
				inst.sg:GoToState("charge", inst.components.combat.target)
			else
				inst.components.locomotor:RunForward()
				inst.AnimState:PlayAnimation("run_loop")
			end
        end,

		timeline = {
			TimeEvent(9*FRAMES, PlayFootstep),
			TimeEvent(9*FRAMES, FootShake),
			TimeEvent(18*FRAMES, PlayFootstep),
			TimeEvent(18*FRAMES, FootShake),
		},

        events = {
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("run")
			end),
		},

		onexit = function(inst)
			inst.Transform:SetSixFaced()
        end,
    },

	State{
        name = "run_stop",
        tags = { "idle" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
			inst.AnimState:PlayAnimation("run_pst")
        end,

		timeline = {
			TimeEvent(16*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.grunt)
			end),
		},

        events = {
            EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
			end),
        },
    },

	State{
        name = "charge", -- TODO look into ontimeout for how long charges last???
        tags = {"busy", "charging", "keepmoving", "delaysleep"},

		onenter = function(inst, target)
			inst._hashittarget = nil
			--inst.components.locomotor:RunForward()
			inst.components.locomotor:Stop() -- TODO if running prior to this state then the rhino will be attempting to go to a certain point and it messes with the velocity, this might also cause a slight pause in the velocity, double check if it does and if so then find another way.

			if inst.components.combat.target and not inst._hashittarget then
				if inst.components.combat.target:IsValid() then
					inst:ForceFacePoint(target:GetPosition())
					inst.sg.statemem.target = inst.components.combat.target
				end
			end

			inst.Transform:SetEightFaced()
			ToggleOffCharacterCollisions(inst)

			inst.SoundEmitter:PlaySound(inst.sounds.attack)
			inst.AnimState:PlayAnimation("attack2_pre")

			CreateConditionThread(inst, "attack_charge_aoe", 0, 0.1, ChargingCondition, ChargeAOE) -- TODO should this be in the charge_loop state? should targets get hit in this state? specific frame when you start getting hit?
			inst.Physics:SetMotorVelOverride(inst.components.locomotor.runspeed * 1.15, 0, 0) -- TODO tuning speed???
		end,

		onexit = function(inst)
            inst.components.combat:StartCooldown("charge")
			inst.Transform:SetSixFaced()
			ToggleOnCharacterCollisions(inst)
		end,

		timeline = {
			TimeEvent(9*FRAMES, PlayFootstep),
			TimeEvent(9*FRAMES, FootShake),
			TimeEvent(18*FRAMES, PlayFootstep),
			TimeEvent(18*FRAMES, FootShake),
		},

        events = {
            EventHandler("animover", function(inst)
				if not inst.sg.statemem.target_hit and inst.sg.statemem.target and inst.components.combat:IsValidTarget(inst.sg.statemem.target) and not inst.sg.mem.sleep_duration then
					inst.sg:GoToState("charge_loop", inst.sg.statemem.target)
				else
					inst.sg:GoToState("charge_pst", inst.sg.statemem.target)
				end
			end),
			EventHandler("onattackother", function(inst, data)
				if data.target == inst.sg.statemem.target then
					inst.sg.statemem.target_hit = true
				end
			end),
        },
    },

	State{
        name = "charge_loop",
        tags = {"attack", "busy", "charging", "keepmoving", "delaysleep"},

		onenter = function(inst, target)
			if target and not inst._hashittarget then
				if inst.components.combat:IsValidTarget(target) then
					--inst:FacePoint(target:GetPosition())
					inst.sg.statemem.target = target
				end
			end

			inst.Transform:SetEightFaced()
			ToggleOffCharacterCollisions(inst)

			inst.Physics:SetMotorVelOverride(inst.components.locomotor.runspeed*1.15, 0, 0) -- TODO tuning speed??? CHARGE_SPEED_MULT???
			inst.AnimState:PlayAnimation("attack2_loop")
		end,

		onupdate = function(inst)
			-- if target is behind, slow down and turn around
			-- otherwise keep speeding up while trying to still face the target
			-- might wanna limit how frequently all this onupdate stuff happens
			if not inst.sg.statemem.target_hit and inst.sg.statemem.target and inst.components.combat:IsValidTarget(inst.sg.statemem.target) then -- TODO currently the same as Boarillas roll, if not changed commonize it???
				local current_rotation = inst.Transform:GetRotation()
				local angle_to_target = inst:GetAngleToPoint(inst.sg.statemem.target:GetPosition())
				local angle = (current_rotation - angle_to_target + 180) % 360 - 180 -- -180 <= angle < 180, 181 = -179
				local next_rotation = math.abs(angle) <= CHARGE_MAX_ROTATION and angle or CHARGE_MAX_ROTATION * (angle < 0 and -1 or 1)
				inst.Transform:SetRotation(current_rotation - next_rotation)
			end
		end,

		onexit = function(inst)
			inst.Transform:SetSixFaced()
			ToggleOnCharacterCollisions(inst)
		end,

		timeline = {
			TimeEvent(9*FRAMES, PlayFootstep),
			TimeEvent(9*FRAMES, FootShake),
			TimeEvent(18*FRAMES, PlayFootstep),
			TimeEvent(18*FRAMES, FootShake),
		},

        events = {
            EventHandler("animover", function(inst)
				if not inst.sg.statemem.target_hit and inst.sg.statemem.target and inst.components.combat:IsValidTarget(inst.sg.statemem.target) and not inst.sg.mem.sleep_duration and (not inst.bro or not inst.bro.components.health:IsDead())then
					inst.sg:GoToState("charge_loop", inst.sg.statemem.target) -- TODO might need to have it go through the charge_loop state once more after target has been hit. The problem is that sometimes the rhino will stop right on the player as the player is hit, but other times the rhino will go a significant distance away.
				else
					inst.sg:GoToState("charge_pst", inst.sg.statemem.target)
				end
			end),
			EventHandler("onattackother", function(inst, data)
				if data.target == inst.sg.statemem.target then
					inst.sg.statemem.target_hit = true
				end
			end),
        },
    },

	State{
        name = "charge_pst",
        tags = {"busy"}, -- TODO delaysleep and keepmoving?

		onenter = function(inst, target)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("attack2_pst")
		end,

        events = {
            EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
        },
    },

	State{
		name = "cheer_pre",
        tags = {"busy", "cheering", "nosleep"},

        onenter = function(inst, data)
			if inst.bro and inst.bro.components.health and not inst.bro.components.health:IsDead() and not inst.bro.sg:HasStateTag("cheering") then -- TODO need health checks? is it possible to get here with a dead bro?
				FaceBro(inst)
				inst.bro:PushEvent("startcheer")
			end
            inst.Physics:Stop()
			inst.AnimState:PlayAnimation("cheer_pre")
        end,

		timeline = {},

		onexit = function(inst)
			inst.sg.mem.wants_to_cheer = nil
			inst.components.combat:StartCooldown("cheer") -- Start cheer cooldown just in case exiting cheer states
		end,

        events = {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("cheer_loop")
			end),
        },
    },

	State{
		name = "cheer_loop",
        tags = {"busy", "cheering", "nosleep"},

        onenter = function(inst, data)
			inst.AnimState:PlayAnimation("cheer_loop")
			inst.SoundEmitter:PlaySound(inst.sounds.cheer)

			inst.sg.statemem.buff_ready = data and data.buff_ready
            inst.sg.statemem.buffed = data and data.buffed
			inst.sg.statemem.end_cheer = data and data.end_cheer

            -- Set Cheer Timeout if Rhinobro has not started cheering yet
            if not (inst.bro and inst.bro.sg:HasStateTag("cheering") or inst.sg.statemem.buffed) then
                inst.sg:SetTimeout(data and data.timeout or tuning_values.CHEER_TIMEOUT)
            end
        end,

		timeline = {
			TimeEvent(9*FRAMES, function(inst) -- TODO this seems to be close to correct, but it may be timer based.
				-- End successful cheer check
				if inst.sg.statemem.end_cheer then
					inst.sg:GoToState("cheer_pst")
				end
			end)
		},

        ontimeout = function(inst)
            -- Queue Cheer to end if Rhinobro has not started cheering before timeout
            if not inst.bro.sg:HasStateTag("cheering") then
                inst.sg:RemoveStateTag("cheering")
                inst.sg.statemem.end_cheer = true
            end
        end,

		onexit = function(inst)
			inst.components.combat:StartCooldown("cheer") -- Reset Cheer on every onexit just in case leaving the cheer state
		end,

        events = {
			EventHandler("animover", function(inst)
				if inst.sg.statemem.end_cheer then -- TODO needed? leaving here for now, remove if not needed in final version or keep just in case something goes wrong?
					inst.sg:GoToState("cheer_pst")
				else
					local bro_is_cheering = inst.bro and inst.bro.sg.currentstate.name == "cheer_loop"
					local buff_ready = inst.sg.statemem.buff_ready
					local buffed = inst.sg.statemem.buffed
					local end_cheer = buffed or not (bro_is_cheering or inst.bro.sg.mem.wants_to_cheer)

					if buff_ready and bro_is_cheering then -- TODO this was not occurring consistently in animover in the behavioral analysis
						inst:SetBuffLevel(inst.bro_stacks + 1)
						buffed = true
						end_cheer = false -- this is just in case the other bro is interrupted as the the buff occurs which would cause this to be true and this rhino will not get a buff
					end
					--print(tostring(inst) .. " - bro_is_cheering: " .. tostring(bro_is_cheering) .. ", Buff Ready: " .. tostring(buff_ready) .. ", Buffed: " .. tostring(buffed) .. ", End Cheer: " .. tostring(end_cheer)) -- TODO remove when testing is complete and fully functioning
                    inst.sg:GoToState("cheer_loop", {buffed = buffed, buff_ready = not (buff_ready or buffed) and bro_is_cheering, end_cheer = end_cheer, timeout = inst.sg.timeout})
				end
			end),
        },
    },

	State{
		name = "cheer_pst",
        tags = {"busy", "nosleep"},

        onenter = function(inst, data)
			inst.AnimState:PlayAnimation("cheer_post")
        end,

        events = {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
        },
    },

	State{
		name = "pose",
        tags = {"busy", "posing" , "idle"},

        onenter = function(inst)
			inst.Physics:Stop()
			if inst.bro and inst.bro.components.health and not inst.bro.components.health:IsDead() then
				FaceBro(inst)
				local rotation = inst.Transform:GetRotation()
				inst.Transform:SetRotation(rotation - 180)
			end
			inst.AnimState:PlayAnimation("pose_pre", false)
			inst.AnimState:PushAnimation("pose_loop", true)
        end,

		timeline = {
			TimeEvent(15*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.cheer)
			end),
        },
    },

	--We aren't really dead, but we need help from a bro! if bro doesn't come to save us then just die.
	State{
        name = "corpse",
        tags = {"busy", "nointerrupt"},

        onenter = function(inst, data)
			inst.SoundEmitter:PlaySound(inst.sounds.death)
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
			inst:AddTag("NOCLICK")
			--ChangeToObstaclePhysics(inst) -- TODO do we want to change the physics during this state?
            --RemovePhysicsColliders(inst)
        end,

		timeline = {
			TimeEvent(14*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.bodyfall)
				ShakeIfClose(inst)
			end),
        },

        events = {
            EventHandler("animover", function(inst)
				--inst.sg:AddStateTag("corpse") -- added for death_hit animations
                inst.components.revivablecorpse:SetCorpse(true)
                if inst.sg.mem.is_true_death then
                	inst.sg:GoToState("death")
                end
            end),
            EventHandler("attacked", function(inst)
            	if inst:HasTag("corpse") then -- TODO should we also check if the rhino is currently playing the death_hit anim?
					inst.AnimState:PlayAnimation("death_hit", false)
				end
            end),
        },
    },

	State{
		name = "reviving_bro",
        tags = {"doing", "busy", "reviving"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("revive_pre", false)
			inst.AnimState:PushAnimation("revive_loop", false)
			inst.AnimState:PushAnimation("revive_loop", false)
			inst.AnimState:PushAnimation("revive_pst", false)

            if inst.SoundEmitter:PlayingSound("revive_LP") then
                inst.SoundEmitter:KillSound("revive_LP")
            end
            inst.SoundEmitter:PlaySound(inst.sounds.revive_lp, "reviveLP")

            inst.sg.statemem.action = inst:GetBufferedAction()
        end,

		onexit = function(inst)
			inst.SoundEmitter:KillSound("reviveLP")
            -- Clear the revive action if it did not clear correctly.
            if inst.bufferedaction == inst.sg.statemem.action then
                inst:ClearBufferedAction()
            end
		end,

		timeline = {
			TimeEvent(14*FRAMES, function(inst) -- TODO was 7, need to figure out what frame the bro revives on
                inst:PerformBufferedAction()
            end),
        },

        events = {
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
			end),
        },
    },

	State{
        name = "death_post",
        tags = { "busy", "nointerrupt"},

        onenter = function(inst)
			inst:RemoveTag("NOCLICK")
			inst.AnimState:PlayAnimation("death_post")
			inst.components.health:SetPercent(inst.components.revivablecorpse:GetReviveHealthPercent())
            inst.components.health:SetInvincible(true)
            inst.components.revivablecorpse:SetCorpse(false)
            inst:RemoveEventCallback("mob_death", inst.TrueDeathCheck, TheWorld)
        end,

		timeline = {},

        events = {
            EventHandler("animqueueover", function(inst)
				if inst.bro and inst.bro.sg:HasStateTag("idle") then--and inst.bro.components.health and not (inst.bro.components.health:IsDead() or inst.bro.sg:HasStateTag("hit") or inst.bro.sg:HasStateTag("stun")) then -- TODO removed the nearby targets checked because not sure if that is correct. Remove this comment when we decide on the behavior check
					inst:PushEvent("chest_bump", {initiator = true})
					inst.bro:PushEvent("chest_bump")
				else
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            inst.components.health:SetInvincible(false)
			ChangeToCharacterPhysics(inst)
        end,
    },

	State{
        name = "chest_bump",
        tags = { "busy", "nointerrupt" },

        onenter = function(inst, data)
			inst.sg.statemem.initiator = data and data.initiator
			inst.Transform:SetEightFaced()
            inst.components.locomotor:StopMoving()
			inst.AnimState:PlayAnimation("chest_bump")
			FaceBro(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.grunt) -- TODO does this play right away or on the frame they chest bump????
        end,

		timeline = {
			TimeEvent(16*FRAMES, function(inst)
				if inst.bro.sg.currentstate.name == "chest_bump" then
					if inst.sg.statemem.initiator then
						DoChestBumpAoe(inst)
					end
				end
			end),
		},

		onexit = function(inst)
			inst.Transform:SetSixFaced()
		end,

        events = {
            EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
			end),
        },
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
			inst.AnimState:PlayAnimation("death_finalfinal")
			inst.SoundEmitter:PlaySound(inst.sounds.death_final_final)
            inst.Physics:Stop()
			ChangeToObstaclePhysics(inst)
			inst.Physics:ClearCollidesWith(COLLISION.ITEMS)
        end,

		timeline = {
			TimeEvent(21*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.bodyfall)
				ShakeIfClose(inst)
			end),
        },

        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
					if inst.should_fadeout then -- TODO is this needed?
						inst:DoTaskInTime(inst.should_fadeout, ErodeAway)
					end
                end
            end),
        },
    },
}

CommonForgeStates.AddSleepStates(states, {
	starttimeline = {
		TimeEvent(38*FRAMES, function(inst)
			ShakeIfClose(inst)
			inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/trails/bodyfall") -- TODO what bodyfall sound does this use? the one in the prefab is different...
		end),
	},
	sleeptimeline = {
		TimeEvent(0, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.sleep_in)
		end),
		TimeEvent(24*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.sleep_out)
		end),
	},
},{
	onsleep = function(inst)
		inst.SoundEmitter:PlaySound(inst.sounds.sleep_pre)
		ToggleOnCharacterCollisions(inst) --TODO this is here to fix sliding, somehow they're reaching the sleepstate without this being called.
	end,
})
CommonForgeStates.AddHitState(states)
CommonForgeStates.AddTauntState(states, {
	TimeEvent(10*FRAMES, function(inst)
		inst.SoundEmitter:PlaySound(inst.sounds.taunt)
	end),
})
CommonForgeStates.AddSpawnState(states, {
	TimeEvent(10*FRAMES, function(inst)
		inst.SoundEmitter:PlaySound(inst.sounds.taunt)
	end),
})
CommonForgeStates.AddKnockbackState(states)
CommonForgeStates.AddStunStates(states, {
	stuntimeline = {
		TimeEvent(5*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.hit)
		end),
		TimeEvent(10*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.hit)
		end),
		TimeEvent(15*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.hit)
		end),
		TimeEvent(20*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.hit)
		end),
		TimeEvent(25*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.hit)
		end),
		TimeEvent(30*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.hit)
		end),
		TimeEvent(35*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.hit)
		end),
		TimeEvent(40*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.hit)
		end),
	},
}, nil, {
	stun = "grunt",
	hit = "grunt",
},{
    onstun = function(inst, data)
		inst.sg.statemem.flash = 0 -- TODO what is this?
    end,
    onexitstun = function(inst)
        inst.components.health:SetInvincible(false)
		inst.components.health:SetAbsorptionAmount(0)
		--inst.components.bloomer:PopBloom("leap") -- TODO needed?
		--inst.components.colouradder:PopColour("leap")
    end,
})
CommonForgeStates.AddActionState(states)
--CommonStates.AddFrozenStates(states)
CommonForgeStates.AddFossilizedStates(states, { -- TODO the original klei file has some fossilization stuff in it, check if we need it
	fossilizedtimeline = {
		TimeEvent(8*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.sleep_out)
		end),
		TimeEvent(39*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.sleep_out)
		end),
		TimeEvent(71*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.sleep_out)
		end),
	},
	unfossilizedtimeline = {
		TimeEvent(10*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/fossilized_break")
		end),
	},
},{
    unfossilized = {"fossilized_pst_r", "fossilized_pst_l"}
},{
	fossilized = "dontstarve/common/lava_arena/fossilized_pre_2",
})
CommonForgeStates.AddTimeLockStates(states)

return StateGraph("rhinocebro", states, events, "spawn", actionhandlers)
