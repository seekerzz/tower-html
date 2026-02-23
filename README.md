# 图腾纷争 - AI协作开发指南

本文档是 tower-html 项目的 AI 协作开发入口，包含项目背景和开发指南。

---

## AI Agent Team 配置

本项目采用AI Agent Team协作开发模式。通过模拟AI玩家游戏体验，持续发现bug、优化数值平衡、改进游戏机制。

### 团队架构

```
┌───────────────────────────────────────────────────────────────────────┐
│                         项目总监 (你)                                  │
│                       Project Director                                │
│            职责：直接向用户汇报，协调团队成员，分配任务                   │
└─────────────────────┬─────────────────────────────────────────────────┘
                      │ 分配任务 / 汇总报告
    ┌─────────────────┼─────────────────┐
    ▼                 ▼                 ▼
┌──────────┐  ┌──────────────┐  ┌──────────┐
│ AI Agent │  │  游戏策划组   │  │ 游戏开发  │
│  玩家    │  │              │  │          │
│          │  │ ┌──────────┐ │  │          │
│ 读取日志 │  │ │ 主策划   │ │  │ Bug修复  │
│ 输出操作 │  │ │ (机制)   │ │  │ 功能实现 │
│ 反馈体验 │  │ ├──────────┤ │  │ 日志增强 │
└────┬─────┘  │ │ 副策划   │ │  └────┬─────┘
     │        │ │ (数值)   │ │       │
     │        │ └──────────┘ │       │
     │        └──────┬───────┘       │
     │               │               │
     └───────────────┴───────────────┘
                         │
                    ┌────┴────┐
                    ▼         ▼
               游戏日志    代码仓库
```

### 团队成员

| 角色 | 名称 | 职责 | 工作目录 |
|------|------|------|----------|
| **项目总监** | `team-lead` | 协调团队、分配任务、向用户汇报 | 项目根目录 |
| **AI Agent玩家** | `ai-player` | 读取日志、输出操作、反馈bug和体验 | `dev/agents/ai-player/` |
| **游戏策划（机制）** | `game-designer` | 机制设计、流派设计、系统设计 | `dev/agents/game-designer/` |
| **游戏策划（数值）** | `game-designer-2` | 数值平衡、成长曲线、关卡设计 | `dev/agents/game-designer-2/` |
| **游戏开发** | `game-developer` | Bug修复、功能实现、日志增强 | `dev/agents/game-developer/` |

### 游戏策划分工

| 策划角色 | 主要职责 | 当前任务 |
|----------|----------|----------|
| **主策划（机制）** | 流派设计、机制设计、系统架构 | 蝙蝠图腾综合方案设计 |
| **副策划（数值）** | 数值平衡、成长曲线、关卡难度 | 波次系统设计、遗物系统设计 |

### 团队工作流程

```
┌────────────────────────────────────────────────────────────────┐
│  Phase 1: 游戏运行                                              │
│  ─────────────────                                              │
│  AI Agent玩家 ←── 读取 ── 游戏日志输出（文字版）                 │
│       │                                                        │
│       ▼                                                        │
│  Phase 2: 体验反馈                                              │
│  ────────────────                                               │
│  AI Agent玩家 ──► 输出操作决策                                   │
│              ──► 报告Bug                                        │
│              ──► 反馈体验（爽点/坑点/信息缺失）                  │
│       │                                                        │
│       ▼                                                        │
│  Phase 3: 分析与设计                                            │
│  ──────────────────                                             │
│  游戏策划组 ←── 分析反馈                                         │
│   主策划 ──► 机制设计、流派方案                                  │
│   副策划 ──► 数值平衡、成长曲线                                  │
│       │                                                        │
│       ▼                                                        │
│  Phase 4: 实现与修复                                            │
│  ──────────────────                                             │
│  游戏开发 ←──── 接收设计方案                                     │
│        ──► 修复Bug                                              │
│        ──► 完善日志输出                                         │
│        ──► 实现新功能                                           │
│       │                                                        │
│       ▼                                                        │
│  Phase 5: 验证循环                                              │
│  ─────────────────                                              │
│  项目总监 ──► 验证修复效果                                       │
│        ──► 向用户汇报进度                                       │
│        ──► 启动下一轮测试                                       │
└────────────────────────────────────────────────────────────────┘
```

### 快速启动AI Agent Team

#### 1. 初始化团队

```bash
# 创建AI Agent工作目录
mkdir -p dev/agents/{ai-player,game-designer,game-developer}

# 团队已配置，直接使用以下命令启动协作
```

#### 2. 运行游戏并输出日志

```bash
# 运行游戏并输出详细日志（文字版）
godot --path . --headless -- --run-test=ai_player_test --verbose-logging

# 日志输出位置
cat dev/logs/ai_player_session.log
```

#### 3. 分配任务给团队成员

```bash
# 示例：分配分析任务给AI Agent玩家
# 在Claude Code中使用 Team/Agent 功能分配任务

# 1. AI Agent玩家分析日志
claude task assign ai-player "分析第3波战斗日志，报告发现的bug和体验问题"

# 2. 游戏策划（机制）设计系统
claude task assign game-designer "设计蝙蝠图腾流派的完整机制方案"

# 3. 游戏策划（数值）平衡调整
claude task assign game-designer-2 "根据AI玩家反馈，分析数值平衡问题并提出调整方案"

# 4. 游戏开发修复实现
claude task assign game-developer "修复AI玩家发现的日志缺失问题，添加xxx事件的日志输出"
```

### 日志输出规范

为确保AI Agent玩家能够准确理解游戏状态，游戏需要输出以下类型的日志：

#### 商店阶段日志
```
[Shop] Wave 3 ended, entering shop phase
[Shop] Gold: 150, Mana: 500/1000
[Shop] Available units: [wolf, bat, butterfly, cobra, eagle, cow]
[Shop] Shop refresh cost: 10 gold
[Shop] Player purchased unit 'wolf' at position (1, 0)
```

#### 战斗阶段日志
```
[Wave] Wave 4 started, enemy count: 15
[Spawn] Enemy 'slime' spawned at position (100, 200), HP: 50
[Combat] Unit 'wolf' at (1,0) attacks enemy 'slime' for 25 damage
[Combat] Enemy 'slime' died, killer: 'wolf', souls gained: 1
[Core] Base took 10 damage, current HP: 490/500
```

#### 单位状态日志
```
[Unit] Unit 'wolf' upgraded to level 2, damage: 25 -> 35
[Unit] Unit 'bat' applied bleed to enemy 'goblin', stacks: 3
[Unit] Unit 'tiger' devoured unit 'wolf', inherited: +15 damage
[Skill] Skill 'meteor_shower' activated at position (2, 1)
```

### AI Agent玩家输出格式

AI Agent玩家每次响应应包含以下部分：

```markdown
## 当前状态理解
- 波次：第4波进行中
- 核心血量：490/500
- 场上单位：wolf(2,0) Lv2, bat(0,1) Lv1
- 敌人生成：已生成15只slime，剩余5只

## 下一步操作
1. 在位置(-1,0)放置新购买的cow单位
2. 理由：增强前排防御，核心血量较低需要保护

## 发现的问题
- [Bug] wolf单位的攻击日志没有显示暴击伤害数值
- [Bug] 当单位吞噬其他单位时，没有输出继承的属性详情

## 体验反馈
- **爽点**：暴击时的视觉反馈很明显，从日志中能感受到伤害跳字
- **坑点**：不知道敌人的移动路径，难以预判放置位置
- **信息缺失**：无法从日志得知商店下次刷新会出现哪些单位
```

### 当前已知问题（AI Agent待验证）

| 问题 | 文件 | 类型 | 优先级 |
|------|------|------|--------|
| `core_healed` 信号不存在 | `RockArmorCow.gd` | 信号引用 | 高 |
| `get_units_in_cell_range` 方法不存在 | `MushroomHealer.gd`, `Plant.gd` | 方法引用 | 高 |
| `_enter_claw_return()` 不存在 | `Vulture.gd` | 继承链错误 | 高 |
| `current_hp` 重复定义 | `SummonedUnit.gd` | 成员变量冲突 | 中 |
| `setup` 方法不存在 | `SummonManager.gd` | 方法引用 | 中 |

### 团队沟通规范

1. **任务分配**：项目总监使用 `SendMessage` 向指定Agent分配任务
2. **进度汇报**：各Agent完成任务后向项目总监汇报
3. **问题升级**：Agent遇到阻塞问题时立即上报项目总监
4. **文档更新**：所有设计决策和修复记录需同步到相关文档

---

## 项目信息

| 属性 | 值 |
|------|-----|
| **项目名称** | tower-html - 图腾纷争 |
| **引擎** | Godot 4.x |
| **类型** | 塔防游戏 |
| **当前阶段** | P2 - 系统优化与完善 |
| **GitHub** | https://github.com/seekerzz/tower-html |

---

## 目录结构

```
├── docs/                          # 项目文档（提交到GitHub）
│   ├── GameDesign.md              # 游戏设计文档
│   ├── UnitDesign.xlsx            # 单位设计表
│   └── secrets/                   # 密钥配置说明
├── src/                           # 游戏源代码
│   ├── Scripts/                   # 游戏脚本
│   │   ├── Managers/              # Manager类
│   │   ├── Units/                 # 单位类
│   │   ├── Components/            # 组件类
│   │   ├── Skills/                # 技能类
│   │   ├── Effects/               # 特效类
│   │   └── Tests/                 # 测试代码
│   ├── Autoload/                  # 自动加载单例
│   ├── Scenes/                    # 场景文件
│   └── Shaders/                   # 着色器
├── data/                          # 配置数据
│   └── game_data.json             # 单位配置
├── assets/                        # 游戏资源
└── dev/                           # 开发者工作区（不提交到GitHub）
    ├── agents/                    # AI Agent Team 工作区
    │   ├── ai-player/             # AI Agent玩家工作目录
    │   ├── game-designer/         # 游戏策划工作目录
    │   └── game-developer/        # 游戏开发工作目录
    ├── scripts/                   # 自动化脚本
    ├── docs/                      # 开发过程文档
    └── logs/                      # 测试日志
```

---

## 游戏背景

### 游戏背景

图腾纷争是一款塔防游戏，玩家通过购买和升级各种图腾单位来抵御敌人进攻。游戏包含六大图腾流派，每个流派有独特的机制和玩法风格。

### 六大图腾流派

| 流派 | 主色调 | 核心机制 |
|------|--------|----------|
| 狼图腾 | 银灰/红色 | 魂魄系统、召唤、吞噬继承 |
| 蝙蝠图腾 | 暗红/紫色 | 流血、吸血、生命链接 |
| 蝴蝶图腾 | 蓝色/青色 | 升级加速、元素技能 |
| 眼镜蛇图腾 | 绿色/紫色 | 毒素、石化、控制 |
| 鹰图腾 | 金色/棕色 | 视野、暴击、空袭 |
| 牛图腾 | 棕色/绿色 | 嘲讽、护盾、防御 |

### 核心系统架构

```
TotemSystem/
├── SoulManager          # 魂魄系统管理
├── AggroManager         # 嘲讽/仇恨管理
├── SummonManager        # 召唤物管理
├── LifestealManager     # 吸血/流血管理
└── ShopSystem           # 商店系统

Units/
├── BaseUnit             # 单位基类
├── TotemUnit            # 图腾单位基类
└── [具体单位实现]

Behaviors/
├── TauntBehavior        # 嘲讽行为
├── BleedBehavior        # 流血行为
└── [其他行为组件]
```

### 坐标系与核心区规则

**重要：测试用例编写时必须遵守以下规则**

| 区域 | 坐标范围 | 说明 |
|------|----------|------|
| **核心区** | (0, 0) | **禁止放置任何单位**，这是图腾核心所在位置 |
| 初始格子 | 紧邻 (0,0) 的4格 | 开局已解锁的格子 |
| 可扩建区域 | x∈[-2,2], y∈[-2,2] | 中心5×5区域，需消耗金币解锁 |

> ⚠️ **测试用例常见错误**: 将单位放置在 `(0, 0)` 坐标
>
> 错误示例：`{"id": "medusa", "x": 0, "y": 0}`
>
> 正确做法：使用 `(1, 0)`、`(0, 1)`、`(-1, 0)` 或 `(0, -1)` 等紧邻核心的位置

### 关键文件位置

| 文件 | 说明 |
|------|------|
| `docs/GameDesign.md` | 游戏设计文档 |
| `docs/progress.md` | 任务进度跟踪 |
| `data/game_data.json` | 单位配置数据 |
| `src/Scripts/Managers/` | Manager类目录 |
| `src/Scripts/Units/` | 单位类目录 |
| `src/Scripts/Components/` | 组件类目录 |
| `src/Scripts/Tests/` | 测试代码目录 |

### AI Coding Agent工作流程

```
提交任务 → 监控进度 → 代码审查 → 合并PR → 推送GitHub → 继续下一批
```

### 项目阶段

详见 [`docs/progress.md`](docs/progress.md) 了解当前各阶段和任务的详细进展。

| 阶段 | 说明 |
|------|------|
| P0 - 基础系统 | 魂魄、嘲讽、召唤、流血吸血系统 |
| P1 - 图腾单位 | 六大流派单位实现 |
| P2 - 系统优化 | 魅惑、吞噬、石化系统 |
| P3 - 细节完善 | 残血收割、世界树等 |

### 已知问题与修复状态

**回归测试发现的问题**（2026-02-21）：

| 问题 | 文件 | 错误类型 | 修复状态 |
|------|------|----------|----------|
| `core_healed` 信号不存在 | `RockArmorCow.gd` | 信号引用 | ❌ 待修复 |
| `get_units_in_cell_range` 方法不存在 | `MushroomHealer.gd`, `Plant.gd` | 方法引用 | ❌ 待修复 |
| `_enter_claw_return()` 不存在 | `Vulture.gd` | 继承链错误 | ❌ 待修复 |
| `current_hp` 重复定义 | `SummonedUnit.gd` | 成员变量冲突 | ❌ 待修复 |
| `setup` 方法不存在 | `SummonManager.gd` | 方法引用 | ❌ 待修复 |

**问题根因分析**：
1. **合并覆盖问题**：`core_healed` 信号在 `70c0be4`（鹰图腾）合并时被意外移除
2. **方法名拼写错误**：`Vulture.gd` 复制了 `HarpyEagle.gd` 的代码但缺少对应方法定义
3. **API 不一致**：`get_units_in_cell_range` 被调用但在 `Unit` 基类中不存在
4. **继承冲突**：`SummonedUnit` 重复定义父类 `Unit` 已有的成员

**修复优先级**：高（影响多个单位无法正常加载）

---

## 快速开始

### 1. 配置 API 密钥

```bash
cd docs/secrets
# 参考 README.md 创建 .env 文件
# 填入从 https://jules.google.com/settings#api 获取的 API 密钥
```

### 2. 安装依赖

```bash
pip install requests python-dotenv
```

### 3. 运行测试

```bash
# 使用 Godot 运行测试（需要 Godot 引擎）
godot --path . --headless -- --run-test=test_wolf_totem

# 或使用开发者脚本（见下方开发者工作区说明）
cd dev
python scripts/monitor_all_tests.py
```

---

## 开发者工作区

`dev/` 目录包含开发过程中产生的辅助文件和工具，**不会提交到 GitHub**。开发者可以在本地使用这些资源进行调试、测试和任务管理。

### 工作区结构

```
dev/
├── scripts/              # 自动化脚本
│   ├── monitor_all_tests.py       # 监控所有测试
│   ├── run_all_tests.sh           # 批量运行测试
│   └── submit_*.sh                # 任务提交脚本
├── docs/                 # 开发文档
│   ├── jules_prompts/             # Jules 任务 Prompt 文件
│   │   ├── P0_*.md                # Phase 0 基础系统任务
│   │   ├── P1_*.md                # Phase 1 单位实现任务
│   │   ├── P2_*.md                # Phase 2 系统优化任务
│   │   └── TEST_*.md              # 单元测试任务
│   ├── reviews/                   # 代码审查记录
│   ├── diagrams/                  # 架构图和流程图
│   ├── progress.md                # 任务进度跟踪
│   ├── test_progress.md           # 测试进度
│   └── *.md                       # 测试报告
├── logs/                 # 测试日志和输出
│   └── *.log / *.txt
└── test_results/         # 测试结果
    └── *.log
```

### 使用方法

**运行测试：**
```bash
cd dev
./scripts/run_all_tests.sh
```

**提交 Jules 任务（需要 API 密钥）：**
```bash
cd dev
python scripts/submit_jules_task.py \
    --prompt docs/jules_prompts/P0_01_wolf_totem_soul_system.md \
    --task-id P0-01
```

**查看测试报告：**
```bash
# 报告文件位于 dev/docs/
cat dev/docs/COW_TOTEM_TEST_REPORT.md
```

> **注意**：`dev/` 目录已被添加到 `.gitignore`，其中的文件仅在本地保留，不会推送到 GitHub。

---

## 开发指南

### 代码合并前检查清单

**引用完整性检查**（防止运行时SCRIPT ERROR）：

| 检查项 | 检查方法 | 常见错误示例 |
|--------|----------|--------------|
| 信号存在性 | 搜索 `connect.*signal` 验证信号已定义 | `GameManager.core_healed` 不存在 |
| 方法存在性 | 验证调用的方法在目标类/父类中存在 | `_enter_claw_return()` 不存在 |
| 继承链完整 | 覆盖父类方法时验证方法签名一致 | 参数数量不匹配 |
| 成员变量冲突 | 子类不重复定义父类已有成员 | `current_hp` 重复定义 |
| 跨文件API | 引用的公共方法需确认已导出 | `get_units_in_cell_range` 未实现 |

**批量验证脚本**（提交前运行）：
```bash
# 运行全量回归测试，检查SCRIPT ERROR
for test in test_cow_totem_rock_armor_cow test_cow_totem_mushroom_healer \
            test_eagle_totem_vulture test_summon_system; do
  echo "Testing: $test"
  godot --path . --headless -- --run-test=$test 2>&1 | grep "SCRIPT ERROR"
done
```

**合并冲突预防**：
- 涉及 `GameManager.gd`, `Unit.gd` 等共享文件的修改需额外审查
- 多个并行功能开发时，按依赖顺序合并（基础类优先）
- 合并后立即运行相关功能测试验证

---

## 参考文档

- [docs/GameDesign.md](docs/GameDesign.md) - 游戏设计文档

*最后更新: 2026-02-23*
