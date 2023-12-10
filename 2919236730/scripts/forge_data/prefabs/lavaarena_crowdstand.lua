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

local function OnLoad(inst, data)
    if data ~= nil then
        inst.size_width = data.stand_width or 1
        inst.size_height = data.stand_height or 1
        if inst.size_width ~= nil then
            inst.stand_width:set(inst.size_width)
        end
        if inst.size_height ~= nil then
            inst.stand_height:set(inst.size_height)
        end
    end
end

-- print("ROT TEST") local rot = ThePlayer:GetAngleToPoint(TheWorld.components.lavaarenaevent:GetArenaCenterPoint()) print("- rot_start: " .. tostring(rot)) rot = (math.floor((rot + 44) / 90) * 90) ThePlayer.Transform:SetRotation(rot) print("- rot_adj: " .. tostring(rot))
local function StandPostInit(inst)
	inst:DoTaskInTime(0.5, function()
		inst.size_width = inst.size_width or 1
		inst.size_height = inst.size_height or 1
		if TheWorld and TheWorld.components.lavaarenaevent then
			local rot = inst:GetAngleToPoint(TheWorld.components.lavaarenaevent:GetArenaCenterPoint())
			rot = (math.floor((rot + 44) / 90) * 90)
			inst.Transform:SetRotation(rot)
			if not inst.teambanner then
				inst.teambanner = SpawnPrefab("lavaarena_teambanner")
			end
			local bannerpos = Vector3(0-(inst.size_height*2), 0, 0)
			inst.teambanner.Transform:SetPosition(bannerpos:Get())
			inst.teambanner.entity:SetParent(inst.entity)
			inst.teambanner.Transform:SetRotation(90)
			inst.teambanner.AnimState:OverrideSymbol("banner1", "lavaarena_banner", "banner2")
			inst.teambanner.persists = false
			-----
			inst.spectators = {}
			local spectatorpositions = {}
			local xcount = inst.size_height+math.floor(inst.size_height/2)
			local xsize = (inst.size_height*4)-2
			local xposs = {}
			local zcount = inst.size_width+math.floor(inst.size_width/2)
			local zsize = (inst.size_width*4)-2
			local zposs = {}
			local instpos = inst:GetPosition()
			--print("INIT SPECTATOR SPAWN: xcount = ",xcount,"zcount = ",zcount)
			for i = -math.floor(xcount/2), math.floor(xcount/2) do
				--print("X#", i)
				local pos = (xsize/xcount)*i
				table.insert(xposs, pos)
			end
			for i = -math.floor(zcount/2), math.floor(zcount/2) do
				local pos = (zsize/zcount)*i
				table.insert(zposs, pos)
			end
			for k, v in pairs(xposs) do
				for k2, v2 in pairs(zposs) do
					table.insert(spectatorpositions, Vector3(v+(math.random(-50,50)/100), 0 , v2+(math.random(-50,50)/100)))
				end
			end
			for k, v in pairs(spectatorpositions) do
				if math.random() < 0.8 then
					local spec = SpawnPrefab("lavaarena_spectator")
					spec.Transform:SetScale(0.7, 0.7, 0.7)
					spec.Transform:SetPosition(v:Get())
					spec.entity:SetParent(inst.entity)
					--spec.Transform:SetRotation(rot)
					spec.persists = false
					table.insert(inst.spectators, spec)
				end
			end
		end
	end)

    inst.OnLoad = OnLoad
end

local function GetReaction(inst)
	if next(TheWorld.components.forgemobtracker:GetAllLiveMobs()) then
		return math.random() < 0.25 and "boo" or "cheer"
	elseif math.random() < 0.15 then
		return "eat"
	end
	return nil -- Fox: nil means idle
end

local function BecomeDoyDoy(inst)
	inst.AnimState:SetBuild("lavaarena_doydoy")
	inst.AnimState:SetBank("doydoy")
	inst.AnimState:PlayAnimation("idle", true)

	local s = 1.15
	inst.Transform:SetScale(s, s, s)

	inst:RemoveTag("doydoyable")
	inst:AddTag("doydoyed")

	inst:SetStateGraph("SGdoydoy")
end

local function SpectatorPostInit(inst)
	inst:AddTag("doydoyable")

	inst.AnimState:SetBuild("lavaarena_boaraudience1_build_"..tostring(math.random(3)))

	local shade = .75 + math.random() * .25
	inst.AnimState:SetMultColour(shade, shade, shade, 1)

	inst.BecomeDoyDoy = BecomeDoyDoy
	inst.GetReaction = GetReaction

	inst:SetStateGraph("SGspectator")
end

return {
	stand_postinit = StandPostInit,
	spectator_postinit = SpectatorPostInit
}
