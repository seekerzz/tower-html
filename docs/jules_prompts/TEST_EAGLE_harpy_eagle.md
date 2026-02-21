# Jules 任务: 角雕 (harpy_eagle) 自动化测试

## 任务ID
TEST-EAGLE-harpy_eagle

## 任务描述
为角雕单位创建完整的自动化测试用例，验证其羽翼风暴机制，确保能在Headless模式下通过。

## 核心机制
**羽翼风暴**: 三连击

## 测试场景

### 测试场景 1: Lv1 三连击验证
```gdscript
{
    "id": "test_harpy_eagle_lv1_triple",
    "core_type": "eagle_totem",
    "duration": 15.0,
    "units": [
        {"id": "harpy_eagle", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3}
    ],
    "expected_behavior": {
        "description": "快速3次攻击，第3次暴击概率*2",
        "verification": "攻击周期内有3次伤害事件，第3次暴击率更高"
    }
}
```

**验证指标**:
- [ ] 每次攻击周期3次伤害
- [ ] 第3次暴击概率翻倍

### 测试场景 2: Lv2 暴击概率提升验证
**验证指标**:
- [ ] 第3次暴击概率*3

### 测试场景 3: Lv3 必定暴击验证
```gdscript
{
    "id": "test_harpy_eagle_lv3_crit",
    "core_type": "eagle_totem",
    "duration": 20.0,
    "units": [
        {"id": "harpy_eagle", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3}
    ],
    "expected_behavior": {
        "description": "第3次攻击必定暴击并触发图腾回响",
        "verification": "第3次攻击必定暴击，触发鹰图腾的额外攻击"
    }
}
```

**验证指标**:
- [ ] 第3次必定暴击
- [ ] 触发图腾回响

## Headless测试配置

### 测试运行命令
```bash
# Lv1 三连击测试
godot --path . --headless -- --run-test=test_harpy_eagle_lv1_triple

# Lv3 必定暴击测试
godot --path . --headless -- --run-test=test_harpy_eagle_lv3_crit
```

### 通过标准
- 退出码为 0
- 无 SCRIPT ERROR
- 测试日志正常生成

## 实现步骤

1. **阅读现有代码**:
   - 阅读 `src/Scripts/Tests/TestSuite.gd` 了解测试配置格式
   - 阅读 `src/Scripts/Units/EagleTotem/HarpyEagle.gd` 了解单位实现

2. **添加测试用例**:
   在 `TestSuite.gd` 的 `get_test_config` 函数中添加:
   ```gdscript
   "test_harpy_eagle_lv1_triple":
       return {
           "id": "test_harpy_eagle_lv1_triple",
           "core_type": "eagle_totem",
           "duration": 15.0,
           "units": [
               {"id": "harpy_eagle", "x": 0, "y": 1, "level": 1}
           ],
           "enemies": [
               {"type": "basic_enemy", "count": 3}
           ],
           "expected_behavior": "快速3次攻击，第3次暴击概率*2"
       }

   "test_harpy_eagle_lv3_crit":
       return {
           "id": "test_harpy_eagle_lv3_crit",
           "core_type": "eagle_totem",
           "duration": 20.0,
           "units": [
               {"id": "harpy_eagle", "x": 0, "y": 1, "level": 3}
           ],
           "enemies": [
               {"type": "basic_enemy", "count": 3}
           ],
           "expected_behavior": "第3次攻击必定暴击并触发图腾回响"
       }
   ```

3. **运行测试验证**:
   ```bash
   for test in test_harpy_eagle_lv1_triple test_harpy_eagle_lv3_crit; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```

4. **更新测试进度**:
   测试完成后，更新 `docs/test_progress.md` 中角雕的验证指标。

## 进度更新要求

完成每个测试场景后，更新 `docs/progress.md`:

```markdown
| TEST-EAGLE-harpy_eagle | in_progress | 添加Lv1三连击测试 | 2026-02-20T14:30:00 |
| TEST-EAGLE-harpy_eagle | in_progress | 添加Lv3必定暴击测试 | 2026-02-20T14:45:00 |
| TEST-EAGLE-harpy_eagle | completed | 所有测试通过 | 2026-02-20T15:00:00 |
```

同时在 `docs/test_progress.md` 中更新验证指标:
```markdown
**验证指标**:
- [x] 每次攻击周期3次伤害
- [x] 第3次暴击概率翻倍
- [x] 第3次暴击概率*3（Lv2）
- [x] 第3次必定暴击（Lv3）
- [x] 触发图腾回响（Lv3）

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
- `src/Scripts/Units/EagleTotem/HarpyEagle.gd` - 单位实现

## Task ID

Task being executed: TEST-EAGLE-harpy_eagle
