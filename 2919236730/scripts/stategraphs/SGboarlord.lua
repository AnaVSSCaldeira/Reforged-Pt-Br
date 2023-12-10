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
require("stategraphs/commonforgestates")
local events = {
	CommonForgeHandlers.OnTalk(),
    EventHandler("player_died", function(inst)
		inst.sg:GoToState(math.random() < .25 and "laugh2" or "laugh_pre")
	end),
}

local states = {
    State{
        name = "idle",
        tags = {"idle"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("idle", true)
        end,
    },
	
	State{
        name = "laugh_pre",
        tags = {"busy"},
		
		onenter = function(inst)
			inst.AnimState:PlayAnimation("laugh_pre")
		end,
	
		events = {
			EventHandler("animover", function(inst) 
				inst.sg:GoToState("laugh_loop")
			end),
		},
    },
	
	State{
        name = "laugh_loop",
        tags = {"busy"},
		
		onenter = function(inst)
			inst.sg.statemem.laughed_times = 1
			inst.AnimState:PlayAnimation("laugh_loop")
		end,
		
		onexit = function(inst)
			inst.sg.statemem.laughed_times = 0
		end,
	
		events = {
			EventHandler("animover", function(inst)
				if inst.sg.statemem.laughed_times >= 3 then
					inst.sg:GoToState("laugh_pst")
				else
					inst.sg.statemem.laughed_times = inst.sg.statemem.laughed_times + 1
					inst.AnimState:PlayAnimation("laugh_loop")
				end
			end),
		},
    },
	
	State{
        name = "laugh_pst",
        tags = {"idle"},
		
		onenter = function(inst)
			inst.AnimState:PlayAnimation("laugh_pst")
		end,
	
		events = {
			EventHandler("animover", function(inst) 
				inst.sg:GoToState("idle")
			end),
		},
    },
	
	State{
        name = "sleep_pre",
        tags = {"busy"},
		
		onenter = function(inst)
			inst.AnimState:PlayAnimation("sleep_pre")
		end,
	
		events = {
			EventHandler("animover", function(inst) 
				inst.sg.statemem.laughed_times = 0
				inst.sg:GoToState("sleep_loop")
			end),
		},
    },
	
	State{
        name = "sleep_loop",
        tags = {"busy"},
		
		onenter = function(inst)
			inst.AnimState:PlayAnimation("sleep_loop", true)
		end,
		
		events = {
			--EventHandler("animover", function(inst) inst.sg:GoToState() end),
		},
    },
	
	State{
        name = "sleep_pst",
        tags = {"idle"},
		
		onenter = function(inst)
			inst.AnimState:PlayAnimation("sleep_pst")
		end,
	
		events = {
			EventHandler("animover", function(inst) 
				inst.sg:GoToState("idle")
			end),
		},
    },
	
	State{
        name = "laugh2",
        tags = {"busy"},
		
		onenter = function(inst)
			inst.AnimState:PlayAnimation("laugh2")
		end,

		events = {
            EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),--animqueueover
        },
    },
}

CommonForgeStates.AddTalkStates(states, {},{
	hideloop = "hide_idle",
},{
    talk = "dontstarve/characters/lava_arena/pugna/talk_LP",
})

return StateGraph("boarlord", states, events, "idle")