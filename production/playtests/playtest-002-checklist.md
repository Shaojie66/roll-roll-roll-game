# Playtest 002 Checklist — Vertical Slice Validation

**Method**: Manual in-engine playtest, all 14 levels
**Build**: `milestone-02` branch (commit 51c9065)
**Date**: [Fill before testing]
**Tester**: [Name/ID]

---

## Pre-Flight Check

Before testing any level, verify:
- [ ] Game launches without crash
- [ ] Player can move in all 4 cardinal directions
- [ ] Box can be pushed in all 4 cardinal directions
- [ ] Deny feedback appears when push is blocked
- [ ] Level hints display correctly
- [ ] R key resets the current level
- [ ] Goal completion triggers level complete feedback

---

## Level 1-5: Core Tutorial

### Level 1: 出库练习
- [ ] Player starts at correct grid position
- [ ] Pushing box causes it to roll (not slide)
- [ ] Box top-face label changes after each roll
- [ ] No button/door/enemy in this level
- [ ] Player can reach goal after pushing box aside

### Level 2: 门铃测试
- [ ] Door blocks player path initially
- [ ] Pushing box onto button opens door
- [ ] Moving box OFF button closes door immediately
- [ ] Player can walk through open door to goal

### Level 3: 清道夫巡线
- [ ] Enemy blocks direct player path
- [ ] Box with IMPACT face defeats enemy on contact
- [ ] Box with NORMAL face does NOT defeat enemy
- [ ] After enemy defeat, player can reach goal

### Level 4: 重货通道
- [ ] Heavy button requires HEAVY face to activate
- [ ] Heavy enemy requires HEAVY face to defeat
- [ ] Player cannot pass without proper face configuration
- [ ] Path through level is clear after correct box manipulation

### Level 5: 一箱三用
- [ ] Box must be reused across 3 different purposes
- [ ] Sequence: button → enemy → energy socket (or equivalent)
- [ ] Wrong order blocks progress
- [ ] R key allows quick restart to try different sequence

---

## Level 6-8: Terrain Introduction

### Level 6: 斜坡导引
- [ ] Ramp tile visually distinct (amber glow)
- [ ] Box rolling onto ramp changes face orientation
- [ ] Correct face (ENERGY) activates the button
- [ ] Wrong approach (pushing box without ramp) does not work

### Level 7: 传送分拣线
- [ ] Conveyor tile visually distinct (cyan glow with arrows)
- [ ] Box placed on conveyor auto-moves after 0.8s
- [ ] Player cannot push box while it is on conveyor
- [ ] Box reaches button area for activation

### Level 8: 旋转质检台
- [ ] Rotating platform visually distinct (red glow, slow rotation animation)
- [ ] Box rolling onto platform rotates 90° clockwise
- [ ] Correct face (IMPACT) activates button after rotation
- [ ] Platform rotation animation speeds up when box is on it

---

## Level 9-12: Terrain Combinations

### Level 9: 坡道+传送带组合
- [ ] Ramp changes box face correctly
- [ ] Conveyor transports box after ramp
- [ ] Box arrives at button with correct face
- [ ] Button activates, door opens, player reaches goal

### Level 10: 三机制联动
- [ ] All three terrain types present and functional
- [ ] Correct sequence: ramp → conveyor → rotating platform
- [ ] Box arrives at button with correct face
- [ ] Visual feedback on all terrain activations

### Level 11: 综合排序关
- [ ] Multiple passes through terrain possible
- [ ] Box can be recalled and re-processed
- [ ] Player must cycle box to get correct face (ENERGY)
- [ ] Energy button activates with correct face

### Level 12: 工厂出口大门
- [ ] Timing puzzle: player intercepts box from conveyor
- [ ] Rotating platform available as alternative path
- [ ] Box arrives at IMPACT button with correct face
- [ ] Multiple solution paths possible

---

## Level 13-14: Extended Tutorial

### Level 13: 多箱协作
- [ ] Two boxes present in level
- [ ] Each box maintains independent face orientation
- [ ] Both boxes can be on button/door area simultaneously
- [ ] Both boxes contribute to solving the level

### Level 14: 箱子召回术
- [ ] Box used for multiple tasks in sequence
- [ ] Box must be recalled after first use
- [ ] Enemy defeated with correct face
- [ ] Box repositioned for final button activation

---

## Mechanical Verification

### Box Face System
- [ ] NORMAL face: activates NORMAL buttons
- [ ] IMPACT face: activates IMPACT buttons, defeats enemies
- [ ] HEAVY face: activates HEAVY buttons, defeats HEAVY enemies
- [ ] ENERGY face: activates ENERGY buttons/sockets
- [ ] Face label and color update visually on roll

### Terrain Behaviors
- [ ] Ramp: box face changes, box does not move extra
- [ ] Conveyor: box auto-moves every 0.8s, blocked by walls
- [ ] Rotating platform: box face rotates 90° clockwise per entry
- [ ] Multiple terrain passes stack effects

### Edge Cases
- [ ] Box blocked by wall: conveyor skips that tick
- [ ] Box on conveyor hit by player push: player push wins, box moves
- [ ] Box already on rotating platform, pushed again: rotates again (+90°)
- [ ] Two boxes on same cell: GridMotor prevents overlap

---

## Visual & Audio Verification
- [ ] Terrain glow intensity increases when box is present
- [ ] Conveyor arrow animation visible
- [ ] Rotating platform rotation animation visible
- [ ] Door slides open/closed smoothly
- [ ] Button press animation visible
- [ ] Box roll animation visible
- [ ] Goal pad glow animation on level complete

---

## Critical Bugs to Look For
- [ ] Box falls through floor or wall
- [ ] Box stuck in terrain and cannot be retrieved
- [ ] Player can walk through closed door
- [ ] Button activates without box (false positive)
- [ ] Level auto-completes without player action
- [ ] Game crashes on level load
- [ ] Conveyor moves box through walls

---

## Test Summary

| Level | Completed | Blocked By Bug | Notes |
|-------|-----------|----------------|-------|
| L1    | ☐          |                | |
| L2    | ☐          |                | |
| L3    | ☐          |                | |
| L4    | ☐          |                | |
| L5    | ☐          |                | |
| L6    | ☐          |                | |
| L7    | ☐          |                | |
| L8    | ☐          |                | |
| L9    | ☐          |                | |
| L10   | ☐          |                | |
| L11   | ☐          |                | |
| L12   | ☐          |                | |
| L13   | ☐          |                | |
| L14   | ☐          |                | |

**Total completed**: __/14

---

## Bug Report Format

For each bug found:
```
BUG #[N]
Level: L[X]
Summary: One-line description
Steps to reproduce:
1. 
2. 
Expected: 
Actual: 
Severity: [P0/P1/P2/P3]
```
