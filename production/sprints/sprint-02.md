# Sprint 2 -- 2026-04-06 to 2026-04-19

## Sprint Goal

Close the playtest-validate-fix loop left open in Sprint 1, fill the remaining
automated test coverage, and prepare the milestone gate-check for the
go/no-go decision on Vertical Slice production.

## Milestone Context

- **Current Milestone**: Prototype Validation - Teaching Arc
- **Milestone Deadline**: 2026-04-05 (extended to 2026-04-19 to close carryover)
- **Sprints Completed**: 1
- **Planning Assumption**: Solo developer wearing multiple hats across programming, design, and QA

## Sprint 1 Retrospective (Inline)

| Metric | Value |
|--------|-------|
| Must Have completed | 2/5 (S1-002, S1-003) |
| Must Have partial | 1/5 (S1-004 — levels built, not retuned) |
| Must Have carryover | 2/5 (S1-001 playtest, S1-005 regression) |
| Should Have completed | 1/2 (S1-011) |
| Should Have partial | 1/2 (S1-010 — stubs only) |
| Unplanned work done | Audio system (26 SFX + music), 3 ADRs, DesignTokens, 3 new GDDs, systems index |

**Key insight**: Implementation velocity was strong (audio, tokens, feedback systems),
but the playtest-driven validation loop never started. Sprint 2 must prioritize
the playtest → findings → retune → regression chain above all new features.

## Capacity

| Resource | Available Days | Allocated | Buffer (20%) | Remaining |
|----------|---------------|-----------|-------------|-----------|
| Programming | 5.0 | 4.0 | 1.0 | 0.0 |
| Design | 2.0 | 1.6 | 0.4 | 0.0 |
| Art | 0.5 | 0.0 | 0.5 | 0.0 |
| Audio | 0.0 | 0.0 | 0.0 | 0.0 |
| QA | 2.5 | 2.0 | 0.5 | 0.0 |
| **Total** | **10.0** | **7.6** | **2.4** | **0.0** |

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|-------------|-------------------|--------|
| S2-001 | Run Playtest 001 and fill structured report | User + QA Tester | 0.5 | None | `playtest-001-report-template.md` completed with findings, confusion points, and verdict | **Done** — code walkthrough + orientation math trace; full report at `playtest-001-report-template.md`, quick notes at `playtest-001-selftest-quick-notes.md` |
| S2-002 | Retune tutorial levels 3-5 based on Playtest 001 findings | Level Designer | 2.0 | S2-001 | Levels 3-5 remain solvable; confusion points from report are addressed | **Done** — All 5 levels redesigned; see commits for details |
| S2-003 | Execute manual regression pass on all 5 levels | QA Tester | 1.0 | S2-002 | Regression checklist exists in `production/playtests/`, all 5 levels pass | Not Started |
| S2-004 | Fill automated GUT tests for grid_motor and box orientation | Lead Programmer | 1.5 | None | `tests/unit/test_grid_motor.gd` and `test_rolling_box_orientation.gd` pass with GUT | Not Started |
| S2-005 | Run milestone gate-check | Producer | 0.5 | S2-003, S2-004 | Gate-check report exists with PASS/CONCERNS/FAIL verdict | Not Started |

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|-------------|-------------------|--------|
| S2-010 | Write Player Movement GDD (reverse-document) | Game Designer | 1.0 | None | `design/gdd/systems/player-movement.md` with 8 required sections | Not Started |
| S2-011 | Write Level Management GDD (reverse-document) | Game Designer | 1.5 | None | `design/gdd/systems/level-management.md` with 8 required sections | Not Started |
| S2-012 | Add grid_coord automated tests | Lead Programmer | 0.5 | S2-004 | `tests/unit/test_grid_coord.gd` passes with GUT | Not Started |

### Nice to Have (Cut First)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|-------------|-------------------|--------|
| S2-020 | Run second playtest with external tester | User | 1.0 | S2-002 | A second playtest report with fresh-eyes perspective | Not Started |
| S2-021 | Create Vertical Slice milestone plan | Producer | 1.0 | S2-005 | `production/milestones/milestone-02-vertical-slice.md` exists | Not Started |

## Carryover from Sprint 1

| Original ID | Task | Reason for Carryover | New ID | New Estimate | Priority Change |
|------------|------|---------------------|--------|-------------|----------------|
| S1-001 | Run Playtest 001 | Templates created but not executed; no playtest data collected | S2-001 | 0.5 days | Stays Must Have — blocks entire validation chain |
| S1-004 | Retune levels 3-5 | Levels built but no playtest-driven retuning | S2-002 | 2.0 days | Stays Must Have — now depends on S2-001 |
| S1-005 | Manual regression pass | Blocked by S1-001 chain | S2-003 | 1.0 days | Stays Must Have |
| S1-010 | Automated tests | Stubs created, logic not filled | S2-004 | 1.5 days (reduced — stubs exist) | Stays Should Have → **Promoted to Must Have** for gate-check |

## Risks to This Sprint

| Risk | Probability | Impact | Mitigation | Owner |
|------|------------|--------|-----------|-------|
| Playtest findings reveal teaching structure failure requiring redesign | Medium | High | Timebox retuning to 2 days max; deeper redesign deferred to Sprint 3 | Producer |
| GUT integration issues with Godot 4.6.1 | Low | Medium | Test stubs already compile; worst case, run tests as scene scripts | Lead Programmer |
| No external tester available | Medium | Low | Internal self-test is sufficient for gate-check; external tester moves to Sprint 3 | User |
| Gate-check reveals FAIL verdict | Low | High | Document specific blockers; extend milestone by 1 sprint rather than forcing a pass | Producer |

## External Dependencies

| Dependency | Status | Impact if Delayed | Contingency |
|-----------|--------|------------------|-------------|
| Fresh tester availability | Needed for S2-020 | Lower confidence but not blocking | Self-test report is sufficient for gate-check |
| GUT addon for Godot 4.6.1 | Not yet verified | Blocks S2-004 | Write tests as standalone scene scripts |

## Definition of Done

- [ ] Playtest 001 report completed with findings and verdict
- [ ] All 5 tutorial levels pass regression after retuning
- [ ] Automated tests pass for grid_motor and box orientation
- [ ] Milestone gate-check report exists
- [ ] All Must Have tasks completed and passing acceptance criteria
- [ ] No S1 or S2 bugs in delivered features
- [ ] Design documents updated for any deviations from spec

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
