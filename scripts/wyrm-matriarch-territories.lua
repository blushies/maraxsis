local TERRITORY_EXPRESSION = maraxsis_constants.WYRM_MATRIARCH_TERRITORY_EXPRESSION
local MINIMUM_TERRITORY_SIZE = maraxsis_constants.WYRM_MATRIARCH_MINIMUM_TERRITORY_SIZE

--- How many chunks of open trench a territory needs for a matriarch.
local MINIMUM_OPEN_CHUNKS = 20

local TILES_PER_CHUNK = 32

--- The expression that follows the path of the matriarchs along the borders of
--- their territories. 
local PATH_EXPRESSION = "maraxsis_wyrm_path"
local PATH_TILE = "maraxsis-fertile-trench-floor"
local WALL_ROCKS_EXPRESSION = "maraxsis_trench_wall_rocks"
local POLYLPLAST = "maraxsis-trench-polylplast"
local CORAL = "maraxsis-trench-coral-animation"
local TRENCH_FLOOR = {
    "volcanic-folds-underwater",
    "volcanic-cracks-hot-underwater",
    "volcanic-cracks-warm-underwater",
}

--- Chunks to backfill with matriarch path per iteration.
local CHUNKS_PER_BATCH = 32

--- How far past the explored chunks to claim, in chunks.
---
--- Territories will extend further out than the player has explored, so we
--- increase the search area by twice the width of the average territory.
local TERRITORY_MARGIN = maraxsis_constants.WYRM_MATRIARCH_TERRITORY_RADIUS / TILES_PER_CHUNK * 2

--- Generate territories for trench surfaces created before matriarchs existed.
--- @param surface LuaSurface
local function create_missing_territories(surface)
    -- the box the player has explored, and which of its chunks exist
    local explored = {}
    local left, top, right, bottom
    for chunk in surface.get_chunks() do
        if surface.is_chunk_generated(chunk) then
            explored[chunk.x] = explored[chunk.x] or {}
            explored[chunk.x][chunk.y] = true
            left = math.min(left or chunk.x, chunk.x)
            right = math.max(right or chunk.x, chunk.x)
            top = math.min(top or chunk.y, chunk.y)
            bottom = math.max(bottom or chunk.y, chunk.y)
        end
    end
    if not left then return end

    local chunks, chunk_corners = {}, {}
    for x = left - TERRITORY_MARGIN, right + TERRITORY_MARGIN do
        for y = top - TERRITORY_MARGIN, bottom + TERRITORY_MARGIN do
            if not surface.get_territory_for_chunk {x = x, y = y} then
                chunks[#chunks + 1] = {x = x, y = y}
                chunk_corners[#chunk_corners + 1] = {
                    x = x * TILES_PER_CHUNK,
                    y = y * TILES_PER_CHUNK,
                }
            end
        end
    end
    if #chunks == 0 then return end

    local territory_ids = surface.calculate_tile_properties({TERRITORY_EXPRESSION}, chunk_corners)[TERRITORY_EXPRESSION]
    if not territory_ids then return end

    local chunks_by_territory = {}
    for i, chunk in pairs(chunks) do
        local id = territory_ids[i]
        local group = chunks_by_territory[id] or {chunks = {}, explored = 0}
        table.insert(group.chunks, chunk)
        if explored[chunk.x] and explored[chunk.x][chunk.y] then
            group.explored = group.explored + 1
        end
        chunks_by_territory[id] = group
    end

    for _, group in pairs(chunks_by_territory) do
        if group.explored > 0 and #group.chunks >= MINIMUM_TERRITORY_SIZE then
            local territory = surface.create_territory {chunks = group.chunks}
            -- spawn the matriarch that would have spawned with the territory.
            -- on_segmented_unit_created kills her if this territory is invalid
            if territory then territory.regenerate_segmented_units() end
        end
    end
end

--- A matriarch territory is considered reachable if the center tile of M chunks
--- are inside the trench.
--- @param territory LuaTerritory
local function is_reachable(territory)
    local surface = territory.surface
    local chunk_centers = {}
    for _, chunk in pairs(territory.get_chunks()) do
        chunk_centers[#chunk_centers + 1] = {
            x = chunk.x * TILES_PER_CHUNK + (TILES_PER_CHUNK / 2),
            y = chunk.y * TILES_PER_CHUNK + (TILES_PER_CHUNK / 2),
        }
    end
    -- 1 inside the trench, 0 in the rock outside it
    local inside_trench = surface.calculate_tile_properties({"maraxsis_trench_wall"}, chunk_centers).maraxsis_trench_wall
    local chunks_in_trench = 0
    for _, value in pairs(inside_trench) do
        if value > 0 then
            chunks_in_trench = chunks_in_trench + 1
            if chunks_in_trench >= MINIMUM_OPEN_CHUNKS then return true end
        end
    end
    return false
end

--- Removes a matriarch living in a trench "dead zone", where the player can
--- never reach or see her. Her territory stays; it just holds nothing.
--- @param unit LuaSegmentedUnit
local function remove_if_unreachable(unit)
    local territory = unit.territory
    if territory and not is_reachable(territory) then
        unit.destroy()
        return true
    end
    return false
end

--- Backfill chunks generated before we had matriarch paths. Batched to avoid
--- lockups.
local function carve_wyrm_paths()
    local queue = storage.wyrm_path_chunks
    local trench = game.surfaces[maraxsis_constants.TRENCH_SURFACE_NAME]
    if not queue or not trench then
        storage.wyrm_path_chunks = nil
        return
    end

    for _ = 1, CHUNKS_PER_BATCH do
        local chunk = table.remove(queue)
        if not chunk then
            storage.wyrm_path_chunks = nil
            return
        end
        local left, top = chunk.x * TILES_PER_CHUNK, chunk.y * TILES_PER_CHUNK
        local floor = trench.find_tiles_filtered {
            area = {{left, top}, {left + TILES_PER_CHUNK, top + TILES_PER_CHUNK}},
            name = TRENCH_FLOOR,
        }
        if floor[1] then
            local positions = {}
            for i, tile in pairs(floor) do positions[i] = tile.position end
            local properties = trench.calculate_tile_properties({PATH_EXPRESSION, WALL_ROCKS_EXPRESSION}, positions)
            local on_path, wall_rocks = properties[PATH_EXPRESSION], properties[WALL_ROCKS_EXPRESSION]
            local tiles = {}
            for i, value in pairs(on_path) do
                if value > 0 then tiles[#tiles + 1] = {name = PATH_TILE, position = positions[i]} end
            end
            if tiles[1] then trench.set_tiles(tiles, true, false, false, false) end

            --- Backfill plants.
            for i, value in pairs(on_path) do
                if value > 0 and wall_rocks[i] == 0 then
                    local roll = math.random()
                    local name = (roll < maraxsis_constants.WYRM_PATH_POLYLPLAST_PROBABILITY and POLYLPLAST)
                        or (roll < maraxsis_constants.WYRM_PATH_POLYLPLAST_PROBABILITY + maraxsis_constants.WYRM_PATH_CORAL_PROBABILITY and CORAL)
                    if name then
                        local position = {positions[i].x + 0.5, positions[i].y + 0.5}
                        if trench.can_place_entity {name = name, position = position} then
                            trench.create_entity {name = name, position = position}
                        end
                    end
                end
            end
        end
    end
    maraxsis.execute_later("wyrm_path_batch", 1)
end
maraxsis.register_delayed_function("wyrm_path_batch", carve_wyrm_paths)

--- What a dead matriarch's path turns back into.
local BARREN_TILE = "volcanic-folds-underwater"

--- Ticks between each chunk of a dead matriarch's path going barren, so it fades out.
local TICKS_PER_DEAD_CHUNK = 6

--- The path properties we need to reconstruct it.
local PATH_BAND_TERRITORIES = maraxsis_constants.WYRM_PATH_BAND_TERRITORIES
local PATH_BAND_COUNT = table_size(PATH_BAND_TERRITORIES)
local PATH_PROPERTIES = {"maraxsis_wyrm_path_territory", "maraxsis_wyrm_path_patches"}
for _, names in pairs(PATH_BAND_TERRITORIES) do
    for _, name in pairs(names) do
        PATH_PROPERTIES[#PATH_PROPERTIES + 1] = name
    end
end

--- Re-draws one chunk of the shared border between two matriarch territories as
--- if the territories didn't exist.
--- @param chunk ChunkPosition
--- @return boolean # whether any tile decayed
local function make_decayed(chunk)
    local trench = game.surfaces[maraxsis_constants.TRENCH_SURFACE_NAME]
    if not trench then return false end
    local dead_territory_ids = storage.wyrm_dead_territories
    if not dead_territory_ids then return false end
    local left = chunk.x * TILES_PER_CHUNK
    local top = chunk.y * TILES_PER_CHUNK
    local area = {{left, top}, {left + TILES_PER_CHUNK, top + TILES_PER_CHUNK}}
    local path_tiles_in_chunk = trench.find_tiles_filtered {area = area, name = PATH_TILE}
    if not path_tiles_in_chunk[1] then return false end

    local positions = {}
    for i, tile in pairs(path_tiles_in_chunk) do positions[i] = tile.position end
    local properties = trench.calculate_tile_properties(PATH_PROPERTIES, positions)
    local territory_ids = properties.maraxsis_wyrm_path_territory
    local patches = properties.maraxsis_wyrm_path_patches

    local tiles_to_kill = {}
    for i, tile in pairs(path_tiles_in_chunk) do
        local bands_drawn = 0
        local bands_alive = 0
        local territory_id = territory_ids[i]
        --- This tile is:
        ---  - "drawn" if it's near a border, so it would've been drawn during
        ---    map generation.
        ---  - "alive" if it's near a border and a territory on either side is
        ---    still alive.
        --- If there's a difference, we know we should repaint the tile.
        for _, names in pairs(PATH_BAND_TERRITORIES) do
            local is_drawn = false
            local is_alive = not dead_territory_ids[territory_id]
            for _, name in pairs(names) do
                local neighbor_territory_id = properties[name][i]
                is_drawn = is_drawn or neighbor_territory_id ~= territory_id
                is_alive = is_alive or not dead_territory_ids[neighbor_territory_id]
                if is_drawn and is_alive then break end
            end
            if is_drawn then bands_drawn = bands_drawn + 1 end
            if is_drawn and is_alive then bands_alive = bands_alive + 1 end
        end
        local should_repaint_tile = bands_alive < bands_drawn
        --- Handle the path edge where the tiles might now be dead now due to
        --- the fading edges. Same logic as in trench-noise-expressions.lua
        local faded_out = bands_alive / PATH_BAND_COUNT <= patches[i]
        if should_repaint_tile and faded_out then
            tiles_to_kill[#tiles_to_kill + 1] = {name = BARREN_TILE, position = tile.position}
        end
    end
    if not tiles_to_kill[1] then return false end
    trench.set_tiles(tiles_to_kill, true, false, false, false)
    --- Kill all the decorative plants there too.
    for _, plant in pairs(trench.find_entities_filtered {area = area, name = {POLYLPLAST, CORAL}}) do
        if trench.get_tile(plant.position).name ~= PATH_TILE then plant.destroy() end
    end
    return true
end

--- Queues a chunk for dying.
--- @param x integer
--- @param y integer
local function queue_dead_path_chunk(x, y)
    local trench = game.surfaces[maraxsis_constants.TRENCH_SURFACE_NAME]
    if not trench then return end
    local key = x .. "," .. y
    if storage.wyrm_dead_path_seen[key] or not trench.is_chunk_generated {x, y} then return end
    storage.wyrm_dead_path_seen[key] = true
    table.insert(storage.wyrm_dead_path_chunks, {x = x, y = y})
end

local function kill_dead_paths()
    local queue = storage.wyrm_dead_path_chunks
    local trench = game.surfaces[maraxsis_constants.TRENCH_SURFACE_NAME]
    if not queue or not queue[1] or not trench then
        storage.wyrm_dead_path_chunks = nil
        storage.wyrm_dead_path_seen = nil
        return
    end
    storage.wyrm_dead_path_seen = storage.wyrm_dead_path_seen or {}
    local chunk = table.remove(queue, math.random(#queue))
    local tiles_died = make_decayed(chunk)
    --- Queue up adjacent chunks if we decayed tiles in this chunk.
    if tiles_died then
        for dx = -1, 1 do
            for dy = -1, 1 do
                queue_dead_path_chunk(chunk.x + dx, chunk.y + dy)
            end
        end
    end
    maraxsis.execute_later("wyrm_dead_path_batch", TICKS_PER_DEAD_CHUNK)
end
maraxsis.register_delayed_function("wyrm_dead_path_batch", kill_dead_paths)

--- The territory value for the top-left tile of each chunk determines the
--- chunk's territory. Gets all the territory IDs for the given chunks.
--- @param surface LuaSurface
--- @param chunks ChunkPosition[]
--- @return double[]
local function chunk_territory_ids(surface, chunks)
    local chunk_corners = {}
    for i, chunk in pairs(chunks) do
        chunk_corners[i] = {x = chunk.x * TILES_PER_CHUNK, y = chunk.y * TILES_PER_CHUNK}
    end
    return surface.calculate_tile_properties({"maraxsis_wyrm_path_territory"}, chunk_corners).maraxsis_wyrm_path_territory
end

--- Variation on breadth-first search that grows the list of chunks by the given
--- margin.
--- @param chunks ChunkPosition[]
--- @param margin integer
--- @return ChunkPosition[]
local function grow_chunks(chunks, margin)
    local grown, seen, frontier = {}, {}, {}
    local function add(x, y, next_frontier)
        local key = x .. "," .. y
        if seen[key] then return end
        seen[key] = true
        local chunk = {x = x, y = y}
        grown[#grown + 1] = chunk
        next_frontier[#next_frontier + 1] = chunk
    end
    for _, chunk in pairs(chunks) do add(chunk.x, chunk.y, frontier) end
    for _ = 1, margin do
        local next_frontier = {}
        for _, chunk in pairs(frontier) do
            for dx = -1, 1 do
                for dy = -1, 1 do
                    add(chunk.x + dx, chunk.y + dy, next_frontier)
                end
            end
        end
        frontier = next_frontier
    end
    return grown
end

--- A fertile path decays when both adjacent matriarchs are dead.
maraxsis.on_event(defines.events.on_segmented_unit_died, function(event)
    local unit = event.segmented_unit
    local surface = unit.surface
    local territory = unit.territory
    if not unit.valid or
        surface.name ~= maraxsis_constants.TRENCH_SURFACE_NAME or
        not territory
        then return end
    local chunks = territory.get_chunks()
    if not chunks[1] then return end
    local id = chunk_territory_ids(surface, {chunks[1]})[1]

    --- We first search for chunks we want to decay by looking at the territory
    --- and its immediate neighbor chunks.
    local area_chunks = grow_chunks(chunks, 1)
    local area_territory_ids = chunk_territory_ids(surface, area_chunks)

    storage.wyrm_dead_territories = storage.wyrm_dead_territories or {}
    storage.wyrm_dead_territories[id] = true

    --- Chunks belonging to neighbor territories that are also dead. These get
    --- queued for decaying.
    local dead_neighbor_chunks = {}
    for i, chunk in pairs(area_chunks) do
        local territory_id = area_territory_ids[i]
        local is_neighbor = territory_id ~= id
        local is_dead = storage.wyrm_dead_territories[territory_id]
        if is_neighbor and is_dead then
            table.insert(dead_neighbor_chunks, chunk)
        end
    end
    if not dead_neighbor_chunks[1] then return end

    local idle = not storage.wyrm_dead_path_chunks
    storage.wyrm_dead_path_chunks = storage.wyrm_dead_path_chunks or {}
    -- Chunks done for an earlier death may have more to lose now, so start afresh.
    storage.wyrm_dead_path_seen = {}
    for _, chunk in pairs(dead_neighbor_chunks) do
        queue_dead_path_chunk(chunk.x, chunk.y)
    end
    if idle then kill_dead_paths() end
end)

--- Handle infertile ground in new chunks generated in territories with dead matriarchs.
maraxsis.on_event(defines.events.on_chunk_generated, function(event)
    if not storage.wyrm_dead_territories then return end
    if event.surface.name ~= maraxsis_constants.TRENCH_SURFACE_NAME then return end
    make_decayed(event.position)
end)

--- Migrate trench surfaces created before matriarchs were a thing. This can't
--- be in migrations/ because those all run before scripts/map-gen/maraxsis.lua
--- gives the trench its territory_settings.
local function ensure_matriarchs()
    if storage.wyrm_matriarch_territories_filled then return end
    storage.wyrm_matriarch_territories_filled = true

    local trench = game.surfaces[maraxsis_constants.TRENCH_SURFACE_NAME]
    if not trench then return end
    for _, territory in pairs(trench.get_territories()) do
        territory.visibility_condition = "never"
    end
    create_missing_territories(trench)
    for _, unit in pairs(trench.get_segmented_units()) do
        remove_if_unreachable(unit)
    end

    local chunks = {}
    for chunk in trench.get_chunks() do
        if trench.is_chunk_generated(chunk) then chunks[#chunks + 1] = {x = chunk.x, y = chunk.y} end
    end
    storage.wyrm_path_chunks = chunks
    carve_wyrm_paths()
end

maraxsis.on_event(maraxsis.events.on_init(), function()
    ensure_matriarchs()
end)

maraxsis.on_event(defines.events.on_territory_created, function(event)
    local territory = event.territory
    if territory.surface.name ~= maraxsis_constants.TRENCH_SURFACE_NAME then return end
    territory.visibility_condition = "never"
end)

maraxsis.on_event(defines.events.on_segmented_unit_created, function(event)
    local unit = event.segmented_unit
    if not unit.valid then return end
    if unit.surface.name ~= maraxsis_constants.TRENCH_SURFACE_NAME then return end
    remove_if_unreachable(unit)
end)
