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
local assets = {}
local prefabs = {}
local tuning_values = TUNING.FORGE.COOKPOT
------------------------------------------------------------------------------
local DEFENSE_DEBUFF = 1.3
local function OnAttached(inst, target)
    if target.components.combat and not target.components.combat:HasDamageBuff("haunt_debuff", true) then
        target.components.combat:AddDamageBuff("haunt_debuff", {buff = DEFENSE_DEBUFF}, true)
    end
    if not target:HasTag("haunted") then
        target:AddTag("haunted")
    end
    target.AnimState:SetHaunted(true)
    inst.haunt_debuff_timer = inst:DoTaskInTime(5, function(inst)
        inst.components.debuff:Stop()
        inst.haunt_debuff_timer = nil
    end)
end

local function OnExtended(inst, target)
    RemoveTask(inst.haunt_debuff_timer)
    inst.haunt_debuff_timer = inst:DoTaskInTime(5, function(inst)
        inst.components.debuff:Stop()
        inst.haunt_debuff_timer = nil
    end)
end

local function OnDetached(inst, target)
    if target:IsValid() then
        if target.components.combat then
            target.components.combat:RemoveDamageBuff("haunt_debuff", true)
        end
        target:RemoveTag("haunted")
        target.AnimState:SetHaunted(false)
    end
    RemoveTask(inst.haunt_debuff_timer)
	inst:Remove()
end
------------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.BasicEntityInit(nil, nil, nil, {anim_loop = false})
	------------------------------------------
	if not TheWorld.ismastersim then
		return inst
	end
    ------------------------------------------
	inst:AddComponent("debuff")
	inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetExtendedFn(OnExtended)
	inst.components.debuff:SetDetachedFn(OnDetached)
    ------------------------------------------
	return inst
end
------------------------------------------------------------------------------
return Prefab("debuff_haunt", fn, assets, prefabs)
