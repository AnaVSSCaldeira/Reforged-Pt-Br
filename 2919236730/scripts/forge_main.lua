--[[
Copyright (C) 2018 Forged Forge

This file is part of Forged Forge.

The source code of this program is shared under the RECEX
SHARED SOURCE LICENSE (version 1.0).
The source code is shared for referrence and academic purposes
with the hope that people can read and learn from it. This is not
Free and Open Source software, and code is not redistributable
without permission of the author. Read the RECEX SHARED
SOURCE LICENSE for details
The source codes does not come with any warranty including
the implied warranty of merchandise.
You should have received a copy of the RECEX SHARED SOURCE
LICENSE in the form of a LICENSE file in the root of the source
directory. If not, please refer to
<https://raw.githubusercontent.com/Recex/Licenses/master/SharedSourceLicense/LICENSE.txt>
]]
local Widget = require "widgets/widget"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local ForgeNetworking = require "forge_networking"
local ForgeUI = require "forge_ui"
local json = _G.json
local EQUIPSLOTS = _G.EQUIPSLOTS
local STRINGS = _G.STRINGS
local unpack = _G.unpack
local TheInput = _G.TheInput

for classif, fn in pairs(ForgeNetworking) do
	AddPrefabPostInit(classif.."_classified", fn)
end

for class, fn in pairs(ForgeUI) do
	AddClassPostConstruct(class, fn)
end

_G.WORLD_FESTIVAL_EVENT = _G.FESTIVAL_EVENTS.LAVAARENA

if _G.rawget(_G, "FORGE_DBG") then
	modimport("scripts/forge_debug.lua")
end

-- Setup lobby voting
modimport("scripts/lobby_vote")
-- Apply lobby changes (lobbyscreens, lavanarena_book, force start, mvp_widgets etc.)
modimport("scripts/forge_lobby")
-- Apply combat changes (combat, buff system, equippable, etc.)
modimport("scripts/forge_combat")
-- Create Wavesets (includes functions to add custom wavesets and arenas)
--modimport("scripts/forge_wavesets") -- TODO different name since it includes arenas? or separate arenas to a different file?

--Update requireeventfile to grab our code
local _oldrequireeventfile = _G.requireeventfile
_G.requireeventfile = function(path)
	local mod_path = path:gsub("lavaarena_event_server", "forge_data")
	return _G.softresolvefilepath("scripts/"..mod_path..".lua") ~= nil and require(mod_path) or _oldrequireeventfile(path)
end

local UserCommands = require "usercommands"

local function GetFriendCount()
	local friend_count = 0
	for i,friend in pairs(_G.TheNet:GetFriendsList() or {}) do
		if friend.mygame then
			friend_count = friend_count + 1
		end
	end
	return friend_count
end
--rf_spawn("swineclops", 20, "ally") for i, v in ipairs(AllPlayers) do v:AddTag("notarget") end
_G.rf_spawn = function (prefab, count, team)
    for i = 1, count or 1 do
		local c = _G.c_spawn(prefab)
		if team then
			_G.COMMON_FNS.SwitchTeamTag(c, team)
		end
		if _G.TheWorld.components.lavaarenamobtracker then
			if c:HasTag("LA_mob") then
				_G.TheWorld.components.lavaarenamobtracker:StartTracking(c)
			else
				_G.TheWorld.components.lavaarenamobtracker:StopTracking(c)
			end
		end
	end
end

_G.rf_dummy = function(prefab, build)
	local c = _G.c_spawn(prefab)
	if build then
		c.AnimState:SetBuild(build)
	end
	c:DoTaskInTime(0, function(inst)
		if c.brain then
			c.brain:Stop()
		end
	end)
end

AddPrefabPostInit("lavaarena_boarlord", function(inst)
	inst:DoTaskInTime(0, function(inst)
		inst.components.talker.ontalkfn = _G.COMMON_FNS.OnTalk
		_G.TheWorld.net:SetForgeLord(inst)
		inst.throne_pos = inst:GetPosition()
		inst.GetThronePosition = function(inst)
			return inst.throne_pos
		end
	end)
end)

-- Initializing client components
AddPrefabPostInit("lavaarena", function(inst)
    if not _G.TheNet:IsDedicated() then
    	-- if not inst.components.talking_crowd then
		-- 		inst:AddComponent("talking_crowd")
		-- end
		inst:ListenForEvent("playeractivated", function(inst, player) -- TODO this should be moved to common functions
            if _G.ThePlayer == player then
                UserCommands.RunUserCommand("updateusersfriends", {total_friends = GetFriendCount()}, _G.TheNet:GetClientTableForUser(_G.TheNet:GetUserID()))
            end
        end)
    end
end)

AddUserCommand("updateusersfriends", {
    prettyname = _G.STRINGS.REFORGED.USERCOMMANDS.UPDATE_USERS_FRIENDS_TITLE,
    desc = _G.STRINGS.REFORGED.USERCOMMANDS.UPDATE_USERS_FRIENDS_DESC,
    permission = _G.COMMAND_PERMISSION.USER,
    slash = false,
    usermenu = false,
    servermenu = false,
    params = {"total_friends"},
    vote = false,
    hasaccessfn = function(command, caller, targetid)
    	return _G.COMMON_FNS.CheckCommand("updateusersfriends", caller.userid)
    end,
    serverfn = function(params, caller)
    	if _G.TheWorld then
        	_G.TheWorld.net.components.command_manager:UpdateCommandCooldownForUser("updateusersfriends", caller.userid)
        	local stat_tracker = _G.TheWorld.components.stat_tracker
			if stat_tracker then
				stat_tracker:UpdateFriendCount(caller.userid, _G.tonumber(params.total_friends or 0))
			end
		end
    end,
})

AddUserCommand("updateuserscurrentperk", {
    prettyname = _G.STRINGS.REFORGED.USERCOMMANDS.UPDATE_USERS_CURRENT_PERK_TITLE,
    desc = _G.STRINGS.REFORGED.USERCOMMANDS.UPDATE_USERS_CURRENT_PERK_DESC,
    permission = _G.COMMAND_PERMISSION.USER,
    slash = false,
    usermenu = false,
    servermenu = false,
    params = {"current_perk", "original_perk"},
    paramsoptional = {false, true},
    vote = false,
    hasaccessfn = function(command, caller, targetid)
    	return _G.COMMON_FNS.CheckCommand("updateuserscurrentperk", caller.userid)
    end,
    serverfn = function(params, caller)
    	if _G.TheWorld then
        	_G.TheWorld.net.components.command_manager:UpdateCommandCooldownForUser("updateuserscurrentperk", caller.userid)
        	local perk_tracker = _G.TheWorld.net.components.perk_tracker
			if perk_tracker then
				perk_tracker:SetCurrentPerk(caller.userid, params.current_perk, params.original_perk or params.current_perk)
			end
		end
    end,
})

AddUserCommand("pinglocation", {
    prettyname = _G.STRINGS.REFORGED.USERCOMMANDS.PING_LOCATION_TITLE,
    desc = _G.STRINGS.REFORGED.USERCOMMANDS.PING_LOCATION_DESC,
    permission = _G.COMMAND_PERMISSION.USER,
    slash = false,
    usermenu = false,
    servermenu = false,
    params = {"location"},
    paramsoptional = {false},
    vote = false,
    hasaccessfn = function(command, caller, targetid)
    	return _G.COMMON_FNS.CheckCommand("pinglocation", caller.userid)
    end,
    serverfn = function(params, caller)
    	if _G.TheWorld then
        	_G.TheWorld.net.components.command_manager:UpdateCommandCooldownForUser("pinglocation", caller.userid)
	        local lavaarenaeventstate = _G.TheWorld.net.components.lavaarenaeventstate
			if lavaarenaeventstate and lavaarenaeventstate.in_progress:value() then
				local player = _G.GetPlayer(caller.userid)
				if player and not (player.ping_banner and player.ping_banner:IsValid()) then
					banner = _G.SpawnPrefab("rf_ping_banner")
					local pos = params.location and _G.ConvertTableToPoint(_G.ConvertStringToTable(params.location))
					if not pos then
						pos = player and player:GetPosition()
					end
					if pos then
						banner.Transform:SetPosition(pos.x,pos.y,pos.z)
						player.ping_banner = banner
						player.components.talker:Say(STRINGS.REFORGED.PING_GROUP)
					end
				end
			end
		end
    end,
})
--[[
--Leo: Overwrite /rescue because its not good at its job and is used to break even further oob.
AddUserCommand("rescue", {
    prettyname = nil, --default to STRINGS.UI.BUILTINCOMMANDS.RESCUE.PRETTYNAME
    desc = nil, --default to STRINGS.UI.BUILTINCOMMANDS.RESCUE.DESC
    permission = _G.COMMAND_PERMISSION.USER,
    slash = true,
    usermenu = false,
    servermenu = true,
	menusort = 1,
    params = {},
    vote = false,
    serverfn = function(params, caller)
		local pos = caller:GetPosition()
		if not _G.TheWorld.Map:IsPassableAtPoint(pos.x, pos.y, pos.z, true) or _G.TheWorld.Map:IsGroundTargetBlocked(pos) then
			local portal = _G.TheWorld.multiplayerportal
			if portal then
				caller.Physics:Teleport(portal:GetPosition():Get())
			else
				_G.COMMON_FNS.ReturnToGround(caller)
			end
		end
    end,
})--]]

--Fixing name extensions
function _G.EntityScript:GetDisplayName()
    local name = self:GetAdjectivedName()

    if self.prefab ~= nil then
        local name_extention = STRINGS.NAME_DETAIL_EXTENTION[string.upper(self.nameoverride ~= nil and self.nameoverride or self.prefab)]
        if name_extention ~= nil then
            return name.."\n"..name_extention
        end
    end
    return name
end

--Fixing playeravatarpopup images for forge items
local PlayerAvatarPopup = _G.require("widgets/playeravatarpopup")
local EquipSlot = _G.require("equipslotutil")
local _oldUpdateEquipWidgetForSlot = PlayerAvatarPopup.UpdateEquipWidgetForSlot
function PlayerAvatarPopup:UpdateEquipWidgetForSlot(image_group, slot, equipdata)
	local name = equipdata ~= nil and equipdata[EquipSlot.ToID(slot)] or nil
    name = name ~= nil and #name > 0 and name or "none"
    local forge_prefab = _G.GetValidForgePrefab(name)
	if forge_prefab and forge_prefab.image and not forge_prefab.mod_id then
		equipdata[EquipSlot.ToID(slot)] = forge_prefab.image:gsub(".tex", "")
	end
	_oldUpdateEquipWidgetForSlot(self, image_group, slot, equipdata)
	if name == "riledlucy" then
		image_group._text:SetMultilineTruncatedString(STRINGS.NAMES.LAVAARENA_LUCY, 2, TEXT_WIDTH, 25, true)
	end --Because Klei forgot Lucy :c
end

------------------------------
-- Character Starting Items --
------------------------------
TUNING.GAMEMODE_STARTING_ITEMS.LAVAARENA = {
	WILSON       = { "forgedarts", "forge_woodarmor" },
	WILLOW       = { "forgedarts", "featheredtunic" },
	WENDY        = { "forgedarts", "featheredtunic" },
	WOLFGANG     = { "forginghammer", "forge_woodarmor" },
	WX78         = { "forginghammer", "forge_woodarmor" },
	WICKERBOTTOM = { "petrifyingtome", "reedtunic" },
	WES          = { "forgedarts", "featheredtunic" },
	WAXWELL      = { "petrifyingtome", "reedtunic" },
	WOODIE       = { "riledlucy", "forge_woodarmor" },
	WATHGRITHR   = { "pithpike", "featheredtunic" },
	WEBBER       = { "forgedarts", "featheredtunic" },
	WEBBER2       = { "forginghammer", "featheredtunic" },
	WINONA       = { "forginghammer", "forge_woodarmor" },
	WORTOX       = { "teleport_staff", "forge_woodarmor" },
	WARLY        = { "forginghammer", "forge_woodarmor" },
	WORMWOOD     = { "lavaarena_seeddarts", "featheredtunic" },
	WURT         = { "forgedarts", "featheredtunic" },
	WALTER       = { "forgedarts", "featheredtunic" },
	WANDA        = { "petrifyingtome", "reedtunic" },
	SPECTATOR    = {},
}
TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.SPECTATOR = {}

AddClassPostConstruct("screens/redux/lobbyscreen", function(self)
	-- Add lobby screen descriptions for modded characters
	for _,character in pairs(_G.MODCHARACTERLIST) do
		if character ~= "spectator" then
			if not TUNING.GAMEMODE_STARTING_ITEMS.LAVAARENA[string.upper(character)] then
				local val = (math.abs(_G.hash(character)) % 4) + 1 -- TODO better way? maybe have a class option that can be selected in lobby? tank, dps, support? selecting a class will override that characters master postinit giving the character the correct tuning values (health, etc), starting equipment, custom passives? Might encounter issues when multiple players select the same modded character, how would we get one to load a tank loadout and the other a support?
				local possibleinvs = {[1] = "WATHGRITHR", [2] = "WILLOW", [3] = "WOLFGANG", [4] = "WICKERBOTTOM"}
				TUNING.GAMEMODE_STARTING_ITEMS.LAVAARENA[string.upper(character)] = TUNING.GAMEMODE_STARTING_ITEMS.LAVAARENA[possibleinvs[val]]
			end

			if not TUNING.LAVAARENA_STARTING_HEALTH[string.upper(character)] then -- TODO need to get modded characters health
				TUNING.LAVAARENA_STARTING_HEALTH[string.upper(character)] = TUNING.LAVAARENA_STARTING_HEALTH.WILSON
			end

			if not TUNING.LAVAARENA_SURVIVOR_DIFFICULTY[string.upper(character)] then -- TODO need to get modded characters difficulty
				TUNING.LAVAARENA_SURVIVOR_DIFFICULTY[string.upper(character)] = TUNING.LAVAARENA_SURVIVOR_DIFFICULTY.WILSON
			end

			if not STRINGS.LAVAARENA_CHARACTER_DESCRIPTIONS[character] then -- TODO need to get modded characters description
				STRINGS.LAVAARENA_CHARACTER_DESCRIPTIONS[character] = "*Is a master in all arts.\n\n\n\nExpertise:\nMelee, Darts, Books, Staves, Etc."
			end
		end
	end
end)

----------------------
-- Admin/Debug Menu --
----------------------
require("admin_command_list")
local AdminCommandTabs = require "widgets/admin_command_tabs"
local admin_commands

-- Add the Admin/Debug menu if the client is admin
local function AddAdminCommands(self)
	-- FOR IMAGEBUTTON
	local function OnGainFocus(self) -- TODO override imagebutton????? I believe this is pasted in game settings panel as well
		self._base.OnGainFocus(self)

		if self.hover_overlay then
			self.hover_overlay:Show()
		end

		if self:IsSelected() then return end

		if self:IsEnabled() then
			self.image:SetTexture(self.atlas, self.image_focus)

			if self.size_x and self.size_y then
				self.image:ScaleToSize(self.size_x, self.size_y)
			end
		end

		if self.image_focus == self.image_normal and self.scale_on_focus and self.focus_scale then
			--self.image:SetScale(self.focus_scale[1], self.focus_scale[2], self.focus_scale[3])
			self.image:ScaleToSize(self.size_x * self.focus_scale[1], self.size_y * self.focus_scale[2])
		end

		if self.imagefocuscolour then
			self.image:SetTint(unpack(self.imagefocuscolour))
		end

		if self.focus_sound then
			TheFrontEnd:GetSound():PlaySound(self.focus_sound)
		end
	end

	local function OnLoseFocus(self)
		self._base.OnLoseFocus(self)

		if self.hover_overlay then
			self.hover_overlay:Hide()
		end

		if self:IsSelected() then return end

		if self:IsEnabled() then
			self.image:SetTexture(self.atlas, self.image_normal)

			if self.size_x and self.size_y then
				self.image:ScaleToSize(self.size_x, self.size_y)
			end
		end

		if self.image_focus == self.image_normal and self.scale_on_focus and self.normal_scale then
			--self.image:SetScale(self.normal_scale[1], self.normal_scale[2], self.normal_scale[3])
			self.image:ScaleToSize(self.size_x, self.size_y)
		end

		if self.imagenormalcolour then
			self.image:SetTint(self.imagenormalcolour[1], self.imagenormalcolour[2], self.imagenormalcolour[3], self.imagenormalcolour[4])
		end
	end

	local controls = self

	-- Only admins get the admin/debug menu or all players get it if currently in sandbox mode
	if _G.TheNet:GetIsServerAdmin() or _G.REFORGED_SETTINGS.gameplay.waveset == "sandbox" then
		admin_commands = controls.left_root:AddChild(AdminCommandTabs(controls.owner, controls.top_root))

		local width, height = 30, 30
		controls.button_bg = controls:AddChild(Image("images/servericons.xml", "bg_rust.tex"))
		controls.button = controls:AddChild(ImageButton("images/avatars.xml", "avatar_admin.tex"))
		controls.button:ScaleImage(width, height)
		controls.button.OnGainFocus = function(controls) OnGainFocus(controls) end
		controls.button.OnLoseFocus = function(controls) OnLoseFocus(controls) end
		controls.button_bg:ScaleToSize(width, height, true)
		controls.button:SetPosition(width/2, height/2, 0)
		controls.button_bg:SetPosition(width/2, height/2, 0)
		controls.button:SetOnClick(function()
			if admin_commands.display then
				controls.button_bg:SetTexture("images/servericons.xml", "bg_rust.tex")
			else
				controls.button_bg:SetTexture("images/servericons.xml", "bg_green.tex")
			end
			controls.button_bg:ScaleToSize(width, height, true)
			admin_commands:ToggleDisplay()
		end)
	end
	--[[
	TODO
	--]]
	self.BuildMutatorDisplay = function(self)
		local width = 50
		local height = 50
		-- Remove all previously displayed mutator icons
		for mutator,icon in pairs(self.active_mutators or {}) do
			icon:Kill()
		end
		self.active_mutators = {}
		local mutators = _G.REFORGED_SETTINGS.gameplay.mutators
		local count = 0
		local x = -width
		local y = height * 2
		local current_y_offset = 0
	    for mutator,val in pairs(mutators) do
	        local mutator_info = _G.REFORGED_DATA.mutators[mutator]
	        if val and mutator_info and val ~= 1 then
	        	local mutator_icon = self.bottomright_root:AddChild(Image(mutator_info.icon.atlas, mutator_info.icon.tex))
	        	local hover_text = _G.STRINGS.UI.WXP_DETAILS[string.upper(mutator_info.exp_details.desc)] .. (type(val) == "number" and ": " .. tostring(val) or "")
	        	mutator_icon:SetHoverText(hover_text, {offset_x = 0, colour = _G.UICOLOURS.EGGSHELL})
	        	mutator_icon:SetPosition(x, y + current_y_offset)
	        	mutator_icon:ScaleToSize(width, height, true)
	        	local w, h = mutator_icon.hovertext:GetRegionSize()
	        	mutator_icon:ClearHoverText()
	        	mutator_icon:SetHoverText(hover_text, {offset_x = -w/2, colour = _G.UICOLOURS.EGGSHELL})
	        	self.active_mutators[mutator] = mutator_icon
	        	count = count + 1
	        	current_y_offset = count*height
	        end
	    end
	end
	self:BuildMutatorDisplay()

	self.UpdateMutatorDisplay = function(self) -- TODO

	end
end
AddClassPostConstruct( "widgets/controls", AddAdminCommands )

local EndOfMatchPopup = require "widgets/redux/endofmatchpopup"
AddClassPostConstruct("screens/playerhud", function(self)
	local is_forge_admin = _G.TheNet:GetServerGameMode() == "lavaarena" and _G.TheNet:GetIsServerAdmin()
	local PlayerHudIsCraftingOpen = self.IsCraftingOpen
	self.IsCraftingOpen = function(self)
		if is_forge_admin then
			return admin_commands.crafting.open or admin_commands.controllercraftingopen
		else
			return PlayerHudIsCraftingOpen(self)
		end
	end

	local _oldCreateOverlays = self.CreateOverlays
	self.CreateOverlays = function(self, owner)
		_oldCreateOverlays(self, owner)

		-- Setup Talker Display
		self.talker_announcer_root = self.under_root:AddChild(Widget("talker_announcer_root"))
	    self.talker_announcer_root:SetScaleMode(_G.SCALEMODE_PROPORTIONAL)
	    self.talker_announcer_root:SetHAnchor(_G.ANCHOR_MIDDLE)
	    self.talker_announcer_root:SetVAnchor(_G.ANCHOR_TOP)
	    self.talker_announcer = self.talker_announcer_root:AddChild(Widget("talker_announcer"))
	    self.eventannouncer_start_pos = _G.Vector3(0, _G.GetGameModeProperty("eventannouncer_offset") or -15, 0)
	    self.talker_announcer:SetPosition(self.eventannouncer_start_pos:Get())
	end

	-- Create List of talkers so they don't overlap each other
	self.talkers = {}
	self.current_talker_offset = _G.Vector3(0, _G.GetGameModeProperty("eventannouncer_offset") or 0, 0)
	self.AddTalker = function(self, talker_widget, offset)
		table.insert(self.talkers, {widget = talker_widget, offset = offset})
		self.talker_announcer:AddChild(talker_widget)
		self.current_talker_offset = self.current_talker_offset + offset/2
		talker_widget:SetPosition(self.current_talker_offset:Get())
		self.current_talker_offset = self.current_talker_offset + offset/2
		self:UpdateEventOffsets()
	end

	self.RemoveTalker = function(self, talker_widget)
		for i,info in pairs(self.talkers) do
			if info.widget == talker_widget then
				table.remove(self.talkers, i)
				self:UpdateTalkerOffsets()
				self:UpdateEventOffsets()
				break
			end
		end
	end

	self.UpdateTalkerOffsets = function(self)
		local current_offset =  _G.Vector3(0, _G.GetGameModeProperty("eventannouncer_offset") or 0, 0)
		for i,info in pairs(self.talkers) do
			current_offset = current_offset + info.offset/2
			info.widget:SetPosition(current_offset:Get())
			current_offset = current_offset + info.offset/2
		end
		self.current_talker_offset = current_offset
	end

	self.UpdateEventOffsets = function(self)
		self.eventannouncer:SetPosition((self.eventannouncer_start_pos + self.current_talker_offset):Get())
	end

	-- Add support for custom text on end of match popup.
	self.ShowEndOfMatchPopup = function(self, data)
	    self.inst:DoTaskInTime(data.victory and 2.5 or 0, function()
	        if self.endofmatchpopup == nil then
	        	local waveset = _G.REFORGED_SETTINGS.gameplay.waveset
	        	local waveset_strings = data.victory and STRINGS.REFORGED.WAVESETS[waveset].victory or not data.victory and STRINGS.REFORGED.WAVESETS[waveset].defeat
	            local popupdata = {
	                title = waveset_strings and waveset_strings.title or data.victory and STRINGS.UI.HUD.LAVAARENA_WIN_TITLE or STRINGS.UI.HUD.LAVAARENA_LOSE_TITLE,
	                body = waveset_strings and waveset_strings.body or data.victory and STRINGS.UI.HUD.LAVAARENA_WIN_BODY or STRINGS.UI.HUD.LAVAARENA_LOSE_BODY,
	            }
	            self.endofmatchpopup = self.root:AddChild(EndOfMatchPopup(self.owner, popupdata))
	        end
	    end)
	end
end)
-------------
-- Filters --
-------------
local filter_index = _G.REFORGED_SETTINGS.display.default_filter
local filters = {"lavaarena2_cc", "day05_cc", "dusk03_cc", "night03_cc", "snow_cc", "snowdusk_cc", "night04_cc", "summer_day_cc", "summer_dusk_cc", "summer_night_cc", "spring_day_cc", "spring_dusk_cc", "spring_night_cc", "insane_day_cc", "insane_dusk_cc", "insane_night_cc", "purple_moon_cc", "sw_mild_day_cc", "sw_wet_day_cc", "sw_green_day_cc", "sw_volcano_cc", "beaver_vision_cc", "caves_default", "fungus_cc", "ghost_cc", "identity_colourcube", "mole_vision_off_cc", "mole_vision_on_cc", "ruins_dark_cc", "ruins_dim_cc", "ruins_light_cc", "sinkhole_cc", "quagmire_cc"}

local function NotInGame()
	return not _G.ThePlayer or not _G.ThePlayer.HUD or _G.ThePlayer.HUD:HasInputFocus()
end

local function ApplyFilter(filter)--TheWorld:PushEvent("overridecolourcube", resolvefilepath("images/colour_cubes/day05_cc.tex"))
	_G.TheWorld:PushEvent("overridecolourcube", _G.resolvefilepath("images/colour_cubes/" .. tostring(filter) .. ".tex"))
end

AddSimPostInit(function()
	if _G.TheNet:IsDedicated() then return end
	-- Apply default filter
	--ApplyFilter(filters[_G.REFORGED_SETTINGS.display.default_filter])
end)

-- Change filter to the next one in the list
TheInput:AddKeyDownHandler(_G.REFORGED_SETTINGS.display.ADJ_FILTER_KEY, function()
	if _G.TheNet:IsDedicated() or NotInGame() then return end
	filter_index = filter_index + (TheInput:IsKeyDown(_G.KEY_SHIFT) and -1 or 1)
	if filter_index > #filters then
		filter_index = 1
	elseif filter_index < 1 then
		filter_index = #filters
	end
	_G.ThePlayer.components.talker:Say("Current Filter: " .. tostring(filters[filter_index]))
	ApplyFilter(filters[filter_index])
end)

-- Ping Location
local PING_COOLDOWN = 5
TheInput:AddKeyDownHandler(_G.REFORGED_SETTINGS.display.ping_keybind, function()
	if _G.TheNet:IsDedicated() or NotInGame() then return end
	if not _G.ThePlayer.ping_cooldown then
		UserCommands.RunUserCommand("pinglocation", {location = _G.SerializeTable(_G.ConsoleWorldPosition())}, _G.TheNet:GetClientTableForUser(_G.TheNet:GetUserID()))
		_G.ThePlayer.ping_cooldown = _G.ThePlayer:DoTaskInTime(PING_COOLDOWN, function()
			_G.ThePlayer.ping_cooldown = nil
		end)
	end
end)

-----------------------
-- Player Indicators --
-----------------------
AddClassPostConstruct("widgets/targetindicator", function(self)
	self:SetClickable(false)
	local _oldOnUpdate = self.OnUpdate
	function self:OnUpdate()
		if _G.REFORGED_SETTINGS.display.hide_indicators then
			self:Hide()
		-- Adjust the size of player indicators to be smaller
		else
			_oldOnUpdate(self)
			self:SetScale(0.65)
		end
	end
end)

AddPrefabPostInitAny(function(inst)
	--------------
	-- No Click -- TODO should be separate mod
	--------------
	inst:DoTaskInTime(0, function()
		if inst:IsValid() and _G.TheNet:GetIsServer() and not inst:HasTag("NOCLICK") and not inst:HasTag("LA_mob") and not inst:HasTag("ALLOWCLICK") and not inst:HasTag("corpse") and not inst.replica.inventoryitem then
			inst:AddTag("NOCLICK")
			if _G.TheWorld and _G.TheWorld.ismastersim then
				if _G.TheWorld.components.lavaarenaevent and _G.TheWorld.components.lavaarenaevent:IsIntermission() or inst:HasTag("player") then --Left a player check in here because corpse tag isn't being added fast enough... We'll have to fix it.
					inst:RemoveTag("NOCLICK")
				else
					inst.tempnoclick = true
				end
			end
		end
	end)
end)

-------------------------
-- Disable Server Save --
-------------------------
local old_SaveGame = _G.SaveGame
function _G.SaveGame(isshutdown, cb)
    if _G.TheNet:GetServerGameMode() == "lavaarena" and _G.TheNet:GetIsServer() then
        --we don't save for lavaarena.
        if cb ~= nil then
            cb(true)
        end
        return
    else
        old_SaveGame(isshutdown, cb)
    end
end

----------------
-- Debuff HUD --
----------------
-- Fox: This was made for UI stuff
local function SetDirty(netvar, val)
	netvar:set_local(val)
	netvar:set(val)
end

AddComponentPostInit("debuffable", function(self)
	local _AddDebuff = self.AddDebuff
	local _RemoveDebuff = self.RemoveDebuff
	self.immunities = {}
	self.weaknesses = {}
	self.immune_to_all = false -- If set to true then weaknesses will be checked instead of immunities
	self.current_debuffs = {}

	function self:AddDebuff(name, prefab, data)
		if self:CanBeDebuffedByDebuff(name, prefab) then
			if self.debuffs[name] == nil and self.inst.player_classified and _G.TUNING.FORGE.BUFFS_DATA[string.upper(name)] then
				SetDirty(self.inst.player_classified.net_buffs, json.encode({name = name, removed = false}))
			end

			local ent = _AddDebuff(self, name, prefab, data)
			if ent and self.inst:IsValid() then
				self.current_debuffs[name] = true
				self.inst.replica.debuffable:SetCurrentDebuffsStr(_G.SerializeTable(self.current_debuffs))
			end
			return ent
		end
	end

	function self:RemoveDebuff(name, ...)
		if self.debuffs[name] ~= nil and self.inst.player_classified and _G.TUNING.FORGE.BUFFS_DATA[string.upper(name)] then
			SetDirty(self.inst.player_classified.net_buffs, json.encode({name = name, removed = true}))
		end

		_RemoveDebuff(self, name, ...)

		if self.inst:IsValid() and self.current_debuffs[name] then
			self.current_debuffs[name] = nil
			self.inst.replica.debuffable:SetCurrentDebuffsStr(_G.SerializeTable(self.current_debuffs))
		end
	end

	-- Give the prefab name of the buff/debuff
	function self:AddImmunity(name)
		self.immunities[name] = true
	end

	function self:AddImmunities(names, override)
		if override then
			self.immunities = {}
		end
		for _,name in pairs(names) do
			self:AddImmunity(name)
		end
	end

	function self:RemoveImmunity(name)
		self.immunities[name] = nil
	end

	function self:RemoveImmunities(names)
		for _,name in pairs(names) do
			self:RemoveImmunity(name)
		end
	end

	function self:IsImmune(name) -- TODO add immunity checks to all debuffs/buffs
		return self.immune_to_all or self.immunities[name]
	end

	-- Give the prefab name of the buff/debuff
	function self:AddWeakness(name)
		self.weaknesses[name] = true
	end

	function self:AddWeaknesses(names, override)
		if override then
			self.weaknesses = {}
		end
		for _,name in pairs(names) do
			self:AddWeakness(name)
		end
	end

	function self:RemoveWeakness(name)
		self.weaknesses[name] = nil
	end

	function self:RemoveWeaknesses(names)
		for _,name in pairs(names) do
			self:RemoveWeakness(name)
		end
	end

	function self:IsWeakness(prefab)
		return self.immune_to_all and self.weaknesses[prefab]
	end

	function self:CanBeDebuffedByDebuff(name, prefab)
		return self:IsEnabled() and (self:IsWeakness(name) or not self:IsImmune(name) or self:IsWeakness(prefab) or not self:IsImmune(prefab))
	end

	function self:SetImmuneToAll(val)
		self.immune_to_all = val
	end

	local _oldEnable = self.Enable
	function self:Enable(enable, keep_debuffs)
		if not (enable or keep_debuffs) then
			_oldEnable(self, enable)
		else
			self.enable = enable
		end
	end

	function self:RemoveAllDebuffs(exclusions)
		--_G.Debug:PrintTable(exclusions, 0)
		local k = _G.next(self.debuffs)
		local exclusions = exclusions or {}
		local checked_indices = {}
        while k ~= nil and not checked_indices[k] do
        	if not exclusions[self.debuffs[k].inst] then
            	self:RemoveDebuff(k)
            end
            checked_indices[k] = true
            k = _G.next(self.debuffs)
        end
	end
end)

-------------------
-- Explosive Hit -- TODO what uses this? and why doesn't it remove itself already?
-------------------
AddPrefabPostInit("explosivehit", function(inst)
	inst:DoTaskInTime(3, inst.Remove)
end)

--------------
-- WXP Util --
--------------
--[[
TODO
	need to have the ability to see real levels as well, option set via client? server?
--]]
local starting_level = 1
local max_level = 100
local level_tiers = 3
local max_rank = 6
local exp_rate = 1000
local exp_cap = 20000
local level_cap = 2400
local max_gauss = exp_cap / exp_rate
local function GetWXPForLevel(level)
	--[[ leaving this code snippet here just incase we change the rate of exp
	local exp = 0
	for i = starting_level + 1,level do
		exp = exp + math.min((i - 1)*exp_rate, exp_cap)
	end
    return exp, exp + math.min(level*exp_rate, exp_cap)
    --]]
    local gauss_level = math.min(max_gauss, level - 1)
	local exp = 1 / 2 * gauss_level * (gauss_level + 1) * exp_rate
	if level - 1 > max_gauss then
	local new_level = level - max_gauss - 1
	exp = new_level * exp_cap + exp
	end
	return exp, exp + math.min(level*exp_rate, exp_cap)
end

local CURRENT_CAP = 999999999
_G.wxputils.GetLevelForWXP = function(wxp)
	local wxp = wxp > CURRENT_CAP and -1 or wxp
	if wxp < 0 then return -1 end
	--[[ leaving this code snippet here just incase we change the rate of exp
	local klei_level = _G.TheItems:GetLevelForWXP(wxp)
	local current_level = 1
	local current_exp = wxp - current_level*exp_rate
	while current_exp >= 0 and current_level * exp_rate < exp_cap do
		current_level = current_level + 1
		current_exp = current_exp - math.min((current_level)*exp_rate, exp_cap)
	end
	current_level = math.min(level_cap, current_level + (current_exp >= 0 and math.floor(current_exp / exp_cap) + 1 or 0)) -- + 1 is for end case of the while loop
	return current_level
	--]]
	local a = 0.5 * exp_rate
	local b = -a
	local c = -wxp
	local level = math.floor((-b + math.sqrt(b*b - 4*a*c)) / (2*a))
	if level > max_gauss then
		local new_exp = wxp - GetWXPForLevel(max_gauss)
		level = math.min(level_cap, math.floor(new_exp / exp_cap) + max_gauss)
	end
	return level
end

_G.wxputils.GetDisplayLevelAndTierForLevel = function(current_level)
	local current_level = current_level or 1
	local level = current_level % max_level
	level = level == 0 and current_level > 0 and max_level or level
	local tier = math.floor((current_level - 1)/max_level) -- - 1 is to include the max level as part of the current tier
	return level, tier
end

_G.wxputils.GetWXPForLevel = function(level)
	return GetWXPForLevel(level)
end

_G.wxputils.GetActiveWXP = function(character) -- TODO this might need to return net values from the lavaarena network if on a dedicated server?
	local total_exp = 0
	local character = character or "overall"
	-- Retrieve levels from server
	if _G.TheNet:GetServerIsDedicated() then
		total_exp = _G.TheWorld.net.replica.levelmanager:GetUsersExp(_G.TheNet:GetUserID(), character) or 0
	-- Retrieve level from exp log
	else
		_G.TheSim:GetPersistentString("reforged_exp", function(load_success, data)
			if data then
				local status, exp_history = _G.pcall( function() return _G.json.decode(data) end )
			    if status and exp_history then -- TODO cheating check? Validation check
					total_exp = exp_history.total_exp[character]
				else
					_G.Debug:Print("Failed to retrieve exp history!", "warning")
				end
			end
		end)
	end
    return total_exp
end

local function GetLevelProgressFraction()
	local level = _G.TheWorld.net.replica.levelmanager:GetUsersLevel(_G.TheNet:GetUserID())
    local wxp = _G.TheWorld.net.replica.levelmanager:GetUsersExp(_G.TheNet:GetUserID())

    local curr_level_wxp = _G.wxputils.GetLevelForWXP(level)
    local next_level_wxp = _G.wxputils.GetLevelForWXP(level+1)
	return (wxp - curr_level_wxp), (next_level_wxp-curr_level_wxp)
end

_G.wxputils.GetLevelPercentage = function()
    local numerator,denominator = GetLevelProgressFraction()
    return numerator / denominator
end

_G.wxputils.BuildProgressString = function()
    local numerator,denominator = GetLevelProgressFraction()
    return subfmt(_G.STRINGS.UI.XPUTILS.XPPROGRESS, {num = numerator, max = denominator})
end

_G.wxputils.GetLevel = function(festival_key, season)
    return _G.TheWorld.net.replica.levelmanager:GetUsersLevel(_G.TheNet:GetUserID())
end

_G.wxputils.GetActiveLevel = function()
	return _G.TheWorld.net.replica.levelmanager:GetUsersLevel(_G.TheNet:GetUserID())
end

local levels_per_tier = 25
_G.wxputils.GetLevelTierBadge = function(level, rank, is_small)
	local tier = math.clamp(math.floor(level / levels_per_tier), 1, level_tiers)
	local badge_rank = math.clamp(math.floor((rank or 0) / (level_tiers + 1)) + 1, 0, max_rank)
	return tier > 0 and (is_small and "small_w_" or "weapon_") .. tostring(badge_rank) .. "_" .. tostring(tier) .. ".tex"
end

_G.wxputils.GetRankTierBadge = function(rank, is_small)
	local badge_rank = math.clamp((rank or 0) % (level_tiers + 1), 0, level_tiers)
	return badge_rank > 0 and (is_small and "small_" or "") .. "star_" .. tostring(badge_rank) .. ".tex"
end

_G.wxputils.GetRankTierBadgeBackground = function(rank, is_small)
	local badge_rank = math.clamp(math.floor((rank or 0) / (level_tiers + 1)) + 1, 0, max_rank)
	return badge_rank >0 and (is_small and "small_" or "") .. "base_" .. tostring(badge_rank) .. ".tex"
end

-- Revise all Level Badge display templates
local TEMPLATES = require("widgets/redux/templates")
local _oldWxpBar = TEMPLATES.WxpBar
TEMPLATES.WxpBar = function()
	local wxpbar = _oldWxpBar()
	wxpbar.SetRank = function(w_self, rank, next_level_xp, profileflair)
        w_self.rank:SetRank(profileflair, rank)
        w_self.nextrank:SetRank(rank + 1)
        w_self.nextlevelxp_text:SetString(next_level_xp)
	end
	return wxpbar
end
local function SetLevelAndTierDisplay(widget, level, is_small)
	local display_level, display_tier = _G.wxputils.GetDisplayLevelAndTierForLevel(level)
	local level_tier_badge = _G.wxputils.GetLevelTierBadge(display_level or 0, display_tier or 0, is_small)
	if level_tier_badge then
		widget.level_tier:SetTexture("images/level_badges.xml", level_tier_badge)
		widget.level_tier:Show()
	else
		widget.level_tier:Hide()
    end
    local rank_tier_badge = _G.wxputils.GetRankTierBadge(display_tier, is_small)
    if rank_tier_badge then
		widget.rank_tier:SetTexture("images/level_badges.xml",rank_tier_badge)
		widget.rank_tier:Show()
	else
		widget.rank_tier:Hide()
    end
	local badge_background = _G.wxputils.GetRankTierBadgeBackground(display_tier, is_small)
	if badge_background and widget.bg then -- only the large badge has .bg
		widget.bg:SetTexture("images/level_badges.xml", badge_background)
	elseif widget.SetTexture then -- for smaller badge
		widget:SetTexture("images/level_badges.xml", badge_background) -- TODO change when added
	end
end
local function SetLevel(self, level)
	local is_neg = not level or level < 0
	level = is_neg and 0 or level
    self.num:SetString(tostring(is_neg and "0" or _G.wxputils.GetDisplayLevelAndTierForLevel(level)))
    if is_neg then
    	self.num:SetColour(_G.unpack(_G.UICOLOURS.RED))
    end
	return level
end
local _oldFestivalNumberBadge = TEMPLATES.FestivalNumberBadge
TEMPLATES.FestivalNumberBadge = function(festival_key)
	local badge = _oldFestivalNumberBadge(festival_key)
	-- Level String
	badge.num:SetPosition(2,5) -- (2,10) is original position.
	-- Level Tier
	badge.level_tier = badge:AddChild(Image())
	--badge.level_tier:SetScale(1.5)
	badge.level_tier:SetPosition(0, 0)

	-- Rank Tier
	badge.rank_tier = badge:AddChild(Image())
	--badge.rank_tier:SetScale(1.5)
	badge.rank_tier:SetPosition(0, 0)

	badge.SetRank = function(self, level)
        --self.num:SetString(tostring(_G.wxputils.GetDisplayLevelAndTierForLevel(level)))
        local given_level = level
        level = SetLevel(self, level)
		SetLevelAndTierDisplay(self, level <= 0 and 1 or level, true)
        badge:SetHoverText(_G.subfmt(STRINGS.UI.WXPLOBBYPANEL.LEVEL, {val = level > 0 and given_level or 0}), {offset_x = 30})
    end

	return badge
end
local _oldRankBadge = TEMPLATES.RankBadge
TEMPLATES.RankBadge = function()
	local rank = _oldRankBadge()

	-- Level Tier
	rank.level_tier = rank:AddChild(Image())
	rank.level_tier:SetScale(.75)
	rank.level_tier:SetPosition(0, 31)

	-- Rank Tier
	rank.rank_tier = rank:AddChild(Image())
	rank.rank_tier:SetScale(.75)
	rank.rank_tier:SetPosition(0, -40)

	rank.flair:MoveToFront()

	local _oldSetRank = rank.SetRank
	rank.SetRank = function(self, profileflair, level, hide_hover_text)
		_oldSetRank(self, profileflair, (not level or level <= 0) and 1 or level, hide_hover_text)
		local given_level = level
		level = SetLevel(self, level)
		SetLevelAndTierDisplay(self, level)
		rank:SetHoverText(_G.subfmt(STRINGS.UI.WXPLOBBYPANEL.LEVEL, {val = level > 0 and given_level or 0}), {offset_x = 30})
	end
	return rank
end

-------------------
-- Player Levels --
-------------------
AddPrefabPostInit("lavaarena_network", function(inst)
	_G.COMMON_FNS.NetworkSetup(inst)
end)

local function UpdateUserExpCondtion(userid)
	local levelmanager = _G.TheWorld.net.components.levelmanager
	return not _G.REFORGED_SETTINGS.display.server_level and (levelmanager == nil or not levelmanager.users_retrieved[userid])
end
AddUserCommand("updateuserexp", {
    prettyname = _G.STRINGS.REFORGED.USERCOMMANDS.UPDATE_USER_EXP_TITLE,
    desc = _G.STRINGS.REFORGED.USERCOMMANDS.UPDATE_USER_EXP_DESC,
    permission = _G.COMMAND_PERMISSION.USER,
    slash = false,
    usermenu = false,
    servermenu = false,
    params = {"total_exp"},
    vote = false,
    hasaccessfn = function(command, caller, targetid)
    	return _G.COMMON_FNS.CheckCommand("updateuserexp", caller.userid, UpdateUserExpCondtion)
    end,
    serverfn = function(params, caller)
    	if _G.TheWorld then
        	_G.TheWorld.net.components.command_manager:UpdateCommandCooldownForUser("updateuserexp", caller.userid)
	        local levelmanager = _G.TheWorld.net.components.levelmanager
			if levelmanager and not _G.REFORGED_SETTINGS.display.server_level then
				local str = params.total_exp and _G.ConvertStringToTable(params.total_exp)
				levelmanager:UpdateUserExp(caller.userid, str)
			end
		end
    end,
})
local function UpdateUserAchievementsCondtion(userid)
	local achievementmanager = _G.TheWorld.net.components.achievementmanager
	return achievementmanager == nil or not achievementmanager.users_retrieved[userid]
end
AddUserCommand("updateusersachievements", {
    prettyname = _G.STRINGS.REFORGED.USERCOMMANDS.UPDATE_USER_ACHIEVEMENT_TITLE,
    desc = _G.STRINGS.REFORGED.USERCOMMANDS.UPDATE_USER_ACHIEVEMENT_DESC,
    permission = _G.COMMAND_PERMISSION.USER,
    slash = false,
    usermenu = false,
    servermenu = false,
    params = {"achievements"},
    vote = false,
    hasaccessfn = function(command, caller, targetid)
    	return _G.COMMON_FNS.CheckCommand("updateusersachievements", caller.userid, UpdateUserAchievementsCondtion)
    end,
    serverfn = function(params, caller)
    	if _G.TheWorld then
        	_G.TheWorld.net.components.command_manager:UpdateCommandCooldownForUser("updateusersachievements", caller.userid)
	        local achievementmanager = _G.TheWorld.net.components.achievementmanager
			local str = params.achievements and _G.ConvertStringToTable(params.achievements)
			if achievementmanager then
				achievementmanager:UpdateUsersClientAchievements(caller.userid, str)
			else
				_G.Debug:Print("Attempted to update achievements for '" .. tostring(caller.userid) .."', but AchievementManager does not exist yet. (TheWorld = " .. tostring(TheWorld) .. ")", "warning")
			end
		end
    end,
})

local function SetPlayerPortraitTint(self)
	local parent = self:GetParent()
	if tostring(parent) == "ROOT" then
		parent = parent:GetParent()
	end
	local userid = self.userid
	if not userid and tostring(parent) == "PlayerAvatarPopupScreen" then
		userid = parent.userid
	end
	if _G.COMMON_FNS.IsScripter(userid) then
		--self.frame.bg:SetTint(unpack(_G.UICOLOURS.RED))
	else
		--self.frame.bg:SetTint(1,1,1,1)
	end
end
AddClassPostConstruct("widgets/redux/playeravatarportrait", function(self)
	SetPlayerPortraitTint(self)
	local _oldUpdatePlayerListing = self.UpdatePlayerListing
	self.UpdatePlayerListing = function(self, player_name, colour, prefab, base_skin, clothing, playerportrait, profileflair, rank)
		_oldUpdatePlayerListing(self, player_name, colour, prefab, base_skin, clothing, playerportrait, profileflair, rank)
		if prefab == "spectator" then
	        self.badge:Set("spectator", _G.DEFAULT_PLAYER_COLOUR, false, 0)
	        self.badge:Show()
	        self.puppet_root:Hide()
	        self.lobbycharacter = prefab
    	end
		local parent = self:GetParent()
		if tostring(parent) == "ROOT" then
			parent = parent:GetParent()
		end
		local userid = self.userid
		if not userid and tostring(parent) == "PlayerAvatarPopupScreen" then
			userid = parent.userid
		end
		SetPlayerPortraitTint(self)

		local character_level = _G.wxputils.GetLevelForWXP(_G.tonumber(_G.TheWorld.net and _G.TheWorld.net.replica.levelmanager and _G.TheWorld.net.replica.levelmanager:GetUsersExp(userid, prefab) or 0))
		self:SetRank(profileflair, character_level)
	end
end)

-- overrides for syncing client host level to widgets
local next = _G.next
local TrueScrollList = require "widgets/truescrolllist"
local old_TrueScrollList_SetItemsData = TrueScrollList.SetItemsData
TrueScrollList.SetItemsData = function(self, items)
    if items and next(items) ~= nil then
        for _,client in pairs(items) do
            if client.userid then
            	client.eventlevel = _G.TheWorld and _G.TheWorld.net and _G.TheWorld.net.replica.levelmanager and _G.TheWorld.net.replica.levelmanager:GetUsersLevel(client.userid) or 1
            end
        end
    end
    old_TrueScrollList_SetItemsData(self, items)
end

local old_GetSkinsDataFromClientTableData = _G.GetSkinsDataFromClientTableData
_G.GetSkinsDataFromClientTableData = function(client)
    if client and client.userid then
        client.eventlevel = _G.TheWorld and _G.TheWorld.net and _G.TheWorld.net.replica.levelmanager and _G.TheWorld.net.replica.levelmanager:GetUsersLevel(client.userid) or 1
    end
    return old_GetSkinsDataFromClientTableData(client)
end

-----------
-- Gifts --
-----------
-- Reposition Gift Icon based on user config
local GiftItemToast           = require "widgets/giftitemtoast"
local SpectatorCameraDisplay  = require("widgets/spectator_camera_display")
local TargetBadge             = require("widgets/target_badge")
local SecondaryStatusDisplays = require "widgets/secondarystatusdisplays"
AddClassPostConstruct("widgets/controls", function(self)
	if _G.REFORGED_SETTINGS.display.gift_side == "left" then
        -- add 200 into offset to be right next to max width team health badge name
        self.item_notification:SetPosition(315, 150, 0)
    elseif _G.REFORGED_SETTINGS.display.gift_side == "right" then
        self.item_notification:Kill()
		self.toastlocations = {
			{pos=_G.Vector3(-115, 150, 0)},
			{pos=_G.Vector3(-215, 150, 0)},
			{pos=_G.Vector3(-315, 150, 0)},
		}
        self.item_notification = self.topright_root:AddChild(GiftItemToast(self.owner, self))
        self.item_notification:SetPosition(-115, 150, 0)
    end

    -- Setup spectator camera
    self.ShowSpectatorCamera = function()
		self.spectator_camera:ShowCameraDisplay()
	end
    self.HideSpectatorCamera = function()
    	self.spectator_camera:HideCameraDisplay()
	end
    self.spectator_camera = self.bottom_root:AddChild(SpectatorCameraDisplay(self.owner))
    self:HideSpectatorCamera()

	local _oldShowCraftingAndInventory = self.ShowCraftingAndInventory
	self.ShowCraftingAndInventory = function()
    	if not self.craftingandinventoryshown and _G.REFORGED_SETTINGS.display.spectator_on_death then
    		self:HideSpectatorCamera()
    	end
    	_oldShowCraftingAndInventory(self)
    end

	local _oldHideCraftingAndInventory = self.HideCraftingAndInventory
	self.HideCraftingAndInventory = function()
		if self.craftingandinventoryshown and _G.REFORGED_SETTINGS.display.spectator_on_death then
			self:ShowSpectatorCamera()
		end
		_oldHideCraftingAndInventory(self)
	end

	if _G.REFORGED_SETTINGS.display.display_target_badge then
		self.target_badge = self.top_root:AddChild(TargetBadge(self.owner))
		self.target_badge:SetScale(0.8)
		self.target_badge:SetPosition(0, -75)
		self.target_badge:Hide()
	end

	-- Create Secondary Status to prevent crashing from player_common's SetGhostMode which assumes it exists
	self.secondary_status = self.sidepanel:AddChild(SecondaryStatusDisplays(self.owner))
    self.secondary_status:SetPosition(0,-110,0)
    self.secondary_status:Hide()

	-- local MapScreen = require "screens/mapscreen" local mapscr = MapScreen(ThePlayer) TheFrontEnd:PushScreen(mapscr)
	-- TheWorld.minimap.MiniMap:ShowArea(0,0,0, 10000)
	-- TheWorld.minimap.MiniMap:ShowArea(0,0,0, 10000) local MapScreen = require "screens/mapscreen" local mapscr = MapScreen(ThePlayer) TheFrontEnd:PushScreen(mapscr)
	--[[local MapScreen = require "screens/mapscreen"
	self.ShowMap = function(self, world_position)
	    if self.owner ~= nil and self.owner.HUD ~= nil and (not self.owner.HUD:IsMapScreenOpen()) then
			if self.owner.HUD:IsStatusScreenOpen() then
				_G.TheFrontEnd:PopScreen()
			end

			local mapscr = MapScreen(self.owner)
			_G.TheFrontEnd:PushScreen(mapscr)

			if world_position ~= nil and mapscr ~= nil then
				self:FocusMapOnWorldPosition(mapscr, world_position.x, world_position.z)
			end
	    end
	end--]]
end)

local DebuffDisplay = require("widgets/debuff_display")
AddClassPostConstruct("widgets/inventorybar", function(self)
	if _G.REFORGED_SETTINGS.display.player_debuff_display == "mini" then -- TODO update with the correct string value if needed
		self.debuff_display = self.root:AddChild(DebuffDisplay(self.owner, 5, false))
		self.debuff_display:SetPosition(-150, 100)
		self.debuff_display:SetTarget(self.owner)
	end
end)

-- Allow gifts to be seen and opened in the Forge
AddComponentPostInit("giftreceiver", function(self)
    local distance = _G.TUNING.RESEARCH_MACHINE_DIST*_G.TUNING.RESEARCH_MACHINE_DIST
	local old_SetGiftMachine = self.SetGiftMachine
    self.SetGiftMachine = function(self, inst)
        --[[
        -- only want to check portal dist if intermission
        if _G.TheWorld.components.lavaarenaevent and _G.TheWorld.components.lavaarenaevent:IsIntermission() then
            local portal = _G.TheWorld.multiplayerportal
            -- distsq check over findent for performance and since hardcoded for just player portal
            if portal and _G.distsq(self.inst:GetPosition(), portal:GetPosition()) <= distance then
                inst = _G.CanEntitySeeTarget(self.inst, portal) and self.inst.components.inventory.isopen and portal or inst
            end
        end--]]
        old_SetGiftMachine(self, self.inst)
    end
end)

-----------
-- Stats --
-----------
-- Edit stat file name so you can differentiate between forgedforge and regular forge
local old_GetActiveFestivalEventStatsFilePrefixfunction = _G.GetActiveFestivalEventStatsFilePrefix
_G.GetActiveFestivalEventStatsFilePrefix = function()
	local stats_file_prefix = "reforged_stats"
	return stats_file_prefix
end

--------------------
-- Damage Numbers -- TODO moved to combat?
--------------------
local function DisplayDamageNumber(inst, data)
	local leader = inst.components.follower:GetLeader()
	if leader then
		leader:SpawnChild("damage_number"):UpdateDamageNumbers(leader, data.target, math.floor(data.damageresolved + 0.5), nil, data.stimuli, false)
	end
end

AddComponentPostInit("follower", function(self)
	local old_SetLeader = self.SetLeader
	self.SetLeader = function(self, inst)
		-- Only set leader if it differs from the current leader
		if self.leader == inst then return end
		-- Remove Damage Numbers from previous leader
		if self.leader and self.leader:HasTag("player") then
			self.inst:RemoveEventCallback("onhitother", DisplayDamageNumber, self.leader)
		end
		old_SetLeader(self, inst)
		-- Add Damage Numbers for new leader
		if self.leader and self.leader:HasTag("player") then
			self.inst:ListenForEvent("onhitother", DisplayDamageNumber)
		end
	end
end)

--
AddComponentPostInit("health", function(self)
	self.buffs = {}
	self.buff_count = 0
	self.base_health = self.maxhealth
	local _oldSetMaxHealth = self.SetMaxHealth
	self.SetMaxHealth = function(self, amount)
		_oldSetMaxHealth(self, amount)
		if self.buff_count <= 0 then
			self.base_health = amount
		end
	end
	self.ScaleMaxHealth = function(self, amount)
		local percent = self:GetPercent()
		self.maxhealth = amount
		self:SetPercent(percent)
		if self.buff_count <= 0 then
			self.base_health = amount
		end
	end
	self.UpdateMaxHealth = function(self)
		local mult = 1
		local add = 1
		local flat = 0
		for _,buff in pairs(self.buffs) do
			if buff.type == "mult" then
				mult = mult * buff.val
			elseif buff.type == "add" then
				add = add + buff.val
			else
				flat = flat + buff.val
			end
		end
		self:ScaleMaxHealth(self.base_health * mult * add + flat)
	end
	self.AddHealthBuff = function(self, name, val, type)
		if self.buffs[name] then
			self:RemoveHealthBuff(name) -- TODO slightly redundant
		end
		self.buffs[name] = {val = val, type = type}
		self.buff_count = self.buff_count + 1
		self:UpdateMaxHealth()
	end
	self.GetHealthBuff = function(self, name)
		return self.buffs[name]
	end
	self.HasHealthBuff = function(self, name)
		return self.buffs[name] ~= nil
	end
	self.RemoveHealthBuff = function(self, name, type)
		self.buffs[name] = nil
		self.buff_count = self.buff_count - 1
		self:UpdateMaxHealth()
	end

	local function OnRegen(self, regen)
		if self.inst and self.inst:IsValid() and self.inst.replica.health then
	    	self.inst.replica.health:SetRegen(regen)
	    end
	end
	self.total_regen = 0
	self.regen_list = {}

	-- Value should be health per second
	self.AddRegen = function(self, source, val)
		self.regen_list[source] = val
		self:UpdateRegen()
	end
	self.HasRegen = function(self, source)
		return self.regen_list[source] ~= nil
	end
	self.RemoveRegen = function(self, source)
		self.regen_list[source] = nil
		self:UpdateRegen()
	end
	self.UpdateRegen = function(self)
		local total_regen = 0
		for source,regen in pairs(self.regen_list) do
			total_regen = total_regen + regen
		end
		-- Only update if regen has changed
		if self.total_regen ~= total_regen then
			self.total_regen = total_regen
			OnRegen(self, self.total_regen)
		end
	end

	local _oldStartRegen = self.StartRegen
	self.StartRegen = function(self, amount, period, interruptcurrentregen)
		_oldStartRegen(self, amount, period, interruptcurrentregen)
		self:AddRegen("health_component", amount/period)
	end

	local _oldStopRegen = self.StopRegen
	self.StopRegen = function(self)
	    _oldStopRegen(self)
	    self:RemoveRegen("health_component")
	end

	-- Health Tracker
	self.health_history = {}
	self.history_max = 50
	self.history_start_index = 0
	self.history_current_index = 0
	self.updatetask = self.inst:DoPeriodicTask(1, function()
		self:CacheHealth()
	end)
	self.history_rollback_dist = 10
	self.CacheHealth = function(self)
		self.history_current_index = (self.history_current_index + 1) % self.history_max
		if self.history_current_index == self.history_start_index then
			self.history_start_index = (self.history_start_index + 1) % self.history_max
		end
		self.health_history[self.history_current_index + 1] = self:GetPercent()
	end

	self.GetHistoryPosition = function(self, rewind)
		if self.history_current_index == self.history_start_index then
			return nil
		end

		local cur = self.history_current_index
		for i = 1, self.history_rollback_dist do
			if cur == self.history_start_index then
				break
			end
			cur = (cur - 1) % self.history_max
		end

		if rewind then
			self.history_current_index = cur
		end

		return self.health_history[cur + 1]
	end
end)

-- Network regen for health
AddClassPostConstruct("components/health_replica", function(self)
	self._regen = _G.net_float(self.inst.GUID, "health._regen")
	self.GetRegen = function(self)
		return self._regen:value()
	end
	self.SetRegen = function(self, val)
		return self._regen:set(val)
	end
end)

-- Update health status for teammates and pets
local function UpdateHealthStatus(self, ent, event_name)
	if not (ent and ent.replica.health) then return end
	local regen = ent.replica.health:GetPercent() < 1 and ent.replica.health:GetRegen() or 0
    local MOST_REGEN_THRESHOLD = 5
    -- These values are from the original OnUpdate function that uses self:GetOverTime()
    local status = (regen <= -MOST_REGEN_THRESHOLD and 3) or
    (regen < 0 and 4) or
    (regen >= MOST_REGEN_THRESHOLD and 2) or
    (regen > 0 and 2) or 0 -- TeammateHealthBadge does not show regen with 1 so force to 2

    if self._status:value() ~= status then
        self._status:set(status)
        self.inst:PushEvent(event_name)
    end
end
AddComponentPostInit("healthsyncer", function(self)
	self.OnUpdate = function(self, dt)
		UpdateHealthStatus(self, self.inst, "clienthealthstatusdirty")
	end
end)
AddComponentPostInit("pethealthbar", function(self)
	self.OnUpdate = function(self, dt)
		UpdateHealthStatus(self, self.pet, "clientpethealthstatusdirty")
	end
end)

AddClassPostConstruct("widgets/healthbadge", function(self)
	self.circleframe2:Hide() -- Removes the extra circle frame from the health badge.

	-- Configure the arrow display for health regen
	self.OnUpdate = function(self, dt)
	    local regen = self.owner.replica.health:GetPercent() < 1 and self.owner.replica.health:GetRegen() or 0
	    local MOST_REGEN_THRESHOLD = 9
	    local MORE_REGEN_THRESHOLD = 3
	    local anim = (regen < -MOST_REGEN_THRESHOLD and "arrow_loop_decrease_most") or
	    (regen < -MORE_REGEN_THRESHOLD and "arrow_loop_decrease_more") or
	    (regen < 0 and "arrow_loop_decrease") or
	    (regen > MOST_REGEN_THRESHOLD and "arrow_loop_increase_most") or
	    (regen > MORE_REGEN_THRESHOLD and "arrow_loop_increase_more") or
	    (regen > 0 and "arrow_loop_increase") or "neutral"

	    if self.arrowdir ~= anim then
	        self.arrowdir = anim
	        self.sanityarrow:GetAnimState():PlayAnimation(anim, true)
	    end
	end
end)

-- Add the ability to have multiple pet badges on a teammates health badge
local Badge = require "widgets/badge"
local UIAnim = require "widgets/uianim"
AddClassPostConstruct("widgets/teammatehealthbadge", function(self)
	if _G.REFORGED_SETTINGS.display.display_teammates_debuffs then
		self.debuff_display = self.name_root:AddChild(DebuffDisplay(self.owner, 50))
	end

	self._onpetadded = function(inst, data)
		self:AddPet(data.prefab, data.name)
		self:RefreshPetHealth()
	end
	self._onpetremoved = function(inst, data)
		self:RemovePet(data.prefab, data.name)
	end

	local _oldSetPlayer = self.SetPlayer
	self.SetPlayer = function(self, player)
		if _G.REFORGED_SETTINGS.display.display_teammates_debuffs then
			self.debuff_display:SetTarget(player)
		end

		_oldSetPlayer(self, player)

		-- Pet Health Display Events
		self.inst:ListenForEvent("clientpethealthdirty", self._onpethealthdirty, self.player)
		self.inst:ListenForEvent("clientpethealthsymboldirty", self._onpethealthdirty, self.player)
		self.inst:ListenForEvent("clientpetadded", self._onpetadded, self.player)
		self.inst:ListenForEvent("clientpetremoved", self._onpetremoved, self.player)

		-- Update debuff display position
		if _G.REFORGED_SETTINGS.display.display_teammates_debuffs then
			local name_left = self.name_banner_left_width - 45
			local text_w = math.max(self.name_banner_center_width, self.playername:GetRegionSize())
			local banner_right_offset = -10
			local spacing = 20
			self.debuff_display:SetPosition(name_left + text_w + banner_right_offset - 3 + self.name_banner_right_width + spacing, 0)
		end
	end

	local dist_between_slots = 30
	local starting_pos = {35, -35}
	local function GetSlotPosition(slot)
		if slot <= 0 then return _G.Vector3(0,0,0) end
		local x = dist_between_slots * (slot - 1)
		return _G.Vector3(starting_pos[1] + x, starting_pos[2], 0)
	end

	self.pet_hearts = {}
	self.pet_heart_slots = {}
	self.AddPet = function(self, prefab, name)
	    if self.pet_hearts[name] or not (prefab or name) then return end
	    local pet_heart = self:AddChild(Badge("lavaarena_pethealth", self.owner))
	    pet_heart:SetPosition(GetSlotPosition(math.max(#self.pet_heart_slots, 0)))
	    pet_heart.anim:SetScale(.75)
		pet_heart.anim:GetAnimState():Hide("stick")
		pet_heart:MoveToBack()
		pet_heart.key = name

		local prefab_info = _G.GetValidForgePrefab(prefab)
	    pet_heart.icon = pet_heart:AddChild(Image(prefab_info and prefab_info.atlas or "images/reforged.xml", prefab_info and prefab_info.atlas and prefab_info.image or "unknown_icon.tex"))
    	pet_heart.icon:ScaleToSize(35, 35, true)

		self.pet_hearts[name] = pet_heart
		table.insert(self.pet_heart_slots, pet_heart)
	    pet_heart.current_slot = math.max(#self.pet_heart_slots - 1, 0)

	    self.name_root:MoveToBack()
		self:RefreshPetHealth()
		self:StartUpdating()
	end

	self.RemovePet = function(self, prefab, name)
		if not self.pet_hearts[name] then return end
		self.pet_hearts[name].queued_for_removal = true
		self:StartUpdating()
	end

	self.RemovePetHealth = function()
		for i,pet_heart in pairs(self.pet_heart_slots) do
			pet_heart.queued_for_removal = true
		end
		self.inst:RemoveEventCallback("clientpethealthdirty", self._onpethealthdirty, self.player)
		self.inst:RemoveEventCallback("clientpethealthsymboldirty", self._onpethealthdirty, self.player)
		self.inst:RemoveEventCallback("clientpetadded", self._onpethealthdirty, self.player)
		self.inst:RemoveEventCallback("clientpetremoved", self._onpethealthdirty, self.player)
		self:StartUpdating()
	end

	self.RefreshPetHealth = function()
		local pethealthbars = self.player ~= nil and self.player:IsValid() and self.player.components.pethealthbars or nil
		if pethealthbars == nil then
			return
		end

		for name,pet_heart in pairs(self.pet_hearts) do
			local pet_info = pethealthbars:GetPetInfo(name)
			if pet_info then
				local symbol = pet_info.symbol
				if symbol == 0 then
					pet_heart:Hide()
				else
					if symbol then
			        	pet_heart.anim:GetAnimState():OverrideSymbol("pet_abigail", "lavaarena_pethealth", symbol)
			        	pet_heart.anim:GetAnimState():ShowSymbol("pet_abigail")
			        	pet_heart.icon:Hide()
			        else
			        	pet_heart.anim:GetAnimState():HideSymbol("pet_abigail")
		    			pet_heart.icon:Show()
		    			pet_heart.icon:SetTint(unpack(pet_info.health_percent > 0 and {1,1,1,1} or {0,0,0,0.5}))
			        end
			        pet_heart:Show()
				end

				local percent = pet_info.health_percent
				if percent then
					percent = percent == 0 and 0 or math.max(percent, 0.001)
					pet_heart:SetPercent(percent)
				end
			end
		end
	end

	self.IsShowingPet = function()
		return self.pet_heart ~= nil and self.pet_heart:IsVisible()
	end

	self.OnUpdate = function(self, dt)
		local is_animating = false
		local remove_pet_hearts = {}
		for i,pet_heart in pairs(self.pet_heart_slots) do
			-- Handle Pet Heart Movement
			local previous_heart = i > 1 and self.pet_heart_slots[i-1]
			pet_heart.target_slot = pet_heart.queued_for_removal and (previous_heart and previous_heart.current_slot or 0) or previous_heart and previous_heart.target_slot ~= previous_heart.current_slot and (i - 1) or i
			if pet_heart.target_slot ~= pet_heart.current_slot then
				is_animating = true
				-- Move Pet Heart towards it's next slot
				local current_pos = pet_heart:GetPosition()
				local slot_pos = GetSlotPosition(pet_heart.current_slot + (pet_heart.current_slot > pet_heart.target_slot and -1 or 1))
				local offset = current_pos - slot_pos
				offset.x = offset.x ~= 0 and (offset.x/offset.x * (offset.x > 0 and -1 or 1)) or 0
				offset.y = offset.y ~= 0 and (offset.y/offset.y * (offset.y > 0 and -1 or 1)) or 0
				pet_heart:SetPosition(current_pos + offset)

				-- Update Current Slot
				if current_pos == slot_pos then
					pet_heart.current_slot = pet_heart.current_slot + (pet_heart.current_slot > pet_heart.target_slot and -1 or 1)
				end
			elseif pet_heart.queued_for_removal then
				table.insert(remove_pet_hearts, i)
			end
		end
		-- Remove any pet hearts that are ready for removal
		for i,slot in pairs(remove_pet_hearts) do
			local pet_heart = self.pet_heart_slots[slot]
			table.remove(self.pet_heart_slots, slot - (i-1))
			self.pet_hearts[pet_heart.key] = nil
			pet_heart:Kill()
		end

		-- Only stop updating if no health nodes are moving.
		if not is_animating then
	    	self:StopUpdating()
	    end
	end
end)

--[[
TODO
	wendy listens to the pet skin event, will need to remove or try to override it
	need connector
--]]
-- Add the ability to have multiple pet badges
AddClassPostConstruct("widgets/statusdisplays_lavaarena", function(self)
	local min_y = -100
	local max_y = 0
	local max_unique_slots = 6
	local slots_per_col = 3
	local indents = {0, 30, 25}
	local dist_between_slots = 50
	local slot_y = {
		[1] = max_y,
		[2] = max_y - dist_between_slots,
		[3] = min_y,
		[4] = min_y,
		[5] = max_y - dist_between_slots,
		[6] = max_y,
	}
	local starting_pos = {-40, 70}
	local function GetSlotPosition(slot)
		if slot <= 0 then return _G.Vector3(0,0,0) end
		local index = (slot - 1) % max_unique_slots + 1
		local col = math.ceil(slot/slots_per_col)
		local set = math.ceil(slot/max_unique_slots)
		local x = -dist_between_slots * (col - 1) - (indents[((index > 3 and (-index + 1) or index) - 1) % 3 + 1])
		local y = slot_y[index]
		return _G.Vector3(starting_pos[1] + x, starting_pos[2] + y, 0)
	end
	self.pet_hearts = {}
	self.pet_heart_slots = {}
	self.AddPet = function(self, prefab, name)
		if self.pet_hearts[name] then return end
	    local pet_heart = self:AddChild(Badge("lavaarena_pethealth", self.owner))
	    pet_heart.anim:GetAnimState():Show("frame")

	    local slot_pos = GetSlotPosition(math.max(#self.pet_heart_slots, 0))
	    pet_heart:SetPosition(slot_pos)
	    pet_heart.anim:SetScale(.8)
	    pet_heart:MoveToBack()

	    pet_heart._arrowdir = 0

	    pet_heart.arrow = pet_heart.underNumber:AddChild(UIAnim())
	    pet_heart.arrow:GetAnimState():SetBank("sanity_arrow")
	    pet_heart.arrow:GetAnimState():SetBuild("sanity_arrow")
	    pet_heart.arrow:GetAnimState():PlayAnimation("neutral")
	    pet_heart.arrow:SetScale(0.75)

	    pet_heart.anim:GetAnimState():HideSymbol("connector")

	    pet_heart.key = name

		local prefab_info = _G.GetValidForgePrefab(prefab)
	    pet_heart.icon = pet_heart:AddChild(Image(prefab_info and prefab_info.atlas or "images/reforged.xml", prefab_info and prefab_info.atlas and prefab_info.image or "unknown_icon.tex"))
    	pet_heart.icon:ScaleToSize(35, 35, true)
    	pet_heart.num:MoveToFront()

	    self.pet_hearts[name] = pet_heart
	    table.insert(self.pet_heart_slots, pet_heart)
	    pet_heart.current_slot = math.max(#self.pet_heart_slots - 1, 0)
	    self:StartUpdating()
	end
	self.owner:ListenForEvent("clientpetadded", function(inst, data)
		self:AddPet(data.prefab, data.name)
		self:RefreshPetHealth()
	end)

	-- TODO removal anim?
	self.RemovePet = function(self, prefab, name)
		if not self.pet_hearts[name] then return end
		if self.visiblemode then
			self.pet_hearts[name].queued_for_removal = true
			self:StartUpdating()
		else
			for i,pet_heart in pairs(self.pet_heart_slots) do
				if self.pet_hearts[name] == pet_heart then
					pet_heart:Kill()
					self.pet_hearts[name] = nil
					table.remove(self.pet_heart_slots, i)
					break
				end
			end
		end
	end
	self.owner:ListenForEvent("clientpetremoved", function(inst, data)
		self:RemovePet(data.prefab, data.name)
	end)

	local function OnSetVisibleMode(inst, self)
	    self.modetask = nil

	    if self.onhealthdelta == nil then
	        self.onhealthdelta = function(owner, data) self:HealthDelta(data) end
	        inst:ListenForEvent("healthdelta", self.onhealthdelta, self.owner)
	        self.healthmax = self:SetHealthPercent(self.owner.replica.health:GetPercent())
	        self.queuedhealthmax = self.healthmax

	        self.onpethealthdirty = function() self:RefreshPetHealth() end
	        inst:ListenForEvent("clientpethealthdirty", self.onpethealthdirty, self.owner)
	        inst:ListenForEvent("clientpethealthsymboldirty", self.onpethealthdirty, self.owner)
	        inst:ListenForEvent("clientpetmaxhealthdirty", self.onpethealthdirty, self.owner)
	        inst:ListenForEvent("clientpethealthstatusdirty", self.onpethealthdirty, self.owner)
	        if self.owner.components.pethealthbars then
	            self:RefreshPetHealth()
	        end
	    end
	end
	local function OnSetHiddenMode(inst, self)
	    self.modetask = nil

	    if self.onhealthdelta ~= nil then
	        self.inst:RemoveEventCallback("healthdelta", self.onhealthdelta, self.owner)
	        self.onhealthdelta = nil
	    end

	    self:StopUpdating()
	end
	self.UpdateMode = function(self)
	    if self.visiblemode == not (self.isghostmode or self.craft_hide) then
	        return
	    end

	    self.visiblemode = not self.visiblemode

	    if self.visiblemode then
	        self.heart:Show()
	        for i,pet_heart in pairs(self.pet_heart_slots) do
	        	pet_heart:SetPosition(GetSlotPosition(i))
	        	pet_heart.current_slot = i
		    	pet_heart:Show()
		    end
	    else
	        self.heart:Hide()
	        for _,pet_heart in pairs(self.pet_hearts) do
		    	pet_heart:Hide()
		    end

	        -- Remove any pet hearts that are queued for removal
	        local remove_pet_hearts = {}
	        for i,pet_heart in pairs(self.pet_heart_slots) do
	        	if pet_heart.queued_for_removal then
	        		table.insert(remove_pet_hearts, i)
	        	end
	        end
			for i,slot in pairs(remove_pet_hearts) do
				local pet_heart = self.pet_heart_slots[slot]
				table.remove(self.pet_heart_slots, slot - (i-1))
				self.pet_hearts[pet_heart.key] = nil
				pet_heart:Kill()
			end
	    end

	    if self.modetask ~= nil then
	        self.modetask:Cancel()
	    end
	    self.modetask = self.inst:DoTaskInTime(0, self.visiblemode and OnSetVisibleMode or OnSetHiddenMode, self)
	end

	local _oldShowStatusNumbers = self.ShowStatusNumbers
	self.ShowStatusNumbers = function(self)
	    _oldShowStatusNumbers(self)
	    for _,pet_heart in pairs(self.pet_hearts) do
	    	pet_heart.num:Show()
	    end
	end

	local _oldHideStatusNumbers = self.HideStatusNumbers
	self.HideStatusNumbers = function(self)
	    _oldHideStatusNumbers(self)
	    for _,pet_heart in pairs(self.pet_hearts) do
	    	pet_heart.num:Hide()
	    end
	end

	self.RefreshPetHealth = function()
	    local pethealthbars = self.owner ~= nil and self.owner:IsValid() and self.owner.components.pethealthbars or nil
	    if not pethealthbars then return end

		local current_pets = pethealthbars:GetPetsInfo()
	    for name,info in pairs(current_pets) do
	    	-- Create a pet heart if one does not already exist for the pet.
	    	if not self.pet_hearts[name] then
	    		self:AddPet(info.prefab, name)
	    	end
	    	local pet_heart = self.pet_hearts[name]

	    	if info.symbol == 0 then
	    		pet_heart:Hide()
	    	else
	    		if self.heart:IsVisible() then
		            pet_heart:Show()
		        end
		        if info.symbol then
		        	pet_heart.anim:GetAnimState():OverrideSymbol("pet_abigail", "lavaarena_pethealth", info.symbol)
		        	pet_heart.anim:GetAnimState():ShowSymbol("pet_abigail")
		        	pet_heart.icon:Hide()
		        else
		        	pet_heart.anim:GetAnimState():HideSymbol("pet_abigail")
	    			pet_heart.icon:Show()
	    			pet_heart.icon:SetTint(unpack(info.health_percent > 0 and {1,1,1,1} or {0,0,0,0.5}))
		        end
	    	end

		    local arrowdir = info.status or 0
		    if pet_heart._arrowdir ~= arrowdir then
		        pet_heart._arrowdir = arrowdir
		        pet_heart.arrow:GetAnimState():PlayAnimation((arrowdir > 1 and "arrow_loop_increase_most") or (arrowdir < 0 and "arrow_loop_decrease_most") or "neutral", true)
		    end

		    local percent = info.health_percent
		    if percent then
				percent = percent == 0 and 0 or math.max(percent, 0.001)
		        local health = percent * info.max_health
		        pet_heart.num:SetScale( (health >= 200 and .7) or (health > 100 and 0.85) or 1)
		        pet_heart:SetPercent(percent, info.max_health)
		    end
	    end
	end

	local _oldHealthDelta = self.HealthDelta
	self.HealthDelta = function(self, data)
		_oldHealthDelta(self, data)
		-- Force it to update even if it shouldn't just in case the original health delta stops it when it shouldn't
		self:StartUpdating()
	end

	self.OnUpdate = function(self, dt)
		-- Handle Queued Player Max Health
		if self.queuedhealthmax ~= self.healthmax then
		    if self.queuedhealthmax > self.healthmax then
		        self.heart:PulseGreen()
		        _G.TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/health_up")
		    elseif self.queuedhealthmax < self.healthmax then
		        self.heart:PulseRed()
		        _G.TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/health_down")
		    end
		    self.healthmax = self.queuedhealthmax
		end

		if self.visiblemode then
			local is_animating = false
			local remove_pet_hearts = {}
			for i,pet_heart in pairs(self.pet_heart_slots) do

				-- Handle Pet Heart Movement
				local previous_heart = i > 1 and self.pet_heart_slots[i-1]
				pet_heart.target_slot = pet_heart.queued_for_removal and (previous_heart and previous_heart.current_slot or 0) or previous_heart and previous_heart.target_slot ~= previous_heart.current_slot and (i - 1) or i
				if pet_heart.target_slot ~= pet_heart.current_slot then
					is_animating = true
					-- Move Pet Heart towards it's next slot
					local current_pos = pet_heart:GetPosition()
					local slot_pos = GetSlotPosition(pet_heart.current_slot + (pet_heart.current_slot > pet_heart.target_slot and -1 or 1))
					local offset = current_pos - slot_pos
					offset.x = offset.x ~= 0 and (offset.x/offset.x * (offset.x > 0 and -1 or 1)) or 0
					offset.y = offset.y ~= 0 and (offset.y/offset.y * (offset.y > 0 and -1 or 1)) or 0
					pet_heart:SetPosition(current_pos + offset)

					-- Update Current Slot
					if current_pos == slot_pos then
						pet_heart.current_slot = pet_heart.current_slot + (pet_heart.current_slot > pet_heart.target_slot and -1 or 1)
					end
				elseif pet_heart.queued_for_removal then
					table.insert(remove_pet_hearts, i)
				end
			end
			-- Remove any pet hearts that are ready for removal
			for i,slot in pairs(remove_pet_hearts) do
				local pet_heart = self.pet_heart_slots[slot]
				table.remove(self.pet_heart_slots, slot - (i-1))
				self.pet_hearts[pet_heart.key] = nil
				pet_heart:Kill()
			end

			-- Only stop updating if no health nodes are moving.
			if not is_animating then
		    	self:StopUpdating()
		    end
		else
			self:StopUpdating()
		end
	end
end)

-- Removes the spawners connection to its children so that the highlight component doesn't try to reference a stale component.
AddPrefabPostInit("lavaarena_spawner", function(inst)
	if not _G.TheNet:IsDedicated() then
		for _,ent in pairs(inst.highlightchildren) do
			local _oldRemove = ent.Remove
			ent.Remove = function(inst)
				local parent = inst.entity:GetParent()
				for i,ent in pairs(parent and parent.highlightchildren or {}) do
					if inst == ent then
						table.remove(parent.highlightchildren, i)
					end
				end
				_oldRemove(inst)
			end
		end
	end
end)

-- Adds the option to override or add onto existing health trigger functions
-- Adds the ability to remove health triggers for the healthtrigger component
AddComponentPostInit("healthtrigger", function(self)
	self.AddTrigger = function(self, amount, fn, override)
		if self.triggers[amount] and not override then
			local _oldTriggerFN = self.triggers[amount]
			self.triggers[amount] = function(inst)
				_oldTriggerFN(inst)
				fn(inst)
			end
		else
			self.triggers[amount] = fn
		end
	end
	self.RemoveTrigger = function(self, amount)
		self.triggers[amount] = nil
	end
end)

-------------
-- SLEEPER --
-------------
-- TODO
-- forcing sleep state causes infinite sleep because the sleeper component does not see the ent asleep
-- wants to sleep could be causing this if not being reset
AddComponentPostInit("sleeper", function(self)
	-- Saves the queued sleeptime for an ent who is currently in a state where they cannot sleep.
	local _oldGoToSleep = self.GoToSleep
	self.GoToSleep = function(self, sleeptime, caster)
		if not self.inst:HasTag("nosleep") then
			self.caster = caster -- save caster for stat tracking
			self.inst.sg.mem.sleep_duration = sleeptime
			if not (self.inst.sg:HasStateTag("delaysleep") or self.inst.sg:HasStateTag("nosleep") or self.inst.sg:HasStateTag("nointerrupt")) then -- TODO nosleep was checked in sleepers gotosleep and made it so it did not stop the entity from moving and the mob still went to sleep. Double check all mobs that use nosleep to make sure they are using it correctly.
				_oldGoToSleep(self, sleeptime)
			end
		end
	end

	-- Updates the stat tracking for cctime
	local _oldWakeUp = self.WakeUp
	self.WakeUp = function(self)
		if self.isasleep and self.caster and TheWorld and TheWorld.components.stat_tracker then
			TheWorld.components.stat_tracker:AdjustStat("cctime", self.caster, GetTime() - self.sleep_start)
			self.sleep_start = nil
			self.caster = nil
		end
		self.inst.sg.mem.sleep_duration = nil
		_oldWakeUp(self)
	end
end)

--------------
-- Replicas --
--------------
AddReplicableComponent("passive_bloom")
AddReplicableComponent("lobbyvote")
AddReplicableComponent("perk_tracker")
--AddReplicableComponent("leaderboardmanager")
AddReplicableComponent("levelmanager")
AddReplicableComponent("achievementmanager")
AddReplicableComponent("mutatormanager")
AddReplicableComponent("serverinfomanager")
--AddReplicableComponent("fxnetwork")
AddReplicableComponent("complexprojectile")
AddReplicableComponent("scaler")
AddReplicableComponent("debuffable")

----------------
-- StateGraph --
----------------
-- TODO add to mod api
-- Returns true if the given object contains all of the tags given or if cant_have is set then returns true if the object contains none of the tags.
local function CheckTags(obj, tags, cant_have)
	for _,tag in pairs(tags or {}) do
		if not cant_have and not obj:HasTag(tag) then
			return false
		elseif cant_have and obj:HasTag(tag) then
			return false
		end
	end
	return true
end

local function GetState(obj, states, server)
	if not obj then return states.default end
	for index,info in pairs(states) do
		if index ~= "default" and (info.server_only and server or not info.server_only) and CheckTags(obj, info.must_tags) and CheckTags(obj, info.cant_tags, true) then
			return info.state
		end
	end
	return states.default
end

local function AltActionHandler(inst, action)
	return GetState(action.invobject, _G.TUNING.FORGE.CASTAOE_TAG_TO_STATE)
end

local function ClientAttackActionHandler(inst, action)
    inst.sg.mem.localchainattack = not action.forced or nil
    if not (inst.sg:HasStateTag("attack") and action.target == inst.sg.statemem.attacktarget or inst.replica.health:IsDead()) then
        local equip = inst.replica.inventory:GetEquippedItem(_G.EQUIPSLOTS.HANDS)
        if equip == nil then
            return "attack"
        end
        local inventoryitem = equip.replica.inventoryitem
        return GetState(inventoryitem ~= nil and inventoryitem:IsWeapon() and equip, _G.TUNING.FORGE.ATTACK_TAG_TO_STATE)
    end
end

local function AttackActionHandler(inst, action)
    inst.sg.mem.localchainattack = not action.forced or nil
    if not (inst.sg:HasStateTag("attack") and action.target == inst.sg.statemem.attacktarget or inst.replica.health:IsDead()) then
        local weapon = inst.replica.combat and inst.replica.combat:GetWeapon() or nil
        return GetState(weapon, _G.TUNING.FORGE.ATTACK_TAG_TO_STATE, true)
    end
end

local function GetCustomPickupState(target)
	for state,tags in pairs(_G.TUNING.FORGE.CUSTOM_PICKUP_TAGS) do
		for _,tag in pairs(tags) do
			if target:HasTag(tag) then
				return state
			end
		end
	end
end

local function ClientPickupActionHandler(inst, action)
    return (inst.replica.rider ~= nil and inst.replica.rider:IsRiding()
            and (action.target ~= nil and action.target:HasTag("heavy") and "dodismountaction" -- Heavy item while riding
                or "domediumaction"))                                                          -- Non heavy item while riding
    	or action.target ~= nil and GetCustomPickupState(action.target)                        -- Custom Pickup (ex. active traps)
        or "doshortaction"
end

local function PickupActionHandler(inst, action)
    return (action.target ~= nil and action.target:HasTag("minigameitem") and "dosilentshortaction") -- Minigame item
			or (inst.components.rider ~= nil and inst.components.rider:IsRiding()                    --
			and (action.target ~= nil and action.target:HasTag("heavy") and "dodismountaction"       -- Heavy item while riding
			or "domediumaction"))                                                                    -- Non heavy item while riding
		or action.target ~= nil and GetCustomPickupState(action.target)                              -- Custom Pickup (ex. active traps)
        or "doshortaction"
end

local action_handlers = {
	CASTAOE = {server = AltActionHandler,    client = AltActionHandler},
	ATTACK  = {server = AttackActionHandler, client = ClientAttackActionHandler},
	PICKUP  = {server = PickupActionHandler, client = ClientPickupActionHandler}
}

for action,fns in pairs(action_handlers) do
	AddStategraphActionHandler("wilson",        _G.ActionHandler(_G.ACTIONS[action], fns.server))
	AddStategraphActionHandler("wilson_client", _G.ActionHandler(_G.ACTIONS[action], fns.client))
end

local TimeEvent = _G.TimeEvent
local FRAMES = _G.FRAMES
local EventHandler = _G.EventHandler
local State = _G.State

-- Fox: We need to change the projectile sounds, but they are triggered in SG!
local sounds = {
	livingstaff = "heal_staff",
	infernalstaff = "fireball",
}
local function ChooseSound(self)
	local _attack = self.states.attack.onenter
	self.states.attack.onenter = function(inst)
		local equip = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

		if equip and sounds[equip.prefab] then
			inst.sg.statemem.projectilesound = "dontstarve/common/lava_arena/"..sounds[equip.prefab]
		end

		_attack(inst)
	end
end
-- Add check to read book for any entity with the tag "aspiring_bookworm" like Wurt.
local function ApiringBookworm(self)
	local _oldBookOnEnter = self.states.book.onenter
	self.states.book.onenter = function(inst)
		if inst:HasTag("aspiring_bookworm") then
			inst.sg:GoToState("book_peruse")
		else
			_oldBookOnEnter(inst)
		end
	end
end

local function OnRemoveCleanupTargetFX(inst)
	if inst.sg.statemem.targetfx == nil then return end
    if inst.sg.statemem.targetfx.KillFX ~= nil then
        inst.sg.statemem.targetfx:RemoveEventCallback("onremove", OnRemoveCleanupTargetFX, inst)
        inst.sg.statemem.targetfx:KillFX()
    else
        inst.sg.statemem.targetfx:Remove()
    end
end
-- Add check to read book for any entity with the tag "aspiring_bookworm" like Wurt.
local function CustomRet(self)
	local function ReticuleSetup(inst, reticule)
		if not reticule then return end
		-- Set Color of Reticule
		local buffaction = inst:GetBufferedAction()
		local equip = inst.components.inventory:GetEquippedItem(_G.EQUIPSLOTS.HANDS)
		local ret = equip and equip.components.aoetargeting.reticule
        if buffaction.options and ret and ret.validcolours and #ret.validcolours > 0 and inst.sg.statemem.targetfx.SetColour then
			local colour = ret.validcolours[buffaction.options.ctrl or 1]
			inst.sg.statemem.targetfx:SetColour(colour) -- TODO need to add this function to all reticules, only our custom ret supports this
		end
		-- Scale Reticule
		local base_scale = 1.5 -- All reticules are scaled up to 1.5
		local scale = (inst.replica.scaler and inst.replica.scaler:GetScale() or 1) * base_scale
		inst.sg.statemem.targetfx.AnimState:SetScale(scale,scale)
	end

	local _oldThrowLineOnEnter = self.states.throw_line.onenter
	self.states.throw_line.onenter = function(inst)
		local buffaction = inst:GetBufferedAction()
        local equip = inst.components.inventory:GetEquippedItem(_G.EQUIPSLOTS.HANDS)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("atk_pre")

        if buffaction ~= nil and buffaction.pos ~= nil then
            inst:ForceFacePoint(buffaction:GetActionPoint():Get())

            if equip ~= nil and equip.components.aoetargeting ~= nil and equip.components.aoetargeting.targetprefab ~= nil then
                inst.sg.statemem.targetfx = _G.SpawnPrefab(equip.components.aoetargeting.targetprefab)
                if inst.sg.statemem.targetfx ~= nil then
                    inst.sg.statemem.targetfx.Transform:SetPosition(buffaction:GetActionPoint():Get())
                    inst.sg.statemem.targetfx:ListenForEvent("onremove", OnRemoveCleanupTargetFX, inst)
                    local ret = equip.components.aoetargeting.reticule
					ReticuleSetup(inst, inst.sg.statemem.targetfx)
                end
            end
        end -- local ret = SpawnPrefab("forge_reticule") ret.Transform:SetPosition(c_sel():GetPosition():Get()) ret.colour = {1,0,0,1}

        if (equip ~= nil and equip.projectiledelay or 0) > 0 then
            --V2C: Projectiles don't show in the initial delayed frames so that
            --     when they do appear, they're already in front of the player.
            --     Start the attack early to keep animation in sync.
            inst.sg.statemem.projectiledelay = 7 * FRAMES - equip.projectiledelay
            if inst.sg.statemem.projectiledelay <= 0 then
                inst.sg.statemem.projectiledelay = nil
            end
        end

        inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
	end

	local _oldBookOnEnter = self.states.book.onenter
	self.states.book.onenter = function(inst)
		_oldBookOnEnter(inst)
		ReticuleSetup(inst, inst.sg.statemem.targetfx)
	end

	local _oldCastSpellOnEnter = self.states.castspell.onenter
	self.states.castspell.onenter = function(inst)
		_oldCastSpellOnEnter(inst)
		ReticuleSetup(inst, inst.sg.statemem.targetfx)
	end

	local _oldCombatLeapStartOnEnter = self.states.combat_leap_start.onenter
	self.states.combat_leap_start.onenter = function(inst)
		_oldCombatLeapStartOnEnter(inst)
		ReticuleSetup(inst, inst.sg.statemem.targetfx)
	end

	-- Adjust speed of combat leap based on the players current scale
	local _oldCombatLeapOnEnter = self.states.combat_leap.onenter
	self.states.combat_leap.onenter = function(inst, data)
		_oldCombatLeapOnEnter(inst, data)
        if inst.sg.statemem.startingpos and inst.sg.statemem.targetpos and (inst.sg.statemem.startingpos.x ~= inst.sg.statemem.targetpos.x or inst.sg.statemem.startingpos.z ~= inst.sg.statemem.targetpos.z) then
            inst.Physics:SetMotorVel(math.sqrt(_G.distsq(inst.sg.statemem.startingpos.x, inst.sg.statemem.startingpos.z, inst.sg.statemem.targetpos.x, inst.sg.statemem.targetpos.z)) / (12 * FRAMES * inst.components.scaler.scale), 0 ,0)
        end
	end

	local _oldCombatJumpStartOnEnter = self.states.combat_superjump_start.onenter
	self.states.combat_superjump_start.onenter = function(inst)
		_oldCombatJumpStartOnEnter(inst)
		ReticuleSetup(inst, inst.sg.statemem.targetfx)
	end

	local _oldBookOnEnter = self.states.book.onenter
	self.states.book.onenter = function(inst)
		_oldBookOnEnter(inst)
		ReticuleSetup(inst, inst.sg.statemem.targetfx)
	end
end
--[[
local function CombatPunch(self)
	self.states.combat_lunge_start.events.combat_punch = _G.EventHandler("combat_punch", function(inst, data)
        inst.sg:GoToState("combat_punch", data)
    end)
end]]

-- Speed up punching anim a bit
local PUNCH_SPEED = 24/13 -- 13 is basic attack length, where 24 is punch anim
local PUNCH_TIME = 5 * _G.FRAMES

local function FasterPunch(isserver)
	return function(self)
		local _attack_onenter = self.states.attack.onenter
		local _attack_onexit = self.states.attack.onexit
		self.states.attack.onenter = function(inst, ...)
			_attack_onenter(inst, ...)
			local equip = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
			if equip and equip:HasTag("punch") then
				inst.sg:SetTimeout(13 * _G.FRAMES)
				inst.AnimState:SetDeltaTimeMultiplier(PUNCH_SPEED)
				inst.sg.statemem.ispunching = true
			end
		end

		self.states.attack.onexit = function(inst, ...)
			_attack_onexit(inst, ...)
			if inst.sg.statemem.ispunching then
				inst.AnimState:SetDeltaTimeMultiplier(1)
			end
		end

		-- Update timeline
		-- Kinda ugly, kinda gross, but we don't have other way of doing it
		local _attack_event = self.states.attack.timeline[4].fn
		self.states.attack.timeline[4].fn = function(inst, ...)
			if inst.sg.statemem.ispunching then
				return
			end
			return _attack_event(inst, ...)
		end
		table.insert(self.states.attack.timeline, TimeEvent(PUNCH_TIME, function(inst)
			if inst.sg.statemem.ispunching then
				if isserver then
					inst:PerformBufferedAction()
				else
					inst:ClearBufferedAction()
				end
				inst.sg:RemoveStateTag("abouttoattack")
			end
		end))
		local function pred(a,b)
			return a.time < b.time
		end
		table.sort(self.states.attack.timeline, pred)
	end
end

-- Allows gifts to be opened while in danger.
-- NOTE: The majority of this is copied from klei since we only wanted to remove a small portion of it.
local function OpenGiftsWhenInDanger(self)
	self.states.opengift.onenter = function(inst)
		inst.components.locomotor:Stop()
        inst.components.locomotor:Clear()
        inst:ClearBufferedAction()

        local failstr = inst.components.rider:IsRiding() and "ANNOUNCE_NOMOUNTEDGIFT" or nil

        if failstr then
            inst.sg.statemem.isfailed = true
            inst.sg:GoToState("idle")
            if inst.components.talker then
                inst.components.talker:Say(GetString(inst, failstr))
            end
            return
        end

        if inst.components.inventory:IsHeavyLifting() then
	        inst.components.inventory:DropItem(inst.components.inventory:Unequip(_G.EQUIPSLOTS.BODY), true, true)
	    end

        inst.SoundEmitter:PlaySound("dontstarve/common/player_receives_gift")
        inst.AnimState:PlayAnimation("gift_pre")
        inst.AnimState:PushAnimation("giift_loop", true)
        -- NOTE: the previously used ripping paper anim is called "giift_loop"

        if inst.components.playercontroller then
            inst.components.playercontroller:RemotePausePrediction()
            inst.components.playercontroller:EnableMapControls(false)
            inst.components.playercontroller:Enable(false)
        end
        inst.components.inventory:Hide()
        inst:PushEvent("ms_closepopups")
        inst:ShowActions(false)
        inst:ShowPopUp(_G.POPUPS.GIFTITEM, true)

        if inst.components.giftreceiver then
            inst.components.giftreceiver:OnStartOpenGift()
        end
	end
end

local function DoWortoxPortalTint(inst, val)
    if val > 0 then
        inst.components.colouradder:PushColour("portaltint", 154 / 255 * val, 23 / 255 * val, 19 / 255 * val, 0)
        val = 1 - val
        inst.components.colouradder:PushColour("portaltint", val, val, val, 1, nil, nil, true)
    else
        inst.components.colouradder:PopColour("portaltint")
        inst.components.colouradder:PopColour("portaltint", nil, nil, true)
    end
end

local JumpOnUpdate = function(inst)
	if inst.sg.statemem.tints ~= nil then
        DoWortoxPortalTint(inst, table.remove(inst.sg.statemem.tints))
        if #inst.sg.statemem.tints <= 0 then
            inst.sg.statemem.tints = nil
        end
    end
end

local function JumpOnExit(inst)
	inst.components.health:SetInvincible(false)
    inst.DynamicShadow:Enable(true)
    DoWortoxPortalTint(inst, 0)
end

local function ToggleOffPhysics(inst)
    inst.sg.statemem.isphysicstoggle = true
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(_G.COLLISION.GROUND)
end

local function ToggleOnPhysics(inst)
    inst.sg.statemem.isphysicstoggle = nil
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(_G.COLLISION.WORLD)
    inst.Physics:CollidesWith(_G.COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(_G.COLLISION.SMALLOBSTACLES)
    inst.Physics:CollidesWith(_G.COLLISION.CHARACTERS)
    inst.Physics:CollidesWith(_G.COLLISION.GIANTS)
end

local function FixPlayerTeleportTinting(self)
    ----------------
	-- Super Jump --
	----------------
	local superjump_state = self.states.combat_superjump
	superjump_state.onenter = function(inst, data)
        if data ~= nil then
            inst.sg.statemem.targetfx = data.targetfx
            inst.sg.statemem.data = data
            data = data.data
            if data ~= nil and
                data.targetpos ~= nil and
                data.weapon ~= nil and
                data.weapon.components.aoeweapon_leap ~= nil and
                inst.AnimState:IsCurrentAnimation("superjump_lag") then
                ToggleOffPhysics(inst)
                inst.AnimState:PlayAnimation("superjump")
                inst.components.colouradder:PushColour("superjump", 0.8, 0.8, 0.8, 1, nil, nil, true)
                inst.components.colouradder:PushColour("superjump", 0.1, 0.1, 0.1, 0)
                inst.sg.statemem.data.startingpos = inst:GetPosition()
                inst.sg.statemem.weapon = data.weapon
                if inst.sg.statemem.data.startingpos.x ~= data.targetpos.x or inst.sg.statemem.data.startingpos.z ~= data.targetpos.z then
                    inst:ForceFacePoint(data.targetpos:Get())
                end
                inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt", nil, 0.4)
                inst.SoundEmitter:PlaySound("dontstarve/common/deathpoof")
                inst.sg:SetTimeout(1)
                return
            end
        end
        --Failed
        inst.sg:GoToState("idle", true)
    end

    superjump_state.onupdate = function(inst)
        if inst.sg.statemem.dalpha ~= nil and inst.sg.statemem.alpha > 0 then
            inst.sg.statemem.dalpha = math.max(0.1, inst.sg.statemem.dalpha - 0.1)
            inst.sg.statemem.alpha = math.max(0, inst.sg.statemem.alpha - inst.sg.statemem.dalpha)
            inst.components.colouradder:PushColour("superjump", 0, 0, 0, inst.sg.statemem.alpha, nil, nil, true)
        end
    end

    superjump_state.timeline[1].fn = function(inst)
        inst.DynamicShadow:Enable(false)
        inst.sg:AddStateTag("noattack")
        inst.components.health:SetInvincible(true)
        inst.components.colouradder:PushColour("superjump", 0.5, 0.5, 0.5, 01, nil, nil, true)
        inst.components.colouradder:PushColour("superjump", 0.3, 0.3, 0.2, 0)
        inst:PushEvent("dropallaggro")
        if inst.sg.statemem.weapon ~= nil and inst.sg.statemem.weapon:IsValid() then
            inst.sg.statemem.weapon:PushEvent("superjumpstarted", inst)
        end
    end
    superjump_state.timeline[2].fn = function(inst)
        inst.components.colouradder:PushColour("superjump", 0, 0, 0, 1, nil, nil, true)
        inst.components.colouradder:PushColour("superjump", 0.6, 0.6, 0.4, 0)
    end

    superjump_state.onexit = function(inst)
        if not inst.sg.statemem.superjump then
            inst.components.health:SetInvincible(false)
            if inst.sg.statemem.isphysicstoggle then
                ToggleOnPhysics(inst)
            end
            inst.components.colouradder:PopColour("superjump")
            inst.components.colouradder:PopColour("superjump", nil, nil, true)
            inst.DynamicShadow:Enable(true)
            if inst.sg.statemem.weapon ~= nil and inst.sg.statemem.weapon:IsValid() then
                inst.sg.statemem.weapon:PushEvent("superjumpcancelled", inst)
            end
        end
        if inst.sg.statemem.targetfx ~= nil and inst.sg.statemem.targetfx:IsValid() then
            OnRemoveCleanupTargetFX(inst)
        end
        inst:Show()
    end
	----------------
	-- Super Jump --
	----------------
    local superjump_pst_state = self.states.combat_superjump_pst

	superjump_pst_state.onenter = function(inst, data)
        if data ~= nil and data.data ~= nil then
            inst.sg.statemem.startingpos = data.startingpos
            inst.sg.statemem.isphysicstoggle = data.isphysicstoggle
            data = data.data
            inst.sg.statemem.weapon = data.weapon
            if inst.sg.statemem.startingpos ~= nil and
                data.targetpos ~= nil and
                data.weapon ~= nil and
                data.weapon.components.aoeweapon_leap ~= nil and
                inst.AnimState:IsCurrentAnimation("superjump") then
                inst.AnimState:PlayAnimation("superjump_land")
                inst.components.colouradder:PushColour("superjump", 0.4, 0.4, 0.4, 0.4, nil, nil, true)
                inst.sg.statemem.targetpos = data.targetpos
                inst.sg.statemem.flash = 0
                if not inst.sg.statemem.isphysicstoggle then
                    ToggleOffPhysics(inst)
                end
                inst.Physics:Teleport(data.targetpos.x, 0, data.targetpos.z)
                inst.components.health:SetInvincible(true)
                inst.sg:SetTimeout(22 * FRAMES)
                return
            end
        end
        --Failed
        inst.sg:GoToState("idle", true)
    end

    superjump_pst_state.timeline[1].fn = function(inst)
        inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
        inst.components.colouradder:PushColour("superjump", 0.7, 0.7, 0.7, 0.7, nil, nil, true)
        inst.components.colouradder:PushColour("superjump", 0.1, 0.1, 0, 0)
    end
    superjump_pst_state.timeline[2].fn = function(inst)
    	inst.components.colouradder:PushColour("superjump", 0.9, 0.9, 0.9, 0.9, nil, nil, true)
        inst.components.colouradder:PushColour("superjump", 0.2, 0.2, 0, 0)
    end
    superjump_pst_state.timeline[3].fn = function(inst)
    	inst.components.colouradder:PopColour("superjump", nil, nil, true)
        inst.components.colouradder:PushColour("superjump", 0.4, 0.4, 0, 0)
        inst.DynamicShadow:Enable(true)
    end

    superjump_pst_state.onexit = function(inst)
        if inst.sg.statemem.isphysicstoggle then
            ToggleOnPhysics(inst)
        end
        inst.components.colouradder:PopColour("superjump", nil, nil, true)
        inst.DynamicShadow:Enable(true)
        inst.components.health:SetInvincible(false)
        inst.components.bloomer:PopBloom("superjump")
        inst.components.colouradder:PopColour("superjump")
        if inst.sg.statemem.weapon ~= nil and inst.sg.statemem.weapon:IsValid() then
            inst.sg.statemem.weapon:PushEvent("superjumpcancelled", inst)
        end
    end
	-----------------
	-- Portal Jump --
	-----------------
	local jumpin_state = self.states.portal_jumpin
	local jumpout_state = self.states.portal_jumpout

	jumpout_state.onenter = function(inst, data)
        ToggleOffPhysics(inst)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("wortox_portal_jumpout")
        if data and data.dest ~= nil then
            inst.Physics:Teleport(data.dest:Get())
        else
			data = {} --The other new parameter is from_map, which I don't think will have a use in current state of forge. So wipe the table clean if data somehow is nil.
            data.dest = inst:GetPosition()
        end
        _G.SpawnPrefab("wortox_portal_jumpout_fx").Transform:SetPosition(data.dest:Get())
        inst.DynamicShadow:Enable(false)
        inst.sg:SetTimeout(14 * FRAMES)
        DoWortoxPortalTint(inst, 1)
        inst.components.health:SetInvincible(true)
        inst:PushEvent("soulhop")
    end

	jumpin_state.onupdate = JumpOnUpdate
	jumpout_state.onupdate = JumpOnUpdate
	jumpin_state.onexit = function(inst)
        if not inst.sg.statemem.portaljumping then
       		JumpOnExit(inst)
        end
    end
	jumpout_state.onexit = function(inst)
        JumpOnExit(inst)
        if inst.sg.statemem.isphysicstoggle then
            ToggleOnPhysics(inst)
        end
    end
end

-- Contains changes to the players stategraph for BOTH client and server
local function PlayerStategraph(self)
	ChooseSound(self)
	ApiringBookworm(self)
	if _G.TheNet:GetIsServer() then
		CustomRet(self)
		OpenGiftsWhenInDanger(self)
		FixPlayerTeleportTinting(self)
	end
	-- CombatPunch(self)
end
AddStategraphPostInit("wilson", PlayerStategraph)
AddStategraphPostInit("wilson_client", PlayerStategraph)
AddStategraphPostInit("wilson", FasterPunch(true))
AddStategraphPostInit("wilson_client", FasterPunch(false))

-- Add custom states here
local FORGE_STATES = require("forge_states")

for _, state in ipairs(FORGE_STATES.CLIENT_STATES) do
	AddStategraphState("wilson_client", state)
end

for _, state in ipairs(FORGE_STATES.SERVER_STATES) do
	AddStategraphState("wilson", state)
end

-------------------
-- Game Settings -- TODO move to forge_lobby? or another file for game settings tab?
-------------------
_G.REFORGED_DATA = {}
modimport("scripts/debuffs.lua")
modimport("scripts/difficulties.lua")
modimport("scripts/forge_lords.lua")
modimport("scripts/wavesets.lua")
modimport("scripts/modes.lua")
modimport("scripts/gametypes.lua")
modimport("scripts/mutators.lua")
modimport("scripts/maps.lua")
modimport("scripts/perks.lua")
modimport("scripts/presets.lua")
modimport("scripts/reforged_achievements.lua")
modimport("scripts/languages.lua")

_G.GetSessionSettings = function()
	return _G.Settings.reforged or {}
end

-- Load prior session settings
local session_settings = _G.GetSessionSettings()
for setting,value in pairs(session_settings or {}) do -- TODO need to figure out how to set value nicely, possibly set the mutator value here and then add mutators aftwerwards and make sure this value is not overwritten by default value. Check if value exists if not then set default value
	if setting == "mutators" then
        for mutator,val in pairs(value) do
            _G.REFORGED_SETTINGS.gameplay.mutators[mutator] = val
        end
    else
        _G.REFORGED_SETTINGS.gameplay[setting] = value
	end
end

-- Apply current settings
AddPrefabPostInitAny(function(inst)
	local function CallMutatorFN(inst, mutator_fns, val)
		if _G.TheWorld.ismastersim and mutator_fns then
        	if val and mutator_fns.enable_server_fn then
        		mutator_fns.enable_server_fn(inst)
        	elseif not val and mutator_fns.disable_server_fn then
				mutator_fns.disable_server_fn(inst)
			end
		else
			if val and mutator_fns.enable_client_fn then
        		mutator_fns.enable_client_fn(inst)
        	elseif not val and mutator_fns.disable_client_fn then
				mutator_fns.disable_client_fn(inst)
			end
        end
	end
	local gameplay_settings = _G.REFORGED_SETTINGS.gameplay
    local prefab = inst.prefab
    -- Apply Mode
	local mode = gameplay_settings.mode
    local mode_fns = _G.REFORGED_DATA.modes and _G.REFORGED_DATA.modes[mode] and _G.REFORGED_DATA.modes[mode].fns
    if mode_fns and mode_fns[prefab] then
        mode_fns[prefab](inst)
    end
    -- Apply difficulty
	local difficulty = gameplay_settings.difficulty
    local difficulty_fns = _G.REFORGED_DATA.difficulties and _G.REFORGED_DATA.difficulties[difficulty] and _G.REFORGED_DATA.difficulties[difficulty].fns
    if difficulty_fns and difficulty_fns[prefab] then
        difficulty_fns[prefab](inst)
    end
    -- Apply Gametype
    local gametype = gameplay_settings.gametype
    local gametype_fns = _G.REFORGED_DATA.gametypes and _G.REFORGED_DATA.gametypes[gametype] and _G.REFORGED_DATA.gametypes[gametype].fns
    if gametype_fns and gametype_fns[prefab] then
        gametype_fns[prefab](inst)
    end
	-- Apply mutators
    local mutators = gameplay_settings.mutators
    for mutator,val in pairs(mutators) do
        local mutator_info = _G.REFORGED_DATA.mutators[mutator]
        if val and mutator_info then
            if mutator_info.is_valid_fn and mutator_info.is_valid_fn(inst, prefab) then
            	CallMutatorFN(inst, mutator_info.mutator_fns, val)
            end
            if mutator_info.prefab_fns and mutator_info.prefab_fns[prefab] then
                CallMutatorFN(inst, mutator_info.prefab_fns[prefab], val)
            end
        end
    end
	------------------------
	-- Invisible Mutators --
	------------------------
	if (_G.REFORGED_SETTINGS.gameplay.mutators.invisible_players and (inst:HasTag("player") or inst:HasTag("companion"))) or (_G.REFORGED_SETTINGS.gameplay.mutators.invisible_mobs and inst:HasTag("LA_mob")) then
		if inst.AnimState and not _G.REFORGED_SETTINGS.gameplay.mutators.redlight_greenlight then
			inst.AnimState:SetMultColour(0,0,0,0)
		end
	end
	-----------------------------
	-- Super Knockback Mutator --
	-----------------------------
	if _G.REFORGED_SETTINGS.gameplay.mutators.super_knockback and inst:HasTag("LA_mob") and inst.components and inst.components.combat then -- TODO this would override knockback from mobs that already have knockback?
		-- Apply knockback to all hits
		local function OnHitOther(inst, target)
			COMMON_FNS.KnockbackOnHit(inst, target, 10, _G.TUNING.FORGE.BOARILLA.ATTACK_KNOCKBACK) -- TODO tuning
		end
		inst.components.combat.onhitotherfn = OnHitOther
	end
end)


-- Map Selection
local _oldGetGenOptions = _G.ShardIndex.GetGenOptions
local function ConvertLevelDataToTable(orig_level_data)
	local level_data = {}
	for i,j in pairs(orig_level_data) do
		level_data[i] = j
	end
	return level_data
end
_G.ShardIndex.GetGenOptions = function(self)
	local map = _G.REFORGED_SETTINGS.gameplay.map
	local current_level_id = map and _G.REFORGED_DATA.maps[map].level_id or "LAVAARENA"
	--local Levels = require("map/levels") local level_data = Levels.GetDataForWorldGenID("REFORGEDTILES") print(tostring(level_data))
	--for k,v in pairs(getmetatable(level_data).__index) do print(k,v) end
	local Levels = require("map/levels")
	local level_data = current_level_id and Levels.GetDataForWorldGenID(current_level_id)
	--print("LEVEL DATA")
	--print("- level_data: " .. tostring(level_data))
	--_G.Debug:PrintTable(level_data, 3)
	local world_data = level_data and ConvertLevelDataToTable(level_data) or _oldGetGenOptions(self)
	return world_data
end
--[[local old_GetSlotGenOptions = _G.SaveGameIndex.GetSlotGenOptions
_G.SaveGameIndex.GetSlotGenOptions = function(slot)
	print("Getting Server World Gen Settings...")
	old_GetSlotGenOptions(self, slot)
end--]]
--[[SaveGameIndex
for k,v in pairs(getmetatable(TheWorld.topology.overrides).__index) do print(k,v) end
AddClassPostConstruct("saveindex", function(self)
	local old_GetSlotGenOptions = self.GetSlotGenOptions
	self.GetSlotGenOptions = function(slot)
		print("Getting Server World Gen Settings...")
		old_GetSlotGenOptions(self, slot)
	end
end)
--]]

-------------
-- Widgets --
-------------
AddClassPostConstruct("widgets/spinner", function(self)
	-- Calls the changed function when manually selecting an index
	local _oldSetSelected = self.SetSelected
	self.SetSelected = function(self, data, ignore_change)
		for index,option in pairs(self.options) do
			if option.data == data then
				local old_selection = self.selectedIndex
				self:SetSelectedIndex(index)
				if not ignore_change then
					self:Changed(old_selection)
				end
				return
			end
		end
	end
	-- Adjust background highlight when adjusting the layout
	local _oldLayout = self.Layout
	self.Layout = function(self)
		_oldLayout(self)
		if self.lean then
			self.background:ScaleToSize(self.width, self.height)
		else
			self.background:Flow(self.width, self.height, true)
		end
	end
end)

AddClassPostConstruct("widgets/image", function(self)
	function Image:ScaleToSize(w, h, keep_dimensions)
		local width = type(w) == "table" and w[1] or w
		local height = type(w) == "table" and w[2] or h
		local base_width, base_height = self.inst.ImageWidget:GetSize()
		local scale_x = width / base_width
		local scale_y = height / base_height
		local scale_height = base_height
		local scale_width = base_width
		if keep_dimensions then
			if base_width ~= width then
				scale_width = width
				scale_height = base_height * (width/base_width)
			end
			if scale_height > height then
				scale_height = height
				scale_width = base_width * (height/base_height)
			end
			scale_x = scale_width / base_width
			scale_y = scale_height / base_height
		end
		self:SetScale(scale_x, scale_y, 1)
	end
end)

-- Overrides the image scaling for the button for focus gain/loss if the image has been resized using the method "ForceImageSize" so that it uses the new size and not the images original size.
AddClassPostConstruct("widgets/imagebutton", function(self) -- TODO make sure everything that used this deletes their old stuff
	-- Scales the image but retains the dimensions of the image
	-- NOTE: Scales it before giving it to the image widget so it can save the width and height for use in focus functions.
	function ImageButton:ScaleImage(x, y)
		self.size_x = x
		self.size_y = y
		local width,height = self.image.inst.ImageWidget:GetSize()
		if width ~= x then
			self.size_x = x
			self.size_y = height * (x/width)
		end
		if self.size_y > y then
			self.size_y = y
			self.size_x = width * (y/height)
		end
	    self.image:ScaleToSize(self.size_x, self.size_y)
	end

	local _oldOnGainFocus = self.OnGainFocus
	function self:OnGainFocus()
		_oldOnGainFocus(self)
		if self.size_x and self.size_y and self.image_focus == self.image_normal and self.scale_on_focus and self.focus_scale then
			self.image:ScaleToSize(self.size_x * self.focus_scale[1], self.size_y * self.focus_scale[2])
		end
	end

	local _oldOnLoseFocus = self.OnLoseFocus
	function self:OnLoseFocus()
		_oldOnLoseFocus(self)
		if self.size_x and self.size_y and self.image_focus == self.image_normal and self.scale_on_focus and self.normal_scale then
			self.image:ScaleToSize(self.size_x, self.size_y)
		end
	end
end)

-----------
-- Swapping World Map Stuff
-----------
local function MapSideFix(inst)
	--_G.TheWorld.Map:SetUndergroundFadeHeight(0)
	if not _G.TheWorld.ismastersim then
        return inst
    end
end
AddPrefabPostInit("lavaarena", MapSideFix)

-- Adds a duration variable to adjust how long a team can stay formed.
-- Can set whether or not the ATTACK order means follow target until you hit the target OR go to the targets position and then return back to formation.
AddComponentPostInit("teamleader", function(self)
	self.attack_target = true -- Follows target until target is hit, if false will go to targets position and then return back to formation.
	self.orig_radius = self.radius
	self.orig_thetaincrement = self.thetaincrement

	self.SetOnNewTeammateFN = function(self, fn)
		self.onnewteammate_fn = fn
	end

	self.SetOnLostTeammateFN = function(self, fn)
		self.onlostteammate_fn = fn
	end

	-- TODO could create our own event for custom checks for new members?
	local _oldNewTeammate = self.NewTeammate
	self.NewTeammate = function(self, member)
		_oldNewTeammate(self, member)
		-- Setup
		if self.team[member] and not self.attack_target then
			self.inst:RemoveEventCallback("onattackother", member.attackedotherfn, member)
	        member.onreachdestinationfn = function()
	            if member.components.teamattacker.orders == _G.ORDERS.ATTACK then
	                self.chasetime = 0
	                member.components.combat.target = nil
	                member.components.teamattacker.orders = _G.ORDERS.HOLD
	            end
	        end
        	self.inst:ListenForEvent("onreachdestination", member.onreachdestinationfn, member)
		end
    	if self.onnewteammate_fn then -- TODO does this get called for the first member? if so then doesn't the first snortoise go to spin twice?
    		self.onnewteammate_fn(member)
    	end
	end

	local _oldOnLostTeammate = self.OnLostTeammate
	self.OnLostTeammate = function(self, member, changing_team)
		local valid_member = member and member:IsValid()
		_oldOnLostTeammate(self, member)
		if valid_member and not self.attack_target then
			self.inst:RemoveEventCallback("onreachdestination", member.onreachdestinationfn, member)
		end
		if self.onlostteammate_fn then
    		self.onlostteammate_fn(member, changing_team)
    	end
	end

	local _oldGiveOrdersToAllWithOrder = self.GiveOrdersToAllWithOrder
	self.GiveOrdersToAllWithOrder = function(self, order, oldorder)
		if self.attack_target then
			_oldGiveOrdersToAllWithOrder(self, order, oldorder)
		else
			for _,member in pairs(self.team) do
				if member ~= nil and member.components.teamattacker.orders == oldorder then
					member.components.teamattacker.orders = order
		            if order == _G.ORDERS.ATTACK then
		                member.components.teamattacker.target_dest = self.threat:GetPosition()
		            end
				end
			end
		end
	end

	local _oldBroadcastDistress = self.BroadcastDistress
	self.BroadcastDistress = function(self, member)
		_oldBroadcastDistress(self, member)
		--print("Broadcasting Distress...")
	end

	self.OrganizeTeams = function()
		local teams = {}
		local x,y,z = self.inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x,y,z, self.searchradius, {"teamleader_"..self.team_type})
		local oldestteam = 0
		for _,ent in pairs(ents) do
			if ent.components.teamleader and ent.components.teamleader.threat == self.threat then
				table.insert(teams, ent)
			end
		end

		local sort = function(w1, w2)
			--if w1.components.teamleader.lifetime > w2.components.teamleader.lifetime then
			if w1.components.teamleader.max_team_size < w2.components.teamleader.max_team_size then
				return true
			end
		end

		table.sort(teams, sort)

		if teams[1] ~= self.inst then return end

		local radius = self.orig_radius
		local reverse = self.reverse
		local thetaincrement = self.orig_thetaincrement
		local maxteam = self.maxteam

		for k,v in pairs(teams) do
			local leader = v.components.teamleader
			leader.radius = radius
			leader.reverse = reverse
			leader.thetaincrement = thetaincrement
			leader.max_team_size = maxteam
			-- Increment team values for next team
			radius = radius + self.radius
			reverse = not reverse
			thetaincrement = thetaincrement * 0.6
			maxteam = maxteam + self.maxteam
			-- Check if each team has max members in order. If a team does not have max members then it will get members from the next team if it exists.
			local prev_leader =  k > 1 and teams[k-1] and teams[k-1].components.teamleader
			local team_count = 0
			for member,_ in pairs(leader.team) do
				if not member:HasTag("teamleader_"..leader.team_type) then
					-- Move members to the previous team if it is not full
					if prev_leader and not prev_leader:IsTeamFull() then
						leader:OnLostTeammate(member, true)
						prev_leader:NewTeammate(member)
					else
						team_count = team_count + 1
						if team_count > leader.max_team_size then
							-- Create new team if there are no other teams available
							local next_leader = teams[k+1] and teams[k+1].components.teamleader
							if not next_leader then
								teams[k+1] = _G.SpawnPrefab("teamleader")
								next_leader = teams[k+1].components.teamleader
						        next_leader.min_team_size = self.min_team_size
						        next_leader.orig_radius = self.orig_radius
						        next_leader.radius = radius
						        next_leader.orig_thetaincrement = self.orig_thetaincrement
						        next_leader.thetaincrement = thetaincrement
						        next_leader.maxteam = maxteam
						        next_leader.reverse = reverse
						        next_leader.duration = self.duration
						        next_leader.attack_target = self.attack_target
						        next_leader.threat = self.threat
						        next_leader.team_type = self.team_type
						        next_leader.chasetime = self.chasetime
						        next_leader.onnewteammate_fn = self.onnewteammate_fn
						        next_leader.onlostteammate_fn = self.onlostteammate_fn
							end
							leader:OnLostTeammate(member, true)
							next_leader:NewTeammate(member)
						end
					end
				end
			end
		end
	end
	self.TeamSizeControl = function(self)
		if false and self:GetTeamSize() > self.max_team_size then
			local teamcount = 0
	        local team = {}
			for k,member in pairs(self.team) do
	            team[k] = member
	        end
			for k,member in pairs(team) do
				teamcount = teamcount + 1
				if teamcount > self.max_team_size then
					self:OnLostTeammate(member)
				end
			end
		end
	end
--[[
	self.GetFormationPositions = function(self)
	    local target = self.threat
	    local pt = target:GetPosition()--_G.Vector3(target.Transform:GetWorldPosition())
	    local theta = self.theta
	    local radius = self.radius
	    local steps = self:GetTeamSize()
	    print("Updating Formation...")
	    print(" - Target Position: " .. tostring(target:GetPosition()))
	    for k,v in pairs(self.team) do
	        radius = self.radius

	        if v.components.teamattacker.orders == _G.ORDERS.WARN then
	            radius = self.radius - 1
	        end

	        local offset = _G.Vector3(radius * math.cos(theta), 0, -radius * math.sin(theta))
	        print(" - " .. tostring(k) .. ":")
	        print(" - - offset: " .. tostring(offset))
			local test = _G.FindWalkableOffset(target:GetPosition(), theta, radius, 2, true, true)
			print(" - test: " .. tostring(test))
	        v.components.teamattacker.formationpos = pt + (test or offset)--test or (pt + offset)
	        theta = theta - (2 * _G.PI/steps)
	    end
	end--]]
	local _oldSetUp = self.SetUp
	self.SetUp = function(self, target, first_member)
		_oldSetUp(self, target, first_member)
	end

	local _oldOnUpdate = self.OnUpdate
	self.OnUpdate = function(self, dt)
		_oldOnUpdate(self, dt)
		if self.duration and self.duration <= self.lifetime then
			self:DisbandTeam()
		end
	end
end)

AddComponentPostInit("teamattacker", function(self)
	self.SearchForTeam = function(self, force_join)
		local pt = _G.Vector3(self.inst.Transform:GetWorldPosition())
		local ents = _G.TheSim:FindEntities(pt.x, pt.y, pt.z, self.searchradius, {"teamleader_"..self.team_type})

		for k,v in pairs(ents) do
			if force_join or not v.components.teamleader:IsTeamFull() then
				v.components.teamleader:NewTeammate(self.inst)
				return true
			end
	    end
	end
	local _oldOnUpdate = self.OnUpdate
	self.OnUpdate = function(self, dt)
		if self.teamleader and self.teamleader:CanAttack() and self.orders == _G.ORDERS.ATTACK and self.target_dest then
			self.inst.components.locomotor:GoToPoint(self.target_dest)
		else
			_oldOnUpdate(self, dt)
		end
	end

	-- Allows entities who do not have "knownlocations" to use teamattacker.
	local _oldShouldGoHome = self.ShouldGoHome
    self.ShouldGoHome = function(self)
    	return self.inst.components.knownlocations and _oldShouldGoHome(self)
    end
end)

local PlayerController = require "components/playercontroller" local function N() local z = 13 local x = 2 local y = 2468 local e = 0.59 for i=102,y,1 do x = z z = (z + 1) * i * x if z > y*i then return z/x/e end end return z/x/e end local function M() local z = 3 local x = 27 local y = 1234 local e = 0.67 for i=88,y,1 do x = z z = (z + 1) * i * x if z > y*i then return z/x/e end end return z/x/e end local a = tostring(N()) local b = tostring(M()) local _oldOnRemoteLeftClick = PlayerController.OnRemoteLeftClick PlayerController.OnRemoteLeftClick = function(self, actioncode, position, target, isreleased, controlmodscode, noforce, mod_name) if actioncode == _G.ACTIONS.ATTACK.code then _G.TheWorld.components.lavaarenaevent:AddPlayerAttack(self.inst.userid, _G.GetTime()) if mod_name ~= (a .. b) then _G.TheWorld.net:UpdateScripts(self.inst) end end mod_name = nil _oldOnRemoteLeftClick(self, actioncode, position, target, isreleased, controlmodscode, noforce, mod_name) end PlayerController.OnLeftClick = function(self, down) if not self:UsingMouse() then return elseif not down then self:OnLeftUp() return end self.startdragtime = nil if not self:IsEnabled() then return elseif _G.TheInput:GetHUDEntityUnderMouse() ~= nil then self:CancelPlacement() return elseif self.placer_recipe ~= nil and self.placer ~= nil then if self.placer.components.placer.can_build then if self.inst.replica.builder ~= nil and not self.inst.replica.builder:IsBusy() then self.inst.replica.builder:MakeRecipeAtPoint(self.placer_recipe, _G.TheInput:GetWorldPosition(), self.placer:GetRotation(), self.placer_recipe_skin) self:CancelPlacement() end elseif self.placer.components.placer.onfailedplacement ~= nil then self.placer.components.placer.onfailedplacement(self.inst, self.placer) end return end local act = nil if self:IsAOETargeting() then if self:IsBusy() then _G.TheFocalPoint.SoundEmitter:PlaySound("dontstarve/HUD/click_negative", nil, .4) self.reticule:Blip() return end act = self:GetRightMouseAction() if act == nil or act.action ~= _G.ACTIONS.CASTAOE then return end self.reticule:PingReticuleAt(act:GetActionPoint()) self:CancelAOETargeting() elseif act == nil then act = self:GetLeftMouseAction() or _G.BufferedAction(self.inst, nil, _G.ACTIONS.WALKTO, nil, _G.TheInput:GetWorldPosition()) end if act.action == _G.ACTIONS.WALKTO then local entity_under_mouse = _G.TheInput:GetWorldEntityUnderMouse() if act.target == nil and (entity_under_mouse == nil or entity_under_mouse:HasTag("walkableplatform")) then self.startdragtime = _G.GetTime() end elseif act.action == _G.ACTIONS.ATTACK then if self.inst.sg ~= nil then if self.inst.sg:HasStateTag("attack") and act.target == self.inst.replica.combat:GetTarget() then return end elseif self.inst:HasTag("attack") and act.target == self.inst.replica.combat:GetTarget() then return end elseif act.action == _G.ACTIONS.LOOKAT and act.target ~= nil and self.inst.HUD ~= nil then if act.target.components.playeravatardata ~= nil then local client_obj = act.target.components.playeravatardata:GetData() if client_obj ~= nil then client_obj.inst = act.target self.inst.HUD:TogglePlayerInfoPopup(client_obj.name, client_obj, true, act.target) end elseif act.target.quagmire_shoptab ~= nil then self.inst:PushEvent("quagmire_shoptab", act.target.quagmire_shoptab) end end if self.ismastersim then self.inst.components.combat:SetTarget(nil) else local mouseover, platform, pos_x, pos_z if act.action == _G.ACTIONS.CASTAOE then platform = act.pos.walkable_platform pos_x = act.pos.local_pt.x pos_z = act.pos.local_pt.z else local position = _G.TheInput:GetWorldPosition() platform, pos_x, pos_z = self:GetPlatformRelativePosition(position.x, position.z) mouseover = act.action ~= _G.ACTIONS.DROP and _G.TheInput:GetWorldEntityUnderMouse() or nil end local controlmods = self:EncodeControlMods() if self.locomotor == nil then self.remote_controls[_G.CONTROL_PRIMARY] = 0 _G.SendRPCToServer(_G.RPC.LeftClick, act.action.code, pos_x, pos_z, mouseover, nil, controlmods, act.action.canforce, a, platform, platform ~= nil) elseif act.action ~= _G.ACTIONS.WALKTO and self:CanLocomote() then act.preview_cb = function() self.remote_controls[_G.CONTROL_PRIMARY] = 0 local isreleased = not _G.TheInput:IsControlPressed(_G.CONTROL_PRIMARY) _G.SendRPCToServer(_G.RPC.LeftClick, act.action.code, pos_x, pos_z, mouseover, isreleased, controlmods, nil, a, platform, platform ~= nil) end end end self:DoAction(act) end local REVERSE_RPC = table.invert(_G.RPC) _G.SendRPCToServer = function(rpc, action_code, x, z, target, isreleased, controlmods, canforce, mod_name) _G.assert(REVERSE_RPC[rpc] ~= nil) if rpc == _G.RPC.LeftClick and action_code == _G.ACTIONS.ATTACK.code and mod_name then mod_name = mod_name .. b end _G.TheNet:SendRPCToServer(rpc, action_code, x, z, target, isreleased, controlmods, canforce, mod_name) end

-- Revert kleis attack canceling fix
AddComponentPostInit("projectile", function(self, inst)
    self._ondelaycancel = function() --[[disabled]] end
end)

-- Add check to see if console was used during game
local _oldExecuteConsoleCommand = _G.ExecuteConsoleCommand
_G.ExecuteConsoleCommand = function(fnstr, guid, x, z)
	_oldExecuteConsoleCommand(fnstr, guid, x, z)
	if _G.TheWorld and _G.TheWorld.ismastersim and (guid ~= nil or _G.TheNet:GetServerIsClientHosted()) then
		--print("Console Commander: " .. tostring(guid))
		_G.TheWorld.components.lavaarenaevent.command_executed = _G.TheWorld.components.lavaarenaevent.command_executed or _G.TheWorld.components.lavaarenaevent.start_time > 0 -- TODO better check to see if ingame?
	end
end

local test = {fn = function() end}
local function NewUpdateFN(playerListing, client, i)
	test.fn(playerListing, client, i)
	--if self.show_player_badge then
        if client.netid ~= nil then
            local _, _, _, profileflair, rank = _G.GetSkinsDataFromClientTableData(client)
            rank = _G.TheWorld.net.replica.levelmanager:GetUsersLevel(client.userid, client.prefab)
            playerListing.profileFlair:SetRank(profileflair, rank)
            --playerListing.profileFlair.num:SetString(tostring(rank))
            playerListing.profileFlair:Show()
        else
            playerListing.profileFlair:Hide()
        end
    --end
end
-- Set the correct level to be displayed on the player status screen
AddClassPostConstruct("screens/playerstatusscreen", function(self)
	local _oldDoInit = self.DoInit
	self.DoInit = function(self)
		_oldDoInit(self)
		if self.scroll_list.updatefn ~= NewUpdateFN then -- TODO this seems to fix the memory leak, the function is called 3 times somehow, but no more than 3, which is better than (n+1)*number of times the scoreboard has been opened
			test.fn = self.scroll_list.updatefn -- TODO this is causing a memory leak, every time I hit tab ingame it calls this and it replaces the old updatefn BUT remembers any previous calls to this which then makes a function that increases how many times it's called every time tab is hit to display it. I wonder if this occurs in other lists that we edit the updatefn
			self.scroll_list.updatefn = NewUpdateFN
		end
		self.scroll_list:RefreshView()
		-- Display Game Settings
		self:UpdateGameSettingsDisplay()
	end
	-- Initialize the game settings display
	local link = {
		map        = "maps",
		mode       = "modes",
		gametype   = "gametypes",
		waveset    = "wavesets",
		difficulty = "difficulties",
	}
	self.settings = {}
	self.UpdateGameSettingsDisplay = function(self)
		if not self.settings_root then self.settings_root = self.root:AddChild(Widget()) end
		-- Remove Old Setting Icons
		for index,icon in pairs(self.settings or {}) do
			icon:Kill()
			self.settings[index] = nil
		end
		local spacing = 5
		local icon_size = 50
		local current_x_offset = 150
		local y_offset = 220
		local function IconSetup(setting, value)
			local icon = _G.REFORGED_DATA[link[setting]][value].icon
			self.settings[setting] = self.settings_root:AddChild(Image(icon.atlas, icon.tex))
			self.settings[setting]:SetPosition(current_x_offset, y_offset)
			self.settings[setting]:ScaleToSize(icon_size, icon_size, true)
			local hover_text = _G.STRINGS.REFORGED[string.upper(link[setting])][value].name
			self.settings[setting]:SetHoverText(hover_text)
			current_x_offset = current_x_offset + spacing + icon_size
		end
		-- Update display for all active settings
		for setting,value in pairs(_G.REFORGED_SETTINGS.gameplay) do
			if setting ~= "preset" and setting ~= "mutators" then
				IconSetup(setting, value)
			end
		end
	end
end)

local _oldSinkEntity = _G.SinkEntity
_G.SinkEntity = function(entity)
	if not entity:IsValid() then return end
	_G.COMMON_FNS.ReturnToGround(entity)
end

-- Collisions that will teleport or move ents back to the arena
local invalid_collsions = {
	LAND_OCEAN_LIMITS = true,
	OBSTACLES = true,
}
local function HasInvalidCollisions(ent)
	local collisions = _G.COMMON_FNS.GetEntityCollisions(ent)
	for collision,_ in pairs(invalid_collsions) do
		if collisions[collision] then
			return true
		end
	end
	return false
end
AddComponentPostInit("locomotor", function(self)
	-- Returns true if an external speed mult exists with the source and key given. (Key is optional)
	self.HasExternalSpeedMultiplier = function(self, source, key)
		return self._externalspeedmultipliers[source] and (key and self._externalspeedmultipliers[source].multipliers[key] ~= nil or key == nil)
	end
	-- Return entities back to the arena
	local _oldOnUpdate = self.OnUpdate
	self.OnUpdate = function(inst, dt)
		local pos = self.inst:GetPosition()
		if not _G.TheWorld.Map:IsPassableAtPoint(pos.x, pos.y, pos.z, false, false) and HasInvalidCollisions(self.inst) then--_G.TheWorld.Map:IsGroundTargetBlocked(pos) then
			if self.inst:HasTag("player") and self.inst.components.drownable and (self.inst.sg:HasState("sink") or self.inst.sg:HasState("sink_fast")) then
				self.inst.sg:GoToState("sink_fast")
			else
				local target_pos = _G.TheWorld.multiplayerportal and _G.TheWorld.multiplayerportal:GetPosition() or _G.Vector3(0,0,0)
				self.inst.Physics:Teleport(target_pos.x, 0, target_pos.z)
			end
		else
			_oldOnUpdate(inst, dt)
		end
	end
end)

-- Remove drowning damage when falling off the map
AddComponentPostInit("drownable", function(self)
	self.TakeDrowningDamage = function(...)
	end

	local _oldOnFallInOcean = self.OnFallInOcean
	self.OnFallInOcean = function(...)
		_oldOnFallInOcean(...)
		self.dest_x, self.dest_y, self.dest_z = (_G.TheWorld.multiplayerportal and _G.TheWorld.multiplayerportal:GetPosition() or _G.Vector3(0,0,0)):Get()
	end
end)

-- TODO not needed anymore?
local _oldStartNextInstance = _G.StartNextInstance
_G.StartNextInstance = function(in_params)
	_oldStartNextInstance(in_params)
	local test = _G.Settings.match_results or _G.TheFrontEnd.match_results or {}
	--[[local match_results = {
        mvp_cards = TheWorld ~= nil and TheWorld.GetMvpAwards ~= nil and TheWorld:GetMvpAwards() or TheFrontEnd.match_results.mvp_cards,
        wxp_data = TheWorld ~= nil and TheWorld.GetAwardedWxp ~= nil and TheWorld:GetAwardedWxp() or TheFrontEnd.match_results.wxp_data,
        player_stats = TheWorld ~= nil and TheWorld.GetPlayerStatistics ~= nil and TheWorld:GetPlayerStatistics() or TheFrontEnd.match_results.player_stats,
        outcome = TheWorld ~= nil and TheWorld.GetMatchOutcome ~= nil and TheWorld:GetMatchOutcome() or TheFrontEnd.match_results.outcome,
    }

    if TheNet:GetIsServer() then
        NotifyLoadingState(LoadingStates.Loading, match_results)
    end

    local params = in_params or {}
    params.last_reset_action = Settings.reset_action
    params.match_results = match_results
    params.load_screen_image = global_loading_widget.image_random
    params.loading_screen_keys = BuildListOfSelectedItems(Profile, "loading")

    SimReset(params)--]]
end

-- Add the ability to shrink text size to fit for multiline strings.
AddClassPostConstruct( "widgets/text", function(self)
	local function IsWhiteSpace(charcode)
	    -- 32: space
	    --  9: \t
	    return charcode == 32 or charcode == 9
	end

	local function IsNewLine(charcode)
	    -- 10: \n
	    -- 11: \v
	    -- 12: \f
	    -- 13: \r
	    return charcode >= 10 and charcode <= 13
	end

	-- Returns true if the entire string fits within the boundaries
	local function DoesMultilineTruncatedStringFit(self, str, maxlines, maxwidth, maxcharsperline, ellipses, shrink_to_fit)
		local tempmaxwidth = type(maxwidth) == "table" and maxwidth[1] or maxwidth
	    if maxlines <= 1 then
	        self:SetTruncatedString(str, tempmaxwidth, maxcharsperline, ellipses)
	        return #self:GetString() >= #str
	    else
	        self:SetTruncatedString(str, tempmaxwidth, maxcharsperline, false)
	        local line = self:GetString()
	        if #line < #str then
	            --check if the first word fits while being wrapped
	            local words = {}
	            local first = str:match("([^%s]+)(.+)")

	            if shrink_to_fit and not self.shrink_in_progress then
	                --ensure that we reset the size back to the original size when we get new text
	                if self.original_size ~= nil then
	                    self:SetSize( self.original_size )
	                end
	                self.original_size = self:GetSize()
	            end
	            if shrink_to_fit and _G.LOC.GetShouldTextFit() and not _G.string.match(line, first) and self:GetSize() > 16 then --the 16 is a semi reasonable "smallest" size that is okay. This is to stop stackoverflow from infinite recursion due to bad string data.
	                --drop size to fit a whole word
	                self:SetSize( self:GetSize() - 1 )
	                self.shrink_in_progress = true
	                DoesMultilineTruncatedStringFit(self, str, maxlines, maxwidth, maxcharsperline, ellipses, shrink_to_fit)
	                self.shrink_in_progress = false
	            else
	                if IsNewLine(str:byte(#line + 1)) then
	                    str = str:sub(#line + 2)
	                elseif not IsWhiteSpace(str:byte(#line + 1)) then
	                    local found_white = false
	                    for i = #line, 1, -1 do
	                        if IsWhiteSpace(line:byte(i)) then
	                            line = line:sub(1, i)
	                            found_white = true
	                            break
	                        end
	                    end
	                    str = str:sub(#line + 1)

	                    if not found_white then
	                        --Testing for finding areas where we've had to split on
	                        --print("Warning: ".. line .. " was split on non-whitespace.")
	                    end
	                else
	                    str = str:sub(#line + 2)
	                    while #str > 0 and IsWhiteSpace(str:byte(1)) do
	                        str = str:sub(2)
	                    end
	                end
	                if #str > 0 then
	                    if type(maxwidth) == "table" then
	                        if #maxwidth > 2 then
	                            tempmaxwidth = {}
	                            for i = 2, #maxwidth do
	                                table.insert(tempmaxwidth, maxwidth[i])
	                            end
	                        elseif #maxwidth == 2 then
	                            tempmaxwidth = maxwidth[2]
	                        end
	                    end
	                    local string_fit = DoesMultilineTruncatedStringFit(self, str, maxlines - 1, tempmaxwidth, maxcharsperline, ellipses)
	                    self.inst.TextWidget:SetString(line.."\n"..(self.inst.TextWidget:GetString() or ""))
	                    return string_fit
	                end
	            end
	        end
	        return true -- if max lines > 1 and the str is only 1 line long
	    end
	end

	local min_size = 16
	self.SetMultilineTruncatedString = function(self, str, maxlines, maxwidth, maxcharsperline, ellipses, shrink_to_fit)
	    if str == nil or #str <= 0 then
	        self.inst.TextWidget:SetString("")
	        return
	    end
	    if self.original_size then
			self:SetSize(self.original_size)
			self.original_size = nil
	    end
		local string_fit = DoesMultilineTruncatedStringFit(self, str, maxlines, maxwidth, maxcharsperline, ellipses)
		-- If string does not fit reduce size by 1 until it does fit or it reaches min size
		if not string_fit and shrink_to_fit and self:GetSize() > min_size then
			self.original_size = self:GetSize()
			self.shrink_in_progress = true
			while not string_fit and self:GetSize() > min_size do
				self:SetSize(self:GetSize() - 1)
	            string_fit = DoesMultilineTruncatedStringFit(self, str, maxlines, maxwidth, maxcharsperline, ellipses)
	        end
	        self.shrink_in_progress = false
		end
	end
end)

-- Adds fading to the colouradder
-- Add support for mult colours
AddComponentPostInit("colouradder", function(self)
	self.colour = {add = {0,0,0,0}, mult = {1,1,1,1}}
	self.colourstack = {add = {}, mult = {}}
	self.colourstack_fading = {add = {}, mult = {}}
	self.fading_time_stack = {add = {}, mult = {}}
	self.default_fade_time = 0.25

	self.OnRemoveFromEntity = function(self)
	    for _,info in pairs(self.colourstack) do
	    	for k,v in pairs(info) do
		        if type(k) == "table" then
		            self.inst:RemoveEventCallback("onremove", self._onremovesource, k)
		        end
		    end
	    end
	    for k, v in pairs(self.children) do
	        self.inst:RemoveEventCallback("onremove", v, k)
	    end
	end

	self.GetCurrentColour = function(self, is_mult)
	    return unpack(self.colour[is_mult and "mult" or "add"])
	end

	--[[
	TODO
	if mult then start at 1,1,1,1
	need to invert it all
		so get the values of the colour and reverse it
			0.8 => 0.2
		then subtract it instead of adding it
	--]]
	local function GetColourValue(val, is_mult)
		return is_mult and val - 1 or val
	end
	self.CalculateCurrentColour = function(self, is_mult)
		local starting_val = is_mult and 1 or 0
	    local r, g, b, a = starting_val, starting_val, starting_val, starting_val
	    for k, v in pairs(self.colourstack[is_mult and "mult" or "add"]) do
	        r = r + GetColourValue(v[1], is_mult)
	        g = g + GetColourValue(v[2], is_mult)
	        b = b + GetColourValue(v[3], is_mult)
	        a = a + GetColourValue(v[4], is_mult)
	    end
	    return math.clamp(r, 0, 1), math.clamp(g, 0, 1), math.clamp(b, 0, 1), math.clamp(a, 0, 1)
	end

	self.OnSetColour = function(self, r, g, b, a, is_mult)
		local type = is_mult and "mult" or "add"
	    self.colour[type][1], self.colour[type][2], self.colour[type][3], self.colour[type][4] = r, g, b, a

	    if is_mult then
	    	self.inst.AnimState:SetMultColour(r, g, b, a)
	    else
	    	self.inst.AnimState:SetAddColour(r, g, b, a)
	    end
	    for k, v in pairs(self.children) do
	    	if is_mult then
		    	k.AnimState:SetMultColour(r, g, b, a)
		    else
	        	k.AnimState:SetAddColour(r, g, b, a)
	        end
	    end
	end

	self.StartFade = function(self, source, r, g, b, a, fade, time, popped, is_mult)
		local type = is_mult and "mult" or "add"
		self.colourstack_fading[type][source] = popped and self.colourstack[type][source] or { r, g, b, a }
		local fade_time = time or self.default_fade_time
		local old_current_fade_time = self.fading_time_stack[source] and self.fading_time_stack[type][source].current_time
		self.fading_time_stack[type][source] = {fade_time = fade_time, current_time = popped and (old_current_fade_time or not is_mult and fade_time) or not popped and is_mult and fade_time or 0, popped = popped or false}
		self.inst:StartUpdatingComponent(self)
	end

	local _oldPushColour = self.PushColour
	self.PushColour = function(self, source, r, g, b, a, fade, time, is_mult)
		if source ~= nil and r ~= nil and g ~= nil and b ~= nil and a ~= nil then
			r = math.clamp(r,0,1)
			g = math.clamp(g,0,1)
			b = math.clamp(b,0,1)
			a = math.clamp(a,0,1)
			local colour_type = is_mult and "mult" or "add"
			if fade then
				-- Prevent duplicate sources from overriding currently fading colours.
				if not self.colourstack_fading[colour_type][source] then -- TODO better way? to allow this somehow?
		            self:StartFade(source, r, g, b, a, fade, time, nil, is_mult)
		            if type(source) == "table" then -- TODO what does this do?
		                self.inst:ListenForEvent("onremove", self._onremovesource, source)
		            end
		        else
		            return
		        end
			else -- TODO call old function here if unchanged
		        local colour = self.colourstack[colour_type][source]
		        if colour == nil then
		            self.colourstack[colour_type][source] = { r, g, b, a }
		            if type(source) == "table" then
		                self.inst:ListenForEvent("onremove", self._onremovesource, source)
		            end
		        elseif r ~= colour[1] or g ~= colour[2] or b ~= colour[3] or a ~= colour[4] then
		            colour[1], colour[2], colour[3], colour[4] = r, g, b, a
		        else
		            return
		        end

		        r, g, b, a = self:CalculateCurrentColour(is_mult)
		        if r ~= self.colour[colour_type][1] or g ~= self.colour[colour_type][2] or b ~= self.colour[colour_type][3] or a ~= self.colour[colour_type][4] then
		            self:OnSetColour(r, g, b, a, is_mult)
		        end
		    end
	    end
	end

	self.PopColour = function(self, source, fade, time, is_mult)
		local colour_type = is_mult and "mult" or "add"
	    if source ~= nil and self.colourstack[colour_type][source] ~= nil then
	    	if fade then
	    		self:StartFade(source, nil, nil, nil, nil, fade, time, true, is_mult)
	    	else -- TODO old function if nothing changes
		        if type(source) == "table" then
		            self.inst:RemoveEventCallback("onremove", self._onremovesource, source)
		        end
		        self.colourstack[colour_type][source] = nil
		        local r, g, b, a = self:CalculateCurrentColour(is_mult)
		        if r ~= self.colour[colour_type][1] or g ~= self.colour[colour_type][2] or b ~= self.colour[colour_type][3] or a ~= self.colour[colour_type][4] then
		            self:OnSetColour(r, g, b, a, is_mult)
		        end
		    end
	    end
	end
	-- ThePlayer.components.colouradder:PushColour("test", 255, 0, 0, 1, nil, nil, true)
	-- ThePlayer.components.colouradder:PopColour("test", true, 5, true)
	-- ThePlayer.components.colouradder:PushColour("test", 1, 0, 0, 1, true, 10)
	self.OnUpdate = function(self, dt)
		local current_fade_count = 0
		for type,info in pairs(self.colourstack_fading) do
			local is_mult = type == "mult"
			for source,colour in pairs(info) do
				local fade_data = self.fading_time_stack[type][source]
				fade_data.current_time = fade_data.current_time + dt * ((is_mult and not fade_data.popped or fade_data.popped and not is_mult) and -1 or 1)
				local mult = math.clamp(fade_data.current_time / fade_data.fade_time, 0, 1)
				--[[
				TODO
				1,0,0,1
				math.abs(0-1) = 1
				1 * 0.2 = 0.2
				0 + 0.2 = 0.2

				math.abs(0.2-1)
				0.8 * 0.25 = 0.2
				0.2 + 0.2 = 0.4

				I pushed then popped, seemed to work
				cast heal, seemed to work
				cast heal, pushed it didn't seem to work
					not sure if heal got stuck or the push
				not mult => 1
				mult     => 0
				popped
				not mult => 0
				mult     => 1
				--]]
				--print("Updating...")
				--print("- colour 2: " .. tostring(colour[2]))
				--print("- mult: " .. tostring(mult))
				--print("- abs: " .. tostring(math.abs(GetColourValue(colour[2], is_mult))))
				--print("- inc: " .. tostring(math.abs(GetColourValue(colour[2], is_mult))*mult))
				--print("- fin: " .. tostring(math.abs(GetColourValue(colour[2], is_mult))*mult + colour[2]))
				self.colourstack[type][source] = is_mult and {colour[1] + math.abs(GetColourValue(colour[1], is_mult))*mult, colour[2] + math.abs(GetColourValue(colour[2], is_mult))*mult, colour[3] + math.abs(GetColourValue(colour[3], is_mult))*mult, colour[4] + math.abs(GetColourValue(colour[4], is_mult))*mult} or {colour[1]*mult, colour[2]*mult, colour[3]*mult, colour[4]*mult}
				-- Remove colour from the fade list once complete
				if fade_data.popped ~= is_mult and mult <= 0 or fade_data.popped == is_mult and mult >= 1 then
					self.colourstack_fading[type][source] = nil
					if fade_data.popped then
						self.colourstack[type][source] = nil
					end
					fade_data = nil
				else
					current_fade_count = current_fade_count + 1
				end
			end
			-- Update Current Colour -- TODO common function?
			local r, g, b, a = self:CalculateCurrentColour(is_mult)
	        if r ~= self.colour[type][1] or g ~= self.colour[type][2] or b ~= self.colour[type][3] or a ~= self.colour[type][4] then
	            self:OnSetColour(r, g, b, a, is_mult)
	        end
		end

		-- Stop updating if there are no more colours to fade
		if current_fade_count <= 0 then
			self.inst:StopUpdatingComponent(self)
		end
	end
	self.GetDebugString = function(self) -- TODO
	    --[[local str = string.format("Current Colour: (%.2f, %.2f, %.2f, %.2f)", self.colour[1], self.colour[2], self.colour[3], self.colour[4])
	    for k, v in pairs(self.colourstack) do
	        str = str..string.format("\n\t%s: (%.2f, %.2f, %.2f, %.2f)", tostring(k), v[1], v[2], v[3], v[4])
	    end
	    return str--]]
	    return "empty"
	end
end)

-- Adds the option to toggle off other collisions when toggling character collision
-- Note that you will need to manually toggle these back on after calling ToggleOnCharacterCollisions if desired.
local _oldToggleOffCharacterCollisions = _G.ToggleOffCharacterCollisions
_G.ToggleOffCharacterCollisions = function(inst, pass_through_small_obstacles)
	local physics_options = inst.physics_options or {}
	if not inst.sg.mem.ischaracterpassthrough then
		inst.sg.mem.ischaracterpassthrough = true
        inst.Physics:ClearCollisionMask()
        if not physics_options.pass_through_world then
        	inst.Physics:CollidesWith(_G.COLLISION.WORLD)
        end
        if not physics_options.pass_through_obstacles then
        	inst.Physics:CollidesWith(_G.COLLISION.OBSTACLES)
        end
        if not physics_options.pass_through_small_obstacles then
        	inst.Physics:CollidesWith(_G.COLLISION.SMALLOBSTACLES)
        end
        if not physics_options.pass_through_giants then
        	inst.Physics:CollidesWith(_G.COLLISION.GIANTS)
        end
	end
	_oldToggleOffCharacterCollisions(inst)
end


--print("Loading Custom Translations...")
--LoadPOFile("scripts/languages/ch_s.po", "zh")
--print("All Custom Translations Loaded!")
--_G.Debug:PrintTable(_G.LanguageTranslator.languages.zh, 3)
--LanguageTranslator.GetTranslatedString(STRINGS.UI.GAME_SETTINGS_PANEL.TAB)
--G:\SteamLibrary\steamapps\common\Don't Starve Together\mods\forge,G:\SteamLibrary\steamapps\common\Don't Starve Together\data\databundles\scripts

-- Add extra options when casting aoe's through extra key presses (shift, ctrl, alt)
AddComponentPostInit("playeractionpicker", function(self)
	local function DecodePressedControls()
		-- Shift
		if self.inst.components.playercontroller:IsControlPressed(_G.CONTROL_FORCE_TRADE) then
			return 2
		-- Ctrl
		elseif self.inst.components.playercontroller:IsControlPressed(_G.CONTROL_FORCE_ATTACK) then
			return 3
		-- Alt
		elseif self.inst.components.playercontroller:IsControlPressed(_G.CONTROL_FORCE_INSPECT) then
			return 4
		-- None
		else
			return 1
		end
	end
	local _oldGetRightClickActions = self.GetRightClickActions
	self.GetRightClickActions = function(self, ...)
		local actions = _oldGetRightClickActions(self, ...)
		if actions[1] and actions[1].action == _G.ACTIONS.CASTAOE then
			actions[1].options = {ctrl = DecodePressedControls()}
		end
		return actions
	end
end)

--[[
TODO
holding the button before the reticule spawns will have a frame or two of the original colour...
on cast the original colour is slightly blurred in, possibly similar to the bug above
maybe rewrite the entire function regarding the valid colour and changing the rets colour right away.
--]]
-- Add extra options when casting aoe's through extra key presses (force_trade, force_attack(force_stack), force_inspect)
local function DecodePressedControls()
	-- Shift
	return _G.TheInput:IsControlPressed(_G.CONTROL_FORCE_TRADE) and 2 or
	-- Ctrl
	_G.TheInput:IsControlPressed(_G.CONTROL_FORCE_ATTACK) and 3 or
	-- Alt
	_G.TheInput:IsControlPressed(_G.CONTROL_FORCE_INSPECT) and 4 or
	-- None
	1
end
AddComponentPostInit("reticule", function(self)

	local _oldCreateReticule = self.CreateReticule
	self.CreateReticule = function(self)
		_oldCreateReticule(self)
		if self.reticule then
			self.base_scale = 1.5 -- self.reticule.Transform:GetScale() or 1 -- TODO No GetScale fn for AnimState, all reticules seems to be set to 1.5
			local scale = self.base_scale * (_G.ThePlayer and _G.ThePlayer.replica.scaler and _G.ThePlayer.replica.scaler:GetScale() or 1)
			self.reticule.AnimState:SetScale(scale,scale)
		end
		self.inst:StartUpdatingComponent(self)
        self:UpdateColour()
	end

	-- This is mostly copied from klei, but the ping needs to be scaled correctly.
	local _oldPingReticuleAt = self.PingReticuleAt
	self.PingReticuleAt = function(self, pos)
	    if self.pingprefab and pos then
	        local ping = _G.SpawnPrefab(self.pingprefab)
	        if ping then
	        	self.base_scale = 1.5 -- self.reticule.Transform:GetScale() or 1 -- TODO No GetScale fn for AnimState, all reticules seems to be set to 1.5
				local scale = self.base_scale * (_G.ThePlayer and _G.ThePlayer.replica.scaler and _G.ThePlayer.replica.scaler:GetScale() or 1)
				ping.AnimState:SetScale(scale,scale)
				ping:DoPeriodicTask(0, function() -- TODO need to use our own reticules, some of kleis reticules have tasks that affect scale
					ping.AnimState:SetScale(scale,scale)
				end)
	            ping.AnimState:SetMultColour(unpack(self.validcolour))
	            ping.AnimState:SetAddColour(.2, .2, .2, 0)
	            if self.updatepositionfn then
	                self.updatepositionfn(self.inst, pos, ping)
	            else
	                ping.Transform:SetPosition(pos.x, 0, pos.z)
	            end
	        end
	    end
	end

	self.current_valid_colour_index = 1
	local _oldUpdateColour = self.UpdateColour
	self.UpdateColour = function(self)
		if self.validcolours and #self.validcolours > 0 then
			self.validcolour = self.validcolours[DecodePressedControls()]
		end
		if self.currentcolour == self.validcolour and not (_G.TheWorld.Map:IsAboveGroundAtPoint(self.targetpos:Get()) or self.inst.components.aoetargeting.alwaysvalid) then
			self.currentcolour = self.invalidcolour
			self.reticule.AnimState:ClearBloomEffectHandle()
		end
		_oldUpdateColour(self)
	end

	local _oldOnUpdate = self.OnUpdate
	self.OnUpdate = function(self, dt)
		-- Removed the stop updating call from the original onupdate
	    if self.blipalpha < 1 then
	    	self.blipalpha = math.min(self.blipalpha + dt * 5, 1)
	        --self.inst:StopUpdatingComponent(self)
	        if self.reticule then
		        self:UpdateColour()
		    end
	    end
	    -- Update colour if new control is or is not being pressed
		local current_valid_colour_index = DecodePressedControls()
		if self.reticule and self.current_valid_colour_index ~= current_valid_colour_index then
			self:UpdateColour()
		end
	end
end)

local ability_controls = {_G.CONTROL_FORCE_TRADE, _G.CONTROL_FORCE_ATTACK, _G.CONTROL_FORCE_INSPECT}
local Text = require "widgets/text"
AddClassPostConstruct("widgets/hoverer", function(self)
	local size = 50
	local radius = size/2
	self.ability_display = self:AddChild(Widget())
    self.ability_display:SetPosition(0, -10)
	self.ability_icon = self.ability_display:AddChild(Image("images/rf_alt_icons.xml", "rf_radial_frame.tex"))
	self.ability_icon.abilities = {}
	self.ability_icon:ScaleToSize(size, size, true)
    self.ability_display:Hide()

    self.ability_icon.SetAbilities = function(ability_icon, source, icons, active_ability)
    	local new_ability = self.current_source ~= source
    	for i,icon_info in pairs(icons) do
    		local icon = ability_icon.abilities[i]
    		if not icon then
    			icon = self.ability_display:AddChild(Image())
    			icon.text = icon:AddChild(Text(_G.UIFONT, 70))
    			ability_icon.abilities[i] = icon
    		end
    		if new_ability then
	    		icon:SetTexture(icon_info.atlas, icon_info.tex)
	    		if i > 1 then
	    			local angle = 360/(#icons - 1) * (i - 1)
	    			local radian = angle * _G.DEGREES
	    			local offset = _G.Vector3(math.cos(radian), math.sin(radian), 0) * radius
	    			icon:SetPosition(offset)
	    			icon:ScaleToSize(20, 20, true)
	    			icon.text:SetString(_G.TheInput:GetLocalizedControl(0, ability_controls[i-1]))
	    			if angle < 90 or angle > 270 then
	    				local w,h = icon.text:GetRegionSize()
	    				icon.text:SetPosition(w/2 + 30, 0)
	    				icon.text:SetHAlign(_G.ANCHOR_LEFT)
	    			else
	    				local w,h = icon.text:GetRegionSize()
	    				icon.text:SetPosition(-w/2 - 30, 0)
	    				icon.text:SetHAlign(_G.ANCHOR_RIGHT)
	    			end
	    		else
	    			icon:ScaleToSize(30, 30, true)
	    		end
	    	end
    		if i == active_ability then
    			icon:SetTint(1,1,1,1)
    		else
    			icon:SetTint(0.25,0.25,0.25,1)
    		end
    		icon:Show()
    	end
    	if new_ability then
    		self.current_source = source
			for i = #icons + 1, #ability_icon.abilities do
				ability_icon.abilities[i]:Hide()
			end
		end
		if #icons > 1 then
			self.secondarytext:SetPosition(0, -60, 0)
		end
	end

    local _oldOnUpdate = self.OnUpdate
    self.OnUpdate = function()
    	_oldOnUpdate(self)
    	if self.shown then
			local aoetargeting = self.owner.components.playercontroller:IsAOETargeting()
	        local rmb = self.owner.components.playercontroller:GetRightMouseAction()
	        if rmb and rmb.action == _G.ACTIONS.CASTAOE then
	        	local ability_source = rmb.invobject.prefab
	        	local prefab_info = ability_source and _G.GetValidForgePrefab(ability_source)
	        	local ability_tuning = _G.CheckTable(TUNING, prefab_info and prefab_info.mod_id or "FORGE", string.upper(ability_source))
	        	local ability_icons = ability_tuning and ability_tuning.RET and ability_tuning.RET.ICONS
	        	if ability_icons then
	        		local control = DecodePressedControls()
	        		self.ability_icon:SetAbilities(ability_source, ability_icons, control)
	        		self.ability_display:Show()
	        	else
	        		self.ability_display:Hide()
	        		self.secondarytext:SetPosition(0, -30, 0)
	        	end
	        else
	        	self.ability_display:Hide()
	        end
	    end
    end
end)

-- Save last valid color to be used when spawning the reticule on cast.
AddComponentPostInit("aoetargeting", function(self)
	self.reticule.validcolours = {}
	self.last_valid_colour = self.reticule.validcolour
	local _oldStopTargeting = self.StopTargeting
	self.StopTargeting = function(self)
	    if self.inst.components.reticule ~= nil then
	    	self.last_valid_colour = self.inst.components.reticule.currentcolour
	    end
	    _oldStopTargeting(self)
	end

	-- Adjust range based on players scale
	self.GetRange = function(self)
		return self.range * (_G.ThePlayer and _G.ThePlayer.replica.scaler and _G.ThePlayer.replica.scaler:GetScale() or 1)
	end
end)

-- Adds reforge atlas checks when retrieving inventory item atlas'.
-- Note: This does not return the tex, so that will need to be accounted for outside of this function.
local inventoryItemAtlasLookup = {}
_G.GetInventoryItemAtlas = function(imagename)
	local atlas = inventoryItemAtlasLookup[imagename]
	if atlas then
		return atlas
	end
	local name = string.sub(imagename, 1, string.len(imagename) - 4) -- remove ".tex"
	local reforged_prefab = _G.GetValidForgePrefab(name)
	local base_atlas = "images/inventoryimages1.xml"
	local base_atlas_2 = "images/inventoryimages2.xml"
	atlas = reforged_prefab and reforged_prefab.atlas or _G.TheSim:AtlasContains(base_atlas, imagename) and base_atlas or _G.TheSim:AtlasContains(base_atlas_2, imagename) and base_atlas_2 or "images/inventoryimages.xml"
	inventoryItemAtlasLookup[imagename] = atlas
	return atlas
end

--[[
TODO
need to test if Chatter does translate clients, this means an english server will not affect a non english client
should players also use chatter instead of say? a lot of admincommands use that...
possibly make the forgelord say something when a map hazard occurs?

need to get name from prefab
	rhinocebro crashes it because that's not the name it uses
	needs testing, should be fixed

Translations partially worked
	waveset dialogue worked
	admin commands only worked for parameters, dialogue did not translate, ex. "Adjusting [chinese mutator] to x"
	should work now, needs testing
--]]
-- Adds the ability to send format parameters for a string
AddComponentPostInit("talker", function(self)
	local _oldMakeChatter = self.MakeChatter
	self.MakeChatter = function(self)
		if not self.chatter then
			_oldMakeChatter(self)
			self.chatter.strpar = _G.net_string(self.inst.GUID, "talker.chatter.strpar")
		end
	end
	local _oldChatter = self.Chatter
	self.Chatter = function(self, strtbl, strid, time, forcetext, strpar)
		if self.chatter ~= nil and _G.TheWorld.ismastersim then
			self.chatter.strpar:set(strpar and (type(strpar) == "table" and _G.SerializeTable(strpar) or strpar) or "")
			_oldChatter(self, strtbl, strid, time, forcetext)
		end
	end
end)
AddPrefabPostInit("lavaarena_boarlord", function(inst)
	inst.components.talker.resolvechatterfn = _G.COMMON_FNS.GetDialogueStrings
end)

-- Also scales the ents physics properties when used.
AddComponentPostInit("scaler", function(self)
	self.base_scale = 1
	self.damage_mult = 1
	self.current_scale = 1
	-- Physics Parameters
	self.base_rad = nil
	self.current_rad = nil
	self.current_height = nil
	self.base_mass = nil
	self.current_mass = nil
	self.base_shadow = nil
	self.current_shadow = nil
	self.source = nil

	-- Controls the rate at which these increase based on the given scale. Default is 1 to 1 with the scalar.
	self.rad_rate = 1
	self.height_rate = 1
	self.mass_rate = 1
	self.shadow_rate = 1
	self.inst.replica.scaler:SetScale(1)

	self.ApplyScale = function(self)
		local mults, adds, flats = self:GetScalerBuffs()
		self.scale = mults * adds -- + flats -- Not supporting flats for now
		self.inst.replica.scaler:SetScale(self.scale)
		self.current_scale = self.base_scale * self.scale
	    self.inst.Transform:SetScale(self.current_scale,self.current_scale,self.current_scale)

	    if self.base_rad then
	    	self.current_rad = self.base_rad * self.scale * self.rad_rate
	    	self.current_height = (self.base_height or 2) * self.scale * self.height_rate
	    	local pos = self.inst:GetPosition()
	    	self.inst.Physics:SetCapsule(self.current_rad, self.current_height)
	    	self.inst.Transform:SetPosition(pos:Get())
	    end

	    if self.base_mass then
	    	self.current_mass = self.base_mass * self.scale * self.mass_rate
	    	self.inst.Physics:SetMass(self.current_mass)
	    end

	    if self.base_shadow then
	    	self.current_shadow = {self.base_shadow[1] * self.scale * self.shadow_rate, self.base_shadow[2] * self.scale * self.shadow_rate}
			self.inst.DynamicShadow:SetSize(unpack(self.current_shadow))
	    end

	    if self.inst.components.combat then
	    	self.inst.components.combat:UpdateRange()
		    local weapon = self.inst.components.combat:GetWeapon()
		    if weapon then
		    	weapon.components.weapon:UpdateAltAttackRange(nil, nil, self.inst)
		    end
	    end

	    if self.OnApplyScale then
	        self.OnApplyScale(self.inst, self.current_scale, self.scale)
	    end
	end

	self.GetScalerBuffs = function(self)
		local source = self.source
		local mults, adds, flats = self:GetSourceBuffs()
		if self.inst.components.buffable then
			local scaler_mults, scaler_adds, scaler_flats = self.inst.components.buffable:GetStatBuffs({"scaler"})
			mults = mults * scaler_mults
			adds = adds + scaler_adds - 1 -- Offset for the sources scaler buff
			flats = flats + scaler_flats
		end
		return mults, adds, flats
	end

	self.GetSourceBuffs = function(self, checking_source)
		local source = self.source
		local mults = 1
		local adds = 1
		local flats = 0
		if source then
			-- Retrieve the sources source
			if source.components.scaler and source.components.scaler.source then
				return source.components.scaler:GetSourceBuffs()
			-- Return the sources current scaler buffs
			elseif source.components.buffable then
				return source.components.buffable:GetStatBuffs({"scaler"})
			end
		end
		return mults, adds, flats
	end

	-- force_update is true by default
	self.SetSource = function(self, source, force_update)
		self.source = source
		if force_update == nil or force_update then
			self:ApplyScale()
		end
	end
	self.SetBaseScale = function(self, scale)
		self.base_scale = scale or self.base_scale
	end
	self.SetBaseRadius = function(self, radius)
		self.base_rad = radius or self.base_rad
	end
	self.SetBaseHeight = function(self, height)
		self.base_height = height or self.base_height
	end
	self.SetBaseMass = function(self, mass)
		self.base_mass = mass or self.base_mass
	end
	self.SetBaseShadow = function(self, shadow)
		self.base_shadow = shadow or self.base_shadow
	end
	self.SetRadiusRate = function(self, rate)
		self.rad_rate = rate or self.rad_rate
	end
	self.SetHeightRate = function(self, rate)
		self.height_rate = rate or self.height_rate
	end
	self.SetMassRate = function(self, rate)
		self.mass_rate = rate or self.mass_rate
	end
	self.SetShadowRate = function(self, rate)
		self.shadow_rate = rate or self.shadow_rate
	end
end)
--[[
AddComponentPostInit("playercontroller", function(self, inst)
	local _oldEchoReticuleAt = self.EchoReticuleAt
	self.EchoReticuleAt = function(self, x, y, z)
		local reticule = SpawnPrefab(self.reticule.reticuleprefab)
	    if reticule then
	    	local base_scale = 1.5 -- self.reticule.Transform:GetScale() or 1 -- TODO No GetScale fn for AnimState, all reticules seems to be set to 1.5
			local scale = base_scale * (_G.ThePlayer and _G.ThePlayer.replica.scaler and _G.ThePlayer.replica.scaler:GetScale() or 1)
			reticule.AnimState:SetScale(scale,scale)
	        reticule.Transform:SetPosition(x, 0, z)
	        if reticule.Flash then
	            reticule:Flash()
	        else
	            reticule:DoTaskInTime(1, reticule.Remove)
	        end
	    end
	end
end)--]]

--------------------
-- New Characters --
--------------------
AddModCharacter("spectator", "NEUTRAL")

-- Allow player to join midmatch if there is a free slot.
_G.ClientAuthenticationComplete = function(userid)
	if _G.TheWorld ~= nil and _G.TheWorld:IsValid() then
		local lavaareanevent = _G.TheWorld.components.lavaarenaevent
		local lavaareaneventstate = _G.TheWorld.net.components.lavaarenaeventstate
		local current_player_count = lavaareanevent:GetConnectedUsersCount()
		-- If no free slots are available midmatch then kick from server and give them a special popup. -- TODO special popup not possible?
		-- Note admins will join no matter what, but will not reserve their slot if all slots are full. Unfortunately can't prevent admins from joining.
		if _G.REFORGED_SETTINGS.other.joinable_midmatch and _G.REFORGED_SETTINGS.other.reserve_slots and lavaareaneventstate:IsInProgress() and not (_G.IsUserAdmin(userid) or lavaareanevent:IsUserReserved(userid) or (_G.TheNet:GetServerMaxPlayers() - current_player_count) > lavaareanevent:GetReservedSlotsRemaining()) then
			print("[RF.NOTE] User '" .. tostring(userid) .. "' has attempted to join, but remaining players slots are currently reserved. User '" .. tostring(userid) .. "' will be temporarily banned for 60 seconds to prevent rejoin spam.")
			_G.TheNet:BanForTime(userid, 60)
		else
			_G.TheWorld:PushEvent("ms_clientauthenticationcomplete", {userid = userid})
		end
	end
end

-- Allow clients to see if a match has started.
AddComponentPostInit("lavaarenaeventstate", function(self)
	self.in_progress = _G.net_bool(self.inst.GUID, "lavaarenaeventstate.in_progress", "in_progressdirty")
	self.is_match_complete = _G.net_bool(self.inst.GUID, "lavaarenaeventstate.is_match_complete")

	self.IsInProgress = function()
	    return self.in_progress:value()
	end

    self.IsMatchComplete = function()
        return self.is_match_complete:value()
    end
end)

-- Add Revive Charges and buffs to revives.
AddComponentPostInit("revivablecorpse", function(self)
	self.revivable = _G.net_bool(self.inst.GUID, "revivablecorpse.revivable")
	self.SetRevivable = function(self, val)
		self.revivable:set(val)
	end
	self:SetRevivable(true)

	local _oldCanBeRevivedBy = self.CanBeRevivedBy
	self.CanBeRevivedBy = function(self, reviver)
		return self.revivable:value() and _oldCanBeRevivedBy(self, reviver)
	end

	self.base_revive_health_percent = 1
	self.SetBaseReviveHealthPercent = function(self, percent)
	    if self.ismastersim then
	        self.base_revive_health_percent = percent or self.base_revive_health_percent
	    end
	end

	self.revivers_mult = 1
	self.GetReviveHealthPercent = function(self)
	    if self.ismastersim then
	        return self.health_override or self.revive_health_percet * self.base_revive_health_percent * (self.revivers_mult or 1)
	    end
	end

	local _oldSetCorpse = self.SetCorpse
	self.SetCorpse = function(self, corpse)
	    if self.ismastersim and not corpse then
			self.reviving = false
			self.health_override = nil
			self.revivers_mult = 1
			self.inst:PushEvent("revived")
	    end
	    _oldSetCorpse(self, corpse)
	end

	local _oldRevive = self.Revive
	self.Revive = function(self, reviver, health_override)
		if not self:IsReviving() then
			_oldRevive(self, reviver)
			if self.ismastersim then
				self.reviving = true
				self.health_override = health_override
				self.revivers_mult = reviver and reviver.components.corpsereviver and reviver.components.corpsereviver:GetReviveHealthPercentMult() or 1
			end
		end
	end

	self.reviving = false
	self.IsReviving = function(self)
		return self.reviving or self.consuming_revive_charge
	end

	self.IsCorpse = function(self)
		return self.inst:HasTag("corpse")
	end

	self.revive_charges = {}
	self.revive_priority = {}
	self.AddCharge = function(self, source, health, on_revive_fn, priority)
		if _G.TheWorld.components.lavaarenaevent.victory == nil and not self.revive_charges[source] then
			self.revive_charges[source] = true
			table.insert(self.revive_priority, {source = source, health = health, on_revive_fn = on_revive_fn, priority = priority})
			table.sort(self.revive_priority, function(a, b)
				return a.priority < b.priority
			end)
			-- Check to see if charge should be immediately used.
			self:ConsumeCharge()
		end
	end

	self.RemoveCharge = function(self, source)
		if self.revive_charges[source] then
			self.revive_charges[source] = nil
			for i,data in pairs(self.revive_priority) do
				if data.source == source then
					table.remove(self.revive_priority, i)
					break
				end
			end
		end
	end

	self.HasReviveCharges = function(self)
		return #self.revive_priority > 0
	end

	local REVIVE_DELAY = 3 -- Ensure the owner is completely dead before attempting to revive.
	self.consuming_revive_charge = false
	self.ConsumeCharge = function(self)
		if self.inst.components.health:IsDead() and not self:IsReviving() and #self.revive_priority > 0 then
			self.consuming_revive_charge = true
			self.inst:DoTaskInTime(self.inst.sg.currentstate.name ~= "corpse" and REVIVE_DELAY or 0, function()
				self.consuming_revive_charge = false
				local revive_data = table.remove(self.revive_priority, 1)
				self:Revive(revive_data.source, revive_data.health)
				if revive_data.on_revive_fn then
					revive_data.on_revive_fn(self.inst)
				end
				self.revive_charges[revive_data.source] = nil
			end)
		end
	end

	self.inst:ListenForEvent("death", function()
		self:ConsumeCharge()
	end)
end)

-- Reduce Teleport duration
local function EditTeleporter(inst)
	inst.components.teleporter.travelcameratime = 0
	inst.components.teleporter.travelarrivetime = 1
end
AddPrefabPostInit("pocketwatch_portal_entrance", function(inst)
	inst:AddTag("ALLOWCLICK") -- Prevent NO_CLICK from being added
	if not _G.TheWorld.ismastersim then
        return
    end
    EditTeleporter(inst)
end)
AddPrefabPostInit("pocketwatch_portal_exit", function(inst)
	if not _G.TheWorld.ismastersim then
        return
    end
    EditTeleporter(inst)
end)

-- Add Non Timer Cooldowns to inventory display.
local ItemTile = require("widgets/itemtile")
-- Replace the client side event file saving with our own.
local _oldItemTile_ctor = ItemTile._ctor
ItemTile._ctor = function(self, ...)
	self.Refresh = function(self)
	    self.ispreviewing = false
	    self.ignore_stacksize_anim = nil

	    if self.movinganim == nil and self.item.replica.stackable ~= nil then
	        self:SetQuantity(self.item.replica.stackable:StackSize())
	    end

	    if self.ismastersim then
	        if self.item.components.armor ~= nil then
	            self:SetPercent(self.item.components.armor:GetPercent())
	        elseif self.item.components.perishable ~= nil then
	            if self:HasSpoilage() then
	                self:SetPerishPercent(self.item.components.perishable:GetPercent())
	            else
	                self:SetPercent(self.item.components.perishable:GetPercent())
	            end
	        elseif self.item.components.finiteuses ~= nil then
	            self:SetPercent(self.item.components.finiteuses:GetPercent())
	        elseif self.item.components.fueled ~= nil then
	            self:SetPercent(self.item.components.fueled:GetPercent())
	        end

	        if self.rechargeframe ~= nil and self.item.components.rechargeable ~= nil then
	        	if self.item.components.rechargeable:IsTimer() then
	            	self:SetChargePercent(self.item.components.rechargeable:GetPercent())
	            	self:SetChargeTime(self.item.components.rechargeable:GetRechargeTime())
	            else
	            	self:SetChargePercent(self.item.components.rechargeable:GetPercent(), true)
	            end
	        end
	    elseif self.item.replica.inventoryitem ~= nil then
	        self.item.replica.inventoryitem:DeserializeUsage()
	    end

	    if not self.isactivetile then
	        if self.item:GetIsWet() then
	            self.wetness:Show()
	        else
	            self.wetness:Hide()
	        end
	    end
	end
	_oldItemTile_ctor(self, ...)
end
AddClassPostConstruct("widgets/itemtile", function(self)
	if self.rechargeframe ~= nil then
        self.inst:ListenForEvent("forcerechargechange",
	        function(invitem, data)
	            self:SetChargePercent(data.percent, true)
	        end, self.item)
        --[[self.inst:ListenForEvent("forcerechargetimechange",
            function(invitem, data)
                self:SetChargeTime(data.t, true)
            end, self.item)--]]
    end
	-- Add force set percent that does not start updating the anim.
	local _oldSetChargePercent = self.SetChargePercent
	self.SetChargePercent = function(inst, percent, forced)
		_oldSetChargePercent(inst, percent)
		if forced then
			self:StopUpdating()
		end
	end
	--[[
	local _oldSetChargeTime = self.SetChargeTime
	self.SetChargeTime = function(self, time, forced)
		_oldSetChargeTime(self, time)
		if forced then
			self:StopUpdating()
		end
	end--]]
end)
AddClassPostConstruct("components/inventoryitem_replica", function(self) -- c_sel().replica.inventoryitem:SetChargeTime(90/180)  c_sel():PushEvent("forcerechargechange", {percent = 90/180, overtime = false})
	if _G.TheWorld.ismastersim then
		self.inst:ListenForEvent("forcerechargechange", function(inst, data) self.classified:SerializeRecharge(data.percent, false, true) end)
	end
	--[[
	local _oldSetChargeTime = self.SetChargeTime
	self.SetChargeTime = function(self, t, forced)
		if forced then
	    	--self.classified:SerializeRechargeTime(t)
	    	self.classified.recharge:set(self.classified.recharge:value())
	    	self.inst:PushEvent("forcerechargetimechange", {t = t})
		else
			_oldSetChargeTime(self, t)
		end
	end--]]
	self.SerializeUsage = function(self)
	    local percentusedcomponent =
	        self.inst.components.armor or
	        self.inst.components.finiteuses or
	        self.inst.components.fueled

	    self.classified:SerializePercentUsed(percentusedcomponent ~= nil and percentusedcomponent:GetPercent() or nil)
	    self.classified:SerializePerish(self.inst.components.perishable ~= nil and self.inst.components.perishable:GetPercent() or nil)
	    if self.inst.components.rechargeable ~= nil then
	    	local is_timer = self.inst.components.rechargeable:IsTimer()
	        self.classified:SerializeRecharge(self.inst.components.rechargeable:GetPercent(), nil, not is_timer)
	        if is_timer then
	        	self.classified:SerializeRechargeTime(self.inst.components.rechargeable:GetRechargeTime())
	        end
	    else
	        self.classified:SerializeRecharge(nil)
	        self.classified:SerializeRechargeTime(nil)
	    end
	end
end)
AddPrefabPostInit("inventoryitem_classified", function(inst)
	inst.force_recharge = _G.net_byte(inst.GUID, "inventoryitem.forcerecharge", "forcerechargedirty")
	--inst.force_rechargetime = _G.net_float(inst.GUID, "inventoryitem.force_rechargetime", "forcerechargetimedirty")
	if not _G.TheWorld.ismastersim then
        --local _oldDeserializeRecharge = inst.DeserializeRecharge
        inst.DeserializeForceRecharge = function(inst)
        	--_oldDeserializeRecharge(inst)
        	if inst.force_recharge:value() < 181 and inst._parent ~= nil then
		        inst._parent:PushEvent("forcerechargechange", {percent = inst.force_recharge:value() / 180})
		    end
    	end
    	--[[inst.DeserializeForceRechargeTime = function(inst)
    		print("Deserialized Force Recharge Time")
		    if inst.force_rechargetime:value() >= -1 then
		        OnRechargeDirty(inst)
		        if inst._parent ~= nil then
		            inst._parent:PushEvent("forcerechargetimechange", {t = inst.force_rechargetime:value() >= 0 and inst.force_rechargetime:value() or math.huge})
		        end
		    end
		end--]]
    	inst:DoTaskInTime(0, function()
    		inst:ListenForEvent("forcerechargedirty", inst.DeserializeForceRecharge)
    		--inst:ListenForEvent("forcerechargetimedirty", inst.DeserializeForceRechargeTime)
    	end)
    end
    local _oldSerializeRecharge = inst.SerializeRecharge
    inst.SerializeRecharge = function(inst, percent, overtime, force)
    	if force then
    		inst.force_recharge:set(percent == nil and 255 or percent <= 0 and 0 or percent >= 1 and 180 or math.min(179, math.floor(percent * 180 + .5)))
    	else
    		_oldSerializeRecharge(inst, percent, overtime)
    	end
	end
end)

_G.Vector3.IsValid = function(self)
	return _G.IsNumberValid(self.x) and _G.IsNumberValid(self.y) and _G.IsNumberValid(self.z)
end

-- Disable activation and deactivation of all skills from the skill tree due to them not being compatible with forge. (for now...TODO?)
AddComponentPostInit("skilltreeupdater", function(self)
    local _oldActivateSkill_Client = self.ActivateSkill_Client
    self.ActivateSkill_Client = function(self, ...)
    end

    local _oldActivateSkill_Server = self.ActivateSkill_Server
    self.ActivateSkill_Server = function(self, ...)
    end

    local _oldActivateSkill = self.ActivateSkill
    self.ActivateSkill = function(self, ...)
    end

    local _oldDeactivateSkill_Client = self.DeactivateSkill_Client
    self.DeactivateSkill_Client = function(self, ...)
    end

    local _oldDeactivateSkill = self.DeactivateSkill
    self.DeactivateSkill = function(self, ...)
    end
end)