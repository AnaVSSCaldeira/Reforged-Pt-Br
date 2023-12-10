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

local function MasterPostInit(inst)
	inst:AddComponent("inspectable")

    inst.postfxstates = {
        "doublefizzle",
        "convergetothemiddle",
        "righttoleftandback",
        "randomfizzle",
    }

    inst:SetStateGraph("SGlavaarenaspawner")

	local function onload(inst, data, newents)
		local lavaarena_id = {west = 3, south = 2, east = 1}
		if data == nil then
			Debug:Print("lavaarena_spawner has no properties in the map file. Defaulting spawnerid to 1.", "error")
			inst.spawnerid = 1
		else
			inst.spawnerid = lavaarena_id[data.spawnerid] or data.spawnerid
			inst.override_build = data.override_build or nil
		end
	end
	inst.OnLoad = onload

	inst:DoTaskInTime(0.1, function()
		local rot = inst:GetAngleToPoint(TheWorld.components.lavaarenaevent:GetArenaCenterPoint())
		if inst.override_build then
			inst.AnimState:SetBuild(inst.override_build)
		end
		rot = (math.floor((rot+44)/90) * 90) + 90
		inst.Transform:SetRotation(rot)
		TheWorld:PushEvent("ms_register_lavaarenaspawner", { spawner = inst, id = inst:GetSpawnPortalID() })
	end)

	function inst.SpawnMobs(inst, wave_info, delay, round, wave)
        inst:PushEvent("spawnlamobs", {mobs = wave_info[1], options = wave_info[2], delay = delay, round = round, wave = wave})
	end

	function inst.GetSpawnPortalID(inst) -- TODO change to a GetPortalID method that simply gets self.spawnerid which is set onload from the map file
		return inst.spawnerid
	end
end

return {
	master_postinit = MasterPostInit
}
