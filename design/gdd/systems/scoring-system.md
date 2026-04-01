# Scoring System — 评分系统

> **Status**: Draft
> **Author**: Game Designer
> **Last Updated**: 2026-04-01
> **Implementation Target**: Sprint 4 (if deferred from MVP) or VS+ phase
> **Implements Pillar**: 滚动就是解谜 / 可爱外表，硬核规则

## Overview

评分系统为每个关卡提供 1-3 星评级，基于玩家完成的步数与关卡标准步数（par）的比较。评分系统不阻塞游戏进度，仅用于追踪玩家表现和提供重复挑战动机。

> **Scope Note**: 评分系统是 VS+ 功能。MVP 不包含评分。Milestone 02 的 Gate Criteria 已将评分系统标记为 deferred。

---

## Player Fantasy

每一次通关都是一次自我超越。玩家看到自己的步数与"完美通关"的差距，然后说"再来一次，我能更好"。星星不是强制目标，而是给想要优化的玩家一个方向。

---

## Detailed Rules

### Star Rating Calculation

玩家完成关卡时，根据实际移动步数与关卡标准步数（par_moves）的比较计算星级：

| 星级 | 条件 | 视觉表现 |
|------|------|---------|
| ★★★ | move_count ≤ par_moves | 金色星 |
| ★★☆ | par_moves < move_count ≤ par_moves × 1.5 | 银色星 |
| ★☆☆ | move_count > par_moves × 1.5 | 铜色星 |
| —/— | 未达成（游戏结束前退出） | 灰色虚线 |

### Move Counter

- 移动计数器记录玩家每次有效移动（不是视角转动或菜单操作）
- 推动箱子算 1 次移动
- 移动被阻挡（撞墙）时：如果格子不变，不计数；如果格子变化，计数
- 重置关卡（R键）：计数器清零，不计入历史

### Par Calculation

每关的 par_moves 由关卡设计师在 LevelRoot 中设定：
```
[Global]
par_moves = 12  # 设计师认为的"理想"完成步数
```

Par 的确定原则：
- Par 是"第一次能完成的步数"，不是"最优解"
- Par 应该让普通玩家在 2-3 次尝试内达成
- Par 不公开显示，只在通关后对比用

### Level Completion Trigger

- 玩家到达 goal_pad 且 goal_pad.activated == true 时触发评分计算
- 评分计算是同步的，不阻塞游戏进程

---

## Formulas

### Star Rating Formula

```
star_rating = calculate_stars(move_count: int, par_moves: int) -> int:
    if move_count <= par_moves:
        return 3
    elif move_count <= par_moves * 1.5:
        return 2
    else:
        return 1
```

| 变量 | 类型 | 说明 |
|------|------|------|
| `move_count` | int | 玩家实际移动步数 |
| `par_moves` | int | 关卡标准步数（LevelRoot 设置） |
| `star_rating` | int | 返回 1-3 |

### Star Threshold Calculation

```
three_star_threshold = par_moves
two_star_threshold = floor(par_moves * 1.5)
one_star_threshold = infinity  # 超过两星阈值即得一星
```

---

## Edge Cases

| 场景 | 处理方式 |
|------|---------|
| 玩家在通关前退出（ESC暂停→退出） | 不计入评分，显示 —/— |
| 移动计数器溢出 | 上限 9999，溢出按 9999 处理 |
| par_moves 未设置 | 默认值 99（极难达成三星） |
| 0 步通关 | 可能（某些利用地形击杀敌人的关卡），正常计算 |
| 负数步数 | 不可能，计数不可能为负 |

---

## Dependencies

| 系统 | 接触点 |
|------|--------|
| GridMotor | `_move_count` 变量用于星级计算 |
| LevelRoot | `par_moves` 属性定义 |
| UI/HUD System | LevelCompleteOverlay 显示星星 |
| AudioManager | 星级达成时播放对应 SFX |

---

## Tuning Knobs

| 参数 | 默认值 | 可调范围 | 影响 |
|------|-----|--------|------|
| `two_star_multiplier` | 1.5 | 1.2–2.0 | 两星阈值 = par × multiplier |
| `star_reveal_delay` | 0.1s | 0.05–0.3s | 星星逐个弹出动画延迟 |
| `par_default` | 99 | 5–200 | par 未设置时的默认值 |

---

## Acceptance Criteria

- [ ] 移动计数器在玩家移动时正确递增
- [ ] 星级计算公式正确（≤par=3星，≤1.5×par=2星，>1.5×par=1星）
- [ ] LevelCompleteOverlay 显示正确数量和颜色的星星
- [ ] 玩家在 goal_pad 激活时触发评分计算
- [ ] R 键重置时计数器清零
- [ ] 退出关卡不产生评分记录

---

## Open Questions

| # | Question | Status |
|---|----------|--------|
| 1 | 是否需要"全关卡总星级"追踪？ | Open — deferred to VS+ |
| 2 | 是否需要显示"距离下一星还差X步"？ | Open — deferred to VS+ |
| 3 | 是否需要"无伤通关"特殊奖励？ | Open — deferred to VS+ |
