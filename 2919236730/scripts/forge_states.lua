-- Blowdart 18(14) fames, slingshot: 28(25)
local TIMEOUT = 2

local SLINGSHOT_ANIM_SPEED_MOD = 28/18

local function SlingshotQuickCommonOnEnter(inst, is_client)
    inst.AnimState:SetDeltaTimeMultiplier(SLINGSHOT_ANIM_SPEED_MOD)
    inst.AnimState:PlayAnimation("slingshot_pre")

    if inst.sg.laststate == inst.sg.currentstate then
        inst.sg.statemem.chained = true
        inst.AnimState:SetTime(3*FRAMES)
    end

    local buffaction = inst:GetBufferedAction()
    local target = buffaction.target
    if buffaction then
        if target and target:IsValid() then
            inst:ForceFacePoint(target.Transform:GetWorldPosition())
            inst.sg.statemem.attacktarget = target -- this is to allow repeat shooting at the same target
        end
        if is_client then
            inst:PerformPreviewBufferedAction()
        end
    end

    local equip = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if (equip ~= nil and equip.projectiledelay or 0) > 0 then
        inst.sg.statemem.projectiledelay = (inst.sg.statemem.chained and 15 or 18) * FRAMES - equip.projectiledelay
        if inst.sg.statemem.projectiledelay <= 0 then
            inst.sg.statemem.projectiledelay = nil
        end
    end
end

local function SlingshotQuickStart(inst)
    local buffaction = inst:GetBufferedAction()
    local target = buffaction and buffaction.target or nil
    if not (target and target:IsValid() and inst.components.combat:CanTarget(target)) then
        inst:ClearBufferedAction()
        inst.sg:GoToState("idle")
    end
end

local function SlingshotQuickEnd(inst)
    local buffaction = inst:GetBufferedAction()
    local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if equip and equip.components.weapon and equip.components.weapon.projectile then
        local target = buffaction and buffaction.target or nil
        if target and target:IsValid() and inst.components.combat:CanTarget(target) then
            inst.sg:RemoveStateTag("abouttoattack")
            inst.sg.statemem.abouttoattack = false
            inst:PerformBufferedAction()
            inst.SoundEmitter:PlaySound("dontstarve/characters/walter/slingshot/shoot")
        else
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end
    else -- out of ammo
        inst:ClearBufferedAction()
        inst.components.talker:Say(GetString(inst, "ANNOUNCE_SLINGHSOT_OUT_OF_AMMO"))
        inst.SoundEmitter:PlaySound("dontstarve/characters/walter/slingshot/no_ammo")
    end
end

local function PunchCondition(inst)
    return inst.sg:HasStateTag("punching")
end

local function PunchAOE(inst)
    --_G.COMMON_FNS.DoAOE(inst, nil, nil, {invulnerability_time = 0.2}) -- TODO tuning?
    local mob_index = {}

	--local offset = (target_pos - starting_pos):GetNormalized()*(i*0.6) -- TODO why 0.6?
	--local current_pos = starting_pos + offset
	local weapon = inst.components.combat:GetWeapon()
	local targets = COMMON_FNS.EQUIPMENT.GetAOETargets(inst, inst:GetPosition(), 1, nil, COMMON_FNS.GetPlayerExcludeTags(inst), nil, nil, true)
	if weapon.components.weapon and weapon.components.weapon:HasAltAttack() then
		weapon.components.weapon:DoAltAttack(inst, targets, nil, nil)
	end
end

return {
    CLIENT_STATES = {
        State{
            name = "slingshot_shoot_alt",
            tags = { "doing", "busy", "nointerrupt" },

            onenter = function(inst)
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("slingshot_pre")
                inst.AnimState:PushAnimation("dart_lag", false)

                local buffaction = inst:GetBufferedAction()
                if buffaction then
                    inst:PerformPreviewBufferedAction()
                    if buffaction.pos then
                        inst:ForceFacePoint(buffaction:GetActionPoint():Get())
                    end
                end

                inst.sg:SetTimeout(TIMEOUT)
            end,

            onupdate = function(inst)
                if inst:HasTag("doing") then
                    if inst.entity:FlattenMovementPrediction() then
                        inst.sg:GoToState("idle", "noanim")
                    end
                elseif inst.bufferedaction == nil then
                    inst.sg:GoToState("idle")
                end
            end,

            ontimeout = function(inst)
                inst:ClearBufferedAction()
                inst.sg:GoToState("idle")
            end,
        },
        State{
            name = "slingshot_shoot_quick",
            tags = { "attack" },

            onenter = function(inst)
                inst.components.locomotor:Stop()

                SlingshotQuickCommonOnEnter(inst, true)
                inst.AnimState:PushAnimation("slingshot_lag", true)

                inst.sg:SetTimeout(2)
            end,

            onupdate = function(inst, dt)
                if inst.sg.timeinstate >= (inst.sg.statemem.chained and 10 or 13) * FRAMES and inst.sg.statemem.flattened_time == nil --[[and inst:HasTag("attack")]] then
                    if inst.entity:FlattenMovementPrediction() then
                        inst.sg.statemem.flattened_time = inst.sg.timeinstate
                        inst.sg:AddStateTag("idle")
                        inst.sg:AddStateTag("canrotate")
                        inst.entity:SetIsPredictingMovement(false) -- so the animation will come across
                    end
                end

                if inst.bufferedaction == nil and inst.sg.statemem.flattened_time ~= nil and inst.sg.statemem.flattened_time < inst.sg.timeinstate then
                    inst.sg.statemem.flattened_time = nil
                    inst.entity:SetIsPredictingMovement(true)
                    inst.sg:RemoveStateTag("attack")
                    inst.sg:AddStateTag("idle")
                end

                --[[if (inst.sg.statemem.projectiledelay or 0) > 0 then
                    inst.sg.statemem.projectiledelay = inst.sg.statemem.projectiledelay - dt
                    if inst.sg.statemem.projectiledelay <= 0 then
                        inst:ClearBufferedAction()
                        inst.sg:RemoveStateTag("abouttoattack")
                    end
                end--]]
            end,

            ontimeout = function(inst)
                inst:ClearBufferedAction()
                inst.sg:GoToState("idle")
            end,

            events = {
                EventHandler("animqueueover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg:GoToState("idle")
                    end
                end),
            },

            onexit = function(inst)
                if inst.sg.statemem.flattened_time ~= nil then
                    inst.entity:SetIsPredictingMovement(true)
                end
                inst.AnimState:SetDeltaTimeMultiplier(1)
            end,
        },
        State{
            name = "combat_punch",
            tags = { "doing", "busy", "nomorph" },

            onenter = function(inst)
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("power_punch", false)

                inst:PerformPreviewBufferedAction()

                inst.sg:SetTimeout(7 * FRAMES)
            end,

            onupdate = function(inst)
                if inst:HasTag("busy") then
                    if inst.entity:FlattenMovementPrediction() then
                        inst.sg:GoToState("idle", "noanim")
                    end
                elseif inst.bufferedaction == nil then
                    inst.AnimState:PlayAnimation("slide_pst")
                    inst.sg:GoToState("idle")
                end
            end,

            ontimeout = function(inst)
                inst:ClearBufferedAction()
                inst.AnimState:PlayAnimation("slide_pst")
                inst.sg:GoToState("idle", true)
            end,
        },
		
		State{
            name = "pocketwatch_castspell",
            tags = { "busy", "doing" },

            onenter = function(inst)
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("useitem_pre") -- 8 frames
                inst.AnimState:PushAnimation("pocketwatch_cast", false)
                inst.AnimState:PushAnimation("useitem_pst", false)

                inst:PerformPreviewBufferedAction()
				
				inst.sg:SetTimeout(2)
            end,

            ontimeout = function(inst)
				inst:ClearBufferedAction()
                inst.sg:GoToState("idle", true)
			end,
        },
    },
    SERVER_STATES = {
        State{
            name = "slingshot_shoot_quick",
            tags = { "attack" },

            --TODO: Attacks slower when lag compensation is on, this is a bug.
            onenter = function(inst)
                if inst.components.combat:InCooldown() then
                    inst.sg:RemoveStateTag("abouttoattack")
                    inst:ClearBufferedAction()
                    inst.sg:GoToState("idle", true)
                    return
                end

                inst.sg.statemem.abouttoattack = true

                SlingshotQuickCommonOnEnter(inst)
                inst.AnimState:PushAnimation("slingshot", false)

                inst.components.combat:StartAttack()
                inst.components.combat:SetTarget(inst.sg.statemem.attacktarget)
                inst.components.locomotor:Stop()

                inst.sg:SetTimeout((inst.sg.statemem.chained and 15 or 18) * FRAMES)
            end,

            onupdate = function(inst, dt)
                if (inst.sg.statemem.projectiledelay or 0) > 0 then
                    inst.sg.statemem.projectiledelay = inst.sg.statemem.projectiledelay - dt
                    if inst.sg.statemem.projectiledelay <= 0 then
                        inst:PerformBufferedAction()
                        inst.sg:RemoveStateTag("abouttoattack")
                    end
                end
            end,

            timeline = {
                TimeEvent(10*FRAMES, function(inst)
                    if inst.sg.statemem.chained then
                        SlingshotQuickStart(inst)
                    end
                end),
                TimeEvent(11*FRAMES, function(inst) -- start of slingshot
                    if inst.sg.statemem.chained then
                        inst.SoundEmitter:PlaySound("dontstarve/characters/walter/slingshot/stretch")
                    end
                end),
                TimeEvent(14*FRAMES, function(inst)
                    if inst.sg.statemem.chained and inst.sg.statemem.projectiledelay == nil then
                        SlingshotQuickEnd(inst)
                    end
                end),
                TimeEvent(13*FRAMES, function(inst)
                    if not inst.sg.statemem.chained then
                        SlingshotQuickStart(inst)
                    end
                end),
                TimeEvent(14*FRAMES, function(inst) -- start of slingshot
                    if not inst.sg.statemem.chained then
                        inst.SoundEmitter:PlaySound("dontstarve/characters/walter/slingshot/stretch")
                    end
                end),
                TimeEvent(17*FRAMES, function(inst)
                    if not inst.sg.statemem.chained and inst.sg.statemem.projectiledelay == nil then
                        SlingshotQuickEnd(inst)
                    end
                end),
            },

            ontimeout = function(inst)
                inst.sg:RemoveStateTag("attack")
                inst.sg:AddStateTag("idle")
            end,

            events = {
                EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
                EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
                EventHandler("animqueueover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg:GoToState("idle")
                    end
                end),
            },

            onexit = function(inst)
                inst.components.combat:SetTarget(nil)
                if inst.sg.statemem.abouttoattack and inst.replica.combat ~= nil then
                    inst.replica.combat:CancelAttack()
                end
                inst.AnimState:SetDeltaTimeMultiplier(1)
            end,
        },
        State{
            name = "slingshot_shoot_alt",
            tags = {"attack", "busy", "nointerrupt", "nomorph"},

            onenter = function(inst)
                local buffaction = inst:GetBufferedAction()
                local target = buffaction and buffaction.target or nil
                if target and target:IsValid() then
                    inst:ForceFacePoint(target.Transform:GetWorldPosition())
                    inst.sg.statemem.attacktarget = target -- this is to allow repeat shooting at the same target
                end

                inst.sg.statemem.abouttoattack = true
                inst.AnimState:PlayAnimation("slingshot_pre")
                inst.AnimState:PushAnimation("slingshot", false)

                inst.components.combat:StartAttack()
                inst.components.combat:SetTarget(target)
                inst.components.locomotor:Stop()
            end,

            timeline = {
                TimeEvent(FRAMES, function(inst) -- start of slingshot
                    inst.SoundEmitter:PlaySound("dontstarve/characters/walter/slingshot/stretch")
                end),

                TimeEvent(18*FRAMES, function(inst)
                    local buffaction = inst:GetBufferedAction()
                    local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                    if equip and equip.components.weapon then
                        inst.sg.statemem.abouttoattack = false
                        inst:PerformBufferedAction()
                        inst.SoundEmitter:PlaySound("dontstarve/characters/walter/slingshot/shoot")
                    end
                end),
            },

            events = {
                EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
                EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
                EventHandler("animqueueover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg:GoToState("idle")
                    end
                end),
            },
        },
        -- Warly's Cookpot Idle State (for all characters)
        State{
            name = "forge_cooking",
            tags = {"idle", "busy", "cooking", "notalking"},

            onenter = function(inst, data)
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("idle_wardrobe1_pre")
                inst.AnimState:PushAnimation("idle_wardrobe1_loop", true)
            end,

            timeline = {
                TimeEvent(10*FRAMES, function(inst)
                    inst.sg:RemoveStateTag("busy")
                end),
            },

            onexit = function(inst)
                if inst.cookpot and not inst.cookpot.cooked then
                    inst.cookpot.Despawn(inst.cookpot)
                end
            end,

            -- events = {},
        },
        -- Gauntlets Punch States
        State{
            name = "combat_punch",
            tags = {"aoe", "doing", "busy", --[["nopredict",]] "nomorph",},

            onenter = function(inst, data)
                inst.AnimState:PlayAnimation("power_punch")

                inst.sg.statemem.curr_flash = 0
                inst.sg.statemem.flash_time = 7 * FRAMES

                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")

                inst.components.locomotor:Stop()
                inst.sg:SetTimeout(inst.sg.statemem.flash_time)
            end,

            onupdate = function(inst, dt)
                if inst.sg.statemem.curr_flash <= inst.sg.statemem.flash_time then
                    inst.sg.statemem.curr_flash = math.min(1, inst.sg.statemem.curr_flash + dt)

                    local crl = inst.sg.statemem.curr_flash / inst.sg.statemem.flash_time
                    inst.components.colouradder:PushColour("punch", crl, crl, 0, 0)
                end
            end,

            ontimeout = function(inst)
                inst.sg:GoToState("combat_punch_pst")
            end,
        },
        State{
            name = "combat_punch_pst",
            tags = {"aoe", "doing", "busy", "nopredict", "nomorph", "punching"},

            onenter = function(inst, data)
                inst.AnimState:PlayAnimation("power_punch")
                inst.AnimState:SetTime(7 * FRAMES)
                -- inst.AnimState:Pause()

                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")

                inst:PerformBufferedAction()

                inst.components.locomotor:Stop()
                inst.components.locomotor:EnableGroundSpeedMultiplier(false)

                inst.components.bloomer:PushBloom("punch", "shaders/anim.ksh", -2)
                inst.components.colouradder:PushColour("punch", 1, 1, 0, 0)

                inst.sg.statemem.flash = 1
                inst.sg.statemem.fx = inst:SpawnChild("gauntlet_ground_fx")

                inst.Physics:SetMotorVelOverride(25, 0, 0)

                CreateConditionThread(inst, "attack_charged_punch_aoe", 0, 0.15, PunchCondition, PunchAOE)

                -- 7 frames of movement
                --inst.sg:SetTimeout(9 * FRAMES)
            end,

            onupdate = function(inst, dt)
                if inst.sg:HasStateTag("punching") then
                    SpawnAt("gauntlet_tail_fx", inst)
                end

                if inst.sg.statemem.curr_flash and inst.sg.statemem.curr_flash <= inst.sg.statemem.flash_time then
                    inst.sg.statemem.curr_flash = math.min(1, inst.sg.statemem.curr_flash + dt)

                    local crl = 1 - inst.sg.statemem.curr_flash / inst.sg.statemem.flash_time
                    inst.components.colouradder:PushColour("punch", crl, crl, 0, 0)
                end
            end,

            timeline = {
                -- Fox: For some reason it takes 1 frame to stop physics
                TimeEvent(8 * FRAMES, function(inst)
                    inst.Physics:ClearMotorVelOverride()
                    inst.components.locomotor:Stop()
                end),
                TimeEvent(9 * FRAMES, function(inst)
                    -- inst.AnimState:Resume()
                    -- inst.AnimState:SetTime(17 * FRAMES)
                    inst.sg.statemem.curr_flash = 0
                    inst.sg.statemem.flash_time = inst.AnimState:GetCurrentAnimationLength() - inst.AnimState:GetCurrentAnimationTime() --7 * FRAMES

                    inst.sg:RemoveStateTag("punching")
                    -- inst.sg:RemoveStateTag("busy")
                    if inst.sg.statemem.fx then
                        inst.sg.statemem.fx:Remove()
                        inst.sg.statemem.fx = nil
                    end

                    -- inst.AnimState:PlayAnimation("slide_pst", false)
                end),
            },

            onexit = function(inst)
                inst.components.locomotor:EnableGroundSpeedMultiplier(true)

                if inst.components.playercontroller then
                    inst.components.playercontroller:Enable(true)
                end

                if inst.sg.statemem.fx then
                    inst.sg.statemem.fx:Remove()
                    inst.sg.statemem.fx = nil
                end

                inst.components.bloomer:PopBloom("punch")
                inst.components.colouradder:PopColour("punch")
            end,

            events = {
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        if inst.components.playercontroller then
                            inst.components.playercontroller:Enable(true)
                        end

                        inst.sg:GoToState("idle")
                    end
                end),
            },
        },
        State{
            name = "pocketwatch_castspell",
            tags = { "busy", "doing" },

            onenter = function(inst)
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("useitem_pre") -- 8 frames
                inst.AnimState:PushAnimation("pocketwatch_cast", false)
                inst.AnimState:PushAnimation("useitem_pst", false)

                local buffaction = inst:GetBufferedAction()
                if buffaction ~= nil then
                    inst.AnimState:OverrideSymbol("watchprop", buffaction.invobject.AnimState:GetBuild(), "watchprop")
                    inst.sg.statemem.castfxcolour = buffaction.invobject.castfxcolour
                end
            end,

            timeline = {
                TimeEvent(8*FRAMES, function(inst)
                    inst.AnimState:Show("ARM_normal")
                    inst.sg.statemem.stafffx = SpawnPrefab((inst.components.rider ~= nil and inst.components.rider:IsRiding()) and "pocketwatch_cast_fx_mount" or "pocketwatch_cast_fx")
                    inst.sg.statemem.stafffx.entity:SetParent(inst.entity)
                    inst.sg.statemem.stafffx:SetUp(inst.sg.statemem.castfxcolour or { 1, 1, 1 })

                    inst.SoundEmitter:PlaySound("wanda2/characters/wanda/watch/heal")
                end),
                TimeEvent(16*FRAMES, function(inst)
                    if inst.sg.statemem.stafffx ~= nil then
                        inst.sg.statemem.stafflight = SpawnPrefab("staff_castinglight_small")
                        inst.sg.statemem.stafflight.Transform:SetPosition(inst.Transform:GetWorldPosition())
                        inst.sg.statemem.stafflight:SetUp(inst.sg.statemem.castfxcolour or { 1, 1, 1 }, 0.75, 0)
                    end
                end),
                TimeEvent(25*FRAMES, function(inst)
                    if not inst:PerformBufferedAction() then
                        inst.sg:GoToState("idle")
                    end
                end),
                TimeEvent(40*FRAMES, function(inst)
                    inst.sg:RemoveStateTag("busy")
                end),
                TimeEvent(48*FRAMES, function(inst)
                    if inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
                        inst.AnimState:Show("ARM_carry")
                        inst.AnimState:Hide("ARM_normal")
                    end
                end),
            },

            events = {
                EventHandler("animqueueover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg:GoToState("idle")
                    end
                end),
            },

            onexit = function(inst)
                if inst.sg.statemem.stafffx ~= nil and inst.sg.statemem.stafffx:IsValid() then
                    inst.sg.statemem.stafffx:Remove()
                end
                if inst.sg.statemem.stafflight ~= nil and inst.sg.statemem.stafflight:IsValid() then
                    inst.sg.statemem.stafflight:Remove()
                end

                if inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
                    inst.AnimState:Show("ARM_carry")
                    inst.AnimState:Hide("ARM_normal")
                end
            end,
        },
    },
}
