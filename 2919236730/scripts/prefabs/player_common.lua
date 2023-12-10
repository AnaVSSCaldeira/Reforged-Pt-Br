local _oldPlayerCommon = kleiloadlua("scripts/prefabs/player_common.lua")
local _oldMakePlayerCharacter = _oldPlayerCommon()
--if _G.TheNet:GetServerGameMode() ~= "lavaarena" then print("using old!") return _oldMakePlayerCharacter end -- TODO change to include other modes if other modes are added (such as gorge)?
local postinit_files = {} -- TODO how to make mod friendly? modders could just use the technique above to edit our character_postinit table...but what if multiple mods want to change stuff at the same time hmmmm...
local character_postinits = require("prefabs/forge_characters")
local is_forge = _G.TheNet:GetServerGameMode() == "lavaarena" -- TODO use to differentiate gamemodes
local function GetPostInit(name, type, postinit)
    --if not is_forge then return postinit end
    local common_fn = character_postinits[type]
    local _oldPostInit = postinit
    local postinit = character_postinits[name] and character_postinits[name][type] or postinit
    return function(inst)
        if common_fn then
            common_fn(inst, name) -- TODO is there anyway to access name from the inst at this point?
        end
        postinit(inst, name, _oldPostInit) -- TODO is there anyway to access name from the inst at this point?
        if type == "master" then
            -----------------------
            -- Modded Characters --
            -----------------------
            if inst.forge_fn then -- TODO better way?
                inst:forge_fn()
            end

            -- Need to wait for userid to be available
            inst:ListenForEvent("setowner", function()
                local perk_options = _G.TheWorld.net.components.perk_tracker:GetCurrentPerkOptions(inst.userid, name)
                -- Apply perk overrides
                if perk_options then
                    if perk_options.overrides.health then
                        inst.components.health:SetMaxHealth(perk_options.overrides.health)
                    end
                    if perk_options.overrides.inventory then
                        inst.starting_inventory = perk_options.overrides.inventory
                    end
                    if perk_options.fn then
                        perk_options.fn(inst, name)
                    end
                end
            end)
        end
    end
end
local function GetCommonPostInit(name, common_postinit)
    return GetPostInit(name, "common", common_postinit)
end
local function GetMasterPostInit(name, master_postinit)
    return GetPostInit(name, "master", master_postinit)
end
local function MakePlayerCharacter(name, customprefabs, customassets, common_postinit, master_postinit, starting_inventory) -- TODO could put all the common stuff from forge_characters in common_postinit?
    return _oldMakePlayerCharacter(name, customprefabs, customassets, GetCommonPostInit(name, common_postinit), GetMasterPostInit(name, master_postinit), starting_inventory)
end

return MakePlayerCharacter
