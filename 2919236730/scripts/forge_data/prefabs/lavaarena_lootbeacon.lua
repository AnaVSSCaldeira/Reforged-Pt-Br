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
	inst.colour = 0
	inst.SoundEmitter:PlaySound("dontstarve/wilson/equip_item_gold")
	local function ontargetpickedup(target, data)
		target.AnimState:SetAddColour(0,0,0,1)
		target:RemoveEventCallback("onpickup", ontargetpickedup)
		target:RemoveEventCallback("equipped", ontargetpickedup)
		if inst ~= nil and inst:IsValid() then
			inst.AnimState:PlayAnimation("pst")
			inst:ListenForEvent("animover", inst.Remove)
			if inst._timeouttask ~= nil then
				inst._timeouttask:Cancel()
			end
			if inst._colourfadetask ~= nil then
				inst._colourfadetask:Cancel()
			end
			if inst._colourtask ~= nil then
				inst._colourtask:Cancel()
			end
			if inst._followtask ~= nil then
				inst._followtask:Cancel()
			end
			target.lootbeacon = nil
		end
	end
	inst.SetTarget = function(inst, target)
		inst.target = target
		target.lootbeacon = inst
		inst:Show()
		inst.AnimState:PlayAnimation("pre")
		inst.AnimState:PushAnimation("loop")
		target:ListenForEvent("onpickup", ontargetpickedup)
		target:ListenForEvent("equipped", ontargetpickedup)
		inst._followtask = inst:DoPeriodicTask(0, function(inst) 
			if inst.target ~= nil then
				inst.Transform:SetPosition(target:GetPosition():Get())
			else
				inst._followtask:Cancel()
				inst._followtask = nil
			end
		end)
		inst._colourtask = inst:DoPeriodicTask(0, function(inst)
			if inst.colour < 0.5 then
				target.AnimState:SetAddColour(inst.colour, inst.colour, inst.colour,1)
				inst.colour = inst.colour + 0.05
			else
				inst._colourtask:Cancel()
				inst._colourtask = nil
			end
		end)
		inst._timeouttask = inst:DoTaskInTime(10, function(inst)
			inst.AnimState:PlayAnimation("pst")
			inst._colourfadetask = inst:DoPeriodicTask(0, function(inst)
				if inst.colour > 0 then
					inst.target.AnimState:SetAddColour(inst.colour, inst.colour, inst.colour,1)
					inst.colour = inst.colour - 0.05
				else
					inst.target.AnimState:SetAddColour(0,0,0,1)
					inst:Remove()
				end
			end)
		end)
	end
	
	inst:ListenForEvent("onremove", function() if inst.target ~= nil then inst.target.AnimState:SetAddColour(0,0,0,1) end end)
end

return {
	master_postinit = MasterPostInit
}
