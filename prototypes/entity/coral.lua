local resource_autoplace = require "resource-autoplace"
local sounds = require "__base__.prototypes.entity.sounds"

data:extend {{
    type = "autoplace-control",
    category = "resource",
    name = "maraxsis-coral",
    order = "e-0",
    richness = true
}}

local coral_variants = {}
for i = 1, 3 do
    coral_variants[i] = {
        filename = "__maraxsis__/graphics/icons/coral-" .. i .. ".png",
        width = 64,
        height = 64,
        scale = 0.65,
        flags = {"icon"},
    }
end

data:extend {{
    type = "item",
    name = "maraxsis-coral",
    icon = "__maraxsis__/graphics/icons/coral-1.png",
    icon_size = 64,
    pictures = coral_variants,
    stack_size = 200,
    spoil_result = "limestone",
    spoil_ticks = 60 * 60 * 10,
    spoil_quality_change = 1,
}}

data:extend {{
    type = "resource",
    name = "maraxsis-coral",
    hidden_in_factoriopedia = true,
    icon = "__maraxsis__/graphics/icons/coral-1.png",
    flags = {"placeable-neutral"},
    order = "a-b-x[maraxsis-coral]",
    tree_removal_probability = 0.8,
    tree_removal_max_distance = 32 * 32,
    minable = {
        mining_particle = "stone-particle",
        mining_time = 5,
        results = {
            {type = "item", name = "maraxsis-coral", amount = 1},
        }
    },
    walking_sound = sounds.ore,
    mining_sound = table.deepcopy(data.raw.tree["slipstack"].mining_sound),
    mined_sound = table.deepcopy(data.raw.tree["slipstack"].mined_sound),
    driving_sound = stone_driving_sound, -- todo
    collision_box = {{-0.1, -0.1}, {0.1, 0.1}},
    selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
    autoplace = {
        control = "maraxsis-coral",
        default_enabled = false,
        force = "neutral",
        order = "z",
        placement_density = 1,
        probability_expression = "maraxsis_coral_ore",
        richness_expression = [[var("control:maraxsis-coral:richness") * random_penalty(x, y, 9232 + (sqrt(x*x + y*y) / 10), 99, 1000)]],
    },
    stage_counts = {},
    map_color = {255, 20, 147},
    mining_visualisation_tint = {255, 20, 147},
    factoriopedia_simulation = {init = make_resource("maraxsis-coral")},
    created_effect = {
        type = "direct",
        action_delivery = {
            type = "instant",
            source_effects = {
                {
                    type = "script",
                    effect_id = "maraxsis-coral-created",
                },
            }
        }
    }
}}

local animations = {}
for i = 1, 7 do
    local variant = require("__maraxsis__/graphics/entity/coral/" .. i .. ".lua")
    variant.filename = "__maraxsis__/graphics/entity/coral/" .. i .. ".png"
    variant.frame_count = variant.sprite_count
    variant.sprite_count = nil
    variant.flags = {"no-scale"}
    variant.animation_speed = 0.2
    variant.tint = {0.9, 0.9, 0.9, 1}
    variant.shift.y = variant.shift.y - 1
    animations[i] = {
        layers = {
            variant,
            {
                filename = "__maraxsis__/graphics/entity/coral/sh.png",
                width = 340,
                height = 126,
                draw_as_shadow = true,
                frame_count = 1,
                repeat_count = variant.frame_count,
                scale = 0.33,
                shift = {1.3, 0},
            }
        }
    }
end

data:extend {{
    type = "simple-entity",
    name = "maraxsis-coral-animation",
    flags = {"placeable-neutral", "placeable-off-grid", "not-on-map"},
    icon = "__maraxsis__/graphics/icons/coral-1.png",
    icon_size = 64,
    random_animation_offset = true,
    hidden = true,
    max_health = 1,
    collision_box = {{-0.1, -0.1}, {0.1, 0.1}},
    selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
    selectable_in_game = false,
    collision_mask = {layers = {}},
    random_variation_on_create = true,
    animations = animations,
    factoriopedia_alternative = "maraxsis-coral",
    localised_name = {"entity-name.maraxsis-coral"},
    localised_description = {"entity-description.maraxsis-coral"},
    subgroup = "creatures",
    order = "j-c[maraxsis-polylplast]"
}}

-- totally not a slipstack
local polylplast = table.deepcopy(data.raw.tree.slipstack)
polylplast.name = "maraxsis-polylplast"
polylplast.subgroup = "creatures"
polylplast.order = "j-c[maraxsis-polylplast]"
polylplast.autoplace = nil
polylplast.minable.results = {
    {type = "item", name = "maraxsis-coral", amount_min = 20, amount_max = 25},
    {type = "item", name = "stone",          amount_min = 4,  amount_max = 6},
}
polylplast.maraxsis_buildability_rules = {water = true, dome = false, coral = true, trench = true, trench_entrance = false, trench_lava = false}
polylplast.collision_mask.layers.ground_tile = nil
polylplast.collision_mask.layers[maraxsis_trench_entrance_collision_mask] = true
data:extend {polylplast}

--- Copies of the polylplast and coral for the matriarch paths, only in the
--- trench. They glow a little in different colors.
local trench_polylplast = table.deepcopy(polylplast)
trench_polylplast.name = "maraxsis-trench-polylplast"
trench_polylplast.localised_name = {"entity-name.maraxsis-polylplast"}
trench_polylplast.localised_description = {"entity-description.maraxsis-polylplast"}
trench_polylplast.hidden_in_factoriopedia = true
trench_polylplast.factoriopedia_alternative = "maraxsis-polylplast"
trench_polylplast.autoplace = nil
local POLYP_GLOW_COLORS = {
    {0.4, 0.3, 1.0},    -- indigo
    {0.6, 0.5, 1.0},    -- blue-violet
    {0.55, 0.35, 1.0},  -- violet
    {0.85, 0.65, 1.0},  -- lavender
    {0.75, 0.35, 1.0},  -- purple
    {0.9, 0.4, 1.0},    -- orchid
    {1.0, 0.35, 0.85},  -- magenta
    {1.0, 0.5, 0.75},   -- pink
}
for n, variation in pairs(trench_polylplast.variations) do
    local color = POLYP_GLOW_COLORS[(n - 1) % #POLYP_GLOW_COLORS + 1]
    local glow = table.deepcopy(variation.trunk)
    glow.filename = "__maraxsis__/graphics/entity/polylplast/glow.png"
    glow.surface = nil
    glow.flags = nil
    glow.draw_as_glow = true
    glow.tint = color
    variation.trunk = {layers = {variation.trunk, glow}}

    local tips = table.deepcopy(variation.leaves)
    tips.filename = "__maraxsis__/graphics/entity/polylplast/glow.png"
    tips.surface = nil
    tips.flags = nil
    tips.draw_as_glow = true
    tips.tint = color
    variation.overlay = tips
end
data:extend {trench_polylplast}

--- Copy of the coral, but decoration only. Also glows a little.
local trench_coral = table.deepcopy(data.raw["simple-entity"]["maraxsis-coral-animation"])
trench_coral.name = "maraxsis-trench-coral-animation"
trench_coral.autoplace = nil
local CORAL_GLOW_COLORS = {
    {1.0, 0.75, 0.25},  -- amber
    {0.25, 1.0, 0.6},   -- green
    {0.1, 1.0, 0.85},   -- teal
    {0.2, 0.85, 1.0},   -- cyan
    {0.4, 0.55, 1.0},   -- blue
    {0.75, 0.5, 1.0},   -- violet
    {1.0, 0.55, 0.85},  -- pink
}
for n, animation in pairs(trench_coral.animations) do
    local glow = table.deepcopy(animation.layers[1])
    glow.filename = "__maraxsis__/graphics/entity/coral/" .. n .. "-glow.png"
    glow.tint = CORAL_GLOW_COLORS[n]
    glow.draw_as_glow = true
    table.insert(animation.layers, glow)
end
data:extend {trench_coral}
