--- Bait is a wyrm confinement cell planted by a fishing tower, baited with a
--- fish food. It "ripens" into a captured wyrm specimen only when a wyrm
--- matriarch swims over it.

local BAIT_NAME = "maraxsis-wyrm-bait"
local FISH_FOOD_NAME = "maraxsis-fish-food"

--- How long after a matriarch passes before the bait is ready to harvest.
local RIPEN_TICKS = 60 * 30

--- @return table<string, true>
local function baited()
    storage.baited_wyrm_bait = storage.baited_wyrm_bait or {}
    return storage.baited_wyrm_bait
end

--- @param bait LuaEntity
local function bait_hash(bait)
    return bait.surface.index .. ":" .. bait.position.x .. "," .. bait.position.y
end

maraxsis.on_event(defines.events.on_tower_planted_seed, function(event)
    local bait = event.plant
    if bait.name ~= BAIT_NAME then return end

    -- an empty cell catches nothing. Spend a fish food from the same tower to bait it
    local input = event.tower.get_inventory(defines.inventory.agricultural_tower_input)
    if input and input.remove {name = FISH_FOOD_NAME, count = 1} == 1 then
        baited()[bait_hash(bait)] = true
    end
end)

maraxsis.on_event(defines.events.on_script_trigger_effect, function(event)
    if event.effect_id ~= maraxsis_constants.WYRM_BAIT_RIPENED_EFFECT_ID then return end

    local bait = event.target_entity
    if not bait or not bait.valid or bait.name ~= BAIT_NAME then return end
    if not baited()[bait_hash(bait)] then return end
    -- she has already visited this one
    if bait.tick_grown - game.tick <= RIPEN_TICKS then return end

    bait.tick_grown = game.tick + RIPEN_TICKS
end)

--- @param bait LuaEntity
local function forget(bait)
    if bait.valid and bait.name == BAIT_NAME then
        baited()[bait_hash(bait)] = nil
    end
end

maraxsis.on_event(defines.events.on_tower_mined_plant, function(event) forget(event.plant) end)
maraxsis.on_event(defines.events.on_player_mined_entity, function(event) forget(event.entity) end)
maraxsis.on_event(defines.events.on_robot_mined_entity, function(event) forget(event.entity) end)
