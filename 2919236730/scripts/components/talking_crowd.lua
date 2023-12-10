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

--CunningFox: We need to make it client-only 'cause
--This uses 2d ambiences

-- Just as reminder
--[[
local STATES = {
	CALM = 0,
	CHEER_MOB = 1,
	CHEER_HUMAN = 2,
}]]

local SOUNDS = {
	"dontstarve/lava_arena_amb/cheer_creature",
	"dontstarve/lava_arena_amb/cheer_human",
	"dontstarve/lava_arena_amb/crowds",
}

local TalkingCrowd = Class(function(self, inst)
	self.inst = inst

	self.state = 0
	self.sound = TheFrontEnd:GetSound() or inst.SoundEmitter

	self.inst:DoTaskInTime(0, function() self:StartAMB() end)
end)

function TalkingCrowd:StartAMB()
	if self.sound:PlayingSound("crowd_amb") then
		self.sound:KillSound("crowd_amb")
	end
	self.sound:PlaySound(SOUNDS[3], "crowd_amb")
end

function TalkingCrowd:ChangeState(val)
	self.state = val

	if self.state < 1 then
		self:StopCheerSounds()
	else
		self:StartCheerSounds()
	end
end

function TalkingCrowd:StartCheerSounds()
	self:StopCheerSounds()

	local function DoCheer() -- TODO this needs to be looked at and fixed.
		--print("Playing Crowd Cheer Sound...")
		if self.sound:PlayingSound("crowd_reaction") then
			self.sound:KillSound("crowd_reaction")
		end
		self.sound:PlaySound(SOUNDS[self.state], "crowd_reaction")
		self.sound:SetVolume("crowd_reaction", .5)
		self.task = self.inst:DoTaskInTime(math.random()*2+math.random()*2 + 1.5, DoCheer)
		--print("- Completed Crowd Cheer Sound!")
	end

	DoCheer()
end

function TalkingCrowd:StopCheerSounds()
	--self.sound:KillSound("crowd_reaction")

	if self.task then
		self.task:Cancel()
		self.task = nil
	end
end

return TalkingCrowd
