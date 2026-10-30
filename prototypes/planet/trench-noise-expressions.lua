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

--- Makes the edge of the fertile zone be wavy instead of straight.
--- 
--- The "wavelength" of the wobble wave, in tiles.
local WYRM_PATH_WOBBLE_LENGTH = 120
data:extend {{
    type = "noise-expression",
    name = "maraxsis_wyrm_path_wobble",
    expression = [[
        ]] .. maraxsis_constants.WYRM_PATH_WOBBLE .. [[ * basis_noise{
            x = x,
            y = y,
            seed0 = map_seed,
            seed1 = 'maraxsis_wyrm_path_wobble',
            input_scale = 1/]] .. WYRM_PATH_WOBBLE_LENGTH .. [[,
            output_scale = 1
        }
    ]],
}}

--- Noise mask we use to make the path progressively faded.
---
--- How many tiles make up the diameter of a "bald" spot in the thin area.
local WYRM_PATH_EDGE_GRAIN = 4
data:extend {{
    type = "noise-expression",
    name = "maraxsis_wyrm_path_patches",
    expression = [[
        clamp(0.5 + 0.5 * basis_noise{
            x = x,
            y = y,
            seed0 = map_seed,
            seed1 = 'maraxsis_wyrm_path_patches',
            input_scale = 1/]] .. WYRM_PATH_EDGE_GRAIN .. [[,
            output_scale = 1
        }, 0.01, 0.99)
    ]],
}}

--- Determines what unit spawns in the territory. It's always a matriarch unless
--- enemies are turned off:
--- - 0 for matriarch (first in territory_settings.units)
--- - 1 for no enemy
data:extend {{
    type = "noise-expression",
    name = "maraxsis_wyrm_matriarch_variation_expression",
    expression = "-no_enemies_mode",
}}


--- Matriarch territories are long strips that follow the middle of the trench.
--- A chunk is in a strip when it's within STRIP_REACH tiles of the trench
--- (where maraxsis_trench_noise is 0). Areas that 'flatten out' where the
--- trench opens up are filled in, this makes the matriarch stick to the edges
--- of these open areas more.
--- 
--- How far from zero a strip reaches, in tiles.
local STRIP_REACH = 72
--- How far on either side we read to measure the slope, in tiles.
local STRIP_SLOPE_CHECK = 16
--- Anywhere the noise is closer to 0 than this is in a strip too.
local STRIP_FLAT_NOISE = 0.04
--- Roughly how big the territories are, in tiles.
local STRIP_CELL_SIZE = 3500
--- How much gap in between two territories, in tiles.
local STRIP_GAP = 400
local STRIP_GRID_SHIFT = 1000

--- The voronoi cell number at the given points px and py.
data:extend {{
    type = "noise-function",
    name = "maraxsis_wyrm_trench_cell_at",
    parameters = {"px", "py"},
    expression = [[
        voronoi_cell_id{
            x = px,
            y = py,
            seed0 = map_seed,
            seed1 = 7,
            grid_size = ]] .. STRIP_CELL_SIZE .. [[,
            distance_type = 'manhattan',
            jitter = 0.5
        }
    ]],
}}

--- The voronoi cells that split up the territories and define the territory's ID.
data:extend {{
    type = "noise-expression",
    name = "maraxsis_wyrm_trench_cell",
    expression = "maraxsis_wyrm_trench_cell_at(x + " .. STRIP_GRID_SHIFT * STRIP_CELL_SIZE .. ", y + " .. STRIP_GRID_SHIFT * STRIP_CELL_SIZE .. ")",
}}

--- Create a checkerboard. We allow wyrm territories to be in the "black" grid
--- sections, which lets us space the territories out so there's no two too close.
data:extend {{
    type = "noise-function",
    name = "maraxsis_wyrm_checkerboard",
    parameters = {"gi", "gj", "di", "dj", "cell"},
    expression = "cell_is_in_square & is_black",
    local_expressions = {
        --- The grid square we're checking here.
        square_i = "gi + di",
        square_j = "gj + dj",
        --- The center of the square.
        center_x = "(square_i + 0.5) * " .. STRIP_CELL_SIZE,
        center_y = "(square_j + 0.5) * " .. STRIP_CELL_SIZE,
        --- 1 if the tile's cell is this square's cell.
        cell_is_in_square = "maraxsis_wyrm_trench_cell_at(center_x, center_y) == cell",
        --- 1 if this square is a black square on the checkerboard.
        is_black = "(square_i + square_j) % 2 == 0",
    },
}}
local checkerboard = {}
for di = -1, 1 do
    for dj = -1, 1 do
        table.insert(checkerboard, "maraxsis_wyrm_checkerboard(gi, gj, " .. di .. ", " .. dj .. ", cell)")
    end
end
data:extend {{
    type = "noise-expression",
    name = "maraxsis_wyrm_trench_cell_kept",
    expression = table.concat(checkerboard, " + "),
    local_expressions = {
        --- The grid square this tile is in.
        gi = "floor(x / " .. STRIP_CELL_SIZE .. ") + " .. STRIP_GRID_SHIFT,
        gj = "floor(y / " .. STRIP_CELL_SIZE .. ") + " .. STRIP_GRID_SHIFT,
        cell = "maraxsis_wyrm_trench_cell",
    },
}}
--- The voronoi cells but restricted to the trench area.
data:extend {{
    type = "noise-expression",
    name = "maraxsis_wyrm_trench_territory",
    --- -1 means no territory.
    expression = "if((inside > 0) & away_from_spawn & kept, maraxsis_wyrm_trench_cell, -1)",
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
        --- Roughly how wide the open area is.
        flat_reach = STRIP_FLAT_NOISE .. " / (slope + 0.000001)",
        --- How far out from the middle line the territory goes, in tiles. Accounts
        --- for the open area where the territory spreads out.
        territory_reach = "max(" .. STRIP_REACH .. ", flat_reach)",
        edge_distance = [[
            voronoi_pyramid_noise{
                x = x + ]] .. STRIP_GRID_SHIFT * STRIP_CELL_SIZE .. [[,
                y = y + ]] .. STRIP_GRID_SHIFT * STRIP_CELL_SIZE .. [[,
                seed0 = map_seed,
                seed1 = 7,
                grid_size = ]] .. STRIP_CELL_SIZE .. [[,
                distance_type = 'manhattan',
                jitter = 0.5
            } * ]] .. STRIP_CELL_SIZE .. [[
        ]],
        --- How far this tile is from the end of the strip, in tiles. STRIP_GAP
        --- gets divided by 2 because half the gap belongs to each territory side.
        end_distance = "edge_distance - " .. STRIP_GAP / 2,
        --- Makes the end of the strips be rounded instead of flat. Makes it seem
        --- more natural.
        rounded_end_hypotenuse = [[
            sqrt(
                zero_distance ^ 2 +
                max(0, territory_reach - end_distance) ^ 2
            )
        ]],
        --- How far inside the territory we are, in tiles. Negative if we're outside.
        inside = "territory_reach - rounded_end_hypotenuse",
        --- maraxsis_trench_noise doesn't account for spawn, so we do so ourselves here
        away_from_spawn = "distance > maraxsis_starting_area",
        kept = "maraxsis_wyrm_trench_cell_kept",
    },
}}

local path_fertility = {}
local band_end = 0
for i, band in ipairs(maraxsis_constants.WYRM_PATH_BANDS) do
    band_end = band_end + band.width
    local next_band = maraxsis_constants.WYRM_PATH_BANDS[i + 1]
    local step = band.fertile - (next_band and next_band.fertile or 0)
    table.insert(path_fertility, "(wobbled_distance < " .. band_end .. ") * " .. step)
end

--- Green "fertile" ground under where the matriarch paths. You farm wyrms here.
data:extend {{
    type = "noise-expression",
    name = "maraxsis_wyrm_path",
    expression = "kept & (fertility > maraxsis_wyrm_path_patches)",
    local_expressions = maraxsis.merge(data.raw["noise-expression"]["maraxsis_wyrm_trench_territory"].local_expressions, {
        --- If outside the territory: how far outside. If too far inside: how
        --- far inside. This keeps the fertile ground from drawing in the middle
        --- of an open area. The territory contains it but she paths on the border,
        --- so her path sticks to the border too. This creates an open, non-fertile
        --- middle area, if it's open enough.
        path_distance = "if(inside > 0, max(0, inside - " .. STRIP_REACH .. "), -inside)",
        --- path_distance with the wobble added
        wobbled_distance = "if(path_distance > 0, max(0, path_distance - maraxsis_wyrm_path_wobble), 0)",
        fertility = "if(wobbled_distance == 0, 1, " .. table.concat(path_fertility, " + ") .. ")",
    }),
}}

