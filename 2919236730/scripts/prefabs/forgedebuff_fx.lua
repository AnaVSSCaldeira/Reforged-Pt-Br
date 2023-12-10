--[[
Copyright (C) 2018 Forged Forge

This file is part of Forged Forge.

The source code of this program is shared under the RECEX
SHARED SOURCE LICENSE (version 1.0).
The source code is shared for referrence and academic purposes
with the hope that people can read and learn from it. This is not
Free and Open Source software, and code is not redistributable
without permission of the author. Read the RECEX SHARED
SOURCE LICENSE for details
The source codes does not come with any warranty including
the implied warranty of merchandise.
You should have received a copy of the RECEX SHARED SOURCE
LICENSE in the form of a LICENSE file in the root of the source
directory. If not, please refer to
<https://raw.githubusercontent.com/Recex/Licenses/master/SharedSourceLicense/LICENSE.txt>
]]

local assets = {
    Asset("ANIM", "anim/lavaarena_sunder_armor.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddFollower()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("DECOR") --"FX" will catch mouseover
    inst:AddTag("NOCLICK")

    inst.AnimState:SetBank("lavaarena_sunder_armor")
    inst.AnimState:SetBuild("lavaarena_sunder_armor")
    inst.AnimState:PlayAnimation("pre")
    ------------------------------------------
    inst.entity:SetPristine()
    ------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end

	local symbols = {boarilla = "helmet", boarrior = "head", crocommander = "shell", pitpig = "helmet", scorpeon = "head", snortoise = "body"} --LEO, FIXITFIXITFIXITFIXIT!!!
	inst.SetTarget = function(inst, target) -- TODO can't you set the parent and then the position will be based off the parent and attached to the parent?
		inst.owner = target
		if symbols[target.prefab] then
			inst.Follower:FollowSymbol(target.GUID, symbols[target.prefab], -20, -150, 1)
		else
			inst:Remove()
		end
	end

    inst:ListenForEvent("animover", function(inst)
		if (not inst.owner and not inst.AnimState:IsCurrentAnimation("pst")) or inst.AnimState:IsCurrentAnimation("pst") then
			inst:Remove()
		else
			inst.AnimState:PlayAnimation("loop")
		end
	end)

    return inst
end

return Prefab("forgedebuff_fx", fn, assets)
