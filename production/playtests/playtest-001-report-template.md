# Playtest 001 Report

> **Method**: Code walkthrough — reconstructed grid layouts from .tscn scenes,
> simulated all box orientation state transitions, traced player paths through
> grid_motor logic. No live engine run. Findings are structural/design-level,
> not live-player-behavior-level.

## Session Info

- **Date**: 2026-03-30
- **Build**: `main` @ a622e5c
- **Duration**: N/A (code walkthrough)
- **Tester**: Claude Code (no live play)
- **Platform**: PC
- **Input Method**: N/A
- **Session Type**: Structural code audit + simulation

## Test Focus

Validate readability of the five-level graybox tutorial arc, with emphasis on:
- top-face readability (Label3D visibility from overhead camera)
- failed push clarity (deny reasons, HUD feedback, audio)
- button / enemy / socket teaching sequence
- Level 5 "one box, three jobs" payoff

## First Impressions (First 5 minutes)

- **Understood the goal?** Yes — from code inspection: push box, manipulate faces, reach goal
- **Understood the controls?** Yes — WASD/arrows, R to restart
- **Emotional response**: Concern
- **Notes**: 3 of 5 levels have structural teaching failures identified through orientation math tracing and path analysis. The feedback system (deny reasons, HUD flash, audio) is well-implemented. The issues are in level layouts, not in the core mechanics.

## Gameplay Flow

### What worked well

- Multi-layered deny feedback (HUD text + player body flash + audio) is excellent
- Box face labels use Chinese with icon prefixes — readable if label size is adequate
- Checkerboard floor + grid lines make cell boundaries clear from overhead camera
- Tutorial arc from code covers all 4 face types and all 4 interactable types
- Audio integration on all interactions (button press/release, door open/close, socket activate, goal activate, enemy defeat) is complete

### Pain points

- **P1 — High**: Level 1 mixes Level 1 + Level 2 teaching. The GDD says Level 1 should be "pure rolling awareness" but the implementation has a button + door. A first-time player gets three concepts at once.
- **P2 — High**: Level 3's first push succeeds. The player's obvious move (push box toward enemy) results in HEAVY face on top, which defeats the normal enemy. The player never experiences a failed push — which is the entire teaching point of Level 3.
- **P3 — High**: Level 5 has a critical math error. The hint says "push right to make ENERGY face activate the socket" but purely horizontal pushes cycle NORMAL_A → IMPACT_A → NORMAL_B → IMPACT_B and never produce ENERGY on top. ENERGY is on the back face and requires a vertical push to rotate to top. The stated solution does not work.
- **P4 — Medium**: Level 2 places player and box on the same grid cell at spawn (grid (2,2) = world (4,4)). GridMotor's register will warn about overwriting. Mechanically this means any first move pushes the box, but it's a confusing visual.
- **P5 — Medium**: Level 4's GDD concept ("重货通道" = Heavy Route) does not match the implementation ("能源供给" = Energy Supply). The heavy button + heavy enemy teaching point is missing entirely from the 5-level arc.
- **P6 — Medium**: Level 5 hint text spells out the entire solution ("先开门，再清掉机器人，最后用 ENERGY 顶面给出口供能") removing all discovery. In a real playtest, a player would follow the hint without understanding why.

### Confusion points

- Level 2 player/box initial overlap: intentional or bug?
- Level 3 first-move-success: how does player learn face-dependent defeat?
- Level 5 ENERGY unreachable: is the level actually solvable?
- Level 4 heavy mechanic missing: where are heavy buttons and heavy enemies taught?

### Moments of delight

- Deny feedback is genuinely well-layered (text + flash + audio)
- Face label color-coding (blue=normal, purple=impact, orange=heavy, cyan=energy) is a strong visual system
- The 6-face orientation state machine is correct and elegant

## Bugs Encountered

| # | Description | Severity | Reproducible |
|---|-------------|----------|-------------|
| B1 | Level 5 ENERGY face is unreachable via the hinted-only horizontal corridor push strategy | Critical | Yes — orientation math |
| B2 | Level 2 player and box overlap on same grid cell at spawn | Low | Yes — scene inspection |
| B3 | Level 4 scene name in main.gd ("能源供给") contradicts tutorial-arc.md ("重货通道") | Low | Yes — doc vs code mismatch |
| B4 | `light_energy` declared twice in Level 02.tscn and Level 05.tscn DirectionalLight nodes (second assignment wins) | Low | Yes — .tscn inspection |
| B5 | Level 01.tscn contains a NormalEnemy reference (id="5") that is NOT placed in the scene tree — just a loaded resource. The floor warning disc exists but no enemy in Level 1. | Low | Yes — scene inspection |

## Feature-Specific Feedback

### Rolling Box Readability

- **Understood purpose?** Yes — face labels are clear, color coding is strong
- **Found engaging?** Yes — orientation state machine is elegant
- **Suggestions**: Label3D size should be verified in-engine from default camera height (18 units, ~60-degree angle). A 3D label on a small cube may be hard to read at that distance. Consider increasing font size or adding a floating UI indicator above the camera view.

### Failed Push Feedback

- **Understood purpose?** Yes — deny reasons are specific and actionable
- **Found readable?** Yes — multi-layered (HUD text + body flash + audio)
- **Suggestions**: None — the feedback system is well-designed and implemented

### Level 5 Multi-Use Box

- **Understood purpose?** Partially — the intent is clear but the execution is broken
- **Found engaging?** No — the corridor layout reduces "three jobs" to "push right repeatedly"
- **Suggestions**: Redesign Level 5 layout to force at least one vertical push, so ENERGY can become the top face. The current hint text also spells out the entire solution — consider removing the step-by-step enumeration.

## Quantitative Data

- **Restarts**: N/A (code walkthrough)
- **Time per level**: L1 ~2min, L2 ~3min, L3 ~4min, L4 ~4min, L5 ~6min (estimated)
- **Hints needed**: L1 hint too verbose, L3 hint ambiguous, L4 correct, L5 too explicit
- **Features discovered vs missed**: Heavy buttons and heavy enemies are never introduced in any level (design gap)

## Overall Assessment

- **Would play again?** Yes — core mechanics are solid and engaging
- **Difficulty**: Just Right (for Levels 2-4), Too Easy (L1, L3), Broken (L5)
- **Pacing**: Good — each level is short and focused
- **Session length preference**: Good

## Top 3 Priorities from this Session

1. **Fix Level 5 ENERGY math** — the level must be verified as solvable, or redesigned with a layout that forces a vertical push to reach ENERGY face
2. **Separate Level 1 teaching** — move button/door to Level 2 so Level 1 teaches only "rolling changes face"
3. **Redesign Level 3 first-move** — ensure the player's first natural push fails (wrong face), so they experience the deny feedback and learn to read the face before succeeding

## Design-Intent Conflicts

- **Conflict 1**: Tutorial arc doc says Level 1 = pure rolling awareness (no button/door). Implementation = button + door included. First-time player gets 3 concepts instead of 1.
- **Conflict 2**: Tutorial arc doc says Level 4 = "重货通道" (heavy button + heavy enemy). Implementation = energy socket. Heavy buttons/enemies never taught.
- **Conflict 3**: Tutorial arc doc says Level 5 = spatial "one box, three jobs" puzzle. Implementation = linear corridor. The spatial reasoning component is removed.
- **Conflict 4**: Design pillar "滚动就是解谜" (rolling IS the puzzle) vs Level 5 where rolling is just navigation, not puzzle-solving.

## Verdict

- **Recommendation**: **Rework** (3 of 5 levels)
- **Reasoning**: The core feedback systems (deny reasons, audio, visual states) are well-built and ready. The issues are purely in level layouts and their teaching effectiveness. Level 5 has a critical math error (ENERGY unreachable), Level 1 teaches two lessons instead of one, and Level 3's first-move-succeeds bypasses the intended failure-based teaching. Fix these three before any external playtest.
- **Immediate Next Actions**:
  1. Redesign Level 5 layout so ENERGY face is reachable; verify orientation math before shipping
  2. Remove button+door from Level 1, restore Level 1 to pure rolling-only
  3. Redesign Level 3 so first push uses NORMAL face (wrong), forcing player to experience deny feedback
  4. Add heavy button + heavy enemy to the tutorial arc (either Level 4 or Level 5 remix)
  5. Run a real external playtest after structural fixes are applied
