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
local tuning_values = TUNING.FORGE.LAVAARENA_CHEFHAT
--------------------------------------------------------------------------
local hat_values = {
    cover_head = true
}
--------------------------------------------------------------------------
local function fn()
    local inst = COMMON_FNS.EQUIPMENT.HelmInit("lavaarena_chefhat", nil, "anim", nil, nil, nil, hat_values, tuning_values)
    ------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
	inst.components.inventoryitem.atlasname = "images/reforged.xml"
	--inst.components.inventoryitem.imagename = "lavaarena_"..name.."hat"
	inst.components.itemtype:SetType("cooldown_hats") --TODO: maybe make this cookhats?
    ------------------------------------------
	
    inst.components.equippable:AddUniqueBuff({
	{name = "chef_mastery", val = 1, type = "flat"},
	{name = "cooldown", val = TUNING.FORGE.LAVAARENA_CHEFHAT.BONUS_COOLDOWNRATE, type = "add"}
	})

    ------------------------------------------
	return inst
end

--------------------------------------------------------------------------
return ForgePrefab("lavaarena_chefhat", fn, assets, nil, nil, tuning_values.ENTITY_TYPE, nil, "images/reforged.xml", "lavaarena_chefhat.tex", "lavaarena_chefhat", "common_head1")