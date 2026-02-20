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
├── docs/
│   ├── jules_prompts/             # Jules任务Prompt文件
│   │   ├── run_jules_task.py      # 单任务提交脚本
│   │   ├── run_jules_batch.py     # 批量任务提交脚本
│   │   ├── check_jules_status.py  # 任务状态检查脚本
│   │   ├── P0_*.md                # Phase 0 基础系统任务
│   │   ├── P1_*.md                # Phase 1 单位实现任务
│   │   └── P2_*.md                # Phase 2 系统优化任务
│   ├── roles/                     # AI角色人设
│   │   ├── art_director.md        # 美术总监
│   │   ├── game_designer.md       # 游戏策划
│   │   ├── system_architect.md    # 系统架构师
│   │   └── qa_engineer.md         # 测试工程师
│   ├── GameDesign.md              # 游戏设计文档
│   └── progress.md                # 任务进度跟踪
├── scripts/                       # 游戏代码
│   ├── managers/                  # Manager类
│   ├── units/                     # 单位类
│   └── behaviors/                 # Behavior类
├── tests/                         # 测试代码
└── data/                          # 配置数据
    └── game_data.json             # 单位配置
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

**何时调用**:
- 需要为新功能编写测试
- 设计集成测试验证系统交互
- 执行回归测试

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

### 关键文件位置

| 文件 | 说明 |
|------|------|
| `docs/GameDesign.md` | 游戏设计文档 |
| `docs/progress.md` | 任务进度跟踪 |
| `data/game_data.json` | 单位配置数据 |
| `tests/` | 测试目录 |
| `scripts/managers/` | Manager类目录 |
| `scripts/units/` | 单位类目录 |
| `scripts/behaviors/` | Behavior类目录 |

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

---

## 快速开始

### 1. 配置 API 密钥

```bash
cd docs/secrets
cp .env.example .env
# 编辑 .env 文件，填入从 https://jules.google.com/settings#api 获取的 API 密钥
```

### 2. 安装依赖

```bash
pip install requests python-dotenv
```

### 3. 提交任务

```bash
# 单个任务
python docs/jules_prompts/run_jules_task.py \
    --prompt docs/jules_prompts/P0_01_wolf_totem_soul_system.md \
    --task-id P0-01 \
    --wait

# 批量任务
python docs/jules_prompts/run_jules_batch.py --phase P0
```

---

## 使用指南

### 如何与角色协作

1. **明确问题类型**: 先判断问题属于哪个专业领域
2. **加载对应角色**: 在对话中引用对应的角色Prompt文件
3. **提供上下文**: 说明当前进度、相关文件位置、约束条件
4. **迭代讨论**: 可能需要多个角色交叉讨论

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

## 参考文档

- [docs/GameDesign.md](docs/GameDesign.md) - 游戏设计文档
- [docs/progress.md](docs/progress.md) - 任务进度跟踪与实现状态
- [docs/roles/](docs/roles/) - AI角色人设文档

---

*最后更新: 2026-02-20*
