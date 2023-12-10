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

local assets =
{
    Asset("ANIM", "anim/lavaarena_boarrior_fx.zip"),
}

local function SpikeLaunch(inst, launcher, basespeed, startheight, startradius)
    local x0, y0, z0 = launcher.Transform:GetWorldPosition()
    local x1, y1, z1 = inst.Transform:GetWorldPosition()
    local dx, dz = x1 - x0, z1 - z0
    local dsq = dx * dx + dz * dz
    local angle
    if dsq > 0 then
        local dist = math.sqrt(dsq)
        angle = math.atan2(dz / dist, dx / dist) + (math.random() * 20 - 10) * DEGREES
    else
        angle = 2 * PI * math.random()
    end
    local sina, cosa = math.sin(angle), math.cos(angle)
    local speed = basespeed + math.random()
    inst.Physics:Teleport(x0 + startradius * cosa, startheight, z0 + startradius * sina)
    inst.Physics:SetVel(cosa * speed, speed * 5 + math.random() * 2, sina * speed)
end

local function DoToss(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
    local totoss = TheSim:FindEntities(x, 0, z, 0.7, { "_inventoryitem" }, { "locomotor", "INLIMBO" })
    for i, v in ipairs(totoss) do
        if v.components.mine ~= nil then
            v.components.mine:Deactivate()
        end
    end
	COMMON_FNS.LaunchItems(inst, 0.7)
end

local function OnRemove(inst)
	inst:Remove()
end

local function MakeGroundLift(name, radius, hasanim, hassound, excludesymbols)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        if hassound then
            inst.entity:AddSoundEmitter()
        end
        inst.entity:AddNetwork()

        if hasanim then
            inst.entity:AddAnimState()
            inst.AnimState:SetBank("lavaarena_boarrior_fx")
            inst.AnimState:SetBuild("lavaarena_boarrior_fx")
			inst.AnimState:PlayAnimation("ground_hit_2")
            if excludesymbols ~= nil then
                for i, v in ipairs(excludesymbols) do
                    inst.AnimState:Hide(v)
                end
            end
        else
            inst:AddTag("CLASSIFIED")
        end

        --inst:Hide()

        inst:AddTag("notarget")
        inst:AddTag("hostile")
        inst:AddTag("groundspike")

        --For impact sound
        inst:AddTag("object")
        inst:AddTag("stone")

        inst:SetPrefabNameOverride("boarrior")
        ------------------------------------------
        inst.entity:SetPristine()
        ------------------------------------------
        if not TheWorld.ismastersim then
            return inst
        end
		------------------------------------------
		if radius then
			inst:DoTaskInTime(0, DoToss)
		end
		--
		inst:ListenForEvent("animover", OnRemove)

        --event_server_data("lavaarena", "prefabs/lavaarena_groundlifts").master_postinit(inst, radius, hasanim, hassound)

        return inst
    end

    return Prefab(name, fn, assets)
end

return MakeGroundLift("lavaarena_groundlift", .7, true, false, { "embers" }),
    MakeGroundLift("lavaarena_groundliftembers", .7, true, false),
    MakeGroundLift("lavaarena_groundliftrocks", .7, true, false, { "embers", "splash" }),
    MakeGroundLift("lavaarena_groundliftwarning", .7, false, false),
    MakeGroundLift("lavaarena_groundliftempty", 1, false, true)
