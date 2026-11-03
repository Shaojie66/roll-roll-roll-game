# 系统索引 — 玩具星港：滚滚滚

> **Last Updated**: 2026-03-30
> **Source**: Code inventory + existing GDDs + ADRs

## Systems Overview

| # | System | GDD | ADR | Implementation | Key Files |
|---|--------|-----|-----|---------------|-----------|
| 1 | 滚动功能箱 (Rolling Utility Box) | ✅ Draft | — | ✅ Complete | `rolling_box.gd` (219 LOC) |
| 2 | 机关联动 (Interactables) | ✅ Draft | ADR-004 | ✅ Complete | `floor_button.gd`, `sliding_door.gd`, `energy_socket.gd`, `goal_pad.gd` |
| 3 | 网格引擎 (Grid Motor) | — | ADR-002 | ✅ Complete | `grid_motor.gd` (144 LOC) |
| 4 | 网格坐标 (Grid Coordinates) | — | — | ✅ Complete | `grid_coord.gd` |
| 5 | 玩家移动 (Player Movement) | — | — | ✅ Complete | `player.gd` (136 LOC) |
| 6 | 敌人系统 (Enemy System) | ✅ Draft | — | ✅ Partial | `normal_enemy.gd` (87 LOC), `normal_enemy.tscn`, `heavy_enemy.tscn` |
| 7 | 音频管理 (Audio Manager) | — | ADR-003 | ✅ Complete | `audio_manager.gd` (~750 LOC) |
| 8 | 关卡管理 (Level Management) | — | — | ✅ Complete | `main.gd` (489 LOC), `level_root.gd` (29 LOC) |
| 9 | 地形 (Terrain) | — | — | ⚠️ Partial | `wall_block.gd` (31 LOC); ramps/conveyors/pits planned |
| 10 | UI/HUD | — | — | ✅ Inline | Inline in `main.gd` + `main.tscn` |
| 11 | 设计令牌 (Design Tokens) | — | — | ✅ Complete | `design_tokens.gd` |

### Legend

- ✅ = Exists and reasonably complete for current stage
- ⚠️ = Exists but incomplete (only a subset of planned features)
- ⬜ = Missing entirely
- — = Not applicable or not yet created

## GDD Documents

| Document | Path | Status | Covers Systems |
|----------|------|--------|---------------|
| Game Concept | [`game-concept.md`](game-concept.md) | Draft | All (high-level) |
| Rolling Utility Box | [`rolling-utility-box.md`](systems/rolling-utility-box.md) | Draft | #1 Rolling Box, partial #6 Enemy |
| Interactables System | [`interactables-system.md`](systems/interactables-system.md) | Draft | #2 Interactables |
| Enemy System | [`enemy-system.md`](systems/enemy-system.md) | Draft | #6 Enemy |

## ADR Documents

| ADR | Path | Systems Covered |
|-----|------|----------------|
| ADR-002 | [`adr-002-grid-motor.md`](../../docs/architecture/adr-002-grid-motor.md) | #3 Grid Motor |
| ADR-003 | [`adr-003-audio-manager.md`](../../docs/architecture/adr-003-audio-manager.md) | #7 Audio Manager |
| ADR-004 | [`adr-004-interactable-signal-architecture.md`](../../docs/architecture/adr-004-interactable-signal-architecture.md) | #2 Interactables |

## Level Design Documents

| Document | Path | Status |
|----------|------|--------|
| Tutorial Arc (Level 1-5) | [`tutorial-arc-first-five-levels.md`](../levels/tutorial-arc-first-five-levels.md) | Draft |

## System Dependency Map

```text
                    ┌─────────────────┐
                    │   Main (Level    │
                    │   Management)    │
                    │   #8             │
                    └───────┬─────────┘
                            │ loads/manages
                    ┌───────▼─────────┐
                    │   LevelRoot     │
                    │   (per-level)   │
                    └───────┬─────────┘
                            │ contains
          ┌─────────┬───────┼───────┬──────────┐
          │         │       │       │          │
    ┌─────▼───┐ ┌───▼───┐ ┌▼──────┐│    ┌─────▼─────┐
    │ Player  │ │Rolling│ │Enemies││    │ Terrain   │
    │ #5      │ │ Box   │ │ #6    ││    │ #9        │
    └────┬────┘ │ #1    │ └───┬───┘│    └─────┬─────┘
         │      └───┬───┘     │    │          │
         │          │         │    │          │
         └────┬─────┴────┬────┘    │          │
              │          │         │          │
        ┌─────▼──────────▼─────────▼──────────▼─┐
        │         Grid Motor  #3                │
        │   (occupancy, movement, collision)     │
        └─────────────┬─────────────────────────┘
                      │ entity_move_finished signal
              ┌───────▼────────┐
              │ Interactables  │
              │ #2             │
              │ Buttons, Doors,│
              │ Sockets, Goals │
              └───────┬────────┘
                      │
              ┌───────▼────────┐
              │ Audio Manager  │
              │ #7             │
              └────────────────┘

  Shared utilities (no direct gameplay logic):
    ├── Grid Coordinates  #4  (coordinate math)
    └── Design Tokens     #11 (visual constants)
```

### Dependency Rules

- **Grid Motor (#3)** is the central hub — all spatial entities depend on it
- **Interactables (#2)** subscribe to Grid Motor signals; never polled
- **Rolling Box (#1)** is queried by Interactables (face kind) and Grid Motor (push chains)
- **Enemies (#6)** are queried by Grid Motor during push resolution
- **Audio Manager (#7)** is called directly by all gameplay systems (acceptable coupling at this scale)
- **Player (#5)** interacts only through Grid Motor; never touches interactables directly
- **Terrain (#9)** registers as grid blockers; no active behavior yet

## Documentation Priority Queue

| Priority | Task | Effort |
|----------|------|--------|
| ~~P0~~ | ~~Create Enemy System GDD~~ | Done — `enemy-system.md` created |
| P1 | Create Player Movement GDD | Small — 136 LOC, mostly documented in code |
| P2 | Create Level Management GDD | Medium — 489 LOC spanning loading, HUD, overlays |
| P3 | Create Terrain System GDD | Small — 31 LOC current, but post-MVP scope is large |
| P4 | Extract UI/HUD into separate GDD | Medium — currently inline in main.gd |
