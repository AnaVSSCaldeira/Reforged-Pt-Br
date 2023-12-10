local RF_DATA = _G.REFORGED_DATA
RF_DATA.modes = {}
function AddMode(name, fns, icon, order_priority, reset) -- TODO what does this need?
    if RF_DATA.modes[name] then
        _G.Debug:Print("Attempted to add the mode '" .. tostring(name) .."', but it already exists.", "error")
        return
    end
    RF_DATA.modes[name] = {
        fns  = fns or {},
        icon = icon, -- {atlas = ".xml", tex = ".tex"}
        order_priority = order_priority or 999,
        --reset = true,
    }
end
_G.AddMode = AddMode
--------------------------------------------------------------------------
--------------------
-- Forge Season 1 --
--------------------
local function SetBanner(inst)
    local wave = _G.TheWorld.components.lavaarenaevent
    return wave and wave.current_round_data and wave.current_round_data.banner or _G.UTIL.WAVESET.defaultbanner() or "battlestandard_heal"
end
local forge_s01_icon = {atlas = "images/reforged.xml", tex = "forge_s1_icon.tex"}
local forge_s01_fns = {
    -- Boarillas do not roll
    boarilla = function(inst)
        ------------------------------------------
        if not _G.TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------
        inst.classic = true -- used for roll selection
    end,
    -- Banners are set per round so both Boarrior and Crocs spawn the same banner in the last round.
    boarrior = function(inst)
        ------------------------------------------
        if not _G.TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------
        inst.components.combat:SetAttackOptions("reinforcements", {banner_opts = {prefab = SetBanner}})
    end,
}
AddMode("forge_s01", forge_s01_fns, forge_s01_icon, 1)
--------------------------------------------------------------------------
--------------------
-- Forge Season 2 --
--------------------
--[[
Banners are randomized via
New item drops
--]]
local forge_s02_icon = {atlas = "images/reforged.xml", tex = "forge_icon.tex"}
local forge_s02_fns = {
    -- Boarillas now roll
    boarilla = function(inst)
        ------------------------------------------
        if not _G.TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------
        inst.classic = false -- TODO this is technically default
    end,
}
AddMode("forge_s02", forge_s02_fns, forge_s02_icon, 2)
--------------------------------------------------------------------------
--------------
-- ReForged --
--------------
--[[
Lucy interrupts
    currently tracks if you interrupt any part of the attack state...need to make it so it tracks if you interrupt before the attack does damage....hmmm, different from attack to attack, any way to differentiate it?
    changed to use "pre_attack" tag check need to figure out how spinning and rolling should be counted as interrupted. And need to add tag to swine, the combos for him might be annoying to add interrupt checks accurately...
Server Leaderboard
    endless
    sort by
        time
        waves completed
--]]
_G.TUNING.FORGE.STAT_CATEGORIES["parry_counter"] = {category = "defense", priority = 6,}
_G.TUNING.FORGE.STAT_CATEGORIES["perfect_parry_counter"] = {category = "defense", priority = 6,}
_G.STRINGS.UI.MVP_LOADING_WIDGET.LAVAARENA.DESCRIPTIONS.parry_counter = "damage reflected"
_G.STRINGS.UI.MVP_LOADING_WIDGET.LAVAARENA.DESCRIPTIONS.perfect_parry_counter = "perfect parries"
local reforged_fns = {
    wolfgang = function(inst)
        if not _G.TheWorld.ismastersim then
            return inst
        end
        inst:DoTaskInTime(0, function(inst) --Leo: Pretty sure this runs before the component gets added, so delay time.
            if inst.components.passive_mighty then
                inst.components.passive_mighty.duration = 20 --seconds
            end
        end)
    end,
    -- Abigails attacks apply the Haunt Debuff.
    forge_abigail = function(inst)
        ------------------------------------------
        if not _G.TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------
        inst:ListenForEvent("onhitother", function(inst, data)
            if data.target and data.target.components.debuffable then
                data.target.components.debuffable:AddDebuff("debuff_haunt", "debuff_haunt")
            end
        end)
    end,
    -- TODO play a sound that signifies a perfect parry? need to find sound that fits
    -- Perfect Parry: Parrying at the same time as an enemies attack will reflect the damage back to the attacker
    blacksmithsedge = function(inst)
        ------------------------------------------
        if not _G.TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------
        _G.TheWorld.components.stat_tracker:AddStat("parry_counter")
        _G.TheWorld.components.stat_tracker:AddStat("perfect_parry_counter")
        ------------------------------------------
        local PARRY_BUFFER = 10*_G.FRAMES
        local function OnAttacked(player, data)
            --inst.sg:HasStateTag("parrying") and inst.components.combat.redirectdamagefn and inst.components.combat.redirectdamagefn(player, data.attacker, data.damage, data.weapon, data.stimuli)
            --if inst.components.parryweapon:TryParry(player, data.attacker, data.damage, data.weapon, data.stimuli) then
            player:DoTaskInTime(_G.FRAMES, function()
                if player.sg:HasStateTag("parrying") then
                    if data.attacker and data.attacker.components.combat then
                        local reflected_damage = (data.damage or 0) / 2
                        data.attacker.components.combat:GetAttacked(player, reflected_damage, inst, "strong")
                        _G.TheWorld.components.stat_tracker:AdjustStat("parry_counter", player, reflected_damage)
                    end
                    if not inst.perfect_parry then
                        inst.components.rechargeable.recharge = (180 - inst.components.rechargeable.recharge) / 2 + inst.components.rechargeable.recharge
                        inst:PushEvent("rechargechange", {percent = inst.components.rechargeable.recharge and inst.components.rechargeable.recharge / 180, overtime = false})
                        _G.TheWorld.components.stat_tracker:AdjustStat("perfect_parry_counter", player, 1)
                        inst.perfect_parry = true
                    end
                end
            end)
        end
        local _oldOnParry = inst.components.aoespell.aoe_cast
        inst.components.aoespell.aoe_cast = function(inst, caster, pos)
            _oldOnParry(inst, caster, pos)
            inst.perfect_parry = nil
            inst.parry_start_time = _G.GetTime()
            caster:ListenForEvent("attacked", OnAttacked)
            caster:DoTaskInTime(PARRY_BUFFER, function(player)
                player:RemoveEventCallback("attacked", OnAttacked)
            end)
        end
    end,
    -- Healing Aura scales directly based on healing power.
    healingcircle_bloom = function(inst)
        ------------------------------------------
        if not _G.TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------
        local _oldStart = inst.Start
        inst.Start = function(inst)
            _oldStart(inst)
            local scale_per_additional_heal_rate = 0.1
            local max_scale = 1 + scale_per_additional_heal_rate * (inst.heal_rate - TUNING.FORGE.LIVINGSTAFF.HEAL_RATE)
            local scale = (math.random((max_scale - scale_per_additional_heal_rate / 2)*100, max_scale*100) + math.random())/100
            inst.components.scaler:SetBaseScale(scale)
            inst.components.scaler:ApplyScale()
        end
    end,
}
local reforged_icon = {atlas = "images/reforged.xml", tex = "reforged_icon.tex"}
AddMode("reforged", reforged_fns, reforged_icon, 3)
--------------------------------------------------------------------------
------------------
-- Forged Forge --
------------------
--[[
Recreates the attack behavior of Forged Forge mobs
--]]
local function ShieldCheck(inst)
    if not inst.isguarding and inst.components.health:GetPercent() < 0.9 and (inst.components.combat.laststartattacktime + 8) < _G.GetTime() then
        inst:PushEvent("entershield")
    end
end
local forged_forge_fns = {
    swineclops = function(inst)
        ------------------------------------------
        if not _G.TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------
        inst:SetStateGraph("SGswineclops_ff")
        inst.altattack = true
        inst.is_enraged = false
        inst.currentcombo = 0
        inst.maxpunches = 1
        inst.shieldtime_end = true

        inst:ListenForEvent("healthdelta", function(inst)
            local health = inst.components.health:GetPercent()
            if health > 0.9 then
                inst.maxpunches = 1
            elseif health >  0.7 and health <= 0.9 then
                inst.maxpunches = 2
            elseif health > 0.5 and health <= 0.7 then
                inst.maxpunches = 5
            elseif health > 0.25 and health <= 0.5 then
                inst.maxpunches = 7
            elseif health <= 0.25 then
                inst.maxpunches = 998
            end

        end)
        -- Remove health triggers from ReForged Swine
        local tuning_values = TUNING.FORGE.SWINECLOPS
        inst.components.healthtrigger:RemoveTrigger(tuning_values.ATTACK_MODE_TRIGGER)
        inst.components.healthtrigger:RemoveTrigger(tuning_values.ATTACK_AND_GUARD_MODE_TRIGGER)
        inst.components.healthtrigger:RemoveTrigger(tuning_values.COMBO_2_TRIGGER)
        inst.components.healthtrigger:RemoveTrigger(tuning_values.INFINITE_COMBO_TRIGGER)
        inst:DoTaskInTime(5, function(inst)
            inst:PushEvent("entershield")
        end)
        inst:DoPeriodicTask(1, ShieldCheck)
    end,
}
local forged_forge_icon = {atlas = "images/reforged.xml", tex = "forged_forge_icon.tex"}
AddMode("forged_forge", forged_forge_fns, forged_forge_icon, 4)
--------------------------------------------------------------------------
