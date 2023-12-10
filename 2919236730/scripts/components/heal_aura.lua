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
local HealAura = Class(function(self, inst)
	self.inst = inst
	self.range = TUNING.FORGE.LIVINGSTAFF.RANGE
	self.duration = TUNING.FORGE.LIVINGSTAFF.DURATION
	self.heal_rate = TUNING.FORGE.LIVINGSTAFF.HEAL_RATE

	self.cache = {}
	self.ignored_cache = {}
	self.pos = nil
	self.start_time = GetTime()
	self.current_time = 0
	self.attack_cooldown = 2 -- TODO need to check this value, might be less
	self.oversleep_duration = 2 -- sleep time after heal ends
	self.sleep_duration = 3--self.duration + self.oversleep_duration -- total sleep time
	self.sleep_period = 0.5--1 -- TODO might be less
	self.sleep_cooldown = 2

	self.inst:DoTaskInTime(0, inst.StartUpdatingComponent, self)
	self.onunfossilize = function(ent) self:OnUnfossilize(ent) end
	self.onwakeupstat = function(ent) self:OnWakeUpStat(ent) end
end)

local function IsDebuffable(ent)
	return ent.components.debuffable and ent.components.debuffable:CanBeDebuffedByDebuff("healingcircle_regenbuff")
end

local function CanBeSlept(ent)
	return ent.components.debuffable == nil or ent.components.debuffable:CanBeDebuffedByDebuff("sleep")
end

local function IsEntityAlive(ent)
	return ent.components.health and not ent.components.health:IsDead() and ent:IsValid()
end

local function IsPlayerOrAlly(ent)
	return ent:HasTag("player") or ent:HasTag("companion")
end

local function IsValidEnt(ent)
	return IsPlayerOrAlly(ent) and IsDebuffable(ent) or not IsPlayerOrAlly(ent) and CanBeSlept(ent)
end

-- to prevent skipping states with epic mobs unfossilizing and mobs in bunkered, attack, fossilized, or burning states from being slept
local function IsIgnoreState(ent)
	--return ent:HasTag("fossilized") or ent:HasTag("fire") or
		--ent.sg and (ent.sg:HasStateTag("hiding") or ent.sg.HasStateTag("attack") or ent.sg:HasStateTag("nosleep") or
		--(ent:HasTag("epic") and ent.sg:HasStateTag("caninterrupt")))
	return ent:HasTag("fossilized") or ent:HasTag("fire") or
		ent.sg and (ent.sg:HasStateTag("hiding") and not ent.sg:HasStateTag("attack") or (ent:HasTag("epic") and ent.sg:HasStateTag("caninterrupt")))
end

-- TODO move these 2 methods to the sleeper component?

-- we don't want the mob falling asleep while we are attacking them or attacked too recently
function HealAura:IsRecentlyAttacked(ent)
	return self.current_time - ent.components.combat.lastwasattackedtime < (ent.random_attack_cooldown or self.attack_cooldown)
end

function HealAura:AddMobSleep(ent)
	local sleeper = ent.components.sleeper
	if sleeper and (not sleeper.isasleep and (GetTime() - sleeper.lasttransitiontime > self.sleep_cooldown) -- Don't put a mob back to sleep that has recently woken up
		or sleeper.isasleep and (self.duration - (self.current_time - self.start_time) > self.sleep_duration - 1)) -- Stop putting to sleep when the time left of the heal aura is less than the sleep duration (-1)
		and not self:IsRecentlyAttacked(ent) and not IsIgnoreState(ent) and (not ent.components.debuffable or IsDebuffable(ent)) then
		 -- self.testtime = math.max(0, self.testperiod + math.random() - .5)
		ent.components.sleeper:GoToSleep(self.sleep_duration, self.caster)
	end
end

local function SleepingCondition(ent, data) -- TODO still wakes up sometimes in the middle of heal auras, possibly due to _isinheals being removed for a short period.
	return data and data.heal_aura and data.heal_aura.inst and data.heal_aura.inst:IsValid() and data.heal_aura.cache[ent] and IsEntityAlive(ent) -- ent:HasTag("_isinheals") -- Remove isinheals check to be compatible with multiple heals
end

local function Sleep(ent, data)
	local sleeper = ent.components.sleeper
	if data and data.heal_aura then
		data.heal_aura:AddMobSleep(ent)
	end
end

local function OnExitSleep(ent, data)
	-- Prevent ents from sleeping after a Heal Aura has ended.
	if not (ent:HasTag("_isinheals") or ent.sg:HasStateTag("delaysleep")) then
		ent.sg.mem.sleep_duration = nil
		if ent.components.sleeper and ent.components.sleeper:IsAsleep() and not (ent.sg:HasStateTag("sleeping") or ent.sg:HasStateTag("waking")) then
			ent.components.sleeper:WakeUp()
		end
	end
end

local function SleepThread(ent, heal_aura)
	CreateConditionThread(ent, "heal_aura_sleep_" .. tostring(heal_aura.inst.GUID), 0, heal_aura.sleep_period, SleepingCondition, Sleep, OnExitSleep, {heal_aura = heal_aura})
	Sleep(ent, heal_aura)
end

function HealAura:InRange(ent)
	local pos = ent:GetPosition()
	return distsq(pos.x, pos.z, self.pos.x, self.pos.z) < self.range * self.range
end

function HealAura:OnUpdate(dt) -- TODO use mob radius????
	self.current_time = GetTime()
	if not self.pos then self.pos = self.inst:GetPosition() end
	local ents = TheSim:FindEntities(self.pos.x, 0, self.pos.z, self.range, {"locomotor"}) -- TODO could exclude "_isinheals" since they would be set already
	for _, ent in pairs(ents) do
		if not self.cache[ent] and IsEntityAlive(ent) then
			if IsValidEnt(ent) and (not IsPlayerOrAlly(ent) or not ent.components.debuffable:HasDebuff("healingcircle_regenbuff")) then
				self.cache[ent] = true
				self.ignored_cache[ent] = nil
				self:OnEntEnter(ent)
				ent:PushEvent("entered_heal_aura", {heal_aura = self.inst, ignored = false})
			elseif not self.ignored_cache[ent] then
				self.ignored_cache[ent] = true
				ent:PushEvent("entered_heal_aura", {heal_aura = self.inst, ignored = true})
			end
		end
	end
	for ent in pairs(self.cache) do
		if not IsEntityAlive(ent) or not self:InRange(ent) or not IsValidEnt(ent) then
			self:OnEntLeave(ent)
			ent:PushEvent("exited_heal_aura", {heal_aura = self.inst})
		end
	end
	for ent in pairs(self.ignored_cache) do
		if not IsEntityAlive(ent) or not self:InRange(ent) then
			self.ignored_cache[ent] = nil
			ent:PushEvent("exited_heal_aura", {heal_aura = self.inst})
		end
	end
end

function HealAura:OnEntEnter(ent)
	ent:AddTag("_isinheals") -- for targeting and shield behaviours -- TODO change tag name to a more generic term
	if ent.components.colouradder then
		ent.components.colouradder:PushColour("heal_aura_" .. tostring(self.inst.GUID), 0, 0.3, 0.1, 1, true, .35)
	end
	ent.heal_aura_count = (ent.heal_aura_count or 0) + 1
	if IsPlayerOrAlly(ent) and IsDebuffable(ent) then
		local debuffable = ent.components.debuffable
		debuffable:AddDebuff("healingcircle_regenbuff", "healingcircle_regenbuff")
		local healingcircle_regenbuff = debuffable:GetDebuff("healingcircle_regenbuff")
		if healingcircle_regenbuff then
			healingcircle_regenbuff.heal_value = self.heal_rate * healingcircle_regenbuff.tick_rate
			healingcircle_regenbuff.caster = self.caster
		end
		if debuffable:HasDebuff("scorpeon_dot") then
			debuffable:RemoveDebuff("scorpeon_dot")
		end
	elseif ent.components.sleeper and not IsPlayerOrAlly(ent) then
		SleepThread(ent, self) -- TODO put function contents here when functional
		--[[
		ent.random_attack_cooldown = self.attack_cooldown + math.random()
		if ent:HasTag("epic") then
			ent:ListenForEvent("unfossilize", self.onunfossilize)
		end--]]
	end
end

function HealAura:OnEntLeave(ent)
	if not self.cache[ent] then
		Debug:Print("Tried to remove non-exsisting ent!", "error")
		return
	end
	ent.heal_aura_count = ent.heal_aura_count - 1
	if ent.heal_aura_count <= 0 then
		if ent:HasTag("_isinheals") then
			ent:RemoveTag("_isinheals")
		end
	end
	if ent.components.colouradder then
		ent.components.colouradder:PopColour("heal_aura_" .. tostring(self.inst.GUID), true, .35)
	end
	if ent.components.debuffable and ent.components.debuffable:HasDebuff("healingcircle_regenbuff") then
		ent.components.debuffable:RemoveDebuff("healingcircle_regenbuff")
	elseif not IsPlayerOrAlly(ent) then
		if ent:HasTag("epic") then
			ent:RemoveEventCallback("unfossilize", self.onunfossilize)
		end
	end
	self.cache[ent] = nil
end

-- this will prevent boarrior and boarilla from sleeping instantly after you fossilize
-- them inside of a heal if they were previously asleep
-- this also fixes a bug where they would not sleep again after being awakened with fossilization
function HealAura:OnUnfossilize(ent)
	if self.current_time - ent.components.sleeper.lasttransitiontime < (ent.random_attack_cooldown or self.attack_cooldown) then
		ent.components.combat.lastwasattackedtime = self.current_time
		ent.components.sleeper:WakeUp() -- fixes a delay with brain not activating
	end
end

function HealAura:Stop()
	self.inst:StopUpdatingComponent(self)
	for ent in pairs(self.cache) do
		self:OnEntLeave(ent)
		ent:PushEvent("exited_heal_aura", {heal_aura = self.inst})
	end
	for ent in pairs(self.ignored_cache) do
		ent:PushEvent("exited_heal_aura", {heal_aura = self.inst})
	end
end

HealAura.OnRemoveEntity = HealAura.Stop
HealAura.OnRemoveFromEntity = HealAura.Stop

return HealAura
