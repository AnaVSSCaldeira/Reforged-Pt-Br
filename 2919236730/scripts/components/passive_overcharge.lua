local function OnAttacked(inst, data)
    if data.stimuli and data.stimuli == "electric" then
        inst.components.passive_overcharge:Overcharge()
    end
end

local function OnDeath(inst, data)
    inst.components.passive_overcharge:RemoveOvercharge()
end

local PassiveOvercharge = Class(function(self, player)
    self.player       = player
    self.overcharged  = false
    self.duration     = 10
    self.speed_bonus  = 0.1 -- percent increase
    self.light_radius = 3

    self.player:AddTag("shockable")

    self.player:ListenForEvent("attacked", OnAttacked)
    self.player:ListenForEvent("death", OnDeath)
end)

function PassiveOvercharge:Overcharge(attacker, weapon)
    if self.overcharged then
        RemoveTask(self.overcharge_timer)
    end
    self.overcharged = true
    self.player.SoundEmitter:KillSound("overcharge_sound")
    self.player.SoundEmitter:PlaySound("dontstarve/characters/wx78/charged", "overcharge_sound")
    self.player.components.bloomer:PushBloom("overcharge", "shaders/anim.ksh", 50)
    self.player.Light:Enable(true)
    self.player.Light:SetRadius(self.light_radius)
    self.player.components.locomotor:SetExternalSpeedMultiplier(self, "passive_overcharge", 1 + self.speed_bonus)
    self.overcharge_timer = self.player:DoTaskInTime(self.duration, function(inst)
        self:RemoveOvercharge()
    end)
    self.player.components.talker:Say(GetString(self.player, "ANNOUNCE_CHARGE"))
    self.player:StartUpdatingComponent(self)
end

function PassiveOvercharge:IsOvercharged()
    return self.overcharged
end

function PassiveOvercharge:RemoveOvercharge()
    self.player.SoundEmitter:KillSound("overcharge_sound")
    self.player.Light:Enable(false)
    self.player.components.locomotor:RemoveExternalSpeedMultiplier(self, "passive_overcharge")
    self.player.components.bloomer:PopBloom("overcharge")
    self.player.components.talker:Say(GetString(self.player, "ANNOUNCE_DISCHARGE"))
    self.player:StopUpdatingComponent(self)
end

function PassiveOvercharge:OnUpdate(dt)
    if self:IsOvercharged() then
        local overcharge_percent = GetTaskRemaining(self.overcharge_timer) / self.duration
        self.player.Light:SetRadius(overcharge_percent * self.light_radius)
        self.player.components.locomotor:SetExternalSpeedMultiplier(self, "passive_overcharge", 1 + (overcharge_percent * self.speed_bonus))
    else
        self.player:StopUpdatingComponent(self)
    end
end

function PassiveOvercharge:OnRemoveFromEntity()
    RemoveTask(self.overcharge_timer)
    self.player:RemoveTag("shockable")
    self.player:RemoveEventCallback("attacked", OnAttacked)
    self.player:RemoveEventCallback("death", OnDeath)
end

function PassiveOvercharge:GetDebugString()
    return string.format("Status: %s, (duration:%2.2f)", tostring(self.overcharged), self.overcharge_timer and GetTaskRemaining(self.overcharge_timer) or 0)
end

return PassiveOvercharge
