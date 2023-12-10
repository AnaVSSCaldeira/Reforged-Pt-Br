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
	local function onload(inst, data, newents)
		inst.override_build = data and data.override_build or nil
	end
	inst.OnLoad = onload

	if inst.override_build then
		inst.AnimState:SetBuild(inst.override_build)
	end

	inst:AddComponent("inspectable")

	TheWorld:PushEvent("ms_register_forgelord", inst)
	--Forces pugna to face the correct direction, apparently need a small delay to update his rotation.
	if TheWorld.components.lavaarenaevent and TheWorld.components.lavaarenaevent:GetArenaCenterPoint() then
		inst:DoTaskInTime(0, function(inst)
			inst:ForceFacePoint(TheWorld.components.lavaarenaevent:GetArenaCenterPoint():Get())
			inst.AnimState:SetScale(-1, 1) --he was animated facing the wrong direction.
		end)
	end

	inst.lines_left = 0
	inst:SetStateGraph("SGboarlord")
end

return {
	master_postinit = MasterPostInit
}
