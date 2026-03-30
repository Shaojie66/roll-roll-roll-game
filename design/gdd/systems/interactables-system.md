# 机关联动系统

> **Status**: Draft
> **Author**: Codex + User
> **Last Updated**: 2026-03-23
> **Updated**: 2026-03-30 — floor_button.gd, sliding_door.gd, energy_socket.gd all implemented
> **Implements Pillar**: 滚动就是解谜 / 一个箱子，多种用途 / 可爱外表，硬核规则

## Overview

机关联动系统管理所有由滚动功能箱触发的环境交互物：按钮、门、能源槽和出口终端。它的职责是把箱子的顶面状态转化为关卡的拓扑变化——开门、关门、供能、完成关卡。整个系统不做数值计算，全部基于确定性布尔判定。

当前包含 5 个具体实体：

| 实体 | 类 | 场景 | 角色 |
|------|-----|------|------|
| 普通按钮 | `FloorButton` | `floor_button.tscn` | 任意顶面即可触发，持续压住才保持 |
| 重压按钮 | `FloorButton`（参数变体） | `heavy_button.tscn` | 仅重压面可触发 |
| 滑动门 | `SlidingDoor` | `sliding_door.tscn` | 被按钮/能源槽控制开关 |
| 能源槽 | `EnergySocket` | `energy_socket.tscn` | 仅能源面可触发，可链接门和出口 |
| 出口终端 | `GoalPad` | `goal_pad.tscn` | 玩家踩上即完成关卡 |

## Player Fantasy

玩家应感觉关卡是一台精密的玩具机械装置：按下开关灯会亮，门会滑开，终端充能后出口闪烁。每一步交互都有清晰的因果链——"我把箱子推到按钮上 → 按钮亮了 → 门开了 → 我能走了。"

当玩家回收箱子导致门关闭时，应该立刻理解因果关系，而不是感到被惩罚。系统的目标不是阻碍，而是让空间规则可预测、可推理。

## Detailed Rules

### 1. FloorButton（普通按钮 / 重压按钮）

**共用实现**：`FloorButton` 类通过 `accepted_face_kinds` 导出属性区分普通/重压。

| 属性 | 普通按钮 | 重压按钮 |
|------|---------|---------|
| `accepted_face_kinds` | `["NORMAL","IMPACT","HEAVY","ENERGY"]` | `["HEAVY"]` |
| 视觉基板颜色 | 深蓝灰 | 深蓝灰 |
| 压板颜色 | 默认材质 | 砖橙色（发光） |

**触发规则**：

- 箱子必须停留在按钮格上（`grid_position == button.grid_position`）
- 箱子当前顶面必须在 `accepted_face_kinds` 中
- 按钮为**持续触发**：箱子离开后按钮恢复未按下状态

**状态机**：

| 状态 | 进入条件 | 退出条件 | 视觉表现 |
|------|---------|---------|---------|
| 未按下 | 初始 / 箱子离开 / 顶面不匹配 | 合格箱子停留 | 压板抬起，指示灯红色(0.4能量) |
| 已按下 | 合格箱子停留在格上 | 箱子离开 | 压板下沉0.08，指示灯绿色(1.15能量) |

**联动**：通过 `linked_doors: Array[NodePath]` 控制一个或多个 `SlidingDoor`。按下时调用 `door.set_open(true)`，释放时调用 `door.set_open(false)`。

**音频**：

- 按下 → `AudioManager.play_button_press()` + `start_button_hum()`
- 释放 → `AudioManager.play_button_release()` + `stop_button_hum()`

### 2. SlidingDoor（滑动门）

**角色**：关卡拓扑的可变节点。关闭时占据网格并阻挡所有实体通过，打开时从网格注销并让出通路。

**导出属性**：

| 属性 | 类型 | 默认值 | 说明 |
|------|------|-------|------|
| `starts_open` | bool | false | 初始状态 |
| `open_offset` | Vector3 | (0, 2.2, 0) | 开门时门板的位移方向和距离 |

**状态机**：

| 状态 | 进入条件 | 退出条件 | 网格行为 |
|------|---------|---------|---------|
| 关闭 | 初始 / 控制方释放 | 控制方按下 | `register_entity` → 占据网格，`blocks_grid_cell=true` |
| 打开 | 控制方按下 | 控制方释放 | `unregister_entity` → 让出网格，`blocks_grid_cell=false` |

**关闭保护**：如果门的格子上已有其他实体（如箱子穿过中），门不会关闭，避免挤压玩家或产生重叠。

**音频**：

- 打开 → `AudioManager.play_door_open()`
- 关闭 → `AudioManager.play_door_close()`

### 3. EnergySocket（能源槽）

**角色**：高级触发器，仅接受能源面顶面的箱子。可链接门和出口终端，是 Level 4-5 的关键教学对象。

**触发规则**：

- 与 `FloorButton` 结构一致，但 `accepted_face_kinds` 默认为 `["ENERGY"]`
- 持续触发：箱子离开后失去供能

**联动**：

- `linked_doors: Array[NodePath]` → 控制门开关
- `linked_goals: Array[NodePath]` → 控制出口终端的 `set_powered()`

**视觉状态**：

| 状态 | Core 缩放 | 指示灯颜色 | 灯光能量 |
|------|----------|-----------|---------|
| 未供能 | 1.0 | 暗蓝灰 (0.32, 0.44, 0.54) | 0.18 |
| 已供能 | 1.18 | 亮青色 (0.48, 0.98, 1.0) | 1.2 |

**音频**：供能时 → `AudioManager.play_energy_socket_activate()`

### 4. GoalPad（出口终端）

**角色**：关卡完成触发器。玩家踩上已激活的出口即完成关卡。

**导出属性**：

| 属性 | 类型 | 默认值 | 说明 |
|------|------|-------|------|
| `requires_external_power` | bool | false | 是否需要外部供能才能激活 |

**状态机**：

| 状态 | 进入条件 | 退出条件 | 视觉表现 |
|------|---------|---------|---------|
| 未供能 | `requires_external_power=true` 且无供能 | 能源槽供能 | Ring缩小0.82，暗蓝灯(0.18能量) |
| 待激活 | 已供能或不需要供能 | 玩家踩上 | Ring标准1.0，冷蓝灯(0.8能量) |
| 已激活 | 玩家踩上已供能的终端 | 不可逆 | Ring放大1.25，亮青灯(1.5能量) |

**完成链路**：

```
GoalPad._activate_goal()
  → LevelRoot.complete_level()
    → level_completed 信号
      → main.gd._on_level_completed()
        → 通关弹窗
```

**音频**：激活时 → `AudioManager.play_goal_activate()`

### 5. 信号驱动架构

所有机关通过 `GridMotor.entity_move_finished` 信号驱动刷新，不做轮询：

```
GridMotor.entity_move_finished(entity, origin, target)
  +-- FloorButton._on_entity_move_finished() → _refresh_state() → _sync_linked_doors()
  +-- EnergySocket._on_entity_move_finished() → _refresh_state() → _sync_links()
  +-- GoalPad._on_entity_move_finished() → _activate_goal()
```

FloorButton 和 EnergySocket 仅在 `rolling_box` 组的实体移入/移出自身格子时刷新。GoalPad 仅在 `player` 组的实体移入自身格子时触发。

## Formulas

本系统全部使用确定性布尔判定，无数值计算。

### 按钮/能源槽激活判定

```text
activated = (occupant != null)
         && occupant.is_in_group("rolling_box")
         && occupant.current_face_kind() in accepted_face_kinds
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| occupant | Node | null 或网格实体 | `GridMotor.get_entity_at(grid_position)` | 当前格子上的占据者 |
| accepted_face_kinds | PackedStringArray | 面种类子集 | 场景导出属性 | 该机关接受的顶面类型集合 |

**Expected output**: true / false

### 门开关判定

门不主动检查状态，而是被按钮/能源槽通过 `set_open()` 直接控制：

```text
door_state = last_set_open_call_value
```

### 关闭安全判定

```text
can_close = (GridMotor.get_entity_at(door.grid_position) == null)
         || (GridMotor.get_entity_at(door.grid_position) == door)
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| door.grid_position | Vector2i | 关卡范围内 | 门实体自身 | 门在网格中的位置 |

**Expected output**: true / false。为 false 时门保持打开状态直到格子清空。

### 出口激活判定

```text
can_activate = entity.is_in_group("player")
            && target == goal.grid_position
            && (goal.is_powered || !goal.requires_external_power)
            && !goal.is_active
```

**Expected output**: true / false

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| 箱子以错误顶面停在重压按钮上 | 按钮不激活，门保持关闭 | `accepted_face_kinds` 不匹配 |
| 箱子从按钮滚走 | 按钮立即释放，关联门关闭 | 持续触发原则 |
| 门关闭时格子上站着箱子 | 门不关闭，等箱子离开后再尝试 | 防止重叠和穿模 |
| 多个按钮控制同一扇门 | 当前实现为最后一次 `set_open()` 胜出 | MVP 简化，后续可改为 AND/OR 逻辑 |
| 能源槽同时链接门和出口 | 供能时门开且出口供电；断电时门关且出口断电 | `_sync_links()` 遍历两个列表 |
| 玩家在门打开的瞬间走过 | 门的动画时长(0.18s)内网格已注销，可通行 | 逻辑先于动画 |
| 出口已激活后能源槽断电 | 不影响——`is_active` 不可逆 | 防止通关后被撤销 |
| `requires_external_power=false` 的出口 | 玩家踩上即完成，无需供能 | Level 1-3 的简单出口 |
| 箱子停在出口上 | 不触发通关——只有 `player` 组的实体才触发 | 出口只响应玩家 |
| 关卡初始化时按钮下已有箱子 | `_ready()` 中 `_refresh_state(true)` 检测并同步 | 支持预布局关卡 |
| 玩家站在按钮上 | 按钮不激活——只响应 `rolling_box` 组 | 按钮不是地板开关 |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| 滚动功能箱 (RollingBox) | This depends on RollingBox | 需要 `current_face_kind()` 方法和 `rolling_box` 组标识 |
| 网格引擎 (GridMotor) | This depends on GridMotor | 需要 `entity_move_finished` 信号和 `get_entity_at()` 查询 |
| 网格坐标 (GridCoord) | This depends on GridCoord | `world_to_grid` / `grid_to_world` 坐标转换 |
| 设计令牌 (DesignTokens) | This depends on DesignTokens | 灯光颜色常量（按钮开关、出口三态） |
| 音频管理器 (AudioManager) | This depends on AudioManager | 按钮按下/释放、门开关、能源供电、目标激活音效 |
| 玩家 (Player) | GoalPad depends on Player | 出口终端只响应 `player` 组的实体 |
| 关卡根节点 (LevelRoot) | GoalPad depends on LevelRoot | 调用 `complete_level()` 完成关卡 |
| 滚动功能箱 GDD | RollingBox GDD depends on this | 箱子设计文档的"机关规则"章节引用本系统 |
| 教学弧线 | Tutorial Arc depends on this | Level 2-5 的教学围绕机关展开 |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| 按钮压板下沉量 (`PRESS_OFFSET.y`) | 0.08 units | 0.04-0.14 | 反馈更明显 | 更微妙但可能不易察觉 |
| 按钮动画时长 (`ANIMATION_DURATION`) | 0.12s | 0.08-0.20s | 更沉稳 | 更干脆 |
| 门滑动时长 (`ANIMATION_DURATION`) | 0.18s | 0.12-0.30s | 更有仪式感 | 更利落 |
| 门打开位移 (`open_offset`) | (0, 2.2, 0) | Y: 1.5-3.0 | 门消失更彻底 | 门仍可见，暗示可关闭 |
| 能源槽核心放大 | 1.18x | 1.05-1.35x | 供能视觉更强 | 更克制 |
| 能源槽动画时长 (`ANIMATION_DURATION`) | 0.14s | 0.10-0.22s | 更厚重 | 更敏捷 |
| 出口Ring放大 | 1.25x | 1.10-1.40x | 激活感更强 | 更含蓄 |
| 出口动画时长 (`ANIMATION_DURATION`) | 0.16s | 0.10-0.24s | 更有重量 | 更即时 |
| 按钮指示灯-开能量 | 1.15 | 0.8-1.5 | 更耀眼 | 更柔和 |
| 按钮指示灯-关能量 | 0.4 | 0.2-0.6 | 未按状态也显眼 | 更安静 |
| 能源槽指示灯-供能能量 | 1.2 | 0.8-1.6 | 充能感更强 | 更低调 |
| 出口指示灯-激活能量 | 1.5 | 1.0-2.0 | 过关高光更强 | 更含蓄 |

## Acceptance Criteria

- [x] 普通按钮被任意顶面箱子占据时激活，箱子离开后释放
- [x] 重压按钮仅被重压面箱子激活，其余顶面不触发
- [x] 能源槽仅被能源面箱子供电
- [x] 按钮激活/释放时，关联的所有门同步开启/关闭
- [x] 门关闭时占据网格格子，阻挡玩家和箱子通行
- [x] 门打开时让出网格格子，允许通行
- [x] 门不会在有实体占据其格子时强行关闭
- [x] 出口终端在 `requires_external_power=true` 时需要能源槽供能才可激活
- [x] 出口终端在 `requires_external_power=false` 时玩家踩上即完成
- [x] 出口激活后不可逆，即使后续断电也不撤销
- [x] 每个机关的视觉状态（灯光颜色、压板位置、缩放）与逻辑状态一致
- [x] 所有机关音效在正确时机播放，无遗漏无重复
- [x] 关卡重置后所有机关恢复初始状态
- [x] 玩家仅凭视觉即可区分：未触发/已触发按钮、开/关门、供能/未供能插槽、可用/不可用出口

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| 多按钮控制同一扇门时使用 AND 还是 OR 逻辑 | Game Designer | Vertical Slice 前 | MVP 暂用最后写入胜出 |
| 是否引入"锁存按钮"（触发一次后永久开启） | Game Designer | 第 10 关设计前 | Open |
| 能源槽是否应增加"充能进度条"而非瞬间供能 | UX Designer | Vertical Slice 前 | Open |
| 门是否需要支持水平滑动方向 | Level Designer | Alpha 前 | 当前仅支持垂直位移 |
