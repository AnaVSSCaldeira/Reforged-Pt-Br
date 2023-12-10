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
    Asset("ANIM", "anim/lavaarena_hit_sparks_fx.zip"),
}
--------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.FXEntityInit("hits_sparks", "lavaarena_hit_sparks_fx", nil, {noanimover = true, pristine_fn = function(inst)
		inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
		inst.AnimState:SetFinalOffset(1)
	end})
	------------------------------------------
	if not TheWorld.ismastersim then
		return inst
	end
	------------------------------------------
	inst.SetPosition = function(inst, player, target) -- For melee weapons
		local offset = (player:GetPosition() - target:GetPosition()):GetNormalized()*(target.Physics and target.Physics:GetRadius() or 1)
		offset.y = offset.y + 1 + math.random(-5, 5)/10
		inst.Transform:SetPosition((target:GetPosition() + offset):Get())
		inst.AnimState:PlayAnimation("hit_3")
		inst.AnimState:SetScale(player:GetRotation() > 0 and -.7 or .7,.7)
	end
	------------------------------------------
	inst.SetPiercing = function(inst, source, target) -- For projectile weapons
		local offset = (source:GetPosition() - target:GetPosition()):GetNormalized()*(target.Physics and target.Physics:GetRadius() or 1)
		offset.y = offset.y + 1 + math.random(-5, 5)/10
		inst.Transform:SetPosition((target:GetPosition() + offset):Get())
		inst.AnimState:PlayAnimation("hit_3")
		inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
		inst.Transform:SetRotation(inst:GetAngleToPoint(target:GetPosition():Get()) + 90)
	end
	------------------------------------------
	inst.SetThrusting = function(inst, target, offset) -- For Maxwell's shadow puppets
		inst.Transform:SetPosition((target:GetPosition() + offset):Get())
		inst.AnimState:PlayAnimation("hit_3")
		inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
		inst.Transform:SetRotation(inst:GetAngleToPoint(target:GetPosition():Get()) + 90)
	end
	------------------------------------------
	inst.SetBounce = function(inst, owner) -- For missing with Lucy
		inst.Transform:SetPosition(owner:GetPosition():Get())
		inst.AnimState:PlayAnimation("hit_2")
		inst.AnimState:Hide("glow")
		inst.AnimState:SetScale(owner:GetRotation() > 0 and 1 or -1, 1)
	end
	------------------------------------------
	return inst
end
--------------------------------------------------------------------------
return Prefab("weaponsparks_fx", fn, assets)
