local BIOLUMINESCENCE_PARAMETERS = {
    [defines.segmented_unit_ai_state.patrolling] = {
        color = {0.5, 0.5, 0.5},
        delay = 240,
        intensity = 1,
        size = 0.3,
    },
    [defines.segmented_unit_ai_state.investigating] = {
        color = {0.5, 0.5, 0.5},
        delay = 240,
        intensity = 1,
        size = 0.3,
    },
    [defines.segmented_unit_ai_state.attacking] = {
        color = {1, 0, 0},
        delay = 20,
        intensity = 3,
        size = 0.5,
    },
    [defines.segmented_unit_ai_state.enraged_at_target] = {
        color = {1, 0, 0},
        delay = 20,
        intensity = 3,
        size = 0.5,
    },
    [defines.segmented_unit_ai_state.enraged_at_nothing] = {
        color = {1, 0, 0},
        delay = 20,
        intensity = 3,
        size = 0.5,
    },
}

local function get_flash_parameters(segment)
    return BIOLUMINESCENCE_PARAMETERS[segment.segmented_unit.get_ai_state().type]
end

local function get_segment_index(segment)
    for i, s in pairs(segment.segmented_unit.segments) do
        if s.entity == segment then return i end
    end
    return 0
end

local function get_segment_glow_delay(segment, flash_parameters)
    return flash_parameters.delay - ((game.tick - get_segment_index(segment)) % flash_parameters.delay)
end

local function draw_bioluminescese(segment)
    if not segment.valid then return end
    local flash_parameters = get_flash_parameters(segment)
    -- skip animating when we're not near the player and therefore inactive
    if segment.segmented_unit.activity_mode ~= defines.segmented_unit_activity_mode.full then
        maraxsis.execute_later("draw_bioluminescese", get_segment_glow_delay(segment, flash_parameters), segment)
        return
    end
    rendering.draw_light {
        sprite = "utility/light_medium",
        scale = segment.prototype.collision_box.left_top.x * flash_parameters.size,
        intensity = flash_parameters.intensity,
        oriented = true,
        target = segment,
        surface = segment.surface_index,
        time_to_live = 5,
        color = flash_parameters.color,
    }
    local delay = get_segment_glow_delay(segment, flash_parameters)
    maraxsis.execute_later("draw_bioluminescese", delay, segment)
end
maraxsis.register_delayed_function("draw_bioluminescese", draw_bioluminescese)

maraxsis.on_event(defines.events.on_script_trigger_effect, function(event)
    if event.effect_id ~= "maraxsis-wyrm-matriarch-segment-created" then
        return
    end

    local segment = event.target_entity
    maraxsis.execute_later("draw_bioluminescese", 1, segment)
end)
