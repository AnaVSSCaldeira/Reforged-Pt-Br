local number_values = {round = true, time = true, total_deaths = true}
local string_exclusions = {["false"] = true, ["nil"] = true}
-- Parses the data from the given file and adds the valid runs to the list
local function GetRunsFromFile(self, filename)
    local run_count = {total = 0, valid = 0, invalid = 0, duplicate = 0}
    TheSim:GetPersistentString(filename, function(load_success, data)
        if load_success and data ~= nil then
            local forge_data = ParseString(data, "\n")
            local current_run = {}
            current_run.mutators = {}
            current_run.players_stats = {}
            local duplicate_run = false
            local invalid_run = false
            local random_characters = true
            local unique_characters = true
            local character_index = 3
            local death_index = 1
            local total_deaths = 0
            local current_characters = {}
            local fields = {}
            local mutator_fields = {}
            for i,j in pairs(forge_data) do
                local line_data = ParseString(j, ",")
                --[[print("index: " .. tostring(i))
                for l,m in pairs(line_data) do
                    print(tostring(l) .. ": " .. tostring(m))
                end--]]

                if line_data[1] == "endofmatch" then
                    if current_run.total_deaths == nil then
                        current_run.total_deaths = total_deaths
                    end
                    current_run.random_team = random_characters
                    current_run.unique_team = unique_characters
                    -- Add valid runs
                    if not invalid_run then
                        table.insert(self.loaded_runs, current_run)
                        run_count.valid = run_count.valid + 1
                    else
                        run_count.invalid = run_count.invalid + (invalid_run and 1 or 0)
                    end
                    run_count.total = run_count.total + 1

                    -- reset
                    current_run = {}
                    current_run.mutators = {}
                    current_run.players_stats = {}
                    invalid_run = false
                    random_characters = true
                    unique_characters = true
                    current_characters = {}
                    total_deaths = 0
                    fields = {}
                elseif #fields > 0 then
                    invalid_run = #fields ~= #line_data
                    local player_stats = {}
                    -- Make the index be the stat name
                    for index,stat in pairs(fields) do
                        local val = line_data[index]
                        player_stats[stat] = val == "true" and true or not string_exclusions[val] and val ~= "false" and val or false
                        if stat == "character" then
                            unique_characters = unique_characters and not current_characters[val]
                            current_characters[val] = current_characters[val]
                        elseif stat == "random_character" then
                            random_characters = random_characters and stat == "true"
                        elseif stat == "deaths" and current_run.total_deaths == nil then
                            total_deaths = total_deaths + tonumber(val)
                        end
                    end
                    table.insert(current_run.players_stats, player_stats)
                elseif #mutator_fields > 0 then
                    current_run.mutators = {}
                    -- Make the index be the mutator name
                    for index,mutator in pairs(mutator_fields) do
                        current_run.mutators[mutator] = line_data[index]
                    end
                    mutator_fields = {}
                elseif line_data[1] == "fields" then
                    fields = line_data
                elseif line_data[1] == "mutators" then
                    mutator_fields = line_data
                elseif line_data[1] == "client_date" or line_data[1] == "server_date" then
                    current_run["date_time"] = line_data[2]
                elseif number_values[line_data[1]] then
                    current_run[line_data[1]] = tonumber(line_data[2])
                elseif line_data[1] ~= nil then
                    current_run[line_data[1]] = line_data[2] == "true" and true or not string_exclusions[line_data[2]] and line_data[2] or false
                end
            end
        end
    end)
    return run_count
end

-- Attempts to get all runs from within the given date range.
local function GetFilesFromDateRange(self, filename, start_date, end_date)
    local max_days_per_month = 31
    local months_per_year = 12
    local current_date = start_date

    -- Loop through each date
    local file_count = 0
    local run_count = {total = 0, valid = 0, invalid = 0, duplicate = 0}
    local complete = false
    while not complete do
        --print(string.format("%02d-%02d-%02d.csv", current_date.month, current_date.day, current_date.year))
        local current_run_count = GetRunsFromFile(self, string.format("%s%02d-%02d-%02d.csv", filename, current_date.month, current_date.day, current_date.year))
        if current_run_count.total > 0 then
            run_count.total = run_count.total + current_run_count.total
            run_count.valid = run_count.valid + current_run_count.valid
            run_count.invalid = run_count.invalid + current_run_count.invalid
            run_count.duplicate = run_count.duplicate + current_run_count.duplicate
            file_count = file_count + 1
        end

        -- Check if looped through every date
        if current_date.day == end_date.day and current_date.month == end_date.month and current_date.year == end_date.year then
            complete = true
        -- Update date values
        elseif current_date.day == max_days_per_month then
            current_date.day = 1
            if current_date.month == months_per_year then
                current_date.month = 1
                current_date.year = current_date.year + 1
            else
                current_date.month = current_date.month + 1
            end
        else
            current_date.day = current_date.day + 1
        end
    end
    print("- " .. tostring(file_count) .. " files found.")
    print("- " .. tostring(run_count.total) .. " total runs found.")
    print("-- " .. tostring(run_count.valid) .. " valid runs, " .. tostring(run_count.invalid) .. " invalid runs, " .. tostring(run_count.duplicate) .. " duplicate runs found")
end
--[[
local function OnLoadedRunStr(self, loaded_run_str)
    self.inst.replica.leaderboardmanager:SetLoadedRunStr(loaded_run_str)
end--]]

local function OnLoadedRunsStr(self, loaded_runs_str)
    self.inst.replica.leaderboardmanager:SetLoadedRunsStr(loaded_runs_str)
end

local LeaderboardManager = Class(function(self, inst)
    self.inst = inst
    self.loaded_runs = {}
    --self.loaded_run_str = ""
    self.loaded_runs_str = ""

    self:Initialize()
end, nil, {
    --loaded_run_str = OnLoadedRunStr,
    loaded_runs_str = OnLoadedRunsStr,
})

function LeaderboardManager:Initialize()
    local current_date = os.date("*t")
    -- Load ReForged Runs
    Debug:Print("Loading ReForged Runs...", "log")
    GetFilesFromDateRange(self, "event_match_stats\\reforged_stats_server_", {day = 1, month = 11, year = 19}, {day = current_date.day, month = current_date.month, year = tonumber(string.sub(current_date.year,-2))}) -- Check from start date to current date
    --PrintTable(self.loaded_runs)
    if #self.loaded_runs > 0 then
        -- Test 1
        self.loaded_runs_str = SerializeTable(self.loaded_runs)

        -- Test 2
        --for i,run in pairs(self.loaded_runs) do
            --print("Run " .. tostring(i))
            --self.inst:DoTaskInTime((i-1)*5*FRAMES, function()
                --print("Adding run " .. tostring(i))
                --self.loaded_run_str = SerializeTable(run)
            --end)
        --end

        -- Test 3
        --self.last_update_time = GetTimeRealSeconds()
        --self.next_update_time = self.last_update_time
        --self.inst:StartWallUpdatingComponent(self)
    end
end

local last_tick_seen = -1
local current_tick = 0
local current_run_index = 0
-- TODO dt seems to always be 0, would be nice to only do the checks every second instead of every update?
function LeaderboardManager:OnWallUpdate(dt)
    self.last_update_time = GetTimeRealSeconds()
    Debug:Print("Last Update: " .. tostring(self.last_update_time), "log")
    if #self.loaded_runs > current_run_index and self.next_update_time <= self.last_update_time then
        --local time = self.timeout - (GetTimeRealSeconds() - self.vote_start_time)
        -- Check Loading Clients and update their display once they finish loading if they are part of the current vote.
        self.next_update_time = self.last_update_time + 2
        current_run_index = current_run_index + 1
        Debug:Print("Adding run " .. tostring(current_run_index), "log")
        self.loaded_run_str = SerializeTable(self.loaded_runs[current_run_index])
    elseif not (#self.loaded_runs > current_run_index) then
        self.inst:StopWallUpdatingComponent(self)
        current_run_index = 0
    end
end

return LeaderboardManager
