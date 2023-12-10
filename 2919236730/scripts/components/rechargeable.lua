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

local Rechargeable = Class(function(self, inst)
	self.inst = inst
	self.recharge = 255
	self.rechargetime = -2
	self.max_recharge = 500
	self.maxrechargetime = 30
	self.cooldownrate = 1
	self.is_timer = true
	self.max_damage_charge = 100
	self.total_damage = 0
	self.isready = true
	self.ignore_ready = false
	self.updatetask = nil
	self.onready = nil
	self.pickup_cooldown = 1
	self.pickup = false
	self.charges = {}
	self.charge_priority = {}
	self.charge_count = 0
	self.onequip = function(inst, data)
        self:RecalculateRate()
    end
    self.ondamage = function(inst, data)
    	if not self.isready and not data.is_alt then
    		self:Update(data.damageresolved)
    	end
	end
	-- when a player equips this weapon
	self.inst:ListenForEvent("equipped", function(inst, data)
		self.owner = data.owner
		self:RecalculateRate()
		-- check if less than 1 sec remaining on CD? then have a 1 sec equip?
		-- if not on cooldown, then add 1 sec equip CD
		if self.updatetask == nil and self.is_timer and self.pickup_cooldown > 0 then
			self.pickup = true
			self:StartRecharge()
		end
		-- when the player who equipped this wep equips/unequipes something else
		self.inst:ListenForEvent("equip", self.onequip, self.owner)
		self.inst:ListenForEvent("unequip", self.onequip, self.owner)
		if not self.is_timer then
			self.inst:ListenForEvent("onhitother", self.ondamage, self.owner)
		end
	end)
	-- when a player unequips this weapon
	self.inst:ListenForEvent("unequipped", function(inst, data)
		self.inst:RemoveEventCallback("equip", self.onequip, self.owner)
		self.inst:RemoveEventCallback("unequip", self.onequip, self.owner)
		self.inst:RemoveEventCallback("onhitother", self.ondamage, self.owner)
		-- if dropping it when 1 sec pickup cd active, remove it
		if self.pickup and self.updatetask ~= nil then
			self.pickup = false
			self.updatetask:Cancel()
			self.updatetask = nil
		end
		-- if dropped, then remove CDR bonuses
		self.cooldownrate = 1
		self.owner = nil
	end)
end)

function Rechargeable:SetRechargeTime(rechargetime)
	self.maxrechargetime = rechargetime
end

function Rechargeable:SetIsTimer(val)
	self.is_timer = val
end

function Rechargeable:SetPickupCooldown(val)
	self.pickup_cooldown = val
end

function Rechargeable:SetMaxRecharge(amount)
	self.max_recharge = amount
end

function Rechargeable:SetOnReadyFn(fn)
	self.onready = fn
end

function Rechargeable:RecalculateRate()
	if self.owner ~= nil and self.is_timer then
		self.cooldownrate = self.owner.components.buffable and self.owner.components.buffable:ApplyStatBuffs({"cooldown"}, 1) or 1
		-- if we still have a recharge going, need to update client info with new rechargetime
		if self.updatetask ~= nil then
			self.inst.replica.inventoryitem:SetChargeTime(self:GetRechargeTime())
		end
	end
end

function Rechargeable:FinishRecharge()
	if self.updatetask ~= nil then
		self.updatetask:Cancel()
		self.updatetask = nil
	end
	self.isready = true
	if self.inst.components.aoetargeting then
		self.inst.components.aoetargeting:SetEnabled(true)
	end
	if self.onready then
		self.onready(self.inst)
	end
	self.pickup = false
	self.recharge = 255
	if self.is_timer then
		self.inst:PushEvent("rechargechange", { percent = self.recharge and self.recharge / 180, overtime = false })
	else
		self.inst:PushEvent("forcerechargechange", {percent = self.recharge and self.recharge / 180, overtime = false})
	end
end

function Rechargeable:Update(amount)
	if self.is_timer then
		self.recharge = self.recharge + 180 * FRAMES / (self.rechargetime * (self.pickup and self.pickup_cooldown or self.cooldownrate))
	else
		self.amount_charged = self.amount_charged + amount
		self.recharge = self.amount_charged / self.max_recharge * 180
	end
	if self.recharge >= 180 then
		self:FinishRecharge()
	elseif not self.is_timer then
		self.inst:PushEvent("forcerechargechange", {percent = self.recharge and self.recharge / 180, overtime = false})
	end
end

function Rechargeable:StartRecharge()
	if not (self.isready or self.pickup) and self.charge_count > 0 then
		local charge_data = table.remove(self.charge_priority, 1)
		self:RemoveCooldownCharge(charge_data.source)
		self.owner:PushEvent("charge_consumed", {item = self.inst, source = charge_data.source})
	end
	self.isready = false
	if self.inst.components.aoetargeting and self.charge_count <= 0 then
		self.inst.components.aoetargeting:SetEnabled(false)
	end
	self.rechargetime = self.pickup and self.pickup_cooldown or self.maxrechargetime
	self.recharge = 0
	self.amount_charged = 0
	if self.is_timer then
		self:RecalculateRate()
		self.inst:DoTaskInTime(0, function()
			self.inst.replica.inventoryitem:SetChargeTime(self:GetRechargeTime())
			self.inst:PushEvent("rechargechange", { percent = self.recharge and self.recharge / 180, overtime = false })
			RemoveTask(self.updatetask)
			self.updatetask = self.inst:DoPeriodicTask(FRAMES, function() self:Update() end)
		end)
	else
		self.inst:PushEvent("forcerechargechange", {percent = self.recharge and self.recharge / 180, overtime = false})
	end
end

function Rechargeable:GetPercent()
	return self.recharge and self.recharge / 180, false
end

function Rechargeable:GetRechargeTime()
	return (self.pickup and 1) or self.maxrechargetime * self.cooldownrate
end

function Rechargeable:AddCooldownCharge(source, priority)
	if not self.charges[source] then
		self.charges[source] = true
		table.insert(self.charge_priority, {source = source, priority = priority})
		table.sort(self.charge_priority, function(a, b)
			return a.priority < b.priority
		end)
		self.charge_count = self.charge_count + 1
		if not self.isready and self.inst.components.aoetargeting and not self.inst.components.aoetargeting:IsEnabled() then
			self.inst.components.aoetargeting:SetEnabled(true)
		end
	end
end

function Rechargeable:RemoveCooldownCharge(source)
	if self.charges[source] then
		self.charges[source] = nil
		for i,data in pairs(self.charge_priority) do
			if data.source == source then
				table.remove(self.charge_priority, i)
				break
			end
		end
		self.charge_count = self.charge_count - 1
		if self.charge_count <= 0 and not self.isready and self.inst.components.aoetargeting then
			self.inst.components.aoetargeting:SetEnabled(false)
		end
	end
end

function Rechargeable:SetOnReadyFN(fn)
	self.onready = fn
end

function Rechargeable:IsReady()
	return self.isready or self.ignore_ready or self.charge_count > 0
end

function Rechargeable:IsTimer()
	return self.is_timer == true
end

function Rechargeable:GetDebugString()
    return string.format("recharge: %2.2f, rechargetime: %2.2f, cooldownrate: %2.2f", self.recharge, self:GetRechargeTime(), self.cooldownrate)
end

return Rechargeable
