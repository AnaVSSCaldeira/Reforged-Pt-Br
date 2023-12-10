local events = {
    EventHandler("spawnlamobs", function(inst, data)
        inst:DoTaskInTime(data.delay - FRAMES*38, function(inst)
            inst.sg:GoToState("prespawnfx", data)
        end)
    end),
}

local DECOR_RADIUS = 3.3
local NUM_DECOR = 6

local function GetDecorPos(index)
    local angle = 240 * DEGREES
    local start_angle = -.5 * angle
    local delta_angle = angle / (NUM_DECOR - 1)
    return DECOR_RADIUS * math.sin(start_angle + index * delta_angle),
        0,
        -DECOR_RADIUS * math.cos(start_angle + index * delta_angle)
end

local function SpawnDecorFX(inst, index)
    local fx = SpawnPrefab("lavaarena_spawnerdecor_fx_"..tostring(math.random(3)))
    local x, y, z = GetDecorPos(index)
    fx.Transform:SetPosition(x, y, z)
    fx.entity:SetParent(inst.entity)
end

local states = {
    State{
        name = "idle",
        tags = {"idle"},
    },

    State{
        name = "prespawnfx",
        tags = {"busy", "prefx"},

        onenter = function(inst, data)
            inst.sg.statemem.spawns = data

            if not (type(data.mobs) ~= "table" or #data.mobs == 0) then -- TODO why? what is this?
                for i = 0, NUM_DECOR-1 do
                    local fx = SpawnPrefab("lavaarena_spawnerdecor_fx_small")
                    local x, y, z = GetDecorPos(i)
                    fx.Transform:SetPosition(x, y, z)
                    fx.entity:SetParent(inst.entity)
                end
            end

            inst.sg:SetTimeout(FRAMES * 38)
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("spawn", inst.sg.statemem.spawns)
        end
    },

    State{
        name = "spawn",
        tags = {"busy", "spawning"},

        onenter = function(inst, data)
			-- Check if there are mobs to spawn
			if data.mobs then
				-- TODO move these
				local DEFAULT = {
					DIST_FROM_CENTER = 2,
					TOTAL_SLOTS = 1,
					ROTATION = 1,
					ATTEMPTS_TO_FIND_SPAWN = 2,
				}

				local spawn_rings = data.options and data.options.spawn_rings or {{dist_from_center = DEFAULT.DIST_FROM_CENTER, total_slots = DEFAULT.TOTAL_SLOTS}}
				local rotation = data.options and data.options.rotation or DEFAULT.ROTATION -- TODO add it to spawn_rings? so each ring can be rotated?

				TheWorld.components.forgemobtracker:SetSpawnPortal(inst:GetSpawnPortalID())
				local current_count = {}
				-- Calculate Mobs Spawn Positions
				for i,mob_info in pairs(data.mobs) do
					-- Update count
					current_count[mob_info.spawn_ring] = (current_count[mob_info.spawn_ring] or 0) + 1

					-- Get position of mob at spawner in given slot
					local spawner_pos = inst:GetPosition()
					local spawner_rotation = inst.Transform:GetRotation()
					local spawner_rotation_offset = spawner_rotation % 360 - 90
					local current_spawn_ring = spawn_rings[mob_info.spawn_ring or 1] or {}
					local slot = mob_info.slot or current_count[mob_info.spawn_ring or 1]
					local total_slots = current_spawn_ring.total_slots or DEFAULT.TOTAL_SLOTS
					local rotation = current_spawn_ring.rotation or 0
					local dist_from_center = current_spawn_ring.dist_from_center or DEFAULT.DIST_FROM_CENTER
					local offset = mob_info.spawn_ring ~= 0 and FindWalkableOffset(spawner_pos, ((slot/total_slots * 360 + spawner_rotation_offset + rotation) * PI / 180), dist_from_center, DEFAULT.ATTEMPTS_TO_FIND_SPAWN, true, true) or {x = 0, y= 0, z = 0}
                    local mob = COMMON_FNS.SpawnMob(mob_info.prefab, spawner_pos + offset, data.round, data.wave, inst.spawnerid)
				end

				-- Spawn FX
				if #data.mobs > 1 then
					SpawnPrefab("lavaarena_creature_teleport_medium_fx").Transform:SetPosition(inst.Transform:GetWorldPosition())
				else
					SpawnPrefab("lavaarena_creature_teleport_small_fx").Transform:SetPosition(inst.Transform:GetWorldPosition())
				end

				inst.sg:SetTimeout(FRAMES * 30)
				TheWorld.components.lavaarenaevent:SpawnFinishedForPortal()
			-- Nothing to Spawn
			else
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            local postfxstate = GetRandomItem(inst.postfxstates)
            inst.sg:GoToState(postfxstate)
        end
    },

    State{
        name = "doublefizzle",
        tags = {"busy", "postfx"},

        onenter = function(inst)
            for i = 0, NUM_DECOR-1 do
                SpawnDecorFX(inst, i)
            end
            inst.sg:SetTimeout(5)
        end,

        timeline = {
            TimeEvent(22 * FRAMES, function(inst)
                for i = 0, NUM_DECOR-1 do
                    SpawnDecorFX(inst, i)
                end
            end),
        },

        ontimeout = function(inst)
            inst.sg:GoToState("idle")
        end
    },

    State{
        name = "convergetothemiddle",
        tags = {"busy", "postfx"},

        onenter = function(inst)
            SpawnDecorFX(inst, 0)
            SpawnDecorFX(inst, NUM_DECOR-1)
            inst.sg:SetTimeout(5)
        end,

        timeline = {
            TimeEvent(8 * FRAMES, function(inst)
                SpawnDecorFX(inst, 1)
                SpawnDecorFX(inst, NUM_DECOR-2)
            end),
            TimeEvent(19 * FRAMES, function(inst)
                SpawnDecorFX(inst, 2)
                SpawnDecorFX(inst, NUM_DECOR-3)
            end),
            TimeEvent(28 * FRAMES, function(inst)
                SpawnDecorFX(inst, 1)
                SpawnDecorFX(inst, NUM_DECOR-2)
            end),
            TimeEvent(39 * FRAMES, function(inst)
                SpawnDecorFX(inst, 0)
                SpawnDecorFX(inst, NUM_DECOR-1)
            end),
        },

        ontimeout = function(inst)
            inst.sg:GoToState("idle")
        end
    },

    State{
        name = "righttoleftandback",
        tags = {"busy", "postfx"},

        onenter = function(inst)
            SpawnDecorFX(inst, 0)
            SpawnDecorFX(inst, 1)
            inst.sg:SetTimeout(5)
        end,

        timeline = {
            TimeEvent(4 * FRAMES, function(inst)
                SpawnDecorFX(inst, 2)
            end),
            TimeEvent(7 * FRAMES, function(inst)
                SpawnDecorFX(inst, 3)
            end),
            TimeEvent(11 * FRAMES, function(inst)
                SpawnDecorFX(inst, 4)
            end),
            TimeEvent(14 * FRAMES, function(inst)
                SpawnDecorFX(inst, 5)
            end),
            TimeEvent(20 * FRAMES, function(inst)
                SpawnDecorFX(inst, 4)
            end),
            TimeEvent(25 * FRAMES, function(inst)
                SpawnDecorFX(inst, 3)
            end),
            TimeEvent(28 * FRAMES, function(inst)
                SpawnDecorFX(inst, 2)
            end),
            TimeEvent(32 * FRAMES, function(inst)
                SpawnDecorFX(inst, 1)
            end),
            TimeEvent(34 * FRAMES, function(inst)
                SpawnDecorFX(inst, 0)
            end),
        },

        ontimeout = function(inst)
            inst.sg:GoToState("idle")
        end
    },

    State{
        name = "randomfizzle",
        tags = {"busy", "postfx"},

        onenter = function(inst)
            SpawnDecorFX(inst, 3)
            inst.sg:SetTimeout(5)
        end,

        timeline = {
            TimeEvent(3 * FRAMES, function(inst)
                SpawnDecorFX(inst, 5)
            end),
            TimeEvent(5 * FRAMES, function(inst)
                SpawnDecorFX(inst, 2)
            end),
            TimeEvent(10 * FRAMES, function(inst)
                SpawnDecorFX(inst, 4)
            end),
            TimeEvent(12 * FRAMES, function(inst)
                SpawnDecorFX(inst, 0)
            end),
            TimeEvent(17 * FRAMES, function(inst)
                SpawnDecorFX(inst, 1)
            end),
            TimeEvent(19 * FRAMES, function(inst)
                SpawnDecorFX(inst, 3)
            end),
            TimeEvent(24 * FRAMES, function(inst)
                SpawnDecorFX(inst, 5)
            end),
            TimeEvent(26 * FRAMES, function(inst)
                SpawnDecorFX(inst, 2)
            end),
            TimeEvent(31 * FRAMES, function(inst)
                SpawnDecorFX(inst, 4)
            end),
            TimeEvent(33 * FRAMES, function(inst)
                SpawnDecorFX(inst, 0)
            end),
            TimeEvent(38 * FRAMES, function(inst)
                SpawnDecorFX(inst, 1)
            end),
        },

        ontimeout = function(inst)
            inst.sg:GoToState("idle")
        end
    },
}

return StateGraph("lavaarenaspawner", states, events, "idle")
