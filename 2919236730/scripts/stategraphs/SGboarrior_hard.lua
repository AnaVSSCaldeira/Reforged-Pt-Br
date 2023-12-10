local boarrior_sg = deepcopy(require "stategraphs/SGboarrior")
boarrior_sg.name = "boarrior_hard"
local tuning_values = TUNING.FORGE.BOARRIOR

---------------------------
-- Update Attack Pattern -- Boarrior now calls for reinforcements (of increasing strength) as a periodic attack.
---------------------------
local _oldDoAttack = boarrior_sg.events.doattack.fn
boarrior_sg.events.doattack.fn = function(inst, data)
    if not (inst.sg:HasStateTag("hit") or inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("nointerrupt")) and inst.components.combat:IsAttackReady("reinforcements") then
        inst.sg:GoToState("banner_pre")
    else
        _oldDoAttack(inst, data)
    end
end

----------
-- Spin -- Makes Boarrior move towards target while spinning.
----------
-- TODO
-- Change the state to be like boarilla rolling where boarrior spins for a set duration, so more than just one anim, and does damage on throughout just like boarilla, and has no collision.
local function SpinningCondition(inst)
    return inst.sg.currentstate.name == "attack_spin"
end

local SPIN_MOVEMENT_SPEED = 10
local function SpinMovement(inst)
    local target = inst.components.combat.target
    if target and target:IsValid() and not target.components.health:IsDead() then
        inst:ForceFacePoint(target:GetPosition())
        inst.Physics:SetMotorVelOverride(SPIN_MOVEMENT_SPEED,0,0)
    else
        inst.Physics:ClearMotorVelOverride()
    end
end
local spin_state = boarrior_sg.states.attack_spin
local _oldOnEnter = spin_state.onenter
spin_state.onenter = function(inst, data)
    _oldOnEnter(inst, data)
    if inst.components.combat:GetAttackOptions("spin").can_move then
        CreateConditionThread(inst, "attack_spin_movement", 0, 0.1, SpinningCondition, SpinMovement)
    end
end

------------
-- Banner -- Boarrior summons an additional banner for each time banners are summoned (to max).
------------
local MAX_BANNERS = 7
local ATTACK_BANNER_CD = {pitpigs = 30, crocs = 45}
local banner_state = boarrior_sg.states.banner_pre
local _oldOnEnter = banner_state.onenter
banner_state.onenter = function(inst, data)
    _oldOnEnter(inst, data)
    inst.components.combat:StartCooldown("reinforcements")
end

local banner_pst_state = boarrior_sg.states.banner_pst
local _oldOnEnterBannerPst = banner_pst_state.onenter
banner_pst_state.onenter = function(inst, data)
    _oldOnEnterBannerPst(inst, data)
    -- Increase the amount of banners summoned by 1 (to max) every time banners are summoned.
    local current_max_banners = inst.components.combat:GetAttackOptions("reinforcements").banner_opts.max
    inst.components.combat:SetAttackOptions("reinforcements", {banner_opts = {max = math.min((current_max_banners or tuning_values.MAX_BANNERS) + 1, MAX_BANNERS)}})
end

COMMON_FNS.ApplyStategraphPostInits(boarrior_sg)
return boarrior_sg
