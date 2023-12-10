--[[
Copyright (C) 2019 Forged Forge

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
local ShaderManager = Class(function(self, inst)
    self.inst = inst
    self.base_shader_info = nil -- {shader = "", apply_fn = fn, remove_fn = fn}
    self.shaders = {}
    self.shader_link = {}
    self.shader_count = 0
    self.current_shader_index = nil
    self.shader_task = nil
    self.cycle_time = 1
end)

function ShaderManager:AddShader(source, shader, apply_fn, remove_fn)
    if not self.shaders[source] then
        self.shaders[source] = {shader = shader, apply_fn = apply_fn, remove_fn = remove_fn}
        self.shader_count = self.shader_count + 1
        table.insert(self.shader_link, source)
        if self.shader_count > 1 then
            self:UpdateCycleTask()
        else
            self:ApplyShader(source)
            self.current_shader_index = 1
        end
    end
end

function ShaderManager:RemoveShader(source)
    local shader_info = self.shaders[source]
    if shader_info then
        local is_shader_active = self.shader_link[self.current_shader_index] == source
        if is_shader_active then
            self:RemoveActiveShader()
        end
        self.shaders[source] = nil
        for i,shader_source in pairs(self.shader_link) do
            if source == shader_source then
                table.remove(self.shader_link, i)
                -- Want to lower the index so that when updating the cycle task it goes to the next shader correctly
                if i <= self.current_shader_index then
                    self.current_shader_index = self.current_shader_index - 1
                end
                if is_shader_active then
                    self:UpdateCycleTask(true)
                end
                break
            end
        end
        self.shader_count = self.shader_count - 1
        -- Reset to base shader if no shaders are left
        if self.shader_count <= 0 then
            self.current_shader_index = nil
            self:ApplyShader(self.base_shader_info)
        end
    end
end

function ShaderManager:ApplyShader(source, shader_override)
    if not self.inst:IsValid() then return end
    self:RemoveActiveShader()
    local shader_info = shader_override or self.shaders[source]
    if shader_info then
        if shader_info.shader then
            self.inst.AnimState:SetBloomEffectHandle(resolvefilepath("shaders/" .. tostring(shader_info.shader) .. ".ksh"))
        end
        if shader_info.apply_fn then
            shader_info.apply_fn(self.inst)
        end
    end
end

function ShaderManager:RemoveActiveShader()
    if not self.inst:IsValid() then return end
    if self.current_shader_index then
        local source = self.shader_link[self.current_shader_index]
        local shader_info = self.shaders[source]
        if shader_info and shader_info.remove_fn then
            shader_info.remove_fn(self.inst)
        end
        self.inst.AnimState:ClearBloomEffectHandle()
    end
end

function ShaderManager:UpdateCycleTask(reset)
    if not self.inst:IsValid() then return end
    if (reset or self.shader_count <= 1) and self.shader_task then
        self.shader_task:Cancel()
        self.shader_task = nil
    end
    if self.shader_count > 1 and not self.shader_task then
        self.shader_task = self.inst:DoPeriodicTask(self.cycle_time, function()
            self.current_shader_index = (self.current_shader_index or 0) % self.shader_count + 1
            self:ApplyShader(self.shader_link[self.current_shader_index])
        end)
    end
end

function ShaderManager:OnRemoveFromEntity()
    RemoveTask(self.shader_task)
    self:RemoveActiveShader()
    --self:ApplyShader(self.base_shader_info)
end

return ShaderManager
