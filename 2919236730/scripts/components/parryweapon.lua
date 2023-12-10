--[[
Copyright (C) 2019 Forged Forge

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

local ParryWeapon = Class(function(self, inst)
    self.inst = inst
    self.onparrystart = nil
    self.duration = 2
    self.max_angle_diff = 70

    --Zarklord: V2C: Recommended to explicitly add tag to prefab pristine state
    inst:AddTag("parryweapon")
end)

function ParryWeapon:SetOnParryStartFn(fn)
    self.onparrystart = fn
end

function ParryWeapon:SetOnParrySuccessFn(fn)
    self.onparrysuccess = fn
end

function ParryWeapon:SetOnParryFailFn(fn)
    self.onparryfail = fn
end

function ParryWeapon:OnPreParry(player)
    if player.sg then
        player.sg:PushEvent("start_parry")
    end
    if self.onparrystart then
        self.onparrystart(self.inst, player)
    end
end

function ParryWeapon:TryParry(player, target, damage, weapon, stimuli)
    if player.sg then
        player.sg:PushEvent("try_parry")
    end
    if self.ontryparry then
        return self.ontryparry(player, target, damage, weapon, stimuli)
    end
    local ent = target or weapon
    if ent == nil then return false end
    local player_rot = player.Transform:GetRotation()
    local target_angle = player:GetAngleToPoint(ent.Transform:GetWorldPosition())
    local angle_diff = player_rot - target_angle
    local smallest_angle = math.abs(angle_diff + (angle_diff > 180 and -360 or angle_diff < -180 and 360 or 0))
    local weapon = ent.components.combat and ent.components.combat:GetWeapon()
    local damagetype = ent.components.weapon and ent.components.weapon.damagetype or weapon and weapon.components.weapon and weapon.components.weapon.damagetype or ent.components.combat and ent.components.combat.damagetype
    local parry_success = smallest_angle <= self.max_angle_diff and damagetype == TUNING.FORGE.DAMAGETYPES.PHYSICAL
    if parry_success and self.onparrysuccess then
        self.onparrysuccess(self.inst, player, target, damage, weapon, stimuli)
    elseif self.onparryfail then
        self.onparryfail(self.inst, player, target, damage, weapon, stimuli)
    end
    return parry_success
end

return ParryWeapon
