# 关卡管理系统

> **Status**: Draft
> **Author**: Codex (reverse-documented from `main.gd` + `level_root.gd`)
> **Last Updated**: 2026-03-30
> **Implements Pillar**: 滚动就是解谜 / 可爱外表，硬核规则

## Overview

关卡管理系统负责游戏会话的整体 orchestration：关卡加载与切换、输入路由、HUD 呈现、暂停与完成流程、玩家反馈提示和星星评分。该系统不包含任何游戏逻辑或网格规则，仅负责将 UI 和场景粘合在一起。

## Player Fantasy

玩家感觉游戏是一个精心制作的玩具展示台：关卡切换时有清爽的卡片滑入，通关时有星星逐一弹出充满成就感，暂停时有平滑的幕布落下。移动被拒绝时，屏幕边缘会短暂闪红并给出清晰的文字原因，让玩家立即理解错误而不感到沮丧。

## Detailed Rules

### 关卡生命周期

```
游戏启动
  → main.gd._ready()
    → _ensure_input_actions()  // 动态注册 WASD/Arrow/R/ESC
    → _load_level(0)           // 加载第 1 关
      → 清空当前关卡（_active_level.queue_free()）
      → 实例化 LEVEL_SEQUENCE[0]
      → 连接 hint_requested → _set_hint_text()
      → 连接 level_completed → _on_level_completed()
      → 连接 player.deny_feedback_requested → _on_player_deny_feedback()
      → grid_motor.reset_move_count()
      → world.add_child(level)
      → _update_level_hud()    // 动画显示关卡标题卡
      → hint_label.text = "目标加载中..."
      → hint_label.text = LevelRoot.start_hint_text

玩家完成关卡
  → GoalPad._activate_goal()
    → LevelRoot.complete_level()
      → is_level_completed = true
      → player.input_enabled = false
      → hint_requested.emit(completed_hint_text)
      → level_completed.emit()
    → main.gd._on_level_completed()
      → hint_label.text = "本关完成！"
      → grid_motor.get_move_count()
      → AudioManager.play_level_complete(move_count, _star_count_for_moves(move_count))
      → await 0.6s
      → _show_level_complete_overlay()

暂停
  → ESC 按下（level complete 叠加层可见时先关闭它）
    → _show_pause_overlay()
      → get_tree().paused = true
      → AudioManager.play_pause_open()
    或
    → _hide_pause_overlay()
      → get_tree().paused = false
      → AudioManager.play_pause_close()
```

### 输入路由

`main.gd._input()` 是唯一的输入入口点，拦截所有键盘事件并路由：

| 按键 | 动作 | 条件 |
|------|------|------|
| W / Arrow Up | `try_move_actor(player, Vector2i.UP)` | 未暂停 + `input_enabled` |
| S / Arrow Down | `try_move_actor(player, Vector2i.DOWN)` | 同上 |
| A / Arrow Left | `try_move_actor(player, Vector2i.LEFT)` | 同上 |
| D / Arrow Right | `try_move_actor(player, Vector2i.RIGHT)` | 同上 |
| R | `_load_level(_current_level_index)` | 未暂停 + 未在退出动画中 |
| ESC | 暂停切换 / 关闭通关叠加层 | — |

输入首先检查 `player.input_enabled != false`，确保关卡完成后玩家无法继续移动。

### 暂停流程

| 状态 | 进入条件 | 退出条件 |
|------|---------|---------|
| 运行中 | 初始 / `_hide_pause_overlay()` 完成 | ESC 按下 |
| 暂停中 | ESC 按下，`get_tree().paused = true` | 继续按钮 / 重新开始按钮 / 退出按钮 |

暂停菜单三个按钮：
- **继续** → `_on_pause_resume_pressed()` → `play_pause_close()` → `_hide_pause_overlay()`
- **重新开始** → `_on_pause_restart_pressed()` → 关闭暂停 → 0.3s 延迟 → `_load_level(current)`
- **退出游戏** → `_on_pause_quit_pressed()` → 关闭暂停 → 0.3s 延迟 → `get_tree().quit()`

### 通关叠加层

通关叠加层在 `_on_level_completed()` 触发后 0.6s 自动弹出，不可跳过。

**动画时序**：

```
t=0ms     显示 overlay，card scale=0.85, alpha=0, darken alpha=0
t=0–250ms darken alpha 0→0.60 (CUBIC ease-out)
t=0–350ms card alpha 0→1 + scale 0.85→1.0 (BACK ease-out)
t=430ms   star1 scale 0→1.15→1.0 (BACK ease-out)，delay=0
t=510ms   star2 scale 动画，delay=0.08s
t=590ms   star3 scale 动画，delay=0.16s
t=770ms   button_row alpha 0→1 (SINE ease-out)
```

**星星评分**：

| 星星数 | 条件 |
|--------|------|
| ⭐⭐⭐ (3) | `moves <= star3_max`（各关卡不同，见 LEVEL_PRESENTATION） |
| ⭐⭐ (2) | `star3_max < moves <= star2_max` |
| ⭐ (1) | `moves > star2_max` |

通关叠加层右上角有"Next / Replay / Select"三按钮，MVP 中 Select 按钮不可见（`complete_select_btn.visible = false`）。

最后一关（index=4）通关后：
- kicker 显示"教程 05 / 05"，title 显示"教程已完成！"
- Next 按钮会循环回到第 1 关
- Replay 按钮变成金色样式

### 拒绝反馈（移动被阻挡）

当玩家尝试移动被 `GridMotor.move_denied` 拒绝时，`main.gd._on_player_deny_feedback()` 处理两层视觉反馈：

| 层级 | 效果 | 时长 |
|------|------|------|
| Layer 2 | `ObjectiveCard` 边框闪红色 `Color(1.0, 0.35, 0.35, 0.9)` | 0.15s |
| Layer 4 | `HintLabel` 整体变为 `Color(1.0, 0.7, 0.7)`（淡红） | 0.4s |

同时 `hint_label.text` 变为 `[ 拒绝原因 ]`，并在 `_deny_restore_delay = 2.0s` 后恢复原始 hint 文本。

### 关卡 HUD 元素

| 元素 | 节点路径 | 内容来源 |
|------|---------|---------|
| Level kicker | `LevelKickerLabel` | `LEVEL_PRESENTATION[index]["kicker"]` |
| Level title | `LevelTitleLabel` | `LEVEL_PRESENTATION[index]["title"]` |
| Level subtitle | `LevelSubtitleLabel` | `LEVEL_PRESENTATION[index]["subtitle"]` |
| Controls hint | `ControlsLabel` | `CONTROL_HINT_TEXT` 常量 |
| Hint text | `HintLabel` | LevelRoot `start_hint_text` / `completed_hint_text` / 拒绝原因 |

关卡标题卡（`LevelCard`）在 `_load_level()` 时执行淡入动画：`alpha 0→1` over 0.4s（SINE ease-out）。

## Formulas

### 星星评分

```text
star_count(moves) = 3, if moves <= star3_max
                  = 2, if star3_max < moves <= star2_max
                  = 1, otherwise
```

| 变量 | 类型 | 值来源 | 示例（Level 1） |
|------|------|-------|----------------|
| `moves` | int | `GridMotor.get_move_count()` | 6 |
| `star3_max` | int | `LEVEL_PRESENTATION[index]["star3_max"]` | 6 |
| `star2_max` | int | `LEVEL_PRESENTATION[index]["star2_max"]` | 10 |

### 关卡呈现数据（5 个教程关卡）

| 关卡 | kicker | star3_max | star2_max |
|------|--------|-----------|-----------|
| 1 | 教程 01 / 05 | 6 | 10 |
| 2 | 教程 02 / 05 | 8 | 14 |
| 3 | 教程 03 / 05 | 10 | 16 |
| 4 | 教程 04 / 05 | 12 | 18 |
| 5 | 教程 05 / 05 | 16 | 24 |

### 拒绝恢复延迟

```text
_deny_restore_timer = _deny_restore_delay  ## 2.0s
hint_label.text = "[ 拒绝原因 ]"
## 2.0s 后
hint_label.text = _stored_hint  ## 恢复原始 hint
```

### 叠加层动画时间

| 动画 | 持续时间 | 缓动 |
|------|---------|------|
| 通关 darken 进入 | 250ms | TRANS_CUBIC, EASE_OUT |
| 通关 card 进入 | 350ms | TRANS_BACK, EASE_OUT |
| 通关 star 弹出 | 180ms (90ms+90ms) | TRANS_BACK, EASE_OUT |
| 通关 button row 淡入 | 150ms | TRANS_SINE, EASE_OUT |
| 通关 overlay 关闭 | 250ms | TRANS_CUBIC, EASE_IN |
| 暂停 darken 进入 | 200ms | TRANS_CUBIC, EASE_OUT |
| 暂停 card 进入 | 300ms | TRANS_BACK, EASE_OUT |
| 暂停 overlay 关闭 | 250ms | TRANS_CUBIC, EASE_IN |
| 关闭延迟（按钮到加载） | 300ms | — |
| 关卡标题卡淡入 | 400ms | TRANS_SINE, EASE_OUT |
| Hint 文字切换 | 150ms fade out + 150ms fade in | TRANS_SINE, EASE_OUT |

## Edge Cases

| 场景 | 预期行为 | 依据 |
|------|---------|------|
| 玩家在加载新关卡时快速按 R | 忽略（`is_animating_out` 守卫） | `_is_animating_out` guard on all button handlers |
| 玩家在通关动画期间按 ESC | 无响应（`is_animating_out` 守卫） | `_is_animating_out` guard |
| 玩家在最后一关点 Next | 循环回到 Level 1 | `_on_complete_next_pressed()`: `next_idx = 0` when `next_idx >= LEVEL_SEQUENCE.size()` |
| LevelRoot 发送第二次 `complete_level()` | 不重复触发（`is_level_completed` 守卫） | `LevelRoot.complete_level()` 开头检查 `is_level_completed` |
| `hint_requested` 信号在关卡切换时仍有待处理 | 旧 hint 在 `_load_level()` 开始时被清空 | `_load_level()` 中 `_deny_restore_timer = 0.0` 重置 |
| Player 节点在 `_try_connect_player_deny_signal()` 时机早于玩家节点创建 | 延迟到 `get_tree().get_first_node_in_group("player")` | `_try_connect_player_deny_signal()` 在 `_load_level()` 中调用；若 player 为 null，下一帧若 nodeAdded 可重新尝试 |
| 暂停菜单打开时网格实体仍在动画中 | `get_tree().paused = true` 冻结所有节点 `_process` | Godot 引擎行为 |
| Level presentation 数据缺失 | HUD 使用 fallback 值"原型"/"未命名关卡" | `_update_level_hud()` 中 `presentation.get("kicker", "原型")` |
| InputMap 已有该 action 且有 events | 跳过注册，跳过重复添加 | `_ensure_input_actions()` 中 `if not InputMap.action_get_events(action_name).is_empty(): continue` |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| GridMotor | main.gd queries GridMotor | `reset_move_count()` / `get_move_count()` / `try_move_actor()` |
| Player | main.gd depends on Player | 读取 `input_enabled`；连接 `deny_feedback_requested` 信号 |
| LevelRoot | main.gd depends on LevelRoot | 监听 `hint_requested` 和 `level_completed` 信号 |
| AudioManager | main.gd calls AudioManager | 脚步声、移动拒绝、暂停开关、关卡完成音效 |
| DesignTokens | main.gd uses DesignTokens | `ACCENT_GOLD_STAR` 用于最后一关 replay 按钮样式 |
| 叠加层场景 | main.gd owns overlay nodes | 暂停叠加层（`PauseOverlay`）和通关叠加层（`LevelCompleteOverlay`）作为 CanvasLayer 子节点 |
| 关卡序列 | main.gd owns `LEVEL_SEQUENCE` | 5 个教程关卡 scene 文件路径 |
| Godot InputMap | main.gd modifies InputMap | `_ensure_input_actions()` 动态注册按键映射 |

## Tuning Knobs

| 参数 | 当前值 | 安全范围 | 增大效果 | 减小效果 |
|------|-------|---------|---------|---------|
| `_deny_restore_delay` | 2.0s | 1.0–4.0s | 拒绝提示停留更久 | 更快消失但可能没看清 |
| `_deny_feedback_active` guard | 单一布尔防止多层叠加 | — | — | — |
| 暂停进入 darken 透明度 | 0.55 | 0.3–0.8 | 更暗的暂停背景 | 更通透 |
| 暂停进入时长 | 200ms | 100–400ms | 更沉稳的暂停感 | 更干脆 |
| 通关 darken 透明度 | 0.60 | 0.4–0.8 | 更强的通关仪式感 | 更轻快 |
| 通关 card 进入时长 | 350ms | 200–500ms | 更饱满的弹窗感 | 更急促 |
| star 弹出间隔 | 80ms | 50–150ms | 星星更有节奏 | 更密集 |
| 关闭过渡时长 | 250ms | 150–400ms | 更优雅的退出 | 更快速 |
| 按钮触发到加载延迟 | 0.30s | 0.15–0.50s | 动画完成后操作 | 更快响应 |
| `star3_max` / `star2_max` | 各关不同 | 取决于目标难度 | 见 LEVEL_PRESENTATION 表 | — |

## Acceptance Criteria

- [ ] 游戏启动后自动加载 Level 1，无黑屏或崩溃
- [ ] WASD / 方向键每帧正确路由到 GridMotor.try_move_actor()
- [ ] R 键立即重新加载当前关卡，步数清零
- [ ] ESC 在运行中打开暂停菜单，在暂停中关闭暂停菜单
- [ ] 暂停时 `get_tree().paused = true`，所有游戏动画冻结
- [ ] 玩家在 LevelRoot 发送 `level_completed` 后 `input_enabled = false`
- [ ] 通关叠加层在 `_on_level_completed()` 后 0.6s 准时弹出
- [ ] 星星根据步数正确计算（3/2/1 星），与 LEVEL_PRESENTATION 数据一致
- [ ] 星星逐一弹出动画顺序正确（star1 → star2 → star3）
- [ ] 拒绝反馈的红色闪烁和 hint 文字变色同时发生
- [ ] hint 文字在 2.0s 后正确恢复为关卡原始 hint
- [ ] 最后一关完成后 Next 按钮循环回到第 1 关
- [ ] 关卡加载时 HUD 标题卡有淡入动画
- [ ] InputMap 动态注册不重复添加已存在的 action
- [ ] `complete_select_btn` 在 MVP 中保持隐藏

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| 是否需要关卡选择界面 | Game Designer | Vertical Slice 前 | MVP 中 `complete_select_btn` 隐藏，待后续实现 |
| 是否需要"继续游戏"存档/读档功能 | Game Designer | Vertical Slice 前 | Open — 当前无持久化存储 |
| 通关后是否需要展示关卡重玩排行榜 | Game Designer | Alpha 后 | Open — 当前仅记录本次通关 |
| 暂停菜单是否需要静音选项 | UX Designer | Vertical Slice 前 | Open — 当前无音量控制 UI |
| 是否需要加速模式（调试用） | Lead Programmer | Alpha 前 | Open — 当前无 |
