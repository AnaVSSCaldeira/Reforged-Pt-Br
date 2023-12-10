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
brain is turned off when sleeping and resets all the variables, need to save important trackers to mob itself so that bunker can occur on wake if triggered prior.
--]]
UseShield_Forge = Class(BehaviourNode, function(self, inst, damage_for_shield, shield_time, cooldown_time, hide_from_heals, hide_from_projectiles, hide_when_scared)
    BehaviourNode._ctor(self, "UseShield_Forge")
    self.inst = inst
    self.damage_for_shield = damage_for_shield or 100
    self.hide_from_projectiles = hide_from_projectiles or false
    self.scare_end_time = 0
    self.damage_taken = 0
    self.time_last_attacked = 1
    self.shield_time = shield_time or 2
	self.shield_start_time = 0
    self.projectile_incoming = false
	self.hide_from_heals = hide_from_heals or false
	self.hit_in_heal = false
	self.shield_ready = false
	self.cooldown_time = cooldown_time or 10

    if hide_when_scared then
        self.onepicscarefn = function(inst, data) self.scare_end_time = math.max(self.scare_end_time, data.duration + GetTime() + math.random()) end
        self.inst:ListenForEvent("epicscare", self.onepicscarefn)
    end

	if not self.onattackedfn then -- TODO this can be used to differentiate boarilla and snortoise, not a parameter atm....what was this used for prior?
		self.onattackedfn = function(inst, data) self:OnAttacked(data.attacker, data.damage, data.weapon, data.stimuli) end
		self.onhostileprojectilefn = function() self:OnAttacked(nil, 0, true) end
	end
    self.onfiredamagefn = function() self:OnAttacked() end

    self.inst:ListenForEvent("attacked", self.onattackedfn)
    self.inst:ListenForEvent("hostileprojectile", self.onhostileprojectilefn)
    self.inst:ListenForEvent("firedamage", self.onfiredamagefn)
    self.inst:ListenForEvent("startfiredamage", self.onfiredamagefn)
end)

function UseShield_Forge:OnStop()
    if self.onepicscarefn ~= nil then
        self.inst:RemoveEventCallback("epicscare", self.onepicscarefn)
    end
    self.inst:RemoveEventCallback("attacked", self.onattackedfn)
    self.inst:RemoveEventCallback("hostileprojectile", self.onhostileprojectilefn)
    self.inst:RemoveEventCallback("firedamage", self.onfiredamagefn)
    self.inst:RemoveEventCallback("startfiredamage", self.onfiredamagefn)
end

function UseShield_Forge:TimeToEmerge() -- TODO hide_from_heals???????
    local t = GetTime()
	return t - self.shield_start_time >= self.shield_time -- Shield duration
		and t >= self.scare_end_time -- Scared duration
		and (not self.inst:HasTag("_isinheals") or self.inst:HasTag("_isinheals") and self.hit_in_heal) -- Heal check TODO change this to involve sleep???
    --return t - self.time_last_attacked > self.shield_time
      --  and t >= self.scare_end_time and (not self.inst:HasTag("_isinheals") or self.inst:HasTag("_isinheals") and self.hit_in_heal)
		--         and t >= self.scare_end_time and ((self.hide_from_heals and not self.inst:HasTag("_isinheals")) and (self.inst.components.sleeper and self.inst.components.sleeper.sleepiness < 1) or not self.hide_from_heals)

end

function UseShield_Forge:ShouldShield() -- TODO might want to separate into 2 shield methods to bypass cooldown? If scared should cooldown be ignored? same with the other shield req here except damage of course?
    return not self.inst.components.health:IsDead() and not self.inst.sg:HasStateTag("busy") and self.shield_ready and (self.damage_taken >= self.damage_for_shield -- Damage criteria met
		or self.projectile_incoming -- Hide from projectiles
		or GetTime() < self.scare_end_time -- Hide when scared
		or self.inst.components.health.takingfiredamage) -- Hide when on fire TODO should we include this?
end

function UseShield_Forge:OnAttacked(attacker, damage, projectile, stimuli) -- TODO need another check to push shield for being scared, taking fire damage, or hiding from projectiles. Right now only does shield if hit at the right time.
    if not self.inst.sg:HasStateTag("frozen") then
		-- TODO only goes into shield on hit
		if not (self.inst.sg:HasStateTag("hiding") or self.inst.sg:HasStateTag("hide_pre")) then
			-- Attempt to shield
			if not (TUNING.FORGE.FORCED_HIT_STIMULI[stimuli] or TUNING.FORGE.STUN_STIMULI[stimuli]) and self:ShouldShield() then
				self.inst:PushEvent("entershield")
			else
				-- Start shield cooldown on first hit after being in shield. TODO check to see if snortoise follows this same pattern. 2 man vids will probably show the pattern.
				if not self.shield_ready and not self.cooldown_timer then
					self.cooldown_timer = self.inst:DoTaskInTime(self.cooldown_time, function(inst)
						self.shield_ready = true
						self.cooldown_timer = nil
					end)
				end

				-- Update damage
				if damage then
					self.damage_taken = self.damage_taken + damage
				end

				-- Hide from projectile
				if projectile and self.hide_from_projectiles then
					self.projectile_incoming = true
				end
			end
		else
			-- TODO understand this heal check
			if self.inst.sg:HasStateTag("hiding") and self.inst:HasTag("_isinheals") and ((GetTime() - self.time_last_attacked) > self.shield_time) then
				self.hit_in_heal = true
			end
		end
    end
end

function UseShield_Forge:Visit()
    local combat = self.inst.components.combat
    local statename = self.inst.sg.currentstate.name

    if self.status == READY then
        if self:ShouldShield() and false then -- TODO need to implement this check for shield triggers that do not require a hit to activate
		elseif self.inst.sg:HasStateTag("hiding") or self.inst.sg:HasStateTag("hide_pre") then -- TODO might need to reset values onexit and not here or use common local function and do it in both places.
            self.damage_taken = 0
            self.projectile_incoming = false
			self.time_last_attacked = GetTime()
			self.shield_start_time = GetTime() -- TODO this the right spot???
			self.shield_ready = false -- TODO this might need to be attached to the mob because when the mob sleeps he resets this. Need to find vids of mobs waking up and bunkering shortly after
            self.status = RUNNING
        else -- TODO what exactly does failed do, this will fail constantly until shouldshield returns true, so why not just stay ready???
            self.status = FAILED
        end
    end

    if self.status == RUNNING then
		-- Success if time to emerge and not attacking or if forced out of shield
		if self:TimeToEmerge() and not self.inst.sg:HasStateTag("attack") or not (self.inst.sg:HasStateTag("hiding") or self.inst.sg:HasStateTag("hide_pre")) then
			-- Only exit shield if still inside shield
			if self.inst.sg:HasStateTag("hiding") then
				self.inst:PushEvent("exitshield") -- TODO can this fail and the mob not get out of shield? ready would see that the mob is still hiding and come right back here, so I guess it would fix itself, is this good?
			end
            self.status = SUCCESS
		end
    end
end
