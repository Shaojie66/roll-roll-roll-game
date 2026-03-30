# 玩家移动系统

> **Status**: Implemented
> **Implementation Complete**: Player controller implemented in Sprint 2 — player.gd complete, movement, deny feedback, grid integration all working
> **Author**: Codex (reverse-documented from `player.gd`)
> **Last Updated**: 2026-03-30
> **Implements Pillar**: 滚动就是解谜 / 可爱外表，硬核规则

## Overview

玩家移动系统控制玩家角色在网格上的有向移动。玩家推动方向输入后，系统通过 GridMotor 进行路径解析（空地通行、箱子推动），通过补间动画完成位移和旋转，并发出完成信号触发机关和音频。该系统不处理战斗或交互逻辑，仅负责"从 A 到 B"的运动表达。

## Player Fantasy

玩家感觉角色是一个轻盈的玩具小机器人：按方向键就立刻响应，滚动动画丝滑流畅，每一步都有清脆的脚步声。若移动被阻挡，小机器人会快速闪红反馈，让玩家立即知道哪里走不通。站在原地时，小机器人有轻微的上下浮动和脚底光环呼吸，像一个待命的活泼生命体。

## Detailed Rules

### 移动流程

完整移动周期如下：

```
输入方向 (WASD/Arrow)
  → main.gd 输入路由
    → GridMotor.try_move_actor(player, direction)
      ├── 目标格子为空 → _commit_move() → player.move_to_cell()
      ├── 目标格子为箱子 → try_push_box()
      │   ├── 箱子可推动 → _commit_move() → player.move_to_cell()
      │   └── 箱子不可推动 → move_denied 信号 → player._show_deny_feedback()
      └── 目标格子被阻挡 → move_denied 信号 → player._show_deny_feedback()
        → player.move_to_cell(target, direction)
          ├── is_busy = true
          ├── rotation.y = GridCoordRef.facing_yaw(direction)
          ├── Tween: global_position → grid_to_world(target), duration=move_duration
          └── Tween.finished → _on_move_finished()
            → is_busy = false
            → GridMotor.notify_entity_move_finished()
            → AudioManager.play_player_step()
```

### 移动状态

| 状态 | 进入条件 | 退出条件 | 行为表现 |
|------|---------|---------|---------|
| 待机 | `_on_move_finished()` 完成 / 初始 | 下一帧 `try_move_actor()` 调用时 | idle bob 动画运行，可接受输入 |
| 移动中 | `move_to_cell()` 被调用 | Tween.finished 信号触发 | `is_busy=true`，不响应新输入 |
| 被拒绝 | `GridMotor.move_denied` 信号 | 反馈动画完成（0.25s） | 红色闪烁，不移动 |

### 旋转规则

- 玩家只记录 4 个方向的 facing（北/南/东/西），转换为 Y 轴弧度
- `GridCoordRef.facing_yaw(direction)` 将 Vector2i 方向映射为绕 Y 轴旋转量
- 转向立即发生，不使用补间动画

### 视觉动画

| 动画 | 节点 | 参数 | 说明 |
|------|------|------|------|
| 位移补间 | Player (Node3D) | `global_position` → `grid_to_world(grid_position)`, 0.14s, TRANS_SINE, EASE_OUT | 移动动画 |
| Idle bob | `Visual` (child) | `position.y = sin(_bob_time * TAU / 1.5) * 0.04` | 待机时轻微上下浮动，周期 1.5s |
| 脚底光环呼吸 | `MarkerRing` (MeshInstance3D) | `emission_energy_multiplier` 在 1.0↔1.6 间渐变，周期 1.2s | 永久循环 |

### 反馈动画

| 反馈 | 触发条件 | 视觉效果 | 时长 |
|------|---------|---------|------|
| 移动拒绝 | `GridMotor.move_denied(actor==self)` | body 材质闪红 `DENY_FLASH_ALBEDO` + 红色自发光 | 0.25s |
| 移动成功 | `_on_move_finished()` | 无额外视觉（脚步声暗示成功） | — |

## Formulas

### 网格坐标转换

```text
grid_position = GridCoordRef.world_to_grid(global_position)
global_position = GridCoordRef.grid_to_world(grid_position, PLAYER_HEIGHT)
```

| 变量 | 类型 | 值 | 说明 |
|------|------|-----|------|
| `PLAYER_HEIGHT` | float | 0.75 | 玩家 mesh 离地高度（网格系统用） |

### 面向角度计算

```text
yaw = GridCoordRef.facing_yaw(direction)
```

`facing_yaw` 是 `GridCoordRef` 的静态方法，将 Vector2i 方向映射到 Y 轴弧度：
- `Vector2i(0, -1)` (北/上) → `0.0` rad
- `Vector2i(1, 0)` (东/右) → `PI/2` rad
- `Vector2i(0, 1)` (南/下) → `PI` rad
- `Vector2i(-1, 0)` (西/左) → `-PI/2` rad (或 `3*PI/2`)

### Idle Bob 公式

```text
visual.position.y = sin(_bob_time * TAU / 1.5) * 0.04
```

| 变量 | 值 | 说明 |
|------|-----|------|
| `_bob_time` | 累加 `_process(delta)` | 随时间递增 |
| 振幅 | 0.04 units | 上下浮动 ±0.04 |
| 周期 | 1.5 s | 一个完整上下周期 |

### Marker Ring Pulse 公式

```text
emission_energy_multiplier ∈ [1.0, 1.6]  (1.2s 周期, SINE 缓动)
```

## Edge Cases

| 场景 | 预期行为 | 依据 |
|------|---------|------|
| 玩家在移动中再次输入方向 | 被忽略，`is_busy=true` 阻止 | `GridMotor.try_move_actor()` 检查 `is_busy` |
| 玩家被箱子挡住去路 | 闪红反馈，不移动，脚步音效不播放 | `move_denied` 信号触发 `_show_deny_feedback()` |
| 玩家尝试推箱子但箱子被敌人挡住 | 箱子闪红反馈（由 GridMotor 处理），玩家收到相同拒绝原因 | `try_push_box()` 失败后 `_set_denied(actor, last_deny_reason)` 转发给玩家 |
| 玩家站在原地，Visual 节点 bob 动画 | 正常运行，不影响 `global_position` | bob 操作的是 `Visual.position`（局部坐标） |
| 玩家初始化时网格上有其他实体 | `GridMotor.register_entity()` 会输出警告，但覆盖写入 | `register_entity()` 不做碰撞检测 |
| 关卡重置时玩家状态 | 玩家节点重建，`_ready()` 重新执行完整初始化 | 场景切替由 `main.gd` 管理 |
| `can_push_boxes = false` 时推箱子 | 玩家被当作普通阻挡物处理，门不响应 | `try_move_actor()` 检查 `can_push_boxes` 标志 |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| 网格引擎 (GridMotor) | Player depends on GridMotor | 注册实体、查询占据者、处理移动逻辑、发出 `move_denied` 信号 |
| 网格坐标 (GridCoord) | Player depends on GridCoord | `world_to_grid()` / `grid_to_world()` / `facing_yaw()` 坐标转换 |
| 设计令牌 (DesignTokens) | Player depends on DesignTokens | `DENY_FLASH_ALBEDO` / `DENY_FLASH_EMISSION` 颜色常量 |
| 音频管理 (AudioManager) | Player depends on AudioManager | `play_player_step()` 播放脚步声 |
| 主场景 (main.gd) | main.gd depends on Player | 输入路由调用 `GridMotor.try_move_actor(player, direction)` |
| 场景结构 | — | Player 期望 `Visual`、`Body`、`MarkerRing` 子节点存在 |

## Tuning Knobs

| 参数 | 当前值 | 安全范围 | 增大效果 | 减小效果 |
|------|-------|---------|---------|---------|
| `move_duration` | 0.14 s | 0.08–0.25 s | 移动更有重量感 | 更灵敏但可能感觉不自然 |
| `PLAYER_HEIGHT` | 0.75 units | 0.5–1.0 | 角色更高，贴地感弱 | 更贴地但可能被墙遮挡 |
| Idle bob 振幅 | 0.04 units | 0.02–0.08 | 更活泼 | 更沉稳 |
| Idle bob 周期 | 1.5 s | 1.0–2.5 s | 更悠闲 | 更焦虑 |
| Marker ring pulse 能量范围 | 1.0–1.6 | 0.8–2.0 | 更显眼 | 更低调 |
| Marker ring pulse 周期 | 1.2 s | 0.8–2.0 s | 更急促 | 更缓慢 |
| 拒绝反馈时长 | 0.25 s | 0.15–0.40 s | 反馈更持久 | 更干脆 |
| 拒绝反馈发光强度 | 1.2 | 0.8–2.0 | 更刺眼 | 更柔和 |

## Acceptance Criteria

- [x] 玩家按方向键后，角色在 0.14s 内平滑移动到目标格子
- [x] 玩家面朝方向与最近一次移动方向一致（Y 轴旋转）
- [x] 移动完成后 `is_busy` 恢复为 `false`，可接受下一帧输入
- [x] 目标格子被阻挡时，玩家不移动，红色闪烁反馈在 0.25s 内完成
- [x] 移动完成后脚步声音效播放，无遗漏
- [x] 待机时 `Visual` 节点持续进行 ±0.04 units、周期 1.5s 的上下浮动
- [x] `MarkerRing` 节点持续进行 emission_energy 1.0↔1.6、周期 1.2s 的呼吸动画
- [x] 玩家成功注册到 `GridMotor.occupiers` 字典，占据正确的网格格子
- [x] `can_push_boxes = false` 时玩家不推动箱子（当作普通阻挡物处理）
- [x] 玩家初始化时 `grid_position` 从 `world_to_grid(global_position)` 正确计算
- [x] 所有补间动画使用 `TRANS_SINE` / `EASE_OUT`，无突然的线性停止

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| 玩家是否需要奔跑/冲刺状态 | Game Designer | Vertical Slice 前 | Open — 当前无此设计 |
| 是否需要跳跃动画或下落动画 | Game Designer | Vertical Slice 前 | Open — 当前纯网格移动，无垂直运动 |
| `can_push_boxes` 是否有外部控制场景 | Level Designer | Alpha 前 | Open — 目前始终为 true |
