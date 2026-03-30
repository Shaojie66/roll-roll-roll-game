# Milestone 02: Vertical Slice — 完整主题区

> **Status**: Draft
> **Milestone ID**: M02-VS-001
> **Start Target**: 2026-04-20 (after Sprint 2 completion)
> **Duration**: 8-10 weeks
> **Owner**: Producer (Claude Code)

---

## Overview

Vertical Slice 阶段的目标是将核心原型扩展为一个**可玩的完整主题区域**，包含 8 个关卡、新地形机制（坡道、传送带、旋转平台）、评分系统，以及第一个主题区的完整内容。验证"滚动功能箱"的核心循环足以支撑一个完整的游戏章节。

> **Scope Bounding Rule**: 地形 GDD 必须在已批准的范围内解决 Open Questions。任何需要新机制的问题自动延后至 VS 后，无需新决策。
> **GDD Acceptance Criteria**: 所有 5 个 Open Questions 必须有明确的 YES/NO 决定，包含选择理由。不得引入新机制（需 CEO 审批）。

---

## Vertical Slice Scope

### Content Goals

| Metric | Prototype (当前) | Vertical Slice (目标) |
|--------|----------------|---------------------|
| 关卡数量 | 5 个教学关 | 8 个关卡 (扩展教学区 + 主题区) |
| 主题区域 | 教学弧 (无主题) | 1 个完整主题区 (洞穴/废墟/工厂三选一) |
| 地形机制 | 仅墙壁 | 坡道、传送带、旋转平台 |
| 评分系统 | 无 | 星评分 (1-3 星) — **延后至 VS 后** |
| 敌人类型 | 2 类 | 2 类 (+ 变种为 Nice to Have) |
| 箱子类型 | 1 种 (4 面功能) | 1 种 |

### New Systems to Design & Implement

| System | Design Doc | Implementation | Notes |
|--------|-----------|----------------|-------|
| Terrain System (坡道/传送带/旋转平台) | ❌ 缺失 | ⚠️ 部分实现 (wall_block.gd 存在) | 需要完整 GDD |
| Enemy System | ❌ 缺失 | ✅ 已有 normal_enemy.gd | 需要独立 GDD |
| UI/HUD System | ❌ 缺失 | ⚠️ 内联在 main.gd | 需要独立 GDD |
| Scoring System | ❌ 缺失 | ❌ 不存在 | 新增功能 |
| Terrain Interaction (box-terrain) | ❌ 缺失 | ❌ 不存在 | 箱子在地形上的行为 |

### New Content to Create

| Content | Count | Notes |
|---------|-------|-------|
| 新关卡 (6-7 个) | 6-7 | 扩展教学区 + 首个主题区关卡 |
| 坡道机关 | 1 种 | 上行/下行，影响箱子朝向 |
| 传送带机关 | 1 种 | 自动移动箱子 |
| 旋转平台机关 | 1 种 | 旋转箱子朝向 |
| 新敌人变种 | 1 种 | 基于 NormalEnemy 的变体 |
| 评分系统 UI | 1 套 | 星级显示、重玩评价 |

---

## Milestone Gate Criteria

### G1: Design Documentation Complete

| Criterion | Target | Status |
|-----------|--------|--------|
| Terrain System GDD | `design/gdd/systems/terrain-system.md` | ❌ |
| Enemy System GDD | `design/gdd/systems/enemy-system.md` | ❌ |
| UI/HUD GDD | `design/gdd/systems/ui-hud-system.md` | ❌ |
| Scoring System GDD | `design/gdd/systems/scoring-system.md` | ❌ |
| Level Design Doc (主题区) | `design/levels/theme-area-levels.md` | ❌ |

### G2: Core Mechanics Implemented

| Criterion | Evidence |
|-----------|----------|
| 坡道机关可正确旋转箱子朝向 | 代码 + 单位测试 |
| 传送带可自动移动箱子 | 代码 + 单位测试 |
| 旋转平台可旋转箱子朝向 | 代码 + 单位测试 |
| 评分系统计算正确 (步数/时间/顶面) | 单位测试 |

### G3: Content Playable

| Criterion | Evidence |
|-----------|----------|
| 10-12 关卡可完成 | 人工回归测试 |
| 所有机关类型都有展示关卡 | 关卡清单 |
| 评分系统在每关显示 | UI 测试 |

### G4: Automated Test Coverage

| Criterion | Target |
|-----------|--------|
| 新地形机制测试覆盖 | >80% |
| 评分系统测试覆盖 | 100% |
| 敌人交互测试覆盖 | 100% |

### G5: Visual Polish Baseline

| Criterion | Target |
|-----------|--------|
| 所有机关有明确视觉语言 | 设计Tokens 扩展 |
| 地形机关可区分 | 视觉一致性 |
| 评分星级可识别 | UI 一致性 |

---

## Sprint Breakdown

### Sprint 3 (4-06 ~ 4-19) — Design & Core Systems

**Goal**: 完成所有缺失的 GDD，验证地形机制设计

| Task | Agent | Days | Dependencies |
|------|-------|------|-------------|
| S3-001: Terrain System GDD | Game Designer | 1.5 | None |
| S3-002: Enemy System GDD | Game Designer | 1.0 | None |
| S3-003: UI/HUD System GDD | Game Designer | 1.0 | None |
| S3-004: Scoring System GDD | Game Designer | 1.0 | None |
| S3-005: Implement Ramp mechanism | Gameplay Programmer | 2.0 | S3-001 |
| S3-006: Implement Conveyor mechanism | Gameplay Programmer | 2.0 | S3-001 |
| S3-007: Implement Rotating Platform mechanism | Gameplay Programmer | 1.0 | S3-001 |
| S3-008: Unit tests for terrain mechanisms | QA/Lead Programmer | 1.5 | S3-005/006/007 |

### Sprint 4 (4-20 ~ 5-03) — Level Design & Scoring

**Goal**: 完成评分系统 + 首个主题区关卡设计

| Task | Agent | Days | Dependencies |
|------|-------|------|-------------|
| S3-009: Scoring System — deferred to VS+ | Gameplay Programmer | 0 | S3-004 |
| S3-010: Scoring UI — deferred to VS+ | UI Programmer | 0 | S3-009 |
| S3-011: Level Design — 主题区关卡 1-3 | Level Designer | 2.0 | S3-001 |
| S3-012: Level Design — 主题区关卡 4-6 | Level Designer | 2.0 | S3-011 |
| S3-013: Scoring unit tests | QA/Lead Programmer | 0.5 | S3-009 |
| S3-014: Level implementation — 关卡 6-8 | Gameplay Programmer | 2.0 | S3-011 |

### Sprint 5 (5-04 ~ 5-17) — Integration & Polish

**Goal**: 完成所有关卡，集成评分，开始视觉优化

| Task | Agent | Days | Dependencies |
|------|-------|------|-------------|
| S3-015: Level implementation — 关卡 9-12 | Gameplay Programmer | 2.0 | S3-012 |
| S3-016: Level Design — 扩展教学关 (补充 1-2 关) | Level Designer | 1.0 | None |
| S3-017: Scoring integration test — deferred | QA Tester | 0 | S3-010 |
| S3-018: Visual polish pass — 机关视觉 | Technical Artist | 2.0 | S3-005/006/007 |
| S3-019: Visual polish pass — UI/HUD 一致性 | UI Artist | 1.0 | S3-010 |
| S3-020: Playtest 002 (Vertical Slice) | QA Tester + User | 1.0 | S3-015 |

### Sprint 6 (5-18 ~ 5-31) — Validation & Gate-Check

**Goal**: 完成回归测试，准备 Vertical Slice gate-check

| Task | Agent | Days | Dependencies |
|------|-------|------|-------------|
| S3-021: Regression test (all 12 levels) | QA Tester | 1.5 | S3-015 |
| S3-022: Fix bugs from Playtest 002 | Gameplay Programmer | 2.0 | S3-020 |
| S3-023: Milestone gate-check | Producer | 0.5 | S3-021 |
| S3-024: Update all design docs (final) | Game Designer | 1.0 | All GDDs |
| S3-025: Update risk register | Producer | 0.5 | All tasks |

---

## Design Decisions (resolved by reviews)

### Terrain Colors
| Terrain | Color | Rationale |
|---------|-------|-----------|
| Ramp | Warm amber (#F4B33F, FACE_NORMAL palette) | Matches Normal face — ramp "activates" the normal face |
| Conveyor | Cool cyan (#4AC7F2, FACE_ENERGY palette) | Matches Energy face — conveyor "powers" the box |
| Rotating Platform | Brick red (#E25F39, FACE_HEAVY palette) | Matches Heavy face — rotating platform "is heavy/grounded" |

### Terrain Visual States
| Terrain | Default | Active (box present) |
|---------|---------|---------------------|
| Ramp | Base color, subtle glow | Intensified glow, ramp surface highlight |
| Conveyor | Animated chevron pattern | Direction arrows animate faster |
| Rotating Platform | Slow ambient rotation | Speed increases when box present |

### Conveyor Placement Rule
> Conveyor tiles are never placed on player-walkable cells. Player pushes box ONTO conveyor from adjacent cell. Conveyor auto-poves box. Player cannot simultaneously push and be pushed.

### Terrain Audio Events (E1)
- `ramp_activate` — SFX when box rolls onto ramp
- `conveyor_push` — SFX when conveyor moves box
- `rotating_platform_rotate` — SFX when rotating platform activates

### Terrain GDD Scope Bounding Rule
> Any Open Question requiring a NEW mechanic (not ramp/conveyor/rotating platform) is auto-deferred to post-VS without new decision.

---

## Open Questions

1. **主题区选择**: 洞穴/废墟/工厂 — 需要在 Sprint 3 开始前确定
2. **评分公式**: 延后至 VS 后 — 当前 8 关不需评分系统即可验证核心循环
3. **坡道方向**: 箱子在坡道上滚动时是否需要"消耗"移动？还是有独立的上行/下行方向？
4. **传送带速度**: 相对于玩家移动速度的比例？是否可以被玩家主动停止？
5. **旋转平台**: 每次旋转 90° 还是任意角度？触发方式是踩上去自动还是需要按钮？

---

## Dependencies from Previous Milestone

| Item | Status | Blocker |
|------|--------|---------|
| S2-003: 手动回归测试 | ⚠️ 未完成 | 需在 Godot 编辑器中执行 |
| S2-020: Playtest 002 (外部测试) | ❌ 未开始 | 取决于 S3-015 |
| S2-021: 本文档 | ✅ 完成 | — |

---

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| 地形机制设计过于复杂 | Medium | High | 先做最小可用版本，细节在迭代中加入 |
| 评分系统公式难以平衡 | Medium | Medium | 先实现，用实际关卡数据调优 |
| 6 周内无法完成 12 关 | Medium | High | 优先保证核心关卡质量，扩展关卡可延后 |
| 视觉风格与"可爱外表"不匹配 | Low | Medium | 提前做 DesignTokens 扩展验证 |
