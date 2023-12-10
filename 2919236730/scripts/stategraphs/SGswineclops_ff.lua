require("stategraphs/commonstates")
local tuning_values = {
    HEALTH = 42500, --Pretty sure this is exact

    GUARD_TIME = 15,
    --speed gets multiplied by 1.05 due to scaling.
    RUNSPEED = 10,
    WALKSPEED = 4,

    DAMAGE = 200, --confirmed to be the base. when buffed this increases to 250.

    TAUNT_CD = 10, --almost certain that its determined by battlecry.
    ATTACK2_CD = 3,

    BUFF_DAMAGE = 1.25,
    BUFF_DEFENSE = 0.5,

    ATTACK_RANGE = 3, --either 2 or 3, will tune this later.
    HIT_RANGE = 3, --need more information on hitranges.

    AOE_HIT_RANGE = 6, --going to assume that that all groundpounds and slams use the same radius.

    ATTACK2_RANGE = 8, --to start bellyflop range, mostly use if the target is on the run while hes walking.
    ATTACK2_HIT_RANGE = 0,

    ATTACK_PERIOD = 2,
    ATTACK_GUARD_PERIOD = 1, --unused now

    ATTACK2_CD = 7, --Bellyflop

    --These are for determining the max
    INITIALSHIELD_TRIGGER = 0.9,
    PHASE1_TRIGGER = 0.3,

    ATTACK_KNOCKBACK = 2,
}
local function ShakeIfClose(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, .25, .015, .25, inst, 10)
end

local function ShakePound(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, 0.5, .03, .5, inst, 30)
end

local function ShakeRoar(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, 0.8, .03, .5, inst, 30)
end

local function FindDouble(inst, tags) --ripped from the cleanup branch
	local pos = inst:GetPosition()
	local ents = TheSim:FindEntities(pos.x, 0, pos.z, 255, tags)
	local doubles = {}
	if ents and #ents > 0 then
		for i, v in ipairs(ents) do
			if v:IsValid() and v.components.health and not v.components.health:IsDead() and v ~= inst then
				table.insert(doubles, v)
			end
		end
	end
	return #doubles
end

local function GetCD(inst)
	local health = inst.components.health:GetPercent()

	if health <= 0.3 then
		return 8
	else
		return 20
	end
end

local function DoFrontAoE(inst)
	local pos = inst:GetPosition()
	local angle = -inst.Transform:GetRotation() * DEGREES
	local offset = 3
	local targetpos = {x = pos.x + (offset * math.cos(angle)), y = 0, z = pos.z + (offset * math.sin(angle))}
	local ents = TheSim:FindEntities(targetpos.x,0,targetpos.z, tuning_values.HIT_RANGE, nil, COMMON_FNS.GetAllyTags(inst))
	local targets = {}
	if ents and #ents > 0 then
		for i, v in ipairs(ents) do
			if v:IsValid() and v.components.health and not v.components.health:IsDead() and v.components.combat then
				--v.components.combat:GetAttacked(inst, inst.components.combat.defaultdamage)
				--inst:PushEvent("onattackother", { target = v })
				table.insert(targets, v)
			end
		end
	end
	if targets and #targets > 0 then
		for i, v in ipairs(targets) do
			if v:IsValid() and v.components.health and not v.components.health:IsDead() and v.components.combat then
				v.components.combat:GetAttacked(inst, inst.components.combat:CalcDamage(v))
				inst:PushEvent("onattackother", { target = v })
			end
		end
	else
		inst:PushEvent("onmissother")
	end
end

local function DoSlam(inst)
	local pos = inst:GetPosition()
	local ents = TheSim:FindEntities(pos.x,0,pos.z, 7, nil, COMMON_FNS.GetAllyTags(inst))
	inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/bonehit2")
	inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/trails/bodyfall")
	if ents and #ents > 0 then
		for i, v in ipairs(ents) do
			if v:IsValid() and v.components.health and not v.components.health:IsDead() and v.components.combat and v ~= inst then
				v.components.combat:GetAttacked(inst, inst.components.combat:CalcDamage(v))
			end
		end
	end
end

local function DoGroundPound(inst)
	local pos = inst:GetPosition()
	local ents = TheSim:FindEntities(pos.x,0,pos.z, 7, nil, COMMON_FNS.GetAllyTags(inst))
	ShakeAllCameras(CAMERASHAKE.FULL, 0.5, .03, .5, inst, 30)
	inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/bonehit2")
	inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/trails/bodyfall")
	if ents and #ents > 0 then
		for i, v in ipairs(ents) do
			if v:IsValid() and v.components.health and not v.components.health:IsDead() and v.components.combat and v ~= inst then
				v.components.combat:GetAttacked(inst, inst.components.combat:CalcDamage(v))
			end
		end
	end
end

local function LocateNearbyHealingCircle(inst)
	local pos = inst:GetPosition()
	local circle = FindEntity(inst, 255,  nil, nil, {"notarget"}, {"healingcircle"}, {"healingcircle"}) or nil
	return circle
end

local function BreakBlock(inst)
    RemoveTask(inst.guard_timer)
    inst._bufftype:set(0)
    inst.isguarding = nil
    inst.components.combat:RemoveDamageBuff("swineclops_guard_mode_buff", true)
    inst.components.combat:SetAttackPeriod(tuning_values.ATTACK_PERIOD)
    inst.components.combat:SetHurtSound(nil)
    if inst.components.health:GetPercent() <= 0.9 then
        inst.shieldtime_end = nil
    end
    if inst.altattack then
        inst.components.combat:SetRange(8, 0)
    end
    inst.components.combat:SetAttackPeriod(tuning_values.ATTACK_PERIOD)
    if not inst.sg:HasStateTag("busy") then
        inst.sg:GoToState("block_pst")
    end
end

local function CalcJumpSpeed(inst, target)
    local x, y, z = target.Transform:GetWorldPosition()
    local distsq = inst:GetDistanceSqToPoint(x, y, z)
    if distsq > 0 then
		print(distsq)
        inst:ForceFacePoint(x, y, z)
        local dist = math.sqrt(distsq) - (inst:GetPhysicsRadius(0) + target:GetPhysicsRadius(0))
        if dist > 0 then
            return math.min(10, dist) / (10 * FRAMES)
        end
    end
    return 0
end

local function SetJumpPhysics(inst)
	ToggleOffCharacterCollisions(inst)
end

local function SetNormalPhysics(inst)
	ToggleOnCharacterCollisions(inst)
end

-----------------------------------------------------


local function DoAttackBuff(inst)
	inst.components.combat:SetHurtSound(nil)
	inst._bufftype:set(2)
    inst.components.combat:RemoveDamageBuff("swineclops_guard_mode_buff", true)
    inst.components.combat:AddDamageBuff("swineclops_battlecry_buff", tuning_values.BATTLECRY_BUFF, false)
end

local function DoDefenseBuff(inst)
	if inst.components.health:GetPercent() <= 0.9 then
		inst.shieldend_task = inst:DoTaskInTime(tuning_values.GUARD_TIME, function(inst) inst.shieldtime_end = true end)
	else
		inst.shieldtime_end = true
	end
	inst.components.combat:SetHurtSound("dontstarve/creatures/lava_arena/boarrior/bonehit2")
    inst._bufftype:set(1)
	inst.components.combat:RemoveDamageBuff("swineclops_battlecry_buff")
    inst.components.combat:AddDamageBuff("swineclops_guard_mode_buff", TUNING.FORGE.SWINECLOPS.GUARD_BUFF, true)
end
-----------------------------------------------------

local events=
{
	EventHandler("attacked", function(inst, data)
		if data.stimuli and data.stimuli == "strong" and not (inst.isguarding or inst.sg:HasStateTag("nointerrupt")) and not inst.components.health:IsDead() then
			inst.sg:GoToState("hit")
		elseif data.stimuli and (data.stimuli == "electric" or data.stimuli == "explosive") and not inst.components.health:IsDead() then
			inst.sg:GoToState("stun", data)
		elseif not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") and (inst.sg.mem.last_hit_time == nil or inst.sg.mem.last_hit_time + TUNING.FORGE.HIT_RECOVERY < GetTime())  then
			inst.sg:GoToState(inst.isguarding and "hit_guard" or "hit")
		end
	end),
	EventHandler("victorypose", function(inst)
		if not inst.sg:HasStateTag("busy") then
			inst.sg:GoToState("pose")
		end
	end),
	--Switch to defensive state
	EventHandler("entershield", function(inst, data)
		if not inst.components.health:IsDead() then
			if inst.components.health:GetPercent() > 0.9 then
				inst.shieldtime_end = true
			end
			if not inst.sg:HasStateTag("busy") and not inst.sg:HasStateTag("nointerrupt") then
				inst.sg:GoToState("block_pre")
			else
				inst.sg.mem.wants_to_sheild = true
			end
		end
	end),
	EventHandler("exitshield", function(inst, data)
		BreakBlock(inst)
		if inst.components.health:GetPercent() > 0.9 then
			inst.shieldtime_end = true
		end
		if not inst.sg:HasStateTag("busy") and not inst.sg:HasStateTag("nointerrupt") then
			inst.sg:GoToState("block_pst")
		end
	end),
    EventHandler("death", function(inst, data)
		inst.sg:GoToState("death")
    end),
    EventHandler("doattack", function(inst, data)
		if not inst.components.health:IsDead() and (inst.sg:HasStateTag("hit") or not inst.sg:HasStateTag("busy")) then
			if inst.isguarding and inst.isguarding == true then
				inst.sg:GoToState("attack_guard", data.target)
			else
				if inst.altattack and inst.altattack == true then
					inst.sg:GoToState("attack2", data.target)
				else
					inst.sg:GoToState("attack", data.target)
				end
			end
		end
	end),
   -- CommonHandlers.OnSleep(),
   EventHandler("gotosleep", function(inst)
		if not inst.sg.mem.fossil_to_sleep and not inst.sg.mem.wants_to_sleep and not inst.sg:HasStateTag("nofreeze") and not inst.sg:HasStateTag("sleeping") then
			inst.sg.mem.wants_to_sleep = true
			local circle = LocateNearbyHealingCircle(inst) or nil
			inst.sg:GoToState("attack2", circle )
		elseif inst.sg.mem.fossil_to_sleep then
			--Leo: Leaving this here because I want to see if this ever runs.
			print("fossil sleep check")
			inst.sg.mem.wants_to_sleep = true
			inst.sg:GoToState(inst.sg:HasStateTag("sleeping") and "sleeping" or "sleep")
		elseif inst.components.health and not inst.components.health:IsDead() then
			inst.sg:GoToState("sleep")
		end
   end),
    --CommonHandlers.OnLocomote(true,false),
	EventHandler("locomote", function(inst, data)
        if inst.sg:HasStateTag("busy") then
            return
        end
        local is_moving = inst.sg:HasStateTag("moving")
        local should_move = inst.components.locomotor:WantsToMoveForward()

        if is_moving and not should_move then
			inst.sg:GoToState(inst.isguarding and "run_stop" or "walk_stop")
        elseif not is_moving and should_move then
			inst.sg:GoToState(inst.isguarding and "run_start" or "walk_start")
        elseif data.force_idle_state and not (is_moving or should_move or inst.sg:HasStateTag("idle")) then
            inst.sg:GoToState("idle")
        end
    end),
	CommonHandlers.OnFossilize(),
    CommonHandlers.OnFreeze(),
}


 local states=
{

    State{
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst, playanim)
            inst.Physics:Stop()
			if inst.sg.mem.wants_to_sheild then
				inst.sg:GoToState("block_pre")
			elseif inst.isguarding and inst.isguarding == true then
				inst.AnimState:PlayAnimation("block_loop", true)
			else
				inst.AnimState:PlayAnimation("idle_loop", true)
			end
        end,

    },

	State{
        name = "attack_guard", --punch
        tags = {"attack", "busy"},

		onenter = function(inst, target)
		local buffaction = inst:GetBufferedAction()
        local target = buffaction ~= nil and buffaction.target or nil
		if inst.components.combat.target ~= nil then
            if inst.components.combat.target:IsValid() then
                inst:ForceFacePoint(inst.components.combat.target:GetPosition())
                inst.sg.statemem.attacktarget = inst.components.combat.target
            end
        end
        inst.components.combat:StartAttack()
        inst.components.locomotor:Stop()
        inst.Physics:Stop()
		inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/swipe")

        inst.AnimState:PlayAnimation("block_counter")
	end,

	onexit = function(inst)
		inst.sg.statemem.attacktarget = nil
    end,

    timeline=
    {
			--TimeEvent(1*FRAMES, function(inst)inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/spidermonkey/swipe") end),
            TimeEvent(6*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/attack")
				DoFrontAoE(inst)
			end),
    },

        events=
        {
			EventHandler("onhitother", function(inst)
				 inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/attack")
			end),
            EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
			end),
        },

    },

    State{
        name = "attack", --punch
        tags = {"attack", "busy"},

		onenter = function(inst, target)
		local buffaction = inst:GetBufferedAction()
        local target = buffaction ~= nil and buffaction.target or nil
		if inst.components.combat.target ~= nil then
            if inst.components.combat.target:IsValid() then
                inst:ForceFacePoint(inst.components.combat.target:GetPosition())
                inst.sg.statemem.attacktarget = inst.components.combat.target
            end
        end
        inst.components.combat:StartAttack()
        inst.components.locomotor:Stop()
        inst.Physics:Stop()
		inst.currentcombo = inst.currentcombo + 1
		inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/swipe")
        inst.AnimState:PlayAnimation("attack1", false)
		inst.leftjab = nil
		if inst.currentcombo >= inst.maxpunches then
			inst.AnimState:PushAnimation("attack1_pst", false)
		end
	end,

	onexit = function(inst)
		if inst.currentcombo >= inst.maxpunches then
			inst.currentcombo = 0
		end
    end,

    timeline=
    {
			--TimeEvent(1*FRAMES, function(inst)inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/spidermonkey/swipe") end),
            TimeEvent(6*FRAMES, function(inst)
				DoFrontAoE(inst)
			end),
    },

        events=
        {
			EventHandler("onmissother", function(inst)
				inst.AnimState:PushAnimation("attack1_pst", false)
				inst.currentcombo = 9999 --end combo the lazy way
			end),
			EventHandler("onhitother", function(inst)
				 --inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/attack")
			end),
            EventHandler("animqueueover", function(inst)
				inst.sg:GoToState(inst.currentcombo < inst.maxpunches and "attack_loop" or "idle")
			end),
        },

    },

	State{
        name = "attack_loop", --punch
        tags = {"attack", "busy"},

		onenter = function(inst, target)
		local buffaction = inst:GetBufferedAction()
        local target = buffaction ~= nil and buffaction.target or nil
		if inst.components.combat.target ~= nil then
            if inst.components.combat.target:IsValid() then
                inst:ForceFacePoint(inst.components.combat.target:GetPosition())
                inst.sg.statemem.attacktarget = inst.components.combat.target
            end
        end
        inst.components.combat:StartAttack()
        inst.components.locomotor:Stop()
        inst.Physics:Stop()
		inst.currentcombo = inst.currentcombo + 1
		inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/swipe")
        inst.AnimState:PlayAnimation((inst.maxpunches > 2 and inst.currentcombo == inst.maxpunches) and "attack3" or "attack2", false)
		if inst.maxpunches == 2 or (inst.currentcombo > inst.maxpunches or (inst.sg.statemem.attacktarget and inst.sg.statemem.attacktarget.components.health:IsDead())) then
			inst.AnimState:PushAnimation("attack2_pst", false)
		elseif inst.leftjab and (inst.currentcombo > inst.maxpunches or (inst.sg.statemem.attacktarget and inst.sg.statemem.attacktarget.components.health:IsDead())) then
			inst.AnimState:PushAnimation("attack1_pst", false)
		end

		if not inst.leftjab then
			inst.leftjab = true
		end
	end,

	onexit = function(inst)
		if inst.currentcombo >= inst.maxpunches then
			inst.currentcombo = 0
		end
    end,

    timeline=
    {
            TimeEvent(6*FRAMES, function(inst)
				DoFrontAoE(inst)
				if inst.maxpunches > 2 and inst.currentcombo == inst.maxpunches then
					inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/attack")
				end
			end),
    },

        events=
        {

			EventHandler("onmissother", function(inst)
				if inst.currentcombo > inst.maxpunches and inst.currentcombo ~= inst.maxpunches then
					inst.AnimState:PushAnimation("attack2_pst", false)
				end
				inst.currentcombo = 9999 --end combo the lazy way
			end),
            EventHandler("onhitother", function(inst, data)
				if data.target and data.target.components.health and data.target.components.health:IsDead() then
					inst.currentcombo = 9999
				end
			end),
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState(inst.currentcombo < inst.maxpunches and "attack_loop2" or "idle")
			end),
        },

    },

	State{
        name = "attack_loop2", --left punch
        tags = {"attack", "busy"},

		onenter = function(inst, target)
		local buffaction = inst:GetBufferedAction()
        local target = buffaction ~= nil and buffaction.target or nil
		if inst.components.combat.target ~= nil then
            if inst.components.combat.target:IsValid() then
                inst:ForceFacePoint(inst.components.combat.target:GetPosition())
                inst.sg.statemem.attacktarget = inst.components.combat.target
            end
        end

        inst.components.combat:StartAttack()
        inst.components.locomotor:Stop()
        inst.Physics:Stop()
		inst.currentcombo = inst.currentcombo + 1
		inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/swipe")
        inst.AnimState:PlayAnimation((inst.maxpunches > 2 and inst.currentcombo == inst.maxpunches) and "attack3" or "attack1b", false)
		if inst.maxpunches == 2 or (inst.currentcombo > inst.maxpunches or (inst.sg.statemem.attacktarget and inst.sg.statemem.attacktarget.components.health:IsDead())) then
			inst.AnimState:PushAnimation("attack1_pst", false)
		end
	end,

	onexit = function(inst)
		if inst.currentcombo >= inst.maxpunches then
			inst.currentcombo = 0
		end
    end,

    timeline=
    {
			--TimeEvent(1*FRAMES, function(inst)inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/spidermonkey/swipe") end),
            TimeEvent(6*FRAMES, function(inst)
				DoFrontAoE(inst)
			end),
    },

        events=
        {

			EventHandler("onmissother", function(inst)
				if inst.currentcombo > inst.maxpunches and inst.currentcombo ~= inst.maxpunches then
					inst.AnimState:PushAnimation("attack1_pst", false)
				end
				inst.currentcombo = 99 --end combo the lazy way
			end),
            EventHandler("onhitother", function(inst, data)
				if data.target and data.target.components.health and data.target.components.health:IsDead() then
					inst.currentcombo = 99
				end
			end),
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState(inst.currentcombo < inst.maxpunches and "attack_loop" or "idle")
			end),
        },

    },

	State{
        name = "attack2", --bellyflop
        tags = {"busy", "slamming", "nofreeze"},

		onenter = function(inst, target)
		inst.Physics:Stop()

		inst.altattack = nil

		if inst.brain ~= nil then
			inst.brain:Stop()
		end

		if target ~= nil then
            if target:IsValid() then
                inst:ForceFacePoint(target:GetPosition())
                inst.sg.mem.attacktarget = target
            end
        end
        inst.components.combat:StartAttack()

		inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/jump")
        inst.AnimState:PlayAnimation("bellyflop")
	end,

	onexit = function(inst)
		--inst.components.combat:SetRange(3, 5)
		inst.sg.mem.attacktarget = nil
		inst.sg.mem.jump = nil
		inst.sg.mem.speed = nil
		SetNormalPhysics(inst)
		inst.components.combat:SetRange(tuning_values.ATTACK_RANGE, tuning_values.ATTACK_RANGE)
		if inst.jumptask then
			inst.jumptask:Cancel()
			inst.jumptask = nil
		end
		inst.jumptask = inst:DoTaskInTime(tuning_values.ATTACK2_CD, function(inst) inst.altattack = true
			if not inst.isguarding then
				--use altattack as a check for setting this on the appropriate states
				inst.components.combat:SetRange(8, 0)
			end
		end)
		if inst.brain ~= nil then
			inst.brain:Start()
		end
    end,

	onupdate = function(inst)
        if inst.sg.statemem.jump then
            inst.Physics:SetMotorVel(inst.sg.mem.speed and inst.sg.mem.speed * 1.2 or 5, 0, 0)
        end
    end,

    timeline=
    {
		TimeEvent(1*FRAMES, function(inst)
			inst.sg.statemem.jump = true
			SetJumpPhysics(inst)
			inst.sg:AddStateTag("nointerrupt")
			if inst.sg.mem.attacktarget and inst.sg.mem.attacktarget:IsValid() then
				inst.sg.mem.speed = CalcJumpSpeed(inst, inst.sg.mem.attacktarget)
			end
		end),
		TimeEvent(13*FRAMES, function(inst)
			--inst:PerformBufferedAction()
			inst.components.locomotor:Stop()
			inst.sg.statemem.jump = false
			inst.Physics:Stop()
			DoSlam(inst)
			SetNormalPhysics(inst)
			ShakePound(inst)
			inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/trails/bodyfall")
			--the only time he should be bellyflopping while in defensive stance is when hes being put to sleep.
			BreakBlock(inst)
			inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/chain_hit")
		end),
    },

        events=
        {
            EventHandler("animqueueover", function(inst)
				if inst.sg.mem.wants_to_sleep then
					inst.sg.mem.wants_to_sleep = nil
					inst.sg:GoToState("sleep")
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
			inst.sg.mem.wants_to_sleep = nil
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("hit")
			inst.sg.mem.last_hit_time = GetTime()
			inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/hit")
			inst.currentcombo = 0
        end,

		timeline =
        {
            -- Timing of the gift box opening animation on giftitempopup.lua
            TimeEvent(8 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/step")
            end),
        },

        events=
        {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
        },
    },

	State{
		name = "hit_guard",
        tags = {"busy", "hit"},

        onenter = function(inst)
			inst.sg.mem.wants_to_sleep = nil
            inst.Physics:Stop()
			inst.sg.mem.last_hit_time = GetTime()
            inst.AnimState:PlayAnimation("block_hit")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/bonehit2")
			inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/chain_hit")
        end,

        events=
        {
			EventHandler("animover", function(inst)
				if inst.isguarding and (inst.components.health:GetPercent() <= 0.9 and inst.shieldtime_end) then
					BreakBlock(inst)
				end
				inst.sg:GoToState("idle")
			end),
        },
    },

	State{
		name = "taunt1",
        tags = {"busy"},

        onenter = function(inst, force)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("taunt")
			DoAttackBuff(inst)
        end,

		timeline=
        {
			TimeEvent(10*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/taunt")
				ShakeRoar(inst)
			end),
			TimeEvent(24*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/bonehit2")
				inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/chain_hit")
			end),
			TimeEvent(28*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/bonehit2")
				inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/chain_hit")
			end),
			TimeEvent(32*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/bonehit2")
				inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/chain_hit")
			end),
			TimeEvent(36*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/bonehit2")
				inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/chain_hit")
			end),
        },

		onexit = function(inst)
			--if inst.canbuff == false then inst:DoTaskInTime(20, function(inst) inst.canbuff = true end) end
		end,


        events=
        {
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

	State{
		name = "spawn",
        tags = {"busy", "canattack"},

        onenter = function(inst, force)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("taunt")
			--DoAttackBuff(inst)
        end,

		timeline=
        {
			TimeEvent(10*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/taunt")
				ShakeRoar(inst)
			end),
			TimeEvent(24*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/bonehit2")
				inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/chain_hit")
			end),
			TimeEvent(28*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/bonehit2")
				inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/chain_hit")
			end),
			TimeEvent(32*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/bonehit2")
				inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/chain_hit")
			end),
			TimeEvent(36*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/bonehit2")
				inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/chain_hit")
			end),
        },

		onexit = function(inst)

		end,


        events=
        {
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

	State{
		name = "taunt",
        tags = {"busy"},

        onenter = function(inst, force)
			inst.Physics:Stop()
			--Leo: change this to check for the attack debuff, if it has it then just do the pound taunt.
			if inst.components.health:GetPercent() <= 0.5 and not inst.components.combat:HasDamageBuff("swineclops_battlecry_buff") and not inst.isguarding then
				inst.sg:GoToState("taunt1")
			else
				inst.AnimState:PlayAnimation("taunt2")
			end
        end,

		timeline=
        {
			TimeEvent(8*FRAMES, function(inst)
				DoGroundPound(inst)
				inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/chain_hit")
			end),
			TimeEvent(11*FRAMES, function(inst)
				--DoGroundPound(inst)
				inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/chain_hit")
			end),
			TimeEvent(14*FRAMES, function(inst)
				DoGroundPound(inst)
				inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/chain_hit")
			end),
			TimeEvent(24*FRAMES, function(inst)
				DoGroundPound(inst)
				inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/chain_hit")
			end),
        },

		onexit = function(inst)
			--if inst.taunt_event == false then inst:DoTaskInTime(7, function(inst) inst.taunt_event = true end) end
		end,

        events=
        {
			EventHandler("animover", function(inst)
				if inst.components.health:GetPercent() > 0.9 or inst.sg.mem.wants_to_sheild then
					inst.sg:GoToState("block_pre")
				else
					inst.sg:GoToState("idle")
				end
			end),
        },
    },

	--block
	State{
		name = "block_pre",
        tags = {"busy"},

        onenter = function(inst, force)
			inst.Physics:Stop()
			inst.isguarding = true
			inst.components.combat:SetRange(tuning_values.ATTACK_RANGE, tuning_values.ATTACK_RANGE)
			inst.sg.mem.wants_to_sheild = nil
			DoDefenseBuff(inst)
			inst.AnimState:PlayAnimation("block_pre")
        end,

		onexit = function(inst)
			--inst:DoTaskInTime(60, function(inst) inst.taunt2_event = true end)
			--inst:DoTaskInTime(30, BreakBlock)
		end,

		timeline=
        {
			TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/chain_hit") inst.sg:RemoveStateTag("busy") end),
			--TimeEvent(10*FRAMES, ShakeRoar),
        },

        events=
        {
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
			inst.components.armorbreak_debuff:RemoveDebuff()
			--inst.components.debuffable:RemoveDebuff("swineclops_attackbuff")
			if inst.components.combat:HasDamageBuff("swineclops_guard_mode_buff") then
				BreakBlock(inst)
			end
			if FindDouble(inst, {"epic", "LA_mob"}) < 1 and inst.EnableCameraFocus then
				inst:EnableCameraFocus(true)
			end
			inst:AddTag("NOCLICK")
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            ChangeToObstaclePhysics(inst)
			inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
        end,

		timeline=
        {
			TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/death") ShakePound(inst) end),
			TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/destroy_magic") end),
			TimeEvent(43*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/bonehit2")
				ShakePound(inst)
			end),
			TimeEvent(62*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/chain_hit")
				ShakePound(inst)
			end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then

                end
            end),
        },

    },

	State {
        name = "sleep",
        tags = { "sleeping", "busy" }, --add tag "busy" if you hate sliding

        onenter = function(inst)
			BreakBlock(inst)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("sleep_pre")
			inst.sg.mem.wants_to_sleep = nil
			inst.sg.mem.fossil_to_sleep = nil
            --if fns ~= nil and fns.onsleep ~= nil then
                --fns.onsleep(inst)
            --end
        end,

        timeline =
		{
			TimeEvent(8*FRAMES, function(inst)
				--ShakeIfClose(inst)
				inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/step")
			end),
			TimeEvent(30*FRAMES, function(inst)
				--ShakeIfClose(inst)
				inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/step")
			end),
		},

        events =
        {
            EventHandler("animover", function(inst)
				inst.sg:GoToState("sleeping")
			end ),
            EventHandler("onwakeup", function(inst) inst.sg:GoToState("wake") end),
        },
    },

    State
    {
        name = "sleeping",
        tags = { "sleeping", "busy" },

        --onenter = onentersleeping,

		onenter = function(inst)
			inst.components.locomotor:StopMoving()
			inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/sleep_in")
			inst.AnimState:PlayAnimation("sleep_loop")
		end,

		timeline=
        {
			TimeEvent(30*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/sleep_out") end),
			--inst.SoundEmitter:PlaySound("dontstarve/creatures/hound/sleep")
			--end),
        },

        events =
        {
			--Leo: Temp fix for perma sleeping bug:
			EventHandler("attacked", function(inst) inst.sg:GoToState("wake") end ),

			---
			EventHandler("animover", function(inst)
				inst.sg:GoToState("sleeping")
			end),
			EventHandler("onwakeup", function(inst) inst.sg:GoToState("wake") end),
        },
    },

    State
    {
        name = "wake",
        tags = { "busy", "waking" },

        onenter = function(inst)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("sleep_pst")
            if inst.components.sleeper ~= nil and inst.components.sleeper:IsAsleep() then
                inst.components.sleeper:WakeUp()
            end
            --if fns ~= nil and fns.onwake ~= nil then
                --fns.onwake(inst)
            --end
        end,

        timeline=
        {
			TimeEvent(23*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/step") ShakeIfClose(inst) end),
        },

        events =
        {
            EventHandler("animover", function(inst)
				if inst.components.health:GetPercent() >= tuning_values.INITIALSHIELD_TRIGGER or inst.sg.mem.wants_to_sheild then
					inst.sg:GoToState("block_pre")
				else
					inst.sg:GoToState("idle")
				end
			end),
        },
    },

	State{
		name = "pose",
        tags = {"busy", "posing" , "idle"},

        onenter = function(inst)
			inst.Physics:Stop()
			if FindDouble(inst, {"epic", "LA_mob"}) < 1 and inst.EnableCameraFocus then
				inst:EnableCameraFocus(true)
			end
			inst.AnimState:PlayAnimation("end_pose_pre", false)
			inst.AnimState:PushAnimation("end_pose_loop", true)
        end,

		timeline=
        {
			TimeEvent(11*FRAMES, function(inst)
				if not TheNet:IsDedicated() then
					inst:PushEvent("beetletaur._spawnflower")
				end
			end),
			--TimeEvent(10*FRAMES, ShakeRoar),
        },

        events=
        {
			--EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

	State
    {
        name = "run_start",
        tags = { "moving", "running", "canrotate" },

        onenter = function(inst)
			inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation("run_pre")

        end,

		timeline =
		{
			--TimeEvent(0*FRAMES, function(inst) inst.Physics:Stop() end ),
		},

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("run") end ),
        },
    },

	State
    {
        name = "run",
        tags = { "moving", "running", "canrotate" },

        onenter = function(inst)
			--inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/step")
			inst.components.locomotor:RunForward()
			inst.AnimState:PlayAnimation("run_loop")
        end,

		timeline = {

			TimeEvent(5*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/step") ShakeIfClose(inst) end),
			TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/step") ShakeIfClose(inst) end),
		},

        events=
			{
				EventHandler("animqueueover", function(inst)
					inst.sg:GoToState("run")
				end ),
			},

    },

	State
    {
        name = "run_stop",
        tags = { "idle" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
			inst.AnimState:PlayAnimation("run_pst")
			--inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/trails/step")
        end,

		timeline = {

			TimeEvent(2*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/step") ShakeIfClose(inst)  end),
			TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/step") ShakeIfClose(inst) end),
			--TimeEvent(1*FRAMES, ShakeIfClose),

			--TimeEvent(23*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
		},

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },

	State
    {
        name = "walk_start",
        tags = { "moving", "running", "canrotate" },

        onenter = function(inst)
			inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("walk_pre")

        end,

		timeline =
		{
			--TimeEvent(0*FRAMES, function(inst) inst.Physics:Stop() end ),
		},

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("walk") end ),
        },
    },

	State
    {
        name = "walk",
        tags = { "moving", "running", "canrotate" },

        onenter = function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/step")
			ShakeIfClose(inst)
			inst.components.locomotor:WalkForward()
			inst.AnimState:PlayAnimation("walk_loop")
        end,

		timeline = {
			TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/step") ShakeIfClose(inst) end),
		},

        events=
			{
				EventHandler("animqueueover", function(inst)
					inst.sg:GoToState("walk")
				end ),
			},

    },

	State
    {
        name = "walk_stop",
        tags = { "idle" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
			inst.AnimState:PlayAnimation("walk_pst")
			--inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/trails/step")
        end,

		timeline = {

			TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/step") ShakeIfClose(inst) end),
			--TimeEvent(1*FRAMES, ShakeIfClose),

			--TimeEvent(23*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
		},

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },

	State{
		name = "block_pst",
        tags = {"busy"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("block_pst")
        end,

		timeline=
        {

        },

        events=
        {
			EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                        inst.sg:GoToState("idle")
                end
            end),
        },
    },

	State{
		name = "stun",
        tags = {"busy", "stunned", "nofreeze"},

        onenter = function(inst, data)
			inst.sg.mem.wants_to_sleep = nil
			inst.sg.mem.fossil_to_sleep = nil
			BreakBlock(inst)
            inst.Physics:Stop()
			inst.currentcombo = 0
			inst.sg.mem.stimuli = data.stimuli
			if data.stimuli and data.stimuli == "electric" then
				inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/grunt")
				inst.AnimState:PlayAnimation("stun_loop", true)
				inst.sg:SetTimeout(1)
				inst.components.combat:SetTarget(data.attacker and data.attacker or nil)
				inst.aggrotimer = GetTime() + TUNING.FORGE.AGGROTIMER_STUN
			else
				inst.lasttarget = nil --should allow previous target to be targeted again if hes closest.
				inst.components.combat:SetTarget(nil)
				inst.AnimState:PlayAnimation("stun_loop")
				inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/grunt")
			end
			inst.sg.statemem.flash = 0
        end,

		timeline=
        {
			TimeEvent(5*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/grunt") end),
			TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/grunt") end),
			TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/grunt") end),
			TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/grunt") end),
			TimeEvent(25*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/grunt") end),
			TimeEvent(30*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/grunt") end),
			TimeEvent(35*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/grunt") end),
			TimeEvent(40*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/forge2/beetletaur/grunt") end),
        },

		onexit = function(inst)
			inst.components.health:SetInvincible(false)
			inst.components.health:SetAbsorptionAmount(0)
			--inst.components.bloomer:PopBloom("leap")
            --inst.components.colouradder:PopColour("leap")
        end,

		ontimeout = function(inst)
			inst.sg:GoToState("stun_pst", inst.sg.mem.stimuli or nil)
		end,

        events=
        {
			EventHandler("animqueueover", function(inst) inst.sg:GoToState("stun_pst", inst.sg.mem.stimuli or nil) end),
        },
    },

	State{
		name = "stun_pst",
        tags = {"busy", "nofreeze"},

        onenter = function(inst, stimuli)
			if stimuli and stimuli == "explosive" and (not inst.last_taunt_time or (inst.last_taunt_time + TUNING.FORGE.TAUNT_CD < GetTime())) then
				inst.last_taunt_time = GetTime()
				inst.sg.mem.needstotaunt = true
			end
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("stun_pst")
        end,

		timeline=
        {
			--TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/turtillus/hide_pst") end),
        },

		onexit = function(inst)

        end,

        events=
        {
			EventHandler("animover", function(inst)
				if inst.sg.mem.needstotaunt then
					inst.sg.mem.needstotaunt = nil
					inst.sg:GoToState("taunt")
				else
					if inst.components.health:GetPercent() >= tuning_values.INITIALSHIELD_TRIGGER or inst.sg.mem.wants_to_sheild then
						inst.sg:GoToState("block_pre")
					else
						inst.sg:GoToState("idle")
					end
				end
			end),
        },
    },

	--Fossilized States--
	State
    {
        name = "fossilized",
        tags = { "busy", "fossilized", "caninterrupt" },

        onenter = function(inst, data)
            --ClearStatusAilments(inst)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("fossilized")
			inst.AnimState:PushAnimation("fossilized_shake", true)
            inst.components.fossilizable:OnFossilize(TUNING.FORGE.SWINECLOPS.FOSSIL_TIME)
        end,

        timeline =
		{

		},

        events =
        {
            EventHandler("fossilize", function(inst, data)
                inst.components.fossilizable:OnExtend(TUNING.FORGE.SWINECLOPS.FOSSIL_TIME)
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
                inst.components.fossilizable:SpawnUnfossilizeFx()
            end
        end,
    },



	State
    {
        name = "unfossilizing",
        tags = { "busy", "caninterrupt", "nofreeze" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("fossilized_shake")
        end,

        timeline = {
			TimeEvent(0*FRAMES, function(inst)
                if inst.SoundEmitter:PlayingSound("shakeloop") then
                    inst.SoundEmitter:PlayingSound("shakeloop")
                end
                inst.SoundEmitter:PlaySound("dontstarve/common/lava_arena/fossilized_shake_LP", "shakeloop")
            end),
		},

        events =
        {
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
                inst.components.fossilizable:SpawnUnfossilizeFx()
            end
            inst.SoundEmitter:KillSound("shakeloop")
        end,
    },

	State
    {
        name = "unfossilized",
        tags = { "busy", "caninterrupt", "nofreeze" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("fossilized_pst_r", false)
			inst.AnimState:PushAnimation("fossilized_pst_l", false)
            inst.components.fossilizable:SpawnUnfossilizeFx()
        end,

        timeline =
		{
			TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/fossilized_break") end),
			TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/fossilized_break") end),
		},

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
					if inst:HasTag("_isinheals") then
						inst.sg.mem.wants_to_sleep = nil
						inst.sg.mem.fossil_to_sleep = true
						inst.sg:GoToState("sleep")
					elseif inst.sg.mem.wants_to_sheild then
						inst.sg:GoToState("block_pre")
					else
						inst.sg:GoToState("idle")
					end
				end
            end),
        },
    },

}

--CommonStates.AddFrozenStates(states)

return StateGraph("swineclops_ff", states, events, "spawn")
