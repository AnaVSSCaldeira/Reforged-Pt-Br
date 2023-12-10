local assets = {
    Asset("ANIM", "anim/honey_trail.zip"),
}
--------------------------------------------------------------------------
local function OnUpdate(inst, x, y, z, rad) -- TODO what should the include tags be?
    local exclude_tags = inst.source and COMMON_FNS.GetAllyTags(inst.source) or {}
    for _,ent in ipairs(TheSim:FindEntities(x, y, z, rad, {"_combat"}, exclude_tags)) do
        if not (inst.source and inst.source == ent) and ent.components.health and ent.components.debuffable and ent.components.debuffable:IsEnabled() and not ent.acidimmune and not ent.components.debuffable:HasDebuff("healingcircle_regenbuff") and not (ent.sg and ent.sg:HasStateTag("noattack")) then -- TODO better way to handle immunities? tags? hmmm
            ent.components.debuffable:AddDebuff("scorpeon_dot", "scorpeon_dot")
        end
    end
end

local function OnUpdateClient(inst, x, y, z, rad) -- TODO needed?
    --[[local player = ThePlayer
    if player and player.components.locomotor and not player:HasTag("playerghost") and player:GetDistanceSqToPoint(x, 0, z) < rad * rad then
        player.components.locomotor:PushTempGroundSpeedMultiplier(TUNING.BEEQUEEN_HONEYTRAIL_SPEED_PENALTY, GROUND.MUD)
    end--]]
end

local function OnIsFadingDirty(inst)
    if inst._isfading:value() then
        inst.task:Cancel()
    end
end

local function OnStartFade(inst)
    inst.AnimState:PlayAnimation(inst.trailname.."_pst")
    inst._isfading:set(true)
    inst.task:Cancel()
end

local function OnAnimOver(inst)
    if inst.AnimState:IsCurrentAnimation(inst.trailname.."_pre") then
        inst.AnimState:PlayAnimation(inst.trailname)
        inst:DoTaskInTime(inst.duration, OnStartFade)
    elseif inst.AnimState:IsCurrentAnimation(inst.trailname.."_pst") then
        inst:Remove()
    end
end

local function OnInit(inst, scale)
    local x, y, z = inst.Transform:GetWorldPosition()
    if scale == nil then
        scale = inst.Transform:GetScale()
    end
    inst.task:Cancel()
    local onupdatefn = TheWorld.ismastersim and OnUpdate or OnUpdateClient
    inst.task = inst:DoPeriodicTask(0, onupdatefn, nil, x, y, z, scale)
    onupdatefn(inst, x, y, z, scale)
end

local MAX_POISON_TRAIL_VARIATIONS = 7
local function SetVariation(inst, rand, scale, duration)
    if inst.trailname == nil then
        --inst.Transform:SetScale(scale, scale, scale)
        inst.components.scaler:SetBaseScale(scale)

        inst.trailname = "trail"..tostring(rand or math.random(MAX_POISON_TRAIL_VARIATIONS))
        inst.duration = duration
        inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bee_queen/honey_drip")
        inst.AnimState:PlayAnimation(inst.trailname.."_pre")
        inst:ListenForEvent("animover", OnAnimOver)

        OnInit(inst, inst.components.scaler.current_scale)
    end
end

local function RGB(r, g, b)
    return { r / 255, g / 255, b / 255, 1 }
end
local COLOR = RGB(0, 255, 127)
--------------------------------------------------------------------------
local function fn()
    local inst = COMMON_FNS.FXEntityInit("honey_trail", nil, nil, {noanimover = true, noanim = true, pristine_fn = function(inst)
        inst.entity:AddSoundEmitter()
        ------------------------------------------
        inst.AnimState:SetLayer(LAYER_BACKGROUND+1)
        inst.AnimState:SetSortOrder(3)
        inst.AnimState:OverrideMultColour(unpack(COLOR))
        ------------------------------------------
        inst._isfading = net_bool(inst.GUID, "poison_trail._isfading", "isfadingdirty")
    end})
	------------------------------------------
    if not TheWorld.ismastersim then
        inst:ListenForEvent("isfadingdirty", OnIsFadingDirty)
        inst.task = inst:DoPeriodicTask(0, OnInit)

        return inst
    end
	inst:AddComponent("colouradder")
	inst.components.colouradder:PushColour("acid", 0.1, 0.5, 0.1, 1)
    ------------------------------------------
    inst.SetVariation = SetVariation
    inst.source = nil
    ------------------------------------------
    inst.persists = false
    inst.task = inst:DoTaskInTime(0, inst.Remove)
    ------------------------------------------
    return inst
end
--------------------------------------------------------------------------
return Prefab("poison_trail", fn, assets)
