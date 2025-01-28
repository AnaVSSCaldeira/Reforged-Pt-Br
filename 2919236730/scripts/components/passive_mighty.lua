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
local strength_list = {
	[1] = {
		name = "wimpy",
		skin = {"wimpy_skin", "wolfgang_skinny"},
		damage_mult = 0.5,
		resistance_mult = -0.5,
		scale = 0.9,
		announcement = {down = "ANNOUNCE_NORMALTOWIMPY"},
		sounds = {
			talk = "dontstarve/characters/wolfgang/talk_small_LP",
			hurt = "dontstarve/characters/wolfgang/hurt_small",
			down = "dontstarve/characters/wolfgang/shrink_medtosml",
		},
	},
	[2] = {
		name = "normal",
		skin = {"normal_skin", "wolfgang"},
		damage_mult = 1,
		resistance_mult = 0,
		scale = 1,
		announcements = {down = "ANNOUNCE_MIGHTYTONORMAL", up = "ANNOUNCE_WIMPYTONORMAL"},
		sounds = {
			up = "dontstarve/characters/wolfgang/grow_smtomed",
			down = "dontstarve/characters/wolfgang/shrink_lrgtomed",
		},
	},
	[3] = {
		name = "mighty",
		skin = {"mighty_skin", "wolfgang_mighty"},
		damage_mult = 2,
		resistance_mult = 0.5,
		scale = 1.5,
		announcements = {up = "ANNOUNCE_NORMALTOMIGHTY"},
		sounds = {
			talk = "dontstarve/characters/wolfgang/talk_large_LP",
			hurt = "dontstarve/characters/wolfgang/hurt_large",
			up = "dontstarve/characters/wolfgang/grow_medtolrg",
		},
	},
}

local function OnAttacked(inst, data)
	if inst.components.passive_mighty then
		inst.components.passive_mighty:OnAttacked()
	end
end

local function OnHealthChange(inst, data)
	if inst.components.passive_mighty then
		inst.components.passive_mighty:OnHealthChange()
	end
end

local function OnDeath(inst, data)
	if inst.components.passive_mighty then
		inst.components.passive_mighty:OnDeath()
	end
end

local function OnRevived(inst, data)
	if inst.components.passive_mighty then
		inst.components.passive_mighty:OnRevived()
	end
end

local PassiveMighty = Class(function(self, inst)
	self.debug_mode = false
	self.debug_type = "Mighty"
    self.player = inst
	self.mighty_ready = false
	self.health_threshold = 0.5
	self.health_trigger = 0.3
	self.duration = 30
	self.current_strength = 2
	self.normal_strength = 2
	self.previous_strength = 2
	self.ignore_skins = false
	
	self.player:ListenForEvent("attacked", OnAttacked)
	self.player:ListenForEvent("healthdelta", OnHealthChange)
	self.player:ListenForEvent("death", OnDeath)
	self.player:ListenForEvent("respawnfromcorpse", OnRevived)
	
	Debug:Print("Initializing for " .. tostring(self.player.name) .. " (" .. tostring(self.player.userid) .. ")...", "log", self.debug_type, self.debug_mode, true)
end)

-- Check and update Mighty status when health changes
function PassiveMighty:OnHealthChange()
	if self.player.sg:HasStateTag("nomorph") or self.player:HasTag("playerghost") or self.player.components.health:IsDead() then
        return
    end
	-- Check if Mighty should be reset (players health is above the threshold)
	if self.player.components.health:GetPercent() > self.health_threshold and not self.mighty_ready then
		Debug:Print(tostring(self.player.name) .. "'s (" .. tostring(self.player.userid) .. ")" .. " health is above " .. tostring(self.health_threshold), "log", self.debug_type, self.debug_mode, true)
		self.mighty_ready = true
	end
end

-- Ends the mighty task died while active
function PassiveMighty:OnDeath()
	RemoveTask(self.mighty_timer)
end

-- Check if Mighty should be triggered (players health is below the trigger) when attacked
function PassiveMighty:OnAttacked()
	if self.player.components.health:GetPercent() < self.health_trigger and self.mighty_ready then
		Debug:Print(tostring(self.player.name) .. "'s (" .. tostring(self.player.userid) .. ")" .. " health is below " .. tostring(self.health_trigger), "log", self.debug_type, self.debug_mode, true)
		self:UpdateMightiness(self.current_strength + 1)
		self.mighty_ready = false
	end
end

local ANIM_DURATION = 29 -- amount of frames the powerup and powerdown anims last
local SCALE_STEPS = 5 -- amount of scaling frames to occur for a change in mightiness
function PassiveMighty:ScalingAnim()
	local current_scale = strength_list[self.current_strength].scale
	local previous_scale = strength_list[self.previous_strength].scale
	local scaling_step = (current_scale - previous_scale)/SCALE_STEPS
	-- Remove timers if they already exist
	if self.scale_timers then
		for _,scale_timer in pairs(self.scale_timers) do
			RemoveTask(scale_timer)
		end
	end
	self.scale_timers = {}
	for i=1,SCALE_STEPS do
		self.scale_timers[i] = self.player:DoTaskInTime((i-1)*(ANIM_DURATION/SCALE_STEPS)*FRAMES, function()
			self.player:ApplyScale("mightiness", previous_scale + scaling_step*i)
			self.scale_timers[i] = nil
		end)
	end
end

-- Update players stats based on current mightiness
function PassiveMighty:ApplyMightiness()	
	Debug:Print("Adjusting Mightiness to " .. tostring(self.current_strength) .. " for " .. tostring(self.player.name) .. " (" .. tostring(self.player.userid) .. ")", "log", self.debug_type, self.debug_mode, true)
	
	local strength_info = strength_list[self.current_strength]
	self:ScalingAnim()
	self.player.components.combat.damagemultiplier = strength_info.damage_mult
	self.player.components.health.absorb = strength_info.resistance_mult
	-- Mighty
    if self.current_strength > self.normal_strength then
		self.player:AddTag("heavybody")
		self:StartTimer()
	-- Normal/Wimpy
    else
		self.player:RemoveTag("heavybody")
    end
	
	Debug:Print("Updated stats for " .. tostring(self.player.name) .. " (" .. tostring(self.player.userid) .. ")" .. ": dmg: " .. tostring(self.player.components.combat.damagemultiplier) .. " absorb: " .. tostring(self.player.components.health.absorb), "log", self.debug_type, self.debug_mode, true)
end

function PassiveMighty:UpdateMightiness(strength)
	self.previous_strength = self.current_strength
	if self.current_strength == strength then
		-- Restart timer if mighty is currently active
		if self.current_strength > self.normal_strength then
			self:StartTimer()
		end
		return
	end
	local strength_info = strength_list[strength]
	if not strength_info then
		Debug:Print("Tried to update mightiness to an invalid strength of " .. tostring(strength) .. ".", "warning")
		return
	end
	Debug:Print(tostring(self.player.name) .. " (" .. tostring(self.player.userid) .. ") is becoming " .. tostring(strength_info.name), "log", self.debug_type, self.debug_mode, true)
	
	if not self.ignore_skins then
		self.player.components.skinner:SetSkinMode(unpack(strength_info.skin))
	end
	local is_up = strength > self.current_strength
	--self.player.components.talker:Say(GetString(self.player, strength_info.announcements[is_up and "up" or "down"]))
	self.player.sg:AddStateTag("nointerrupt")
	self.player:PushEvent(is_up and "powerup" or "powerdown")
	self.player.SoundEmitter:PlaySound(strength_info.sounds[is_up and "up" or "down"])
	
	self.player.talksoundoverride = strength_info.sounds.talk
    self.player.hurtsoundoverride = strength_info.sounds.hurt
    self.current_strength = strength
	
	self:ApplyMightiness()
end

-- Create timer for Mighty duration (Reset it if it already exists)
function PassiveMighty:StartTimer()
	RemoveTask(self.mighty_timer)
	self.mighty_timer = self.player:DoTaskInTime(self.duration, function()
		if not self.player.components.health:IsDead() then
			self:UpdateMightiness(self.current_strength - 1)
			Debug:Print("Mighty has expired for " .. tostring(self.player.name) .. " (" .. tostring(self.player.userid) .. ")", "log", self.debug_type, self.debug_mode, true)
		end
		self.mighty_timer = nil
	end)
end

function PassiveMighty:OnRevived()
	if self.current_strength ~= self.normal_strength then -- if not normal then make normal
		self:UpdateMightiness(self.normal_strength)
	end
	self.mighty_ready = false
	self:OnHealthChange()
end

function PassiveMighty:SetDuration(val)
	self.duration = val
end

function PassiveMighty:SetHealthThreshold(val)
	self.health_threshold = val
end

function PassiveMighty:SetHealthTrigger(val)
	self.health_trigger = val
end

-- Add a new level of strength
-- Options:
-- skin - {bank, build} -- TODO is it bank and build or something else?
-- announcement = {up = "", down = ""}
--    up is used if reaching this level of strength from a lower level and vice versa for down.
-- sounds = {talk = "", hurt = "", up = "", down = ""}
--    up is used if reaching this level of strength from a lower level and vice versa for down.
function PassiveMighty:AddStrength(index, name, skin, damage_mult, resistance_mult, scale, announcement, sounds)
	local new_strength = {
		name = name,
		skin = skin,
		damage_mult = damage_mult,
		resistance_mult = resistance_mult,
		scale = scale,
		announcement = announcement,
		sounds = sounds,	
	}
	table.insert(strength_list, index, new_strength)
end

function PassiveMighty:RemoveStrength(index)
	table.remove(strength_list, index)
end

function PassiveMighty:GetStrengthList()
	return strength_list
end

function PassiveMighty:GetStrength(name)
	for _,strength in pairs(strength_list) do
		if strength.name == name then
			return strength
		end
	end
end

function PassiveMighty:SetDamageMult(name, val)
	local strength = self:GetStrength(name)
	strength.damage_mult = val
end

function PassiveMighty:SetResistanceMult(name, val)
	local strength = self:GetStrength(name)
	strength.resistance_mult = val
end

function PassiveMighty:SetScale(name, val)
	local strength = self:GetStrength(name)
	strength.scale = val
end

function PassiveMighty:OnRemoveFromEntity()
	RemoveTask(self.mighty_timer)
	self.player:RemoveEventCallback("attacked", OnAttacked)
	self.player:RemoveEventCallback("healthdelta", OnHealthChange)
	self.player:RemoveEventCallback("death", OnDeath)
	self.player:RemoveEventCallback("respawnfromcorpse", OnRevived)
end

function PassiveMighty:GetDebugString()
    return string.format("Status: %s, Current Strength: %s, (duration:%2.2f)", tostring(self.mighty_ready), self.current_strength, self.mighty_timer and GetTaskRemaining(self.mighty_timer) or 0)
end

return PassiveMighty
