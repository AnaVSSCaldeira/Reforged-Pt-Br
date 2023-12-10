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

local damagenumber = {}

damagenumber["master_postinit"] = function(inst)
	inst.UpdateDamageNumbers = function(self, player, target, damage, large)
		if player == ThePlayer then
			self.PushDamageNumber(player, target, damage, large)
		else
			Debug:Print("Client: ", nil, "DamageNumber")
			print("- player: " .. tostring(player))
			print("- target: " .. tostring(target))
			print("- damage: " .. tostring(damage))
			print("- large: " .. tostring(large))
			self.target:set(target)
			self.damage:set(damage)
			self.large:set(large)
		end
	end
	
	inst:DoTaskInTime(1, inst.Remove) -- is this potentially causing the issue? removing before client produces number? why do we need to remove it, can we keep it?
								      -- CunningFox: Klei ussualy remove prefabs like this after 1 second instead of .1. I think that's what causing this issue
end

return damagenumber
