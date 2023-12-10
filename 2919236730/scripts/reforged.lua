--[[
TODO
Blacksmiths Edge
    Perfect Parry
        If a parry occurs within x amount of frames before getting hit.
        Reflects the damage back to owner (half or full damage?) and decreases parry cooldown by 50%?
        Stimuli?
        Can cause hit state?
        This could possibly stop attacks?
Heal Aura
    Healing Flowers scale based on healing power instead of only 2 different fx scales.
--]]
local reforged_fns = {
    --[[
    TODO
    Haunting Debuff
        Any mob hit by Abigail gets this.
        Timer for remove, can be extended with more hits.
        Increase damage dealt to the mob by 50%????
        Use the same visuals as base game for haunting?
    --]]
    forge_abigail = function(inst)
        ------------------------------------------
        if not _G.TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------
    end,
    --[[
    TODO
    Passive
        instead of shadows come and do one attack, after doing enough damage a shadow joins the fight (mimicking what maxwell was doing?) one hit to kill, can have a max of 3 out? pet armor buffs them?
        different types of shadows? cycle through spawning order
    --]]
    waxwell = function(inst)
        ------------------------------------------
        if not _G.TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------
    end,
    --[[
    TODO
    Balloons - starting weapon?
        Helium tank? (skins)
        Balloon animal (skins)
        Alt: places balloon, aggros nearby enemies while active (like bernie dance, but bernie dance is odd see video in bernie section), on hit explodes and stuns nearby enemies, flys away after x amount of time?
    --]]
    wes = function(inst)
        ------------------------------------------
        if not _G.TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------
    end,
}

return reforged_fns
