# Godot 4 Starter Architecture

## Goal

This document locks the technical direction for the first playable version of
`玩具星港：滚滚滚` and explains the project structure in a way that is safe
for a beginner to follow.

The main principle is simple:

`use Godot like a scene editor and runtime shell, but keep puzzle rules deterministic and code-driven`

That means:
- visible things are built as scenes
- puzzle rules live in scripts
- movement and box orientation are not left to physics randomness

## Chosen Stack

| Decision | Choice | Why |
| ---- | ---- | ---- |
| Engine | Godot 4.6.1 stable | Current stable 4.6 line, safer than RC builds for a beginner project |
| Language | GDScript | Fastest iteration loop, best fit for a solo beginner, strongest Godot-first learning material |
| Rendering | Forward+ | Good default for desktop stylized 3D |
| Core gameplay model | Grid-based deterministic logic | Puzzle readability is more important than realistic physics |
| Physics usage | Minimal, presentation-first | Use collision helpers and areas, not rigid-body simulation, for rule-critical interactions |
| Testing | Manual graybox tests first, GUT later | Better learning curve and lower setup friction |

## Why This Is the Best Beginner Choice

### Why GDScript instead of C#

- It is the path of least resistance in Godot.
- Most Godot examples and community answers are written in GDScript first.
- Reloading scripts and testing small changes is quicker.
- Your project is rule-heavy, not CPU-heavy, so you do not need C# for performance.

### Why grid logic instead of full physics

- You are making a puzzle game, so players must be able to reason about outcomes.
- A box that rolls to the wrong place because of contact jitter will feel unfair.
- Deterministic grid updates are much easier to debug than stacked physics bodies.
- You can still make it look physical with animation, sound, squash, and camera work.

## Recommended Scene Tree

Start with one top-level game scene:

```text
Main.tscn
Main (Node)
├── World (Node3D)
│   └── LevelRoot (Node3D)
├── UI (CanvasLayer)
└── Debug (Node)
```

### Responsibilities

- `Main`: application root for the running game session
- `World`: owns the current level scene
- `LevelRoot`: owns gameplay objects for one level
- `UI`: HUD, prompts, pause menu, transition overlays
- `Debug`: optional helper visuals that can be removed later

Keep this root stable. Do not let every level invent its own top-level layout.

## Recommended Autoloads

Limit autoloads to three:

| Autoload | Responsibility | What it should NOT do |
| ---- | ---- | ---- |
| `game_state.gd` | Current level id, run state, restart requests | It should not hold every gameplay object reference |
| `scene_router.gd` | Load/unload the current level scene under `World` | It should not own puzzle rules |
| `audio_manager.gd` | Music and global SFX playback | It should not become a generic event bus |

If you feel tempted to add a fourth autoload early, stop and ask whether the
logic belongs inside a scene-local script instead.

## Folder-by-Folder Rules

### `src/core/`

This folder is for reusable engine-facing code:
- grid coordinates
- movement resolution
- occupancy maps
- main scene bootstrapping
- shared enums and constants

Code here should be reusable across multiple levels.

### `src/gameplay/`

This folder is for concrete game rules and actors:
- player
- rolling boxes
- enemies
- buttons
- doors
- energy sockets
- terrain interactables

If a script only makes sense because this game has rolling boxes, it belongs
here, not in `src/core/`.

### `src/levels/`

Each level should be a scene, not a hardcoded array inside one giant script.
Keep shared level markers and helpers in `src/levels/shared/`, then put actual
tutorial maps in `src/levels/tutorial/`.

### `src/ui/`

UI should read game state and show it. It should not own puzzle rules.

### `assets/`

Use this folder for imported content and stable data assets:
- meshes
- textures
- fonts
- sound
- later: `.tres` data resources

Do not hide rule logic in `assets/`.

## Scene vs Script Rules

Use this beginner rule of thumb:

- If something exists in the world and can be instanced in a level, make it a scene.
- If something is reusable logic with no standalone presence, make it a script or resource.

Examples:

- `player.tscn` + `player.gd`: scene
- `rolling_box.tscn` + `rolling_box.gd`: scene
- `grid_coord.gd`: script
- `box_face_rules.gd`: script or resource
- `level_01.tscn`: scene

This follows Godot's general guidance that scenes are more than a visual group;
they are reusable units of structure and behavior.

## First Playable File List

Create these files first, in this order:

1. `project.godot`
2. `src/core/main/Main.tscn`
3. `src/core/main/main.gd`
4. `src/core/grid/grid_coord.gd`
5. `src/core/grid/grid_motor.gd`
6. `src/gameplay/player/player.tscn`
7. `src/gameplay/player/player.gd`
8. `src/gameplay/boxes/rolling_box.tscn`
9. `src/gameplay/boxes/rolling_box.gd`
10. `src/gameplay/interactables/buttons/floor_button.tscn`
11. `src/gameplay/interactables/doors/sliding_door.tscn`
12. `src/levels/shared/level_root.gd`
13. `src/levels/tutorial/level_01.tscn`

Do not start by building menus, save systems, or content pipelines.

## Implementation Rules for This Project

### Rule 1: Gameplay state is authoritative

The source of truth is grid state and orientation data, not the transform that
happens to be visible mid-animation.

Good:
- update logical box orientation
- then animate the box to match it

Bad:
- read the current mesh transform and guess the logical state from it

### Rule 2: One object, one owner

Each gameplay object should own its own local behavior.

Examples:
- the box script knows its current top face
- the button script knows whether it is pressed
- the door script knows whether it is open

Avoid one giant `level.gd` script that manually handles every object type.

### Rule 3: Export references, do not crawl the tree

Prefer explicit references in the editor:

```gdscript
@export var target_door: Node3D
```

or local unique child lookups inside the same scene.

Avoid fragile paths like:

```gdscript
get_node("../../Door")
```

### Rule 4: Levels compose mechanics, not rewrite them

Level scripts may define layout and goals, but they should not redefine how
boxes, buttons, or enemies work.

### Rule 5: Keep data simple until the mechanic works

For the first prototype:
- hardcoded enums are acceptable
- one box type is enough
- one enemy type is enough

Only introduce `.tres` data resources once the core loop feels correct.

## What Not To Build Yet

Do not add these in the first pass:
- save/load system
- localization pipeline
- fancy inventory
- procedural generation
- full physics-based puzzles
- cinematic camera system
- plugin-heavy workflows

Every one of these would slow learning and delay the first proof that the box
mechanic is fun.

## Milestone Recommendation

### Milestone 1: Graybox Prototype

Ship one playable level with:
- player movement
- one rolling box
- one button
- one door
- restart level

### Milestone 2: Mechanic Proof

Add:
- top-face UI
- one normal enemy
- one heavy switch
- three tutorial levels

### Milestone 3: Teaching Arc

Add:
- heavy enemy
- energy socket
- all first five tutorial levels
- basic polish for feedback clarity

## Success Criteria

The architecture is working if:
- you can add a new level without touching box rules
- you can change button behavior without touching player movement
- the same rolling box scene works in every tutorial level
- failures are explainable from the visible state of the board
