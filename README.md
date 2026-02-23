# 图腾纷争 - AI协作开发指南

本文档是 tower-html 项目的 AI 协作开发入口，包含角色职责说明和项目背景知识。

项目进展跟踪请参阅 [`docs/progress.md`](docs/progress.md)。

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
│   ├── roles/                     # AI角色人设
│   ├── reviews/                   # 代码审查记录
│   ├── diagrams/                  # 架构图和流程图
│   ├── secrets/                   # 密钥配置（仅README）
│   ├── GameDesign.md              # 游戏设计文档
│   └── progress.md                # 任务进度跟踪
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
    ├── scripts/                   # 自动化脚本
    ├── docs/                      # 开发过程文档
    └── logs/                      # 测试日志
```

---

## 角色职责

本项目采用多角色协作模式，每个角色负责特定的专业领域。角色文档是通用的，可在不同项目中复用。

### 🎨 美术总监

**职责范围**:
- 设计技能特效的视觉方案（粒子、动画、光影）
- UI/UX设计（界面布局、图标、交互反馈）
- 维护游戏视觉风格的一致性

**何时调用**:
- 需要为新内容设计特效
- 审核现有视觉实现是否符合风格
- 优化UI交互体验

**Prompt文件**: [`docs/roles/art_director.md`](docs/roles/art_director.md)

---

### 🎮 游戏策划

**职责范围**:
- 审核游戏机制的完整性和可玩性
- 设计数值平衡（属性、公式、成长曲线）
- 确保实现与设计文档一致

**何时调用**:
- 审核新机制设计
- 评估数值平衡性
- 发现设计与实现偏差时

**Prompt文件**: [`docs/roles/game_designer.md`](docs/roles/game_designer.md)

---

### 🏗️ 系统架构师

**职责范围**:
- 将大型功能拆分为独立的AI可执行任务
- 分析系统依赖，提出代码解耦方案
- 提交AI任务，监控执行进度
- 审核代码、合并PR、跟踪进度

**何时调用**:
- 需要规划新系统的实现步骤
- 拆分复杂任务为AI可执行单元
- 审核架构设计方案

**Prompt文件**: [`docs/roles/system_architect.md`](docs/roles/system_architect.md)

---

### 🧪 测试工程师

**职责范围**:
- 根据功能描述设计测试用例
- 构建Headless模式下的自动化测试场景
- 验证功能正确性和边界条件处理
- **验证代码引用完整性**：检查所有信号连接、方法调用、父类继承是否正确

**何时调用**:
- 需要为新功能编写测试
- 设计集成测试验证系统交互
- 执行回归测试
- **代码合并前进行引用完整性检查**

**测试执行标准**:

| 检查项 | 说明 | 常见错误 |
|--------|------|----------|
| **信号存在性** | 验证 `GameManager` 或其他全局对象的信号已定义 | `core_healed` 信号不存在导致 SCRIPT ERROR |
| **方法存在性** | 验证调用的方法在目标类中存在 | `get_units_in_cell_range` 方法不存在 |
| **继承链完整性** | 验证覆盖/调用的父类方法存在 | `_enter_claw_return()` 在父类中不存在 |
| **成员变量冲突** | 验证子类不重复定义父类成员 | `current_hp` 与父类 `Unit` 重复定义 |
| **场景加载** | 验证单位场景文件能正确加载 | `.tscn` 文件引用缺失脚本 |

**测试失败处理流程**:
1. 记录失败的测试ID和错误信息
2. 分析错误类型（信号/方法/继承/变量冲突）
3. 追溯引入错误的提交
4. 修复后重新运行全量回归测试

**Prompt文件**: [`docs/roles/qa_engineer.md`](docs/roles/qa_engineer.md)

---

## 公共知识

所有角色都应了解以下项目背景信息。

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
│   │   └── P2_*.md                # Phase 2 系统优化任务
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

## 使用指南

### 如何与角色协作

1. **明确问题类型**: 先判断问题属于哪个专业领域
2. **加载对应角色**: 在对话中引用对应的角色Prompt文件
3. **提供上下文**: 说明当前进度、相关文件位置、约束条件
4. **迭代讨论**: 可能需要多个角色交叉讨论

### 新需求/变更工作流程

**重要：新增游戏变更或提出新需求时，必须遵循以下流程：**

```
需求提出 → 多角色讨论协商 → 系统架构师给出Jules Prompt → 各角色审核修改 → 提交Jules执行
```

**详细步骤**:

1. **需求提出**: 明确描述需要新增或变更的内容
2. **多角色讨论协商**:
   - 游戏策划：审核机制合理性和数值平衡
   - 美术总监：评估视觉效果需求
   - 系统架构师：分析技术可行性
   - 测试工程师：考虑测试覆盖
3. **系统架构师给出Jules Prompt**: 根据讨论结果，编写完整的Jules任务Prompt
4. **各角色审核修改**:
   - 确保Prompt涵盖所有讨论达成的方案细节
   - 检查是否有遗漏或歧义
   - 必要时进行多轮修改
5. **提交Jules执行**: 审核通过后，方可提交给Jules执行

**注意**: 未经讨论和审核的Prompt禁止直接提交，以确保实现方案经过充分论证。

---

### 典型工作流示例

**新功能开发流程**:
1. 策划：审核机制设计、数值方案
2. 架构师：拆分任务、设计代码结构、提交AI任务
3. AI Coding Agent：执行编码任务
4. 测试：编写并执行测试用例
5. 美术：设计特效方案（如需）

**代码审查流程**:
1. 架构师：审核代码结构和依赖
2. 策划：验证机制实现是否符合设计
3. 测试：验证功能正确性
4. 美术：检查视觉效果（如需）

---

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
- [docs/progress.md](docs/progress.md) - 任务进度跟踪与实现状态
- [docs/roles/](docs/roles/) - AI角色人设文档

---

*最后更新: 2026-02-21*
