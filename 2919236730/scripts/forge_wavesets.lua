-- TODO
-- Check if these functions are global with your expansion
_G.WAVESETS = {}
-- Adds the waveset so it can be used via the game settings panel.
-- Options:
--   total_rounds      - number of rounds in the waveset
--   min_spawn_portals - the minimum amount of spawn portals required for an arena to be compatible with the waveset, default = 3
--   default_arena     - the arena the waveset was designed for, default = "lavaarena"
function AddWaveset(filename, total_rounds, min_spawn_portals, default_arena)
	if not _G.WAVESETS[filename] then
		_G.WAVESETS[filename] = {total_rounds = total_rounds, min_spawn_portals = min_spawn_portals or 3, default_arena = default_arena or "lavaarena"}
	else
		Debug:Print("Attempted to add the waveset " .. tostring(filename) .. ", but it already exists!", "error")
	end
end
AddWaveset("classic", 5, 3, "lavaarena")
AddWaveset("default", 7, 3, "lavaarena") -- TODO change name

_G.FORGE_ARENAS = {} -- TODO create methods that you can use to add to this, sort alphabetically? or sort in game settings panel
-- Adds the arena so it can be used via the game settings panel.
-- Options:
--   spawn_portals - the amount of spawn portals in the arena, default = 3
--   icon          - the atlas and image for the arena icon that is displayed in the game settings panel. Format must be: {atlas = "", image = ""}
function AddArena(name, spawn_portals, icon)
	if not _G.FORGE_ARENAS[name] then
		_G.FORGE_ARENAS[name] = {spawn_portals = spawn_portals or 3, icon = {atlas = icon.atlas, image = icon.image}}
	else
		Debug:Print("Attempted to add the " .. tostring(name) .. " arena, but it already exists!", "error")
	end
end
AddArena("lavaarena", 3, {atlas = "", image = ""})
