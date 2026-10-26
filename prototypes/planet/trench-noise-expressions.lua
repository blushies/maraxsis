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

--- The wall rocks where you can place pipes and belts but no domes. Delineates
--- the buildable and unbuildable areas in the trench.
data:extend {{
    type = "noise-expression",
    name = "maraxsis_trench_wall_rocks",
    expression = [[
        maraxsis_trench_elevation >= 0.028
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
        maraxsis_3x3_grid
        * maraxsis_trench_wall_rocks
        * (maraxsis_trench_elevation < ]] .. (TRENCH_ENTRANCE_ELEVATION + 0.02) .. [[)
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

--- Places coral and polylplasts on the matriarch paths.
for i, spec in pairs {
    {
        prototype = data.raw.tree["maraxsis-trench-polylplast"],
        probability = maraxsis_constants.WYRM_PATH_POLYLPLAST_PROBABILITY,
    },
    {
        prototype = data.raw["simple-entity"]["maraxsis-trench-coral-animation"],
        probability = maraxsis_constants.WYRM_PATH_CORAL_PROBABILITY,
    },
} do
    spec.prototype.autoplace = {
        tile_restriction = {"maraxsis-fertile-trench-floor"},
        probability_expression = [[
            (1 - maraxsis_trench_wall_rocks) *
            (random_penalty{
                x = x + ]] .. i * 10000 .. [[,
                y = y,
                seed = map_seed,
                source = 1,
                amplitude = 1
            } > ]] .. (1 - spec.probability) .. [[)
        ]],
    }
end
data.raw["simple-entity"]["maraxsis-chimney"].autoplace = {
    probability_expression = [[
        maraxsis_trench_wall * maraxsis_3x3_grid * (random_penalty{x = x, y = y, seed = map_seed, source = 1, amplitude = 1} > 0.995)
    ]],
    order = "f[entity]-a[chimney]"
}

--- How far from a border each band of the path reaches.
local PATH_CENTER_REACH = "(" .. (maraxsis_constants.WYRM_PATH_WIDTH - maraxsis_constants.WYRM_PATH_1_3_FADE - maraxsis_constants.WYRM_PATH_2_3_FADE) .. " + maraxsis_wyrm_path_wobble)"
local PATH_MIDDLE_REACH = "(" .. (maraxsis_constants.WYRM_PATH_WIDTH - maraxsis_constants.WYRM_PATH_1_3_FADE) .. " + maraxsis_wyrm_path_wobble)"
local PATH_OUTER_REACH = "(" .. maraxsis_constants.WYRM_PATH_WIDTH .. " + maraxsis_wyrm_path_wobble)"

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
            (center + middle + outer) / 3 > maraxsis_wyrm_path_patches
        ]],
        local_expressions = {
            --- Main band, all fertile.
            center = [[
                maraxsis_wyrm_border_within(]] .. PATH_CENTER_REACH .. [[)
            ]],
            --- Middle band with 2/3rds fertile tiles.
            middle = [[
                maraxsis_wyrm_border_within(]] .. PATH_MIDDLE_REACH .. [[)
            ]],
            --- Outer band with 1/3rd the fertile tiles.
            outer = [[
                maraxsis_wyrm_border_within(]] .. PATH_OUTER_REACH .. [[)
            ]],
        },
    },
    {
        --- Makes the edge of the fertile zone be wavy instead of straight.
        type = "noise-expression",
        name = "maraxsis_wyrm_path_wobble",
        expression = [[
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
    {
        --- Noise mask we use to make the path progressively faded.
        type = "noise-expression",
        name = "maraxsis_wyrm_path_patches",
        expression = [[
            clamp(0.5 + 0.5 * basis_noise{
                x = x,
                y = y,
                seed0 = map_seed,
                seed1 = 'maraxsis_wyrm_path_patches',
                input_scale = 1/]] .. maraxsis_constants.WYRM_PATH_EDGE_GRAIN .. [[,
                output_scale = 1
            }, 0.01, 0.99)
        ]],
    },
    {
        --- The territory a path tile is in.
        type = "noise-expression",
        name = "maraxsis_wyrm_path_territory",
        expression = "maraxsis_wyrm_territory_at(0, 0)",
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

local PATH_REACHES = {center = PATH_CENTER_REACH, middle = PATH_MIDDLE_REACH, outer = PATH_OUTER_REACH}
for band, names in pairs(maraxsis_constants.WYRM_PATH_BAND_TERRITORIES) do
    local reach = PATH_REACHES[band]
    for direction, name in pairs(names) do
        local d = maraxsis_constants.WYRM_PATH_DIRECTIONS[direction]
        data:extend {{
            type = "noise-expression",
            name = name,
            expression = "maraxsis_wyrm_territory_at(" .. d[1] .. " * " .. reach .. ", " .. d[2] .. " * " .. reach .. ")",
        }}
    end
end


--- Matriarch territories are long strips that follow the middle of the trench.
--- A chunk is in a strip when it's within STRIP_REACH tiles of the trench
--- (where maraxsis_trench_noise is 0). Areas that 'flatten out' where the
--- trench opens up are filled in, this makes the matriarch stick to the edges
--- of these open areas more. Voronoi cells divide the strips into territories.
--- 
--- How far from zero a strip reaches, in tiles.
local STRIP_REACH = 64
--- How far on either side we read to measure the slope, in tiles.
local STRIP_SLOPE_CHECK = 16
--- Anywhere the noise is closer to 0 than this is in a strip too.
local STRIP_FLAT_NOISE = 0.04
--- Roughly how big the territories are, in tiles.
local STRIP_CELL_SIZE = 3500
--- How much gap in between two territories, in tiles.
local STRIP_GAP = 400

data:extend {{
    type = "noise-expression",
    name = "maraxsis_wyrm_trench_territory",
    --- -1 means no territory.
    expression = "if(in_strip & away_from_other, cell, -1)",
    local_expressions = {
        here = "maraxsis_trench_noise(x, y)",
        gx = [[
            (maraxsis_trench_noise(x + ]] .. STRIP_SLOPE_CHECK .. [[, y) -
             maraxsis_trench_noise(x - ]] .. STRIP_SLOPE_CHECK .. [[, y)) /
        ]] .. 2 * STRIP_SLOPE_CHECK,
        gy = [[
            (maraxsis_trench_noise(x, y + ]] .. STRIP_SLOPE_CHECK .. [[) -
             maraxsis_trench_noise(x, y - ]] .. STRIP_SLOPE_CHECK .. [[)) /
        ]] .. 2 * STRIP_SLOPE_CHECK,
        slope = "sqrt(gx * gx + gy * gy)",
        --- Roughly how far this tile is from zero.
        zero_distance = "abs(here) / (slope + 0.000001)",
        near_zero = "zero_distance < " .. STRIP_REACH,
        in_flat = "abs(here) < " .. STRIP_FLAT_NOISE,
        in_strip = "near_zero | in_flat",
        cell = [[
            voronoi_cell_id{
                x = x + 1000 * ]] .. STRIP_CELL_SIZE .. [[,
                y = y + 1000 * ]] .. STRIP_CELL_SIZE .. [[,
                seed0 = map_seed,
                seed1 = 7,
                grid_size = ]] .. STRIP_CELL_SIZE .. [[,
                distance_type = 'manhattan',
                jitter = 0.5
            }
        ]],
        edge_distance = [[
            voronoi_pyramid_noise{
                x = x + 1000 * ]] .. STRIP_CELL_SIZE .. [[,
                y = y + 1000 * ]] .. STRIP_CELL_SIZE .. [[,
                seed0 = map_seed,
                seed1 = 7,
                grid_size = ]] .. STRIP_CELL_SIZE .. [[,
                distance_type = 'manhattan',
                jitter = 0.5
            } * ]] .. STRIP_CELL_SIZE .. [[
        ]],
        --- `STRIP_GAP / 2` because half the gap belongs to each territory side
        away_from_other = "edge_distance > " .. STRIP_GAP / 2,
    },
}}
