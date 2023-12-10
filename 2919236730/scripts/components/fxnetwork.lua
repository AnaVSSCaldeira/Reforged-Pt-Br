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
--[[
in current_players keep track of whether or not they have fx stuff turned off and use that to dictate if the player is part of the player list for the new fx.
on rejoin players should spawn any fx that is persistent?
	for now keep these server side?
		until this is figured out?
	amplify
	battlecry?
		how to get this to remove at the right time because animover would not work for it since the time would be different from when it started?
		possibly have a remove check sent to all clients?
			so 3 people and a 4th rejoins
			the 4th gets the fx which has 5 seconds left but has 10 for this player since they just got it
			the animover triggers and tells the server to remove it with a check that says it should be removed on all clients to which the server sends back to all clients telling them to remove it
		if players leave one at a time and rejoin then the animover timer will be wrong for all of them...
			but the server will still update them correctly so battlecry will still be removed at the right time. This will only apply to those fx that rely on animover and animover alone which typically are very quick fx that no one will notice.
Remove Event listeners for replica?
Is there a debug string for replicas?
	check health, combat???? ask ex?

for i,j in pairs(TheWorld.net.components.fxnetwork.tracker) do print(tostring(i) .. ": " .. tostring(j)) end
--]]
--------------------------------------------------------------------------
local function GetPlayers()
	local players = {}
	for _,player in pairs(GetPlayerClientTable()) do
		players[player.userid] = true
	end
	return players
end
--------------------------------------------------------------------------
local function OnSource(self, source)
	self.inst.replica.fxnetwork:SetSource(source)
end

local function OnTarget(self, target)
	self.inst.replica.fxnetwork:SetTarget(target)
end

local function OnFX(self, fx)
	self.inst.replica.fxnetwork:SetFX(fx)
end

local function OnName(self, name)
	self.inst.replica.fxnetwork:SetName(name)
end

local function OnRemoveFX(self, name)
	self.inst.replica.fxnetwork:QueueFXForRemoval(name)
end

local function OnPersistent(self, persistent)
	self.inst.replica.fxnetwork:SetPersistent(persistent)
end

-- Syncs all FX to the connected player.
local function OnClientConnected(inst, data)
    local fxnetwork = inst.components.fxnetwork
    -- Send client a list of FX that are going to be synced.
    local sync_fx = {}
    for name,_ in pairs(fxnetwork.tracker) do
    	sync_fx[name] = true
    end
    self.inst.replica.fxnetwork:SyncFX(SerializeTable(sync_fx))
    -- Sync each FX one at a time.
    for name,fx_info in pairs(fxnetwork.tracker) do -- TODO test this, does it need a delay?
    	self.inst.replica.fxnetwork:SyncFXName(name)
    	self.inst.replica.fxnetwork:SyncFXTarget(fx_info.target)
    	self.inst.replica.fxnetwork:SyncFXSource(fx_info.source)
    	self.inst.replica.fxnetwork:SyncFXPrefab(fx_info.prefab)
    end
end
--------------------------------------------------------------------------
local FXNetwork = Class(function(self, inst)
    self.inst = inst
    self.name = ""
    self.fx = ""
    self.remove_fx = ""
	self.tracker = {}
	self.persistent_fx_count = 0
	self.count = 0
	self.inst:ListenForEvent("ms_clientauthenticationcomplete", OnClientConnected)
end, nil, {
	source = OnSource,
	target = OnTarget,
	fx = OnFX,
	name = OnName,
	remove_fx = OnRemoveFX,
	persistent = OnPersistent,
})

function FXNetwork:GetValidName(name, count)
	if self.tracker[name .. (count and "_" .. tostring(count) or "")] then
		name = self:GetValidName(name, count and (count + 1) or 1)
	end
	return name
end

function FXNetwork:GetPlayerCount(players)
	local player_count = 0
	for i,player in pairs(players) do
		player_count = player_count + 1
	end
	return player_count
end

function FXNetwork:CreateFX(target, prefab, source, persistent, name)
	Debug:Print("Sending " .. tostring(prefab) .. " to clients...", "log")
	if PrefabExists(prefab) then
		print(" - success")
		local name = (name or prefab) .. "_" .. tostring(self.count)--persistent and self:GetValidName(name or prefab) or prefab
		if persistent then
			self.tracker[self.name] = {prefab = prefab, target = target}
			self.persistent_fx_count = self.persistent_fx_count + 1
		end
		self.persistent = persistent ~= nil
		self.source = source or target
		self.target = target
		self.fx = prefab
		self.name = name
		self.count = self.count + 1
		return self.name
	end
	return nil
end

-- Only use this when ALL players have removed the FX
function FXNetwork:RemoveFX(name)
	Debug:Print("Removing " .. tostring(name) .. "...", "log")
	if name and self.tracker[name] then
		print(" - removed")
		self.remove_fx = name
		self.tracker[name] = nil
		self.persistent_fx_count = self.persistent_fx_count - 1
	end
end

-- Removes the player from the given FX's tracker. If all players are removed from this tracker then the FX will be removed from the tracker.
function FXNetwork:RequestRemoveFX(name, userid)
	if name and self.tracker[name] then
		self.tracker[name][userid] = nil
		if self:GetPlayerCount(self.tracker[name]) <= 0 then
			self:RemoveFX(name)
		end
	end
end

function FXNetwork:OnRemoveFromEntity() -- TODO does the replica need this at all? since it has events?
	self.inst:RemoveEventCallback("ms_clientauthenticationcomplete", OnClientConnected)
	self.inst:RemoveEventCallback("ms_clientdisconnected", OnClientDisconnect)
end

function FXNetwork:GetDebugString()
    return string.format("Networked FX: %d", self.persistent_fx_count)
end

return FXNetwork
