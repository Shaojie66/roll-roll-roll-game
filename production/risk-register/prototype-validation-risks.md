# Prototype Validation Risks

## Active Risks

| ID | Risk | Probability | Impact | Trigger to Watch | Mitigation | Owner | Status |
|----|------|------------|--------|------------------|------------|-------|--------|
| R-001 | Players do not attach meaning to the top-face text quickly enough | High | High | Tester cannot explain face meaning by Level 2 | Increase readability and reduce label ambiguity after Playtest 001 | UX Designer | Open |
| R-002 | Silent blocked pushes are interpreted as engine bugs | High | High | Tester says "it did not work" without explaining why | Add explicit blocked-action feedback and retest | Gameplay Programmer | Open |
| R-003 | Level 5 requires too much route inference for a first-time player | Medium | High | Tester solves earlier levels but stalls in Level 5 for more than 3 minutes | Rework route layout and final objective signaling | Level Designer | Open |
| R-004 | Empty automated test coverage slows iteration and hides regressions | Medium | Medium | A later fix breaks an earlier level unnoticed | Add minimal rule coverage in Sprint 1 | Lead Programmer | Open |

## Review Notes

- First review date: 2026-03-24
- Next update source: `production/playtests/playtest-001-report-template.md`
