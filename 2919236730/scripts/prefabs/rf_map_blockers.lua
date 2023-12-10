
local prefabs =
{

}

local assets =
{

}

local function MakeBlocker(name, rad)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddNetwork()

        inst:AddTag("FX")
		inst:AddTag("NOCLICK")
        inst:AddTag("BLOCKER")

		inst:SetGroundTargetBlockerRadius(rad)
        ------------------------------------------
        inst.entity:SetPristine()
        ------------------------------------------
        if not TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------
        return inst
    end

    return Prefab(name, fn, assets)
end

return MakeBlocker("rf_map_blocker_small", 5),
MakeBlocker("rf_map_blocker_med", 12),
MakeBlocker("rf_map_blocker_large", 20)
	
