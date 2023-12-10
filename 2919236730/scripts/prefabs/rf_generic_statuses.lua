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
local assets = {
	Asset("ANIM", "anim/rf_generic_fossilized.zip"),
	Asset("ANIM", "anim/rf_generic_frozen.zip"),
	Asset("ANIM", "anim/rf_generic_frozen_med.zip"),
}

------------------------------------------------------------------------------
local function MakeGenericFx(name, data)
    local function fn()
        local inst = COMMON_FNS.BasicEntityInit(data.bank, data.build, data.anim, {anim_loop = false, pristine_fn = function(inst)
            inst.entity:AddSoundEmitter()
    		------------------------------------------
    		if data.scale then
    			inst.AnimState:SetScale(data.scale, data.scale)
    		end
            ------------------------------------------
            COMMON_FNS.AddTags(inst, "FX", "NOCLICK")
        end})
		------------------------------------------
        if not TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------
        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

return MakeGenericFx("rf_generic_fossilized", {bank = "rf_generic_fossilized", build = "fossilized", anim = "fossilized"}),
MakeGenericFx("rf_generic_frozen_med", {bank = "rf_generic_frozen", build = "rf_generic_frozen_med", anim = "frozen"}),
MakeGenericFx("rf_generic_frozen_small", {bank = "rf_generic_frozen", build = "rf_generic_frozen_med", anim = "frozen", scale = 0.5})
