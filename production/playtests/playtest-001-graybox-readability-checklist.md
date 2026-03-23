# Playtest 001 Checklist - Graybox Teaching Arc

## Purpose

Validate the readability of the first five tutorial levels in the current
graybox build of `玩具星港：滚滚滚`.

Primary questions:
- Does the player understand that rolling changes the box state?
- Can the player tell why a push succeeds or fails?
- Does Level 5 clearly communicate that one box must be reused for multiple jobs?

## Session Setup

- Tester should not receive a verbal explanation of the mechanics before starting.
- Start from the main scene and play levels in order.
- Facilitator may only intervene if the tester is stuck for more than 3 minutes.
- Capture timestamps for first confusion, first restart, and level completion.
- Record exact wording the tester uses when describing the box faces.

## Global Checks

- [ ] Tester understands movement controls without help.
- [ ] Tester notices the top-face label on the box.
- [ ] Tester understands the restart shortcut (`R`).
- [ ] Tester can tell the difference between wall, door, enemy, button, and socket states.
- [ ] Failed actions are interpreted as understandable rules rather than bugs.
- [ ] Camera angle keeps the active route readable.

## Level-by-Level Checklist

### Level 1 - Rolling Awareness

- [ ] Tester notices that the box rolls instead of sliding.
- [ ] Tester notices that the top-face text changes after a push.
- [ ] Tester reaches the exit without facilitator help.

Questions to ask after completion:
- "What changed when the box moved?"
- "What do you think the word on top of the box means?"

### Level 2 - Hold the Door Open

- [ ] Tester realizes the box must stay on the button.
- [ ] Tester understands the door closes again when the box leaves.
- [ ] Tester reaches the exit without being told to "leave the box behind."

Questions to ask after completion:
- "Why did the door open?"
- "What would make it close again?"

### Level 3 - Normal Enemy Rule

- [ ] Tester notices the enemy blocks the path.
- [ ] Tester understands that not every top face defeats the enemy.
- [ ] Tester can explain why the winning push worked.

Questions to ask after completion:
- "Why did that hit work?"
- "What would make the push fail?"

### Level 4 - Heavy Rule

- [ ] Tester understands that the armored enemy is different from the normal enemy.
- [ ] Tester connects the heavy switch and heavy enemy to the same face rule.
- [ ] Tester identifies the heavy face without trial-and-error frustration dominating the session.

Questions to ask after completion:
- "What made this enemy different?"
- "What does the square switch teach that the earlier button did not?"

### Level 5 - One Box, Three Jobs

- [ ] Tester understands the first job is opening the door.
- [ ] Tester attempts to reuse the same box instead of assuming a second box exists.
- [ ] Tester realizes the enemy must be cleared before the final energy step.
- [ ] Tester understands the goal pad is unpowered until the socket is filled.
- [ ] Tester completes the level or clearly explains the missing logic step.

Questions to ask after completion:
- "List the three jobs the box had to do."
- "Which step was least obvious?"
- "Did any failure feel unfair or unreadable?"

## Observation Rubric

Use this severity scale for issues:
- **High**: blocks progress or causes the mechanic to be misunderstood
- **Medium**: progress continues, but player confidence drops
- **Low**: cosmetic, pacing, or polish issue that does not block understanding

## Exit Interview

- [ ] Ask the tester to describe the game loop in one sentence.
- [ ] Ask which level taught the clearest lesson.
- [ ] Ask which level felt the most confusing.
- [ ] Ask whether the box states felt memorable or arbitrary.
- [ ] Ask whether they would play a harder version of this puzzle arc.

## Artifacts to Save

- Completed report in `production/playtests/playtest-001-report-template.md`
- Any bug or confusion notes added to `production/risk-register/prototype-validation-risks.md`
- Follow-up action items copied into the active sprint plan
