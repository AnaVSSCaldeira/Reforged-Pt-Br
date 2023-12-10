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

local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"
local easing = require "easing"
local Widget = require "widgets/widget"

local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"
local easing = require "easing"
local Widget = require "widgets/widget"
local Queue = require "queue"

local PassiveWidget = Class(Widget, function(self, player, nonhost, position)
    ------------------ NO TOUCHY ------------------
	Widget._ctor(self, "PassiveWidget")
	
	-- Options
	self.display_shadows = options.display_shadows
	self.display_amp = options.display_amp
	self.display_attack_buff = options.display_attack_buff
	self.display_mighty_host = options.display_mighty_host
	self.display_mighty_nonhost = options.display_mighty_nonhost
		
	-- get string for icon image and use that when loading icon
	
	self.player = player
	self.nonhost = nonhost
	
	
	-- Display --
	local bar = self:AddChild(TEMPLATES.LargeScissorProgressBar())
    bar:SetPosition(0, 0)
	
	bar:SetPercent(100)
	
	--self:UpdateDisplay()
end)

-- Update damage checks and display
function PassiveWidget:UpdateTotalDamage(damage, target)
	--print("[Update Damage] " .. self.player.prefab)
	if self.player.prefab == "waxwell" then
		self:ShadowCheck(damage, target)
	elseif self.player.prefab == "wickerbottom" then
		self:AmpCheck(damage)
	elseif self.player.prefab == "wathgrithr" then
		self:AttackBuffCheck()
	end
	self:UpdateDisplay()
end

-- Update display of passives
-- not reset on death possibly because of wilson rezs to 121 health, which 0.005 difference in health percent, to small to notice?
--	check by rezing wolf as wilson
-- poison idea, check for min damage 1 or 0.5 since poison is over time BUT pigs might do 1 damage, they might do 2 as well
function PassiveWidget:UpdateDisplay()
	if self.player.prefab == "wolfgang" and self.mighty then
		local t = GetTime()
		if t - self.mighty_start_time <= self.mighty_duration then
			local time_left = t - self.mighty_start_time
			local time_str = string.format("%.1f", self.mighty_duration - time_left) .. " s"
			self.passive_text:SetString(time_str)
			self.passive_text:Show()
		else
			self.mighty = false
			self.passive_text:Hide()
			self:StopUpdating()
		end
	elseif self.player.prefab == "wx78" then
			self.passive_text:SetString(tostring(self.shock_hit_count) .. "/" .. tostring(self.shock_hit_count_trigger))
	elseif self.nonhost == false then 
		if self.player.prefab == "waxwell" then
			self.passive_text:SetString(tostring(self.shadow_current_damage) .. "/" .. tostring(self.shadow_damage_trigger))
		elseif self.player.prefab == "wickerbottom" then
			self.passive_text:SetString(tostring(self.amp_current_damage) .. "/" .. tostring(self.amp_damage_trigger))
		elseif self.player.prefab == "wathgrithr" then
			self.passive_text:SetString(tostring(self.attack_buff_current_hit_count) .. "/" .. tostring(self.attack_buff_hit_count_trigger))
		end
	end
end

-- called every tick after self:StartUpdating() is called
function PassiveWidget:OnUpdate(dt)
	local t = GetTime()
	
	-- if havent updated text display in self.dt_display time, then update it
	if (t - self.last_update) > self.dt_display then
		-- Update Mighty duration
		if self.player.prefab == "wolfgang" and self.mighty then
			self.last_update = t
			self:UpdateDisplay()
		-- Check for consistent attacks from wigfrid
		elseif self.player.prefab == "wathgrithr" then --and self.attack_buff_current_hit_count > 0 --(t - self.attack_buff_hit_times.first) >= self.attack_buff_timer_reset then
			self:AttackBuffHitUpdate()
		elseif self.player.prefab == "wx78" and t - self.shock_current_trigger_time > self.shock_timer_reset then
			self.shock_triggered = false
			self.shock_hit_count = 0
			self:StopUpdating()
			self:UpdateDisplay()
		end
	end
end

-- Check which icon needs to be displayed
function PassiveWidget:IconCheck()
	local image_name = ""
	if self.player.prefab == "waxwell" then
		self.ability_icon = self:AddChild(Image("images/lavaarena_achievements.xml", image_name .. "waxwell_minion_kill.tex"))
		--waxwell_minion_kill
	elseif self.player.prefab == "wickerbottom" then
		-- check weapons
		self.ability_icon = self:AddChild(Image("images/lavaarena_achievements.xml", "wickerbottom_healing.tex"))
		--wickerbottom_healing
		--wickerbottom_meteor
	elseif self.player.prefab == "wathgrithr" then
			self.ability_icon = self:AddChild(Image("images/lavaarena_achievements.xml", "wathgrithr_battlecry.tex"))
			--wathgrithr_battlecry
	elseif self.player.prefab == "woodie" then
		self.ability_icon = self:AddChild(Image("images/lavaarena_achievements.xml", "woodie_lucychuck.tex"))
		--woodie_lucychuck
	elseif self.player.prefab == "wx78" then
		self.ability_icon = self:AddChild(Image("images/lavaarena_achievements.xml", "wx78_shocks.tex"))
		--wx78_shocks
		--wx78_anvil
		if self.nonhost then
			self.ability_icon:ScaleToSize(50, 50, true)
		end
	elseif self.player.prefab == "webber" then
		self.ability_icon = self:AddChild(Image("images/lavaarena_achievements.xml", "webber_merciless.tex"))
		--webber_merciless
	elseif self.player.prefab == "wolfgang" then
		image_name = "mighty" -- REMOVE when you have all icons done
		self.ability_icon = self:AddChild(Image("images/" .. image_name .. ".xml", image_name .. ".tex"))
		if self.nonhost then
			self.ability_icon:ScaleToSize(50, 50, true)
		else
			self.ability_icon:ScaleToSize(100, 100, true)
		end
	end	
end

return PassiveWidget
