# 敌人系统

> **Status**: Draft (reverse-documented from implementation)
> **Author**: Codex + User
> **Last Updated**: 2026-03-30
> **Implements Pillar**: 滚动就是解谜 / 可爱外表，硬核规则
> **Source**: Reverse-documented from `normal_enemy.gd` (87 LOC), `grid_motor.gd` (lines 95-113), `rolling-utility-box.md` section 7

## Overview

敌人系统管理关卡中的静态空间障碍物。敌人不追逐玩家、不巡逻、不攻击——它们的唯一作用是占据网格格子并阻挡通行，迫使玩家用滚动功能箱的特定顶面来清除它们。

敌人的存在把"把箱子推到哪里"的纯位置谜题升级为"把箱子以什么状态推到哪里"的双重谜题，是核心解谜机制的关键放大器。

## Player Fantasy

玩家面对敌人时应该感觉到的是**空间约束**，而不是**动作威胁**。理想体验：

- 看到敌人挡住关键通路
- 计算需要几步滚动才能把箱子翻成正确的顶面
- 成功击败敌人时，获得"我看穿了这个局面"的满足感

敌人不是用来吓唬玩家的，而是让玩家多想一步的"活锁"。

## Detailed Rules

### 1. 敌人类型

| 类型 | 类 | 场景 | 可被击败的顶面 | 首次出现 |
|------|-----|------|---------------|---------|
| 普通敌人 | `NormalEnemy` | `normal_enemy.tscn` | 冲击面, 重压面 | Level 3 |
| 重甲敌人 | `NormalEnemy`（参数变体） | `heavy_enemy.tscn` | 仅重压面 | Level 4 |

两种敌人共用 `NormalEnemy` 类，通过 `accepted_face_kinds` 导出属性区分：

| 属性 | 普通敌人 | 重甲敌人 |
|------|---------|---------|
| `accepted_face_kinds` | `["IMPACT", "HEAVY"]` | `["HEAVY"]` |
| `enemy_group_name` | `"normal_enemy"` | `"heavy_enemy"` |

### 2. 网格行为

- 敌人在 `_ready()` 中自动注册到 `GridMotor`（同步注册，非延迟）
- 敌人占据 1 个网格格子（`blocks_grid_cell = true`）
- 敌人不移动、不巡逻——位置在关卡初始化后固定
- 敌人被击败后：`blocks_grid_cell = false`，从网格注销，格子释放

### 3. 击败流程

击败由 `GridMotor.try_push_box()` 发起，不由敌人自身触发：

```text
1. 玩家推箱子 → GridMotor.try_move_actor(player, direction)
2. 箱子目标格有敌人 → GridMotor.try_push_box(box, direction)
3. GridMotor 预测箱子滚动后的顶面 → box.predict_face_kind(direction)
4. GridMotor 询问敌人是否可被该顶面击败 → enemy.can_be_defeated_by(predicted_face_kind)
5a. 可以击败 → GridMotor 注销敌人 → enemy.defeat(direction, face_kind) → 箱子移入目标格
5b. 不能击败 → 推动整体失败，玩家和箱子都不移动，显示拒绝理由
```

### 4. 击败动画

`defeat()` 方法执行以下视觉效果（持续 `defeat_duration` = 0.2s）：

| 效果 | 参数 | 缓动 |
|------|------|------|
| 弹飞位移 | 方向 * 0.65 水平 + 0.55 垂直 | TRANS_SINE, EASE_OUT |
| 旋转 | X轴 65度 + Y轴 110度 * 方向符号 | TRANS_SINE, EASE_OUT |
| 缩小消失 | 从 1.0 缩至 0.25 | TRANS_BACK, EASE_IN |

动画完成后 `queue_free()` 销毁节点。

### 5. 视觉反馈

击败时状态灯颜色根据击败所用的顶面类型切换：

| 击败顶面 | 状态灯颜色 | 灯光能量 |
|----------|-----------|---------|
| 重压面 | `DesignTokens.LIGHT_ENEMY_DEFEAT_HEAVY` | `DesignTokens.LIGHT_ENEMY_DEFEAT_ENERGY` |
| 冲击面/其他 | `DesignTokens.LIGHT_ENEMY_DEFEAT_NORMAL` | `DesignTokens.LIGHT_ENEMY_DEFEAT_ENERGY` |

### 6. 音频

敌人在 `_ready()` 中将自身的 `defeated` 信号连接到 `AudioManager.play_enemy_defeat()`。这是自注册模式（见 ADR-003），避免全局 `node_added` 监听器。

### 7. 组标识

每个敌人加入以下组：

| 组名 | 用途 |
|------|------|
| `grid_entity` | 通用网格实体标识 |
| `enemy` | GridMotor 在 `try_push_box()` 中检查此组以识别敌人 |
| `{enemy_group_name}` | 类型区分（`normal_enemy` / `heavy_enemy`） |

## Formulas

本系统使用确定性布尔判定，与 [`rolling-utility-box.md`](rolling-utility-box.md) 中定义的公式一致。

### 击败判定

```text
defeated = predicted_top_face in enemy.accepted_face_kinds
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| predicted_top_face | String | "NORMAL" / "IMPACT" / "HEAVY" / "ENERGY" | `box.predict_face_kind(direction)` | 箱子滚入敌人格后将朝上的面 |
| accepted_face_kinds | PackedStringArray | 面种类子集 | 敌人导出属性 | 该敌人可被哪些顶面击败 |

**Expected output**: true / false

**Key**: 判定使用的是**预测顶面**（箱子滚动后的状态），不是当前顶面。这保证了"看到什么就得到什么"的可预测性。

### 推动失败拒绝信息

```text
deny_reason = "%s 顶面打不过敌人" % face_kind_display_name
```

其中 `face_kind_display_name` 将英文 face kind 转为中文显示名（普通/冲击/重压/能源）。

## Edge Cases

| Scenario | Expected Behavior | Rationale | Verified In |
|----------|------------------|-----------|-------------|
| 箱子普通面朝上推向普通敌人 | 推动失败，玩家不移动 | `"NORMAL"` 不在 `["IMPACT","HEAVY"]` 中 | `grid_motor.gd:104` |
| 箱子能源面朝上推向普通敌人 | 推动失败 | `"ENERGY"` 不在 `["IMPACT","HEAVY"]` 中 | `grid_motor.gd:104` |
| 箱子冲击面朝上推向重甲敌人 | 推动失败 | `"IMPACT"` 不在 `["HEAVY"]` 中 | `grid_motor.gd:104` |
| 箱子重压面朝上推向普通敌人 | 击败成功 | `"HEAVY"` 在 `["IMPACT","HEAVY"]` 中 | `grid_motor.gd:104-108` |
| 敌人已被击败时再次调用 defeat() | 忽略（is_defeated 守卫） | 防止重复击败动画和音效 | `normal_enemy.gd:46-47` |
| 敌人被击败后箱子能否进入该格 | 可以——GridMotor 先 unregister，再 commit_move | 击败先于箱子移动 | `grid_motor.gd:105-108` |
| 同一格有两个敌人 | 不支持——GridMotor occupiers 字典一格一实体 | 关卡设计阶段避免 | `grid_motor.gd:31-33` |
| 玩家直接走向敌人 | 被阻挡（"被阻挡"拒绝信息） | 玩家不能直接攻击敌人 | `grid_motor.gd:79` |
| 关卡重置后敌人恢复 | 整个关卡场景重新实例化 | 无需单独重置逻辑 | `main.gd:188` |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| 网格引擎 (GridMotor) | This depends on GridMotor | 注册/注销网格占据；击败判定在 GridMotor 中执行 |
| 滚动功能箱 (RollingBox) | This depends on RollingBox | 需要 `predict_face_kind()` 预测滚动后顶面 |
| 网格坐标 (GridCoord) | This depends on GridCoord | `world_to_grid` / `grid_to_world` 坐标转换 |
| 设计令牌 (DesignTokens) | This depends on DesignTokens | 击败灯光颜色常量 |
| 音频管理器 (AudioManager) | This depends on AudioManager | `play_enemy_defeat()` 击败音效 |
| 滚动功能箱 GDD | RollingBox GDD references this | `rolling-utility-box.md` section 7 引用敌人击败规则 |
| 教学弧线 | Tutorial Arc depends on this | Level 3 教冲击面击败，Level 4 教重压面击败 |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `defeat_duration` | 0.2s | 0.12-0.35s | 击败动画更慢更有仪式感 | 更利落但可能不够清晰 |
| `ENEMY_HEIGHT` | 0.45 | 0.3-0.6 | 敌人更高更显眼 | 更矮更不起眼 |
| `accepted_face_kinds` (普通) | ["IMPACT","HEAVY"] | 1-3 种面 | 更容易击败 | 更难击败 |
| `accepted_face_kinds` (重甲) | ["HEAVY"] | 1-2 种面 | 更容易击败（降低难度） | 保持当前难度 |
| 弹飞水平距离 | 0.65 | 0.4-1.0 | 弹飞更远更戏剧化 | 更含蓄 |
| 弹飞垂直距离 | 0.55 | 0.3-0.8 | 弹飞更高 | 更贴地 |
| 缩小终值 | 0.25 | 0.1-0.4 | 消失前保留更多体积 | 消失更彻底 |
| 敌人种类数量 | 2 | 1-3 (MVP) | 更多组合变化 | 更聚焦教学 |
| 重甲敌人首次出现 | Level 4 | Level 3-6 | 更早加压 | 更晚但教学更平滑 |

## Acceptance Criteria

- [ ] 普通敌人可被冲击面和重压面击败
- [ ] 重甲敌人仅可被重压面击败
- [ ] 普通面和能源面无法击败任何敌人，推动被拒绝
- [ ] 击败判定使用预测顶面（滚动后），而非当前顶面
- [ ] 推动失败时玩家和箱子均不移动，显示中文拒绝理由
- [ ] 敌人被击败后从网格注销，格子可通行
- [ ] 击败动画（弹飞+旋转+缩小）在 defeat_duration 内完成
- [ ] 击败音效通过 AudioManager 播放，不重复触发
- [ ] 已击败的敌人不响应重复 defeat() 调用
- [ ] 关卡重置后所有敌人恢复初始位置和状态
- [ ] 玩家不能直接走进敌人格，只能通过箱子击败
- [ ] 每种敌人有视觉区分度，玩家能一眼分辨类型

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| 是否需要增加敌人被击败前的"预警"视觉（如箱子靠近时敌人闪烁） | UX Designer | Vertical Slice 前 | Open |
| 重甲敌人是否应有独立的击败动画（更重的弹飞、不同音效） | Art Director + Audio | Vertical Slice 前 | Open — 当前共用 NormalEnemy 类 |
| 是否引入第三种敌人类型（如仅能源面击败的"屏蔽敌人"） | Game Designer | 第 10 关设计前 | Open |
| 敌人是否应在被击败前显示"需要什么面"的提示图标 | UX Designer | Prototype 后 | Open |
