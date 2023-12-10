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
local assets = {
    Asset("ANIM", "anim/lavaarena_boaron_basic.zip"),
}
local prefabs = {}
local tuning_values = TUNING.FORGE.PITPIG
local sound_path = "dontstarve/creatures/lava_arena/boaron/"
local satz = 2.5
local dupe_symbols = {"helmet", "strap"}
local dupe_colors = {
	{hue = 0.18, sat = satz}, --red
	
	{hue = 0.7, sat = satz}, --blue
	{hue = 0.4, sat = satz}, --green
	{hue = 0.625, sat = satz}, --cyan
	{hue = 0, sat = satz}, --pink
}
--------------------------------------------------------------------------
-- Attack Functions
--------------------------------------------------------------------------
local function OnDashCooldownComplete(inst)
	inst.components.combat:SetRange(tuning_values.DASH_RANGE) --, tuning_values.HIT_RANGE TODO does this need hit range?
end
--------------------------------------------------------------------------
-- Physics Functions
--------------------------------------------------------------------------
local physics = {
	scale  = 0.8,
	mass   = 50,
	radius = 0.5,
	shadow = {1.75,0.75},
}
local function PhysicsInit(inst)
	MakeCharacterPhysics(inst, physics.mass, physics.radius)
    inst.DynamicShadow:SetSize(unpack(physics.shadow))
    local scale = physics.scale
	inst.Transform:SetScale(scale,scale,scale)
    inst.Transform:SetSixFaced()
end
--------------------------------------------------------------------------
local mob_values = {
	name_override   = "boaron",
	physics         = physics,
	physics_init_fn = PhysicsInit,
	stategraph      = "SGpitpig",
	brain           = require("brains/boaronbrain"),
	sounds = {
		taunt    = sound_path .. "taunt",
		hit      = sound_path .. "hit",
		stun     = sound_path .. "stun",
		attack_1 = sound_path .. "attack_1",
		attack_2 = sound_path .. "attack_2",
		death    = sound_path .. "death",
		sleep    = sound_path .. "sleep",
	},
}
--------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.CommonMobFN("boaron", "lavaarena_boaron_basic", mob_values, tuning_values)
	------------------------------------------
	if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
	COMMON_FNS.AddSymbolFollowers(inst, "helmet", nil, "medium", {symbol = "bod"}, {symbol = "bod"})
	------------------------------------------
	inst.components.combat:AddAttack("dash", true, tuning_values.DASH_CD, OnDashCooldownComplete)
	inst.components.combat:SetRange(tuning_values.DASH_RANGE, tuning_values.HIT_RANGE)
	------------------------------------------
	return inst
end

return ForgePrefab("pitpig", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/reforged.xml", "pitpig_icon.tex")
