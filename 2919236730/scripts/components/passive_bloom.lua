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
	While active and in a heal, that heal is buffed?
	Blooming has several states, need to make sure that over the duration of the activation time the states are slowly applied until bloomed and then reset if hit of course
		This might be hard to code for a generic character
			could have a boolean dictating if a custom build or something is being used
				use a custom function maybe?

	When hit decay over time to prior skins?

	Description
		Becomes Bloomed by not getting hit. While Bloomed movement speed is increased, plant summons grow stronger, and Pollen is released every 10 seconds decreasing nearby enemies attacks.
--]]
local skin_overrides = {
	[1] = "normal_skin",
	[2] = "stage_2",
	[3] = "stage_3",
	[4] = "stage_4",
}
--------------------------------------------------------------------------
local function BloomingTask(self)
	self.blooming_task = self.inst:DoTaskInTime(self.time_per_stage, function()
		if self.inst and not self.inst.components.health:IsDead() then
			self.blooming_task = nil
			self:SetCurrentStage(self.current_stage + 1)
		end
	end)
end

local function OnAttacked(inst, data)
	if inst.components.passive_bloom then
		inst.components.passive_bloom:OnAttacked()
	end
end

local function OnDeath(inst, data)
	if inst.components.passive_bloom then
		inst.components.passive_bloom:OnDeath()
	end
end

local function OnRevived(inst, data)
	if inst.components.passive_bloom then
		inst.components.passive_bloom:OnRevived()
	end
end

local function OnCurrentStage(self, current_stage)
	self.inst.replica.passive_bloom:SetCurrentStage(current_stage)
end

local function OnPollenDebuffDuration(self, duration)
	self.inst.replica.passive_bloom:SetPollenDebuffDuration(duration)
end
--------------------------------------------------------------------------
local PassiveBloom = Class(function(self, inst)
    self.inst = inst
	self.bloomed = false
	self.current_stage = 1
	self.skin_overrides = skin_overrides -- this dictates the amount of stages
	self.time_per_stage = 10
	self.decay_time_per_stage = 1
	self.pollen_period = 14
	self.pollen_range = 9
	self.pollen_attack_mult_debuff = 0.85
	self.pollen_debuff_duration = 12
	self.bloom_speed_mult = 1.2
	self.default_build = "wilson"

	self.inst:ListenForEvent("attacked", OnAttacked)
	self.inst:ListenForEvent("death", OnDeath)
	self.inst:ListenForEvent("respawnfromcorpse", OnRevived)

	BloomingTask(self)
end, nil, {
	current_stage = OnCurrentStage,
	pollen_debuff_duration = OnPollenDebuffDuration,
})

-- Resets Bloom on death
function PassiveBloom:OnDeath() -- TODO just use StopBloom instead if remains empty
	self:StopBloom() -- TODO anything else needed?
end

-- Check if Mighty should be triggered (players health is below the trigger) when attacked
function PassiveBloom:OnAttacked() -- TODO just use ResetBloom instead if remains empty
	self:ResetBloom()
end

-- TODO increase plant summon level somehow, and remove it correctly
-- TODO add some sort of fx to the source so it seems like they release pollen. Check spore bomb, could be used
function PassiveBloom:ApplyBloom()
	self.bloomed = true
	self.inst.components.locomotor:SetExternalSpeedMultiplier(self.inst, "passive_bloom", self.bloom_speed_mult)
	self.pollen_task = self.inst:DoPeriodicTask(self.pollen_period, function(inst)
		local target_pos = inst:GetPosition()
		local pollen_cloud = SpawnPrefab("pollen_cloud_fx").Transform:SetPosition(target_pos:Get())
		local ents = TheSim:FindEntities(target_pos.x, 0, target_pos.z, self.pollen_range, {"locomotor"}, COMMON_FNS.CommonExcludeTags(inst))
		for _,ent in pairs(ents) do
			local debuffable = ent.components.debuffable
			if inst.components.combat:IsValidTarget(ent) and debuffable then
		        debuffable:AddDebuff("debuff_pollen", "debuff_pollen")
		        local debuff_pollen = debuffable:GetDebuff("debuff_pollen")
		        if debuff_pollen then
		        	debuff_pollen.source = self.inst
		        	debuff_pollen.duration = self.pollen_debuff_duration
		        	debuff_pollen.attack_mult_debuff = self.pollen_attack_mult_debuff
		        end
			end
		end
	end)
end

function PassiveBloom:ResetBloom()
	self:StopBloom()
	self:SetCurrentStage(1)
end

-- Removes Bloom and prevents Bloom from restarting.
function PassiveBloom:StopBloom()
	RemoveTask(self.pollen_task)
	RemoveTask(self.blooming_task)
	self.bloomed = false
	self.inst.components.locomotor:RemoveExternalSpeedMultiplier(self.inst, "passive_bloom")
end

function PassiveBloom:OnRevived()
	self:ResetBloom()
end

function PassiveBloom:SetCurrentStage(val)
	self.current_stage = val
	self.inst.components.skinner:SetSkinMode(self.skin_overrides[self.current_stage], self.default_build)
	COMMON_FNS.CreateFX("bloom_fx", self.inst)
	if self.current_stage >= #self.skin_overrides then
		self:ApplyBloom()
	else
		BloomingTask(self)
	end
end

function PassiveBloom:SetTimePerStage(val)
	self.time_per_stage = val
end

-- Value given must be a table of strings that represent the desired skin
function PassiveBloom:SetSkinOverrides(val)
	self.skin_overrides = val
end

function PassiveBloom:SetDecayTimePerStage(val)
	self.decay_time_per_stage = val
end

function PassiveBloom:SetPollenPeriod(val)
	self.pollen_period = val
end

function PassiveBloom:SetPollenRange(val)
	self.pollen_range = val
end

function PassiveBloom:SetPollenAttackMultDebuff(val)
	self.pollen_attack_mult_debuff = val
end

function PassiveBloom:SetPollenDebuffDuration(val)
	self.pollen_debuff_duration = val
end

function PassiveBloom:SetBloomSpeedMult(val)
	self.bloom_speed_mult = val
end

function PassiveBloom:SetDefaultBuild(val)
	self.default_build = val
end

function PassiveBloom:OnRemoveFromEntity()
	self.inst:RemoveEventCallback("attacked", OnAttacked)
	self.inst:RemoveEventCallback("death", OnDeath)
	self.inst:RemoveEventCallback("respawnfromcorpse", OnRevived)
end

function PassiveBloom:GetDebugString()
    return string.format("Status: %s, Stage: %d, (activation time:%2.2f, pollen timer:%2.2f)", tostring(self.bloomed), self.current_stage, self.blooming_task and GetTaskRemaining(self.blooming_task) or 0, self.pollen_task and GetTaskRemaining(self.pollen_task) or 0)
end

return PassiveBloom
