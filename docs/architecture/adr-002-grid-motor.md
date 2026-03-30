# ADR-002: Grid Motor as Central Movement Authority

- **Status**: Accepted
- **Date**: 2026-03-21
- **Deciders**: Technical Director, Lead Programmer

## Context

The game uses deterministic grid-based movement. Every entity (player, boxes, walls, doors, enemies) occupies exactly one grid cell. Movement must be atomic: an entity is either fully in cell A or fully in cell B, never in-between logically. Multiple systems need to query "what's at cell X?" and the answer must be consistent.

## Decision

Introduce a single `GridMotor` node per level that owns all movement authority:

- **Occupancy dictionary**: `occupiers: Dictionary` maps `Vector2i → Node` for O(1) cell queries.
- **`try_move_actor()`**: The sole entry point for player-initiated movement. Handles push chains (player pushes box) and enemy collision in one atomic transaction.
- **`register_entity()` / `unregister_entity()`**: All blocking entities register on spawn and unregister on removal (doors opening, enemies defeated).
- **`entity_move_finished` signal**: Emitted after any entity completes its move animation. All interactables (buttons, sockets, goals) subscribe to this single signal.

## Alternatives Considered

1. **Per-entity collision checks**: Each entity queries its neighbors directly. Rejected — leads to order-dependent bugs and duplicated logic.
2. **Physics-based collisions via RigidBody3D**: Rejected per project pillar "可爱外表，硬核规则" — deterministic rules cannot depend on physics simulation.
3. **Event bus with global signals**: A global signal bus instead of per-motor signals. Rejected — too indirect; the motor already knows the full movement context.

## Consequences

- **Positive**: Single source of truth for occupancy. Movement rules are centralized and testable. Signal-driven interactables avoid polling.
- **Negative**: All entities must register synchronously in `_ready()` (deferred registration causes race conditions). The motor must be instantiated before any entity.
- **Migration**: Adding new entity types requires implementing `grid_position`, `blocks_grid_cell`, and calling `register_entity()` in `_ready()`.

## References

- Implementation: `src/core/grid/grid_motor.gd`
- Grid math: `src/core/grid/grid_coord.gd`
- Design doc: `design/gdd/systems/rolling-utility-box.md` §交互结算顺序
