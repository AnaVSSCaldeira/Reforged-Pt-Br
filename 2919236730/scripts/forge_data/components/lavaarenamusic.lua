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

local function SetDirty(netvar, val)
	netvar:set_local(val)
	netvar:set(val)
end
local function MasterPostInit(self, inst, netvars)
	function self:StartMusic()
		netvars.level:set(1)
	end
	function self:StopMusic()
		netvars.level:set(0)
	end
	TheWorld:ListenForEvent("ms_playerjoined", function()
		self:StartMusic()
	end)
	
	TheWorld:ListenForEvent("stop_lavaarena_music", function()
		self:StopMusic()
	end)
end

return {
	master_postinit = MasterPostInit
}
