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

local tuning_values = TUNING.FORGE.BATTLESTANDARD
------------------------------------------------------------------------------
local function OnDeath(inst)
    inst.AnimState:PlayAnimation("break")
	inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/banner_break")
	inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + 2 * FRAMES, function(inst) inst:Remove() end)
end

local function OnHit(inst)
	if not inst.components.health:IsDead() then
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle", true)
    	inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_wood_armour_sharp")
	end
end


local function ShouldTrack(inst, viewer)
    return inst:IsValid() and not inst:IsNear(viewer, tuning_values.MIN_INDICATOR_RANGE) and CanEntitySeeTarget(viewer, inst)
end
------------------------------------------------------------------------------
local function MakePingBanner(name, build)
    local assets = {}

    local function fn()
        local inst = COMMON_FNS.BasicEntityInit("lavaarena_battlestandard", build, "place", {anim_loop = false, pristine_fn = function(inst)
            inst.entity:AddSoundEmitter()
            ------------------------------------------
    		inst.AnimState:PushAnimation("active", true)
    		inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/banner")
            ------------------------------------------
            COMMON_FNS.AddTags(inst, "structure", "ping", "NOCLICK")
            ------------------------------------------
            inst.nameoverride = "lavaarena_battlestandard"
            ------------------------------------------
    		local t1 = REFORGED_SETTINGS.display.ping_transparency and REFORGED_SETTINGS.display.ping_transparency/100 or 1
    		inst.AnimState:SetMultColour(1, 1, 1, 0.8)
            if not TheNet:IsDedicated() then
                inst:AddComponent("hudindicatable")
                inst.components.hudindicatable:SetShouldTrackFunction(ShouldTrack)
                -- NOTE: For some reason the component fails to call this even though it has an event for it.
                inst:ListenForEvent("onremove", function()
                    inst.components.hudindicatable:UnRegisterWithWorldComponent()
                end)
            end
        end})
		------------------------------------------
        if not TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------
		--ShakeAllCameras(CAMERASHAKE.FULL, .4, .03, .4, inst, 30)
        ------------------------------------------
		inst:DoTaskInTime(4, OnDeath)
        ------------------------------------------
        return inst
    end

    return ForgePrefab(name, fn, assets, prefabs, nil, "STRUCTURES", nil, "images/reforged.xml", name .. "_icon.tex")
end

return MakePingBanner("rf_ping_banner", "lavaarena_banner_ping_build")
