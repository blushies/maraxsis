local TERRITORY_EXPRESSION = maraxsis_constants.WYRM_MATRIARCH_TERRITORY_EXPRESSION
local MINIMUM_TERRITORY_SIZE = maraxsis_constants.WYRM_MATRIARCH_MINIMUM_TERRITORY_SIZE

--- How many chunks of open trench a territory needs for a matriarch.
local MINIMUM_OPEN_CHUNKS = 20

local TILES_PER_CHUNK = 32

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
