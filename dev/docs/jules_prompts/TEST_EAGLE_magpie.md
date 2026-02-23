# Jules 任务: 喜鹊 (magpie) 自动化测试

## 任务ID
TEST-EAGLE-magpie

## 任务描述
为喜鹊单位创建完整的自动化测试用例，验证其幸运掉金币机制，确保能在Headless模式下通过。

## 核心机制
**幸运掉金币**: 偷取敌人属性

## 测试场景

### 测试场景 1: Lv1 闪光物验证
```gdscript
{
    "id": "test_magpie_lv1_steal",
    "core_type": "eagle_totem",
    "duration": 30.0,
    "units": [
        {"id": "magpie", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 10, "attack": 20}  # 多次攻击触发概率
    ],
    "expected_behavior": {
        "description": "攻击有15%概率偷取敌人属性",
        "verification": "约15%的攻击偷取敌人攻击力或攻速"
    }
}
```

**验证指标**:
- [ ] 偷取概率15%
- [ ] 偷取属性增加自身
- [ ] 敌人属性暂时降低

### 测试场景 2: Lv2 偷取效果提升验证
**验证指标**:
- [ ] 偷取概率25%
- [ ] 偷取效果+50%

### 测试场景 3: Lv3 报喜验证
```gdscript
{
    "id": "test_magpie_lv3_reward",
    "core_type": "eagle_totem",
    "duration": 30.0,
    "core_health": 400,
    "max_core_health": 500,
    "initial_gold": 100,
    "units": [
        {"id": "magpie", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 10}
    ],
    "expected_behavior": {
        "description": "偷取成功时随机给核心回复10HP或10金币",
        "verification": "偷取触发时，核心血量或金币增加"
    }
}
```

**验证指标**:
- [ ] 偷取成功时核心回血10点或金币+10
- [ ] 效果随机触发

## Headless测试配置

### 测试运行命令
```bash
# Lv1 闪光物测试
godot --path . --headless -- --run-test=test_magpie_lv1_steal

# Lv3 报喜测试
godot --path . --headless -- --run-test=test_magpie_lv3_reward
```

### 通过标准
- 退出码为 0
- 无 SCRIPT ERROR
- 测试日志正常生成

## 实现步骤

1. **阅读现有代码**:
   - 阅读 `src/Scripts/Tests/TestSuite.gd` 了解测试配置格式
   - 阅读 `src/Scripts/Units/EagleTotem/Magpie.gd` 了解单位实现

2. **添加测试用例**:
   在 `TestSuite.gd` 的 `get_test_config` 函数中添加:
   ```gdscript
   "test_magpie_lv1_steal":
       return {
           "id": "test_magpie_lv1_steal",
           "core_type": "eagle_totem",
           "duration": 30.0,
           "units": [
               {"id": "magpie", "x": 0, "y": 1, "level": 1}
           ],
           "enemies": [
               {"type": "basic_enemy", "count": 10, "attack": 20}
           ],
           "expected_behavior": "攻击有15%概率偷取敌人属性"
       }

   "test_magpie_lv3_reward":
       return {
           "id": "test_magpie_lv3_reward",
           "core_type": "eagle_totem",
           "duration": 30.0,
           "core_health": 400,
           "max_core_health": 500,
           "initial_gold": 100,
           "units": [
               {"id": "magpie", "x": 0, "y": 1, "level": 3}
           ],
           "enemies": [
               {"type": "basic_enemy", "count": 10}
           ],
           "expected_behavior": "偷取成功时随机给核心回复10HP或10金币"
       }
   ```

3. **运行测试验证**:
   ```bash
   for test in test_magpie_lv1_steal test_magpie_lv3_reward; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```

4. **更新测试进度**:
   测试完成后，更新 `docs/test_progress.md` 中喜鹊的验证指标。

## 进度更新要求

完成每个测试场景后，更新 `docs/progress.md`:

```markdown
| TEST-EAGLE-magpie | in_progress | 添加Lv1闪光物测试 | 2026-02-20T14:30:00 |
| TEST-EAGLE-magpie | in_progress | 添加Lv3报喜测试 | 2026-02-20T14:45:00 |
| TEST-EAGLE-magpie | completed | 所有测试通过 | 2026-02-20T15:00:00 |
```

同时在 `docs/test_progress.md` 中更新验证指标:
```markdown
**验证指标**:
- [x] 偷取概率15%
- [x] 偷取属性增加自身
- [x] 敌人属性暂时降低
- [x] 偷取概率25%（Lv2）
- [x] 偷取效果+50%（Lv2）
- [x] 偷取成功时核心回血10点或金币+10（Lv3）
- [x] 效果随机触发（Lv3）

**测试记录**:
- 测试日期: 2026-02-20
- 测试人员: Jules
- 测试结果: 通过
- 备注: 无
```

## 相关文档

- `docs/test_progress.md` - 详细测试场景规范
- `docs/roles/qa_engineer.md` - 测试工程师角色指南
- `src/Scripts/Tests/AutomatedTestRunner.gd` - 测试运行器
- `src/Scripts/Tests/TestSuite.gd` - 测试配置
- `src/Scripts/Units/EagleTotem/Magpie.gd` - 单位实现

## Task ID

Task being executed: TEST-EAGLE-magpie
