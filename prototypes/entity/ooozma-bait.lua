--- Bait is an ooozma confinement cell planted by a fishing tower, baited with fish
--- food.

local bait = table.deepcopy(data.raw["plant"]["maraxsis-fishing-plant"])
bait.name = "maraxsis-ooozma-bait"
bait.localised_name = {"entity-name.maraxsis-ooozma-bait"}
bait.localised_description = {"entity-description.maraxsis-ooozma-bait"}
bait.icon = data.raw.item["maraxsis-ooozma-specimen"].icon
bait.icon_size = data.raw.item["maraxsis-ooozma-specimen"].icon_size
bait.pictures = nil

bait.growth_ticks = 60 * 60 * 5

--- Prevent bait from being planted in domes or lava.
bait.collision_mask = {
    layers = {
        object = true,
        [maraxsis_dome_collision_mask] = true,
        [maraxsis_lava_collision_mask] = true,
    }
}

bait.surface_conditions = maraxsis.trench_surface_conditions()

bait.minable = {
    mining_time = 0.5,
    results = {{type = "item", name = "maraxsis-ooozma-specimen", amount = 10}},
}

bait.agricultural_tower_tint = {
    primary = defines.color.darkslateblue,
    secondary = defines.color.mediumpurple,
}

--- Show green preview squares over trench tiles to indicate that we can place
--- ooozma bait there.
bait.autoplace = {
    tile_restriction = {"maraxsis-fertile-trench-floor"},
    probability_expression = "0",
    richness_expression = "0",
}

data:extend {bait}
