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
    local self = inst.components.timelockable

    if self:IsTimeLocked() then
        inst:PushEvent("time_unlock")
        if TheWorld and TheWorld.components.stat_tracker then
            -- ...
            -- update stat: ccbroken
            if data.attacker then
                TheWorld.components.stat_tracker:AdjustStat("ccbroken", data.attacker, 1)
            end
        end
    end
end

local TimeLockable = Class(function(self, inst)
    self.inst = inst
    self.duration = 7
    self.start_time = nil
    self.last_caster = nil
    self.has_constant_duration = false

    --self.inst:ListenForEvent("attacked", OnAttacked)
end)

function TimeLockable:SetDuration(duration, constant_duration)
    self.has_constant_duration = constant_duration
    self.duration = duration or self.duration
end

function TimeLockable:GetDuration(caster)
    return self.duration
end

function TimeLockable:HasConstantDuration(caster)
    return self.has_constant_duration
end

function TimeLockable:OnSpawnFX()
    if self.inst.SoundEmitter then
        self.inst.SoundEmitter:PlaySound("dontstarve/common/lava_arena/spell/fossilized")
    end

    SpawnAt("pocketwatch_ground_fx", self.inst)
end

function TimeLockable:TimeLock(duration, caster)
    self.start_time = GetTime()
    self.last_caster = caster
    if self.time_lock_timer then
        self.time_lock_timer:Cancel()
        self.time_lock_timer = nil
    end
    self.time_lock_timer = self.inst:DoTaskInTime(duration, function(inst)
        self.inst:PushEvent("time_unlocked")
    end)

    -- TODO should it increase the stat if the same person is ccing before they are "uncc'd"
    UpdateNumCCStat(self)
end

function TimeLockable:OnTimeLock(duration, caster)
    self.inst:AddTag("time_locked")
    self:TimeLock(duration, caster)
end

function TimeLockable:OnTimeUnlock()
    self.inst:RemoveTag("time_locked")
    UpdateTimeCCStat(self)
    self.start_time = nil -- TODO is this needed?
    if self.time_lock_timer then
        self.time_lock_timer:Cancel()
        self.time_lock_timer = nil
    end
end

function TimeLockable:OnExtend(duration, caster)
    UpdateTimeCCStat(self)
    self:TimeLock(duration, caster)
end

function TimeLockable:IsTimeLocked()
    return self.inst:HasTag("time_locked")
end

function TimeLockable:GetDebugString()
    return string.format("status:%s, base_duration:%2.2f, last_caster:%s, (duration:%2.2f)", tostring(self:IsTimeLocked()), self.duration, tostring(self.last_caster), self.time_lock_timer and GetTaskRemaining(self.time_lock_timer) or 0)
end

return TimeLockable
