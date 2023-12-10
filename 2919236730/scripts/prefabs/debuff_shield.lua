local assets = {}
local prefabs = {}
local MAX_LEVEL = 5
local DAMAGE_RECEIVED_MULT_DEBUFF = 1.2
--------------------------------------------------------------------------
local function OnAttached(inst, target)
    inst.target = target
    inst:DoTaskInTime(0, function() -- Delay so duration and shield mult can be adjusted
        inst.entity:SetParent(target.entity)
        inst.Transform:SetPosition(0, 0, 0)
        inst.Follower:FollowSymbol(target.GUID, target.AnimState:BuildHasSymbol("torso") and "torso" or target.components.debuffable.followsymbol, 0, 50, 0)

        -- Remove debuff when target dies
        inst:ListenForEvent("death", function()
            inst.components.debuff:Stop()
        end, target)

        -- Attach buff
        if target.components.combat then
            target.components.combat:AddDamageBuff("shield_buff", inst.shield_mult, true)
        end

        if inst.duration then
            target.debuff_shield_timer = target:DoTaskInTime(inst.duration, function()
                inst.components.debuff:Stop()
            end)
        end
    end)
end

local function OnExtended(inst, target)
    RemoveTask(target.debuff_shield_timer)
    target.debuff_shield_timer = target:DoTaskInTime(inst.duration, function()
        inst.components.debuff:Stop()
    end)
end

local function OnDetached(inst, target)
    if target and target.components.combat then
        target.components.combat:RemoveDamageBuff("shield_buff", true)
    end

    inst:Remove()
end
--------------------------------------------------------------------------
local function fn(inst)
    local inst = COMMON_FNS.BasicEntityInit("forcefield", "forcefield_colorable", "open", {pristine_fn = function(inst)
        inst.AnimState:PushAnimation("idle_loop", true)
        inst.entity:AddFollower()
        inst.AnimState:SetScale(0.7, 0.7)
        inst.AnimState:SetAddColour(102/255, 186/255, 213/255, 1)
        ------------------------------------------
        inst.AnimState:SetFinalOffset(1)
        ------------------------------------------
        COMMON_FNS.AddTags(inst, "FX", "NOCLICK")
    end})
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetDetachedFn(OnDetached)
    inst.components.debuff:SetExtendedFn(OnExtended)
    ------------------------------------------
    inst.duration = 5 -- in seconds
    inst.shield_mult = 0.8
    inst.SetDuration = function(inst, duration)
        inst.duration = duration or inst.duration
    end
    inst.SetShieldMult = function(inst, mult)
        if inst.shield_mult ~= mult and mult < 0.75 then
            inst.AnimState:PlayAnimation("shield_buff", true)
        end
        inst.shield_mult = mult or inst.shield_mult
    end
    ------------------------------------------
    return inst
end

return Prefab("debuff_shield", fn)
