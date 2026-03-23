# Directory Structure

```text
/
├── project.godot                # Godot project file (created when engine project is initialized)
├── CLAUDE.md                    # Master configuration for Claude Code
├── .claude/                     # Agents, skills, hooks, rules, internal docs
├── src/
│   ├── core/                    # Engine-facing foundation code
│   │   ├── autoload/            # Small global singletons only: game_state, scene_router, audio_manager
│   │   ├── main/                # Main.tscn and root scene orchestration
│   │   ├── grid/                # Grid math, occupancy, movement rules, coordinate helpers
│   │   └── shared/              # Reusable enums, constants, helper resources, base components
│   ├── gameplay/
│   │   ├── player/              # Player scene, controller, presentation
│   │   ├── boxes/               # Rolling box scenes, state logic, face rules
│   │   ├── enemies/             # Enemy scenes and enemy-specific logic
│   │   └── interactables/
│   │       ├── buttons/         # Floor buttons and heavy switches
│   │       ├── doors/           # Sliding doors, gates, locks
│   │       ├── energy/          # Energy sockets and powered terminals
│   │       └── terrain/         # Conveyors, ramps, pits, rotating platforms
│   ├── levels/
│   │   ├── shared/              # Level root scene, common markers, reusable pieces
│   │   └── tutorial/            # The first five teaching levels
│   ├── ui/
│   │   ├── hud/                 # In-game HUD and prompts
│   │   └── menus/               # Main menu, pause, level select
│   └── debug/                   # Temporary debug scenes and gizmos
├── assets/
│   ├── art/
│   │   ├── environment/         # Walls, floors, props, level dressing
│   │   ├── props/               # Boxes, buttons, doors, interactable visuals
│   │   └── ui/                  # UI sprites and icons
│   ├── audio/
│   │   ├── music/               # Music tracks and stingers
│   │   └── sfx/                 # UI, movement, box, enemy, and environment SFX
│   ├── fonts/                   # Imported fonts
│   ├── materials/               # Shared Godot materials
│   ├── models/                  # Mesh sources and exported 3D assets
│   ├── textures/                # Shared textures
│   └── data/                    # `.tres` / `.res` data resources once rules stabilize
├── design/
│   ├── gdd/                     # Design docs and system docs
│   └── levels/                  # Level concepts, teaching arcs, graybox notes
├── docs/
│   ├── architecture/            # Engine-specific technical plans and structure docs
│   └── engine-reference/        # Curated version-pinned Godot reference docs
├── tests/
│   ├── unit/                    # Script-level tests (GUT once adopted)
│   └── integration/             # Cross-scene and rules integration tests
├── tools/                       # Export helpers, validation scripts, content utilities
├── prototypes/                  # Throwaway prototypes isolated from production scenes
└── production/
    ├── session-state/           # Ephemeral session state (active.md — gitignored)
    └── session-logs/            # Session audit trail (gitignored)
```

## Newcomer Rules

- Keep gameplay-critical rules in `src/core/` and `src/gameplay/`, not in ad-hoc level scripts.
- Every concrete object should have one obvious home. If you cannot decide where a file goes, the design is probably too coupled.
- Prefer one scene plus one primary script per gameplay object.
- Do not put reusable rule logic inside `assets/`; keep `assets/` for imported content and data resources only.
