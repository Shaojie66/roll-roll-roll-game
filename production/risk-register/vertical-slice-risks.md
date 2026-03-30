# Vertical Slice Risks (Milestone 02)

## Active Risks

| ID | Risk | Probability | Impact | Trigger to Watch | Mitigation | Owner | Status |
|----|------|------------|--------|------------------|------------|-------|--------|
| R-VS-01 | Conveyor belt boxes can desync if player pushes during tick | Medium | Medium | Box fails to move while player keeps pushing | Conveyor checks is_busy before pushing; design constraint: player not on conveyor cell | Gameplay Programmer | Mitigated — is_busy check prevents double-push |
| R-VS-02 | Rotating platform + conveyor combo causes boxes to skip cells | Low | High | Box appears to teleport over a cell | Each terrain uses GridMotor entity_move_finished signal; verify ordering in test | QA | Open |
| R-VS-03 | Multi-box (L13) grid registration conflicts | Medium | High | Two boxes at same cell crash or one disappears | GridMotor.register_entity checks occupancy before adding; test L13 carefully | Gameplay Programmer | Open |
| R-VS-04 | Factory theme levels (L6-12) not playtested — mechanics may be wrong | High | High | Level cannot be solved with intended mechanics | Manual review of each level solution path; GUT tests cover terrain mechanics | Level Designer | Open |
| R-VS-05 | AudioManager calls cause runtime errors in headless/CI | Low | Medium | Godot headless autoload not present | All AudioManager calls wrapped with null guard (fixed in audit) | All | Mitigated — null guards added |
| R-VS-06 | Terrain glow animation causes 60fps drop on low-end hardware | Low | Medium | Tween per-actor causes GC pressure | Tween is short (0.2s) and one-shot; should be fine | Technical Artist | Open |
| R-VS-07 | Extended tutorial levels (L13, L14) not designed for current implementation | Medium | Medium | Level 13/14 may have mechanics that don't match current box behavior | Check initial_top_face export works for both boxes; verify enemy defeat in L14 | Level Designer | Open |
| R-VS-08 | Scoring system deferred — UI/HUD polish blocked | High | Low | S3-019 cannot complete until S3-010 | UI polish can proceed without scoring; S3-019 is deferred | UI Artist | Deferred |

## Review Notes

- Milestone 02 Vertical Slice: Sprint 5 status
- Terrain implementation complete: S3-005/006/007 ✅
- Level implementation complete: L1-14 ✅
- Visual polish (terrain): S3-018 ✅
- Extended tutorial: S3-016 ✅
- Audit fixes: P1 AudioManager guards, public API, timing constants ✅
- Playtest 002 pending: S3-020
- Scoring UI deferred: S3-010 (VS+)
- Next update: After Playtest 002 results
