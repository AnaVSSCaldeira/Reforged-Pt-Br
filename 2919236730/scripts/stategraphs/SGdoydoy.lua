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
local TIMEOUT = function() return 1 + math.random() * 2 end

local states = {
    State{
        name = "idle",
        tags = {"idle"},
        onenter = function(inst)
			if not inst.AnimState:IsCurrentAnimation("idle") then
				inst.AnimState:PlayAnimation("idle", true)
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
			inst.AnimState:PlayAnimation("eat_pre", false)
			inst.AnimState:PushAnimation("eat", false)
			inst.AnimState:PushAnimation("eat_pst", false)
		end,
	
		timeline =
        {
            TimeEvent((700 + 1334 + 550)/1000, function(inst) inst.sg:GoToState("idle") end),
        },

        events =
		{
			EventHandler("animqueueover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
				end
			end),
		},
    },
	
	State{
        name = "cheer",
        tags = {"busy"},
		
		onenter = function(inst)
			inst.AnimState:PlayAnimation("mate_dance_pre", false)
			inst.AnimState:PushAnimation("mate_dance_loop", false)
			inst.AnimState:PushAnimation("mate_dance_pst", false)
		end,
	
		timeline =
        {
            TimeEvent((1034 + 2000 + 900)/1000, function(inst) inst.sg:GoToState("idle") end),
        },

        events =
		{
			EventHandler("animqueueover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
				end
			end),
		},
    },
	
	State{
        name = "boo",
        tags = {"busy"},
		
		onenter = function(inst)
			inst.AnimState:PlayAnimation("peck", false)
		end,
	
		events =
		{
			EventHandler("animover", function(inst) 
				inst.sg:GoToState("idle")
			end),
		},
    },
}

return StateGraph("spectator_doydoy", states, {}, "idle")

