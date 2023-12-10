local pollen_assets = {
    Asset("ANIM", "anim/wormwood_pollen_fx.zip"),
}
local bloom_assets = {
    Asset("ANIM", "anim/wormwood_bloom_fx.zip"),
}
local pollen_cloud_assets = {
    Asset("ANIM", "anim/sporecloud.zip"),
    Asset("ANIM", "anim/sporecloud_base.zip"),
}
local amplify_assets = {
    Asset("ANIM", "anim/lavaarena_arcane_orb.zip"),
}
local crackle_assets = { -- TODO rename
    Asset("ANIM", "anim/lavaarena_hammer_attack_fx.zip"),
}
local forge_spear_assets = {
    Asset("ANIM", "anim/lavaarena_hits_variety.zip"),
}
local debuff_assets = {
    Asset("ANIM", "anim/lavaarena_sunder_armor.zip"),
}
local weaponspark_assets = {
    Asset("ANIM", "anim/lavaarena_hit_sparks_fx.zip"),
}
--------------------------------------------------------------------------
local amplify_prefabs = {
    "spellmasteryorbs",
}
local amplify_orb_prefabs = {
    "spellmasteryorb",
}
local crackle_prefabs = { -- TODO rename
    "forginghammer_cracklebase_fx", -- TODO rename
}
--------------------------------------------------------------------------
-- Need to call Remove as a function and not link the function location because the function is changed and the location is different.
local function RemoveFX(inst)
    inst:Remove()
end
--------------------------------------------------------------------------
local function CommonFXFN(bank, build) -- TODO put in common functions for modders?
    local inst = CreateEntity()
    COMMON_FNS.AddTags(inst, "FX", "NOCLICK")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = true
    ------------------------------------------
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    ------------------------------------------
    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build or bank)
    ------------------------------------------
    return inst
end

-- idle animation until the "out" animation
local function OnAnimOver(inst) -- TODO put in common functions for modders?
    if inst.AnimState:IsCurrentAnimation("out") then
        inst:Remove()
    else
        inst.AnimState:PlayAnimation("idle")
    end
end
--------------------------------------------------------------------------
-- BLOOM --
--------------------------------------------------------------------------
local function BloomFXFN()
    local fx = COMMON_FNS.FXEntityInit("wormwood_bloom_fx", nil, nil, {noanim = true, pristine_fn = function(fx)
        fx.AnimState:SetFinalOffset(2)
    end})
	------------------------------------------
    if not TheWorld.ismastersim then
        return fx
    end
    ------------------------------------------
    fx.OnSpawn = function(inst, data)
        if data and data.target then
            local target = data.target
            local stage = data.target.replica.passive_bloom:GetCurrentStage()
            local bloomed = stage and stage > 2
            if target.replica.rider ~= nil and target.replica.rider:IsRiding() then
                fx.Transform:SetSixFaced()
                fx.AnimState:PlayAnimation(bloomed and "poof_mounted" or "poof_mounted_less")
            else
                fx.Transform:SetFourFaced()
                fx.AnimState:PlayAnimation(bloomed and "poof" or "poof_less")
            end
            ------------------------------------------
            fx.Transform:SetPosition(target.Transform:GetWorldPosition())
            fx.Transform:SetRotation(target.Transform:GetRotation())
            ------------------------------------------
            local skin_build = string.match(inst.AnimState:GetSkinBuild() or "", "wormwood(_.+)") or ""
            skin_build = skin_build:match("(.*)_build$") or skin_build
            skin_build = skin_build:match("(.*)_stage_?%d$") or skin_build
            if skin_build:len() > 0 then
                fx.AnimState:OverrideSkinSymbol("bloom_fx_swap_leaf", "wormwood"..skin_build, "bloom_fx_swap_leaf")
            end
            data.target.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds", nil, .6)
        end
    end
    ------------------------------------------
    return fx
end
--------------------------------------------------------------------------
-- Pollen Cloud FX --
--------------------------------------------------------------------------
local function PollenCloudFXFN()
    local fx = COMMON_FNS.FXEntityInit("sporecloud", nil, "sporecloud_pre", {pristine_fn = function(fx)
        fx.AnimState:SetFinalOffset(2)
        ------------------------------------------
        fx.entity:AddSoundEmitter()
        if fx.SoundEmitter:PlayingSound("spore_loop") then
            fx.SoundEmitter:KillSound("spore_loop")
        end
        fx.SoundEmitter:PlaySound("dontstarve/creatures/together/toad_stool/spore_cloud_LP", "spore_loop")
    end})
	------------------------------------------
    if not TheWorld.ismastersim then
        return fx
    end
    ------------------------------------------
    fx.OnSpawn = function(inst, data)
        if data and data.target then
            local target = data.target
        end
    end
    ------------------------------------------
    return fx
end
--------------------------------------------------------------------------
-- AMPLIFY --
--------------------------------------------------------------------------
local function AmplifyFN()
    local fx = COMMON_FNS.FXEntityInit("lavaarena_arcane_orb", "lavaarena_arcane_orb", "anchor", {noanimover = true, anim_loop = true, pristine_fn = function(fx)
        fx.AnimState:SetLightOverride(1)
        fx.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    end})
	------------------------------------------
    if not TheWorld.ismastersim then
        return fx
    end
    ------------------------------------------
    fx.orbs = SpawnPrefab("spellmasteryorbs")
    ------------------------------------------
    fx.OnSpawn = function(inst, data)
        inst.orbs:SetTarget(data and data.target)
    end
    ------------------------------------------
    fx.RemoveFX = function(inst)
        inst.orbs:RemoveOrbsFX()
        inst.orbs = nil
        inst:Remove()
    end
    ------------------------------------------
    return fx
end
--------------------------------------------------------------------------
local function AmplifyOrbFN()
    local fx = COMMON_FNS.FXEntityInit("lavaarena_arcane_orb", "lavaarena_arcane_orb", "in", {noanimover = true, anim_loop = true, pristine_fn = function(fx)
        fx.entity:AddSoundEmitter()
        fx.entity:AddFollower()
        ------------------------------------------
        fx.Transform:SetEightFaced()
        ------------------------------------------
        fx.AnimState:PushAnimation("idle")
    end})
    ------------------------------------------
    return fx
end
--------------------------------------------------------------------------
local orb_update_time = 0.1 -- TOO small?
local remove_orb_delay = 0.1
local function AmplifyOrbsFN()
    local fx = CreateEntity()
    fx.entity:AddFollower()
    fx.entity:AddSoundEmitter()
    fx:AddTag("FX")
    ------------------------------------------
    fx.entity:SetPristine()
    ------------------------------------------
    if not TheWorld.ismastersim then
        return fx
    end
    ------------------------------------------
    -- Attach Orbs to player
    fx.SetTarget = function(inst, target)
        local max_orbs = 3
        inst.target = target
        -- Create each orb
        inst.orbs = {}
        for i = 1, max_orbs, 1 do
            inst.orbs[i] = SpawnPrefab("spellmasteryorb") -- Starting rotations: 119, 239, 359
            inst.orbs[i].current_degree = 360 / max_orbs * i - 1 -- Needs to range from 0 to 359 for mod division
            local set = inst.OrbPositions[inst.orbs[i].current_degree]
            local current_x = set[1]
            local current_y = set[2]
            -- Attach Orb to player
            inst.orbs[i].Follower:FollowSymbol(target.GUID, "torso", current_x, current_y + 100, current_y / 100)
            target.SoundEmitter:PlaySound("dontstarve/common/lava_arena/spell/start_light_orb")
        end

        -- Start rotating orbs
        inst.Rotating = inst:DoPeriodicTask(orb_update_time, inst.RotateOrbs, nil, inst)

        -- Play orb idle loop
        if target.SoundEmitter:PlayingSound("orb_loop") then
            target.SoundEmitter:KillSound("orb_loop")
        end
        target.SoundEmitter:PlaySound("reforge/sfx/loop_light_orb_LP", "orb_loop")--"dontstarve/common/lava_arena/spell/loop_light_orb_LP", "orb_loop")
        --target.SoundEmitter:PlaySound("dontstarve/common/lava_arena/spell/loop_light_orb_LP", "orb_loop")
        target.SoundEmitter:SetVolume("orb_loop", 0.35)
    end
    ------------------------------------------
    -- Create a lookup table of orb positions for each degree
    fx.GenerateOrbPositions = function()
        local orb_positions = {}
        local distance = 100
        for i = 0, 359, 1 do -- Needs to range from 0 to 359 for mod division
            local radian = i * (math.pi / 180)
            local x = distance * math.cos(radian)
            local y = distance / 2 * math.sin(radian)
            orb_positions[i] = {x, y}
        end
        return orb_positions
    end
    fx.OrbPositions = fx:GenerateOrbPositions()
    ------------------------------------------
    -- Rotate each orb 2 degrees
    fx.RotateOrbs = function(inst)
        -- Rotate each orb
        for i, orb in pairs(inst.orbs) do
            -- Force degree to be between 0 and 360
            orb.current_degree = (orb.current_degree + 2) % 360 -- TODO 0 is not in the position list
            -- Update orbs offset
            local set = inst.OrbPositions[orb.current_degree]
            local current_x = set[1]
            local current_y = set[2]
            orb.Follower:SetOffset(current_x, current_y + 100, current_y/100)
        end
    end
    ------------------------------------------
    fx.RemoveOrbsFX = function(inst)
        -- Stop playing orb idle loop
        inst.target.SoundEmitter:KillSound("orb_loop") -- TODO test this, was inst but now is target, might fix the issue ex talked about
        -- Remove each orb
        for i, orb in pairs(inst.orbs) do
            orb:DoTaskInTime(remove_orb_delay * (i - 1), function(inst)
                inst.AnimState:PlayAnimation("out")
                inst.SoundEmitter:PlaySound("dontstarve/common/lava_arena/spell/stop_light_orb") -- TODO sound plays on target
                inst:ListenForEvent("animover", RemoveFX)
            end)
            orb = nil
        end
        inst:Remove()
    end
    ------------------------------------------
    return fx
end
--------------------------------------------------------------------------
-- BATTLECRY --
--------------------------------------------------------------------------
local function RemoveBattleCryFX(inst)
    -- idle animation until the "out" animation
    if inst.AnimState:IsCurrentAnimation("out") then
        inst:Remove()
    else
        inst.AnimState:PlayAnimation("idle")
    end
end
local function MakeBattleCry(name, build, scale, offset)
    local assets = {
        Asset("ANIM", "anim/"..build..".zip"),
    }
    --------------------------------------------------------------------------
    local function SetTarget(inst, target)
        inst.Follower:FollowSymbol(target.GUID, "torso", offset, offset, 1)
        target.SoundEmitter:PlaySound("dontstarve/common/lava_arena/spell/battle_cry")
    end
    --------------------------------------------------------------------------
    local function fn()
        local fx = COMMON_FNS.FXEntityInit(build, nil, "in", {remove_fn = RemoveBattleCryFX, pristine_fn = function(fx)
            --CommonFXFN(build)
            fx.entity:AddFollower()
            ------------------------------------------
            fx.AnimState:SetMultColour(.5, .5, .5, .5)
            ------------------------------------------
            fx.Transform:SetScale(scale, scale, scale)
        end})
		------------------------------------------
        if not TheWorld.ismastersim then
            return fx
        end
        ------------------------------------------
        -- Create Battle Cry icon for the given target
        fx.OnSpawn = function(inst, data)
            if data and data.target then
                inst.Follower:FollowSymbol(data.target.GUID, "torso", offset, offset, 1)
                data.target.SoundEmitter:PlaySound("dontstarve/common/lava_arena/spell/battle_cry")
            end
        end

        -- Remove the Battle Cry
        fx.RemoveFX = function(inst)
            -- Play ending animation of the Battle Cry
            inst.AnimState:PlayAnimation("out")
        end

        --fx:ListenForEvent("animover", OnAnimOver)
        ------------------------------------------
        return fx
    end
    --------------------------------------------------------------------------
    return Prefab(name, fn, assets)
end
--------------------------------------------------------------------------
-- SHOCK --
--------------------------------------------------------------------------
local function CrackleFN()
    local fx = COMMON_FNS.FXEntityInit("lavaarena_hammer_attack_fx", nil, "crackle_hit", {pristine_fn = function(fx)
        fx.entity:AddSoundEmitter()
        ------------------------------------------
        fx.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        fx.AnimState:SetFinalOffset(1)
    end})
	------------------------------------------
    if not TheWorld.ismastersim then
        return fx
    end
    ------------------------------------------
    fx.OnSpawn = function(inst, data)
        if data and data.target then
            local target_pos = data.target:GetPosition()
            inst.Transform:SetPosition(target_pos:Get())
            inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/hammer")
            local base_fx = COMMON_FNS.CreateFX("forginghammer_cracklebase_fx", data.target)
            base_fx.Transform:SetPosition(target_pos:Get())
        end
    end
    ------------------------------------------
    --fx:ListenForEvent("animover", fx.Remove)
    ------------------------------------------
    return fx
end
--------------------------------------------------------------------------
local function CrackleBaseFN()
    local fx = COMMON_FNS.FXEntityInit("lavaarena_hammer_attack_fx", "lavaarena_hammer_attack_fx", "crackle_projection", {pristine_fn = function(fx)
        fx.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        fx.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        fx.AnimState:SetLayer(LAYER_BACKGROUND)
        fx.AnimState:SetSortOrder(3)
        fx.AnimState:SetScale(1.5, 1.5)
        ------------------------------------------
        --fx:ListenForEvent("animover", fx.Remove)
    end})
    ------------------------------------------
    return fx
end

local function ElectricRemoveFN(inst)
    if inst.AnimState:IsCurrentAnimation("crackle_pst") then
        inst:Remove()
    end
end
--------------------------------------------------------------------------
local function ElectricFN() -- TODO need to attach to ent? for pitpigs their lunge is not stopped instantly so this fx could be behind them a few units. Should it be attached? spawned inside the stun state and the stimuli is passed through and checked there? set parent will attach to ent
    --local inst = COMMON_FNS.FXEntityInit("lavaarena_hammer_attack_fx", "lavaarena_hammer_attack_fx", "crackle_loop", {noanimover = true})
    local fx = COMMON_FNS.FXEntityInit("lavaarena_hammer_attack_fx", nil, "crackle_loop", {remove_fn = ElectricRemoveFN, pristine_fn = function(fx)
        fx.entity:AddSoundEmitter()
        ------------------------------------------
        fx.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        fx.AnimState:SetFinalOffset(1)
        fx.AnimState:SetScale(1.5, 1.5)
        --fx.AnimState:PlayAnimation("crackle_loop")
        fx.AnimState:PushAnimation("crackle_loop")
        fx.AnimState:PushAnimation("crackle_pst")
    end})
	------------------------------------------
    if not TheWorld.ismastersim then
        return fx
    end
    ------------------------------------------
    fx.OnSpawn = function(inst, data)
        local target = data and data.target
        if target then
            inst.Transform:SetPosition(target:GetPosition():Get())
            inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/electric")
            if target:HasTag("largecreature") or target:HasTag("epic") then
                inst.AnimState:SetScale(2, 2)
            end
        end
    end
    ------------------------------------------
    fx:ListenForEvent("animqueueover", function(inst) -- TODO is this used? can't remember if this is triggered
        --print("Removing Electric Shock")
        inst:Remove()
    end)
    ------------------------------------------
    return fx
end
--------------------------------------------------------------------------
-- ForgeSpearFX --
--------------------------------------------------------------------------
local function ForgeSpearFN()
    local fx = COMMON_FNS.FXEntityInit("lavaarena_hits_variety", nil, nil, {noanim = true, pristine_fn = function(fx)
        fx.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        fx.AnimState:SetFinalOffset(1)
    end})
	------------------------------------------
    if not TheWorld.ismastersim then
        return fx
    end
    ------------------------------------------
    fx.OnSpawn = function(inst, data)
        local target = data and data.target
        if target then
            inst.Transform:SetPosition(target:GetPosition():Get())
            inst.AnimState:PlayAnimation("hit_"..(target:HasTag("minion") and 1 or (target:HasTag("largecreature") and 3 or 2)))
            inst.AnimState:SetScale(target:HasTag("minion") and 1 or -1, 1)
        end
    end
    ------------------------------------------
    return fx
end
--------------------------------------------------------------------------
-- DEBUFF --
--------------------------------------------------------------------------
local function DebuffFN()
    local fx = COMMON_FNS.FXEntityInit("lavaarena_sunder_armor", nil, "pre", {noanimover = true, pristine_fn = function(fx)
        fx.entity:AddFollower()
        ------------------------------------------
        fx:AddTag("DECOR") --"FX" will catch mouseover
    end})
	------------------------------------------
    if not TheWorld.ismastersim then
        return fx
    end
    ------------------------------------------
    local symbols = {boarilla = "helmet", boarrior = "head", crocommander = "shell", pitpig = "helmet", scorpeon = "head", snortoise = "body"} --LEO, FIXITFIXITFIXITFIXIT!!!
    fx.OnSpawn = function(inst, data) -- TODO can't you set the parent and then the position will be based off the parent and attached to the parent?
        local target = data and data.target
        inst.owner = target
        if target then
            inst.entity:SetParent(target.entity)
        end
        local armorbreak_debuff = target.components.armorbreak_debuff
        local symbol = target and (armorbreak_debuff and armorbreak_debuff.followsymbol or symbols[target.prefab])
        if symbol then
            local follow_offset = armorbreak_debuff.followoffset or {-20, -150, 1}
            inst.Follower:FollowSymbol(target.GUID, symbol, follow_offset.x, follow_offset.y, follow_offset.z)
        else
            inst:Remove()
        end
    end
    ------------------------------------------
    fx:ListenForEvent("animover", function(inst)
        if (not inst.owner and not inst.AnimState:IsCurrentAnimation("pst")) or inst.AnimState:IsCurrentAnimation("pst") then
            inst:Remove()
        else
            inst.AnimState:PlayAnimation("loop")
        end
    end)
    ------------------------------------------
    return fx
end
--------------------------------------------------------------------------
-- WEAPON SPARKS --
--------------------------------------------------------------------------
local function WeaponSparksFN(inst, data) -- For melee weapons
    local target = data and data.target
    local source = data and data.source
    if target and source then
        local offset = (source:GetPosition() - target:GetPosition()):GetNormalized()*(target.Physics and target.Physics:GetRadius() or 1)
        offset.y = offset.y + 1 + math.random(-5, 5)/10
        inst.Transform:SetPosition((target:GetPosition() + offset):Get())
        inst.AnimState:PlayAnimation("hit_3")
        inst.AnimState:SetScale(source:GetRotation() > 0 and -.7 or .7,.7)
    end
end

local function PiercingWeaponSparksFN(inst, data) -- For projectile weapons
    local target = data and data.target
    local source = data and data.source
    if target and source then
        local offset = (source:GetPosition() - target:GetPosition()):GetNormalized()*(target.Physics and target.Physics:GetRadius() or 1)
        offset.y = offset.y + 1 + math.random(-5, 5)/10
        inst.Transform:SetPosition((target:GetPosition() + offset):Get())
        inst.AnimState:PlayAnimation("hit_3")
        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        inst.Transform:SetRotation(inst:GetAngleToPoint(target:GetPosition():Get()) + 90)
    end
end

local spark_offset_mult = 0.25 -- TODO need to check this to make sure it matches what we had before
local function ThrustingWeaponSparksFN(inst, data) -- For Maxwell's shadow puppets
    local target = data and data.target
    local source = data and data.source
    if target and source then
        local offset = (source:GetPosition() - target:GetPosition()):GetNormalized()*(target.Physics and target.Physics:GetRadius() or 1)
        offset.y = offset.y + 1 + math.random(-5, 5)/10
        inst.Transform:SetPosition((target:GetPosition() + offset):Get())
        inst.AnimState:PlayAnimation("hit_3")
        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        inst.Transform:SetRotation(inst:GetAngleToPoint(target:GetPosition():Get()) + 90)
    end
end

local function BouncingWeaponSparksFN(inst, data) -- For missing with Lucy
    local target = data and data.target
    if target then
        inst.Transform:SetPosition(target:GetPosition():Get())
        inst.AnimState:PlayAnimation("hit_2")
        inst.AnimState:Hide("glow")
        inst.AnimState:SetScale(target:GetRotation() > 0 and 1 or -1, 1)
    end
end

local function MakeWeaponSparks(name, fxfn)
    local function fn()
        local fx = COMMON_FNS.FXEntityInit("hits_sparks", "lavaarena_hit_sparks_fx", nil, {noanim = true, pristine_fn = function(fx)
            fx.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
            fx.AnimState:SetFinalOffset(1)
            --Delay one frame so that we are positioned properly before starting the effect
            --or in case we are about to be removed
            --inst:DoTaskInTime(0, fxfn) -- TODO should we do this too? not sure...hmmm...
        end})
		------------------------------------------
        if not TheWorld.ismastersim then
            return fx
        end
        ------------------------------------------
        fx.OnSpawn = fxfn
        ------------------------------------------
        return fx
    end

    return Prefab(name, fn, weaponspark_assets)
end
--------------------------------------------------------------------------
local function TimeBreakFN()
    local fx = COMMON_FNS.FXEntityInit("beetletaur_break", "lavaarena_beetletaur_break", "anim", {pristine_fn = function(fx)
    	fx.entity:AddSoundEmitter()
        ------------------------------------------
        fx.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        fx.AnimState:SetFinalOffset(2)
        ------------------------------------------
    	fx.SoundEmitter:PlaySound("dontstarve/creatures/slurtle/shatter")
        ------------------------------------------
        fx:ListenForEvent("animover", fx.Remove)
    end})
    ------------------------------------------
    return fx
end
-- Bloom
return Prefab("bloom_fx", BloomFXFN, bloom_assets),
    Prefab("pollen_cloud_fx", PollenCloudFXFN, pollen_cloud_assets),
    -- Amplify
    Prefab("amplify_fx", AmplifyFN, amplify_assets, amplify_prefabs),
    Prefab("spellmasteryorb", AmplifyOrbFN, amplify_assets),
    Prefab("spellmasteryorbs", AmplifyOrbsFN, nil, amplify_orb_prefabs),
    -- BattleCry
    MakeBattleCry("battlecry_fx_self", "lavaarena_attack_buff_effect", 1.4, 0),
    MakeBattleCry("battlecry_fx_other", "lavaarena_attack_buff_effect2", 1, 1),
    -- Electrocute
    Prefab("forginghammer_crackle_fx", CrackleFN, crackle_assets, crackle_prefabs),
    Prefab("forginghammer_cracklebase_fx", CrackleBaseFN, crackle_assets),
    Prefab("forge_electrocute_fx", ElectricFN, crackle_assets),
    -- ForgeSpear
    Prefab("forgespear_fx", ForgeSpearFN, forge_spear_assets),
    -- Debuff
    Prefab("forgedebuff_fx", DebuffFN, debuff_assets),
	Prefab("rf_timebreak_fx", TimeBreakFN),
    -- WeaponSparks
    MakeWeaponSparks("weaponsparks_fx", WeaponSparksFN),
    MakeWeaponSparks("weaponsparks_piercing_fx", PiercingWeaponSparksFN),
    MakeWeaponSparks("weaponsparks_thrusting_fx", ThrustingWeaponSparksFN),
    MakeWeaponSparks("weaponsparks_bouncing_fx", BouncingWeaponSparksFN)
