local TRENCH_MOVEMENT_FACTOR = maraxsis_constants.TRENCH_MOVEMENT_FACTOR
local TRENCH_ENTRANCE_ELEVATION = maraxsis_constants.TRENCH_ENTRANCE_ELEVATION

data:extend {{
    type = "noise-expression",
    name = "maraxsis_trench_elevation",
    expression = [[
        maraxsis_elevation(x /]] .. TRENCH_MOVEMENT_FACTOR .. [[, y /]] .. TRENCH_MOVEMENT_FACTOR .. [[)
    ]]
}}

data:extend {{
    type = "noise-expression",
    name = "maraxsis_trench_wall",
    expression = [[
        maraxsis_trench_elevation < ]] .. TRENCH_ENTRANCE_ELEVATION .. [[
    ]]
}}

data:extend {{
    type = "noise-expression",
    name = "maraxsis_lava_master",
    expression = [[
        multioctave_noise{
            x = x,
            y = y,
            persistence = 0.5,
            seed0 = map_seed,
            seed1 = 1344,
            octaves = 1,
            input_scale = 1/250,
            output_scale = 1
        }
    ]]
}}

data:extend {{
    type = "noise-expression",
    name = "maraxsis_lava_master_master",
    expression = [[
        multioctave_noise{
            x = x,
            y = y,
            persistence = 0.5,
            seed0 = map_seed,
            seed1 = 1344,
            octaves = 5,
            input_scale = 1/200,
            output_scale = 1
        }
    ]]
}}

data:extend {{
    type = "noise-expression",
    name = "maraxsis_lava_river_1",
    expression = [[
        multioctave_noise{
            x = x,
            y = y,
            persistence = 0.5,
            seed0 = map_seed,
            seed1 = 13442,
            octaves = 2,
            input_scale = 1/40,
            output_scale = 1
        }
    ]]
}}

data:extend {{
    type = "noise-expression",
    name = "maraxsis_lava_river_2",
    expression = [[
        multioctave_noise{
            x = x,
            y = y,
            persistence = 0.5,
            seed0 = map_seed,
            seed1 = 56443,
            octaves = 2,
            input_scale = 1/40,
            output_scale = 1
        }
    ]]
}}

data:extend {{
    type = "noise-expression",
    name = "maraxsis_lava_thickness",
    expression = [[
        min(if (
            maraxsis_lava_master_master < 0,
            lava_thickness * (0.3 + maraxsis_lava_master_master) / 0.3,
            lava_thickness
        ), 0.3)
    ]],
    local_expressions = {
        lava_thickness = [[
            abs(maraxsis_lava_master)
        ]]
    }
}}

data:extend {{
    type = "noise-function",
    name = "maraxsis_lava_tile",
    expression = [[
        (expanded_thickness > 0.15) *
        min(
            ((-expanded_thickness < maraxsis_lava_river_1) * (maraxsis_lava_river_1 < expanded_thickness)) +
            ((-expanded_thickness < maraxsis_lava_river_2) * (maraxsis_lava_river_2 < expanded_thickness))
        , 1)
    ]],
    local_expressions = {
        expanded_thickness = [[
            maraxsis_lava_thickness * lava_thickness_modifier
        ]]
    },
    parameters = {"lava_thickness_modifier"}
}}

data:extend {{
    type = "noise-expression",
    name = "maraxsis_3x3_grid",
    expression = [[
        ((y %% 3) == 0) * ((x %% 3) == 0)
    ]]
}}

data:extend {{
    type = "noise-expression",
    name = "maraxsis_4x4_grid",
    expression = [[
        ((y %% 4) == 0) * ((x %% 4) == 0)
    ]]
}}

--- Lava rivers.
data:extend {{
    type = "noise-expression",
    name = "maraxsis_hot_lava",
    expression = [[
        maraxsis_lava_biome * maraxsis_lava_tile(1)
    ]]
}}

--- The large patches of the trench where lava rivers can form.
data:extend {{
    type = "noise-expression",
    name = "maraxsis_lava_biome",
    expression = [[
        maraxsis_trench_wall * (maraxsis_lava_master_master > 0)
    ]]
}}

data.raw.tile["lava-hot-underwater"].autoplace = {
    probability_expression = [[
        maraxsis_hot_lava
    ]],
    order = "b[lava]-a[maraxsis]"
}

data.raw["simple-entity"]["maraxsis-lava-lamp"].autoplace = {
    probability_expression = [[
        maraxsis_4x4_grid * maraxsis_hot_lava * (maraxsis_trench_elevation < ]] .. TRENCH_ENTRANCE_ELEVATION - 0.05 .. [[)
    ]],
    order = "b[lava]-a[maraxsis]"
}

data.raw["simple-entity"]["maraxsis-trench-wall-collisionless"].autoplace = {
    probability_expression = [[
        maraxsis_3x3_grid * (maraxsis_trench_elevation < ]] .. (TRENCH_ENTRANCE_ELEVATION + 0.02) .. [[) * (maraxsis_trench_elevation >= 0.028)
    ]],
    order = "b[lava]-a[maraxsis]"
}

data.raw.tile["maraxsis-trench-out-of-map"].autoplace = {
    probability_expression = [[
        1 - maraxsis_trench_wall
    ]],
    order = "a[maraxsis-trench-out-of-map]-a[maraxsis]"
}

data.raw.tile["volcanic-cracks-hot-underwater"].autoplace = {
    probability_expression = [[
        maraxsis_trench_wall * maraxsis_lava_tile(1.5)
    ]],
    order = "c[tile]-a[maraxsis]"
}

data.raw.tile["volcanic-cracks-warm-underwater"].autoplace = {
    probability_expression = [[
        maraxsis_trench_wall * maraxsis_lava_tile(2.5)
    ]],
    order = "d[tile]-a[maraxsis]"
}

data.raw.tile["volcanic-folds-underwater"].autoplace = {
    probability_expression = [[maraxsis_trench_wall]],
    order = "e[tile]-a[maraxsis]"
}

data.raw.tile["maraxsis-fertile-trench-floor"].autoplace = {
    probability_expression = [[
        2 * maraxsis_trench_wall * maraxsis_wyrm_path * (1 - maraxsis_hot_lava)
    ]],
    order = "e[tile]-b[maraxsis]"
}
data.raw["simple-entity"]["maraxsis-chimney"].autoplace = {
    probability_expression = [[
        maraxsis_trench_wall * maraxsis_3x3_grid * (random_penalty{x = x, y = y, seed = map_seed, source = 1, amplitude = 1} > 0.995)
    ]],
    order = "f[entity]-a[chimney]"
}

-- Wyrm matriarch territories, the same as Vulcanus's demolisher territories
data:extend {
    {
        type = "noise-expression",
        name = "maraxsis_wyrm_matriarch_territory_radius",
        expression = maraxsis_constants.WYRM_MATRIARCH_TERRITORY_RADIUS,
    },
    {
        type = "noise-expression",
        name = maraxsis_constants.WYRM_MATRIARCH_TERRITORY_EXPRESSION,
        expression = [[
            voronoi_cell_id{
                x = x + 1000 * maraxsis_wyrm_matriarch_territory_radius,
                y = y + 1000 * maraxsis_wyrm_matriarch_territory_radius,
                seed0 = map_seed,
                seed1 = 0,
                grid_size = maraxsis_wyrm_matriarch_territory_radius,
                distance_type = 'manhattan',
                jitter = 1
            } - maraxsis_wyrm_matriarch_starting_area
        ]],
    },
    {
        --- The territory a point belongs to. Comparing a point's territory with
        --- its neighbors' is how we find the borders between them.
        type = "noise-function",
        name = "maraxsis_wyrm_territory_at",
        expression = [[
            voronoi_cell_id{
                x = x + dx + 1000 * maraxsis_wyrm_matriarch_territory_radius,
                y = y + dy + 1000 * maraxsis_wyrm_matriarch_territory_radius,
                seed0 = map_seed,
                seed1 = 0,
                grid_size = maraxsis_wyrm_matriarch_territory_radius,
                distance_type = 'manhattan',
                jitter = 1
            }
        ]],
        parameters = {"dx", "dy"},
    },
    {
        --- 1 where any neighbor a given reach away sits in another territory.
        type = "noise-function",
        name = "maraxsis_wyrm_border_within",
        expression = [[
            min(1,
                (maraxsis_wyrm_territory_at(reach, 0) != here) +
                (maraxsis_wyrm_territory_at(-reach, 0) != here) +
                (maraxsis_wyrm_territory_at(0, reach) != here) +
                (maraxsis_wyrm_territory_at(0, -reach) != here) +
                (maraxsis_wyrm_territory_at(reach, reach) != here) +
                (maraxsis_wyrm_territory_at(reach, -reach) != here) +
                (maraxsis_wyrm_territory_at(-reach, reach) != here) +
                (maraxsis_wyrm_territory_at(-reach, -reach) != here)
            )
        ]],
        local_expressions = {
            here = "maraxsis_wyrm_territory_at(0, 0)",
        },
        parameters = {"reach"},
    },
    {
        --- The paths the matriarchs keep to: a ring inset from the borders of their territory.
        type = "noise-expression",
        name = "maraxsis_wyrm_path",
        expression = [[
            (center + middle + outer) / 3 > patches
        ]],
        local_expressions = {
            --- Main band, all fertile.
            center = [[
                maraxsis_wyrm_border_within(]] .. (maraxsis_constants.WYRM_PATH_WIDTH - maraxsis_constants.WYRM_PATH_1_3_FADE - maraxsis_constants.WYRM_PATH_2_3_FADE) .. [[ + wobble)
            ]],
            --- Middle band with 2/3rds fertile tiles.
            middle = [[
                maraxsis_wyrm_border_within(]] .. (maraxsis_constants.WYRM_PATH_WIDTH - maraxsis_constants.WYRM_PATH_1_3_FADE) .. [[ + wobble)
            ]],
            --- Outer band with 1/3rd the fertile tiles.
            outer = [[
                maraxsis_wyrm_border_within(]] .. maraxsis_constants.WYRM_PATH_WIDTH .. [[ + wobble)
            ]],
            --- Noise mask we use to make the path progressively faded.
            patches = [[
                clamp(0.5 + 0.5 * basis_noise{
                    x = x,
                    y = y,
                    seed0 = map_seed,
                    seed1 = 'maraxsis_wyrm_path_patches',
                    input_scale = 1/]] .. maraxsis_constants.WYRM_PATH_EDGE_GRAIN .. [[,
                    output_scale = 1
                }, 0.01, 0.99)
            ]],
            --- Makes the edge of the fertile zone be wavy instead of straight.
            wobble = [[
                ]] .. maraxsis_constants.WYRM_PATH_WOBBLE .. [[ * basis_noise{
                    x = x,
                    y = y,
                    seed0 = map_seed,
                    seed1 = 'maraxsis_wyrm_path_wobble',
                    input_scale = 1/]] .. maraxsis_constants.WYRM_PATH_WOBBLE_LENGTH .. [[,
                    output_scale = 1
                }
            ]],
        },
    },
    {
        type = "noise-expression",
        name = "maraxsis_wyrm_matriarch_starting_area",
        expression = "distance < 7 * 32",
    },
    {
        type = "noise-expression",
        name = "maraxsis_wyrm_matriarch_variation_expression",
        expression = "floor(clamp(distance / (18 * 32) - 0.25, 0, 4)) + (-99 * no_enemies_mode)", -- negative number means no matriarch
    },
}
