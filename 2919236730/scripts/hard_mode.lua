--[[
TODO
Petrification time is decreased for all mobs?
Mobs take longer to sleep?
ingame chat enhancements
    scrollable chat
    larger memory
death check onallmobsdead delay for 1 second? onallmobs dead does not pass if stuff is spawning or if mobs alive
change boarrior to have longer reinforcements cooldown for crocs but the same for pit pigs
snortoise reflect limit
--]]
--[[
TODO
    need better initial offset
        currently it's spawning too far behind the snortoise
    better spot to do this?
        the hide state?
    should it multiply the damage reflected?
        probably should?
    Damage stat tracking does not track correctly with this.
    have projectiles actively seek out bunkered snortoise and once it hits 3 send back to attacker?
--]]
local MAX_REFLECTS = 3000
-- Reflects damage back to attacker when Bunkered. If attack is a projectile then the projectile is reflected.
local function BunkerReflect(inst)
    inst:ListenForEvent("attacked", function(inst, data)
        -- Does not redirect or reflect attacks that stun.
        if inst.sg:HasStateTag("hiding") and not _G.TUNING.FORGE.STUN_STIMULI[data.stimuli] then
            -- Redirect projectiles (except for Lucy and stun attacks)
            if data.projectile and data.weapon and data.weapon.prefab ~= "riledlucy" and not data.projectile.components.complexprojectile then -- and (not data.projectile.count or data.projectile.count < MAX_REFLECTS)
                local projectile = _G.SpawnPrefab(data.weapon and data.weapon.components.weapon.projectile or data.projectile.prefab)
                local pos = inst:GetPosition()
                local attacker_pos = data.attacker:GetPosition()
                local angle_variation = (inst.sg:HasStateTag("spinning") and 180 or 60) / 2
                local angle = -inst:GetAngleToPoint(attacker_pos)*_G.DEGREES + math.random(-angle_variation,angle_variation)*_G.DEGREES
                local offset = _G.Point(math.cos(angle), 0, math.sin(angle))
                projectile.Transform:SetPosition((pos + offset*2):Get())
                projectile.components.projectile.ignore_tags = {} -- Allows all entities to be hit
                projectile.components.projectile:AimedThrow(data.weapon, inst, pos + offset*10, data.damage, true)
                --projectile.count = (data.projectile.count or 0) + 1
            -- Reflect non projectile damage back to attacker
            elseif not data.projectile and not (data.attacker and data.attacker.sg and data.attacker.sg:HasStateTag("hiding")) then
                data.attacker.components.combat:GetAttacked(data.attacker, data.damage, data.weapon, data.stimuli)
            end
        end
    end)
end

local SCORPEON_POISON_BOMB_TRIGGER = 0.5
local function PoisonBombTrigger(inst)
    inst.components.healthtrigger:RemoveTrigger(SCORPEON_POISON_BOMB_TRIGGER)
    inst.components.combat:ToggleAttack("spit_bomb")
    --inst.sg:GoToState("taunt") -- TODO should this be handled in idle? as in queue it?
    inst.sg.mem.wants_to_taunt = true
end

local _W = _G.UTIL.WAVESET
-- TODO common function?
-- Leashes all pitpigs to the first croc on each spawner
-- croc leader can also be passed
local function LeashPitpigsToCrocs(spawnedmobs, croc)
    for i,mob_list in pairs(spawnedmobs or {}) do
        local mobs = _W.OrganizeMobs(mob_list)
        if mobs then
            _W.LeashMobs(croc or mobs.crocommander and mobs.crocommander[1], mobs.pitpig)
        end
    end
end
local croc_wave = {
    name = "crocs",
    mob_spawns = _W.SetSpawn({_W.CreateSpawn(_W.CombineMobSpawns(_W.CreateMobSpawnFromPreset("triangle", _W.CreateMobList(_W.RepeatMob("pitpig", 3))), {{{"crocommander"},}})), {1,3}}),
    onspawningfinished = function(self, spawnedmobs, leader)
        LeashPitpigsToCrocs(spawnedmobs, leader)
    end,
}
local snortoise_wave = {
    name = "snorts",
    mob_spawns = _W.SetSpawn({_W.CreateSpawn(_W.CreateMobSpawnFromPreset("square", _W.CreateMobList(_W.RepeatMob("snortoise", 4)))), {1,2,3}}),
    onspawningfinished = function(self, spawnedmobs, leader)
        LeashPitpigsToCrocs(spawnedmobs, leader)
    end,
}

-- ThePlayer.bro1 = c_select()
-- ThePlayer.bro1.bro = ThePlayer.bro2 ThePlayer.bro2.bro = ThePlayer.bro1
local function Rhinocebro(inst, alt)
    inst.AnimState:SetBuild("lavaarena_rhinodrill_hardmode")
	if alt then
        inst.AnimState:AddOverrideBuild("lavaarena_rhinodrill_clothed_hardmode")
    end
    ------------------------------------------
    if not _G.TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    inst.heat = 0
    inst.damagedtype = "_hardmode"
    ------------------------------------------
    inst:SetStateGraph("SGrhinocebro_hard")
    inst:SetBrain(require("brains/rhinocebrobrain_hard"))
    ------------------------------------------
    local MAX_HEAT = 300 -- 10 seconds
    local MAX_HEAT_DISTANCE = 12
    local function IsAsleep(inst)
        return inst.components.sleeper:IsAsleep() or inst.bro.components.sleeper:IsAsleep()
    end
    local function IsFossilized(inst)
        return inst.components.fossilizable:IsFossilized() or inst.bro.components.fossilizable:IsFossilized()
    end
    local function IsCloseToBro(inst)
        local pos = inst:GetPosition()
        local bro_pos = inst.bro:GetPosition()
        local distance_to_bro = distsq(pos, bro_pos)
        return distance_to_bro <= MAX_HEAT_DISTANCE*MAX_HEAT_DISTANCE
    end
    inst:DoPeriodicTask(0, function()
        if inst.bro then
            -- Increase heat only when Rhinocebros are near each other and neither one are cc'd
            if not (IsAsleep(inst) or IsFossilized(inst)) and IsCloseToBro(inst) then
                inst.heat = math.min(MAX_HEAT, (inst.heat or 0) + 1)
            -- Decrease heat if not near each other
            else
                inst.heat = math.max(0, (inst.heat or 0) - 1)
            end
            -- Make the Rhinocebro more red based on current heat
            if inst.heat < MAX_HEAT then
                inst.components.colouradder:PushColour("rhino_heat", inst.heat/MAX_HEAT, 0, 0, 1)
            end
        end
    end)
end

local hard_mode_fns = {
    -- Lucy does not return to Woodie if he misses. -- TODO add lucy dialog for missing?
    riledlucy = function(inst)
        ------------------------------------------
        if not _G.TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------
        local _oldOnMiss = inst.components.projectile.onmiss
        local function OnMiss(inst, attacker, target)
            inst.no_return = true
            _oldOnMiss(inst, attacker, target)
        end
        inst.components.projectile:SetOnMissFn(OnMiss)
    end,
    --[[
    TODO
        Fire Dash
            leaves fire down
                possibly on fire debuff
        dashes 3 times in a row?
            OR
        Maybe keeps dashing until target is killed or misses?
            each dash increases in strength
            a trail starts to form on each dash as it gets more powerful
            3 in a row reaches max damage?
            maybe have 3 dashes be the max?
        knockback?
        Need to add trail fx to indicate more powerful dash?
    --]]
    pitpig = function(inst)
        ------------------------------------------
		inst.AnimState:SetBuild("lavaarena_boaron_hardmode")
		------------------------------------------
        if not _G.TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------
        inst:SetStateGraph("SGpitpig_hard")
        inst:SetPhysicsRadiusOverride(0.5)
        ------------------------------------------
        local ATTACK_KNOCKBACK = 1
        inst.components.combat.onhitotherfn = function(inst, target)
            if inst.sg.mem.dashing then -- TODO use state tag checks? could probably once collision is no longer used
                _G.COMMON_FNS.KnockbackOnHit(inst, target, 5, ATTACK_KNOCKBACK, ATTACK_KNOCKBACK, true) -- TODO tuning
            end
        end
    end,
    --[[
    TODO
        Rapid Fire
        All in one banner
            does all 3 banner buffs
            more health than a banner, 90?
        Pitpig wave summon

        need to keep track of the spawner the croc spawned from to determine where the 3 pitpigs spawn
        need to figure out if the banner summon is a trigger on all/most mobs killed or a cooldown?
            1 pitpig left makes it available?
                both a timer and a 1 pitpig check
            pitpigs and banners are separate?
    --]]
    crocommander = function(inst)
		------------------------------------------
		inst.AnimState:SetBuild("lavaarena_snapper_hardmode")
        ------------------------------------------
        if not _G.TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------
        local tuning_values = TUNING.FORGE.CROCOMMANDER
        inst:SetStateGraph("SGcrocommander_hard")
        ------------------------------------------
        inst.weapon.attack_period = tuning_values.SPIT_ATTACK_PERIOD / 2 -- twice as fast as normal crocommander
        ------------------------------------------
        -- TODO change to use one banner that is the all in one banner?
        inst.components.combat:SetAttackOptions("banner", {max_banners = 4, banners = {"battlestandard_heal", "battlestandard_shield", "battlestandard_damager", "battlestandard_speed"}})
        ------------------------------------------
        inst.components.combat:AddAttack("reinforcements", false, 30)
        ------------------------------------------
        inst.reinforcements = {
            wave = {
                name = "croc_reinforcements",
                mob_spawns = _W.SetSpawn({_W.CreateSpawn(_W.CreateMobSpawnFromPreset("triangle", _W.CreateMobList(_W.RepeatMob("pitpig", 3)))), {inst.spawn_info and inst.spawn_info.spawn_portal or 1}}),
                onspawningfinished = function(self, spawnedmobs, leader)
                    LeashPitpigsToCrocs(spawnedmobs, inst or leader)
                    inst.components.combat:ToggleAttack("reinforcements", false)
                end,
            },
            cooldown = 30,
            min_followers = 1,
            isready_fn = function(inst)
                return inst.components.combat:IsAttackReady("reinforcements")
            end,
        }
        inst.reinforcements_queued = false
        local _oldRemoveFollower = inst.components.leader.RemoveFollower
        inst.components.leader.RemoveFollower = function(self, ...)
            _oldRemoveFollower(self, ...)
            -- Reset Reinforcements if there are 1 or less followers remaining
            if not inst.components.combat:IsAttackActive("reinforcements") and inst.reinforcements.min_followers and self.numfollowers <= inst.reinforcements.min_followers then
                inst.components.combat:ToggleAttack("reinforcements", true)
                _G.RemoveTask(inst.reinforcements_cooldown_timer)
            end
        end
        -- Initialize Reinforcements if Crocommander does not spawn with followers.
        inst:DoTaskInTime(0, function(inst)
            if inst.reinforcements.min_followers and inst.components.leader.numfollowers <= inst.reinforcements.min_followers then
                inst.components.combat:ToggleAttack("reinforcements", true)
            elseif not inst.components.combat:IsAttackReady("reinforcements") then
                inst.components.combat:StartCooldown("reinforcements")
            end
        end)
    end,
    --[[
    TODO
        Snortoise spin in a circle together around a unified target, and attack one after another.
        How many attack at once?
            based on total number?
        make circle large enough so anvil strike can't hit them all
        make it large enough so when 1 charges in the player has time to react
        What if only 1 snortoise? should it do regular spin?
        can modify attack_grp_size as a function, think this determines how many attack at once

        size of circle changes based on the amount of snortoise?
            layered circles?
                OrganizeTeam does this

        maybe increase speed when in ATTACK and then revert back to have a nice smooth circle?
            set a variable to the desired speed and that is used in the SG

        need to get it to update teams if one team finishes early?
            so the middle ring should send 3 members to be in team 1
            if the first ring is not maxed then organize teams should move 1 member to it.
        Should all snortoises start spinning?
    --]]
    snortoise = function(inst)
        ------------------------------------------
		inst.AnimState:SetBuild("lavaarena_turtillus_hardmode")
        ------------------------------------------
        if not _G.TheWorld.ismastersim then
            return inst
        end
		inst.Transform:SetScale(1, 1, 1)
        ------------------------------------------
        inst.components.locomotor.runspeed = 20
        ------------------------------------------
        inst:AddComponent("teamattacker")
        inst.components.teamattacker.team_type = "snortoise"
        ------------------------------------------
        BunkerReflect(inst)
        ------------------------------------------
        inst:SetStateGraph("SGsnortoise_hard")
    end,
    --[[
    TODO
        Barrage of Poison
            shoots 3? poison back to back updating the targets position for each thrown
        Poison explodes into tiny poison projectiles on impact (similar to borderlands baby grenade thingy)?
        Hook melee attack? using hands for hooks.
            locks player in place for a second?
        Poison Spell
            put players to sleep?
        Change poison effect

        Melee/range mode, range mode is just poison lobs
            no modes? just make it range based?
        while in melee range the new poison attack is poison variant of meteor

        Poison Bomb triggers on half health
            which applies a poisoned area for 10 seconds
            permanent poison debuff on attack
            Poison Trail when walking
            Create follow symbol on hand that is a poison projectile?
    --]]
    scorpeon = function(inst)
		inst.AnimState:SetBuild("lavaarena_peghook_hardmode")
        ------------------------------------------
        if not _G.TheWorld.ismastersim then
            return inst
        end
		inst.Transform:SetScale(1, 1, 1)
        ------------------------------------------
        inst:SetStateGraph("SGscorpeon_hard")
        ------------------------------------------
        inst.components.combat:AddAttack("spit_bomb", false, 30)
        ------------------------------------------
        inst.components.healthtrigger:AddTrigger(SCORPEON_POISON_BOMB_TRIGGER, PoisonBombTrigger)
    end,
    --[[
    TODO
        Roll Slam
            Rolls away from target then turns around and rolls toward target increasing speed until a set distance away from target, then does a large jump to slam the target, doing a lot of damage, and large aoe similar in size to Swineclops Tantrum.
        Bunker
            Same as Snortoise
        Basic Attack
            Causes armor break debuff on target, x% extra damage on that target
        Slam
            Slams the ground creating ?fissure? and much larger aoe attack
            Fissures do damage when walked on
        Roll
            Spawns mini fissures as it rolls
    --]]
    boarilla = function(inst)
        ------------------------------------------
        if not _G.TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------
        inst:SetStateGraph("SGboarilla_hard")
        inst.physics_options = {pass_through_small_obstacles = true} -- used to help prevent knocking players out of bounds
        BunkerReflect(inst)
        local _oldOnHitOther = inst.components.combat.onhitotherfn
        inst.components.combat.onhitotherfn = function(inst, target)
            _oldOnHitOther(inst, target)
            if inst.sg.currentstate.name == "attack" and target and target.components.debuffable then
                target.components.debuffable:AddDebuff("debuff_armorbreak", "debuff_armorbreak")
            end
        end
    end,
    --[[
    TODO
        Spawns Pitpig waves with banners as a move not a health trigger
            should we add a delay before checking if all mobs are dead? find a way to be able to spawn enemies as the last mob of a wave?
        Spinning Top
            Should this be like boarilla roll? or is that too much?

    Banner Summon is now a periodic attack. Boarrior will initially summon Pitpigs, but as the fight nears its end Boarrior will summon a croc wave instead.
    Boarrior will summon an additional banner for every time Boarrior summoned banners (up to a max of 7).
    Boarrior now moves while doing the Spin attack.
    Boarrior increases the number of trails of the Slam attack by 1 after summoning banners for the first time.
    --]]
    boarrior = function(inst)
        ------------------------------------------
        if not _G.TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------
        local tuning_values = TUNING.FORGE.BOARRIOR
        inst:SetStateGraph("SGboarrior_hard")
        ------------------------------------------
        inst.components.combat:SetCooldown("reinforcements", 30)
        ------------------------------------------
        inst.components.healthtrigger:AddTrigger(tuning_values.PHASE3_TRIGGER, function(inst)
            inst.components.healthtrigger:RemoveTrigger(tuning_values.PHASE3_TRIGGER)
            inst.components.combat:ToggleAttack("reinforcements", true)
            inst.components.combat:SetAttackOptions("slam", {trail_width = 3})
            inst.components.combat:SetAttackOptions("spin", {can_move = true})
        end) -- Spin Top, Slam, banner attack, change banner attack to not be forced triggered?
        inst.components.healthtrigger:AddTrigger(tuning_values.PHASE4_TRIGGER, function(inst)
            inst.components.healthtrigger:RemoveTrigger(tuning_values.PHASE4_TRIGGER)
            inst.components.combat:SetAttackOptions("reinforcements", {wave = croc_wave})
            inst.components.combat:SetCooldown("reinforcements", 45)
        end) -- Change mob spawns
        ------------------------------------------
    end,
    --[[
    TODO
    Buff
        triggers separately and buffs the other bro
            buff icon pops up on the other brother
        turn off cheer brain node
    Chest Bump
        large explosive aoe
            explosive_small_slurtlehole
            groundpound_ring
            need sound
        sizzle fx when ready? or when close to ready?
    --]]
    rhinocebro = function(inst)
        Rhinocebro(inst)
    end,
    rhinocebro2 = function(inst)
        Rhinocebro(inst, true)
    end,
    --[[
    TODO
    Baby Mode
    Punch
        tracks hits to target
        after x hits target is set on fire (debuff)
        hits are removed over time
            After a target is hit by a punch enough times they get the on fire debuff
            Hits are removed over time
    Jab Projectile Punch
        Targets random mid range target and does a punch projectile
    Body Slam
        Creates fissure. If enraged then creates a lava fissure
    Tantrum
        spawns geysers if enraged
            deals damage and knocks players back
            does not spawn within tantrum aoe
    Uppercut
        Creates flame trail when enraged that goes beyond the target player.
        Adds the fire debuff to any player that touches it.
    Tantrum Evolution
        Tantrums slowly creates geysers around swineclops as he becomes enraged
        hide lock symbol
            broke off

    use beargers pound fx for the ground????
    use different projectile
        infernalstaff fireball?
            make it bigger
    sound
        lava fissure
        uppercut trail
    --]]
    swineclops = function(inst)
		------------------------------------------
		inst.AnimState:SetBuild("lavaarena_beetletaur_hardmode")
        ------------------------------------------
        if not _G.TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------
        inst:SetStateGraph("SGswineclops_hard")
        ------------------------------------------
        local ENRAGED_TRIGGER = 0.5
        inst.components.healthtrigger:AddTrigger(ENRAGED_TRIGGER, function(inst)
            inst.components.healthtrigger:RemoveTrigger(ENRAGED_TRIGGER)
            inst.sg.mem.wants_to_enrage = true
        end)
        inst.components.combat:AddAttack("jab_projectile", true, 5, nil, {min_range = 4, max_range = 9})
        local FIRE_TRAIL_RANGE = 1
        local function OnFireTrailSpawnFN(inst, trail, i, j)
            local pos = inst:GetPosition()
            local scale = inst.components.scaler.scale or 1
            for _,ent in ipairs(TheSim:FindEntities(pos.x, 0, pos.z, FIRE_TRAIL_RANGE*scale, nil, COMMON_FNS.CommonExcludeTags(inst))) do
                local debuffable = ent.components.debuffable
                if ent:IsValid() and not (ent.components.health and ent.components.health:IsDead()) and debuffable then
                    debuffable:AddDebuff("debuff_fire", "debuff_fire")
                    local debuff_fire = debuffable:GetDebuff("debuff_fire")
                    if debuff_fire then
                        debuff_fire.source = inst
                    end
                end
            end
        end
        inst.components.combat:SetAttackOptions("uppercut", {
            max_trails          = 10,
            dist_between_trails = 1,
            trail_width         = 1,
            prefab              = "spear_gungnir_lungefx",
            do_damage           = false,
            OnSpawnFN           = OnFireTrailSpawnFN,
        })
    end,
}

return hard_mode_fns
