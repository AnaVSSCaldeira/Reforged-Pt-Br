-- Fox: Ok, I don't get how they did with original prefab, so I'll just make it my way
-- As a bonus we'll get 30 FPS ErodeAway anim

-- We need to have a bank. Right now there's no better way of doing it
local function GetBank(inst)
    local anim = (inst.entity:GetDebugString():match("bank: [%w_]+"))
    return anim and (anim:gsub("bank: ", ""))
end

local assets = {
    Asset("ANIM", "anim/fossilized.zip"),
}

local function SpawnFx(target, bank, build)
    if not bank or not build then
        return
    end

    local inst = CreateEntity()

    inst:AddTag("FX")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.Transform:SetFromProxy(target.GUID)

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:AddOverrideBuild("fossilized")
    inst.AnimState:PlayAnimation("fossilized_break_fx")

    inst:ListenForEvent("animover", ErodeAway)
end

local function OnTargetDirty(inst)
    local target = inst._target:value()
    if target and target.AnimState then
        SpawnFx(target, GetBank(target), target.AnimState:GetBuild())
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst._target = net_entity(inst.GUID, "reforge_fossilized_break_fx._target", "targetdirty")

    --Dedicated server does not need to spawn the local fx
    if not TheNet:IsDedicated() then
        inst:ListenForEvent("targetdirty", OnTargetDirty)
    end
    ------------------------------------------
    inst.entity:SetPristine()
    ------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    inst.Setup = function(inst, target) inst._target:set(target) end

    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst:DoTaskInTime(1, inst.Remove)

    return inst
end

return Prefab("fossilized_break_fx", fn, assets)
