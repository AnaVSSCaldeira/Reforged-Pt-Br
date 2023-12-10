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
-- TODO Remove this file, but check if any functions should be saved.
_G.repeatprefab = function(prefab, count) 
    local tbl = {} 
    for i = 1, count do 
        table.insert(tbl, prefab) 
    end 
    return tbl 
end 

_G.splittable = function(sourcetable, splitamount)
    local data = {}
    local tbl = sourcetable
    for k,v in pairs(splitamount) do
        local new_tbl = {}
        for i = 1,v do
            local item = math.random(#tbl)
            table.insert(new_tbl, tbl[item])
            table.remove(tbl, item)
        end
        table.insert(data, new_tbl)
    end
    return unpack(data)
end

_G.spreadtableovertables = function(sourcetable, targettables)
    local ret = sourcetable
    local ret_targets = targettables
    for e = 1, #sourcetable do
        local i = math.random(#ret)
        local i_target = math.random(#ret_targets)
        --print("inserting", ret[i], "into", ret_targets[i_target])
        table.insert(ret_targets[i_target], ret[i])
        table.remove(ret, i)
        --table.remove(ret_targets, i_target) --Fid: I'm pretty sure we want the same round capable of multiple drops
    end
end

_G.spreadtableovertablesunique = function(sourcetable, targettables)
    local ret = sourcetable
    local ret_targets = targettables
    for e = 1, #sourcetable do
        local i = math.random(#ret)
        local i_target = math.random(#ret_targets)
        --print("inserting", ret[i], "into", ret_targets[i_target])
        table.insert(ret_targets[i_target], ret[i])
        table.remove(ret, i)
        table.remove(ret_targets, i_target)
    end
end
