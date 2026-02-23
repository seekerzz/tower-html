# Jules 任务: 老鹰 (eagle) 自动化测试

## 任务ID
TEST-EAGLE-eagle

## 任务描述
为老鹰单位创建完整的自动化测试用例，验证其撕裂伤口机制，确保能在Headless模式下通过。

## 核心机制
**撕裂伤口**: 优先攻击高HP敌人

## 测试场景

### 测试场景 1: Lv1 鹰眼验证
```gdscript
{
    "id": "test_eagle_lv1_eye",
    "core_type": "eagle_totem",
    "duration": 20.0,
    "units": [
        {"id": "eagle", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "hp": 50, "count": 2},
        {"type": "high_hp_enemy", "hp": 200, "count": 1}
    ],
    "expected_behavior": {
        "description": "射程极远，优先攻击HP最高的敌人",
        "verification": "老鹰优先攻击高血量敌人"
    }
}
```

**验证指标**:
- [ ] 射程极远
- [ ] 优先攻击HP最高的敌人

### 测试场景 2: Lv2 伤害提升验证
**验证指标**:
- [ ] 射程+20%
- [ ] 对高HP敌人伤害+30%

### 测试场景 3: Lv3 空中处决验证
```gdscript
{
    "id": "test_eagle_lv3_execute",
    "core_type": "eagle_totem",
    "duration": 20.0,
    "units": [
        {"id": "eagle", "x": 0, "y": 1, "level": 3, "attack": 100}
    ],
    "enemies": [
        {"type": "full_hp_enemy", "hp": 100, "count": 3}
    ],
    "expected_behavior": {
        "description": "对HP>80%敌人的第一次攻击造成250%伤害",
        "verification": "满血敌人第一次受到250点伤害"
    }
}
```

**验证指标**:
- [ ] 对>80%HP敌人第一次攻击250%伤害
- [ ] 仅第一次攻击触发

## Headless测试配置

### 测试运行命令
```bash
# Lv1 鹰眼测试
godot --path . --headless -- --run-test=test_eagle_lv1_eye

# Lv3 空中处决测试
godot --path . --headless -- --run-test=test_eagle_lv3_execute
```

### 通过标准
- 退出码为 0
- 无 SCRIPT ERROR
- 测试日志正常生成

## 实现步骤

1. **阅读现有代码**:
   - 阅读 `src/Scripts/Tests/TestSuite.gd` 了解测试配置格式
   - 阅读 `src/Scripts/Units/EagleTotem/Eagle.gd` 了解单位实现

2. **添加测试用例**:
   在 `TestSuite.gd` 的 `get_test_config` 函数中添加:
   ```gdscript
   "test_eagle_lv1_eye":
       return {
           "id": "test_eagle_lv1_eye",
           "core_type": "eagle_totem",
           "duration": 20.0,
           "units": [
               {"id": "eagle", "x": 0, "y": 1, "level": 1}
           ],
           "enemies": [
               {"type": "basic_enemy", "hp": 50, "count": 2},
               {"type": "high_hp_enemy", "hp": 200, "count": 1}
           ],
           "expected_behavior": "射程极远，优先攻击HP最高的敌人"
       }

   "test_eagle_lv3_execute":
       return {
           "id": "test_eagle_lv3_execute",
           "core_type": "eagle_totem",
           "duration": 20.0,
           "units": [
               {"id": "eagle", "x": 0, "y": 1, "level": 3, "attack": 100}
           ],
           "enemies": [
               {"type": "full_hp_enemy", "hp": 100, "count": 3}
           ],
           "expected_behavior": "对HP>80%敌人的第一次攻击造成250%伤害"
       }
   ```

3. **运行测试验证**:
   ```bash
   for test in test_eagle_lv1_eye test_eagle_lv3_execute; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```

4. **更新测试进度**:
   测试完成后，更新 `docs/test_progress.md` 中老鹰的验证指标。

## 进度更新要求

完成每个测试场景后，更新 `docs/progress.md`:

```markdown
| TEST-EAGLE-eagle | in_progress | 添加Lv1鹰眼测试 | 2026-02-20T14:30:00 |
| TEST-EAGLE-eagle | in_progress | 添加Lv3空中处决测试 | 2026-02-20T14:45:00 |
| TEST-EAGLE-eagle | completed | 所有测试通过 | 2026-02-20T15:00:00 |
```

同时在 `docs/test_progress.md` 中更新验证指标:
```markdown
**验证指标**:
- [x] 射程极远
- [x] 优先攻击HP最高的敌人
- [x] 射程+20%（Lv2）
- [x] 对高HP敌人伤害+30%（Lv2）
- [x] 对>80%HP敌人第一次攻击250%伤害（Lv3）
- [x] 仅第一次攻击触发（Lv3）

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
- `src/Scripts/Units/EagleTotem/Eagle.gd` - 单位实现

## Task ID

Task being executed: TEST-EAGLE-eagle
