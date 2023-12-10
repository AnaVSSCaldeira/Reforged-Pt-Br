local STRINGS = _G.STRINGS
local RF_TUNING = _G.TUNING.FORGE
local RF_DATA = _G.REFORGED_DATA
RF_DATA.gametypes = {}
function AddGametype(name, fns, icon, exp_details, order_priority, reset)
    if RF_DATA.gametypes[name] then
        _G.Debug:Print("Attempted to add the gametype '" .. tostring(name) .."', but it already exists.", "error")
        return
    end
    RF_DATA.gametypes[name] = {
        fns            = fns or {},
        icon           = icon,
        exp_details    = exp_details,
        order_priority = order_priority or 999,
        reset          = reset,
    }
end
_G.AddGametype = AddGametype
local forge_icon = {atlas = "images/inventoryimages.xml", tex = "hammer_mjolnir.tex"}
AddGametype("forge", nil, forge_icon, nil, 1)
--[[
TODO
increase fakeout banter chance?
add dotask to delay light checks
--]]
---------------------------
-- Red Light Green Light --
---------------------------
local function RGB(r, g, b)
    return { r / 255, g / 255, b / 255, 1 }
end
local INITIAL_LIGHT_CHECK_DELAY = 1
local phases = {}
local valid_phases = {}
local function AddLightPhase(name, color, onenter_fn, onexit_fn, str, speech, fakeout_banter, min_time, max_time)
    phases[name] = {
        color          = color,
        str            = str,
        speech         = speech,
        fakeout_banter = fakeout_banter,
        min_time       = min_time or 10,
        max_time       = max_time or 20,
        onenter_fn     = onenter_fn,
        onexit_fn      = onexit_fn,
    }
    table.insert(valid_phases, name)
end
local function GetCurrentLightPhase()
    return _G.TheWorld.current_light_phase
end
local function KillPlayer(inst)
    if not inst.components.health:IsDead() and not inst.light_immunity then
        local current_light_phase = GetCurrentLightPhase()
        local light_phase_str = current_light_phase and phases[current_light_phase].str
        inst.components.health:DoDelta(-inst.components.health.currenthealth, nil, light_phase_str or nil, true, nil, true)
    end
end
-- No Light: No restrictions
AddLightPhase("normal", RGB(255, 255, 255), nil, nil, "NOLIGHT", "REFORGED.RLGL.NOLIGHT_SPEECH", "REFORGED.RLGL.NOLIGHT_FAKEOUT_BANTER")
local MOVEMENT_CHECK_TASK_TIME = _G.FRAMES
-- Red Light: Can't move
local function StopPhaseOnLocomote(inst)
    if inst.sg:HasStateTag("moving") and GetCurrentLightPhase() == "stop" then --inst.Physics:GetMotorSpeed() > 0 then
        KillPlayer(inst)
    end
end
local function StopPhaseOnEnter(inst)
    for _,player in pairs(_G.AllPlayers) do
        --player:ListenForEvent("locomote", StopPhaseOnLocomote)
        player.stop_task = player:DoPeriodicTask(MOVEMENT_CHECK_TASK_TIME, StopPhaseOnLocomote, nil, 1)
        --[[
        --Give players a little helping hand
        player.components.locomotor:Stop()
        player.components.locomotor:Clear()
        player:ClearBufferedAction()
        --]]
    end
end
local function StopPhaseOnExit(inst)
    for _,player in pairs(_G.AllPlayers) do
        --player:RemoveEventCallback("locomote", StopPhaseOnLocomote)
        _G.RemoveTask(player.stop_task) -- ThePlayer.components.colouradder:PushColour("test", 255, 0, 0, 1)
    end
end
AddLightPhase("stop", RGB(255, 0, 0), StopPhaseOnEnter, StopPhaseOnExit, "REDLIGHT", "REFORGED.RLGL.REDLIGHT_SPEECH", "REFORGED.RLGL.REDLIGHT_FAKEOUT_BANTER", 2, 5)
-- Green Light: Can't stand still -- TODO for more than a second?
local MIN_MOVE_TIME = 0.5
local function MovePhaseCheck(inst)
    if not inst.sg:HasStateTag("moving") and (not inst.last_move_time or _G.GetTime() - inst.last_move_time > MIN_MOVE_TIME) and GetCurrentLightPhase() == "move" then
        KillPlayer(inst)
    end
end
local function MovePhaseOnLocomote(inst)
    if inst.Physics:GetMotorSpeed() > 0 or inst.sg:HasStateTag("moving") then
        inst.last_move_time = _G.GetTime()
    end
end
local function MovePhaseOnEnter(inst)
    for _,player in pairs(_G.AllPlayers) do
        player:ListenForEvent("locomote", MovePhaseOnLocomote)
        player.move_task = player:DoPeriodicTask(MIN_MOVE_TIME, MovePhaseCheck, nil, 0)
    end
end
local function MovePhaseOnExit(inst)
    for _,player in pairs(_G.AllPlayers) do
        _G.RemoveTask(player.move_task)
        player.move_task = nil
        player:RemoveEventCallback("locomote", MovePhaseOnLocomote)
        player.last_move_time = nil
    end
end
AddLightPhase("move", RGB(0, 255, 127), MovePhaseOnEnter, MovePhaseOnExit, "GREENLIGHT", "REFORGED.RLGL.GREENLIGHT_SPEECH", "REFORGED.RLGL.GREENLIGHT_FAKEOUT_BANTER", 2, 5)
-- Orange Light: Must attack once every 5 seconds???
local MIN_ATTACK_TIME = 2
local function AttackPhaseCheck(inst)
    local current_time = _G.GetTime()
    -- Only kill the player if there are mobs to attack and the wave did not just start.
    if (not inst.components.combat.lastdoattacktime or current_time - inst.components.combat.lastdoattacktime > MIN_ATTACK_TIME) and #_G.TheWorld.components.forgemobtracker:GetAllLiveMobs() > 0 and current_time - _G.TheWorld.components.lavaarenaevent.wave_start_time > MIN_ATTACK_TIME and GetCurrentLightPhase() == "attack" then
        KillPlayer(inst)
    end
end
local function AttackPhaseOnEnter(inst)
    for _,player in pairs(_G.AllPlayers) do
        player.attack_task = player:DoPeriodicTask(MIN_ATTACK_TIME, AttackPhaseCheck, nil, math.max(0, MIN_ATTACK_TIME - INITIAL_LIGHT_CHECK_DELAY))
    end
end
local function AttackPhaseOnExit(inst)
    for _,player in pairs(_G.AllPlayers) do
        _G.RemoveTask(player.attack_task)
        player.attack_task = nil
    end
end
AddLightPhase("attack", RGB(255, 165, 0), AttackPhaseOnEnter, AttackPhaseOnExit, "ORANGELIGHT", "REFORGED.RLGL.ORANGELIGHT_SPEECH", "REFORGED.RLGL.ORANGELIGHT_FAKEOUT_BANTER", 5, 10)
-- Blue Light: Can't get hit.
local function OnAttacked(inst)
    if GetCurrentLightPhase() == "hit" then
        KillPlayer(inst)
    end
end
local function HitPhaseOnEnter(inst)
    for _,player in pairs(_G.AllPlayers) do
        player:ListenForEvent("attacked", OnAttacked)
    end
end
local function HitPhaseOnExit(inst)
    for _,player in pairs(_G.AllPlayers) do
        player:RemoveEventCallback("attacked", OnAttacked)
    end
end
AddLightPhase("hit", RGB(0, 0, 255), HitPhaseOnEnter, HitPhaseOnExit, "BLUELIGHT", "REFORGED.RLGL.BLUELIGHT_SPEECH", "REFORGED.RLGL.BLUELIGHT_FAKEOUT_BANTER", 5, 10)
local function ResetValidPhases(inst)
    if #valid_phases <= 0 then
        for phase,_ in pairs(phases) do
            table.insert(valid_phases, phase)
        end
    end
end
local CHATTER_LINE_DURATION = 4
local BANTER_CHANCE = 0.2
local function CreateFakeoutBanter(inst, time_to_next_phase)
    local time_to_next_fake = math.random(1, time_to_next_phase)
    if math.random() <= BANTER_CHANCE and time_to_next_fake < time_to_next_phase then
        inst:DoTaskInTime(time_to_next_fake, function(inst)
            local fakeout_phase = valid_phases[math.random(1,#valid_phases)]
            local fakeout_banter = phases[fakeout_phase].fakeout_banter
            if inst.components.lavaarenaevent.victory ~= nil then return end -- Do not fakeout banter when the game is over
            local rlgl_talker = inst:GetRLGLTalker()
            if rlgl_talker then
                rlgl_talker.components.talker:Chatter(fakeout_banter, _G.COMMON_FNS.GetBanterID(fakeout_banter), CHATTER_LINE_DURATION)
            end
            CreateFakeoutBanter(inst, time_to_next_phase - time_to_next_fake)
        end)
    end
end
local function ChangeLightPhase(inst, phase)
    if inst.current_light_phase then
        if phases[inst.current_light_phase].onexit_fn then
            phases[inst.current_light_phase].onexit_fn(inst)
        end
        inst:PushEvent("remove_light_phase", {name = "rlgl_" .. tostring(inst.current_light_phase)})
    end

    if inst.components.lavaarenaevent.victory ~= nil then return end -- Stop changing lights when the game is over
    inst.current_light_phase = phase
    local current_phase_info = phases[inst.current_light_phase]
    inst:PushEvent("add_light_phase", {name = "rlgl_" .. tostring(inst.current_light_phase), color = current_phase_info.color, time = 0, priority = 1})
    -- Set players color for the current phase
    for _,player in pairs(_G.AllPlayers) do
        if player.components.colouradder then
            local color = current_phase_info.color
            player.components.colouradder:PushColour("rlgl", color[1], color[2], color[3], color[4], nil, nil, true)
        elseif player.AnimState then
            player.AnimState:SetMultColour(_G.unpack(current_phase_info.color))
        end
    end
    if current_phase_info.onenter_fn then
        inst:DoTaskInTime(INITIAL_LIGHT_CHECK_DELAY, function(inst)
            current_phase_info.onenter_fn(inst)
        end)
    end
    local rlgl_talker = inst:GetRLGLTalker()
    if rlgl_talker then
        rlgl_talker.components.talker:Chatter(phases[inst.current_light_phase].speech, 0, CHATTER_LINE_DURATION)
    end
end
local function UpdateLightPhase(inst)
    -- Start next valid phase
    local next_phase = "normal"
    if inst.current_light_phase == "normal" then
        local index = inst.current_light_phase and math.random(1,#valid_phases) or 1
        next_phase = valid_phases[index]
        table.remove(valid_phases, index)
    end
    ResetValidPhases(inst)
    ChangeLightPhase(inst, next_phase)
    if inst.components.lavaarenaevent.victory ~= nil then return end -- Do not queue the next phase when the game is over
    -- Queue next phase
    local current_phase_info = phases[inst.current_light_phase]
    local time_to_next_phase = math.random(current_phase_info.min_time, current_phase_info.max_time)
    inst:DoTaskInTime(time_to_next_phase, function()
        UpdateLightPhase(inst)
    end)
    CreateFakeoutBanter(inst, time_to_next_phase)
end
local REVIVED_LIGHT_IMMUNITY_TIME = 5
local function StartRLGL(inst)
    UpdateLightPhase(inst)
    for _,player in pairs(_G.AllPlayers) do
        player:ListenForEvent("respawnfromcorpse", function(inst)
            inst.light_immunity = true
            player:DoTaskInTime(REVIVED_LIGHT_IMMUNITY_TIME, function()
                inst.light_immunity = false
            end)
        end)
    end
end
local function OnNewPlayer(inst, player)
    if player.AnimState and inst.current_light_phase then
        player.AnimState:OverrideMultColour(_G.unpack(phases[inst.current_light_phase].color))
    end
end
local rlgl_fns = {
    enable_server_fn = function(inst)
        inst.rlgl_talker = _G.SpawnPrefab("reforged_rlgl_talker")
        inst.GetRLGLTalker = function()
            return inst.rlgl_talker
        end
        ------------------------------------------
        inst:ListenForEvent("ms_playerjoined", OnNewPlayer)
        inst:ListenForEvent("ms_forge_allplayersspawned", StartRLGL)
    end,
    disable_server_fn = function(inst)
        if inst.rlgl_talker then
            inst.rlgl_talker:Remove()
            inst.rlgl_talker = nil
        end
        ------------------------------------------
        inst:RemoveEventCallback("ms_playerjoined", OnNewPlayer)
        inst:RemoveEventCallback("ms_forge_allplayersspawned", StartRLGL)
    end,
}
local rlgl_icon = {atlas = "images/reforged.xml", tex = "rlgl2.tex"}
local rlgl_exp = {desc = "RLGL", val = {mult = RF_TUNING.EXP.GAMETYPES.rlgl}}
AddGametype("rlgl", rlgl_fns, rlgl_icon, rlgl_exp, 3)
local function RGB(r, g, b)
    return { r / 255, g / 255, b / 255, 1 }
end
local classic_phases = {}
local function ClassicAddLightPhase(name, color, onenter_fn, onexit_fn, str, speech, fakeout_banter, min_time, max_time)
    classic_phases[name] = {
        color          = color,
        str            = str,
        speech         = speech,
        fakeout_banter = fakeout_banter,
        min_time       = min_time or 10,
        max_time       = max_time or 20,
        onenter_fn     = onenter_fn,
        onexit_fn      = onexit_fn,
    }
end
local function KillPlayer(inst)
    if not inst.components.health:IsDead() then
        local current_light_phase = GetCurrentLightPhase()
        local light_phase_str = current_light_phase and classic_phases[current_light_phase].str
        inst.components.health:DoDelta(-inst.components.health.currenthealth, nil, light_phase_str or nil, true, nil, true)
    end
end
-- Yellow Light: Prepare for Red Light
ClassicAddLightPhase("yellow", RGB(255, 255, 0), nil, nil, nil, nil, nil, 2, 2)
-- Red Light: Can't move or Attack
local function StopPhaseOnLocomote(inst)
    if inst.sg:HasStateTag("moving") and GetCurrentLightPhase() == "red" then --inst.Physics:GetMotorSpeed() > 0 then
        KillPlayer(inst)
    end
end
local function StopPhaseOnAttackOther(inst, data)
    if not (data and data.is_special) and GetCurrentLightPhase() == "red" then
        KillPlayer(inst, data)
    end
end
local function StopPhaseOnEnter(inst)
    for _,player in pairs(_G.AllPlayers) do -- TODO might need to add check for spell, since onattackother only triggers if hitting a target
        --player:ListenForEvent("locomote", StopPhaseOnLocomote)
        player:ListenForEvent("onattackother", StopPhaseOnAttackOther)
        player.stop_task = player:DoPeriodicTask(MOVEMENT_CHECK_TASK_TIME, StopPhaseOnLocomote, nil, 0)
    end
end
local function StopPhaseOnExit(inst)
    for _,player in pairs(_G.AllPlayers) do
        --player:RemoveEventCallback("locomote", StopPhaseOnLocomote)
        player:RemoveEventCallback("onattackother", StopPhaseOnAttackOther)
        _G.RemoveTask(player.stop_task)
        player.stop_task = nil
    end
end
ClassicAddLightPhase("red", RGB(255, 0, 0), StopPhaseOnEnter, StopPhaseOnExit, "REDLIGHT", "REFORGED.RLGL.REDLIGHT_SPEECH", nil, 4, 8)
-- Green Light: No restrictions
ClassicAddLightPhase("green", RGB(0, 255, 127), nil, nil, "GREENLIGHT", "REFORGED.RLGL.GREENLIGHT_SPEECH", "REFORGED.RLGL.GREENLIGHT_FAKEOUT_BANTER", 9, 20)
local BANTER_CHANCE = 0.2
local function ClassicCreateFakeoutBanter(inst, time_to_next_phase)
    local time_to_next_fake = math.random(1, time_to_next_phase)
    if math.random() <= BANTER_CHANCE and time_to_next_fake < time_to_next_phase then
        inst:DoTaskInTime(time_to_next_fake, function(inst)
            if inst.current_light_phase == "stop" and inst.components.lavaarenaevent.victory == nil then -- Do not fakeout banter when the game is over or when red light is active
                local rlgl_talker = inst:GetRLGLTalker()
                if rlgl_talker then
                    rlgl_talker.components.talker:Chatter(classic_phases.move.fakeout_banter, _G.COMMON_FNS.GetBanterID(classic_phases.move.fakeout_banter), CHATTER_LINE_DURATION)
                end
                ClassicCreateFakeoutBanter(inst, time_to_next_phase - time_to_next_fake)
            end
        end)
    end
end
local function ClassicChangeLightPhase(inst, phase)
    if inst.current_light_phase then
        if classic_phases[inst.current_light_phase].onexit_fn then
            classic_phases[inst.current_light_phase].onexit_fn(inst)
        end
        inst:PushEvent("remove_light_phase", {name = "classic_rlgl_" .. tostring(inst.current_light_phase)})
    end
    if inst.components.lavaarenaevent.victory ~= nil then return end -- Stop changing lights when the game is over
    inst.current_light_phase = phase
    local current_phase_info = classic_phases[inst.current_light_phase]
    inst:PushEvent("add_light_phase", {name = "classic_rlgl_" .. tostring(inst.current_light_phase), color = current_phase_info.color, time = 0, priority = 1})
    -- Set players color for the current phase
    for _,player in pairs(_G.AllPlayers) do
        if player.components.colouradder then
            local color = current_phase_info.color
            player.components.colouradder:PushColour("classic_rlgl", color[1], color[2], color[3], color[4], nil, nil, true)
        elseif player.AnimState then
            player.AnimState:SetMultColour(_G.unpack(current_phase_info.color))
        end
    end
    if current_phase_info.onenter_fn then
        current_phase_info.onenter_fn(inst)
    end

    local rlgl_talker = inst:GetRLGLTalker()
    if rlgl_talker and classic_phases[inst.current_light_phase].speech then
        rlgl_talker.components.talker:Chatter(classic_phases[inst.current_light_phase].speech, 0, CHATTER_LINE_DURATION)
    end
end
local function ClassicUpdateLightPhase(inst)
    -- Start next valid phase
    ClassicChangeLightPhase(inst, inst.current_light_phase == "green" and "yellow" or inst.current_light_phase == "yellow" and "red" or "green")
    if inst.components.lavaarenaevent.victory ~= nil then return end -- Do not queue the next phase when the game is over
    -- Queue next phase
    local current_phase_info = classic_phases[inst.current_light_phase]
    local time_to_next_phase = math.random(current_phase_info.min_time, current_phase_info.max_time)
    inst:DoTaskInTime(time_to_next_phase, function()
        ClassicUpdateLightPhase(inst)
    end)
    ClassicCreateFakeoutBanter(inst, time_to_next_phase)
end
local function StartClassicRLGL(inst)
    if inst and inst.current_light_phase == nil then
        ClassicUpdateLightPhase(inst)
    end
end
local function OnNewPlayerClassic(inst, player)
    if inst.current_light_phase then
        if player.components.colouradder then
            local color = classic_phases[inst.current_light_phase].color
            player.components.colouradder:PushColour("classic_rlgl", color[1], color[2], color[3], color[4], nil, nil, true)
        elseif player.AnimState then
            player.AnimState:SetMultColour(_G.unpack(classic_phases[inst.current_light_phase].color))
        end
    end
end
local classic_rlgl_fns = {
    enable_server_fn = function(inst)
        inst.rlgl_talker = _G.SpawnPrefab("reforged_rlgl_talker")
        inst.GetRLGLTalker = function()
            return inst.rlgl_talker
        end
        ------------------------------------------
        inst:ListenForEvent("ms_playerjoined", OnNewPlayerClassic)
        inst:ListenForEvent("ms_forge_allplayersspawned", StartClassicRLGL)
    end,
    disable_server_fn = function(inst)
        if inst.rlgl_talker then
            inst.rlgl_talker:Remove()
            inst.rlgl_talker = nil
        end
        ------------------------------------------
        inst:RemoveEventCallback("ms_playerjoined", OnNewPlayerClassic)
        inst:RemoveEventCallback("ms_forge_allplayersspawned", StartClassicRLGL)
    end
}
local classic_rlgl_icon = {atlas = "images/reforged.xml", tex = "rlgl.tex"}
local classic_rlgl_exp = {desc = "CLASSIC_RLGL", val = {mult = RF_TUNING.EXP.GAMETYPES.classic_rlgl}}
AddGametype("classic_rlgl", classic_rlgl_fns, classic_rlgl_icon, classic_rlgl_exp, 2)
