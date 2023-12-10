local scorpeon_sg = deepcopy(require "stategraphs/SGscorpeon")
scorpeon_sg.name = "scorpeon_hard"
local tuning_values = TUNING.FORGE.SCORPEON

------------------
-- Spit Barrage -- Scorpeon now fires a barrage of Poison instead of just spitting once.
------------------
local attack_spit_state = scorpeon_sg.states.attack_spit
attack_spit_state.timeline[4].fn = function() end -- This event removed the busy and attack tags from the state causing taunts to interrupt the barrage.
attack_spit_state.events.animqueueover.fn = function(inst)
    inst.sg:GoToState("attack_spit_barrage", {spit_count = 1})
end

local _oldDoAttackFN = scorpeon_sg.events.doattack.fn
scorpeon_sg.events.doattack.fn = function(inst, data)
    if not inst.components.health:IsDead() and (inst.sg:HasStateTag("hit") or not inst.sg:HasStateTag("busy")) then
        if inst.components.combat:IsAttackReady("spit_bomb") then
            inst.sg:GoToState("attack_spit_bomb")
        elseif inst.components.combat:IsAttackReady("spit") then
            inst.sg:GoToState("attack_spit", data.target)
        else
            inst.sg:GoToState("attack", data.target)
        end
    end
end

local BARRAGE_SPIT_ATTACKS = 3
-- Creates the Acid Spit projectile and launches it to the targets position.
local function AcidSpit(inst)
    local target = inst.components.combat.target
    if target then
        local x, y, z = inst.Transform:GetWorldPosition()
        local angle = -inst:GetAngleToPoint(target:GetPosition():Get()) * DEGREES
        local offset = 4.25 -- TODO tuning???
        local target_pos = Point(x + (offset * math.cos(angle)), 0, z + (offset * math.sin(angle)))
        local spit = SpawnPrefab("scorpeon_projectile")
        spit.Transform:SetPosition(inst:GetPosition():Get())
        spit.thrower = inst
        spit.components.complexprojectile:Launch(target_pos, inst)
    end
end
scorpeon_sg.states["attack_spit_barrage"] = State{
    name = "attack_spit_barrage",
    tags = {"attack", "busy"},

    onenter = function(inst, data)
        inst.components.locomotor:Stop()
        inst.components.combat:StartAttack()
        inst.AnimState:PlayAnimation("spit")
        inst.sg.statemem.spit_count = (data.spit_count or 0) + 1
    end,

    onexit = function(inst, data)
        inst.components.combat:StartCooldown("spit")
    end,

    timeline = {
        TimeEvent(0, function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.taunt)
        end),
        TimeEvent(3*FRAMES, function(inst)
            AcidSpit(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.spit)
        end),
    },

    events = {
        EventHandler("animover", function(inst)
            if inst.sg.statemem.spit_count >= BARRAGE_SPIT_ATTACKS then
                inst.sg:GoToState("idle")
            else
                inst.sg:GoToState("attack_spit_barrage", {spit_count = inst.sg.statemem.spit_count})
            end
        end),
    },
}

---------------
-- Spit Bomb -- Scorpeon shoots a poison bomb on itself creating a field of poison
--------------- also coats themselves in poison adding poison to their movement and attacks
local function OnAttackOther(inst, data)
    if data.target ~= nil then
        local fx = SpawnPrefab("poison_trail")
        fx.source = inst
        fx.Transform:SetPosition(data.target.Transform:GetWorldPosition())
        fx:SetVariation(nil, GetRandomMinMax(1, 1.3), 4 + math.random() * .5)
    end
end

local function OnMissOther(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local angle = -inst.Transform:GetRotation() * DEGREES
    local fx = SpawnPrefab("poison_trail")
    fx.source = inst
    fx.Transform:SetPosition(x + TUNING.BEEQUEEN_ATTACK_RANGE * math.cos(angle), 0, z + TUNING.BEEQUEEN_ATTACK_RANGE * math.sin(angle))
    fx:SetVariation(nil, GetRandomMinMax(1, 1.3), 4 + math.random() * .5)
end
-- Creates the Acid Spit projectile and launches it to the targets position.
local MAX_TRAIL_VARIATIONS = 7 -- TODO should this be inside the trail directly?
local POISON_BOMB_DURATION = 10
local POISON_BOMB_SCALE = 2
local function AcidBomb(inst)
    local spit = SpawnPrefab("scorpeon_projectile")
    local pos = inst:GetPosition()
    spit.Transform:SetPosition(pos:Get())
    spit.thrower = inst
    local _oldOnHitFN = spit.components.complexprojectile.onhitfn
    spit.components.complexprojectile.onhitfn = function(inst, attacker, target)
        local fx = _G.SpawnPrefab("poison_trail")
        fx.Transform:SetPosition(pos:Get())
        fx.source = inst.thrower
        fx:SetVariation(math.random(MAX_TRAIL_VARIATIONS), POISON_BOMB_SCALE, POISON_BOMB_DURATION)
        -- Add poison to the Scorpeons movement and attacks as if they got coated by their own attack.
        if inst.thrower and not inst.thrower.trail_task then
            _G.COMMON_FNS.CreateTrail(inst.thrower, "poison_trail")
            inst.thrower:ListenForEvent("onattackother", OnAttackOther)
            inst.thrower:ListenForEvent("onmissother", OnMissOther)
        end

		if inst.thrower and inst.thrower.components.colouradder then
			inst.thrower.components.colouradder:PopColour("acid_coat")
			inst.thrower.components.colouradder:PushColour("acid_coat", 0.1, 0.5, 0.1, 1)
		end
        _oldOnHitFN(inst, attacker, target)
    end
    spit.components.complexprojectile:Launch(pos, inst)
end

scorpeon_sg.states["attack_spit_bomb"] = State{
    name = "attack_spit_bomb",
    tags = {"attack", "busy", "pre_attack"},

    onenter = function(inst, data)
        inst.components.locomotor:Stop()
        inst.components.combat:StartAttack()
        inst.AnimState:PlayAnimation("attack_pre")
        inst.AnimState:PushAnimation("spit", false)
    end,

    onexit = function(inst, data)
        inst.components.combat:StartCooldown("spit_bomb")
        inst.components.combat:StartCooldown("spit")
    end,

    timeline = {
        TimeEvent(0, function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.grunt)
        end),
        TimeEvent(12*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.taunt)
        end),
        TimeEvent(15*FRAMES, function(inst)
            AcidBomb(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.spit)
            inst.sg:RemoveStateTag("pre_attack")
        end),
        TimeEvent(17*FRAMES, function(inst) -- TODO is this correct?
            inst.sg:RemoveStateTag("busy") --TODO: Check other mob's attack states to see if they can be ended early like this.
            inst.sg:RemoveStateTag("attack")
        end),
    },

    events = {
        EventHandler("animqueueover", function(inst)
            inst.sg:GoToState("idle")
        end),
    },
}

-----------------
-- Spit Meteor -- Scorpeon calls in a meteor of acid.
-----------------
local SPIT_METEOR_CD = 30
scorpeon_sg.states["attack_poison_meteor"] = State{
    name = "attack_poison_meteor",
    tags = {"attack", "busy"},

    onenter = function(inst, data)
        inst.attack_spit_meteor_ready = false
        inst.components.locomotor:Stop()
        inst.components.combat:StartAttack()
        inst.AnimState:PlayAnimation("spit")
        inst.sg.statemem.target = data and data.target or inst.components.combat.target
    end,

    onexit = function(inst, data)
        inst.attack_spit_meteor_ready = false
        inst:DoTaskInTime(SPIT_METEOR_CD, function(inst)
            inst.attack_spit_meteor_ready = true
        end)
    end,

    timeline = {
        TimeEvent(0, function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.taunt)
        end),
        TimeEvent(3*FRAMES, function(inst)
            local target_pos = (inst.sg.statemem.target or inst):GetPosition()
            SpawnPrefab("infernalstaff_meteor"):AttackArea(inst, nil, target_pos, nil, {"LA_mob"})
            inst.SoundEmitter:PlaySound(inst.sounds.spit)
        end),
    },

    events = {
        EventHandler("animover", function(inst)
            inst.sg:GoToState("idle")
        end),
    },
}

COMMON_FNS.ApplyStategraphPostInits(scorpeon_sg)
return scorpeon_sg
