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

local FRAME = 1/1000

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    --[[Non-networked entity]]
    ------------------------------------------
    inst:AddTag("CLASSIFIED")
    ------------------------------------------
	inst.blooms = {}
	inst.caster = nil
	------------------------------------------
	inst:AddComponent("heal_aura")
    --MakeLargeBurnable(inst, 5) -- TODO change fx have large in mid, surrounded by medium and then outside is small
	MakeLargeBurnableCharacter(inst)
    --MakeLargePropagator(inst)
    ------------------------------------------
	inst:DoTaskInTime(TUNING.FORGE.LIVINGSTAFF.DURATION, function(inst)
		for _,v in pairs(inst.blooms) do
			if v.Kill ~= nil then v:Kill(true) end
		end
		inst:Remove()
	end)
	------------------------------------------
	function inst:SpawnBlooms()
		local center = inst:GetPosition()
		local inner_blooms = 5
		local outer_blooms = 9
		local max_blooms = 1 + inner_blooms + outer_blooms
		for i = 1,max_blooms do
			local pt = inst:GetPosition()
			-- Inner and Outer Bloom Offset
			if i > 1 then
				local theta = (i > (1 + inner_blooms) and (i-inner_blooms)/outer_blooms or (i-1)/inner_blooms) * 2 * PI
				local radius = inst.components.heal_aura.range/(i > (1 + inner_blooms) and 1 or 2)
				local offset = FindWalkableOffset(pt, theta, radius, 2, true, true)
				if offset then
					pt = pt + offset
				else
					pt = nil
				end
			end
			if pt then
				inst:DoTaskInTime(math.random(), function()
					local bloom = COMMON_FNS.CreateFX("healingcircle_bloom", nil, inst.caster)
					bloom.Transform:SetPosition(pt:Get())
					bloom.buffed = inst.buffed
					bloom.heal_rate = inst.components.heal_aura.heal_rate
					table.insert(inst.blooms, bloom)
				end)
			end
		end
        --inst.components.burnable:Ignite()
	end
	------------------------------------------
	function inst:SpawnCenter()
		local pt = inst:GetPosition()
		local center = COMMON_FNS.CreateFX("healingcircle_center", nil, inst.caster)
		center.Transform:SetPosition(pt.x, 0, pt.z)
		center:DoTaskInTime(TUNING.FORGE.LIVINGSTAFF.COOLDOWN/2, inst.Remove)
	end
	------------------------------------------
	inst:DoTaskInTime(0, inst.SpawnCenter)
	inst:DoTaskInTime(0, inst.SpawnBlooms)
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
local FADEIN_TIME = 13 * FRAMES
local FADEOUT_TIME = 44 * FRAMES - FADEIN_TIME
local CLR = {0, 0.8, 0.55, 1}

local function PlayFlowerSound(inst)
	inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_lichen", "flower_summon")
    inst.SoundEmitter:SetVolume("flower_summon", .75)

    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/flowergrow", "flower_grow")
    inst.SoundEmitter:SetVolume("flower_grow", .65)

    inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds", "flower_sound")
    inst.SoundEmitter:SetVolume("flower_sound", .55)
	--inst.SoundEmitter:SetVolume("flower_sound", .25) --TODO: Leo - might need a volume check, leaving this comment here for reference of what it was before.
end

local function Start(inst)
	PlayFlowerSound(inst)

	inst.AnimState:PlayAnimation("in_"..inst.variation)
	inst.AnimState:PushAnimation("idle_"..inst.variation)

	if inst.buffed then
		inst.components.scaler:SetBaseScale(1 + (math.random(unpack(TUNING.FORGE.LIVINGSTAFF.SCALE_RNG)) + math.random())/100)
		inst.components.scaler:ApplyScale()
		--inst.AnimState:ShowSymbol("drop")
	end

	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	DoColourBlooming(inst, FADEIN_TIME, FADEOUT_TIME, CLR, false, nil, function(inst)
		inst.AnimState:ClearBloomEffectHandle()
	end)
end

local function Kill(inst, withdelay)
	local function fn(inst)
		PlayFlowerSound(inst)

		inst.AnimState:PushAnimation("out_"..inst.variation, false)
		inst:ListenForEvent("animover", inst.Remove)
	end

	local delay = withdelay and math.random() or 0
	if delay > 0 then
		inst:DoTaskInTime(delay, fn)
	else
		fn(inst)
	end
end
--------------------------------------------------------------------------
local function bloom_fn()
	local inst = COMMON_FNS.FXEntityInit("lavaarena_heal_flowers", "lavaarena_heal_flowers_fx", nil, {noanimover = true, noanim = true, pristine_fn = function(inst)
	    inst.entity:AddSoundEmitter()
		--inst.AnimState:HideSymbol("drop")
	end})
	------------------------------------------
	if not TheWorld.ismastersim then
		return inst
	end
	------------------------------------------
	inst.variation = tostring(math.random(1, 6))
	------------------------------------------
	inst:AddComponent("colouradder")
	------------------------------------------
	inst.Start  = Start
	inst.Kill   = Kill
	inst.OnSave = inst.Remove
	------------------------------------------
	inst:DoTaskInTime(0, inst.Start)
	------------------------------------------
	return inst
end
--------------------------------------------------------------------------
local function center_fn()
	local inst = COMMON_FNS.FXEntityInit("lavaarena_heal_flowers", "lavaarena_heal_flowers_fx", nil, {noanimover = true, noanim = true, pristine_fn = function(inst)
		inst.AnimState:SetMultColour(0,0,0,0)
		--inst:Hide()
		------------------------------------------
		inst:AddTag("healingcircle")
	end})
	------------------------------------------
	if not TheWorld.ismastersim then
		return inst
	end
	------------------------------------------
	inst.variation = tostring(math.random(1, 6))
	inst.AnimState:PlayAnimation("in_"..inst.variation)
	inst.AnimState:PushAnimation("idle_"..inst.variation)
	------------------------------------------
	inst:DoTaskInTime(12, inst.Remove)
	------------------------------------------
	return inst
end
--------------------------------------------------------------------------
return Prefab("healingcircle", fn, nil, prefabs),
	Prefab("healingcircle_bloom", bloom_fn, nil, nil),
	Prefab("healingcircle_center", center_fn, nil, nil)
