local function OnNewMusicStr(inst)
    local bgm_manager = inst.components.bgm_manager_reforged
    if bgm_manager then
        local music_str = bgm_manager.current_music_str:value()
        if music_str ~= bgm_manager.current_music_str_playing then
            TheFocalPoint.SoundEmitter:KillSound("bgm")
            if music_str ~= "" then
                TheFocalPoint.SoundEmitter:PlaySound(music_str, "bgm")
            end
            bgm_manager.current_music_str_playing = music_str
        end
    end
end

local BGMManager = Class(function(self, inst)
    self.inst = inst
    self.music = {
        {
            name      = "forge",
            music_str = "dontstarve/music/lava_arena/fight_1", -- "dontstarve/music/music_epicfight"
            priority  = 5,
        }
    }
    self.current_music_name = ""
    self.current_music_str = net_string(inst.GUID, "bgmmanager.current_music_str", "newmusicstr")
    self.current_music_str_playing = ""
    if TheWorld.ismastersim then
        self.inst:ListenForEvent("ms_playerjoined", function()
            self:StartMusic()
        end, TheWorld)
        self.inst:ListenForEvent("stop_lavaarena_music", function()
            self:StopMusic()
        end, TheWorld)
    end
    if not TheNet:IsDedicated() then
        self.inst:ListenForEvent("newmusicstr", OnNewMusicStr)
    end
end)

function BGMManager:AddBGM(name, music_str, priority)
    table.insert(self.music, {name = name, music_str = music_str, priority = priority})
    self:UpdateBGM()
end

function BGMManager:RemoveBGM(name)
    for i,info in pairs(self.music) do
        if info.name == name then
            table.remove(self.music, i)
            break
        end
    end
    self:UpdateBGM()
end

function BGMManager:UpdateBGM()
    if #self.music > 0 then
        table.sort(self.music, function(a,b)
            return a.priority < b.priority
        end)
        if self.current_music_name ~= self.music[1].name then
            self:StartMusic()
        end
    else
        self:StopMusic()
    end
end

function BGMManager:StartMusic()
    if #self.music > 0 then
        self.current_music_str:set_local(self.music[1].music_str)
        self.current_music_str:set(self.music[1].music_str)
    end
end

function BGMManager:StopMusic()
    self.current_music_str:set("")
end

return BGMManager
