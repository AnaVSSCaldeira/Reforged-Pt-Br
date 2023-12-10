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
------------
-- Common --
------------
local function common_postinit(inst, name)
	-- Create FX Network -- TODO remove this if network works
	--COMMON_FNS.CreateFXNetwork(inst)
	--[[ TODO removes replicas, need to figure out which ones can and can't be removed
	-- Remove Environment FX
	local performance_settings = _G.REFORGED_SETTINGS.performance
	if not _G.TheNet:IsDedicated() and not (performance_settings.environment_fx and performance_settings.all_fx) then
		print("added spawn event for performance....")
		inst:DoTaskInTime(0, function(inst)
			print("Applying performance improvements...")
			if _G.TheNet:GetUserID() == inst.userid then
				--for i,ent in pairs(Ents) do if not (ent:HasTag("UI") or ent:HasTag("groundtargetblocker")) then print(ent:GetDebugString()) end end
				local count = 0
				local ents = _G.TheSim:FindEntities(0,0,0,1000)
				for i,ent in pairs(ents) do
					--print(ent:GetDebugString())
					if ent:HasTag("DECOR") or ent:HasTag("fx") and not ent:HasTag("groundtargetblocker") or ent.prefab == "lavaarena_floorgrate" or ent.prefab == "lavaarena_crowdstand" then
						count = count + 1
						ent:Remove()
					end
				end
				print("Removed " .. tostring(count) .. " environment entities for performance.")
			end
		end)
	end--]]
	inst:AddComponent("pethealthbars")
end

local function master_postinit(inst, name)
	inst:AddComponent("drownable")
	inst:AddComponent("itemtyperestrictions")
	-- default is nil wtf make 1
	inst.components.combat.damagemultiplier = 1 -- TODO is this still needed? might be from old buff system?
	inst.components.combat:SetAttackPeriod(0) --Because its required for multitargeting to function
	--Make players not spout out their battlecries
	inst.components.combat.battlecryenabled = false
	-- Set starting inventory
	inst.starting_inventory = TUNING.GAMEMODE_STARTING_ITEMS.LAVAARENA[string.upper(name)] or TUNING.GAMEMODE_STARTING_ITEMS.LAVAARENA.WILSON
	-- Set characters max health TODO might change this for api, but might not
	inst.components.health:SetMaxHealth(TUNING.LAVAARENA_STARTING_HEALTH[string.upper(name)] or TUNING.LAVAARENA_STARTING_HEALTH.WILSON)
	-- Set health on revive
	inst.components.revivablecorpse:SetReviveHealthPercent(TUNING.FORGE.HEALTH_ON_REVIVE)
	-- Make character buffable
	inst:AddComponent("buffable")
	-- Make character scalable
	inst:AddComponent("scaler")
	inst.components.scaler:SetBaseRadius(0.5)
	inst.components.scaler:SetBaseMass(75)
	inst:AddComponent("shader_manager")

	--------------------
	-- Damage Numbers --
	--------------------
	--data = { target = self.inst, damage = damage, damageresolved = damageresolved, stimuli = stimuli, weapon = weapon, redirected = damageredirecttarget }
	inst:ListenForEvent("onhitother", function(self, data)
		-- TODO remove this when confirmed working
		--[[if _G.REFORGED_SETTINGS.display.damage_numbers == "all" then
			print("[DamageNumber] All Players")
			for i, player in pairs(_G.AllPlayers) do
				player:SpawnChild("damage_number"):UpdateDamageNumbers(player, data.target, math.floor(data.damageresolved + 0.5), data.weapon and data.weapon.damage_type, data.stimuli, data.weapon and data.weapon.components.weapon.isaltattacking or false, self.playercolour)
			end
		else--]]
			self:SpawnChild("damage_number"):UpdateDamageNumbers(self, data.target, math.floor(data.damageresolved + 0.5), data.weapon and data.weapon.damage_type, data.stimuli, data.is_alt or false, self.playercolour)
		--end
	end)
	-- TODO create option for this? Displays damage dealt to player, need to create options for all damage number options
	inst:ListenForEvent("attacked", function(self, data)
		if data and data.damageresolved then
			self:SpawnChild("damage_number"):UpdateDamageNumbers(self, self, math.floor(data.damageresolved + 0.5))
		end
	end)

	-----------
	-- Death --
	-----------
	inst:ListenForEvent("death", function(inst)
		if not (inst.components.revivablecorpse and (inst.components.revivablecorpse:IsReviving() or inst.components.revivablecorpse:HasReviveCharges())) and (not inst.IsTrueDeath or inst:IsTrueDeath()) then
			_G.TheWorld:PushEvent("ms_playerdied", inst)
		end
	end)

	---------------
	-- Pet Spawn --
	---------------
	local _oldonspawnpet = inst.components.petleash.onspawnfn
	local _oldondespawnpet = inst.components.petleash.ondespawnfn
	local player = inst
	inst.components.petleash:SetOnSpawnFn(function(inst, pet)
		if not pet then return end

		-- Custom spawn
		if pet.ForgeOnSpawn then
			pet:ForgeOnSpawn(inst)
		elseif not pet:HasTag("nospawnfx") then
			_oldonspawnpet(inst, pet)
		end

		-- Add stat tracking for pets
		_G.COMMON_FNS.PetStatTrackerInit(pet)
		-- Set Pet Levels
		if pet.current_level and inst.current_pet_level ~= pet.current_level then
			pet:PushEvent("updatepetmastery", {level = inst.current_pet_level, force = true})
			--pet:UpdatePetLevel(nil, inst.current_pet_level or 1, true)
		end
	end)
	inst.components.petleash:SetOnDespawnFn(function(inst, pet)
	    if not pet then return end

		-- Custom Despawn
		if pet.ForgeOnDespawn then
			pet:ForgeOnDespawn(inst)
		elseif not pet:HasTag("nospawnfx") then
			_oldondespawnpet(inst, pet)
		end
		pet:Remove()
	end)

	inst.current_pet_level = 1 -- This is the base level pets will spawn at. TODO might need to update pets to check this.

	--------------------
	--Boat things
	--------------------
	inst.components.locomotor:SetAllowPlatformHopping(false) --stops boat bug???

	------------------
	-- Player Spawn --
	------------------
	--[[
	  T
	L   R
	  B
	 3 2
	4 1 5 wilson, wes, wigfrid, wx, maxwell, wicker
	  6
	Lobby: N/A
	Health: wx (client), wilson, wes, wig, wicker, maxwell

	 5 2
	6 1 3  wig, winona, maxwell, woodie, wilson, wx
	  4
	Lobby: wig, wilson, winona, maxwell, wx, woodie (1, 5, 2, 3, 6, 4)
	Health: wig (client), winona, wilson, wx, woodie, maxwell

	 2 4
	3 1 6  winona(c), woodie, wx, wicker, winona(top), wilson (spawned late)
	  4
	Lobby: winona(c), wilson, winona(j), wx, wicker, woodie (1, 6, 4 (top), 3, 4, 2)
	Health: winona(c client), winona(j), woodie, wx, wicker, wilson

	Maybe there is no delay of spawning, it's just the players connecting?
	--]]
	-- Check if floor fx of spawner is playing
	local function GetSpawnOffset(index)
		if index == 1 then
			return _G.Vector3()
		else
			local angle = (index-1)/5 * 2 * _G.PI
			local pos = _G.TheWorld.multiplayerportal ~= nil and _G.TheWorld.multiplayerportal:GetPosition() or _G.TheWorld.components.lavaarenaevent:GetArenaCenterPoint()
			return _G.FindWalkableOffset(pos, angle, 1.5, 2, true, true)
		end
	end
	local function getplayerindexinplayertable(player)
		for k, v in pairs(_G.AllPlayers) do
			if v == player then
				return k
			end
		end
		return 1
	end
	-- Delayed 1 frame to ensure that the original OnNewSpawn is set
	local _OnNewSpawn_old = inst.OnNewSpawn
	inst.OnNewSpawn = function(inst)
		_G.TheWorld:PushEvent("lavaarena_portal_activate")
		if _OnNewSpawn_old then
			_OnNewSpawn_old(inst)
		end
		local index = getplayerindexinplayertable(inst)
		inst:Hide()
		inst.DynamicShadow:Enable(false)
		if inst.components.playercontroller then
			inst.components.playercontroller:Enable(false)
		end
		local pos = _G.TheWorld.multiplayerportal and _G.TheWorld.multiplayerportal:GetPosition() or inst:GetPosition()
		local spawnfx = _G.TheWorld.multiplayerportal and _G.TheWorld.multiplayerportal.spawnfx_prefab or nil
		local offset = GetSpawnOffset(index)
		if offset then
			pos.x = pos.x + offset.x
			pos.z = pos.z + offset.z
		end
		inst:DoTaskInTime(0, function() inst.Transform:SetPosition(pos.x, 0, pos.z) end)
		inst:DoTaskInTime(1+0.2*index, function(inst)
			local fire = spawnfx and _G.SpawnPrefab(spawnfx) or _G.SpawnPrefab("lavaarena_portal_player_fx")
			fire.Transform:SetPosition(pos.x, 0, pos.z)
			if inst:HasTag("largecreature") or inst:HasTag("epic") then --totally not for PP I swear!
				fire.Transform:SetScale(2, 2, 2)
			end
			inst:DoTaskInTime(0.3, function(inst) -- TODO random time?
				if inst.prefab ~= "spectator" then
					inst:Show()
					inst.DynamicShadow:Enable(true)
					inst:PushEvent("player_portal_spawn")
				end

				if inst.forge_onspawnfn then
					--inst.forge_onspawnfn() --Leo: I'll test this when I get up later.
				end

				if inst.components.playercontroller then
					inst.components.playercontroller:Enable(true)
				end
				if inst == _G.AllPlayers[#_G.AllPlayers] then
					if not _G.TheWorld.net.components.lavaarenaeventstate:IsInProgress() then
						_G.TheWorld:PushEvent("ms_forge_allplayersspawned")
					end
					_G.TheWorld:PushEvent("lavaarena_portal_deactivate") -- TODO why don't we just use ms_forge_allplayersspawned event?
				end
			end)
		end)
	end
end

------------
-- Wilson --
------------
local function wilson_master_postinit(inst) -- TODO pass in old master?
	inst.components.itemtyperestrictions:SetRestrictions("books") -- TODO common?
end
------------
-- Willow --
------------
local function willow_customidleanimfn(inst) -- TODO any item that should trigger this anim?
    local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    return item ~= nil and item.prefab == "bernie_inactive" and "idle_willow" or nil
end

local function willow_master_postinit(inst)
	inst.components.itemtyperestrictions:SetRestrictions({"melees", "books"})
	inst.customidleanim = willow_customidleanimfn
end
-----------
-- Wendy --
-----------
local function wendy_master_postinit(inst)
	inst.components.itemtyperestrictions:SetRestrictions({"melees", "books"})
end
--------------
-- Wolfgang --
--------------
local function wolfgang_master_postinit(inst)
	inst.components.itemtyperestrictions:SetRestrictions({"darts", "staves", "books"})
end
-----------
-- WX-78 --
-----------
local function wx78_master_postinit(inst)
	inst.components.itemtyperestrictions:SetRestrictions({"darts", "staves", "books"})
end
------------------
-- Wickerbottom --
------------------
local function wickerbottom_master_postinit(inst)
	inst.components.itemtyperestrictions:SetRestrictions({"darts", "melees"})
end
---------
-- Wes --
---------
local function wes_master_postinit(inst, name)
	inst.components.itemtyperestrictions:SetRestrictions("books")
end
-------------
-- Maxwell --
-------------
local function maxwell_master_postinit(inst)
	inst.soundsname = "maxwell"
	inst.components.itemtyperestrictions:SetRestrictions({"darts", "melees"})
end
------------
-- Woodie --
------------
local function woodie_customidleanimfn(inst)
    local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    return item ~= nil and (item.prefab == "lucy" or item.prefab == "riledlucy") and "idle_woodie" or nil
end

local function woodie_master_postinit(inst)
	inst.components.itemtyperestrictions:SetRestrictions({"darts", "staves", "books"})
	inst.customidleanim = woodie_customidleanimfn
end
-------------
-- Wigfrid --
-------------
local function wigfrid_master_postinit(inst, name)
	inst.talker_path_override = "dontstarve_DLC001/characters/" --Because for some reason player talker values don't get set in forge, might let Klei know of this. Remove this if they fix it.
	inst.components.itemtyperestrictions:SetRestrictions({"staves", "books"})
end
------------
-- Webber --
------------
local function webber_master_postinit(inst)
	inst.talker_path_override = "dontstarve_DLC001/characters/" --Because for some reason player talker values don't get set in forge, might let Klei know of this. Remove this if they fix it.
	inst.components.itemtyperestrictions:SetRestrictions({"staves", "books"})
end
------------
-- Winona --
------------
local function winona_master_postinit(inst, name)
	inst.components.itemtyperestrictions:SetRestrictions("books")
	inst.customidleanim = "idle_winona"
	inst.components.grue:SetResistance(1)
end
------------
-- Wortox --
------------
local function wortox_master_postinit(inst)
	inst.components.itemtyperestrictions:SetRestrictions({"darts", "books", "staves"})
	inst.customidleanim = "idle_wortox"
end
--------------
-- Wormwood --
--------------
local function wormwood_common_postinit(inst, name, _oldPostInit)
	_oldPostInit(inst)
end

local function wormwood_customidleanimfn(inst)
    return inst.AnimState:CompareSymbolBuilds("hand", "hand_idle_wormwood") and "idle_wormwood" or nil
end

local function wormwood_master_postinit(inst)
	inst.components.itemtyperestrictions:SetRestrictions({"melees", "books"})
	inst.customidleanim = wormwood_customidleanimfn
end
-----------
-- Warly --
-----------
local function warly_master_postinit(inst, name)
	inst.components.itemtyperestrictions:SetRestrictions({"books"}) -- "darts"
	inst.customidleanim = "idle_warly"
end
----------
-- Wurt --
----------
local function wurt_master_postinit(inst)
end
------------
-- Walter --
------------
local function walter_master_postinit(inst)
	inst.components.itemtyperestrictions:SetRestrictions({"melees", "staves"})
end
------------
-- Wanda  --
------------
local function wanda_master_postinit(inst)
	inst.components.itemtyperestrictions:SetRestrictions({"darts"})
	inst.customidleanim = "idle_wanda"
    inst.talker_path_override = "wanda2/characters/"
end
------------

local character_postinits = {
	common = common_postinit,
	master = master_postinit,
	wilson = {
		master = wilson_master_postinit,
	},
	willow = {
		master = willow_master_postinit,
	},
	wendy = {
		master = wendy_master_postinit,
	},
	wolfgang = {
		master = wolfgang_master_postinit,
	},
	wx78 = {
		master = wx78_master_postinit,
	},
	wickerbottom = {
		master = wickerbottom_master_postinit,
	},
	wes = {
		master = wes_master_postinit,
	},
	waxwell = {
		master = maxwell_master_postinit,
	},
	woodie = {
		master = woodie_master_postinit,
	},
	wathgrithr = {
		master = wigfrid_master_postinit,
	},
	webber = {
		master = webber_master_postinit,
	},
	winona = {
		master = winona_master_postinit,
	},
	wortox = {
		master = wortox_master_postinit,
	},
	wormwood = {
		common = wormwood_common_postinit,
		master = wormwood_master_postinit,
	},
	warly = {
		master = warly_master_postinit,
	},
	wurt = {
		master = wurt_master_postinit,
	},
	walter = {
		master = walter_master_postinit,
	},
	wanda = {
		master = wanda_master_postinit,
	},
}
return character_postinits -- TODO create a function instead? for each thing? GetCommon, GetMaster???
