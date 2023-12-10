local assets = {}
local prefabs = {
    "deer_ice_fx",
}
local GEYSER_RANGE = 1
local GEYSER_DAMAGE = 50
local ATTACK_KNOCKBACK = 20
--------------------------------------------------------------------------
-- Apply knockback to all hits
local function OnHitOther(inst, source, target)
    COMMON_FNS.KnockbackOnHit(inst, target, 5, ATTACK_KNOCKBACK)
end

local function fn(inst)
	local inst = COMMON_FNS.BasicEntityInit("mole_fx", "mole_move_fx", "move")
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
    inst:AddComponent("scaler")
    ------------------------------------------
    inst.orig = true
    -- TODO add position? add damage?
    inst.Start = function(inst, owner, loop)
        inst.owner = owner
        inst.loop = loop
    end
    inst.Stop = function(inst)
        inst.AnimState:Resume()
    end
    inst:DoTaskInTime(10*FRAMES, function(inst)
        local pos = inst:GetPosition()
        inst.smoke = COMMON_FNS.CreateFX("deer_ice_fx", nil, inst) -- TODO should this spawn at start or on an earlier frame or here?
        inst.smoke.Transform:SetPosition(pos:Get())
        if inst.owner then
            COMMON_FNS.DoAOE(inst, inst.owner, GEYSER_DAMAGE, {range = GEYSER_RANGE, target_pos = pos, onhit_fn = OnHitOther})
        end
        if inst.loop then
            inst.AnimState:Pause()
        end
    end)
    inst:ListenForEvent("animover", function(inst)
        inst.smoke:KillFX()
        inst:Remove()
    end)
	return inst
end

return Prefab("geyser", fn, assets, prefabs)
