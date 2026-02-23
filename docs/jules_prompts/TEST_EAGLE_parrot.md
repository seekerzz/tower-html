# Jules 任务: 鹦鹉 (parrot) 自动化测试

## 任务ID
TEST-EAGLE-parrot

## 任务描述
为鹦鹉单位创建完整的自动化测试用例，验证其模仿机制，确保能在Headless模式下通过。

## 核心机制
**模仿**: 模仿友军攻击特效

## 测试场景

### 测试场景 1: Lv1 模仿验证
```gdscript
{
    "id": "test_parrot_lv1_mimic",
    "core_type": "eagle_totem",
    "duration": 20.0,
    "units": [
        {"id": "parrot", "x": 0, "y": 1, "level": 1},
        {"id": "woodpecker", "x": 1, "y": 0, "level": 1}  # 被模仿单位
    ],
    "setup_actions": [
        {"type": "mimic", "source": "parrot", "target": "woodpecker"}
    ],
    "enemies": [
        {"type": "high_hp_enemy", "count": 1, "hp": 500}
    ],
    "expected_behavior": {
        "description": "模仿相邻友军的攻击特效",
        "verification": "鹦鹉获得啄木鸟的钻孔效果"
    }
}
```

**验证指标**:
- [ ] 可复制相邻友军特效
- [ ] 模仿后获得相同效果

### 测试场景 2: Lv2 模仿效果提升验证
**验证指标**:
- [ ] 模仿效果+50%

### 测试场景 3: Lv3 完美模仿验证
**验证指标**:
- [ ] 可模仿Lv.3单位的特效

## Headless测试配置

### 测试运行命令
```bash
# Lv1 模仿测试
godot --path . --headless -- --run-test=test_parrot_lv1_mimic

# Lv2 模仿效果提升测试
godot --path . --headless -- --run-test=test_parrot_lv2_enhanced

# Lv3 完美模仿测试
godot --path . --headless -- --run-test=test_parrot_lv3_perfect
```

### 通过标准
- 退出码为 0
- 无 SCRIPT ERROR
- 测试日志正常生成

## 实现步骤

1. **阅读现有代码**:
   - 阅读 `src/Scripts/Tests/TestSuite.gd` 了解测试配置格式
   - 阅读 `src/Scripts/Units/EagleTotem/Parrot.gd` 了解单位实现

2. **添加测试用例**:
   在 `TestSuite.gd` 的 `get_test_config` 函数中添加:
   ```gdscript
   "test_parrot_lv1_mimic":
       return {
           "id": "test_parrot_lv1_mimic",
           "core_type": "eagle_totem",
           "duration": 20.0,
           "units": [
               {"id": "parrot", "x": 0, "y": 1, "level": 1},
               {"id": "woodpecker", "x": 1, "y": 0, "level": 1}
           ],
           "setup_actions": [
               {"type": "mimic", "source": "parrot", "target": "woodpecker"}
           ],
           "enemies": [
               {"type": "high_hp_enemy", "count": 1, "hp": 500}
           ],
           "expected_behavior": "模仿相邻友军的攻击特效"
       }

   "test_parrot_lv2_enhanced":
       return {
           "id": "test_parrot_lv2_enhanced",
           "core_type": "eagle_totem",
           "duration": 20.0,
           "units": [
               {"id": "parrot", "x": 0, "y": 1, "level": 2},
               {"id": "woodpecker", "x": 1, "y": 0, "level": 1}
           ],
           "setup_actions": [
               {"type": "mimic", "source": "parrot", "target": "woodpecker"}
           ],
           "enemies": [
               {"type": "high_hp_enemy", "count": 1, "hp": 500}
           ],
           "expected_behavior": "模仿效果+50%"
       }

   "test_parrot_lv3_perfect":
       return {
           "id": "test_parrot_lv3_perfect",
           "core_type": "eagle_totem",
           "duration": 20.0,
           "units": [
               {"id": "parrot", "x": 0, "y": 1, "level": 3},
               {"id": "woodpecker", "x": 1, "y": 0, "level": 3}
           ],
           "setup_actions": [
               {"type": "mimic", "source": "parrot", "target": "woodpecker"}
           ],
           "enemies": [
               {"type": "high_hp_enemy", "count": 1, "hp": 1000}
           ],
           "expected_behavior": "可模仿Lv.3单位的特效"
       }
   ```

3. **运行测试验证**:
   ```bash
   for test in test_parrot_lv1_mimic test_parrot_lv2_enhanced test_parrot_lv3_perfect; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```

4. **更新测试进度**:
   测试完成后，更新 `docs/test_progress.md` 中鹦鹉的验证指标。

## 进度更新要求

完成每个测试场景后，更新 `docs/progress.md`:

```markdown
| TEST-EAGLE-parrot | in_progress | 添加Lv1模仿测试 | 2026-02-20T14:30:00 |
| TEST-EAGLE-parrot | in_progress | 添加Lv2模仿效果提升测试 | 2026-02-20T14:40:00 |
| TEST-EAGLE-parrot | in_progress | 添加Lv3完美模仿测试 | 2026-02-20T14:50:00 |
| TEST-EAGLE-parrot | completed | 所有测试通过 | 2026-02-20T15:00:00 |
```

同时在 `docs/test_progress.md` 中更新验证指标:
```markdown
**验证指标**:
- [x] 可复制相邻友军特效
- [x] 模仿后获得相同效果
- [x] 模仿效果+50%（Lv2）
- [x] 可模仿Lv.3单位的特效（Lv3）

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
- `src/Scripts/Units/EagleTotem/Parrot.gd` - 单位实现

## Task ID

Task being executed: TEST-EAGLE-parrot
