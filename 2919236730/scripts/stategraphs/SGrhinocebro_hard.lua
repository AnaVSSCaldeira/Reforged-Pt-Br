local rhinocebro_sg = deepcopy(require "stategraphs/SGrhinocebro")
rhinocebro_sg.name = "rhinocebro_hard"
local tuning_values = TUNING.FORGE.RHINOCEBRO

-- Override old action handlers. Seems that it does not link properly when using a copy.
local actionhandlers = {ActionHandler(ACTIONS.REVIVE_CORPSE, "reviving_bro")}
rhinocebro_sg.actionhandlers = {}
if actionhandlers then
    for k,v in pairs(actionhandlers) do
        assert( v:is_a(ActionHandler),"Non-action handler added in actionhandler table!")
        rhinocebro_sg.actionhandlers[v.action] = v
    end
end

---------------------------
-- Update Attack Pattern --
---------------------------
local _oldDoAttack = rhinocebro_sg.events.doattack.fn
rhinocebro_sg.events.doattack.fn = function(inst, data)
    _oldDoAttack(inst, data)
end

----------
-- Idle --
----------
local idle_state = rhinocebro_sg.states.idle
local _oldOnEnter = idle_state.onenter
idle_state.onenter = function(inst, data)
    if inst.components.combat:IsAttackReady("cheer") and inst.bro and inst.bro.components.health and not inst.bro.components.health:IsDead() then
        inst.sg:GoToState("cheer_pre")
    else
        inst.Physics:Stop()
        inst.AnimState:PlayAnimation("idle_loop", true)
    end
end

----------------
-- Chest Bump -- Adds an explosion to chest bumps if bros have reached high enough temp
---------------- Brosplosion!
local explosion_scale = 5
local EXPLOSION_DAMAGE = 500
local EXPLOSION_RADIUS = 12
local function CreateExplosion(inst) -- TODO point between rhinos is currently wrong
    local pos = inst:GetPosition()
    local bro_pos = inst.bro:GetPosition()
    local distance_to_bro = distsq(pos, bro_pos)
    local dist = math.sqrt(distance_to_bro) / 2
    local angle = -inst:GetAngleToPoint(bro_pos) * DEGREES
    local offset = Point(dist*math.cos(angle), 0, dist*math.sin(angle))
    local explosion_pos = pos + offset
    local explosion_fx = SpawnPrefab("explode_small_slurtlehole")
    explosion_fx.Transform:SetPosition(explosion_pos:Get())
    explosion_fx.Transform:SetScale(explosion_scale, explosion_scale, explosion_scale)
    local ring_fx = SpawnPrefab("groundpoundring_fx")
    ring_fx.Transform:SetPosition(explosion_pos:Get())
    COMMON_FNS.DoAOE(inst, nil, EXPLOSION_DAMAGE, {range = EXPLOSION_RADIUS, stimuli = "explosive", target_pos = explosion_pos})
end
local chest_bump_state = rhinocebro_sg.states.chest_bump

local _oldChestBumpTime = chest_bump_state.timeline[1].fn
chest_bump_state.timeline[1].fn = function(inst)
    _oldChestBumpTime(inst)
    if inst.bro.sg.currentstate.name == "chest_bump" then
        if inst.sg.statemem.initiator then
            CreateExplosion(inst)
        end
        inst.heat = 0
    end
end

--TODO Shouldn't we delete this?
local _oldOnExit = chest_bump_state.onexit
chest_bump_state.onexit = function(inst, data)
    _oldOnExit(inst, data)
    --inst.heat = 0
end

-----------
-- Cheer --
-----------
local function FaceBro(inst)
    if inst.bro and not inst.bro.components.health:IsDead() then
        local pos = inst.bro:GetPosition()
        inst:ForceFacePoint(pos:Get())
    end
end
local cheer_pre_state = rhinocebro_sg.states.cheer_pre
cheer_pre_state.tags.cheering = nil
local _oldOnEnter = cheer_pre_state.onenter
cheer_pre_state.onenter = function(inst, data)
    if inst.bro then
        FaceBro(inst)
    end
    inst.Physics:Stop()
    inst.AnimState:PlayAnimation("cheer_pre")
end

local cheer_loop_state = rhinocebro_sg.states.cheer_loop
cheer_loop_state.tags.cheering = nil
local _oldOnEnter = cheer_loop_state.onenter
cheer_loop_state.onenter = function(inst, data)
    inst.AnimState:PlayAnimation("cheer_loop")
    inst.SoundEmitter:PlaySound(inst.sounds.cheer)

    inst.sg.statemem.buff_ready = data and data.buff_ready
    inst.sg.statemem.buffed = data and data.buffed
    inst.sg.statemem.end_cheer = data and data.end_cheer
end
cheer_loop_state.ontimeout = nil
local function UpdateBroBuffLevel(inst)
    inst:SetBuffLevel(inst.bro_stacks + 1)
end
cheer_loop_state.events.animover.fn = function(inst)
    if inst.sg.statemem.end_cheer then -- TODO needed? leaving here for now, remove if not needed in final version or keep just in case something goes wrong?
        inst.sg:GoToState("cheer_pst")
    else
        local buff_ready = inst.sg.statemem.buff_ready
        local buffed = inst.sg.statemem.buffed
        local end_cheer = buffed

        if buff_ready then
            UpdateBroBuffLevel(inst.bro or inst)
            buffed = true
            end_cheer = false -- this is just in case the other bro is interrupted as the the buff occurs which would cause this to be true and this rhino will not get a buff
        end
        inst.sg:GoToState("cheer_loop", {buffed = buffed, buff_ready = not (buff_ready or buffed), end_cheer = end_cheer})
    end
end

COMMON_FNS.ApplyStategraphPostInits(rhinocebro_sg)
return rhinocebro_sg
