--[[
Copyright (C) 2018, 2019 Forged Forge

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
local Multithruster = Class(function(self, inst)
    self.inst = inst
    self.ready = true
	self.damage = 0
	self.cooldown = 5
	
	self.inst:ListenForEvent("battlecry", function()
		if self.ready then
			self.inst:AddTag("multithruster")
		end
	end)
end)

-- Starts the thrust attack
function Multithruster:StartThrusting(player)
	if player.sg then
		self.damage = player.components.combat:CalcDamage(nil, self.inst, nil)
		player.sg:PushEvent("start_multithrust")
		return true
	end
	return false
end

-- Creates a thrust that hits the given target
function Multithruster:DoThrust(player, target)
    if player.sg then
        player.sg:PushEvent("do_multithrust")
    end
	player.components.combat:DoAttack(target, nil, nil, "strong", nil, self.damage)
end

-- Stop thrusting and reset it
function Multithruster:StopThrusting(player)
    if player.sg then
        player.sg:PushEvent("stop_multithrust")
    end
	self.ready = false
	self.inst:RemoveTag("multithruster")
	self.damage = 0
	self.inst:DoTaskInTime(5, function()
		self.ready = true
	end)
end

function Multithruster:SetCooldown(cooldown)
	self.cooldown = cooldown
end

return Multithruster