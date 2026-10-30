local TERRITORY_EXPRESSION = maraxsis_constants.WYRM_MATRIARCH_TERRITORY_EXPRESSION
local MINIMUM_TERRITORY_SIZE = maraxsis_constants.WYRM_MATRIARCH_MINIMUM_TERRITORY_SIZE

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

--- @param x integer
--- @param y integer
--- @return string # chunk ID
local function chunk_key(x, y)
    return x .. "," .. y
end

--- The top left tile of a chunk determines the territory it's in.
--- @param surface LuaSurface
--- @param chunks ChunkPosition[]
--- @param territory_for_chunk? table<string, double>
--- @return table<string, double> # Keyed map: chunk -> territory
local function get_chunk_territories(surface, chunks, territory_for_chunk)
    territory_for_chunk = territory_for_chunk or {}
    if not chunks[1] then
        return territory_for_chunk
    end
    local chunk_corners = {}
    for i, chunk in pairs(chunks) do
        chunk_corners[i] = {
            x = chunk.x * TILES_PER_CHUNK,
            y = chunk.y * TILES_PER_CHUNK,
        }
    end
    local territories = surface.calculate_tile_properties({TERRITORY_EXPRESSION}, chunk_corners)[TERRITORY_EXPRESSION]
    for i, chunk in pairs(chunks) do
        territory_for_chunk[chunk_key(chunk.x, chunk.y)] = territories[i]
    end
    return territory_for_chunk
end

--- Generate territories for trench surfaces created before matriarchs existed.
--- @param surface LuaSurface
local function create_missing_territories(surface)
    local explored_chunks = {}
    for chunk in surface.get_chunks() do
        if surface.is_chunk_generated(chunk) and not surface.get_territory_for_chunk(chunk) then
            table.insert(explored_chunks, {x = chunk.x, y = chunk.y})
        end
    end
    if not explored_chunks[1] then return end

    local territory_for_chunk = get_chunk_territories(surface, explored_chunks)
    --- Chunks that joined a territory.
    local claimed = {}
    for _, explored_chunk in pairs(explored_chunks) do
        local key = chunk_key(explored_chunk.x, explored_chunk.y)
        local explored_territory = territory_for_chunk[key]
        if explored_territory < 0 or claimed[key] then goto continue end
        claimed[key] = true
        local territory_chunks = {explored_chunk}
        local frontier = {explored_chunk}
        while frontier[1] do
            --- Unclaimed neighbor chunks with no territory yet
            local neighbors = {}
            --- Unclaimed neighbors we still need to look up the territory IDs for.
            local unknown = {}
            for _, chunk in pairs(frontier) do
                for _, offset in pairs {{1, 0}, {-1, 0}, {0, 1}, {0, -1}} do
                    local x, y = chunk.x + offset[1], chunk.y + offset[2]
                    local neighbor_key = chunk_key(x, y)
                    if not claimed[neighbor_key] and
                       not neighbors[neighbor_key] and
                       not surface.get_territory_for_chunk {x, y} then
                        neighbors[neighbor_key] = {x = x, y = y}
                        if not territory_for_chunk[neighbor_key] then
                            table.insert(unknown, {x = x, y = y})
                        end
                    end
                end
            end
            get_chunk_territories(surface, unknown, territory_for_chunk)
            frontier = {}
            for neighbor_key, chunk in pairs(neighbors) do
                if territory_for_chunk[neighbor_key] == explored_territory then
                    claimed[neighbor_key] = true
                    table.insert(territory_chunks, chunk)
                    table.insert(frontier, chunk)
                end
            end
        end
        if #territory_chunks >= MINIMUM_TERRITORY_SIZE then
            local territory = surface.create_territory {chunks = territory_chunks}
            --- Spawn the matriarch that would have spawned with the territory.
            if territory then territory.regenerate_segmented_units() end
        end
        ::continue::
    end
end

--- What a dead matriarch's path turns back into.
local BARREN_TILE = "volcanic-folds-underwater"

--- How many chunks past her territory a matriarch's fertile path can reach.
local PATH_MARGIN
do
    local tiles = TILES_PER_CHUNK + maraxsis_constants.WYRM_PATH_WOBBLE
    for _, band in pairs(maraxsis_constants.WYRM_PATH_BANDS) do tiles = tiles + band.width end
    PATH_MARGIN = math.ceil(tiles / TILES_PER_CHUNK)
end

--- Turns path tiles in a chunk barren unless inside a territory with a living
--- matriarch, and removes plants there. Fertile tiles not near any territory
--- are noise expressions that were pruned as territories but survived as fertile
--- biomes.
--- @param chunk ChunkPosition
--- @return boolean # whether any tile went barren
local function prune_path(chunk)
    local trench = game.surfaces[maraxsis_constants.TRENCH_SURFACE_NAME]
    if not trench then return false end
    local left = chunk.x * TILES_PER_CHUNK
    local top = chunk.y * TILES_PER_CHUNK
    local area = {{left, top}, {left + TILES_PER_CHUNK, top + TILES_PER_CHUNK}}
    local path_tiles = trench.find_tiles_filtered {area = area, name = PATH_TILE}
    if not path_tiles[1] then return false end

    -- the territory numbers of the territories close enough to own a path tile here
    local territory_chunks = {}
    for dx = -PATH_MARGIN, PATH_MARGIN do
        for dy = -PATH_MARGIN, PATH_MARGIN do
            local nearby = {x = chunk.x + dx, y = chunk.y + dy}
            if trench.get_territory_for_chunk(nearby) then
                table.insert(territory_chunks, nearby)
            end
        end
    end
    local living = {}
    local dead = storage.wyrm_dead_territories or {}
    for _, territory in pairs(get_chunk_territories(trench, territory_chunks)) do
        if not dead[territory] then living[territory] = true end
    end

    local positions = {}
    for i, tile in pairs(path_tiles) do positions[i] = tile.position end
    local cells = trench.calculate_tile_properties({"maraxsis_wyrm_trench_cell"}, positions).maraxsis_wyrm_trench_cell
    local barren = {}
    for i, position in pairs(positions) do
        if not living[cells[i]] then
            table.insert(barren, {name = BARREN_TILE, position = position})
        end
    end
    if not barren[1] then return false end
    trench.set_tiles(barren, true, false, false, false)
    for _, plant in pairs(trench.find_entities_filtered {area = area, name = {POLYLPLAST, CORAL}}) do
        if trench.get_tile(plant.position).name ~= PATH_TILE then plant.destroy() end
    end
    return true
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
            prune_path(chunk)
        end
    end
    maraxsis.execute_later("wyrm_path_batch", 1)
end
maraxsis.register_delayed_function("wyrm_path_batch", carve_wyrm_paths)

--- Ticks between each chunk of a dead matriarch's path going barren, so it fades out.
local TICKS_PER_DEAD_CHUNK = 6

--- Decays queued chunks until one has path in it, then waits a moment before the next,
--- so the path fades out without pausing on chunks that have none.
local function kill_dead_paths()
    local queue = storage.wyrm_dead_path_chunks
    repeat
        if not queue or not queue[1] then
            storage.wyrm_dead_path_chunks = nil
            return
        end
    until prune_path(table.remove(queue, 1))
    maraxsis.execute_later("wyrm_dead_path_batch", TICKS_PER_DEAD_CHUNK)
end
maraxsis.register_delayed_function("wyrm_dead_path_batch", kill_dead_paths)

--- Variation on breadth-first search that grows the list of chunks by the given
--- margin.
--- @param chunks ChunkPosition[]
--- @param margin integer
--- @return ChunkPosition[]
local function grow_chunks(chunks, margin)
    local grown, seen, frontier = {}, {}, {}
    local function add(x, y, next_frontier)
        local key = chunk_key(x, y)
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

--- When a matriarch dies, her path goes barren: her territory's chunks, and the chunks
--- around it that her path's fade reaches into. It spreads out from where she died.
maraxsis.on_event(defines.events.on_segmented_unit_died, function(event)
    local unit = event.segmented_unit
    if not unit.valid then return end
    local surface = unit.surface
    local territory = unit.territory
    if surface.name ~= maraxsis_constants.TRENCH_SURFACE_NAME or not territory then return end
    local chunks = territory.get_chunks()
    if not chunks[1] then return end

    --- Queue all her territory's chunks for death.
    local first = chunks[1]
    local _, id = next(get_chunk_territories(surface, {first}))
    storage.wyrm_dead_territories = storage.wyrm_dead_territories or {}
    storage.wyrm_dead_territories[id] = true
    local head = unit.segments[1]
    local died_at = head and head.valid and head.position or {x = first.x * TILES_PER_CHUNK, y = first.y * TILES_PER_CHUNK}
    local dying = {}
    for _, chunk in pairs(grow_chunks(chunks, PATH_MARGIN)) do
        if surface.is_chunk_generated(chunk) then
            local dx = (chunk.x + 0.5) * TILES_PER_CHUNK - died_at.x
            local dy = (chunk.y + 0.5) * TILES_PER_CHUNK - died_at.y
            chunk.distance = dx * dx + dy * dy
            table.insert(dying, chunk)
        end
    end
    --- Kill the chunks closest to where she died first.
    table.sort(dying, function(a, b) return a.distance < b.distance end)

    local idle = not storage.wyrm_dead_path_chunks
    storage.wyrm_dead_path_chunks = storage.wyrm_dead_path_chunks or {}
    for _, chunk in pairs(dying) do
        table.insert(storage.wyrm_dead_path_chunks, {x = chunk.x, y = chunk.y})
    end
    if idle then kill_dead_paths() end
end)

--- The territory and fertile biome noise expressions are slightly different
--- because the game will remove a territory under WYRM_MATRIARCH_MINIMUM_TERRITORY_SIZE
--- chunks, but will leave the biome. So we must trim the too-small biomes ourselves.
maraxsis.on_event(defines.events.on_chunk_generated, function(event)
    if event.surface.name ~= maraxsis_constants.TRENCH_SURFACE_NAME then return end
    prune_path(event.position)
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
