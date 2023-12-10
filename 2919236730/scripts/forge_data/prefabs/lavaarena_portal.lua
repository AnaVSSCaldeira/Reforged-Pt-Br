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
		local data = data or {}
		inst.override_build = data.override_build or nil
		inst.key_override_build = data.key_override_build or nil
		inst.portalfx_prefab = data.portalfx_prefab or nil
		inst.spawnfx_prefab = data.spawnfx_prefab
	end
	inst.OnLoad = onload
	
	inst:DoTaskInTime(0, function(inst)
		local rot = inst:GetAngleToPoint(TheWorld.components.lavaarenaevent:GetArenaCenterPoint())
		rot = (math.floor((rot+44)/90) * 90)
		inst.Transform:SetRotation(rot)

		inst:AddTag("moddedgiftmachine")
		
		if inst.override_build then
			inst.AnimState:SetBuild(inst.override_build)
		end

		local pos = inst:GetPosition()
		local keyhole = SpawnPrefab("lavaarena_keyhole")
		if inst.key_override_build then
			keyhole.AnimState:SetBuild(inst.key_override_build)
		end
		keyhole.Transform:SetPosition(pos.x, pos.y, pos.z + 5.25)
	end)

	inst.portalfx = nil
	inst.TurnOn = function()
		if inst.portalfx ~= nil then
			return
		end
		inst.portalfx = SpawnPrefab(inst.portalfx_prefab or "lavaarena_portal_activefx")
		inst.portalfx.Transform:SetPosition(inst:GetPosition():Get())
	end

	inst.TurnOff = function()
		if inst.portalfx == nil then
			return
		end
		inst.portalfx.AnimState:PlayAnimation("portal_pst")
		inst.portalfx:ListenForEvent("animover", inst.portalfx.Remove)
		inst.portalfx = nil
	end

	inst:ListenForEvent("lavaarena_portal_activate", inst.TurnOn, TheWorld)
	inst:ListenForEvent("lavaarena_portal_deactivate", inst.TurnOff, TheWorld)
	TheWorld:PushEvent("ms_register_lavaarenaportal", inst)
end

return {
	master_postinit = MasterPostInit
}
