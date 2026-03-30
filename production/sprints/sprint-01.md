# Sprint 1 -- 2026-03-23 to 2026-04-05

## Sprint Goal

Use one structured playtest cycle to turn the current five-level graybox into a
readable, regression-checked prototype that is ready for a go/no-go decision on
full production.

## Milestone Context

- **Current Milestone**: Prototype Validation - Teaching Arc
- **Milestone Deadline**: 2026-04-05
- **Sprints Remaining**: 1
- **Planning Assumption**: Solo developer wearing multiple hats across programming, design, and QA

## Capacity

| Resource | Available Days | Allocated | Buffer (20%) | Remaining |
|----------|---------------|-----------|-------------|-----------|
| Programming | 6.0 | 4.8 | 1.2 | 0.0 |
| Design | 2.0 | 1.6 | 0.4 | 0.0 |
| Art | 0.5 | 0.0 | 0.5 | 0.0 |
| Audio | 0.0 | 0.0 | 0.0 | 0.0 |
| QA | 1.5 | 1.2 | 0.3 | 0.0 |
| **Total** | **10.0** | **7.6** | **2.4** | **0.0** |

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|-------------|-------------------|--------|
| S1-001 | Run Playtest 001 and fill the structured report | User + QA Tester | 0.5 | None | `production/playtests/playtest-001-report-template.md` is completed with findings and verdict | **Carryover** -- templates created, not yet executed |
| S1-002 | Improve box face readability and hint wording based on Playtest 001 | UI Programmer + UX Designer | 2.0 | S1-001 | A tester can identify the box's current role within 3 seconds in Levels 2-5 | **Done** -- DesignTokens, face labels, face panels, color-coded bodies |
| S1-003 | Add readable failed-action feedback for walls, wrong face, blocked door, and enemy mismatch cases | Gameplay Programmer | 2.0 | S1-001 | Blocked actions produce understandable feedback without changing deterministic rules | **Done** -- deny flash, HUD reason text, AudioManager deny SFX |
| S1-004 | Retune tutorial levels 3-5 based on confusion points from Playtest 001 | Level Designer | 2.0 | S1-001, S1-003 | Levels 3-5 remain solvable and the intended lesson order is clearer on replay | **Partial** -- levels built but no playtest-driven retuning |
| S1-005 | Create and execute one manual regression pass for the full tutorial arc | QA Tester | 1.0 | S1-002, S1-003, S1-004 | Regression checklist exists and all five levels pass once after fixes | **Carryover** -- blocked by S1-001 |

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|-------------|-------------------|--------|
| S1-010 | Add basic automated checks for box orientation and enemy interaction rules | Lead Programmer | 2.0 | S1-003 | Core grid-rule regressions are covered by a repeatable local test path | **Partial** -- test stubs created, not yet filled |
| S1-011 | Improve button, socket, and goal visual states with clearer icon/color language | UI Programmer | 1.5 | S1-002 | Interactable states are distinguishable without relying only on hint text | **Done** -- DesignTokens, status lights, state-dependent colors |

### Nice to Have (Cut First)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|-------------|-------------------|--------|
| S1-020 | Add an internal level-skip or quick-reload helper for repeated playtests | Tools Programmer | 0.5 | None | Developer can jump to any tutorial level without editing `main.gd` | Not Started |

## Carryover from Sprint 0

| Original ID | Task | Reason for Carryover | New Estimate | Priority Change |
|------------|------|---------------------|-------------|----------------|
| None | No previous sprint artifacts exist yet | First formal sprint in this repo | 0 | None |

## Risks to This Sprint

| Risk | Probability | Impact | Mitigation | Owner |
|------|------------|--------|-----------|-------|
| Playtest findings reveal a deeper teaching problem than a polish issue | Medium | High | Protect time for level retuning instead of adding new mechanics | Producer |
| No fresh tester is available during the sprint window | Medium | Medium | Run one internal pass immediately and schedule external feedback next | User |
| Fixing feedback clarity introduces regressions in early levels | Medium | Medium | Execute manual regression pass before calling sprint done | QA Tester |

## External Dependencies

| Dependency | Status | Impact if Delayed | Contingency |
|-----------|--------|------------------|-------------|
| Fresh tester availability | Needed | Lower confidence in readability claims | Use internal tester first, then hold milestone as conditional |
| Godot 4.6.1 runtime on dev machine | Ready | Manual validation blocked if runtime breaks | Keep headless smoke test as fallback sanity check |

## Definition of Done

- [ ] All Must Have tasks completed and passing acceptance criteria
- [ ] No S1 or S2 bugs in delivered features
- [ ] Code reviewed and merged to develop
- [ ] Design documents updated for any deviations from spec
- [ ] Test cases written and executed for all new features
- [ ] Asset naming and format standards met

## Daily Status Tracking

| Day | Tasks Completed | Tasks In Progress | Blockers | Notes |
|-----|----------------|------------------|----------|-------|
| Day 1 | | | | |
| Day 2 | | | | |
| Day 3 | | | | |
| Day 4 | | | | |
| Day 5 | | | | |
| Day 6 | | | | |
| Day 7 | | | | |
| Day 8 | | | | |
| Day 9 | | | | |
| Day 10 | | | | |
