# Jules 任务: 红莲火炬 (torch) 自动化测试

## 任务ID
TEST-BUTTERFLY-torch

## 任务描述
为红莲火炬单位创建完整的自动化测试用例，验证其燃烧Buff机制，确保能在Headless模式下通过。

## 核心机制
**燃烧Buff**: 赋予周围单位燃烧Buff，攻击使敌人叠加燃烧层数，最多5层，造成持续伤害

## 测试场景

### 测试场景 1: Lv1 燃烧Buff验证
```gdscript
{
    "id": "test_torch_lv1_burn",
    "core_type": "butterfly_totem",
    "duration": 20.0,
    "units": [
        {"id": "torch", "x": 0, "y": 1, "level": 1},
        {"id": "squirrel", "x": 1, "y": 0}
    ],
    "setup_actions": [
        {"type": "apply_buff", "buff_id": "fire", "target_unit_id": "squirrel"}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3}
    ],
    "expected_behavior": {
        "description": "赋予周围一个单位燃烧Buff，燃烧可叠加5层",
        "verification": "松鼠攻击使敌人叠加燃烧层数，最多5层"
    }
}
```

**验证指标**:
- [ ] 可赋予1个单位燃烧Buff
- [ ] 燃烧可叠加5层
- [ ] 每层燃烧造成持续伤害

### 测试场景 2: Lv2 额外目标验证
**验证指标**:
- [ ] 可赋予2个单位燃烧Buff

### 测试场景 3: Lv3 爆燃验证
```gdscript
{
    "id": "test_torch_lv3_explosion",
    "core_type": "butterfly_totem",
    "duration": 25.0,
    "units": [
        {"id": "torch", "x": 0, "y": 1, "level": 3},
        {"id": "squirrel", "x": 1, "y": 0}
    ],
    "setup_actions": [
        {"type": "apply_buff", "buff_id": "fire", "target_unit_id": "squirrel"}
    ],
    "enemies": [
        {"type": "high_hp_enemy", "count": 1, "hp": 500}
    ],
    "expected_behavior": {
        "description": "燃烧叠加到5层时引爆，造成目标10%最大HP伤害",
        "verification": "5层燃烧时触发爆炸，造成目标50点伤害"
    }
}
```

**验证指标**:
- [ ] 5层燃烧时触发爆炸
- [ ] 爆炸伤害为敌人最大血量的10%

## Headless测试配置

### 测试运行命令
```bash
# Lv1 燃烧Buff测试
godot --path . --headless -- --run-test=test_torch_lv1_burn

# Lv2 额外目标测试
godot --path . --headless -- --run-test=test_torch_lv2_targets

# Lv3 爆燃测试
godot --path . --headless -- --run-test=test_torch_lv3_explosion
```

### 通过标准
- 退出码为 0
- 无 SCRIPT ERROR
- 测试日志正常生成

## 实现步骤

1. **阅读现有代码**:
   - 阅读 `src/Scripts/Tests/TestSuite.gd` 了解测试配置格式
   - 阅读 `src/Scripts/Units/ButterflyTotem/Torch.gd` 了解单位实现

2. **添加测试用例**:
   在 `TestSuite.gd` 的 `get_test_config` 函数中添加:
   ```gdscript
   "test_torch_lv1_burn":
       return {
           "id": "test_torch_lv1_burn",
           "core_type": "butterfly_totem",
           "duration": 20.0,
           "units": [
               {"id": "torch", "x": 0, "y": 1, "level": 1},
               {"id": "squirrel", "x": 1, "y": 0}
           ],
           "setup_actions": [
               {"type": "apply_buff", "buff_id": "fire", "target_unit_id": "squirrel"}
           ],
           "enemies": [
               {"type": "basic_enemy", "count": 3}
           ],
           "expected_behavior": "赋予周围一个单位燃烧Buff，燃烧可叠加5层"
       }

   "test_torch_lv2_targets":
       return {
           "id": "test_torch_lv2_targets",
           "core_type": "butterfly_totem",
           "duration": 20.0,
           "units": [
               {"id": "torch", "x": 0, "y": 1, "level": 2},
               {"id": "squirrel", "x": 1, "y": 0},
               {"id": "wolf", "x": -1, "y": 0}
           ],
           "expected_behavior": "可赋予2个单位燃烧Buff"
       }

   "test_torch_lv3_explosion":
       return {
           "id": "test_torch_lv3_explosion",
           "core_type": "butterfly_totem",
           "duration": 25.0,
           "units": [
               {"id": "torch", "x": 0, "y": 1, "level": 3},
               {"id": "squirrel", "x": 1, "y": 0}
           ],
           "enemies": [
               {"type": "high_hp_enemy", "count": 1, "hp": 500}
           ],
           "expected_behavior": "5层燃烧时触发爆炸，造成目标10%最大HP伤害"
       }
   ```

3. **运行测试验证**:
   ```bash
   for test in test_torch_lv1_burn test_torch_lv2_targets test_torch_lv3_explosion; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```

4. **更新测试进度**:
   测试完成后，更新 `docs/test_progress.md` 中红莲火炬的验证指标。

## 进度更新要求

完成每个测试场景后，更新 `docs/progress.md`:

```markdown
| TEST-BUTTERFLY-torch | in_progress | 添加Lv1燃烧Buff测试 | 2026-02-20T14:30:00 |
| TEST-BUTTERFLY-torch | in_progress | 添加Lv2额外目标测试 | 2026-02-20T14:45:00 |
| TEST-BUTTERFLY-torch | completed | 所有测试通过 | 2026-02-20T15:00:00 |
```

同时在 `docs/test_progress.md` 中更新验证指标:
```markdown
**验证指标**:
- [x] 可赋予1个单位燃烧Buff
- [x] 燃烧可叠加5层
- [x] 每层燃烧造成持续伤害

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
- `src/Scripts/Units/ButterflyTotem/Torch.gd` - 单位实现

## Task ID

Task being executed: TEST-BUTTERFLY-torch
