# Playtest 001 Self-Test Quick Notes

## How to Use

- Open this file beside the game while you play.
- Do not explain the rules to yourself in advance.
- When you get confused or fail, write the exact thought you had in that moment.
- Prefer short notes over polished summaries.
- After finishing, copy the important findings into `playtest-001-report-template.md`.

## Session Info

- **Date**: 2026-03-30
- **Build**: `main` @ a622e5c
- **Tester**: Code walkthrough (no live engine run)
- **Goal**: Check readability, failed-action clarity, and Level 5 multi-use box teaching
- **Method**: Reconstructed grid layouts from .tscn, simulated box orientation math,
  traced all possible player paths through grid_motor logic

## Global Quick Checks

- [x] I could tell what the box's top face was without stopping to decode it.
  - **Note**: Face label uses Chinese text ("● 普通", "◆ 冲击", "■ 重压", "★ 能源") + color-coded body. Readable if font is large enough on the box mesh. **Risk**: Label3D on a small 3D cube may be hard to read from the default camera height (18 units up, ~60-degree angle).
- [x] I could usually tell why a move failed.
  - **Note**: Deny reasons are in Chinese ("被阻挡", "普通 顶面打不过敌人", etc.). Good. HUD hint label flashes red. Player body flashes red. Audio plays. Multi-layered feedback is strong.
- [ ] I could tell when a door, socket, or goal changed state.
  - **Concern**: Doors slide vertically (open_offset Y=2.2) which is correct. But energy socket state change is only scale 1.0→1.18 + color shift — may be too subtle from 18 units above. Goal pad ring scale 0.82→1.0→1.25 is similarly subtle at distance.
- [x] The camera kept the route readable.
  - **Note**: All 5 levels use a fixed overhead camera at ~60 degrees. Grid lines via checkerboard shader help. But Level 5 is 12x7 grid — camera at (11,20,22) with FOV 52 may make far-right entities (enemy at grid 9,3 = world 18,6 and socket at grid 10,3 = world 20,6) small.
- [ ] I understood what Level 5 wanted before brute-forcing it.
  - **Concern**: See Level 5 notes below. The linear corridor layout makes the "three jobs" feel like a sequence of gates rather than a spatial puzzle with real choices.

## Level 1

- **Time**: ~2 min (estimated from path length)
- **Grid**: Player at (1,1), Box at (3,1), Button at (6,1), Door at (4,2), Goal at (6,3)
- **Where I hesitated**: The hint says "先推动箱子，看它滚动后顶面会变化。把它压在圆形按钮上，让门保持开启，再走到发光终点。" This tells me THREE things at once: rolling changes face, button holds door, and reach the goal. That's a lot for Level 1.
- **What I thought the rule was**: Push box onto button, go through door, reach goal.
- **What the game actually seemed to mean**: Same — but the "rolling changes face" part is taught simultaneously with "button holds door open". The GDD says Level 1 should ONLY teach rolling awareness, and Level 2 teaches buttons. But the actual Level 1 already has a button + door!
- **Issue Type**: Rule / Design
- **Severity**: **High** -- Level 1 combines Level 1 + Level 2 concepts from the tutorial arc doc. This violates the "one new concept per level" principle.
- **Exact quote from my head**: "Wait, Level 1 already has a button and a door? The design doc says Level 1 should be pure rolling awareness with just a box and an exit."

### Box Orientation Trace (Level 1)
Initial orientation: top=NORMAL_A, bottom=NORMAL_B, left=IMPACT_A, right=IMPACT_B, front=HEAVY, back=ENERGY

Push RIGHT (x+1): top←left=IMPACT_A, bottom←right=IMPACT_B, left←bottom=NORMAL_B, right←top=NORMAL_A → top = IMPACT ("◆ 冲击")
Push RIGHT again: top←left=NORMAL_B → top = NORMAL ("● 普通")
Push RIGHT again: top←left=IMPACT_B → top = IMPACT ("◆ 冲击")

Player pushes box right 3 times to reach button at (6,1). Box lands with IMPACT face up. Button is `accepted_face_kinds = ["NORMAL","IMPACT","HEAVY","ENERGY"]` so any face works. Door opens. Player walks around through (4,2)→door open→(6,3) goal. Works.

## Level 2

- **Time**: ~3 min
- **Grid**: Player at (2,2), Box at (2,2) — SAME CELL!
- **Where I hesitated**: Player and box are both at world (4, y, 4) which maps to grid (2,2). They overlap on the same cell at startup.
- **What I thought the rule was**: Push box onto button, walk through door.
- **What the game actually seemed to mean**: Same, but the initial overlap is a potential bug.
- **Issue Type**: Layout
- **Severity**: **High** -- Player and box occupy the same grid cell at spawn. GridMotor.register_entity() will warn about overwriting. The player's first move in any direction will push the box because they share the cell. This could work as "the box is right in front of you" but it's technically a grid collision at init.
- **Exact quote from my head**: "Player and box are literally stacked on the same tile. Is this intentional or a scene placement bug?"

### Path Analysis
Button at (3,1), Door at (3,2), Goal at (4,2).
If player pushes RIGHT: box goes to (3,2) — that's the door's cell. Door is closed and registered as a blocker. Push fails ("被墙或门阻挡"). Player gets denied.
If player pushes UP: box goes to (2,1). Then push RIGHT: box goes to (3,1) = button cell. Button activates, door opens. Player walks right through (3,2) to (4,2) goal. Works.

The puzzle is solvable but the initial overlap is concerning.

## Level 3

- **Time**: ~4 min
- **Grid**: Player at (1,2), Box at (3,4), Enemy at (3,3), Goal at (5,4)
- **Where I hesitated**: Box is at grid (3,4) and enemy is at (3,3). Box starts south of the enemy. To push box into enemy, player needs to push box UP (toward enemy). Let me trace orientation.
- **What I thought the rule was**: Roll box to correct face, then push into enemy.
- **What the game actually seemed to mean**: Correct.
- **Issue Type**: Feedback
- **Severity**: Medium -- The hint says "不是所有顶面都能打穿敌人" but doesn't tell you WHICH faces work. The player must discover IMPACT and HEAVY through trial-and-error or by reading the small face label on the box. This is intentional per the design but could be frustrating.
- **Exact quote from my head**: "I need to push the box north into the enemy, but what face will be on top after that push?"

### Box Orientation Trace (Level 3)
Initial: top=NORMAL_A. Box at (3,4), enemy at (3,3).

Push UP (y-1): top←front=HEAVY. HEAVY is in enemy's accepted ["IMPACT","HEAVY"]. Enemy defeated! Box moves to (3,3).

So the very first push UP defeats the enemy immediately. One move. That seems too easy for a level that's supposed to teach "not every face works". The player never experiences a failed push because the default first move succeeds.

Alternative: push RIGHT first: box to (4,4), top=IMPACT_B. Then push UP: box to (4,3), top=HEAVY. Then the enemy at (3,3) is still alive — player would need to maneuver box left.

Actually wait — the intended "learning by failing" only happens if the player's natural first attempt uses a wrong face. But pushing UP gives HEAVY which works. The player might never learn that NORMAL faces fail.

- **Issue Type**: Layout / Teaching
- **Severity**: **High** -- The default obvious move (push box toward enemy) succeeds on the first try. Player never experiences the "wrong face" failure that this level is supposed to teach.

## Level 4

- **Time**: ~4 min
- **Grid**: Player at (1,2), Box at (3,2), EnergySocket at (3,3), Door at (6,3), Goal at (8,3)
- **Where I hesitated**: This is labeled "能源供给" (Energy Supply) in the main.gd presentation data, not "重货通道" (Heavy Route) as in the tutorial arc doc. The hint says "能源槽只接受 ENERGY 顶面". So this level teaches ENERGY sockets, not heavy buttons/enemies.
- **What I thought the rule was**: Roll box to ENERGY face and push onto socket.
- **What the game actually seemed to mean**: Correct — but this is the ENERGY lesson, not the HEAVY lesson. The tutorial arc doc says Level 4 should teach heavy buttons + heavy enemies. The implementation teaches energy sockets instead.
- **Issue Type**: Design
- **Severity**: **High** -- Tutorial sequence mismatch. Doc says Level 4 = heavy button + heavy enemy. Implementation = energy socket + door. Heavy buttons and heavy enemies are never taught in any level.
- **Exact quote from my head**: "Where are the heavy buttons and heavy enemies? Level 4 is supposed to teach those."

### Box Orientation Trace (Level 4)
Initial: top=NORMAL_A. Box at (3,2), socket at (3,3).

Push DOWN (y+1): top←back=ENERGY. ENERGY is in socket's accepted ["ENERGY"]. Socket activates, door opens. Player walks through to goal. One move again.

Same issue as Level 3 — the obvious first move is the correct one. No learning by failing.

Alternative paths exist (push right first, then down) but the direct path works immediately.

## Level 5

- **Time**: ~6 min
- **Grid**: Player at (1,3), Box at (2,3), Button at (3,3), Door at (4,3), Enemy at (9,3), Socket at (10,3), Goal at (9,2)
- **Where I hesitated**: This is a long horizontal corridor. All entities are on row 3 (z=6). The hint spells out the entire solution: "一个箱子，三份工作：先开门，再清掉机器人，最后用 ENERGY 顶面给出口供能。"
- **What I thought the rule was**: Push box right repeatedly along the corridor.
- **What the game actually seemed to mean**: Yes — it's essentially a straight-line push puzzle.
- **Issue Type**: Layout / Teaching
- **Severity**: **High** -- The "one box, three jobs" fantasy is reduced to "push right repeatedly". There's no spatial reasoning, no branching path, no need to recover the box. The player just pushes right ~8 times and everything resolves in sequence along a corridor.
- **Exact quote from my head**: "This is a hallway, not a puzzle. I just keep pushing right."

### Box Orientation Trace (Level 5)
Initial: top=NORMAL_A. Box at (2,3).

Push RIGHT ×1: box→(3,3)=button. top=IMPACT_A. Button accepts all faces → door opens.
Push RIGHT ×2: box→(4,3)=door cell (now open). top=NORMAL_B.
Push RIGHT ×3: box→(5,3). top=IMPACT_B.
Push RIGHT ×4: box→(6,3). top=NORMAL_A.
Push RIGHT ×5: box→(7,3). top=IMPACT_A.
Push RIGHT ×6: box→(8,3). top=NORMAL_B.

Now next push RIGHT: box→(9,3)=enemy cell. Predicted face: top←left. After push 6, orientation is: top=NORMAL_B. Push RIGHT: top←left. Need to track left face through all pushes.

Let me track the full orientation state:
- Start: T=NORMAL_A, B=NORMAL_B, L=IMPACT_A, R=IMPACT_B, F=HEAVY, Bk=ENERGY
- Push R1: T=IMPACT_A, B=IMPACT_B, L=NORMAL_B, R=NORMAL_A, F=HEAVY, Bk=ENERGY
- Push R2: T=NORMAL_B, B=NORMAL_A, L=IMPACT_B, R=IMPACT_A, F=HEAVY, Bk=ENERGY
- Push R3: T=IMPACT_B, B=IMPACT_A, L=NORMAL_A, R=NORMAL_B, F=HEAVY, Bk=ENERGY
- Push R4: T=NORMAL_A, B=NORMAL_B, L=IMPACT_A, R=IMPACT_B, F=HEAVY, Bk=ENERGY (cycle!)
- Push R5: T=IMPACT_A (same as R1)
- Push R6: T=NORMAL_B (same as R2)
- Push R7: predicted top = IMPACT_B. IMPACT is in enemy's accepted ["IMPACT","HEAVY"]. Enemy defeated! Box moves to (9,3).
- Push R8: predicted top = NORMAL_A. Socket accepted = ["ENERGY"]. NORMAL is NOT in accepted. **PUSH FAILS.**

Problem! After 8 right pushes, the face is NORMAL, not ENERGY. The 4-cycle for right pushes is NORMAL_A → IMPACT_A → NORMAL_B → IMPACT_B → repeat. ENERGY and HEAVY are on front/back and never rotate to top during purely-right pushes.

The scene comment says "8 RIGHT pushes: box to (10,3)=socket, top=ENERGY" — this is wrong. ENERGY is on the back face and stays there during right-only pushes.

- **Issue Type**: Rule / Bug
- **Severity**: **Critical** -- Level 5 is unsolvable with the stated strategy. Pushing right only cycles through NORMAL and IMPACT faces. ENERGY never becomes the top face without a vertical push (UP or DOWN). The player must figure out they need to push the box DOWN then UP (or vice versa) at some point to get ENERGY on top. But the corridor layout and hint text both suggest a purely horizontal path.

The level IS potentially solvable if the player detours the box vertically, but:
1. The hint says nothing about needing to change direction
2. The corridor has open space above and below row 3 (walls at rows 1,2,4,5 with gaps)
3. This is actually a much harder puzzle than the hint implies

## Cross-Level Summary

- **Most confusing mechanic**: Why ENERGY face never appears when pushing only horizontally (Level 5)
- **Most unfair-looking failure**: Level 5 socket rejection after 8 pushes — player followed the obvious path and gets denied at the end
- **Most readable level**: Level 3 (clear enemy + box relationship, even though it's one-move solvable)
- **Least readable level**: Level 5 (misleading hint + potentially unsolvable via stated strategy)
- **Did Level 5 communicate "one box, three jobs"?**: No — it communicates "push right until something happens"
- **Top 3 fixes to make next**:
1. **Level 1/2 concept overlap**: Level 1 should match the GDD — just box + exit, no button/door. Move button/door to Level 2.
2. **Level 3 first-move-succeeds**: Rearrange so the natural first push uses a WRONG face, forcing the player to learn the rejection feedback.
3. **Level 5 orientation math**: The corridor-only layout makes ENERGY unreachable. Either redesign the layout to force vertical pushes, or fix the hint to communicate the need for direction changes.

## Draft Verdict

- **Recommendation**: **Rework**
- **Why**: 3 of 5 levels have structural teaching failures: Level 1 teaches two concepts instead of one, Level 3's default path bypasses the intended failure, and Level 5 may be unsolvable via the implied strategy. The code systems (feedback, audio, visuals) are solid — the issue is purely level layout vs. teaching intent.
