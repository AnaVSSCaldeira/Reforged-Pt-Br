local STRINGS = _G.STRINGS
local RF_TUNING = _G.TUNING.FORGE
--[[
TODO
Mutators
    unbreakable_shields
    no interrupts?
        have nointerrupt tags be in a table, then simply remove them all at the start of the game?
--]]
local function MenuRefreshFN(self)
    local mutator = self.item.name
    local category = self.item.type

    -- Spinners
    if category == "slider" then
        self:EnsureSpinnersExist(1)
        -- Stat Spinner
        local spinner_options = {min = 0.25, max = 5, step = 0.25, percent = true, suffix = "%", specific_values = nil}
        if self.item.num_config then
            _G.MergeTable(spinner_options, self.item.num_config, true)
        end
        local stat_spinner = self.spinners[1]
        local spinner_data = _G.deepcopy(spinner_options.specific_values) or {}
        for i = spinner_options.min, spinner_options.max, spinner_options.step or 1 do
            table.insert(spinner_data, {text = i..spinner_options.suffix, data = spinner_options.percent and i / 100 or i})
        end
        if spinner_options.specific_values then
            table.sort(spinner_data, function(a,b)
                return a.data < b.data
            end)
        end
        stat_spinner:SetOptions(spinner_data)
        stat_spinner:SetHoverText("")
        stat_spinner:SetOnChangedFn(function(selected, old) end)
        stat_spinner:SetSelected(_G.REFORGED_SETTINGS.gameplay.mutators[mutator])
        stat_spinner:SetScale(1,1,1)
        stat_spinner:SetPosition(320, 75, 0)
        stat_spinner.fgimage:Hide()
        stat_spinner.width = 200
        stat_spinner:Layout()
        stat_spinner:Show()
    end

    -- Buttons
    self:EnsureButtonsExist(1)
    -- Apply/Enable Button
    local apply_button = self.buttons[1]
    apply_button:Show()
    apply_button:Enable()
    apply_button:SetText(STRINGS.UI.ADMINMENU.BUTTONS[category == "slider" and "APPLY" or _G.REFORGED_SETTINGS.gameplay.mutators[mutator] and "DISABLE" or "ENABLE"])
    apply_button:SetScale(1,1,1)
    apply_button:SetPosition(320, -105, 0)
    apply_button:SetOnClick(function()
        local val
        if category == "slider" then
            val = self.spinners[1]:GetSelectedData()
        else
            val = not _G.REFORGED_SETTINGS.gameplay.mutators[mutator]
            apply_button:SetText(STRINGS.UI.ADMINMENU.BUTTONS[val and "DISABLE" or "ENABLE"])
        end
        _G.UpdateMutator(mutator, val)
    end)
end
_G.REFORGED_DATA.mutators = {}
function AddMutator(name, is_valid_fn, mutator_fns, mutator_type, default_value, num_config, prefab_fns, icon, exp_details, order_priority, reset)
    local mutators = _G.REFORGED_DATA.mutators
    if mutators[name] then
        _G.Debug:Print("Attempted to add the mutator '" .. tostring(name) .."', but it already exists.", "error")
        return
    end
    mutators[name] = {
        is_valid_fn = is_valid_fn,
        mutator_fns = mutator_fns,
        prefab_fns  = prefab_fns,
        type        = mutator_type or "checkbox", -- "slider", "checkbox"
        num_config  = num_config,
        display     = "", -- TODO use this for "stat" instead of type, and then use type to determine if it loads in general or for mobs or players?
        icon        = icon, -- {atlas = ".xml", tex = ".tex"}
        exp_details = exp_details, -- {desc = "", val = 0}
        name            = name,
        default_value   = default_value,
        sortkey         = mutator_type == "slider" and 1 or 0,
        menu_refresh_fn = MenuRefreshFN,
        order_priority  = order_priority or 999,
        reset           = reset,
    }
    -- Keep value from prior settings. If prior settings do not exist then set to default value.
    _G.REFORGED_SETTINGS.gameplay.mutators[name] = _G.REFORGED_SETTINGS.gameplay.mutators[name] or default_value
end
_G.AddMutator = AddMutator
--------------------------------------------------------------------------
local function IsServer()
    return _G.TheWorld and _G.TheWorld.ismastersim
end
--------------------------------------------------------------------------
local function StatIsValidFN(inst, prefab)
    return inst:HasTag("LA_MOB") and IsServer()
end
local function StatExp(mutator_value)
    return {add = (mutator_value <= 0 or mutator_value == 1) and 0 or mutator_value < 1 and -_G.RoundBiasedUp(math.pow(2, _G.RoundBiasedUp(math.floor(1/mutator_value*100)/100, 2) + 1), 2) or mutator_value}--mutator_value <= 1 and mutator_value or (mutator_value - 1) * RF_TUNING.EXP.MUTATORS.MOB_STAT_SCALE}--mutator_value > 1 and (mutator_value - 1) * RF_TUNING.EXP.MUTATORS.MOB_STAT_SCALE or 0 -- TODO tuning
end
local stat_num_config = {min = 50, max = 300, step = 5, percent = true}
------------------
-- Damage Dealt --
------------------
local function EnableDamageDealtMutatorServer(inst)
    if inst.components.combat then
        if inst.components.combat:HasDamageBuff("mutator_damage_dealt") then
            inst.components.combat:RemoveDamageBuff("mutator_damage_dealt")
        end
        local damage_dealt_mutator = _G.REFORGED_SETTINGS.gameplay.mutators.mob_damage_dealt
        if damage_dealt_mutator ~= 1 then
            inst.components.combat:AddDamageBuff("mutator_damage_dealt", {buff = damage_dealt_mutator})
        end
    end
end
local damage_dealt_mutator_fns = {
    enable_server_fn = EnableDamageDealtMutatorServer,
}
local damage_dealt_icon = {atlas = "images/reforged.xml", tex = "battlestandard_damager_icon.tex"}
local damage_dealt_exp = {desc = "MOB_DAMAGE", val = StatExp}
AddMutator("mob_damage_dealt", StatIsValidFN, damage_dealt_mutator_fns, "slider", 1, stat_num_config, nil, damage_dealt_icon, damage_dealt_exp, 1)
--------------------------------------------------------------------------
---------------------
-- Damage Received --
---------------------
local function EnableDamageReceievedMutatorServer(inst)
    if inst.components.combat then
        if inst.components.combat:HasDamageBuff("mutator_damage_received", true) then
            inst.components.combat:RemoveDamageBuff("mutator_damage_received", true)
        end
        local damage_received_mutator = _G.REFORGED_SETTINGS.gameplay.mutators.mob_damage_received
        if damage_received_mutator ~= 1 then
            inst.components.combat:AddDamageBuff("mutator_damage_received", {buff = 1/damage_received_mutator}, true)
        end
    end
end
local damage_received_mutator_fns = {
    enable_server_fn = EnableDamageReceievedMutatorServer,
}
local damage_received_icon = {atlas = "images/reforged.xml", tex = "battlestandard_shield_icon.tex"}
local damage_received_exp = {desc = "MOB_DEFENSE", val = StatExp}
AddMutator("mob_damage_received", StatIsValidFN, damage_received_mutator_fns, "slider", 1, stat_num_config, nil, damage_received_icon, damage_received_exp, 2)
--------------------------------------------------------------------------
------------
-- Health --
------------
-- TODO add buffable system to health? overwrite SetMaxHealth to apply buffs from buffable?
-- This would allow us to update the stat ingame
-- currently does not remove correctly due to this
local function EnableHealthMutatorServer(inst)
    local health = inst.components.health
    if health then
        local health_mutator = _G.REFORGED_SETTINGS.gameplay.mutators.mob_health
        if health:HasHealthBuff("health_mutator") then
            health:RemoveHealthBuff("health_mutator")
        end
        if health_mutator ~= 1 then
            local total_health = health.maxhealth
            health:AddHealthBuff("health_mutator", health_mutator, "mult")
        end
    end
end
local health_mutator_fns = {
    enable_server_fn = EnableHealthMutatorServer,
}
local health_icon = {atlas = "images/reforged.xml", tex = "battlestandard_heal_icon.tex"}
local health_exp = {desc = "MOB_HEALTH", val = StatExp}
AddMutator("mob_health", StatIsValidFN, health_mutator_fns, "slider", 1, stat_num_config, nil, health_icon, health_exp, 3)
--------------------------------------------------------------------------
-----------
-- Speed --
-----------
local function EnableSpeedMutatorServer(inst)
    if inst.components.locomotor then
        inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "mutator_speed")
        local speed_mutator = _G.REFORGED_SETTINGS.gameplay.mutators.mob_speed
        if speed_mutator ~= 1 then
            inst.components.locomotor:SetExternalSpeedMultiplier(inst, "mutator_speed", speed_mutator)
        end
    end
end
local speed_mutator_fns = {
    enable_server_fn = EnableSpeedMutatorServer,
}
local speed_icon = {atlas = "images/reforged.xml", tex = "battlestandard_speed_icon.tex"}
local speed_exp = {desc = "MOB_SPEED", val = StatExp}
AddMutator("mob_speed", StatIsValidFN, speed_mutator_fns, "slider", 1, stat_num_config, nil, speed_icon, speed_exp, 4)
--------------------------------------------------------------------------
-----------------
-- Attack Rate --
-----------------
local function EnableAttackRateMutatorServer(inst)
    if inst.components.buffable then
        local attack_rate_mutator = _G.REFORGED_SETTINGS.gameplay.mutators.mob_attack_rate
        inst.components.buffable:AddBuff("mutator_attack_rate", {{name = "attack_rate", type = "mult", val = attack_rate_mutator}})
    end
end
local function AttackRateExp(mutator_value) -- TODO needs adjusting, currently 0 = 5, 1 = 0, 2 = 5, linear
    return {add = (mutator_value - 1) * -5}
end
local attack_rate_mutator_fns = {
    enable_server_fn = EnableAttackRateMutatorServer,
}
local attack_rate_num_config = {min = 0, max = 200, step = 10, percent = true}
local attack_rate_icon = {atlas = "images/reforged.xml", tex = "mutator_attack_rate.tex"}
local attack_rate_exp = {desc = "MOB_ATTACK_RATE", val = AttackRateExp}
AddMutator("mob_attack_rate", StatIsValidFN, attack_rate_mutator_fns, "slider", 1, attack_rate_num_config, nil, attack_rate_icon, attack_rate_exp, 6)
--------------------------------------------------------------------------
----------
-- Size -- TODO size should affect attack range, each mob might need their own adjustments, not sure if a generic value will work for all
----------
local function EnableSizeMutatorServer(inst)
    local x,y,z = inst.Transform:GetScale()
    local scaler = _G.REFORGED_SETTINGS.gameplay.mutators.mob_size
    if inst.components.scaler then
        if inst.components.buffable then
            inst.components.buffable:AddBuff("mutator_size", {{name = "scaler", type = "mult", val = scaler}})
            inst.components.scaler:ApplyScale()
        else
            inst.components.scaler:SetScale(scaler)
        end
    else
        inst.Transform:SetScale(x*scaler, y*scaler, z*scaler)
    end
end
local function SizeExp(mutator_value) -- TODO adjust when size affects attack range
    return {add = 0}--{add = mutator_value == 1 and 0 or math.floor(mutator_value / RF_TUNING.EXP.MUTATORS.BATTLESTANDARD_EFFICIENCY_SCALE * (mutator_value > 1 and 1 or -1) * 100)/100}
end
local size_mutator_fns = {
    enable_server_fn = EnableSizeMutatorServer,
}
local size_num_config = {min = 50, max = 200, step = 10, percent = true}
local size_icon = {atlas = "images/reforged.xml", tex = "mutator_mobsize.tex"}
local size_exp = {desc = "MOB_SIZE", val = SizeExp}
AddMutator("mob_size", StatIsValidFN, size_mutator_fns, "slider", 1, size_num_config, nil, size_icon, size_exp, 6)
--------------------------------------------------------------------------
-------------------------------
-- BattleStandard Efficiency --
-------------------------------
local function BattleStandardIsValidFN(inst, prefab)
    return inst:HasTag("battlestandard_buff") and IsServer()
end
local function EnableBattleStandardEfficiencyServer(inst)
    inst.efficiency = _G.REFORGED_SETTINGS.gameplay.mutators.battlestandard_efficiency
end
local function BattleStandardEfficiencyStatExp(mutator_value) -- TODO this should give no exp if no banners are in the waveset
    return {add = mutator_value == 1 and 0 or math.floor(mutator_value / RF_TUNING.EXP.MUTATORS.BATTLESTANDARD_EFFICIENCY_SCALE * (mutator_value > 1 and 1 or -1) * 100)/100}
end
local battlestandard_efficiency_fns = {
    enable_server_fn = EnableBattleStandardEfficiencyServer,
}
local battlestandard_icon = {atlas = "images/reforged.xml", tex = "m_battlestandard_effeciency.tex"}
local battlestandard_exp = {desc = "BATTLESTANDARD_EFFICIENCY", val = BattleStandardEfficiencyStatExp}
AddMutator("battlestandard_efficiency", BattleStandardIsValidFN, battlestandard_efficiency_fns, "slider", 1, stat_num_config, nil, battlestandard_icon, battlestandard_exp, 5)
--------------------------------------------------------------------------
--------------
-- No Sleep --
--------------
local function NoSleepIsValidFN(inst, prefab)
    return inst:HasTag("LA_mob") and IsServer()
end
local function EnableNoSleepServer(inst) -- TODO should this be on client too?
    if not inst:HasTag("nosleep") then
        inst:AddTag("nosleep")
    end
end
local function DisableNoSleepServer(inst)
    if inst:HasTag("nosleep") then
        inst:RemoveTag("nosleep")
    end
end
local no_sleep_fns = {
    enable_server_fn = EnableNoSleepServer,
    disable_server_fn = DisableNoSleepServer,
}
local no_sleep_icon = {atlas = "images/reforged.xml", tex = "m_nosleep.tex"}
local no_sleep_exp = {desc = "NO_SLEEP", val = {add = RF_TUNING.EXP.MUTATORS.NO_SLEEP}}
AddMutator("no_sleep", NoSleepIsValidFN, no_sleep_fns, nil, false, nil, nil, no_sleep_icon, no_sleep_exp, 4)
--------------------------------------------------------------------------
----------------
-- No Revives --
----------------
local function NoRevivesIsValidFN(inst, prefab)
    return inst:HasTag("player") and IsServer()
end
local function EnableNoRevivesServer(inst)
    inst._oldRevivableCorpseFN = inst.components.revivablecorpse.canberevivedbyfn
    inst.components.revivablecorpse:SetCanBeRevivedByFn(function()
        return false
    end)
end
local function DisableNoRevivesServer(inst)
    inst.components.revivablecorpse:SetCanBeRevivedByFn(inst._oldRevivableCorpseFN)
end
local no_revives_fns = {
    enable_server_fn = EnableNoRevivesServer,
    disable_server_fn = DisableNoRevivesServer,
}
local no_revives_icon = {atlas = "images/reforged.xml", tex = "m_norevives.tex"}
local no_revives_exp = {desc = "NO_REVIVES", val = {add = RF_TUNING.EXP.MUTATORS.NO_REVIVES}}
AddMutator("no_revives", NoRevivesIsValidFN, no_revives_fns, nil, false, nil, nil, no_revives_icon, no_revives_exp, 5)
--------------------------------------------------------------------------
------------
-- No Hud -- TODO better checks, also on revive the inventory is shown again,add listener to rehide it?
------------
local function NoHudIsValidFN(inst, prefab)
    return inst:HasTag("player") and not _G.TheNet:IsDedicated()
end
local function EnableNoHudClient(inst)
    inst:DoTaskInTime(3*_G.FRAMES, function() -- Delay needed since inventory bar is set late
        if inst and inst.HUD and inst.HUD.controls then
            inst.HUD.controls.status:Hide()
            inst.HUD.controls.teamstatus:Hide()
            inst.HUD.controls:HideCraftingAndInventory()

            inst.HUD.controls._oldShowCraftingAndInventory = inst.HUD.controls.ShowCraftingAndInventory
            inst.HUD.controls.ShowCraftingAndInventory = function() end
        end
    end)
end
local function DisableNoHudClient(inst)
    if inst and inst.HUD and inst.HUD.controls then
        inst.HUD.controls.ShowCraftingAndInventory = inst.HUD.controls._oldShowCraftingAndInventory
        inst.HUD.controls._oldShowCraftingAndInventory = nil

        inst.HUD.controls.status:Show()
        inst.HUD.controls.teamstatus:Show()
        inst.HUD.controls:ShowCraftingAndInventory()
    end
end
local function EnableNoHudServer(inst)
    if _G.TheNet and _G.TheNet:GetServerIsClientHosted() then
        EnableNoHudClient(inst)
    end
end
local function DisableNoHudServer(inst)
    if _G.TheNet and _G.TheNet:GetServerIsClientHosted() then
        DisableNoHudClient(inst)
    end
end
local no_hud_fns = {
    enable_server_fn = EnableNoHudServer,
    disable_server_fn = DisableNoHudServer,
    enable_client_fn = EnableNoHudClient,
    disable_client_fn = DisableNoHudClient,
}
local no_hud_icon = {atlas = "images/reforged.xml", tex = "m_nohud.tex"}
local no_hud_exp = {desc = "NO_HUD", val = {add = RF_TUNING.EXP.MUTATORS.NO_HUD}}
AddMutator("no_hud", NoHudIsValidFN, no_hud_fns, nil, false, nil, nil, no_hud_icon, no_hud_exp, 2)
--------------------------------------------------------------------------
------------------- TODO petrify works on players?
-- Friendly Fire -- TODO make pets hurt players or vice versa? make players able to hurt themselves? like meteor?
------------------- TODO track friendly fire damage dealt and received?
_G.getmetatable(_G.TheNet).__index["GetPVPEnabled"] = function()
    return _G.REFORGED_SETTINGS.gameplay.mutators.friendly_fire
end
-- Allow players to attack each other without needing to "force attack"
AddComponentPostInit("playercontroller", function(self)
    local _oldGetAttackTarget = self.GetAttackTarget
    self.GetAttackTarget = function(self, force_attack, force_target, isretarget)
        force_attack = _G.TheNet:GetPVPEnabled() or force_attack
        return _oldGetAttackTarget(self, force_attack, force_target, isretarget)
    end
end)
local friendly_fire_icon = {atlas = "images/servericons.xml", tex = "pvp.tex"}
local friendly_fire_exp = {desc = "FRIENDLY_FIRE", val = {add = RF_TUNING.EXP.MUTATORS.FRIENDLY_FIRE}}
AddMutator("friendly_fire", nil, nil, nil, false, nil, nil, friendly_fire_icon, friendly_fire_exp, 3)
--------------------------------------------------------------------------
-------------
-- Endless --
-------------
-- Only get exp for completed rounds beyond the original waveset
local function EndlessExp()
    local lavaarenaevent = _G.TheWorld.components.lavaareneavent
    local rounds_completed_ratio = 0
    if lavaarenaevent and lavaarenaevent.total_rounds_completed > 0 then
        rounds_completed_ratio = math.max(math.floor(lavaarenaevent.total_rounds_completed / #lavaarenaevent.waveset_data) - 1, 0)
    end
    return {add = rounds_completed_ratio}
end
local mutators_per_set = {
    {no_hud = true},
    {friendly_fire = true},
    {no_sleep = true},
    {no_revives = true},
    general = {mob_damage_dealt = 0.1, mob_damage_received = 0.1, mob_speed = 0.02, mob_health = 0.1, battlestandard_efficiency = 0.1}, -- Mob stats are increased every set, but only half as much on even sets
}
-- Adjust mutators when a set of rounds has been completed
AddComponentPostInit("lavaarenaevent", function(self)
    self.endless_fn = function(sets_completed)
        local is_even = sets_completed%2 == 0
        local mutators = {}
        if mutators_per_set[sets_completed] then
            for mutator,val in pairs(mutators_per_set[sets_completed]) do
                mutators[mutator] = val
            end
        end
        -- Apply general mutator changes.
        for mutator,val in pairs(mutators_per_set.general) do
            --mutators[mutator] = _G.REFORGED_SETTINGS.gameplay.mutators[mutator] + val * (is_even and 0.5 or 1)
            mutators[mutator] = _G.REFORGED_SETTINGS.gameplay.mutators[mutator] + val
        end
        _G.TheWorld.net.components.mutatormanager:UpdateMutators(mutators)
    end
end)
local endless_icon = {atlas = "images/reforged.xml", tex = "m_endless.tex"}
local endless_exp = {desc = "ENDLESS", val = EndlessExp}
AddMutator("endless", nil, nil, nil, false, nil, nil, endless_icon, endless_exp, 1)
--------------------------------------------------------------------------
----------------
-- Duplicator --
----------------
local duplicator_colours = {
    {255/255, 255/255, 255/255, 1}, -- White
    {255/255,   0/255,   0/255, 1}, -- Red
    {  0/255, 255/255,   0/255, 1}, -- Green (Lime)
    {  0/255,   0/255, 255/255, 1}, -- Blue
    {  0/255,   0/255,   0/255, 1}, -- Black
    {255/255, 255/255,   0/255, 1}, -- Yellow
    {255/255,   0/255, 255/255, 1}, -- Fucsia
    {  0/255, 255/255, 255/255, 1}, -- Aqua
    {128/255, 128/255, 128/255, 1}, -- Grey
} -- TODO need a way of handling mobs that don't spawn at the same time. For instance, mobs that spawn on another mobs death, should inherit any dupe info, but currently the SetVariation event will not work in this case
local function ApplyDuplicatorMutatorToMob(inst, dupe_count, dupe_source)
	if inst.OnDuplicate then
		inst:OnDuplicate(dupe_count)
	else
		local i = (dupe_count - 1)%(#duplicator_colours) + 1
		inst.AnimState:SetHue(i/10)
		--inst.AnimState:SetHighlightColour(_G.unpack(duplicator_colours[i]))
		inst.duplicator_source = dupe_source
		inst.duplicator_count = i
		if inst.SetVariation and dupe_source then
			inst:ListenForEvent("variation_changed", function(source, data)
				inst:SetVariation(data.variation)
			end, dupe_source)
		end
	end	
end

local function DuplicatorExp(mutator_value)
    return {add = (mutator_value <= 0 or mutator_value == 1) and 0 or mutator_value}
end
local duplicator_mutator_fns = {
    apply_server_fn = ApplyDuplicatorMutatorToMob,
}
local duplicator_num_config = {min = 1, max = 10, step = 1, percent = false, suffix = "X", specific_values = {{text = "0.5X", data = 0.5}}}
local duplicator_icon = {atlas = "images/reforged.xml", tex = "mutator_duplicator.tex"} -- TODO icon
local duplicator_exp = {desc = "MOB_DUPLICATOR", val = DuplicatorExp}
AddMutator("mob_duplicator", nil, duplicator_mutator_fns, "slider", 1, duplicator_num_config, nil, duplicator_icon, duplicator_exp, 7)
--------------------------------------------------------------------------
