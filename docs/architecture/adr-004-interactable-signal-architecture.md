# ADR-004: Signal-Driven Interactable Architecture

- **Status**: Accepted
- **Date**: 2026-03-23
- **Deciders**: Technical Director, Game Designer

## Context

The game has five interactable types (FloorButton, HeavyButton, SlidingDoor, EnergySocket, GoalPad) that must react to box and player movement. These reactions must be deterministic, immediate after animation completes, and correctly handle chain effects (button press → door opens → player can now pass).

## Decision

All interactables subscribe to `GridMotor.entity_move_finished(entity, origin, target)` and self-evaluate:

1. **FloorButton / EnergySocket**: Filter for `rolling_box` group. If the box entered or left their cell, refresh activation state via `GridMotor.get_entity_at()` and check `current_face_kind() in accepted_face_kinds`.
2. **GoalPad**: Filter for `player` group. If the player entered their cell and the pad is powered, trigger level completion.
3. **SlidingDoor**: Passive — receives `set_open(bool)` calls from buttons/sockets via `linked_doors` NodePath arrays. Manages its own grid registration/unregistration.

**Linkage via `@export var linked_doors: Array[NodePath]`**: Buttons and sockets iterate their linked paths and call `door.set_open()` directly. This is intentionally explicit and per-instance rather than broadcast.

**Activation is continuous, not latched**: Buttons and sockets require the box to remain on the cell. Moving the box off releases the trigger and closes linked doors. This creates the "reuse one box for multiple jobs" core loop.

## Alternatives Considered

1. **Polling in `_process()`**: Each interactable checks occupancy every frame. Rejected — wasteful and creates frame-order dependencies.
2. **Direct box→button coupling**: Boxes know about buttons and call them directly. Rejected — violates separation of concerns; boxes shouldn't know about interactable types.
3. **Global event bus**: A central dispatcher routes events. Rejected — adds indirection; the GridMotor signal is already the natural event source.
4. **Latched activation** (one press permanently activates): Discussed as post-MVP option. Rejected for MVP to keep "持续触发" principle clear for teaching.

## Consequences

- **Positive**: Clean data flow (GridMotor → interactables → doors). Adding new interactable types only requires subscribing to the existing signal. No polling overhead.
- **Negative**: `linked_doors`/`linked_goals` are NodePaths set in the editor — refactoring scene structure can break links silently. Multiple buttons controlling one door currently use "last write wins" rather than AND/OR logic.
- **Future**: For the Vertical Slice, consider adding AND/OR gate nodes between buttons and doors for complex puzzles.

## References

- Design doc: `design/gdd/systems/interactables-system.md`
- Implementation: `src/gameplay/interactables/buttons/floor_button.gd`, `src/gameplay/interactables/doors/sliding_door.gd`, `src/gameplay/interactables/energy/energy_socket.gd`, `src/gameplay/interactables/goals/goal_pad.gd`
- Signal source: `src/core/grid/grid_motor.gd` §entity_move_finished
