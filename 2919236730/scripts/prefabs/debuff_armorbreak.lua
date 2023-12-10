local assets = {}
local prefabs = {}
local MAX_LEVEL = 5
local DAMAGE_RECEIVED_MULT_DEBUFF = 1.2
--Leo: Why is this still its own component? Why can't you be normal!?!?!
--------------------------------------------------------------------------
local function OnAttached(inst, target, symbol, offset)
    inst.entity:SetParent(target.entity)
    inst.entity:AddFollower()
    local pos = offset or Vector3(0, -130, 0)
    inst.Follower:FollowSymbol(target.GUID, symbol or "head", pos.x, pos.y, pos.z)
    inst.level = 1 -- TODO Not currently used
    if target and target.components.combat then
        target.components.combat:AddDamageBuff("armorbreak_debuff", DAMAGE_RECEIVED_MULT_DEBUFF, true)
    end

    inst:ListenForEvent("death", function()
        inst.components.debuff:Stop()
    end, target)
    inst:Start()
end

local function OnDetached(inst, target)
    if target and target.components.combat then
        target.components.combat:RemoveDamageBuff("armorbreak_debuff", true)
    end
	inst:Remove()
end

local function OnTimerDone(inst, data)
    if data.name == "armorbreakover" then
        inst.components.debuff:Stop()
    end
end
-- ThePlayer.components.debuffable:AddDebuff("debuff_armorbreak", "debuff_armorbreak")
local function OnExtended(inst, target)
    inst.components.timer:StopTimer("armorbreakover")
    inst.components.timer:StartTimer("armorbreakover", inst.duration)
    inst.level = math.max(MAX_LEVEL, inst.level + 1) -- TODO not currently used
end
--------------------------------------------------------------------------
local function fn(inst)
	local inst = COMMON_FNS.BasicEntityInit("lavaarena_sunder_armor", nil, "pre", {pristine_fn = function(inst)
        --inst.AnimState:SetFinalOffset(5)
        local scale = 0.5
        inst.Transform:SetScale(scale, scale, scale)
        inst.Transform:SetPosition(0,2,0)
        inst.AnimState:PushAnimation("loop", true)
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
    ------------------------------------------
    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", OnTimerDone)
	------------------------------------------
	inst.Start = function(inst)
		inst.components.timer:StartTimer("armorbreakover", inst.duration)
	end
	------------------------------------------
	return inst
end

return Prefab("debuff_armorbreak", fn)
