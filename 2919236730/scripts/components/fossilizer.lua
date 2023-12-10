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
local Fossilizer = Class(function(self, inst)
	self.inst = inst
	self.range = 1 -- TODO tuning
	self.duration = 1.75 -- length of spell, NOT fossilization
	self.fossilized_list = {}
end)

function Fossilizer:SetRange(range)
	self.range = range
end

-- TODO adjust this, currently recursive and goes through the 3 anims for fossilizing
local function SpawnFossilFX(inst, caster, pos, amount, current)
	if not current then
		current = 1
	end
	local total_slots = 5
	local scale = caster and caster.components.scaler and caster.components.scaler.scale or 1
	local radius = 3 * scale
	for slot = 1, total_slots, 1 do
		local fossil_fx = COMMON_FNS.CreateFX("fossilizing_fx" .. (current - 1 > 0 and ("_" .. tostring(current - 1)) or ""), nil, caster)
		--fossil_fx.Transform:SetRotation(slot/total_slots * 360)
		local offset = FindWalkableOffset(pos, ((slot/total_slots * 360)* PI / 180), radius, 2, true, true) or {x = 0, y = 0, z = 0}
		fossil_fx.Transform:SetPosition(pos.x + offset.x, pos.y + offset.y, pos.z + offset.z)
		--fossil_fx:ListenForEvent()
	end
	if current < amount then
		inst:DoTaskInTime(0.5, function(inst) SpawnFossilFX(inst, caster, pos, amount, current + 1) end)
	end
end

function Fossilizer:SpawnFosilFx(pos)
	local positions = {}

	--Creating positions to choose where to spawn fx
	for i = 1, 20 do
		local s = i/5
		local a = math.sqrt(s*512)
		local b = math.sqrt(s)

		local test = Vector3(math.sin(a)*b*1.2, 0, math.cos(a)*b*1.2)

		--We don't want to spawn on water, right?
		local tile = TheWorld.Map:GetTileAtPoint((pos + test):Get())
		if tile ~= 1 and tile ~= 255 then
			table.insert(positions, test)
		end
	end

	--[[
	-- TODO this seems a bit hacky....find a better way to do this
	local i = 0
	self.spawn_task = self.inst:DoPeriodicTask(.15, function()
		i = i + 1

		if i >= 13 and self.spawn_task then -- 2 seconds
			self.spawn_task:Cancel()
			self.spawn_task = nil

			return
		end

		-- TODO SpawnAt takes scale too....so why do a transform setscale when you can just pass it the .65?
		SpawnAt("fossilizing_fx", pos + positions[math.random(#positions)]).Transform:SetScale(.65, .65, .65)
	end)--]]
end

function Fossilizer:Fossilize(pos, caster)
	RemoveTask(self.fossilize_task)
	--self:SpawnFosilFx(pos)
	SpawnFossilFX(self.inst, caster, pos, 3) -- TODO check if this occurs in real forge
	self.fossilized_list = {}
	local scale = caster and caster.components.scaler and caster.components.scaler.scale or 1
	local mults, adds, flats = caster and caster.components.buffable and caster.components.buffable:GetStatBuffs({"spell_duration"}) or 1,1,0
	self.fossilize_task = self.inst:DoPeriodicTask(.25, function()
		local targets = COMMON_FNS.EQUIPMENT.GetAOETargets(caster, pos, self.range*scale, {"fossilizable"})
		for _,target in ipairs(targets) do
			-- only petrify the target if they have not already been petrified by this instance
			if not self.fossilized_list[target] then
				if TheWorld and TheWorld.components.stat_tracker and target.sg and target.sg:HasStateTag("hiding") then
					TheWorld.components.stat_tracker:AdjustStat("guardsbroken", caster, 1)
				end
				local has_constant_duration = target.components.fossilizable:HasConstantDuration()
				local duration = target.components.fossilizable:GetDuration()
				duration = not has_constant_duration and (duration * mults * adds + flats) or duration
				target:PushEvent("fossilize", {duration = duration, doer = caster})
				self.fossilized_list[target] = true
			end
		end
	end)
	-- TODO use cast time instead of 2, not sure what it's supposed to be
	self.inst:DoTaskInTime(self.duration, function(inst)
		RemoveTask(self.fossilize_task)
	end)
end

function Fossilizer:OnRemoveEntity()
	for _, task in ipairs({"spawn_task", "fossilize_task"}) do
		RemoveTask(self[task])
	end
end

Fossilizer.OnRemoveFromEntity = Fossilizer.OnRemoveEntity

--[[function Fossilizer:GetDebugString()
    return string.format("Duration: %2.2f", self.duration)
end--]]

return Fossilizer
