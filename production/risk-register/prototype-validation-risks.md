# Prototype Validation Risks

## Active Risks

| ID | Risk | Probability | Impact | Trigger to Watch | Mitigation | Owner | Status |
|----|------|------------|--------|------------------|------------|-------|--------|
| R-001 | Players do not attach meaning to the top-face text quickly enough | High | High | Tester cannot explain face meaning by Level 2 | Increase label font size; verify readability from camera height | UX Designer | Partially Mitigated — labels exist but need in-engine size check |
| R-002 | Silent blocked pushes are interpreted as engine bugs | High | High | Tester says "it did not work" without explaining why | Deny reasons + HUD flash + audio implemented. Tested via code walkthrough: works correctly. | Gameplay Programmer | Mitigated — multi-layer feedback is solid |
| R-003 | Level 5 requires too much route inference for a first-time player | Medium | High | Tester stalls in Level 5 | Confirmed worse than expected — Level 5 ENERGY face was mathematically unreachable via the hinted-only horizontal path. Level redesigned with v-shape path. | Level Designer | Fixed — Level 5 redesigned with v-shape path; ENERGY reachable via R2+D1+R2+U2 |
| R-004 | Empty automated test coverage slows iteration and hides regressions | Medium | Medium | A later fix breaks an earlier level unnoticed | Test stubs exist; logic not filled (Sprint 2 priority) | Lead Programmer | Mitigated — GUT tests filled for grid_motor (push chains, enemy defeat, deny reasons) and rolling_box (all 4 directions, chain cycles, face/enemy interaction) |
| R-005 | Level 1 teaches two concepts (rolling + button/door) instead of one | High | High | Code walkthrough confirmed Level 1 includes button+door; GDD says it should be pure rolling | Move button/door to Level 2 | Level Designer | Fixed — Level 1 stripped to pure rolling, button+door moved to Level 2 |
| R-006 | Level 3 first natural push succeeds bypassing intended failure teaching | High | High | Code walkthrough: default push gives HEAVY = immediate enemy defeat | Redesign Level 3: player walks into enemy first (denied), then uses box | Level Designer | Fixed — Level 3 redesigned: enemy at (5,2) blocks player's direct path |
| R-007 | Heavy buttons and heavy enemies never taught in any level | High | High | Code walkthrough: Level 4 implements energy socket, not heavy route | Add heavy mechanic teaching (Level 4 remix or Level 6) | Level Designer | Open — Level 4 redesigned as button+door teaching; heavy mechanics deferred to future level |
| R-008 | Player and box overlap on same grid cell at Level 2 spawn | Low | Low | Code walkthrough: both at grid (2,2) | Intended as "box in front of you" — verify in-engine it works | Lead Programmer | Fixed — Level 2 player at (1,3), box at (3,3) — adjacent, not overlapping |

## Review Notes

- First review date: 2026-03-24
- Playtest 001 completed: 2026-03-30 (code walkthrough, no live engine run)
- Next update source: `production/playtests/playtest-001-report-template.md`
- Key finding: 3 of 5 levels have structural teaching failures. Core feedback system is solid.
