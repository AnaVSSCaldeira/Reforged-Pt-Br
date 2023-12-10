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

--Fox: This can be used for boarilla and snortoise
--This is used for abilities that launch items constantly (e.g. spinning) for just manual launching of items, look in common_fns.
local ItemLauncher = Class(function(self, inst)
	self.inst = inst
	
	self.radius = 2
	self.launch_speed = 0.2
	self.cache = {}
end)

function ItemLauncher:Enable(val)
	if self.enabled ~= val then
		self.enabled = val 
		self.cache = {}
		
		if self.enabled then
			self.inst:StartUpdatingComponent(self)
		else
			self.inst:StopUpdatingComponent(self)
		end
	end
end

function ItemLauncher:OnUpdate()
	local x, _, z = self.inst:GetPosition():Get()
	for _, v in ipairs(TheSim:FindEntities(x, 0, z, self.radius, { "_inventoryitem" }, { "locomotor", "INLIMBO" })) do
        if not self.cache[v] then
            local range = v:GetPhysicsRadius(.5) + .7
			
            if v:GetDistanceSqToPoint(x, 0, z) < range * range then
                if not v.components.inventoryitem.nobounce and v.Physics ~= nil and v.Physics:IsActive() then
                    self.cache[v] = true
                    Launch(v, self.inst, self.launch_speed)
					
					self.inst:DoTaskInTime(.75, function()
						self.cache[v] = nil
					end)
                end
            end
        end
    end
end

return ItemLauncher