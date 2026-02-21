# Jules 任务: 风暴鹰 (storm_eagle) 自动化测试

## 任务ID
TEST-EAGLE-storm_eagle

## 任务描述
为风暴鹰单位创建完整的自动化测试用例，验证其连锁闪电机制，确保能在Headless模式下通过。

## 核心机制
**连锁闪电**: 召唤雷电

## 测试场景

### 测试场景 1: Lv1 雷暴验证
```gdscript
{
    "id": "test_storm_eagle_lv1_storm",
    "core_type": "eagle_totem",
    "duration": 20.0,
    "units": [
        {"id": "storm_eagle", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 5}
    ],
    "expected_behavior": {
        "description": "召唤雷电攻击随机敌人",
        "verification": "随机敌人受到雷电伤害"
    }
}
```

**验证指标**:
- [ ] 召唤雷电攻击
- [ ] 目标随机

### 测试场景 2: Lv2 伤害提升验证
**验证指标**:
- [ ] 雷电伤害提升

### 测试场景 3: Lv3 范围扩大验证
**验证指标**:
- [ ] 雷暴范围扩大
- [ ] 可命中更多敌人

## Headless测试配置

### 测试运行命令
```bash
# Lv1 雷暴测试
godot --path . --headless -- --run-test=test_storm_eagle_lv1_storm

# Lv2 伤害提升测试
godot --path . --headless -- --run-test=test_storm_eagle_lv2_damage

# Lv3 范围扩大测试
godot --path . --headless -- --run-test=test_storm_eagle_lv3_range
```

### 通过标准
- 退出码为 0
- 无 SCRIPT ERROR
- 测试日志正常生成

## 实现步骤

1. **阅读现有代码**:
   - 阅读 `src/Scripts/Tests/TestSuite.gd` 了解测试配置格式
   - 阅读 `src/Scripts/Units/EagleTotem/StormEagle.gd` 了解单位实现

2. **添加测试用例**:
   在 `TestSuite.gd` 的 `get_test_config` 函数中添加:
   ```gdscript
   "test_storm_eagle_lv1_storm":
       return {
           "id": "test_storm_eagle_lv1_storm",
           "core_type": "eagle_totem",
           "duration": 20.0,
           "units": [
               {"id": "storm_eagle", "x": 0, "y": 1, "level": 1}
           ],
           "enemies": [
               {"type": "basic_enemy", "count": 5}
           ],
           "expected_behavior": "召唤雷电攻击随机敌人"
       }

   "test_storm_eagle_lv2_damage":
       return {
           "id": "test_storm_eagle_lv2_damage",
           "core_type": "eagle_totem",
           "duration": 20.0,
           "units": [
               {"id": "storm_eagle", "x": 0, "y": 1, "level": 2}
           ],
           "enemies": [
               {"type": "basic_enemy", "count": 5}
           ],
           "expected_behavior": "雷电伤害提升"
       }

   "test_storm_eagle_lv3_range":
       return {
           "id": "test_storm_eagle_lv3_range",
           "core_type": "eagle_totem",
           "duration": 20.0,
           "units": [
               {"id": "storm_eagle", "x": 0, "y": 1, "level": 3}
           ],
           "enemies": [
               {"type": "basic_enemy", "count": 8}
           ],
           "expected_behavior": "雷暴范围扩大，可命中更多敌人"
       }
   ```

3. **运行测试验证**:
   ```bash
   for test in test_storm_eagle_lv1_storm test_storm_eagle_lv2_damage test_storm_eagle_lv3_range; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```

4. **更新测试进度**:
   测试完成后，更新 `docs/test_progress.md` 中风暴鹰的验证指标。

## 进度更新要求

完成每个测试场景后，更新 `docs/progress.md`:

```markdown
| TEST-EAGLE-storm_eagle | in_progress | 添加Lv1雷暴测试 | 2026-02-20T14:30:00 |
| TEST-EAGLE-storm_eagle | in_progress | 添加Lv2伤害提升测试 | 2026-02-20T14:40:00 |
| TEST-EAGLE-storm_eagle | in_progress | 添加Lv3范围扩大测试 | 2026-02-20T14:50:00 |
| TEST-EAGLE-storm_eagle | completed | 所有测试通过 | 2026-02-20T15:00:00 |
```

同时在 `docs/test_progress.md` 中更新验证指标:
```markdown
**验证指标**:
- [x] 召唤雷电攻击
- [x] 目标随机
- [x] 雷电伤害提升（Lv2）
- [x] 雷暴范围扩大（Lv3）
- [x] 可命中更多敌人（Lv3）

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
- `src/Scripts/Units/EagleTotem/StormEagle.gd` - 单位实现

## Task ID

Task being executed: TEST-EAGLE-storm_eagle
