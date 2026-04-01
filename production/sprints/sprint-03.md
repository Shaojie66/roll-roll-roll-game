# Sprint 3 -- 2026-04-06 to 2026-04-19

## Sprint Goal

Complete terrain mechanism validation in-engine, close Sprint 2 residual
tasks (live regression + external playtest), and audit all existing GDDs
against the 8-section standard before beginning level expansion.

## Milestone Context

- **Current Milestone**: Vertical Slice (M02)
- **Milestone Deadline**: 2026-05-31
- **Sprints Completed**: 2
- **Planning Assumption**: Solo developer wearing multiple hats across programming, design, and QA

## Sprint 2 Retrospective (Inline)

| Metric | Value |
|--------|-------|
| Must Have completed | 4/5 (S2-001, S2-002, S2-004, S2-005) |
| Must Have partial | 1/5 (S2-003 — live regression pending) |
| Should Have completed | 3/3 (S2-010, S2-011, S2-012) |
| Nice to Have completed | 1/3 (S2-021) |
| Nice to Have partial | 1/3 (S2-020 — external tester playtest) |

**Key insight**: Automated test velocity was strong (44/44 tests in Sprint 2).
Design documentation writing completed ahead of schedule. Live regression
testing and external playtest remain as residual from Sprint 2 — both are
low-complexity tasks that just need dedicated engine time.

## Capacity

| Resource | Available Days | Allocated | Buffer (20%) | Remaining |
|----------|---------------|-----------|-------------|-----------|
| Programming | 5.0 | 4.0 | 1.0 | 0.0 |
| Design | 2.0 | 1.6 | 0.4 | 0.0 |
| Art | 0.5 | 0.0 | 0.5 | 0.0 |
| Audio | 0.0 | 0.0 | 0.0 | 0.0 |
| QA | 2.5 | 2.0 | 0.5 | 0.0 |
| Level Design | 1.0 | 0.8 | 0.2 | 0.0 |
| **Total** | **11.0** | **8.4** | **2.6** | **0.0** |

## Tasks

### Must Have (Critical Path)

| ID | Task | Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------|-----------|-------------|-------------------|--------|
| S3-001 | Live engine regression — all 5 tutorial levels pass in Godot | User | 0.5 | None | Run each level in engine; verify win condition, box behavior, enemy defeat, button/door interaction | **Pending** |
| S3-002 | Terrain GDD audit — verify all 8 required sections present | Game Designer | 0.5 | None | `design/gdd/systems/terrain-system.md` passes 8-section checklist | **✅ DONE** |
| S3-003 | Terrain implementation verification — run all 8 terrain tests in-engine | Lead Programmer | 0.5 | None | `test_terrain.gd` 8/8 tests pass; ramp/conveyor/rotating platform behave per GDD spec | **Pending** |
| S3-004 | Expand terrain unit tests — add conveyor belt push, multi-box scenarios | QA/Lead Programmer | 1.0 | S3-003 | New tests for conveyor auto-push and multi-box terrain interactions; all pass | **✅ DONE** |
| S3-005 | External playtest (S2-020 residual) — fresh-eyes tester completes tutorial levels | User + Tester | 1.0 | S3-001 | Structured playtest report with confusion points, timing, and verdict | **Pending** |
| S3-006 | Enemy GDD audit — verify all 8 required sections present | Game Designer | 0.5 | None | `design/gdd/systems/enemy-system.md` passes 8-section checklist | **✅ DONE** |
| S3-007 | UI/HUD GDD audit — verify all 8 required sections present | Game Designer | 0.5 | None | `design/gdd/systems/ui-hud-system.md` passes 8-section checklist | **✅ DONE** |
| S3-008 | Theme Area selection — decide on first theme area (cave/ruins/factory) | User + Game Designer | 0.5 | None | Decision documented; rationale recorded; communicated to all agents | **✅ DONE** |

### Should Have

| ID | Task | Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------|-----------|-------------|-------------------|--------|
| S3-009 | Scoring System GDD — first draft if time permits | Game Designer | 1.0 | None | `design/gdd/systems/scoring-system.md` skeleton with 8 sections; formulas section at minimum | **✅ DONE** |
| S3-010 | Level design doc for theme area — high-level structure | Level Designer | 1.0 | S3-008 | `design/levels/theme-area-levels.md` with level count, teaching arc, difficulty curve | **Pending** |
| S3-011 | GUT test framework integration verification | Lead Programmer | 0.5 | S3-001 | GUT tests run from command line; results parseable by CI hook | **Pending** |

### Nice to Have (Cut First)

| ID | Task | Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------|-----------|-------------|-------------------|--------|
| S3-012 | Conveyor belt implementation — verify auto-push matches GDD spec | Lead Programmer | 0.5 | S3-002, S3-003 | Conveyor moves box 1 cell per player action; player cannot block | **Pending** |
| S3-013 | Rotating platform implementation — verify 90° rotation matches GDD | Lead Programmer | 0.5 | S3-002, S3-003 | Rotating platform rotates box 90° clockwise; visual animation synced | **Pending** |

## Carryover from Previous Sprint

| Original ID | Task | Reason for Carryover | New ID | New Estimate | Priority Change |
|------------|------|---------------------|--------|-------------|----------------|
| S2-003 | Live engine regression | Code-level regression done; in-engine testing not yet executed | S3-001 | 0.5 days | Must Have |
| S2-020 | External playtest | Internal self-test complete; external fresh-eyes test not scheduled | S3-005 | 1.0 days | Must Have |

## Risks

| Risk | Probability | Impact | Mitigation | Owner |
|------|------------|--------|-----------|-------|
| Terrain GDD fails 8-section audit — requires rewriting | Medium | Medium | Pre-audit checklist now; defer section-by-section if needed | Game Designer |
| Theme area choice causes scope creep | Medium | High | Timebox selection to 0.5 days; decision recorded with rationale | User |
| External tester unavailable | Low | Low | Continue with internal self-test; document limitation | User |
| Sprint 3 carries over to Sprint 4 | Medium | Medium | Prioritize Must Have tasks; defer Should Have to Sprint 4 | Producer |

## External Dependencies

| Dependency | Status | Impact if Delayed | Contingency |
|-----------|--------|------------------|-------------|
| External tester availability | Unknown | Lower external validation coverage | Internal self-test report is sufficient |
| Godot 4.6.1 editor access | Available | None — blocking | N/A |
| GUT addon for Godot 4.6.1 | Not verified in this project | S3-011 blocked | Write tests as standalone scene scripts |

## Dependencies on External Factors

- Theme area selection must be resolved before S3-010 can begin
- S3-002, S3-003 must pass before S3-004 can be meaningful
- S3-001 must pass before S3-005 can proceed (levels must be stable)

## Theme Area Decision (RESOLVED)

**Selected: Chinese Palace / 中国风皇宫** ✅

| Field | Value |
|-------|-------|
| Decision | Chinese Palace (皇宫) |
| Rationale | Unique visual identity, differentiates from Western factory aesthetic, strong color palette (red/gold), fits the toy/star harbor warehouse concept as an ancient celestial palace |
| Pros | Distinctive look, rich visual metaphors (imperial crates, magical orbs, throne mechanisms), strong brand identity |
| Cons | Requires new art assets (red/gold textures, lantern props, palace architecture); more work than factory but higher impact |
| Next Step | Update level design docs to reflect palace theme |

> **Decision gates**: S3-008 and S3-010 can now proceed.
> **Asset implication**: New texture/theme may require Vidu generation for palace-style UI and backgrounds.

## Definition of Done

- [ ] S3-001: All 5 tutorial levels pass live regression in Godot engine
- [x] S3-002: Terrain GDD passes all 8-section requirements
- [ ] S3-003: All 8 terrain unit tests pass in-engine
- [x] S3-004: Expanded terrain tests pass (conveyor, multi-box)
- [ ] S3-005: External playtest report complete
- [x] S3-006: Enemy GDD passes all 8-section requirements
- [x] S3-007: UI/HUD GDD passes all 8-section requirements
- [x] S3-008: Theme area selected and documented
- [ ] No S1 or S2 bugs in delivered features
- [ ] Design documents updated for any deviations from spec
- [ ] `design/levels/factory-theme-levels.md` replaced with Chinese Palace version (S3-010)

## Daily Status Tracking

| Day | Date | Tasks Completed | Tasks In Progress | Blockers | Notes |
|-----|------|----------------|------------------|----------|-------|
| Day 1 | 04-06 | | | | |
| Day 2 | 04-07 | | | | |
| Day 3 | 04-08 | | | | |
| Day 4 | 04-09 | | | | |
| Day 5 | 04-10 | | | | |
| Day 6 | 04-11 | | | | |
| Day 7 | 04-12 | | | | |
| Day 8 | 04-13 | | | | |
| Day 9 | 04-14 | | | | |
| Day 10 | 04-15 | | | | |
| Day 11 | 04-16 | | | | |
| Day 12 | 04-17 | | | | |
| Day 13 | 04-18 | | | | |
| Day 14 | 04-19 | | | | |

---

## Open Questions to Resolve in Sprint 3

| # | Question | Impact | Who Decides | Deadline |
|---|----------|--------|------------|----------|
| OQ-01 | Theme area: Cave / Ruins / Factory? | High — gates all level design | ~~User~~ **RESOLVED: Chinese Palace** | Day 1 |
| OQ-02 | GUT addon integration — does it work with Godot 4.6.1 in this project? | Medium — affects test automation | Lead Programmer | Day 1 |
| OQ-03 | Terrain GDD Section 5 (Edge Cases) — are conveyor multi-box scenarios documented? | Medium — test coverage depends | Game Designer | Day 2 |
| OQ-04 | Does rolling box `apply_ramp_transform` method exist and match the GDD formula? | Medium — unit test validity | Lead Programmer | Day 1 |
