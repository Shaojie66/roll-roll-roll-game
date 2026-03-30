# Enemy System — 敌人系统

> **Status**: Implemented + Expanded
> **Author**: Game Designer (reverse-documented from normal_enemy.gd + GridMotor)
> **Last Updated**: 2026-03-31
> **Implementation Complete**: S3-002 Enemy System GDD — normal_enemy.gd implemented in Sprint 2
> **Expanded**: S3-009 — ShieldEnemy + SplitterEnemy added
> **Implements Pillar**: 可爱外表，硬核规则 / 滚动就是解谜

## Overview

敌人系统定义了敌人的注册、击败判定、死亡动画和网格Motor集成。敌人是网格上的静态阻挡物，箱子在特定顶面状态下撞击敌人会触发击败。敌人本身不移动，不主动攻击玩家。玩家不直接战斗 — 箱子是唯一的武器。

本扩展增加了两种新敌人类型：ShieldEnemy（需要两次打击才能击败）和 SplitterEnemy（被击败时会分裂出两个子敌人）。

---

## Player Fantasy

敌人是一个等待被智取的目标。玩家不是去打倒它，而是看懂了局面，算好了箱子的顶面，在正确的时机推动箱子碾压过去。击败敌人是空间推理的奖赏，不是操作的反应速度。

ShieldEnemy 带来新的张力：它有盾，挡住你第一次进攻。你必须计划两次连续的攻击。SplitterEnemy 带来后果感：你击败它的位置决定了局面是变得更简单还是更复杂。

---

## Detailed Rules

### Enemy Registration

所有敌人通过 GridMotor 的 `occupiers` 字典注册自己（`blocks_grid_cell = true`）。敌人不接受 GridMotor 移动指令。

```
GridMotor.occupiers[Vector2i(5, 2)] = NormalEnemy.new()
```

### Defeat Conditions

箱子撞击敌人时，GridMotor 查询箱子的当前顶面类型和敌人的 `accepted_face_kinds` 白名单：

```
try_push_box(box, direction):
  if occupant.is_in_group("enemy"):
    predicted_face = box.predict_face_kind(direction)  # 箱子滚动后顶面
    if occupant.can_be_defeated_by(predicted_face):
      occupant.defeat(direction, predicted_face)
      _commit_move(box, target, direction)
      return true
```

#### can_be_defeated_by(face_kind: String) -> bool

| 敌人类型 | accepted_face_kinds | 击败行为 |
|---------|---------------------|---------|
| NormalEnemy | `["IMPACT", "HEAVY"]` | 1 hit — 直接死亡 |
| ShieldEnemy | `["IMPACT", "HEAVY"]` | 2 hits — 第1击破盾，第2击死亡 |
| SplitterEnemy | `["IMPACT", "HEAVY"]` | 1 hit — 死亡并分裂 |
| HeavyEnemy | `["HEAVY"]` | 1 hit — 直接死亡（未实现） |
| EnergyEnemy | `["ENERGY"]` | 1 hit — 直接死亡（未实现） |

不在白名单内的 face_kind → 拒绝，箱子被阻挡。

### ShieldEnemy Defeat Logic

ShieldEnemy 有一个内部状态 `shield_hp: int`，初始值为 1。

```
can_be_defeated_by(face_kind: String) -> bool:
  if face_kind not in accepted_face_kinds:
    return false
  return true  # 盾牌存在时也接受打击，但不立即死亡

defeat(direction: Vector2, face_kind: String):
  if is_defeated:
    return  # 忽略第二次击败
  if shield_hp > 0:
    shield_hp -= 1
    _play_shield_break_animation()
    _update_visual_for_unshielded()
    return  # 不死亡，不从occupiers移除
  # shield_hp == 0 时执行普通死亡逻辑
  _do_normal_defeat(direction, face_kind)
```

关键语义：ShieldEnemy 在盾存在时接受 IMPACT/HEAVY 打击（`can_be_defeated_by` 返回 true），箱子正常滚动过去。第1击触发破盾动画，敌人留在原位。第2击才触发正常死亡。

### SplitterEnemy Defeat Logic

SplitterEnemy 被击败时，在当前格子的两个相邻空格（根据击败方向决定哪两个相邻格）中各生成一个 `SplitterMinion` 子敌人。

```
defeat(direction: Vector2, face_kind: String):
  if is_defeated:
    return
  _do_normal_defeat(direction, face_kind)
  _spawn_minions(direction, face_kind)

_spawn_minions(direction: Vector2, face_kind: String):
  # 计算两个子敌人的目标格子
  # 方向垂直于击败方向：在direction的左右两侧
  perpendicular = Vector2(-direction.y, direction.x)
  cell_a = self.grid_position + perpendicular
  cell_b = self.grid_position - perpendicular
  for target_cell in [cell_a, cell_b]:
    if GridMotor.is_cell_empty(target_cell):
      minion = SplitterMinion.new()
      minion.grid_position = target_cell
      GridMotor.register_entity(minion, target_cell)
```

#### SplitterMinion 子敌人

- accepted_face_kinds: `["IMPACT", "HEAVY"]`
- 外观：比 SplitterEnemy 小50%，没有分裂能力
- 击败后不产生任何子敌人
- 单独实现，不继承 SplitterEnemy

### Defeat Animation Sequence

#### NormalEnemy / HeavyEnemy / EnergyEnemy / SplitterMinion

```
1. is_defeated = true
2. blocks_grid_cell = false
3. status_light 变金色/橙色
4. Tween 动画 (并行):
   - global_position → global_position + launch_offset
   - visual.rotation → visual.rotation + spin_offset
   - visual.scale → Vector3(0.25)
5. Tween 结束后 queue_free()
6. 播放 defeat 音效
```

#### ShieldEnemy — Shield Break (第1击)

```
1. shield_hp = 0
2. status_light 变暗
3. Tween 动画:
   - shield_piece.global_position → shield_piece.global_position + shield_fly_offset
   - shield_piece.rotation → shield_piece.rotation + 180°
   - shield_piece.scale → Vector3(0.1)
4. shield_mesh.visible = false
5. 播放 shield_break 音效
6. 敌人本体不移动，不从occupiers移除
```

#### ShieldEnemy — Death (第2击)

同 NormalEnemy 的标准死亡动画。

#### SplitterEnemy — Split Animation

```
1. is_defeated = true
2. blocks_grid_cell = false
3. status_light 变金色
4. Tween 动画 (并行):
   - global_position → global_position + launch_offset
   - visual.scale → Vector3(0.25)
5. Tween 结束后 queue_free()
6. 播放 split_spawn 音效
7. 两个 SplitterMinion 从分裂点出现（缩放从0到1 + 淡入）
```

---

## Enemy Variants

### NormalEnemy

**行为**：静态阻挡物。被 IMPACT 或 HEAVY 顶面箱子撞击时1击死亡。

**视觉**：
- 主色：橙色（`#E07B39`）
- 形状：立方体敌人，略高于地面
- 状态灯：顶部小的圆形指示灯
- 发光：无

**Defeat 动画参数**：
- launch_offset: `Vector3(direction.x * 0.65, 0.55, direction.y * 0.65)`
- spin: `Vector3(65° * spin_sign, 110° * spin_sign, 0)`
- spin_sign: `direction.x < 0 or direction.y < 0 ? -1.0 : 1.0`
- duration: `defeat_duration` (默认 0.2s)
- scale_to: `0.25`

---

### ShieldEnemy

**行为**：静态阻挡物，有1点盾牌HP。接受 IMPACT/HEAVY 打击。第1击打破盾牌并留下敌人；第2击才杀死。盾牌存在时，敌人仍然阻挡箱子滚动（箱子可以正常推过）。

**视觉**：
- 主色：冰蓝色（`#7EC8E3`）
- 形状：NormalEnemy 基础上，顶部有一个透明盾形弧线（弧线高约0.3格）
- 盾牌材质：半透明蓝紫色，带有微弱发光
- 状态灯：盾存在时亮蓝色，盾牌破碎后变暗
- 发光：盾牌有柔和的蓝紫光晕

**Defeat 动画参数（盾破）**：
- shield_fly_offset: `Vector3(direction.x * 0.4, 0.8, direction.y * 0.4)`
- shield_spin: `Vector3(0, 180°, 0)`
- shield_scale_to: `0.1`
- shield_break_duration: `0.25s`
- 音效：`SHIELD_BREAK`

**Defeat 动画参数（死亡）**：
- 同 NormalEnemy，launch_offset.y = 0.5（比 NormalEnemy 略低）
- 音效：`SHIELD_ENEMY_DEFEAT`

---

### SplitterEnemy

**行为**：静态阻挡物。被击败时在两个垂直于击败方向的相邻空格中生成 SplitterMinion。如果两个目标格子都不为空（已被占据或超出边界），则不生成任何子敌人（分裂失败）。SplitterMinion 存活并可以正常被击败。

**视觉**：
- 主色：深红色（`#C94C4C`）
- 形状：NormalEnemy 基础上，身体有裂纹纹理（表明它是不稳定的）
- 状态灯：顶部有两个小圆形指示灯（暗示它内部有多个个体）
- 发光：身体裂缝处有暗红色微光

**Defeat 动画参数**：
- launch_offset: `Vector3(direction.x * 0.65, 0.65, direction.y * 0.65)`（比 NormalEnemy 飞得更高）
- spin: `Vector3(90° * spin_sign, 0, 0)`（只有X轴翻滚，不旋转Y轴）
- scale_to: `0.25`
- duration: `defeat_duration` (默认 0.2s)
- 音效：`SPLITTER_DEFEAT`

**SplitterMinion 视觉**：
- 主色：浅红色（`#E07070`）
- 形状：正常敌人的50%大小版本，简洁圆润
- 无裂纹纹理
- 状态灯：单个
- 发光：无

**分裂动画参数（Minion 出现）**：
- scale_from: `0.0`
- scale_to: `1.0`
- opacity_from: `0.0`
- opacity_to: `1.0`
- duration: `0.3s`
- 音效：`MINION_SPAWN`

---

## Edge Cases

| 场景 | 处理方式 |
|------|---------|
| 箱子撞上敌人但顶面不对 | GridMotor.try_push_box 返回 false，箱子停在原位 |
| 敌人已被击败后再次被撞 | defeat() 检查 is_defeated，忽略第二次击败 |
| 箱子滚动动画中敌人消失 | defeat() 设置 blocks_grid_cell=false，occupiers 字典已更新，不影响碰撞查询 |
| 敌人和箱子同时占据同一格 | GridMotor.register_entity 覆盖警告，正常处理 |
| 玩家自己走到敌人格子上 | GridMotor.try_move_actor 检查 occupant.is_in_group("enemy")，玩家被阻挡 |
| **ShieldEnemy：第1击后玩家再次撞击同一敌人** | 同 NormalEnemy，第2击触发死亡 |
| **ShieldEnemy：玩家用非IMPACT/HEAVY顶面撞击盾牌** | can_be_defeated_by 返回 false，箱子被阻挡（盾牌不接受NORMAL/ENERGY） |
| **ShieldEnemy：盾牌破碎时敌人已不在原位** | 盾牌动画独立播放，不依赖主体位置 |
| **SplitterEnemy：两个相邻格都被占据** | _spawn_minions 检测到目标格不为空，跳过该格；如果两个都满则完全不生成子敌人 |
| **SplitterEnemy：只有一个相邻格为空** | 只生成一个 SplitterMinion，另一个格子被跳过 |
| **SplitterEnemy：分裂出的Minion正上方有箱子** | GridMotor.is_cell_empty 检测到Occupier，不生成Minion（不会挤占已有实体） |
| **SplitterEnemy：分裂方向指向网格外** | _spawn_minions 检测到目标在网格外，跳过该方向 |
| **SplitterMinion 被击败** | 执行标准死亡动画，不产生任何分裂行为 |

---

## Dependencies

| 系统 | 接触点 |
|------|--------|
| GridMotor | `occupiers` 注册、`try_push_box()` 击败判定、`is_cell_empty()` 分裂检测 |
| RollingBox | `predict_face_kind()` 查询顶面类型 |
| AudioManager | defeat 音效 (`LIGHT_ENEMY_DEFEAT_HEAVY / NORMAL`, `SHIELD_BREAK`, `SHIELD_ENEMY_DEFEAT`, `SPLITTER_DEFEAT`, `MINION_SPAWN`) |
| DesignTokens | `LIGHT_ENEMY_DEFEAT_HEAVY`, `LIGHT_ENEMY_DEFEAT_NORMAL`, `LIGHT_ENEMY_DEFEAT_ENERGY`, `SHIELD_BREAK`, `SPLITTER_DEFEAT` |

---

## Tuning Knobs

### Shared (all enemy types)

| 参数 | 默认值 | 可调范围 | 影响 |
|------|-----|--------|------|
| `defeat_duration` | 0.2s | 0.1–0.5s | 击败动画速度，越小越爽快 |
| `launch_offset.y` | 0.55 | 0.3–0.8 | 敌人飞起高度 |
| `spin_degrees.x` | 65° | 30°–120° | 翻滚幅度 |
| `scale_to` | 0.25 | 0.1–0.4 | 消失时缩小比例 |

### ShieldEnemy-specific

| 参数 | 默认值 | 可调范围 | 影响 |
|------|-----|--------|------|
| `shield_break_duration` | 0.25s | 0.15–0.4s | 盾牌破碎动画速度 |
| `shield_fly_offset.y` | 0.8 | 0.5–1.2 | 盾牌飞起高度 |
| `shield_spin.y` | 180° | 90°–270° | 盾牌旋转角度 |
| `shield_scale_to` | 0.1 | 0.05–0.2 | 盾牌消失时缩小比例 |
| `death_launch_offset.y` | 0.5 | 0.3–0.7 | 盾牌破碎后死亡时的飞起高度（比Normal稍低） |

### SplitterEnemy-specific

| 参数 | 默认值 | 可调范围 | 影响 |
|------|-----|--------|------|
| `split_launch_offset.y` | 0.65 | 0.4–0.9 | 分裂时主体飞起高度 |
| `split_spin_degrees.x` | 90° | 60°–120° | 分裂时翻滚幅度（仅X轴） |
| `minion_spawn_duration` | 0.3s | 0.2–0.5s | 子敌人出现动画时长 |
| `minion_size_ratio` | 0.5 | 0.3–0.7 | 子敌人相对于主体的尺寸比例 |

---

## Acceptance Criteria

- [x] NormalEnemy 被 IMPACT 顶面箱子击败
- [x] NormalEnemy 不被 NORMAL 顶面箱子击败
- [x] 击败动画正确播放（飞起+旋转+消失）
- [x] 击败后敌人从 GridMotor.occupiers 正确移除
- [x] 音效正确触发
- [x] 多次击败同一敌人被忽略
- [x] HeavyEnemy/EnergyEnemy 类型可扩展
- [x] ShieldEnemy 第1击 IMPACT/HEAVY 接受打击，破盾动画播放，敌人留在原位
- [x] ShieldEnemy 第2击 IMPACT/HEAVY 击败敌人，死亡动画播放
- [x] ShieldEnemy 不被 NORMAL 顶面箱子击败（盾牌不接受）
- [x] ShieldEnemy 盾牌破碎后视觉正确（盾消失，本体颜色不变）
- [x] SplitterEnemy 被击败后分裂动画播放
- [x] SplitterMinion 在正确的两个相邻格中生成
- [x] SplitterMinion 可以被 IMPACT/HEAVY 顶面箱子击败
- [x] SplitterMinion 被击败后不再分裂
- [x] 两个相邻格都满时 SplitterEnemy 不产生 Minion
- [ ] 分裂音效和 Minion 出现音效正确触发

---

## Open Questions

1. **敌人是否有 HP（多击杀死）？** — 已解答：ShieldEnemy 实现了1点盾牌HP
2. **敌人是否需要独立的 GDD 章节？** — 已解答：每种敌人类型内联在此文档 Enemy Variants 章节
3. **敌人变种的外观如何区分？** — 已解答：Normal=橙色，Shield=冰蓝+盾形，Splitter=深红+裂纹
4. **SplitterEnemy 分裂出的 Minion 是否有独立场景文件？** — 建议：独立 scene + script，便于单独调整参数
5. **ShieldEnemy 盾牌破碎后的碎片是否有碰撞？** — 建议：无碰撞，仅视觉动画
