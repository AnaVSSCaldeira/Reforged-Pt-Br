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

local DEFAULT_COLOUR = { 255 / 255, 80 / 255, 40 / 255, 1 }
local DAMAGE_TYPE_COLOURS = {
	physical = { 210 / 255, 105 / 255, 30 / 255, 1 },
	magical = { 255 / 255, 0 / 255, 255 / 255, 1 },
}
local STIMULI_COLOURS = {
	electric = { 255 / 255, 255 / 255, 0 / 255, 1 },
	explosive = { 255 / 255, 69 / 255, 0 / 255, 1 },
}
--[[
TODO
need to add checks for pet damage for options, currently pet damage does not show for all players if "all" is selected
color needs to be passed through damagedirty for "all"
--]]
local function PushDamageNumber(player, target, damage, damage_type, stimuli, large, colour)
	local font_size = REFORGED_SETTINGS.display.damage_number_font_size
	large = damage > 0 and large
    if REFORGED_SETTINGS.display.damage_numbers ~= "off" and not (REFORGED_SETTINGS.display.damage_numbers ~= "all" and player ~= ThePlayer or target:HasTag("player") and not REFORGED_SETTINGS.display.damage_numbers_players) then
		  player.HUD:ShowPopupNumber(damage, large and font_size*1.5 or font_size, target:GetPosition(), REFORGED_SETTINGS.display.damage_number_height, REFORGED_SETTINGS.display.damage_numbers == "all" and colour or REFORGED_SETTINGS.display.damage_numbers == "elemental" and (STIMULI_COLOURS[stimuli] or DAMAGE_TYPE_COLOURS[damage_type]) or DEFAULT_COLOUR, large)
	end
end

local function OnDamageDirty(inst)
    if inst.target:value() ~= nil then
        local player = inst.entity:GetParent()
        if player ~= nil and player.HUD ~= nil then
            PushDamageNumber(player, inst.target:value(), inst.damage:value(), inst.damage_type:value(), inst.stimuli:value(), inst.large:value())
        end
    end
end

local function master_postinit(inst)
	inst.UpdateDamageNumbers = function(self, player, target, damage, damage_type, stimuli, large)
		if player == ThePlayer then -- TODO this means client host wont show up on clients right? probably should change this always set the the damage variables
			self.PushDamageNumber(player, target, damage, damage_type, stimuli, large)
		else
			self.target:set_local(target)
			self.damage:set_local(damage)
			self.damage_type:set_local(damage_type or "none")
			self.stimuli:set_local(stimuli or "none")
			self.large:set_local(large or false)
		end
	end

	inst:DoTaskInTime(0.1, inst.Remove)
end

local function fn()
    local inst = CreateEntity()
    ------------------------------------------
    inst.entity:AddNetwork()
    ------------------------------------------
    inst.target = net_entity(inst.GUID, "damage_number.target")
    inst.damage = net_shortint(inst.GUID, "damage_number.damage")
	inst.damage_type = net_string(inst.GUID, "damage_number.damage_type")
	inst.stimuli = net_string(inst.GUID, "damage_number.stimuli")
    inst.large = net_bool(inst.GUID, "damage_number.large", "damagedirty")
    ------------------------------------------
    inst:AddTag("CLASSIFIED")
    ------------------------------------------
    inst.entity:SetPristine()
    ------------------------------------------
    if not TheWorld.ismastersim then
        inst:ListenForEvent("damagedirty", OnDamageDirty)
        return inst
    end
    ------------------------------------------
    inst.PushDamageNumber = PushDamageNumber
	master_postinit(inst)
    ------------------------------------------
    return inst
end

return Prefab("damage_number", fn)
