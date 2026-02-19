# Claude 职责说明

本文档用于在新对话中快速恢复上下文。

## 当前项目

**项目**: tower-html - Godot 4.x 塔防游戏（图腾纷争）
**当前阶段**: 使用 Google Jules API 自动化代码实现
**GitHub**: https://github.com/seekerzz/tower-html

---

## 我的职责

作为开发助手，我的主要职责是：

### 1. 管理 Jules AI 任务执行流程

```
提交任务 → 监控进度 → 代码审查 → 合并PR → 推送GitHub → 继续下一批
```

### 2. 任务提交规范

**API Key 获取位置:**
- 访问 https://jules.google.com/settings#api
- 在 Jules Web App 的 Settings 页面创建 API Key
- 最多可同时拥有 3 个 API Key

**API Key 使用方式:**
- 优先从环境变量读取: `export JULES_API_KEY='your_key_here'`
- 或从 `docs/secrets/.env` 文件读取 (已配置 .gitignore 保护)
- **绝不要**将真实 API Key 硬编码在脚本或文档中

**请求配置:**
- 代理: `127.0.0.1:10808`
- 认证头: `X-Goog-Api-Key: ${JULES_API_KEY}`
- 必须包含 `sourceContext` 指定 GitHub 仓库

### 3. 执行顺序 (关键!)

由于 Jules 基于 GitHub 代码版本执行，**必须按以下顺序执行**:

**第一波 (已完成)**
- ✅ P0-01 狼图腾魂魄系统

**第二波 (可并行提交)**
- ⬜ P0-02 嘲讽/仇恨系统 (无依赖)
- ⬜ P0-03 召唤物系统 (无依赖)
- ⬜ P0-04 流血吸血联动系统 (无依赖)

**第三波 (必须等待 P0 合并后)**
- ⬜ P1-A 狼图腾单位群 (依赖 P0-01, P0-03)
- ⬜ P1-B 眼镜蛇图腾单位群
- ⬜ P1-C 蝙蝠图腾单位群 (依赖 P0-04)
- ⬜ P1-D 蝴蝶图腾单位群
- ⬜ P1-E 老鹰图腾单位群
- ⬜ P1-F 奶牛图腾单位群 (依赖 P0-02)

### 4. 每个任务的必要步骤

1. **提交前**: 确保 main 分支最新 (`git pull origin main`)
2. **提交任务**: 使用 `docs/jules_prompts/submit_jules_task.py` (API Key 从 .env 读取)
3. **监控进度**: 使用 `docs/jules_prompts/check_jules_status.py --session-id <ID> --wait`
4. **完成后**:
   - 获取 PR 信息
   - 拉取 PR 分支验证: `git fetch origin pull/{id}/head:pr-{id}`
   - 运行测试: `godot --path . --headless -- --run-test={test_name}`
   - 合并到 main: `git merge pr-{id}`
   - 推送到 GitHub: `git push origin main`
   - 更新 `docs/progress.md`

---

## 可用工具脚本

**注意**: 脚本从 `docs/secrets/.env` 或环境变量读取 API Key，不要硬编码。

```bash
# 提交任务
cd docs/jules_prompts
python submit_jules_task.py \
  --task-id P0-02 \
  --prompt P0_02_taunt_aggro_system.md

# 检查状态
python check_jules_status.py --session-id SESSION_ID

# 持续监控直到完成
python check_jules_status.py --session-id SESSION_ID --wait
```

---

## 关键文件位置

| 文件 | 说明 |
|------|------|
| `docs/jules_prompts/P0_*.md` | P0 任务提示词 (独立系统) |
| `docs/jules_prompts/P1_*.md` | P1 任务提示词 (单位实现) |
| `docs/jules_prompts/submit_jules_task.py` | **任务提交脚本** |
| `docs/jules_prompts/check_jules_status.py` | **任务状态检查脚本** |
| `docs/secrets/.env` | API Key 配置文件 (不要提交到 Git) |
| `docs/progress.md` | 任务进度跟踪 |
| `docs/GameDesign.md` | 游戏设计文档 |

---

## 当前进度 (2026-02-19)

| 阶段 | 总任务 | 已完成 | 进行中 | 待开始 |
|------|--------|--------|--------|--------|
| P0 - 基础系统 | 4 | 1 | 0 | 3 |
| P1 - 图腾单位 | 6 | 0 | 0 | 6 |

**已完成**: P0-01 狼图腾魂魄系统 (PR #439)
**待执行**: P0-02, P0-03, P0-04 (可并行)

---

## 注意事项

1. **Jules 任务独立**: 每个任务没有上下文，不要在一个任务中要求多个功能
2. **GitHub 同步**: Jules 读取的是 GitHub 上的代码，必须先 push 才能提交依赖任务
3. **API 限制**: 注意 Jules API 的调用频率限制
4. **测试验证**: 每个任务完成后必须运行测试验证
5. **PR 合并**: 使用 `--no-edit` 自动合并，保持线性历史

---

## 下一步行动

根据用户指示执行以下之一:

- **并行提交 P0-02, P0-03, P0-04** (推荐，它们互不依赖)
- **逐个提交并等待** (如果用户希望逐步验证)
- **更新文档或脚本** (如有需要改进)

---

*最后更新: 2026-02-19*
*当前对话上下文已保存*
