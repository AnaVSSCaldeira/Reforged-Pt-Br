local assets = {
    Asset("ANIM", "anim/mole_move_fx.zip"),
}
--------------------------------------------------------------------------
local function OnUpdate(inst, x, y, z, rad) -- TODO what should the include tags be?
    local exclude_tags = inst.source and COMMON_FNS.CommonExcludeTags(inst.source) or {}
    for _,ent in ipairs(TheSim:FindEntities(x, y, z, rad, {"locomotor"}, exclude_tags)) do
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
        inst.AnimState:PlayAnimation("move")
        inst:DoTaskInTime(10*FRAMES, function()
            inst.AnimState:Pause()
        end)
        inst:DoTaskInTime(inst.duration, function()
            inst.AnimState:Resume()
        end)
        --OnInit(inst, scale)
    end
end
--------------------------------------------------------------------------
local function fn()
    local radius = 1
    local height = 1
    ------------------------------------------
    local inst = COMMON_FNS.FXEntityInit("mole_fx", "mole_move_fx", nil, {noanim = true, pristine_fn = function(inst)
        inst.entity:AddSoundEmitter()
        ------------------------------------------
        MakeSmallObstaclePhysics(inst, radius, height)
        --inst.AnimState:SetLayer(LAYER_BACKGROUND)
        --inst.AnimState:SetSortOrder(3)
        --inst.AnimState:OverrideMultColour(unpack(COLOR))
        ------------------------------------------
        --inst._isfading = net_bool(inst.GUID, "poison_trail._isfading", "isfadingdirty")
    end})
	------------------------------------------
    if not TheWorld.ismastersim then
        --inst:ListenForEvent("isfadingdirty", OnIsFadingDirty)
        --inst.task = inst:DoPeriodicTask(0, OnInit)

        return inst
    end
    ------------------------------------------
    inst.components.scaler:SetBaseRadius(radius)
    inst.components.scaler:SetBaseHeight(height)
    inst.SetVariation = SetVariation
    inst.source = nil
    ------------------------------------------
    inst.persists = false
    --inst.task = inst:DoTaskInTime(0, inst.Remove)
    ------------------------------------------
    return inst
end

return Prefab("ground_trail", fn, assets)
