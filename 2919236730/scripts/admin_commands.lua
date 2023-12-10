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
local function SendCommand(fnstr)
	local x, _, z = TheSim:ProjectScreenPos(TheSim:GetPosition())
	local is_valid_time_to_use_remote = TheNet:GetIsClient() and TheNet:GetIsServerAdmin()
	if is_valid_time_to_use_remote then
		TheNet:SendRemoteExecute(fnstr, x, z)
	else
		ExecuteConsoleCommand(fnstr)
	end
end
--[[
local x,y,z = ThePlayer.Transform:GetWorldPosition() local ents = TheSim:FindEntities(x,y,z, 9001) for k,v in pairs(ents) do if (v.components and v.components.health and not v:HasTag("player") and not v:HasTag("companion")) then v.components.health:Kill() end end

local x,y,z = ThePlayer.Transform:GetWorldPosition() local ents = TheSim:FindEntities(x,y,z, 9001) for k,v in pairs(ents) do print("1") end

]]
local admin_print = "AdminCommand"
-- All entities are spawned at the players feet
function SpawnEntity(prefab_name, amount, player, is_pet)
	if player then
		Debug:Print("Spawning " .. tostring(amount) .. " " .. tostring(prefab_name), "log", admin_print)
		local fnstr = string.format("local amount = " .. amount .. " or 1 local player = UserToPlayer(\"" .. player.userid .. "\") or ThePlayer")
		if is_pet then
			fnstr = fnstr .. string.format(" COMMON_FNS.SpawnPet(\"" .. prefab_name .. "\", amount, player)")
		else
			fnstr = fnstr .. string.format(" for i = 1, amount, 1 do SpawnPrefab(\"" .. prefab_name .. "\").Transform:SetPosition(player.Transform:GetWorldPosition()) end")
		end
		local speech = string.format(STRINGS.REFORGED.ADMIN_COMMANDS.SPAWNING_ENT, amount, prefab_name)
		fnstr = fnstr .. " player.components.talker:Say(\"" .. speech .. "\")"

		SendCommand(fnstr)
	end
end

--------------
-- Passives --
--------------
-- Triggers BattleCry for the given player as if they had the battlecry passive.
function ActivateBattleCry(player)
	if player then
		Debug:Print("Activating battlecry for " .. tostring(player.userid), "log", admin_print)
		local fnstr = string.format("local player = UserToPlayer(\"" .. player.userid .. "\") or ThePlayer if not player.components.passive_battlecry then player:AddComponent(\"passive_battlecry\") local _oldResetBattleCry = player.components.passive_battlecry.ResetBattleCry player.components.passive_battlecry.ResetBattleCry = function() _oldResetBattleCry(player.components.passive_battlecry) player:RemoveComponent(\"passive_battlecry\") end end player.components.passive_battlecry:ApplyBattleCry() player.components.talker:Say(STRINGS.REFORGED.ADMIN_COMMANDS.ACTIVATING_BATTLECRY)")

		SendCommand(fnstr)
	end
end

-- Gives the BattleCry buff to the given player
function GiveBattleCry(player)
	if player then
		Debug:Print("Giving battlecry to " .. tostring(player.userid), "log", admin_print)
		local fnstr = string.format("local player = UserToPlayer(\"" .. player.userid .. "\") or ThePlayer if not player.components.passive_battlecry then player:AddComponent(\"passive_battlecry\") local _oldResetBattleCry = player.components.passive_battlecry.ResetBattleCry player.components.passive_battlecry.ResetBattleCry = function() _oldResetBattleCry(player.components.passive_battlecry) player:RemoveComponent(\"passive_battlecry\") end end local battlecry = player.components.passive_battlecry battlecry:ApplyBattleCryToTarget(player, true) battlecry.battle_cry = true player.components.talker:Say(STRINGS.REFORGED.ADMIN_COMMANDS.GIVING_BATTLECRY)")

		SendCommand(fnstr)
	end
end

-- Triggers Amplify for the given player as if they had the Amplify passive.
function ActivateAmplify(player)
	if player then
		Debug:Print("Activating Amplify for " .. tostring(player.userid), "log", admin_print)
		local fnstr = string.format("local player = UserToPlayer(\"" .. player.userid .. "\") or ThePlayer if not player.components.passive_amplify then player:AddComponent(\"passive_amplify\") local passive_amplify = player.components.passive_amplify local _oldRemoveAmplify = passive_amplify.RemoveAmplify passive_amplify.RemoveAmplify = function() _oldRemoveAmplify(passive_amplify) player:RemoveComponent(\"passive_amplify\") end end player.components.passive_amplify:ApplyAmplify() player.components.talker:Say(STRINGS.REFORGED.ADMIN_COMMANDS.AMPLIFY)")

		SendCommand(fnstr)
	end
end

-- Triggers Mighty for the given player as if they had the Mighty passive.
function ActivateMighty(player)
	if player then
		Debug:Print("Activating Mighty for " .. tostring(player.userid), "log", admin_print)
		local fnstr = string.format("local player = UserToPlayer(\"" .. player.userid .. "\") or ThePlayer if not player.components.passive_mighty then player:AddComponent(\"passive_mighty\") local passive_mighty = player.components.passive_mighty local _oldApplyMightiness = passive_mighty.ApplyMightiness passive_mighty.ApplyMightiness = function() _oldApplyMightiness(passive_mighty) if passive_mighty.current_strength == passive_mighty.normal_strength then player:RemoveComponent(\"passive_mighty\") end end passive_mighty.ignore_skins = true end player.components.passive_mighty:UpdateMightiness(player.components.passive_mighty.normal_strength + 1) player.components.talker:Say(STRINGS.REFORGED.ADMIN_COMMANDS.MIGHTY)")

		SendCommand(fnstr)
	end
end

-- Triggers Shadows for the given player as if they had the Shadow passive.
function ActivateShadows(player)
	if player then
		Debug:Print("Activating Shadows for " .. tostring(player.userid), "log", admin_print)
		local fnstr = string.format("local player = UserToPlayer(\"" .. player.userid .. "\") or ThePlayer if not player.components.passive_shadows then player:AddComponent(\"passive_shadows\") local passive_shadows = player.components.passive_shadows local _oldApplyShadows = passive_shadows.ApplyShadows passive_shadows.ApplyShadows = function() _oldApplyShadows(passive_shadows) player:RemoveComponent(\"passive_shadows\") end passive_shadows.OnDamageDealt = function(inst, target, damage) passive_shadows.current_target = target passive_shadows:ApplyShadows() end else player.components.passive_shadows:ApplyShadows() end player.components.talker:Say(STRINGS.REFORGED.ADMIN_COMMANDS.SHADOWS)")

		SendCommand(fnstr)
	end
end

-- Triggers Shock for the given player as if they had the Shadow passive.
function ActivateShock(player)
	if player then
		Debug:Print("Activating Shock for " .. tostring(player.userid), "log", admin_print)
		local fnstr = string.format("local player = UserToPlayer(\"" .. player.userid .. "\") or ThePlayer if not player.components.passive_shock then player:AddComponent(\"passive_shock\") local passive_shock = player.components.passive_shock local _oldRemoveShock = passive_shock.RemoveShock passive_shock.RemoveShock = function() _oldRemoveShock(passive_shock) player:RemoveComponent(\"passive_shock\") end end player.components.passive_shock.hit_count = player.components.passive_shock.hit_count_trigger player.components.talker:Say(STRINGS.REFORGED.ADMIN_COMMANDS.SHOCK)")

		SendCommand(fnstr)
	end
end

---------------------
-- Player Commands --
---------------------
-- TODO: Check for item and not enemy?
function EquipItem(prefab_name, player)
	Debug:Print("Equipping " .. tostring(prefab_name), "log", admin_print)
	local fnstr = "local player = UserToPlayer(\"" .. player.userid .. "\") or ThePlayer local player_inv = player.components.inventory local item = SpawnPrefab(\"" .. prefab_name .. "\") local slot = item.components.equippable.equipslot local old_item = player_inv:GetEquippedItem(slot) player_inv:RemoveItem(old_item, true) if old_item then old_item:Remove() end player_inv:Equip(item)"
	local speech = string.format(STRINGS.REFORGED.ADMIN_COMMANDS.EQUIPPING_ITEM, prefab_name)
	fnstr = fnstr .. " player.components.talker:Say(\"" .. speech .. "\")"
	SendCommand(fnstr)
end

function SuperGodMode(player)
	local fnstr = "local player = UserToPlayer(\"" .. player.userid .. "\") or ThePlayer c_supergodmode(player) player.components.talker:Say(STRINGS.REFORGED.ADMIN_COMMANDS[player.components.health.invincible and \"SUPER_GOD_MODE\" or \"MORTAL_MODE\"])"
	SendCommand(fnstr)
end

function ChangeCharacter(player) -- TODO need to fully implement this command
	SendCommand("c_despawn(UserToPlayer(\"" .. player.userid .. "\")) ")
end

-- Spawns a petrification circle around the player
function SpawnPetrifyCircle(self, player)
	Debug:Print("Petrifying mobs near " .. tostring(player.name), "log", admin_print)
	local fnstr = "local player = UserToPlayer(\"" .. player.userid .. "\") for _, comp in ipairs({\"reticule_spawner\", \"fossilizer\"}) do if player.components[comp] == nil then player:AddComponent(comp) end player:DoTaskInTime(2.55, player.RemoveComponent, comp) end player.components.reticule_spawner:Setup(\"aoecctarget\", 3) player.components.fossilizer:SetRange(TUNING.FORGE.PETRIFYINGTOME.ALT_RADIUS)	player.components.fossilizer:Fossilize(player:GetPosition(), player) player.components.talker:Say(STRINGS.REFORGED.ADMIN_COMMANDS.PETRIFY)"

	SendCommand(fnstr)
end

-- toggles damage override on call
function Over9000(player)
	Debug:Print("His power level is over 9000!!!!!!!!", "log", admin_print)
	local fnstr = "local player = UserToPlayer(\"" .. player.userid .. "\") if player.components.combat:HasDamageBuff(\"over_9000\") then player.components.combat:RemoveDamageBuff(\"over_9000\") print(\"Removed over_9000 damage buff from " .. player.userid .. "\") player.components.talker:Say(STRINGS.REFORGED.ADMIN_COMMANDS.UNDER_9000) else player.components.combat:AddDamageBuff(\"over_9000\", {buff = 9001, addtype = \"flat\"}) print(\"Added over_9000 damage buff from " .. player.userid .. "\") player.components.talker:Say(STRINGS.REFORGED.ADMIN_COMMANDS.OVER_9000) end"

	SendCommand(fnstr)
end

-- Revives the current player if they are dead
function RevivePlayer(player)
	Debug:Print("Reviving " .. tostring(player.userid) .. ".", "log", admin_print)
	SendCommand("local player = UserToPlayer(\"" .. player.userid .. "\") if player.components.health:IsDead() then player.components.revivablecorpse:Revive(player) player.components.health:SetPercent(1, nil, \"admin_revive\") end player.components.talker:Say(STRINGS.REFORGED.ADMIN_COMMANDS.REVIVE)")
end

-- toggles damage override on call
function NoCoolDown(player)
	Debug:Print("Patience is for losers.", "log", admin_print)
	local fnstr = "local player = UserToPlayer(\"" .. player.userid .. "\") if player.components.buffable:HasBuff(\"no_cooldown\") then player.components.buffable:RemoveBuff(\"no_cooldown\") print(\"Removed cooldown buff from " .. player.userid .. "\") player.components.talker:Say(\"Patience is a virtue\") else player.components.buffable:AddBuff(\"no_cooldown\", {{name = \"cooldown\", val = 0, type = \"mult\"}}) print(\"Added no cooldown buff from " .. player.userid .. "\") player.components.talker:Say(\"Patience is for losers!\") end"

	SendCommand(fnstr)
end
------------------
-- Wave Manager --
------------------
-- TODO: Check for valid waves
function SelectRoundAndWave(round, wave)
	local round = round or 1
	local wave = wave or 1

	if TheWorld then
		Debug:Print("Starting Round: " .. tostring(round) .. ", Wave: " .. tostring(wave), "log", admin_print)
		local fnstr = "TheWorld.components.lavaarenaevent:StartRound(" .. round .. ", " .. wave .. ", true)"
		local speech = "REFORGED.ADMIN_COMMANDS.ROUND_AND_WAVE_SELECT"
		local par = SerializeTable({round, wave})
		fnstr = fnstr .. " local admin_talker = TheWorld.net:GetAdminTalker() if admin_talker then admin_talker.components.talker:Chatter(\"" .. speech .. "\", 0, 4, nil, " .. par .. ") end"
		SendCommand(fnstr)
	end
end

-- TODO ???
-- Despawn everything on the ground and all enemies
-- Reequip everyone with default equipment
-- Give full health to everyone
-- Reposition all players
-- can I just use the reload?
function RestartForge()
	SendCommand("TheNet:SendWorldResetRequestToServer()")
end

-- TODO ???
-- Despawn all enemies
-- Despawn new items? is there a way to know what is from that wave?
-- Dont need parameter for num since you are just restarting the current round
function RestartCurrentWave()
	local current_round = TheWorld.components.lavaarenaevent.current_round
	Debug:Print("Restarting Round " .. tostring(current_round), "log", admin_print)
	local speech = REFORGED.ADMIN_COMMANDS.RESTART_ROUND
	local par = SerializeTable({current_round})
	SendCommand("TheWorld.components.lavaarenaevent:ForceRestartCurrentRound() local admin_talker = TheWorld.net:GetAdminTalker() if admin_talker then admin_talker.components.talker:Chatter(\"" .. speech .. "\", 0, 4, nil, " .. par .. ") end")
end

-- TODO end the match without any victory or defeat?
-- Immediatley ends the current forge match in failure
function EndForge()
	Debug:Print("Ending Forge and returning to lobby screen.", "log", admin_print)
	SendCommand("TheWorld.components.lavaarenaevent:End(false)")
end

-- TODO: make ToggleWaves instead?
function DisableWaves()
	Debug:Print("Forge is now disabled!", "log", admin_print)
	SendCommand("TheWorld.components.lavaarenaevent:Disable() local admin_talker = TheWorld.net:GetAdminTalker() if admin_talker then admin_talker.components.talker:Chatter(\"REFORGED.ADMIN_COMMANDS.DISABLE_WAVES\", 0, 4) end")
end

function EnableWaves()
	Debug:Print("Forge is now enabled!", "log", admin_print)
	SendCommand("TheWorld.components.lavaarenaevent:Enable() local admin_talker = TheWorld.net:GetAdminTalker() if admin_talker then admin_talker.components.talker:Chatter(\"REFORGED.ADMIN_COMMANDS.ENABLE_WAVES\", 0, 4) end")
end

-------------------
-- Miscellaneous --
-------------------
function DebugSelect(player)
	SendCommand("c_select(UserToPlayer(\"" .. player.userid .. "\"))")
end

function ResetToSave()
	SendCommand("c_reset()")
end

function KillAllMobs()
	Debug:Print("Killing all mobs...", "log", admin_print)
	local fnstr = "local x,y,z = ThePlayer.Transform:GetWorldPosition() local ents = TheSim:FindEntities(x,y,z, 9001) for k,v in pairs(ents) do if v.components and v.components.health and not v:HasTag(\"player\") and not v:HasTag(\"companion\") then v.components.health:Kill() print(\"- \" .. tostring((v.nameoverride ~= nil and STRINGS.NAMES[string.upper(v.nameoverride)]) or v.name) .. \" killed\") end end local admin_talker = TheWorld.net:GetAdminTalker() if admin_talker then admin_talker.components.talker:Chatter(\"REFORGED.ADMIN_COMMANDS.KILL_ALL_MOBS\", 0, 4) end"
	SendCommand(fnstr)
end

-- Spawns a scorpeon projectile at the location of the given player
function SpawnPoison(player) --ToDo: Make this acid --Leo
	Debug:Print("Spawning Poison.", "log", admin_print)
	SendCommand("local player = UserToPlayer(\"" .. player.userid .. "\") SpawnAt(\"scorpeon_projectile\", player).components.complexprojectile:Launch(player:GetPosition(), player) player.components.talker:Say(STRINGS.REFORGED.ADMIN_COMMANDS.POISON)")
end

function UpdateMutator(mutator, val)
	Debug:Print("Updating Mutators.", "log", admin_print)
	local mutator_str = STRINGS.REFORGED.MUTATORS[mutator] and ("REFORGED.MUTATORS." .. mutator .. ".name") or tostring(mutator)
	local speech = "REFORGED.ADMIN_COMMANDS.ADJUST_MUTATOR"
	local par = SerializeTable({mutator_str, val})
	SendCommand("TheWorld.net.components.mutatormanager:UpdateMutators({" .. tostring(mutator) .. " = " .. tostring(val) .. "}) local admin_talker = TheWorld.net:GetAdminTalker() if admin_talker then admin_talker.components.talker:Chatter(\"" .. speech .. "\", 0, 4, nil, " .. par .. ") end")
end
