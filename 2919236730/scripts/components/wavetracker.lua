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

local function GetIndex(a, b)
	return tostring(a).." "..tostring(b)
end

local function IndexToWaves(i)
	return string.split(i, " ")
end

local function IndexTable(tbl) 
	local i = 0 
	
	for k, v in pairs(tbl) do 
		i = i + 1 
	end 
	
	return i 
end

local WaveTracker = Class(function(self, inst)
	self.inst = inst
	
	self.round_mobs = {}
	
	self:DoDebug()
end)

function WaveTracker:SetMobsForWave(round, wave, mobs)
	local index = GetIndex(round, wave)
	
	if self.round_mobs[index] ~= nil or self.round_index ~= nil then
		Debug:Print("Tried to add mobs for wave while not all wave mobs are killed!", "error")
		return
	end
	
	self.round_index = index
	
	self.round_mobs[index] = {}
	for _, ent in ipairs(mobs) do
		self.round_mobs[index][ent] = true
	end
	
	self:StartTrackingWave()
end

function WaveTracker:StartTrackingWave() --inst = c_spawn("spider") TheWorld.components.wavetracker:SetMobsForWave(1, 1, {inst})
	if not self.round_mobs[self.round_index] or IndexTable(self.round_mobs[self.round_index]) == 0 then
		Debug:Print("round_mobs for current round are nil or 0!", "error")
		return
	end
	
	for ent, _ in pairs(self.round_mobs[self.round_index]) do
		--print("Applying ondeath to "..tostring(ent))
		ent:ListenForEvent("death", function(ent)
			--print("OnDeath - "..tostring(ent))
			self.round_mobs[self.round_index][ent] = nil
			
			if IndexTable(self.round_mobs[self.round_index]) == 0 then
				local round_dat = IndexToWaves(self.round_index)
				self.inst:PushEvent("ms_lavaarena_mobsforwavedied", {round = tonumber(round_dat[1]), wave = tonumber(round_dat[2])})
				
				self.round_mobs[self.round_index] = nil
				self.round_index = nil
			end
		end)
	end
end

function WaveTracker:GetMobsForCurrenWave()
	return self.round_mobs[self.round_index] or {}
end

function WaveTracker:DoDebug()
	self.inst:ListenForEvent("ms_lavaarena_mobsforwavedied", function(inst, data)
		printwrap("ms_lavaarena_mobsforwavedied", data)
	end)
end

return WaveTracker
