--[[
Copyright (C) 2019 Forged Forge

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
local HelmSplitter = Class(function(self, inst)
    self.inst = inst
    self.ready = true
	self.damage = 10
	self.cooldown = 5
    self.onhelmsplit = nil
	
	self.inst:ListenForEvent("battlecry", function()
		if self.ready then
			self.inst:AddTag("helmsplitter")
		end
	end)
end)

function HelmSplitter:SetOnHelmSplitFn(fn)
    self.onhelmsplit = fn
end

-- Starts the helm split attack
function HelmSplitter:StartHelmSplitting(player)
    if player.sg then
        player.sg:PushEvent("start_helmsplit")
        return true
    end
    return false
end

--Creates a helmsplit that hits the given target
function HelmSplitter:DoHelmSplit(player, target)
    if player.sg then
        player.sg:PushEvent("do_helmsplit")
    end
	player.components.combat.damage_override = self.damage
	local damage = player.components.combat:CalcDamage(nil, self.inst)
	player.components.combat.damage_override = nil
	--player.components.combat:DoSpecialAttack(self.damage, target, "strong")
	player.components.combat:DoAttack(target, self.inst, nil, "strong", nil, damage)
    if self.onhelmsplit then
		self.onhelmsplit(self.inst, player, target)
	end
end

-- Stop helmsplitting and reset it
function HelmSplitter:StopHelmSplitting(player)
    if player.sg then
        player.sg:PushEvent("stop_helmsplit")
    end
    self.ready = false
	self.inst:RemoveTag("helmsplitter")
	self.inst:DoTaskInTime(self.cooldown, function()
		self.ready = true
	end)
end

function HelmSplitter:SetCooldown(cooldown)
	self.cooldown = cooldown
end

function HelmSplitter:SetDamage(damage)
	self.damage = damage
end

return HelmSplitter