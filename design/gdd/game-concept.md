# Game Concept: 玩具星港：滚滚滚

*Created: 2026-03-21*
*Status: Draft*

---

## Elevator Pitch

> 《玩具星港：滚滚滚》是一款 3D 可爱风关卡解谜游戏，你要在漂浮于宇宙中的玩具仓库里推动并滚动功能箱，让同一个箱子在开门、压按钮、撞击敌人之间切换用途，最终把自己送到出口。
>
> 它像经典推箱子，and also 箱子在滚动时会改变状态，所以路线规划本身就是解谜与战斗。

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | 3D 关卡解谜 / 推箱子 / 轻战斗 |
| **Platform** | PC 首发 |
| **Target Audience** | 喜欢清晰规则、低门槛但有思考深度的解谜玩家 |
| **Player Count** | Single-player |
| **Session Length** | 单关 3-10 分钟，单次游玩 20-40 分钟 |
| **Monetization** | Premium |
| **Estimated Scope** | Small |
| **Comparable Titles** | Sokoban, Captain Toad Treasure Tracker, Stephen's Sausage Roll |

---

## Core Fantasy

玩家扮演一个圆滚滚的小快递员，在像玩具一样可爱的太空仓库里，用聪明而优雅的方式操控功能箱。真正的乐趣不是蛮力推进，而是看懂空间、预判滚动后的状态变化，并把同一个箱子同时当作钥匙、桥梁、压重物和武器来使用。

这份幻想的重点是“把麻烦的环境变成自己的工具”。玩家获得的不是强攻击力，而是“我看懂了这个局面，我用一个箱子同时解决了三个问题”的满足感。

---

## Unique Hook

本作的独特卖点是：`箱子不是静态障碍物，而是会在滚动中切换功能的六面工具。`

传统推箱子主要在想“把箱子推到哪里”。本作要求玩家同时思考：
- 这个箱子会滚到哪里
- 它滚到目的地时顶面会变成什么
- 这个状态更适合压按钮，还是拿去撞敌人
- 如果把它用在战斗上，我还能不能把它回收去开门

这个机制抽象自桌面游戏《滚滚滚》中的“滚动改变单位状态”思路，但在电子游戏里被重构为更易理解的单人关卡规则：状态变化不再服务多人博弈，而是服务清晰、确定性的解谜与轻战斗。

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Sensation** (sensory pleasure) | 3 | 柔和玩具材质、清晰滚动动画、按钮与机关的爽快反馈 |
| **Fantasy** (make-believe, role-playing) | 4 | 扮演小快递员整理混乱星港，把宇宙仓库当玩具盒操控 |
| **Narrative** (drama, story arc) | 7 | 轻量环境叙事，不以剧情推进为核心 |
| **Challenge** (obstacle course, mastery) | 1 | 关卡推演、状态规划、路线最优化 |
| **Fellowship** (social connection) | N/A | 单人项目，不以社交为目标 |
| **Discovery** (exploration, secrets) | 5 | 学会箱子状态组合、发现隐藏解法和捷径 |
| **Expression** (self-expression, creativity) | 6 | 允许多种过关顺序，但不做高自由度建造 |
| **Submission** (relaxation, comfort zone) | 2 | 可爱美术、低暴力表达、失败后快速重来 |

### Key Dynamics (Emergent player behaviors)

- 玩家会先观察整个关卡，再决定先把箱子用于机关还是用于战斗。
- 玩家会自然记忆“这个面滚一下会变成什么”，逐渐形成空间心算。
- 玩家会尝试把同一个箱子重复利用，追求“一箱多用”的高效解法。
- 玩家会在失败后立刻复盘，因为规则确定，错误可以被理解而不是归咎于运气。

### Core Mechanics (Systems we build)

1. **网格移动与滚动箱系统**：角色和箱子按格子移动，箱子每滚动一格就改变朝向与当前功能。
2. **六面功能状态系统**：箱子拥有普通面、冲击面、重压面、能源面，不同顶面决定可交互对象。
3. **机关联动系统**：普通按钮、重压按钮、能源槽、门、传送带、坡道共同构成谜题网络。
4. **确定性撞击战斗系统**：玩家不直接攻击，箱子在特定状态下撞击敌人时产生确定结果。
5. **小型手工关卡系统**：每关围绕 1 个新规则或 1 个规则组合展开教学和变体。

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** (freedom, meaningful choice) | 玩家可自行决定先解门、先打敌人，还是先布置箱子路径 | Core |
| **Competence** (mastery, skill growth) | 玩家会逐步掌握箱子顶面变化、地形利用和多用途规划 | Core |
| **Relatedness** (connection, belonging) | 通过可爱主角和友好的玩具世界建立轻度情感连接 | Supporting |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Achievers** (goal completion, collection, progression) — How: 通关、拿到更优解、完成额外目标
- [x] **Explorers** (discovery, understanding systems, finding secrets) — How: 研究箱子状态变化和隐藏捷径
- [ ] **Socializers** (relationships, cooperation, community) — How: 不是本作重点
- [ ] **Killers/Competitors** (domination, PvP, leaderboards) — How: 不是本作重点

### Flow State Design

- **Onboarding curve**: 前 10 分钟只教 3 件事: 移动、滚动箱子、用箱子压按钮。
- **Difficulty scaling**: 先单机制，再双机制组合，最后做“机关 + 敌人 + 回收箱子”的复合关卡。
- **Feedback clarity**: 箱子顶面图标始终可见；可交互目标用颜色和图标对应；失败原因即时回放。
- **Recovery from failure**: 支持一键重置本关，失败成本低，鼓励反复试验。

---

## Core Loop

### Moment-to-Moment (30 seconds)

观察前方地形，移动主角，推动箱子滚动 1 格，确认箱子当前顶面状态，再决定下一步是继续推进、压机关还是用来撞敌人。

### Short-Term (5-15 minutes)

在单个关卡内完成一个完整循环：
- 识别出口和阻碍
- 让箱子滚成需要的功能面
- 用箱子开门或击退敌人
- 回收或重新定位箱子
- 抵达出口

### Session-Level (30-120 minutes)

玩家一局通常完成 3-6 个小关卡，学习一个新机关或新敌人组合，并逐步建立“同一件道具多用途”的思维方式。

### Long-Term Progression

- 解锁新的关卡主题区，如装配区、发射区、礼物包装区
- 引入新地形，如坡道、传送带、旋转平台
- 引入更高阶的组合规则，而不是单纯增加敌人数

### Retention Hooks

- **Curiosity**: 下一个区域会引入什么新地形或机关组合
- **Investment**: 玩家已经学会一套箱子逻辑，愿意继续验证自己的理解
- **Social**: 可选地分享自己的最优解或无伤解
- **Mastery**: 追求更少步数、更高评价、更优路线

---

## Game Pillars

### Pillar 1: 滚动就是解谜

一切核心乐趣都围绕“滚动导致状态变化”展开，推动路径本身比箱子最终位置更重要。

*Design test*: 如果某个新功能与“箱子滚到哪里、变成什么”无关，就不该优先进入核心玩法。

### Pillar 2: 一个箱子，多种用途

同一个箱子必须能在同一关中承担至少两种职责，例如先压按钮、再撞敌人、最后变成通路。

*Design test*: 如果一个箱子在大多数关卡里只负责一种用途，那设计深度不够，需要重做关卡或箱子状态。

### Pillar 3: 可爱外表，硬核规则

画面和角色表达可以温柔、友好、低压力，但规则必须清晰、确定、可推理。

*Design test*: 如果某个反馈不够清楚，哪怕美术表现很可爱，也必须优先提升可读性。

### Anti-Pillars (What This Game Is NOT)

- **NOT 真实物理沙盒**: 不追求复杂物理模拟，否则会削弱可推理性和关卡稳定性。
- **NOT 动作战斗游戏**: 敌人存在是为了增加空间决策，而不是要求玩家拼手速。
- **NOT 大体量剧情冒险**: 第一版重点是机制和关卡，不是长篇叙事和开放世界探索。

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| Sokoban | 推箱子的空间规划与确定性规则 | 箱子会随滚动切换功能，不再只是位置谜题 | 验证“简单规则也能产生深思考” |
| Captain Toad Treasure Tracker | 玩具感 3D 场景和清晰阅读性 | 我们加入可重复利用的功能箱与轻战斗 | 验证“可爱外观与严谨解谜可以兼容” |
| 《滚滚滚》桌面游戏规则文档 | 滚动带来状态变化、位置比数值更重要 | 去掉多人区域战争，保留单人易读的状态规划内核 | 验证“滚动状态机”本身有足够设计深度 |

**Non-game inspirations**: 玩具积木、儿童房收纳盒、迷你宇宙物流、桌面棋盘的格子感与操作感。

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 12-35 |
| **Gaming experience** | Casual 到 Mid-core |
| **Time availability** | 平日 10-30 分钟，周末可连续玩 1 小时 |
| **Platform preference** | PC, Steam Deck 类便携 PC 也适合 |
| **Current games they play** | 解谜独立游戏、轻策略游戏、可爱风平台游戏 |
| **What they're looking for** | 一个门槛低、规则清晰、每关都有“想明白了”的满足感的小品级游戏 |
| **What would turn them away** | 规则不透明、镜头难看懂、过多动作惩罚、失败后要重复很长流程 |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | Godot 4，适合小体量 3D 项目、单人开发和快速原型 |
| **Key Technical Challenges** | 3D 网格移动与镜头可读性、箱子朝向状态记录、滚动动画与逻辑同步、敌人撞击结算 |
| **Art Style** | 3D stylized |
| **Art Pipeline Complexity** | Low to Medium |
| **Audio Needs** | Moderate |
| **Networking** | None |
| **Content Volume** | MVP 5 关，完整首版 20-30 关，时长 2-4 小时 |
| **Procedural Systems** | None for MVP |

---

## Risks and Open Questions

### Design Risks

- 箱子状态过多会让新手记不住，导致“理解负担”高于“解谜乐趣”。
- 如果敌人存在感太强，玩家会把游戏误读为动作闯关，而不是空间解谜。

### Technical Risks

- 3D 视角如果处理不好，会让玩家误判格子关系和箱子朝向。
- 箱子滚动动画若与实际逻辑脱节，会立刻破坏规则可信度。

### Market Risks

- 纯解谜市场相对细分，需要一个足够清楚的卖点才能被看见。
- 可爱风外观可能让硬核解谜玩家误判深度，宣传要强调“规则驱动”。

### Scope Risks

- 如果过早加入太多箱子类型、敌人类型和剧情演出，项目会失控。
- 如果尝试做真实物理、多人模式或大地图探索，会直接偏离 MVP。

### Open Questions

- 玩家是否能快速理解“顶面状态决定用途”？用 3 关教学原型验证。
- “箱子可攻击敌人”是在增强解谜，还是稀释解谜？用 1 个纯机关关和 1 个含敌人关对比测试。

---

## MVP Definition

**Core hypothesis**: 玩家会觉得“滚动功能箱并让它在压按钮与攻击之间切换”的确定性 3D 解谜循环有趣，并愿意连续完成至少 5 个关卡。

**Required for MVP**:
1. 1 个可移动主角
2. 1 种六面功能箱，含 4 类顶面功能
3. 普通按钮、重压按钮、门、出口
4. 2 类敌人: 普通敌人与重甲敌人
5. 5 个手工教学关卡
6. 一键重置、关卡重开、清晰的顶面状态提示

**Explicitly NOT in MVP** (defer to later):
- 长剧情和复杂角色对话
- 多种可切换角色
- 多箱子品类和升级树
- 收集养成系统
- 随机关卡和多人模式

### Scope Tiers (if budget/time shrinks)

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | 5 个教学关 | 功能箱、按钮、门、2 类敌人 | 4-6 周 |
| **Vertical Slice** | 10-12 关，1 个完整主题区 | 增加坡道、传送带、评分系统 | 8-10 周 |
| **Alpha** | 20 关，3 个主题区 | 全部核心机关完成，内容可通关 | 14-18 周 |
| **Full Vision** | 25-30 关，完整美术和音效包装 | 抛光、可选挑战目标、隐藏关 | 20-28 周 |

---

## Initial System Rules

### Player

- 玩家每次移动 1 格。
- 玩家不能直接攻击敌人。
- 玩家主要通过推动箱子改变环境。

### Rolling Utility Box

- 箱子为立方体，按格子滚动，不做真实连续物理模拟。
- 箱子每滚动 1 格，朝向改变，顶面功能随之改变。
- 建议功能分布如下:
  - 普通面 x2: 可压普通按钮
  - 冲击面 x2: 可击败普通敌人
  - 重压面 x1: 可压重压按钮，也可击败重甲敌人
  - 能源面 x1: 可插入能源槽，开启特定门或机关

### Buttons and Devices

- **普通按钮**: 任意箱子可触发。
- **重压按钮**: 只有顶面为重压面的箱子可触发。
- **能源槽**: 只有顶面为能源面的箱子可触发。
- 门默认与对应机关绑定，机关失效时可选择持续开启或恢复关闭，具体以后按关卡需求决定。

### Enemy Interaction

- 箱子滚入敌人格时立即结算，不做随机伤害。
- 冲击面可击败普通敌人。
- 重压面可击败普通敌人和重甲敌人。
- 普通面和能源面撞到敌人时只产生阻挡或轻微击退，不造成击败。

### Terrain Abstraction

- 坡道: 改变箱子移动成本或滚动距离。
- 传送带: 改变箱子最终落点。
- 旋转平台: 改变通路方向，呼应原桌面规则中的“板块旋转”思想。
- 深坑: 作为失败状态或重置触发器使用。

### Five-Level Teaching Arc

1. 学会推动和观察箱子顶面变化
2. 学会用箱子压普通按钮开门
3. 学会把箱子滚成冲击面并击败普通敌人
4. 学会重压面对应重压按钮和重甲敌人
5. 学会在同一关中回收并重复利用同一个箱子

---

## Next Steps

- [x] Confirm concept direction with user
- [x] Engine setup: Godot 4.6.1 pinned
- [x] Create pillars document
- [x] Decompose game into systems
- [x] Write per-system GDDs (rolling-utility-box, terrain, enemy, interactables, ui-hud)
- [x] Prototype 5-level graybox sequence
- [x] First playtest (Playtest 001)
- [x] Milestone-01 completed
- [ ] Second playtest (Playtest 002) — in progress
- [ ] Milestone-02 (Vertical Slice) completion pending
