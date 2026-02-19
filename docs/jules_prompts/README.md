# Jules Prompts 目录

本文档包含使用 Google Jules API 自动化代码实现的完整流程。

## 目录结构

```
docs/jules_prompts/
├── README.md                      # 本文件
├── _INDEX.md                      # Prompt 索引
├── jules_client.py                # Jules API Python 客户端
├── run_jules_task.py              # 单任务提交脚本
├── run_jules_batch.py             # 批量任务提交脚本
├── P0_01_wolf_totem_soul_system.md    # P0-01: 狼图腾魂魄系统
├── P0_02_taunt_aggro_system.md        # P0-02: 嘲讽/仇恨系统
├── P0_03_summon_system.md             # P0-03: 召唤物系统
├── P0_04_bleed_lifesteal_system.md    # P0-04: 流血吸血联动
├── P1_01_wolf_units_implementation.md # P1-A: 狼图腾单位群
├── P1_02_viper_cobra_units.md         # P1-B: 眼镜蛇单位群
├── P1_03_bat_totem_units.md           # P1-C: 蝙蝠图腾单位群
├── P1_04_butterfly_units.md           # P1-D: 蝴蝶图腾单位群
├── P1_05_eagle_units.md               # P1-E: 鹰图腾单位群
└── P1_06_cow_totem_units.md           # P1-F: 牛图腾单位群
```

## 快速开始

### 1. 配置 API 密钥

**检查是否已有 .env 文件:**
```bash
ls docs/secrets/.env
```

如果已存在 `.env` 文件，直接编辑即可，**不需要**重复复制。

**如果还没有 .env 文件:**
```bash
cd docs/secrets
cp .env.example .env
# 编辑 .env 文件，填入从 https://jules.google.com/settings#api 获取的 API 密钥
```

**注意:** `.env` 文件已被 `.gitignore` 保护，不会被提交到 Git 仓库。

### 2. 安装依赖

```bash
pip install requests python-dotenv
```

### 3. 提交单个任务

```bash
python docs/jules_prompts/run_jules_task.py \
    --prompt docs/jules_prompts/P0_01_wolf_totem_soul_system.md \
    --task-id P0-01 \
    --wait
```

### 4. 批量提交任务

```bash
# 提交所有 P0 任务
python docs/jules_prompts/run_jules_batch.py --phase P0

# 提交所有 P1 任务（并行）
python docs/jules_prompts/run_jules_batch.py --phase P1 --max-workers 6

# 提交并等待完成
python docs/jules_prompts/run_jules_batch.py --phase P1 --wait
```

## 执行流程

### Phase 1: P0 基础系统 (必须串行)

1. **P0-01**: 狼图腾魂魄系统
2. **P0-04**: 流血吸血联动系统
3. **P0-02**: 嘲讽/仇恨系统
4. **P0-03**: 召唤物系统

### Phase 2: P1 单位实现 (并行)

- **组A**: 狼图腾单位 (依赖: P0-01, P0-03)
- **组B**: 眼镜蛇单位 (无依赖)
- **组C**: 蝙蝠单位 (依赖: P0-04)
- **组D**: 蝴蝶单位 (无依赖)
- **组E**: 鹰单位 (无依赖)
- **组F**: 牛图腾单位 (依赖: P0-02)

## 查看进度

进度实时记录在 `docs/progress.md`:

```bash
cat docs/progress.md
```

## 可用命令

### run_jules_task.py

| 参数 | 说明 | 示例 |
|------|------|------|
| `-p, --prompt` | Prompt 文件路径 | `-p P0_01_wolf_totem_soul_system.md` |
| `-t, --task-id` | 任务ID | `-t P0-01` |
| `--title` | 会话标题 | `--title "狼图腾魂魄系统"` |
| `-w, --wait` | 等待完成 | `-w` |
| `--timeout` | 超时时间(秒) | `--timeout 3600` |
| `--approve-plan` | 自动批准计划 | `--approve-plan` |

### run_jules_batch.py

| 参数 | 说明 | 示例 |
|------|------|------|
| `--phase` | 提交阶段 | `--phase P0` |
| `--tasks` | 特定任务 | `--tasks P1-A,P1-B` |
| `--wait` | 等待完成 | `--wait` |
| `--max-workers` | 并行数 | `--max-workers 6` |
| `--list` | 列出任务 | `--list` |

## 参考文档

- [Jules API 文档](https://developers.google.com/jules/api)
- [GameDesign.md](../GameDesign.md) - 游戏设计文档
- [系统架构审核报告](../reviews/system_architect_review.md)
- [执行流程图](../diagrams/jules_execution_flowchart.md)

## 注意事项

1. **任务独立性**: 每个 Jules 任务都是独立的，没有共享上下文
2. **单任务原则**: 不要把多项任务集中到同一个 Jules 任务中
3. **进度同步**: 每个任务需要将进度刷新到 `docs/progress.md`
4. **测试要求**: 每个任务必须按照自动化测试框架规范进行测试
5. **分支管理**: 每个任务在独立分支 `feature/{task-id}` 上工作

## 故障排查

### API 密钥错误

```
错误: JULES_API_KEY 环境变量未设置
```

解决:
```bash
export JULES_API_KEY='YOUR_JULES_API_KEY_HERE'
# 或编辑 docs/secrets/.env 文件
```

### 网络问题

如果需要代理:
```bash
export HTTP_PROXY=http://127.0.0.1:10808
export HTTPS_PROXY=http://127.0.0.1:10808
```

### 查看详细日志

```bash
python run_jules_task.py -p P0_01.md -t P0-01 -w 2>&1 | tee jules.log
```

---

*生成时间: 2026-02-19*
