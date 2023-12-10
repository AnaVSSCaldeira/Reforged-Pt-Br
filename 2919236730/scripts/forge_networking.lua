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

local function OnBuffsDirty(inst)
	if not inst._parent or not inst._parent.HUD then
		return
	end
	--[[
	local buff_base = inst._parent.HUD.controls.buff_base
	local data = json.decode(inst.net_buffs:value())
	
	if data.removed then
		buff_base:RemoveBuff(data.name)
	else
		buff_base:PushBuff(data.name)
	end--]]
end

local function net_player(inst)
	inst.net_buffs = net_string(inst.GUID, "forge.net_buffs", "net_buffs_dirty")
	
	if not TheNet:IsDedicated() then
		local listeners = {
			net_buffs_dirty = OnBuffsDirty,
		}
		
		for event, fn in pairs(listeners) do
			inst:ListenForEvent(event, fn)
		end
	end
end

local function net_inventoryitem(inst)
	inst.isaltattacking = net_bool(inst.GUID, "weapon.isaltattacking")
	inst.altattackrange = net_float(inst.GUID, "weapon.altattackrange")
end

return {
	player = net_player,
	inventoryitem = net_inventoryitem,
}
