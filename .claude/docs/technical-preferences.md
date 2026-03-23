# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.6.1 (stable)
- **Language**: GDScript
- **Rendering**: Forward+ for desktop 3D
- **Physics**: Deterministic grid gameplay. Use code-driven movement and collision checks; do not make puzzle rules depend on `RigidBody3D`.

## Naming Conventions

- **Classes**: PascalCase with `class_name` when reuse is expected, e.g. `RollingBox`
- **Variables**: `snake_case`, e.g. `grid_position`
- **Signals/Events**: `snake_case` past tense where possible, e.g. `box_rolled`, `door_opened`
- **Files**: lowercase `snake_case`, e.g. `rolling_box.gd`, `level_root.gd`
- **Scenes/Prefabs**: scene files use lowercase `snake_case`; root nodes use PascalCase, e.g. `player.tscn` with root `Player`
- **Constants**: `UPPER_SNAKE_CASE`, e.g. `GRID_SIZE`

## Performance Budgets

- **Target Framerate**: 60 FPS
- **Frame Budget**: 16.6 ms
- **Draw Calls**: Prefer under 700 visible draw calls in gameplay scenes; treat 1000+ as a warning
- **Memory Ceiling**: Prefer under 1 GB runtime memory on desktop for the full game; MVP target under 600 MB

## Testing

- **Framework**: Manual graybox playtests first; add GUT for unit tests once core movement and box rules stabilize
- **Minimum Coverage**: Core grid logic and box-state rules should be covered before expanding content
- **Required Tests**: Player movement, box orientation updates, button activation, enemy collision rules, level reset, soft-lock checks

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- No puzzle-critical logic in physics impulses or `RigidBody3D` behavior
- No gameplay rules hidden only inside animation callbacks
- No giant global singleton that owns every system
- No direct cross-scene node traversal like `../../SomeNode` for gameplay dependencies
- No level-specific hacks inside generic core systems

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- Godot built-in nodes, resources, importers, and export pipeline
- GUT for automated tests after the first playable prototype
- Lightweight art/audio asset packs with compatible licenses
- Avoid gameplay plugins until after the vertical slice proves the core loop

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- 2026-03-21: Adopt Godot 4.6.1 + GDScript + grid-driven 3D architecture for MVP
- 2026-03-21: Keep autoload singletons minimal: `game_state`, `scene_router`, `audio_manager`
- 2026-03-21: Use scenes for concrete gameplay objects, scripts/resources for reusable logic and data
