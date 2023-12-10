local env = env
GLOBAL.setfenv(1, GLOBAL)

local UpvalueHacker = require("tools/upvaluehacker")

env.AddComponentPostInit("worldcharacterselectlobby", function(self)
    local _OnWallUpdate = self.OnWallUpdate
    local fixed
    function self:OnWallUpdate(...)
        if not fixed then
            UpvalueHacker.SetUpvalue(self.CanPlayersSpawn, 1, "_countdownf")
            fixed = true
        end
        _OnWallUpdate(self, ...)
    end
end)

env.AddPrefabPostInit("lavaarena", function(inst)
    inst:ListenForEvent("lavaarena_portal_activate", function()
        inst.components.lavaarenaevent:Disable()

        local p = ThePlayer or AllPlayers[1]
        p.components.health:SetInvincible(true)
    end)
end)

function FossilAll(t)
    t = t or math.huge
    for _, v in pairs(Ents) do
        if v.components.fossilizable then
            v:PushEvent("fossilize", {duration = t, doer = ThePlayer or AllPlayers[1]})
        end
    end
end

function MobsInRow(spacing, list)
    list = list or {
        "pitpig",
        "crocommander",
        "snortoise",
        "scorpeon",
        "boarilla",
        "boarrior",
        "rhinocebro",
        "rhinocebro2",
        "swineclops",
    }
    local len = -math.ceil(#list/2) * spacing
    local pt = TheWorld.components.lavaarenaevent:GetArenaCenterPoint()
    for i, v in ipairs(list) do
        local offset = Vector3(len + i * spacing, 0, 0)
        SpawnAt(v, pt + offset)
    end
end
