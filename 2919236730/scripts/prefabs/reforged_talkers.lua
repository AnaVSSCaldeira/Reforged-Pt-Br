local Widget = require("widgets/widget")
local Text = require("widgets/text")
local UIAnim = require "widgets/uianim"

local assets = {
    Asset("ANIM", "anim/boarlord.zip"),
    Asset("ANIM", "anim/lavaarena_boarlord_dialogue.zip"),
}
--------------------------------------------------------------------------
-- Pet Functions
--------------------------------------------------------------------------
local function OnRemoveEntity(inst)
    if inst.speechroot ~= nil then
        inst.speechroot:Kill()
        inst.speechroot = nil
    end
end
--------------------------------------------------------------------------
local function common_fn(bank, build, font, colour)
    local inst = CreateEntity()
    ------------------------------------------
    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    ------------------------------------------
    inst:AddComponent("talker")
    inst.components.talker.fontsize = 35
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.offset = Vector3(0, -900, 0)
    inst.components.talker.disablefollowtext = true
    inst.components.talker.ontalkfn = _G.COMMON_FNS.OnTalk
    inst.components.talker.donetalkingfn = _G.COMMON_FNS.OnTalk
    inst.components.talker.resolvechatterfn = _G.COMMON_FNS.GetDialogueStrings
    inst.components.talker:MakeChatter()
    inst.components.talker.lineduration = 3.5
    ------------------------------------------
    --[[inst.avatar = {
        bank   = bank,
        build  = build,
        font   = font,
        colour = colour,
    }--]]
    ------------------------------------------
    inst.OnRemoveEntity = OnRemoveEntity
    ------------------------------------------
    inst.entity:SetCanSleep(false)
    ------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    return inst
end
--------------------------------------------------------------------------
local function admin_fn()
    local inst = common_fn()
    ------------------------------------------
	inst.entity:SetPristine()
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    return inst
end
--------------------------------------------------------------------------
local function rlgl_fn()
    local inst = common_fn()
    ------------------------------------------
	inst.entity:SetPristine()
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    return inst
end
--------------------------------------------------------------------------
return Prefab("reforged_admin_talker", admin_fn, assets),
    Prefab("reforged_rlgl_talker", rlgl_fn, assets)
--[[
TODO
Need to have a table store the current talkers and set their offsets so they do not stack on each other.
    HUD.talkers = {}
adjusts the speech parent (event announcer) position based on height
Update list on remove and on talk
priority for talker?
make common function for resolve chatter fn
--]]
