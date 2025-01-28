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
--[[
TODO
	test with multiple wigs
	test non wig players getting buffed
--]]
local function RemoveBattleCry(target)
	local passive_battlecry = target.components.passive_battlecry
	if target.battlecry then
		-- Remove Buff
		if target.components.combat then
			target.components.combat:RemoveDamageBuff("battlecry")
		end
		-- Remove FX
		COMMON_FNS.RemoveFX(target.battlecry.fx)
		target.battlecry.fx = nil
		-- Remove Expiration Timer
		RemoveTask(target.battlecry.timer)
		-- Reset BattleCry
		if passive_battlecry then
			passive_battlecry:ResetBattleCry()
		-- Remove Event Listeners
		else
			target.battlecry.OnRemoveFromEntity(target)
		end
		target.battlecry = nil
		Debug:Print("Battle Cry has been removed for " .. tostring(target.name) .. " (" .. tostring(target.userid) .. ")", "log", "BattleCryFX", nil, true)
	-- Check Alt Attack Hits
	elseif passive_battlecry and passive_battlecry.alt_hits > 0 then
		passive_battlecry:BattleCryCheck(passive_battlecry.alt_hits)
		passive_battlecry.alt_hits = 0
	end
end

local function OnAttackOther(inst, data)
	local passive_battlecry = inst.components.passive_battlecry
	-- Check if BattleCry should be triggered
	if passive_battlecry and not passive_battlecry.battle_cry then -- or not inst.battlecry
		passive_battlecry:DecayHits()
		local weapon = data.weapon and data.weapon.components.weapon
		-- Keep track of each hit from an alt attack to update BattleCry after the alt attack is completed
		if data.weapon and data.weapon.components.aoespell and data.weapon.components.aoespell.casting then
			passive_battlecry.alt_hits = passive_battlecry.alt_hits + (weapon and weapon:GetHitWeight() or 1)
		else
			passive_battlecry:BattleCryCheck(weapon and weapon:GetHitWeight())
		end
	-- Remove BattleCry
	elseif inst.battlecry and (not data.weapon or data.weapon and not (data.weapon.components.aoespell and data.weapon.components.aoespell.casting or COMMON_FNS.EQUIPMENT.HasProjectile(data.weapon) and data.weapon.prefab ~= "riledlucy")) then
		RemoveBattleCry(inst)
	end
end

local function OnDeath(inst, data)
	inst.components.passive_battlecry:ResetBattleCry()
end

local function OnRemoveFromEntity(target)
	target:RemoveEventCallback("onhitother", OnAttackOther)
	target:RemoveEventCallback("onmissother", RemoveBattleCry)
	target:RemoveEventCallback("onprojectileattack", RemoveBattleCry)
	target:RemoveEventCallback("spellcomplete", RemoveBattleCry)
end

local PassiveBattleCry = Class(function(self, inst)
	self.debug_mode = true
	self.debug_type = "BattleCry"
    self.player = inst
	self.battle_cry = false
	self.hit_count = 0
	self.hit_count_trigger = 8
	self.radius = 10
	self.decay_time = 1
	self.damage_mult = 1.25
	self.store_time = 6  --Acho que esse é o tempo do buff
	self.alt_hits = 0
	self.last_hit_time = 0

	-- Reset BattleCry on next attack regardless if it hits or not
	self.player:ListenForEvent("onmissother", RemoveBattleCry)
	-- Reset BattleCry when projectiles are thrown
	self.player:ListenForEvent("onprojectileattack", RemoveBattleCry)
	-- Remove BattleCry fot alt attacks after the alt attack has been completed
	self.player:ListenForEvent("spell_complete", RemoveBattleCry)
	-- Update BattleCry count on every hit
	self.player:ListenForEvent("onhitother", OnAttackOther)
	self.player:ListenForEvent("death", OnDeath)

	Debug:Print("Initializing for " .. tostring(self.player.name) .. " (" .. tostring(self.player.userid) .. ")...", "log", self.debug_type, self.debug_mode, true)
end)

-- Updates status of wigfrids Battle Cry ability, triggers on 8 consecutive hits
-- Note: for hits to count as consecutive they must hit a target within "decay_time" or hits will start to decay.
function PassiveBattleCry:BattleCryCheck(hit_count)
	if not self.battle_cry then
		self.hit_count = self.hit_count + (hit_count or 1)
		-- Check for Battle Cry trigger
		if self.hit_count >= self.hit_count_trigger then
			self:ApplyBattleCry()
		end
	end
end

-- Removes non consecutive hits. Decay occurs if the current hit time - the prior hit time is larger than decay_time.
function PassiveBattleCry:DecayHits()
	local current_time = GetTime()
	self.hit_count = math.max(self.hit_count - math.floor((current_time - self.last_hit_time) / self.decay_time), 0)
	self.last_hit_time = current_time
end

-- Apply the Battle Cry to players
function PassiveBattleCry:ApplyBattleCry()
	Debug:Print("Applying Battle Cry for " .. tostring(self.player.name) .. " (" .. tostring(self.player.userid) .. ")...", "log", self.debug_type, self.debug_mode, true)
	self:ApplyBattleCryToTarget(self.player)
	self:ApplyBattleCryToNearbyPlayers()
	self.battle_cry = true
end

-- Resets Battle Cry
function PassiveBattleCry:ResetBattleCry()
	Debug:Print("Remove and Reset Battle Cry for " .. tostring(self.player.name) .. " (" .. tostring(self.player.userid) .. ")", "log", self.debug_type, self.debug_mode, true)
	self.battle_cry = false
	self.hit_count = 0
end

-- Check for players within BATTLECRY_RADIUS of Wigfrid and give them the battle cry
function PassiveBattleCry:ApplyBattleCryToNearbyPlayers()
	-- Check all players coordinates
	for i,player in pairs(AllPlayers) do
		if self.player.userid ~= player.userid and player:IsNear(self.player, self.radius) and not player.components.health:IsDead() then
			self:ApplyBattleCryToTarget(player)
		end
	end
end

-- options:
-- force_other is used to force the battle cry fx to be the "other" fx. This is the fx given to players that recieve the battlecry from another source.
function PassiveBattleCry:ApplyBattleCryToTarget(target, force_other)
	if target == nil then
		Debug:Print("Attempted to give BattleCry to a nil target.", "error")
		return
	end
	-- Restart the battlecry timer if the target already has a battlecry
	if target.battlecry then
		RemoveTask(target.battlecry.timer)
	-- Give the target a battlecry
	else
		target.battlecry = {}
		target.battlecry.fx = COMMON_FNS.CreateFX("battlecry_fx_" .. (not force_other and target.userid == self.player.userid and "self" or "other"), target)
		-- Buff damage for next hit
		if target.components.combat then
			target.components.combat:AddDamageBuff("battlecry", {buff = self.damage_mult}, false)
		end
		-- Reset when used
		if not target.components.passive_battlecry then
			target.battlecry.OnRemoveFromEntity = OnRemoveFromEntity
			-- Reset BattleCry on next attack regardless if it hits or not
			target:ListenForEvent("onhitother", OnAttackOther)
			target:ListenForEvent("onmissother", RemoveBattleCry)
			-- Reset BattleCry when projectiles are thrown
			target:ListenForEvent("onprojectileattack", RemoveBattleCry)
			-- Remove BattleCry for alt attacks after the alt attack has been completed
			target:ListenForEvent("spell_complete", RemoveBattleCry)
		end
	end
	-- Check for special weapon buffs
	local weapon = target.replica.inventory:GetEquippedItem(_G.EQUIPSLOTS.HANDS) or nil
	if weapon then
		weapon:PushEvent("battlecry")
	end
	Debug:Print("Battle Cry created for " .. tostring(target.name) .. " (" .. tostring(target.userid) .. ")", "log", self.debug_type, self.debug_mode, true)

	-- Create timer for Battle Cry duration
	target.battlecry.timer = target:DoTaskInTime(self.store_time, function()
		if target.battlecry then
			RemoveBattleCry(target)
		end
		Debug:Print("Battle Cry has expired for " .. tostring(target.name) .. " (" .. tostring(target.userid) .. ")", "log", self.debug_type, self.debug_mode, true)
	end)
end

function PassiveBattleCry:SetHitCountTrigger(val)
	self.hit_count_trigger = val
end

function PassiveBattleCry:SetDecayTime(val)
	self.decay_time = val
end

function PassiveBattleCry:SetRadius(val)
	self.radius = val
end

function PassiveBattleCry:SetDamageMult(val)
	self.damage_mult = val
end

function PassiveBattleCry:SetStoreTime(val)
	self.store_time = val
end

function PassiveBattleCry:OnRemoveFromEntity()
	OnRemoveFromEntity(self.player)
	self.player:RemoveEventCallback("death", OnDeath)
end

function PassiveBattleCry:GetDebugString()
    return string.format("Status: %s, Hit Count: %d, (duration:%2.2f)", tostring(self.battle_cry), self.hit_count, self.player.battlecry and self.player.battlecry.timer and GetTaskRemaining(self.player.battlecry.timer) or 0)
end

return PassiveBattleCry
