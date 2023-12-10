local TINT = { r = 154 / 255, g = 23 / 255, b = 19 / 255 }
local FADE_OUT_TIME = 0.35
local FADE_IN_TIME = 0.15

local function PushColour(inst, addval)
    if inst.components.colouradder then
        inst.components.colouradder:PushColour("wortoxsoulfx", TINT.r * addval, TINT.g * addval, TINT.b * addval, 1)
    else
        inst.AnimState:SetAddColour(TINT.r * addval, TINT.g * addval, TINT.b * addval, 1)
    end
end

local function PopColour(inst)
    if inst.components.colouradder then
        inst.components.colouradder:PopColour("wortoxsoulfx")
    else
        inst.AnimState:SetAddColour(0, 0, 0, 0)
    end
end

local function OnUpdateTargetTint(inst, dt)
    if inst._tinttarget:IsValid() then
        if inst._tint_mode == false then
			inst._tint = inst._tint + (1/FADE_IN_TIME) * dt
			if inst._tint >= 1 then
				inst._tint = 1
				inst._tint_mode = true
			end
        elseif inst._tint_mode then
            inst._tint = inst._tint - (1/FADE_OUT_TIME) * dt
			if inst._tint <= 0 then
				inst._tint = 0
				inst._tint_mode = nil
			end
        else
            inst._tint = 0
        end
		-- print("inst._tint", inst._tint)
        PushColour(inst._tinttarget, inst._tint)
    end
end

local function OnRemoveEntity(inst)
    if inst._tinttarget:IsValid() then
        PopColour(inst._tinttarget)
    end
end

local function OnTargetDirty(inst)
    if inst._target:value() and not inst._tinttarget then
        if not inst.components.updatelooper then
            inst:AddComponent("updatelooper")
        end
        inst._tint = 0
        inst._tint_mode = false
        inst.components.updatelooper:AddOnWallUpdateFn(OnUpdateTargetTint)
        inst._tinttarget = inst._target:value()
        inst.OnRemoveEntity = OnRemoveEntity
    end
end

local function Setup(inst, target)
    inst._target:set(target)
    if not TheNet:IsDedicated() then
        OnTargetDirty(inst)
    end
    if target.SoundEmitter then
        target.SoundEmitter:PlaySound("dontstarve/characters/wortox/soul/spawn", nil, .5)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst._target = net_entity(inst.GUID, "forge_wortox_soul_in_fx._target", "targetdirty")
    ------------------------------------------
    inst.entity:SetPristine()
    ------------------------------------------
    if not TheWorld.ismastersim then
        inst:ListenForEvent("targetdirty", OnTargetDirty)
        return inst
    end
    ------------------------------------------
    inst.persists = false
    inst.Setup = Setup

    inst:DoTaskInTime(1, inst.Remove)

    return inst
end

return Prefab("forge_wortox_soul_in_fx", fn)
