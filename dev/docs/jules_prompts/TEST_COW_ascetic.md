# Jules 任务: 苦修者 (ascetic) 自动化测试

## 任务ID
TEST-COW-ascetic

## 任务描述
为苦修者单位创建完整的自动化测试用例，验证其伤害转MP机制，确保能在Headless模式下通过。

## 核心机制
**伤害转MP**: 将受到伤害转为MP；Lv3可选择两个目标

## 测试场景

### 测试场景 1: Lv1 伤害转MP验证
```gdscript
{
    "id": "test_ascetic_lv1_convert",
    "core_type": "cow_totem",
    "duration": 20.0,
    "initial_mp": 500,
    "units": [
        {"id": "ascetic", "x": 0, "y": 1, "level": 1},
        {"id": "squirrel", "x": 1, "y": 0}
    ],
    "enemies": [
        {"type": "basic_enemy", "attack_damage": 50, "count": 3}
    ],
    "setup_actions": [
        {"type": "apply_buff", "buff_id": "ascetic", "target_unit_id": "squirrel"}
    ],
    "expected_behavior": {
        "description": "被Buff单位受到伤害的12%转为MP",
        "verification": "松鼠受击50点伤害，MP增加6点"
    }
}
```

**验证指标**:
- [ ] 只能选择一个单位施加Buff
- [ ] 受到伤害的12%转化为MP
- [ ] MP增加量正确计算

### 测试场景 2: Lv2 转化比例提升验证
**验证指标**:
- [ ] 转化比例提升至18%

### 测试场景 3: Lv3 双目标验证
```gdscript
{
    "id": "test_ascetic_lv3_dual",
    "core_type": "cow_totem",
    "duration": 20.0,
    "units": [
        {"id": "ascetic", "x": 0, "y": 1, "level": 3},
        {"id": "squirrel", "x": 1, "y": 0},
        {"id": "bee", "x": -1, "y": 0}
    ],
    "setup_actions": [
        {"type": "apply_buff", "buff_id": "ascetic", "target_unit_id": "squirrel"},
        {"type": "apply_buff", "buff_id": "ascetic", "target_unit_id": "bee"}
    ],
    "expected_behavior": {
        "description": "可以选择两个单位施加Buff",
        "verification": "两个被Buff单位受到伤害都转化为MP"
    }
}
```

**验证指标**:
- [ ] 可以选择两个单位
- [ ] 两个单位的伤害都转化为MP

## Headless测试配置

### 测试运行命令
```bash
# Lv1 伤害转MP测试
godot --path . --headless -- --run-test=test_ascetic_lv1_convert

# Lv3 双目标测试
godot --path . --headless -- --run-test=test_ascetic_lv3_dual
```

### 通过标准
- 退出码为 0
- 无 SCRIPT ERROR
- 测试日志正常生成

## 实现步骤

1. **阅读现有代码**:
   - 阅读 `src/Scripts/Tests/TestSuite.gd` 了解测试配置格式
   - 阅读 `src/Scripts/Units/CowTotem/Ascetic.gd` 了解单位实现

2. **添加测试用例**:
   在 `TestSuite.gd` 的 `get_test_config` 函数中添加:
   ```gdscript
   "test_ascetic_lv1_convert":
       return {
           "id": "test_ascetic_lv1_convert",
           "core_type": "cow_totem",
           "duration": 20.0,
           "initial_mp": 500,
           "units": [
               {"id": "ascetic", "x": 0, "y": 1, "level": 1},
               {"id": "squirrel", "x": 1, "y": 0}
           ],
           "enemies": [
               {"type": "basic_enemy", "attack_damage": 50, "count": 3}
           ],
           "expected_behavior": "被Buff单位受到伤害的12%转为MP"
       }

   "test_ascetic_lv3_dual":
       return {
           "id": "test_ascetic_lv3_dual",
           "core_type": "cow_totem",
           "duration": 20.0,
           "units": [
               {"id": "ascetic", "x": 0, "y": 1, "level": 3},
               {"id": "squirrel", "x": 1, "y": 0},
               {"id": "bee", "x": -1, "y": 0}
           ],
           "expected_behavior": "可以选择两个单位施加Buff"
       }
   ```

3. **运行测试验证**:
   ```bash
   for test in test_ascetic_lv1_convert test_ascetic_lv3_dual; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```

4. **更新测试进度**:
   测试完成后，更新 `docs/test_progress.md` 中苦修者的验证指标。

## 进度更新要求

完成每个测试场景后，更新 `docs/progress.md`:

```markdown
| TEST-COW-ascetic | in_progress | 添加Lv1伤害转MP测试 | 2026-02-20T14:30:00 |
| TEST-COW-ascetic | in_progress | 添加Lv3双目标测试 | 2026-02-20T14:45:00 |
| TEST-COW-ascetic | completed | 所有测试通过 | 2026-02-20T15:00:00 |
```

同时在 `docs/test_progress.md` 中更新验证指标:
```markdown
**验证指标**:
- [x] 只能选择一个单位施加Buff
- [x] 受到伤害的12%转化为MP
- [x] MP增加量正确计算
- [x] 转化比例提升至18%（Lv2）
- [x] 可以选择两个单位（Lv3）
- [x] 两个单位的伤害都转化为MP

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
- `src/Scripts/Units/CowTotem/Ascetic.gd` - 单位实现

## Task ID

Task being executed: TEST-COW-ascetic
