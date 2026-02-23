# Jules 任务: T-01 牦牛守护嘲讽机制测试

## 任务ID
T-01

## 任务描述
根据 `docs/test_progress.md` 中 1.1 节的测试场景，实现并运行牦牛守护(yak_guardian)的Lv1嘲讽机制测试，验证嘲讽系统是否正常工作。

## 测试目标

验证牦牛守护的核心机制：
1. 嘲讽/守护领域周期性吸引敌人攻击自己
2. 为周围友方提供减伤Buff
3. 验证P2-05测试框架扩展的功能

## 测试场景配置

测试已在 `src/Scripts/Tests/TestSuite.gd` 中配置：

```gdscript
"test_cow_totem_yak_guardian":
    return {
        "id": "test_cow_totem_yak_guardian",
        "core_type": "cow_totem",
        "initial_gold": 1000,
        "start_wave_index": 1,
        "duration": 15.0,
        "units": [
            {"id": "squirrel", "x": 0, "y": -1},  # 诱饵单位
            {"id": "yak_guardian", "x": 0, "y": 1, "level": 1}
        ]
    }
```

## 实现步骤

### 1. 检查测试配置

确认 `TestSuite.gd` 中已存在 `test_cow_totem_yak_guardian` 测试配置。如不存在，添加上述配置。

### 2. 运行Headless测试

```bash
godot --path . --headless -- --run-test=test_cow_totem_yak_guardian
```

### 3. 验证测试结果

检查以下指标：

**3.1 测试通过标准**
- [ ] Headless测试退出码为0
- [ ] 终端输出无 `SCRIPT ERROR`
- [ ] 终端输出无 `ERROR:`
- [ ] 测试日志正常生成

**3.2 功能验证**
- [ ] 敌人生成后首先锁定松鼠(0, -1位置)
- [ ] 5秒后敌人目标切换为牦牛守护(0, 1位置)
- [ ] 牦牛守护周围的友方单位获得guardian_shield buff
- [ ] Buff提供的减伤为5%

### 4. 分析测试日志

测试日志位置：`user://test_logs/test_cow_totem_yak_guardian.json`

验证日志中包含：
- 敌人生成事件
- 敌人目标切换记录
- Buff施加记录
- 伤害数值变化（验证减伤效果）

## 预期现象

1. **0-5秒**: 敌人攻击松鼠
2. **5秒后**: 牦牛守护触发嘲讽，敌人目标切换为牦牛守护
3. **全程**: 松鼠获得guardian_shield buff，受到的伤害减少5%

## 问题处理

如果测试失败：

### 常见问题1: 敌人不切换目标
**检查**: AggroManager是否正确应用嘲讽
**修复**: 检查TauntBehavior是否正确触发

### 常见问题2: Buff未施加
**检查**: YakGuardian的Buff施加逻辑
**修复**: 检查守护领域范围计算

### 常见问题3: 测试框架错误
**检查**: P2-05测试框架扩展是否正确合并
**修复**: 检查AutomatedTestRunner的damage_core动作是否可用

## 测试完成后的工作

### 1. 更新测试进度文档

在 `docs/test_progress.md` 中更新测试记录：

```markdown
#### 测试场景 1: Lv1 嘲讽机制验证
**验证指标**:
- [x] 敌人生成后首先锁定松鼠
- [x] 5秒后敌人目标切换为牦牛守护
- [x] 牦牛守护周围的友方单位获得guardian_shield buff
- [x] Buff提供的减伤为5%

**测试记录**:
- 测试日期: 2026-02-20
- 测试人员: Jules
- 测试结果: [x]通过 / [!]发现问题
- 备注: Headless测试退出码0，日志验证通过
```

### 2. 更新进度概览表

```markdown
| 图腾流派 | 单位数量 | 已测试 | 测试覆盖率 |
|----------|----------|--------|------------|
| 牛图腾 (cow_totem) | 9 | 1 | 11% |
```

### 3. 提交代码

```bash
git add docs/test_progress.md
git commit -m "[T-01] 完成牦牛守护Lv1嘲讽机制测试"
```

## 代码提交要求

1. 在独立分支上工作：`test/T-01-yak-guardian`
2. 提交信息格式：`[T-01] 简要描述`
3. 完成后创建 Pull Request 到 main 分支

## 进度同步要求

完成测试后，更新 `docs/progress.md` 添加测试任务记录：

```markdown
| T-01 | completed | 牦牛守护嘲讽测试通过 | 2026-02-20 |
```

## 相关文档

- `docs/test_progress.md` - 测试进度文档（需更新）
- `src/Scripts/Tests/TestSuite.gd` - 测试配置
- `src/Scripts/Tests/AutomatedTestRunner.gd` - 测试运行器
- `docs/progress.md` - 任务进度跟踪

## 注意事项

1. **测试框架依赖**: 本测试依赖P2-05的测试框架扩展（特别是damage_core动作）
2. **坐标规则**: 确保单位不放置在(0,0)核心区
3. **测试时长**: 15秒足够触发2次嘲讽周期
4. **日志分析**: 重点关注敌人目标切换事件
