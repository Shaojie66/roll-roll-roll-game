# Milestone: Prototype Validation - Teaching Arc

## Overview

- **Target Date**: 2026-04-05
- **Type**: Prototype
- **Duration**: 2 weeks
- **Number of Sprints**: 1

## Milestone Goal

Validate that the current five-level graybox tutorial arc teaches the rolling
box rules clearly enough to justify moving into structured production. At the
end of this milestone, the team should be able to answer whether the box-state
readability, failure feedback, and "one box, three jobs" payoff are working
without verbal coaching.

## Success Criteria

- [ ] At least 1 structured playtest report exists for the full five-level sequence
- [ ] A tester can explain the current top-face purpose by the end of Level 2
- [ ] Failed pushes and blocked actions surface readable feedback instead of silent failure
- [ ] Level 5 communicates the intended "reuse one box for multiple jobs" loop
- [ ] A manual regression checklist exists and has been executed once after fixes
- [ ] All S1 and S2 bugs resolved
- [ ] Performance within budget on target hardware
- [ ] Build stable for 3 consecutive days

## Feature List

### Must Ship (Milestone Fails Without These)

| Feature | Design Doc | Owner | Sprint Target | Status |
|---------|-----------|-------|--------------|--------|
| Five-level graybox tutorial arc | `design/levels/tutorial-arc-first-five-levels.md` | Lead Programmer + Game Designer | Sprint 1 | In Progress |
| Structured readability playtest kit | `design/gdd/game-concept.md` | Producer + QA Lead | Sprint 1 | Not Started |
| Feedback clarity pass for box states and failed actions | `design/gdd/systems/rolling-utility-box.md` | Gameplay Programmer + UI Programmer | Sprint 1 | Not Started |
| Manual regression plan for tutorial arc | `design/gdd/systems/rolling-utility-box.md` | QA Tester | Sprint 1 | Not Started |

### Should Ship (Planned but Cuttable)

| Feature | Design Doc | Owner | Sprint Target | Cut Impact | Status |
|---------|-----------|-------|--------------|-----------|--------|
| Basic automated checks for grid and box-state rules | `design/gdd/systems/rolling-utility-box.md` | Lead Programmer | Sprint 1 | Slower iteration and higher regression risk | Not Started |
| Clearer visual affordances for buttons, sockets, and goal state | `design/levels/tutorial-arc-first-five-levels.md` | UI Programmer + UX Designer | Sprint 1 | Readability debt remains for later milestones | Not Started |

### Stretch Goals (Only if Ahead of Schedule)

| Feature | Design Doc | Owner | Value Add |
|---------|-----------|-------|----------|
| Internal level-skip debug shortcut | `docs/architecture/godot-starter-architecture.md` | Tools Programmer | Faster iteration during repeated playtests |
| Fresh external tester pass | `design/gdd/game-concept.md` | Producer | Higher confidence before first production milestone |

## Quality Gates

| Gate | Threshold | Measurement Method |
|------|-----------|-------------------|
| Crash rate | < 1 per hour | Manual play session notes |
| Frame rate | > 60 FPS on dev machine | Godot profiler spot-check |
| Load time | < 5 seconds to first level | Manual timing |
| Critical bugs | 0 open S1 | Local bug list in playtest report |
| Major bugs | < 3 open S2 | Local bug list in playtest report |
| Test coverage | Manual regression checklist completed once | `production/playtests/` artifacts |

## Risk Register

| Risk | Probability | Impact | Mitigation | Owner | Status |
|------|------------|--------|-----------|-------|--------|
| Top-face text is visible but not intuitive enough | High | High | Validate with first-time tester before adding more mechanics | UX Designer | Open |
| Silent failed pushes are read as bugs, not rules | High | High | Add explicit feedback copy and replay the blocked cases | Gameplay Programmer | Open |
| Level 5 route is too opaque for a first read | Medium | High | Tune layout after playtest findings, not before | Level Designer | Open |
| No automated rule coverage causes regressions during polish | Medium | Medium | Add a small core-rule test pass during Sprint 1 | Lead Programmer | Open |

## Dependencies

### Internal Dependencies

| Feature | Depends On | Owner of Dependency | Status |
|---------|-----------|-------------------|--------|
| Playtest report | Stable five-level build | Lead Programmer | Ready |
| Feedback clarity pass | Playtest findings | QA Lead | Pending |
| Regression checklist execution | Feedback fixes landed | Gameplay Programmer | Pending |

### External Dependencies

| Dependency | Provider | Status | Risk if Delayed |
|-----------|---------|--------|----------------|
| One fresh tester session | User / friend / collaborator | Needed | Lower confidence in readability claims |
| Godot 4.6.1 editor runtime | Local machine | Ready | Blocks manual validation if editor setup breaks |

## Review Schedule

| Date | Review Type | Attendees |
|------|-----------|-----------|
| 2026-03-24 | Early progress check | Producer, Lead Programmer |
| 2026-03-29 | Mid-milestone review | User, Game Designer, QA Lead |
| 2026-04-03 | Pre-milestone review | User, Lead Programmer, QA Lead |
| 2026-04-05 | Milestone review | User |
