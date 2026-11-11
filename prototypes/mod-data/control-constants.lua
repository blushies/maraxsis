-- _G.maraxsis_dome_collision_mask = "maraxsis_dome_collision_mask"
-- _G.maraxsis_underwater_collision_mask = "maraxsis_underwater_collision_mask"
-- _G.maraxsis_lava_collision_mask = "maraxsis_lava_collision_mask"
-- _G.maraxsis_coral_collision_mask = "maraxsis_coral_collision_mask"
-- _G.maraxsis_trench_entrance_collision_mask = "maraxsis_trench_entrance_collision_mask"

local TRENCH_MOVEMENT_FACTOR = 1
local TRENCH_ENTRANCE_ELEVATION = 0.08

local SUBMARINES = {
    ["maraxsis-diesel-submarine"] = true,
    ["maraxsis-nuclear-submarine"] = true,
}

local OOOZMA_MATRIARCH_TERRITORY_EXPRESSION = "maraxsis_ooozma_trench_territory"
local OOOZMA_MATRIARCH_MINIMUM_TERRITORY_SIZE = 350

--- Extra padding outside of the main STRIP_REACH path where the fertile tiles
--- get spotty, starting from the inside.
local OOOZMA_PATH_BANDS = {
    {width = 8, fertile = 2 / 3},
    {width = 8, fertile = 1 / 3},
}
--- The "amplitude" of the wobble that makes the path's edge wavy, in tiles.
local OOOZMA_PATH_WOBBLE = 10
--- Chance of a polylplast and coral on each tile of the matriarch path.
local OOOZMA_PATH_POLYLPLAST_PROBABILITY = 0.004
local OOOZMA_PATH_CORAL_PROBABILITY = 0.022

local TRENCH_SURFACE_NAME = "maraxsis-trench"
local MARAXSIS_SURFACE_NAME = "maraxsis"

local MARAXSIS_SURFACES = { -- all surfaces with water mechanics
    [TRENCH_SURFACE_NAME] = true,
    [MARAXSIS_SURFACE_NAME] = true,
    ["maraxsis-factory-floor"] = true,
    ["maraxsis-trench-factory-floor"] = true,
}

local MARAXSIS_TRENCH_SURFACES = { -- all surfaces with trench water mechanics
    [TRENCH_SURFACE_NAME] = true,
    ["maraxsis-trench-factory-floor"] = true,
}


local SUBMARINE_FUEL_SOURCES = {
    ["maraxsis-diesel-submarine"] = {"maraxsis-diesel", "rocket-fuel"},
    ["maraxsis-nuclear-submarine"] = {"nuclear", "nuclear-fuel"},
}

--- Entity types that can be flooded.
local DOME_DISABLEABLE_TYPES = {
    ["assembling-machine"] = true,
    ["furnace"] = true,
    ["lab"] = true,
    ["beacon"] = true,
    ["mining-drill"] = true,
    ["rocket-silo"] = true,
    ["generator"] = true,
    ["fusion-generator"] = true,
    ["fusion-reactor"] = true,
    ["reactor"] = true,
    ["boiler"] = true,
}

--- Entities that need a pressure dome but are immune to flooding. These work
--- in an un-atmosphere'd dome.
local DOME_EXCLUDED_FROM_DISABLE = {
}

local SAND_ITEM_NAME = "sand"

local TROPICAL_FISH_NAMES = {}
for i = 1, 15 do
    local name = "maraxsis-tropical-fish-" .. i
    TROPICAL_FISH_NAMES[i] = name
end

local PRESSURE_DOMES = {
    
}

data:extend {{
    type = "mod-data",
    name = "maraxsis-constants", --Data that was previously defined in a control-level script, now defined in data, allowing other mods to configure these constants.
    data_type = "table",
    data = {
        -- This data is called in scripts.constants.
        TRENCH_MOVEMENT_FACTOR = TRENCH_MOVEMENT_FACTOR,
        SUBMARINES = SUBMARINES,
        PRESSURE_DOMES = PRESSURE_DOMES,
        TRENCH_SURFACE_NAME = TRENCH_SURFACE_NAME,
        MARAXSIS_SURFACE_NAME = MARAXSIS_SURFACE_NAME,
        MARAXSIS_SURFACES = MARAXSIS_SURFACES,
        MARAXSIS_TRENCH_SURFACES = MARAXSIS_TRENCH_SURFACES,
        SUBMARINE_FUEL_SOURCES = SUBMARINE_FUEL_SOURCES,
        DOME_DISABLEABLE_TYPES = DOME_DISABLEABLE_TYPES,
        DOME_EXCLUDED_FROM_DISABLE = DOME_EXCLUDED_FROM_DISABLE,
        TRENCH_ENTRANCE_ELEVATION = TRENCH_ENTRANCE_ELEVATION,
        OOOZMA_MATRIARCH_TERRITORY_EXPRESSION = OOOZMA_MATRIARCH_TERRITORY_EXPRESSION,
        OOOZMA_MATRIARCH_MINIMUM_TERRITORY_SIZE = OOOZMA_MATRIARCH_MINIMUM_TERRITORY_SIZE,
        OOOZMA_PATH_BANDS = OOOZMA_PATH_BANDS,
        OOOZMA_PATH_WOBBLE = OOOZMA_PATH_WOBBLE,
        OOOZMA_PATH_POLYLPLAST_PROBABILITY = OOOZMA_PATH_POLYLPLAST_PROBABILITY,
        OOOZMA_PATH_CORAL_PROBABILITY = OOOZMA_PATH_CORAL_PROBABILITY,
        TROPICAL_FISH_NAMES = TROPICAL_FISH_NAMES,
        SAND_ITEM_NAME = SAND_ITEM_NAME,
        NEEDS_DOME = {}, -- populated by prototypes/collision-mask.lua
        DEGRADATION_ENABLED = true -- https://github.com/notnotmelon/maraxsis/issues/409
    }
}}
