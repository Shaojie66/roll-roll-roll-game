# UI/HUD System — 界面与抬头显示

> **Status**: Draft
> **Author**: Game Designer (reverse-documented from main.gd + main.tscn)
> **Last Updated**: 2026-03-30
> **Note**: Scoring UI (S3-010) deferred to VS+. Current HUD includes level hints, deny feedback, and goal completion display.
> **Implements Pillar**: 可爱外表，硬核规则

## Overview

UI/HUD 系统管理游戏内的所有 2D 界面元素：抬头显示（HUD）、暂停菜单、关卡完成界面。3D 游戏视图由 World 子树渲染，不属于本系统。UI 节点内联在 `main.tscn` 中（`CanvasLayer` + `Control` 节点树）。

---

## Player Fantasy

界面是玩具展示台的底座。HUD 卡片像悬浮的玻璃面板，文字清晰但不抢戏。暂停像玩具暂停了；完成界面像玩具柜台打开了评分灯箱。

---

## Detailed Rules

### Screen Layout

```
┌─────────────────────────────────────┐
│  TopRow                                    │
│  ┌─────────┐  ┌──────────┐  ┌────────┐ │
│  │ LevelCard│  │ControlsCard│  │  (empty) │ │
│  │ Kicker  │  │ WASD hint │  │          │ │
│  │ Title   │  │ R=Restart │  │          │ │
│  │ Subtitle│  │ ESC=Pause │  │          │ │
│  └─────────┘  └──────────┘  └──────────┘ │
│                                            │
│  World (Node3D 渲染区)                       │
│                                            │
│  BottomRow                                    │
│  ┌──────────────────────────────────────┐  │
│  │ ObjectiveCard                             │  │
│  │ Hint: "教程提示文字"                      │  │
│  └──────────────────────────────────────┘  │
└────────────────────────────────────────────┘
```

### Overlay Screens

| Screen | Trigger | Dismiss |
|--------|---------|---------|
| PauseOverlay | ESC key | RESUME / RESTART / QUIT |
| LevelCompleteOverlay | GoalPad activated | (no dismiss — blocks input) |

### Level Complete Stars

评分基于 `move_count`（GridMotor._move_count）：
- ★★★: move_count ≤ star3_max (green kicker text)
- ★★: move_count ≤ star2_max (gold kicker text)
- ★: completion (no star)

### Color Palette

所有 UI 颜色来自 `DesignTokens`:
- Surface: `SURFACE_CARD` / `SURFACE_CARD_OBJ` / `SURFACE_CARD_CTRL`
- Accent: `ACCENT_CYAN`, `ACCENT_GOLD`
- Text: `TEXT_KICKER`, `TEXT_TITLE`, `TEXT_SUBTITLE`
- Separator: `SEPARATOR_CYAN`

---

## HUD Components

### LevelCard (top-left)
- 显示当前关卡 kicker / title / subtitle
- kicker: `TEXT_KICKER` (cyan)
- title: `TEXT_TITLE` (near-white, large)
- subtitle: `TEXT_SUBTITLE` (soft blue-gray)

### ControlsCard (top-center)
- WASD/方向键移动
- R=重开
- ESC=暂停
- 固定显示，不需要动态更新

### ObjectiveCard (bottom-center)
- 显示当前关卡提示（HUD 提示或 goal hint）
- 单行 Label，居中
- 仅在有内容时显示

### HintLabel (objective card 内)
- 动态更新，关卡切换时清空
- goal_pad 激活时显示关卡目标

### PauseOverlay (CanvasLayer)
- 深色半透明遮罩 (ColorRect, alpha 0.85)
- 卡片面板 (SURFACE_CARD_SOLID)
- RESUME / RESTART / QUIT 按钮

### LevelCompleteOverlay (CanvasLayer)
- 深色半透明遮罩
- 星星行 (StarRow): 3 个 Label，动态显示 ★ / ☆ / —/—
- MoveCount 显示

---

## Edge Cases

| 场景 | 处理方式 |
|------|---------|
| 快速双击 ESC | 输入防抖处理 |
| 完成动画中 ESC | ESC 忽略直到完成动画结束 |
| 提示文本过长 | Label truncate_mode = TRUNCATE_RIGHT |
| 0 star 达成 | 显示绿色 kicker "★" 而非 gold |
| 关卡无 goal hint | ObjectiveCard 不显示 |

---

## Dependencies

| 系统 | 接触点 |
|------|--------|
| GridMotor | `_move_count` 用于星星计算 |
| LevelRoot | goal_pad hint 文本 |
| AudioManager | 暂停/恢复音乐 |
| DesignTokens | 所有颜色 token |

---

## Tuning Knobs

| 参数 | 默认值 | 可调范围 | 影响 |
|------|-----|--------|------|
| `pause_card_corner_radius` | 28px | 16–40px | 卡片圆角 |
| `overlay_alpha` | 0.85 | 0.6–0.95 | 遮明暗度 |
| `star_reveal_delay` | 0.1s | 0.05–0.3s | 星星逐个弹出延迟 |

---

## Acceptance Criteria

- [ ] ESC 打开/关闭暂停菜单
- [ ] 暂停时游戏逻辑冻结（GridMotor 停止接受输入）
- [ ] 星星正确计算并显示
- [ ] R 键重置关卡状态
- [ ] QUIT 返回主菜单（当前显示主菜单场景名）
