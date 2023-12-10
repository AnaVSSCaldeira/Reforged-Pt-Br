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

local function PickRandomThing(choices)
	return choices[math.random(#choices)]
end

local EMOTES = {
	EAT = function() return math.random() < .5 and "eat_l" or "eat_r" end,
	CHEER = function() return PickRandomThing({"cheer", "cheer2", "cheer3"}) end,
	BOO = function() return "boo" end,
}

local TIMEOUT = function() return 1 + math.random() * 2 end

local states = {
    State{
        name = "idle",
        tags = {"idle"},
       onenter = function(inst)
			if not inst.AnimState:IsCurrentAnimation("idle_loop") then
				inst.AnimState:PlayAnimation("idle_loop", true)
			end
			inst.sg:SetTimeout(TIMEOUT())
        end,
		
		ontimeout = function(inst)
			local reaction = inst:GetReaction()
			if reaction then
				inst.sg:GoToState(reaction)
			else
				inst.sg:SetTimeout(TIMEOUT())
			end
		end,
    },
	
	State{
        name = "eat",
        tags = {"busy"},
		
		onenter = function(inst)
			inst.AnimState:PlayAnimation(EMOTES.EAT())
		end,
	
		events =
		{
			EventHandler("animover", function(inst) 
				inst.sg:GoToState("idle")
			end),
		},
    },
	
	State{
        name = "cheer",
        tags = {"busy"},
		
		onenter = function(inst)
			inst.AnimState:PlayAnimation(EMOTES.CHEER())
		end,
	
		events =
		{
			EventHandler("animover", function(inst) 
				inst.sg:GoToState("idle")
			end),
		},
    },
	
	State{
        name = "boo",
        tags = {"busy"},
		
		onenter = function(inst)
			inst.AnimState:PlayAnimation(EMOTES.BOO())
		end,
	
		events =
		{
			EventHandler("animover", function(inst) 
				inst.sg:GoToState("idle")
			end),
		},
    },
}

return StateGraph("lavaarena_spectator", states, {}, "idle")

