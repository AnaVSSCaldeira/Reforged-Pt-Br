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

-- Debug class full of functions to help debug
local Debug = Class(function(self, debug_mode)
	self.debug_mode = debug_mode or false
end)

function Debug:SetDebugMode(enabled)
	self.debug_mode = enabled
end

local default_mod_type = "RF"
local types = {
    error   = "ERROR",
    warning = "WARNING",
    note    = "NOTE",
    log     = "LOG",
}
-- Prints the text to the log files if debug_mode is turned on
function Debug:Print(text, type, location, should_print, debug_only, mod_type_override)
	if (should_print == nil or should_print) and (not debug_only or self.debug_mode) then
        local debug_print = "[" .. (mod_type_override or default_mod_type) .. (types[type] and ("." .. tostring(types[type])) or "") .. "]" .. (location and "[" .. tostring(location) .. "]" or "") .. " "
		print(debug_print .. tostring(text))
	end
end

-- Print the contents of a table (Tshaws)
function Debug:PrintTable(tbl, max_depth, indent)
    if indent == nil then
        indent = 0
    end
    if max_depth == nil then
        max_depth = 1
    end
    for k, v in pairs(tbl) do
        local formatting = string.rep("\t", indent) .. tostring(k) .. ": "
        if type(v) == "table" and indent < max_depth then
            print(formatting)
            self:PrintTable(v, max_depth, indent+1)
        elseif type(v) == "userdata" then
            self:PrintUserdata(v, formatting)
        else
            print(formatting .. tostring(v))
        end
    end
end

function Debug:PrintUserdata(userdata, formatting)
    local formatting = formatting or ""
    for i,data in pairs(getmetatable(userdata).__index) do
        print(formatting .. tostring(i) ..": " .. tostring(data))
    end
end

function Debug:PrintDump(variable, max_depth)
    if variable then
        if type(variable) == "table" then
            self:PrintTable(variable, max_depth)
        elseif type(variable) == "userdata" then
            self:PrintUserdata(variable)
        else
            print(tostring(variable))
        end
    else
        print("[Dump]: Variable is nil")
    end
end

local color_string = {"Red:", "Green:", "Blue:", "Alpha:"}
function Debug:PrintColor(ent)
    if not ent or not ent.AnimState then
        print("Ent nil or No AnimState for entity")
        return
    end
    local animstate_colors = {
        Add = {ent.AnimState:GetAddColour()},
        Mult = {ent.AnimState:GetMultColour()}
    }
    for type, colors in pairs(animstate_colors) do
        local msg = type..":"
        for i, v in ipairs(colors) do
            msg = msg.." "..color_string[i].." "..v.." "
        end
        print(msg)
    end
end

return Debug
