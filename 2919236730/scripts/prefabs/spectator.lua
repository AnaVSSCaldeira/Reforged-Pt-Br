local MakePlayerCharacter = require("prefabs/player_common")

local assets = {}
local prefabs = {}
--------------------------------------------------------------------------
local function UpdateHUD(inst)
    if inst.HUD then
        inst.HUD.controls:ShowSpectatorCamera()
    end
    inst:DoTaskInTime(3*FRAMES, function() -- Delay to ensure nothing toggles it on
        if inst.HUD then
            inst.HUD.controls:HideCraftingAndInventory()
        end
    end)
end
--------------------------------------------------------------------------
local function common_postinit(inst)
    --MakeFlyingCharacterPhysics(inst, 1, .5)
    inst.Physics:SetCollisionGroup(COLLISION.FLYERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith((TheWorld.has_ocean and COLLISION.GROUND) or COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.LIMITS)
    inst:Hide()
	inst.SoundEmitter:SetMute(true)
    --ChangeToGhostPhysics(inst)
    inst:AddTag("playerghost")
	inst:AddTag("noplayerindicator")
    --inst:AddTag("NOTARGET") -- TODO needed?
    inst:ListenForEvent("setowner", UpdateHUD)
end

local function master_postinit(inst)
    inst.components.locomotor.fasteronroad = false
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor:SetAllowPlatformHopping(false)

    inst.components.health:SetInvincible(true)
    inst.components.health:SetCurrentHealth(0)
    inst.components.health:ForceUpdateHUD(true)
	
	inst.components.talker:IgnoreAll("spectator")
	inst:DoTaskInTime(3, inst.Hide) --needs to be tested for lower values, using values I've set for PP for reference.
end
--------------------------------------------------------------------------
return MakePlayerCharacter("spectator", prefabs, assets, common_postinit, master_postinit)
