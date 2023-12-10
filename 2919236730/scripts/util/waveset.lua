--[[
TODO
Organize functions so that similar functions are next to each other, maybe add sections like UTIL
Move UTIL functions somewhere else???

set all errors to use assert? forces crash? do we want it to crash from bad waves?

--]]
--------------------
-- Mob Spawn Util --
--------------------
-- Returns a formatted table of the given mob spawn info
local function MobSpawnSetup(prefab, spawn_ring, slot)
	return {prefab = prefab, spawn_ring = spawn_ring or 0, slot = slot or 1}
end

-- Returns a formatted table of the given spawn ring info
local function SpawnRingsSetup(dist_from_center, total_slots, rotation)
	return {dist_from_center = dist_from_center or 1, total_slots = total_slots or 1, rotation = rotation or 0}
end

-- Formats the given mob info into a spawn list and returns it
local function CreateSpawn(mob_list, rotation)
	local mobs = {}
	for i,mob_info in pairs(mob_list[1]) do -- mob_list[1] are the mobs
		table.insert(mobs, MobSpawnSetup(mob_info[1], mob_info[2], mob_info[3], mob_info[4]))
	end

	local options = {spawn_rings = {}}
	for i,spawn_ring_info in pairs(mob_list[2] or {}) do -- mob_list[2] are the spawn_rings
		table.insert(options.spawn_rings, SpawnRingsSetup(spawn_ring_info[1], spawn_ring_info[2], (spawn_ring_info[3] or 0) + (rotation or 0)))
	end

	return {mobs, options}
end

-- Returns a table of the spawns with the index being the desired spawner for that spawn
local function SetSpawn(...)
	local spawns = {}
	for i,spawn_info in pairs({...}) do
		for j,spawner in pairs(spawn_info[2]) do
			spawns[spawner] = spawn_info[1]
		end
		--[[ TODO need total_spawn_portals from global somehow to have default setting be all spawn portals
		local spawn_portals = spawn_info[2]
		for i = 1, #spawn_portals or total_spawn_portals, 1 do
			spawns[spawn_portals and spawn_portals[i] or i] = spawn_info[1]
		end
		--]]
	end
	return spawns
end

--	Combines seperate mob lists into one list (to be used in CreateSpawn)
local function CombineMobSpawns(...)
	local mob_list = {}
	local spawn_rings = {}
	local spawn_ring_count = 0
	for _,spawn_info in pairs({...})do
		-- Add Mobs
		for __,mob_info in pairs(spawn_info[1]) do -- spawn_info[1] are the mobs.
			-- update spawn ring index
			mob_info[2] = mob_info[2] and mob_info[2] ~= 0 and (mob_info[2] + spawn_ring_count) or 0
			table.insert(mob_list, mob_info)
		end

		-- Add Spawn Rings
		for __,spawn_ring_info in pairs(spawn_info[2] or {}) do -- spawn_info[2] are the spawn rings.
			table.insert(spawn_rings, spawn_ring_info)
			spawn_ring_count = spawn_ring_count + 1
		end
	end

	return {mob_list, spawn_rings}
end

--[[
Back
          1       1   2        2              3
                              1 3    213     214
          2         3          4      4       5
Front	Line	Triangle	Square	Flag	Cross
 --]]
local mob_spawn_presets = {
	line = {mob_spawns = {{1, 1},{1, 2}}, spawn_rings_slots = {2}, required_mob_count = 2},
	triangle = {mob_spawns = {{1, 1},{1, 2},{1, 3}}, spawn_rings_slots = {3}, required_mob_count = 3},
	square = {mob_spawns = {{1, 1},{1, 2},{1, 3},{1,4}}, spawn_rings_slots = {4}, required_mob_count = 4},
	flag = {mob_spawns = {{0, 1},{1, 1},{1, 3},{1, 4}}, spawn_rings_slots = {4}, required_mob_count = 4},
	cross = {mob_spawns = {{0,1},{1,1},{1,2},{1,3},{1,4}}, spawn_rings_slots = {4}, required_mob_count = 5},
	circle = {mob_spawns = {}, spawn_rings_slots = {}},
    random = {mob_spawns = {}, spawn_rings_slots = {}}, -- will randomly select a valid preset
}

-- Adds or replaces the given preset to the preset list
local function AddSpawnPreset(name, mob_spawns, spawn_rings_slots, required_mob_count)
    mob_spawn_presets[name] = {mob_spawns = mob_spawns, spawn_rings_slots = spawn_rings_slots, required_mob_count = required_mob_count}
end

--[[
Returns a mob list based on the chosen preset and the given mobs
options
    distance   - this is the distance from the center of the spawners
    rotation   - this rotates the entire preset
    must_equal - random will only select a preset that has the same max mob count as the give mob count
--]]
local function CreateMobSpawnFromPreset(preset, mobs, options)
    local options = options or {}
    if preset == "random" then
        local valid_presets = {}
        for pre,info in pairs(mob_spawn_presets) do
            local req_count = info.required_mob_count
            if req_count and (options.must_equal and req_count == #mobs or not options.must_equal and req_count >= #mobs) or req_count == nil and pre ~= "random" then
                table.insert(valid_presets, pre)
            end
        end
        preset = valid_presets[math.random(#valid_presets)] -- Note: circle will always be in this table so there will always be at least one table entry
    end
    local preset_info = deepcopy(mob_spawn_presets[preset])
	if preset == "circle" then
		preset_info.spawn_rings_slots = {}
		table.insert(preset_info.spawn_rings_slots, #mobs)
		preset_info.mob_spawns = {}
		for i=1,#mobs do
			table.insert(preset_info.mob_spawns, {1,i})
		end
		preset_info.required_mob_count = #mobs
	end
	if preset_info == nil then Debug:Print("(Waveset): " .. tostring(preset) .. " is not a valid preset.", "error") return {}
	elseif #mobs > preset_info.required_mob_count then Debug:Print("(Waveset): " .. tostring(preset) .. " Preset requires at most " .. tostring(preset_info.required_mob_count) .. " mobs, " .. tostring(#mobs) .. " were given.", "error")
        return {}
    end

	local distance = options.distance or 2
	local rotation = options.rotation or 0

	local mob_list = {}
	for i,mob in pairs(mobs) do
		local mob_spawns = {mob}
		TableConcat(mob_spawns, preset_info.mob_spawns[i])
		table.insert(mob_list, mob_spawns)
	end

	local spawn_rings = {}
	for i,spawn_ring_slot in pairs(preset_info.spawn_rings_slots) do
		table.insert(spawn_rings, {distance, spawn_ring_slot, rotation})
	end

	return {mob_list,spawn_rings}
end

-- Combines all of the mobs given into one table and returns the table. If a table is given with a list of mobs then that table will be appended.
local function CreateMobList(...)
	local mob_list = {}
	for i,j in pairs({...}) do
		if type(j) == "table" then
			if #mob_list == 0 then
				mob_list = j
			else
				TableConcat(mob_list, j)
			end
		else
			table.insert(mob_list, j)
		end
	end
	return mob_list
end

--------------
-- Mob Util --
--------------
-- Sorts the given mobs into a table based on their prefab
-- ex. mobs = {pitpig = {pitpig1,pitpig2}, crocommander = {croc1,croc2}}
-- Optional: Can give it a table of already sorted mobs to append to
--           Can choose to not sort mobs by type, sorts by mob type by default
local function OrganizeMobs(mob_list, mobs, is_sorted)
	local mobs = mobs or {}
	local is_sorted = is_sorted == nil or is_sorted
	for mob,_ in pairs(mob_list) do
		if mobs[mob.prefab] == nil then
			mobs[mob.prefab] = {}
		end
		table.insert(is_sorted and mobs[mob.prefab] or mobs, mob)
	end
	return mobs
end

-- Sorts the all the mobs in the give mob lists into a table based on their prefab
-- ex. mobs = {pitpig = {pitpig1,pitpig2}, crocommander = {croc1,croc2}}
-- Optional: Can choose to not sort mobs by type, sorts by mob type by default
local function OrganizeAllMobs(mob_lists, is_sorted)
	local mobs = {}
	local is_sorted = is_sorted == nil or is_sorted
	for _,mob_list in pairs(mob_lists) do
		OrganizeMobs(mob_list, mobs, is_sorted)
	end
	return mobs
end

-- Leashes the given followers to the given leader
local function LeashMobs(leader, followers)
    if not leader then return end
    local str = "{"
	for i,follower in pairs(followers or {}) do
		leader.components.leader:AddFollower(follower)
		str = str .. follower.prefab .. ","
	end
end

-- Checks if the given health triggers have been triggered
local function CheckHealthTriggers(health_triggers, OnHealthDelta, ...)
	local mobs = {...}
	local function RemoveHealthTriggers()
		for i,mob in pairs(mobs) do
			mob:RemoveEventCallback("healthdelta", OnHealthDelta)
		end
	end
	local health_trigger = health_triggers[1]
	-- Checking if no health triggers are left just in case TODO is this check needed?
	if not health_trigger then
		Debug:Print("Health Triggers were not removed!", "warning")
		RemoveHealthTriggers()
		return
	end
	local function ApplyHealthTrigger()
		health_trigger.fn()
		table.remove(health_triggers, 1)
		-- Stop checking health if all health triggers have been triggered
		if #health_triggers < 1 then
			RemoveHealthTriggers()
		-- Check the next trigger in the list just in case more than one trigger occurred at once
		else
			CheckHealthTriggers(health_triggers, OnHealthDelta, unpack(mobs))
		end
	end

	-- Check each mobs health
	local current_health_percent = 0
	local total_percent = #mobs
	local all_percent_triggered = health_trigger.all_percent or false
	for i,mob in pairs(mobs) do
		local mobs_health_percent = mob.components.health:GetPercent()
		current_health_percent = current_health_percent + mobs_health_percent
		-- Individual mob below a specific health trigger
		if health_trigger.single_percent and health_trigger.single_percent >= mobs_health_percent then
			ApplyHealthTrigger()
			return
		end
		-- All mobs below a specific health trigger
		if health_trigger.all_percent and health_trigger.all_percent < mobs_health_percent then
			all_percent_triggered = false
		end
	end
	-- Check triggers
	if all_percent_triggered or health_trigger.total_percent and health_trigger.total_percent >= current_health_percent then
		ApplyHealthTrigger()
	end
end

-- health_triggers:
--      - single_percent: triggers if one mobs health percent drops below it
--      - all_percent: triggers if all mobs health percent drop below it
--      - total_percent: triggers if mobs cumalitive health percent drops below it
local function AddHealthTriggers(health_triggers, ...)
	local mobs = {...}
	local function OnHealthDelta(inst, data)
		if data.amount < 0 then -- Do not need to check if they don't take damage or got healed.
			CheckHealthTriggers(health_triggers, OnHealthDelta, unpack(mobs))
		end
	end
	for _,mob in pairs(mobs) do
		mob:ListenForEvent("healthdelta", OnHealthDelta) -- NOTE: Health Regen triggers this
	end
end

--------------------
-- Item Drop Util --
--------------------
-- Returns an item from the list randomly. Each item has the same chance of being returned.
local function ChooseRandomItem(...)
    local items = {...}
    return items[math.random(#items)]
end

-- Spreads the given item set over the given waves.
-- waves format: {{round,wave},{round,wave},{round}}
--	  Giving no wave means round_end of the given round
-- Optional:
--    Can set the item set to drop on final mob of the wave or random. Default is random.
--    Can set a max amount of items allowed per wave. Default is no limit.
local function SpreadItemSetOverWaves(item_drops, item_set, waves, drop_type, max_per_wave, on_item_added_fn)
    local waves = deepcopy(waves) -- copy table so original table is not changed
    for count,item in pairs(item_set) do
        -- Add item to the item drop list
        local rand_wave_index = math.random(#waves)
        local round = waves[rand_wave_index][1]
        local wave = waves[rand_wave_index][2]
		if wave then
			table.insert(EnsureTable(item_drops, round, wave, drop_type), item)
		else
			table.insert(EnsureTable(item_drops, round, "round_end"), item)
		end

        -- Check max items per wave and remove wave from drop list if item limit reached
        if max_per_wave then
            waves[rand_wave_index].item_count = (waves[rand_wave_index].item_count or 0) + 1
            if waves[rand_wave_index].item_count >= max_per_wave then
                table.remove(waves, rand_wave_index)
            end
        end
        if on_item_added_fn then -- TODO sort of hacky
            on_item_added_fn(item_set, waves, count)
        end
        --print("Adding " .. tostring(item) .. " to Round " .. tostring(round) .. " Wave " .. tostring(wave))
    end
end

-- Add drops to the item set of the given round. Useful for adding sets of weapons to preexisting item sets.
-- If no wave or type is given then it defaults to adding the given items to the end of the given round.
local function AddItemsToItemSet(items, item_drops, round, wave, type)
    local item_loc = wave and type and EnsureTable(item_drops, round, wave, type) or EnsureTable(item_drops, round, "round_end")
    for _,item in pairs(items) do
        table.insert(item_loc, item)
    end
end

-- Returns all character based item drops for the active players.
-- Can set character item by adding "inst.custom_items" to the characters prefab.
-- ex:
-- inst.reforged_items = {[1] = {"moltendarts"}, [2] = {"infernalstaff"}, [3] = {"spiralspear"}}}
-- Most wavesets only support up to 3 tiers. 3rd tier items usually have special abilities like spiral spear and blacksmiths edge.
local function GetCharacterItemDrops()
    local items = {}
    local item_dupe_check = {}
    for _,player in pairs(AllPlayers) do
        for tier,player_items in pairs(player.reforged_items or {}) do
        	if not items[tier] then
        		items[tier] = {}
        	end
            for __,item in pairs(player_items) do
            	if not item_dupe_check[item] then
            		item_dupe_check[item] = true
                	table.insert(items[tier], item)
                end
            end
        end
    end
    return items
end

-- Adds all active character based items to the given item set.
-- tier_opts = {[1] = {round = 1, wave = 1, type = "random", force_items = {"moltendarts"}}}
local function AddCharacterItemDropsToItemSet(item_drops, tier_opts)
	local character_items = GetCharacterItemDrops()
	for tier,item_info in pairs(character_items) do
		local current_tier = tier_opts[tier]
		if current_tier then
			AddItemsToItemSet(item_info, item_drops, current_tier.round, current_tier.wave, current_tier.type)
		end
	end
	-- Add "force_items" if no character items were added to the tier
	for tier,tier_info in pairs(tier_opts) do
		if not character_items[tier] and tier_info.force_items then
			AddItemsToItemSet(tier_info.force_items, item_drops, tier_info.round, tier_info.wave, tier_info.type)
		end
	end
end

local function DupeItems(items, amount, tab)
    for i,item in pairs(items) do
    	-- Check for mob specific drop
    	if type(item) == "table" then
    		DupeItems(item, amount, tab[i])
    	else
        	for i=1,(amount - 1) do -- Only duplicate when amount > 1 and don't duplicate an extra time
            	table.insert(tab, item)
        	end
        end
    end
end
local function GenerateItemDropList(item_drops, character_tier_opts, heal_opts, random_item_spread_fn)
    local dupe_val = _G.REFORGED_SETTINGS.gameplay.mutators.mob_duplicator
    local old_item_drops = deepcopy(item_drops)
    -- Duplicate Original Items
    for round,round_data in pairs(old_item_drops) do
        for wave,wave_data in pairs(round_data) do
            if wave == "round_end" then
                DupeItems(wave_data, dupe_val, item_drops[round][wave])
            else
                for type,drops in pairs(wave_data) do
                    DupeItems(drops, dupe_val, item_drops[round][wave][type])
                end
            end
        end
    end
    for i=1,dupe_val do
        -- Add Character Items
        if character_tier_opts then
            AddCharacterItemDropsToItemSet(item_drops, character_tier_opts)
        end
        -- Add Random Item Spread
        if random_item_spread_fn then
            random_item_spread_fn(item_drops)
        end
    end
    -- Add Healing Items
    if heal_opts then
        for i=1,(math.floor(dupe_val*(heal_opts.dupe_rate or 0))+1) do
            AddCharacterItemDropsToItemSet(item_drops, heal_opts.drops)
        end
    end
end

------------------
-- Waveset Util --
------------------
local default_banners = {"battlestandard_heal", "battlestandard_damager", "battlestandard_shield"}
local defaultbanner = function()
	return default_banners[math.random(1, #default_banners)]
end

-- defaults each item in defaultwavemanager individually
local defaultwavemanager = {
    onenter = function(self)
        self:QueueWave(1)
    end,
    onallmobsdied = function(self)
        if self.current_wave + 1 <= #self.current_round_data.waves and not self:AreWavesSpawning() then
            self:QueueWave(self.current_wave + 1)
            return false
        end
        return true
    end,
	ondisable = function(self)
		for _,timer in pairs(self.timers) do
			RemoveTask(timer)
		end
	end,
}

-- roundend is set to this if not specified for the round
local function defaultroundend(self)
	KillAll("battlestandard")
end

return {
	-- Mob Spawn Util
	CreateMobList = CreateMobList,
	AddSpawnPreset = AddSpawnPreset,
	CreateMobSpawnFromPreset = CreateMobSpawnFromPreset,
	CombineMobSpawns = CombineMobSpawns,
	CreateSpawn = CreateSpawn,
	SetSpawn = SetSpawn,
	RepeatMob = RepeatItem,
	-- Mob Util
	OrganizeMobs = OrganizeMobs,
	OrganizeAllMobs = OrganizeAllMobs,
	LeashMobs = LeashMobs,
	AddHealthTriggers = AddHealthTriggers,
	-- Item Drop Util
	ChooseRandomItem = ChooseRandomItem,
	SpreadItemSetOverWaves = SpreadItemSetOverWaves,
	AddItemsToItemSet = AddItemsToItemSet,
	GetCharacterItemDrops = GetCharacterItemDrops,
	AddCharacterItemDropsToItemSet = AddCharacterItemDropsToItemSet,
    GenerateItemDropList = GenerateItemDropList,
	-- Waveset Util
	defaultbanner = defaultbanner,
	default_banners = default_banners,
	defaultwavemanager = defaultwavemanager,
	defaultroundend = defaultroundend,
}
