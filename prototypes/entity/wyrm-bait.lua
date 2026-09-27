--- Bait is a wyrm confinement cell planted by a fishing tower, baited with fish
--- food. It never ripens on its own: only a wyrm matriarch swimming over it
--- turns it into a specimen. scripts/wyrm-bait.lua does the ripening.

local bait = table.deepcopy(data.raw["plant"]["maraxsis-fishing-plant"])
bait.name = "maraxsis-wyrm-bait"
bait.localised_name = {"entity-name.maraxsis-wyrm-bait"}
bait.localised_description = {"entity-description.maraxsis-wyrm-bait"}
bait.icon = data.raw.item["maraxsis-wyrm-specimen"].icon
bait.icon_size = data.raw.item["maraxsis-wyrm-specimen"].icon_size
bait.pictures = nil
bait.trigger_target_mask = {maraxsis_constants.WYRM_BAIT_TRIGGER_MASK}

--- Max value so it "never" ripens without the matriarch.
bait.growth_ticks = 2 ^ 53

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
    results = {{type = "item", name = "maraxsis-wyrm-specimen", amount = 10}},
}

bait.agricultural_tower_tint = {
    primary = defines.color.darkslateblue,
    secondary = defines.color.mediumpurple,
}

--- Show green preview squares over trench tiles to indicate that we can place
--- wyrm bait there.
bait.autoplace = {
    tile_restriction = {
        "volcanic-folds-underwater",
        "volcanic-cracks-hot-underwater",
        "volcanic-cracks-warm-underwater",
        "nuclear-ground-underwater",
        "maraxsis-trench-foundation",
    },
    probability_expression = "0",
    richness_expression = "0",
}

data:extend {bait}
