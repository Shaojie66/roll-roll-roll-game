# Terrain System — 地形机制

> **Status**: Draft
> **Author**: Game Designer (reverse-documented from GridMotor + RollingBox)
> **Last Updated**: 2026-03-30
> **Implements Pillar**: 滚动就是解谜 / 可爱外表，硬核规则

## Overview

地形机制是 GridMotor 的扩展，定义了三种新的地面瓷砖：坡道（Ramp）、传送带（Conveyor）、旋转平台（Rotating Platform）。地形瓷砖不阻挡移动，但会在箱子经过时触发定向状态变换。玩家可以直接走过地形瓷砖，不受影响。

---

## Player Fantasy

地板不是静止的背景 — 它在呼吸。坡道上的箱子会微微倾斜，传送带上的箱子会缓慢滑动，旋转平台上的箱子会轻轻晃动，等待玩家的指令。每一块地形都是一个隐式的工具提示：看这个地形，用这个箱子。

---

## Detailed Rules

### Terrain Tile Registry

所有地形瓷砖通过 GridMotor 的 `occupiers` 字典注册自己（`blocks_grid_cell = false`），与其他可通行机关（按钮、能量槽）行为一致。

```
GridMotor.occupiers[Vector2i(3,2)] = RampTile.new()
GridMotor.occupiers[Vector2i(4,2)] = ConveyorTile.new()
```

### Terrain Base Class

```
class_name TerrainTile
extends Node3D

@export var terrain_type: StringName  ## "ramp" | "conveyor" | "rotating_platform"
@export var direction: Vector2i        ## 地形方向（世界坐标系）
var is_active := false                   ## 箱子当前是否在地形上

signal terrain_activated(box: Node, terrain_type: StringName)
```

### Ramp Tile

**行为**: 当箱子滚入坡道格子时，箱子朝向在特定方向旋转 90°。箱子在坡道上时，视觉上箱子会微微倾斜。

**朝向旋转规则** (ramp 方向 = 箱子滚动方向):

| 滚动方向 | 顶面变成 | 旋转轴 |
|---------|---------|--------|
| RIGHT (+1, 0) | 原来的左侧 (left) | Y轴 +90° |
| LEFT (-1, 0) | 原来的右侧 (right) | Y轴 -90° |
| UP (0, -1) | 原来的前侧 (front) | X轴 +90° |
| DOWN (0, +1) | 原来的后侧 (back) | X轴 -90° |

**RollingBox 内部变换** (`_apply_ramp_transform`):

```
当前 orientation = {top: A, bottom: B, left: C, right: D, front: E, back: F}

滚动 RIGHT → 新 top = C (旧 left), 新 bottom = D (旧 right)
                新 left = B (旧 bottom), 新 right = A (旧 top)
                新 front = F (旧 back), 新 back = E (旧 front)
```

**边界情况**:
- 箱子从非 cardinal 方向进入坡道：忽略，坡道不触发
- 箱子在坡道上时玩家推入垂直方向：垂直方向正常推动，坡道不触发
- 箱子已经在坡道上，箱子离开再回到同一坡道：重新触发

**视觉反馈**:
- Default: 轻微灰色斜面标记
- Active (箱子在地形上): 地形发光加强（DesignTokens.RAMP_ACTIVE_GLOW）
- 箱子视觉: 倾斜 15°，朝向滚动方向

### Conveyor Tile

**行为**: 当箱子在传送带上时，传送带每 `conveyor_speed` 秒自动推动箱子一格。推动方向由传送带方向决定。

**设计约束**: 传送带格子永远不在玩家可站立的格子上。玩家把箱子推到传送带上，然后箱子自动移动。玩家不能在传送带上同时推箱子。

**传送带参数**:

| 参数 | 值 | 说明 |
|------|-----|------|
| `conveyor_speed` | 0.8 秒/格 | 箱子在传送带上每 0.8 秒移动一格 |
| `conveyor_direction` | Vector2i | 推动方向（世界坐标系） |

**传送带状态机**:

```
ON_GRID:
  → 每 0.8s 检查:
      如果箱子在传送带上且 is_busy == false:
        调用 GridMotor.try_push_box(box, conveyor_direction)
        成功 → 箱子移动到新格子，传送带继续
        失败（被阻挡）→ 跳过本次，等待下一个 0.8s
        箱子离开传送带格子 → 传送带回到 IDLE
```

**边界情况**:
- 箱子被玩家推上传送带，同时传送带 tick 也在同一帧触发：传送带检查 `is_busy`，忽略本次 tick
- 箱子在传送带上被敌人攻击：敌人 defeat 调用 `unregister_entity`，传送带检测到箱子消失，跳到 IDLE
- 多个传送带串联：每块传送带独立计时，不同步

**视觉反馈**:
- Default: 动态箭头纹理，显示传送方向
- Active: 箭头动画加速，OmniLight 颜色变为 ACCENT_CYAN

### Rotating Platform Tile

**行为**: 当箱子滚入旋转平台时，箱子朝向旋转 90°（顺时针）。旋转平台不移动箱子，只改变箱子朝向。

**旋转规则**: 每次激活，箱子顶面顺时针旋转一个位置:
```
新 top = 旧 left
新 left = 旧 bottom
新 bottom = 旧 right
新 right = 旧 top
(front/back 不变)
```

**参数**:

| 参数 | 值 |
|------|-----|
| `rotation_angle` | 90° (固定) |
| `rotation_axis` | Vector3.UP |

**边界情况**:
- 箱子已经在旋转平台上，再次滚入同一平台：再次触发旋转（箱子朝向再次旋转 90°）
- 箱子在旋转平台上时玩家推垂直方向：垂直方向正常推动，旋转平台保持状态

**视觉反馈**:
- Default: 缓慢环境旋转动画（5 RPM）
- Active: 旋转加速（20 RPM），OmniLight 变为 BRICK_RED

---

## Formulas

### Ramp 方向变换（RollingBox._apply_ramp_transform）

```
apply_ramp_transform(roll_direction: Vector2i):
  旧 = _orientation

  如果 roll_direction == RIGHT:
    _orientation.top    = 旧.left
    _orientation.bottom  = 旧.right
    _orientation.left    = 旧.bottom
    _orientation.right   = 旧.top
    ## front/back 不变

  如果 roll_direction == LEFT:
    _orientation.top    = 旧.right
    _orientation.bottom  = 旧.left
    _orientation.left    = 旧.top
    _orientation.right   = 旧.bottom

  如果 roll_direction == UP:
    _orientation.top    = 旧.front
    _orientation.bottom  = 旧.back
    _orientation.front   = 旧.bottom
    _orientation.back   = 旧.top
    ## left/right 不变

  如果 roll_direction == DOWN:
    _orientation.top    = 旧.back
    _orientation.bottom  = 旧.front
    _orientation.front   = 旧.top
    _orientation.back   = 旧.bottom
    ## left/right 不变
```

### Conveyor 推动速度

```
每 0.8 秒:
  if box != null and box.is_busy == false:
    result = _grid_motor.try_push_box(box, conveyor_direction)
    if not result:
      pass  ## 被阻挡，等待下一个 0.8s
```

### Rotating Platform 90° 旋转

```
apply_rotation():
  旧 = _orientation
  _orientation.top    = 旧.left
  _orientation.left   = 旧.bottom
  _orientation.bottom = 旧.right
  _orientation.right  = 旧.top
  ## front/back 不变
```

---

## Edge Cases

| 场景 | 处理方式 |
|------|---------|
| 箱子从非 cardinal 方向进入地形 | 忽略，地形不触发 |
| 箱子在坡道上时玩家推垂直方向 | 垂直方向正常推动，坡道保持激活状态 |
| 传送带推动箱子，箱子撞墙 | try_push_box 返回 false，传送带跳过本次 tick |
| 传送带推动箱子，箱子撞玩家 | try_push_box 返回 false，player 收到 move_denied 信号 |
| 箱子在传送带上被敌人攻击消失 | unregister_entity 触发，传送带检测到 box == null，回到 IDLE |
| 箱子已在旋转平台，再次滚入 | 再次触发旋转（累计 180°） |
| 地形格子被新箱子占据 | GridMotor.occupiers 更新，传送带检测新箱子并激活 |
| 玩家自己走到传送带上 | 传送带只检查 rolling_box group，不影响玩家 |

---

## Dependencies

| 系统 | 接触点 |
|------|--------|
| GridMotor | `occupiers` 注册、`try_push_box()` 调用、`entity_move_finished` 信号 |
| RollingBox | `_orientation` 字典读写、`is_busy` 标志 |
| AudioManager | `terrain_activated` 信号 → 播放对应 SFX |
| DesignTokens | RAMP_COLOR, CONVEYOR_COLOR, ROTATING_PLATFORM_COLOR |

---

## Tuning Knobs

| 参数 | 默认值 | 可调范围 | 影响 |
|------|-----|--------|------|
| `conveyor_speed` | 0.8s | 0.4s–2.0s | 传送带推动频率，越小越快 |
| `ramp_tilt_angle` | 15° | 5°–30° | 箱子在坡道上的视觉倾斜角度 |
| `rotating_speed_active` | 20 RPM | 10–40 RPM | 旋转平台激活时旋转速度 |
| `terrain_glow_intensity` | 1.0 | 0.5–2.0 | 地形激活时发光强度倍率 |

---

## Acceptance Criteria

- [ ] 坡道正确旋转箱子朝向（4 个 cardinal 方向各验证一次）
- [ ] 传送带在箱子就绪时自动推动（不推动 is_busy == true 的箱子）
- [ ] 传送带推动被墙壁阻挡时跳过 tick，不卡死
- [ ] 旋转平台每次激活旋转箱子 90°（顺时针）
- [ ] 所有地形格子在 GridMotor.occupiers 中正确注册（blocks_grid_cell = false）
- [ ] 地形激活时 AudioManager 播放对应 SFX（ramp_activate / conveyor_push / rotating_platform_rotate）
- [ ] 地形视觉状态（default / active）正确切换
- [ ] 地形 GDD 中 5 个 Open Questions 全部有 YES/NO 决定

---

## Open Questions (from Milestone 02)

| # | Question | Decision | Rationale |
|---|----------|---------|-----------|
| 1 | 坡道方向 | 滚动方向 = 变换方向 | 符合直觉，方向一致 |
| 2 | 坡道是否消耗移动 | 否 | 坡道不移动箱子，只变换朝向 |
| 3 | 传送带速度 | 0.8s/格 | 给玩家足够时间观察和反应 |
| 4 | 传送带可被玩家主动停止 | 否 | 设计约束：玩家不站在传送带上 |
| 5 | 旋转平台旋转角度 | 90° 固定 | 简单、可预测、最易教学 |
