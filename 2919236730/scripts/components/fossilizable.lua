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
-- Stat Update Functions --
local function UpdateNumCCStat(self)
	if self.last_caster and TheWorld.components.stat_tracker then
		TheWorld.components.stat_tracker:AdjustStat("numcc", self.last_caster, 1)
	end
end

local function UpdateTimeCCStat(self)
	if self.last_caster and self.start_time and TheWorld.components.stat_tracker then
		TheWorld.components.stat_tracker:AdjustStat("cctime", self.last_caster, GetTime() - self.start_time)
	end
end
---------------------------
local function OnAttacked(inst, data)
	local self = inst.components.fossilizable

	if self:IsFossilized() then
		inst:PushEvent("unfossilize")
		if TheWorld and TheWorld.components.stat_tracker then
			-- ...
			-- update stat: ccbroken
			if data.attacker then
				TheWorld.components.stat_tracker:AdjustStat("ccbroken", data.attacker, 1)
			end
		end
	end
end

local Fossilizable = Class(function(self, inst)
	self.inst = inst
	self.duration = TUNING.FORGE.PETRIFYINGTOME.DURATION
	self.start_time = nil
	self.last_caster = nil
	self.has_constant_duration = false
	self.on_fossilize_fn = nil
	self.on_unfossilize_fn = nil

	self.inst:ListenForEvent("attacked", OnAttacked)
end)

function Fossilizable:SetDuration(duration, constant_duration)
	self.has_constant_duration = constant_duration
	self.duration = duration or self.duration
end

function Fossilizable:SetOnFossilizeFN(fn)
	self.on_fossilize_fn = fn
end

function Fossilizable:SetOnUnfossilizeFN(fn)
	self.on_unfossilize_fn = fn
end

function Fossilizable:GetDuration(caster) -- TODO use this everywhere in this component file
	return self.duration
end

function Fossilizable:HasConstantDuration(caster)
	return self.has_constant_duration
end

function Fossilizable:OnSpawnFX()
	if self.inst.SoundEmitter then
		self.inst.SoundEmitter:PlaySound("dontstarve/common/lava_arena/spell/fossilized")
	end

	SpawnAt("fossilizing_fx", self.inst)
end

function Fossilizable:SpawnUnfossilizeFx()
	SpawnAt("fossilized_break_fx", self.inst):Setup(self.inst)
end

function Fossilizable:Fossilize(duration, caster)
	if self.inst.SoundEmitter then
		self.inst.SoundEmitter:PlaySound("dontstarve/common/lava_arena/spell/fossilized")
	end
	self.start_time = GetTime()
	self.last_caster = caster
	if self.fossil_timer then
		self.fossil_timer:Cancel()
		self.fossil_timer = nil
	end
	self.fossil_timer = self.inst:DoTaskInTime(duration, function(inst) self.inst:PushEvent("unfossilize") end)

	-- TODO should it increase the stat if the same person is ccing before they are "uncc'd"
	UpdateNumCCStat(self)
end

function Fossilizable:OnFossilize(duration, caster)
	self.inst:AddTag("fossilized")
	self:Fossilize(duration, caster)
	if self.on_fossilize_fn then
		self.on_fossilize_fn(self.inst, caster)
	end
end

function Fossilizable:OnUnfossilize()
	self.inst:RemoveTag("fossilized")
	UpdateTimeCCStat(self)
	self.start_time = nil -- TODO is this needed?
	if self.fossil_timer then
		self.fossil_timer:Cancel()
		self.fossil_timer = nil
	end
	-- self:SpawnUnfossilizeFx()
	if self.on_unfossilize_fn then
		self.on_unfossilize_fn(self.inst)
	end
end

function Fossilizable:OnExtend(duration, caster)
	UpdateTimeCCStat(self)
	self:Fossilize(duration, caster)
end

function Fossilizable:IsFossilized()
	return self.inst:HasTag("fossilized")
end

function Fossilizable:GetDebugString()
    return string.format("status:%s, base_duration:%2.2f, last_caster:%s, (duration:%2.2f)", tostring(self:IsFossilized()), self.duration, tostring(self.last_caster), self.fossil_timer and GetTaskRemaining(self.fossil_timer) or 0)
end

return Fossilizable
