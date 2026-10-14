--- A matriarch is passive until something hurts her, where she becomes hostile.
--- When attacking, she's always "enraged". Her enrage timer is also her passive
--- timer. After her enrage is over (see enraged_duration), we turn her back
--- passive.
local PASSIVE_FORCE_NAME = "maraxsis-wyrm-passive"
local HOSTILE_FORCE_NAME = "enemy"

--- How soon to look at a matriarch that was just hit.
local FIRST_CHECK_TICKS = 60

--- @return LuaForce
local function ensure_passive_force()
    local force = game.forces[PASSIVE_FORCE_NAME]
    if not force then
        force = game.create_force(PASSIVE_FORCE_NAME)
    end
    for _, other in pairs(game.forces) do
        if other.name ~= PASSIVE_FORCE_NAME then
            other.set_cease_fire(force, true)
        end
    end
    return force
end

--- @param unit LuaSegmentedUnit
local function make_passive(unit)
    if not unit.valid then return end
    unit.force = ensure_passive_force()
end

--- Makes her passive again after a timeout. Resets when she's hit again.
--- @param unit LuaSegmentedUnit
local function calm_down(unit)
    if not unit.valid then return end
    local ai_state = unit.get_ai_state()
    if ai_state.type == defines.segmented_unit_ai_state.enraged_at_target or
        ai_state.type == defines.segmented_unit_ai_state.enraged_at_nothing then
        maraxsis.execute_later("wyrm_matriarch_calm_down", ai_state.remaining_time + 1, unit)
        return
    end
    make_passive(unit)
    local head = unit.segments[1].entity
    --- If you set her to "patrolling" mode, you have to specify where she should
    --- go. Sending her "investigating" to her current location lets us skip that
    --- since she transitions straight to "patrolling" after that.
    unit.set_ai_state {type = defines.segmented_unit_ai_state.investigating, destination = head.position}
end
maraxsis.register_delayed_function("wyrm_matriarch_calm_down", calm_down)

--- @param unit LuaSegmentedUnit
local function make_hostile(unit)
    if not unit.valid then return end
    if unit.force.name == HOSTILE_FORCE_NAME then return end
    unit.force = HOSTILE_FORCE_NAME
    maraxsis.execute_later("wyrm_matriarch_calm_down", FIRST_CHECK_TICKS, unit)
end

maraxsis.on_event(maraxsis.events.on_init(), function()
    ensure_passive_force()
end)

maraxsis.on_event(defines.events.on_segmented_unit_created, function(event)
    make_passive(event.segmented_unit)
end)

maraxsis.on_event(defines.events.on_force_created, function(event)
    event.force.set_cease_fire(PASSIVE_FORCE_NAME, true)
end)

maraxsis.on_event(defines.events.on_segmented_unit_damaged, function(event)
    make_hostile(event.segmented_unit)
end)
