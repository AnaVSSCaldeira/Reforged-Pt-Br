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

local AOESpell = Class(function(self, inst)
    self.inst = inst
	self.casting = false
	self.spell_types = {}
	self.is_spell = false
	self.aoe_cast = nil
end)

function AOESpell:SetAOESpell(fn)
	self.aoe_cast = fn
end

function AOESpell:CanCast(caster, pos)
	return self.inst.components.aoetargeting ~= nil and self.inst.components.aoetargeting.alwaysvalid or
		(TheWorld.Map:IsPassableAtPoint(pos:Get()) and not TheWorld.Map:IsGroundTargetBlocked(pos) and TheWorld.Map:IsAboveGroundAtPoint(pos:Get()))
end

function AOESpell:CastSpell(caster, pos, options)
	self.casting = true
	if self.aoe_cast ~= nil then
		self.aoe_cast(self.inst, caster, pos, options)
	end

	self.inst:PushEvent("aoe_casted", {caster = caster, pos = pos})
end

function AOESpell:SetSpellTypes(spell_types)
	for _,spell_type in pairs(spell_types) do
		self.spell_types[spell_type] = true
		self.is_spell = true
	end
end

-- TODO better way?
--[[
spell_types - need to add this so we can distinguish attack spells from utility/status effect spells
	damage
	summon
	status?
		heal
		cc?
]]
function AOESpell:OnSpellCast(caster, targets, projectiles)
	self.casting = false
	caster:PushEvent("spell_complete", {weapon = self.inst, is_spell = self.is_spell, spell_types = self.spell_types, targets = targets, projectiles = projectiles})
end

return AOESpell
