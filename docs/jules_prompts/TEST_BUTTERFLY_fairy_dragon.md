# Jules 任务: 仙女龙 (fairy_dragon) 自动化测试

## 任务ID
TEST-BUTTERFLY-fairy_dragon

## 任务描述
为仙女龙单位创建完整的自动化测试用例，验证其传送敌人机制，确保能在Headless模式下通过。

## 核心机制
**相位传送**: 攻击时概率将敌人传送至3格外，Lv3传送时叠加瘟疫Debuff

## 测试场景

### 测试场景 1: Lv1 传送验证
```gdscript
{
    "id": "test_fairy_dragon_lv1_teleport",
    "core_type": "butterfly_totem",
    "duration": 30.0,
    "units": [
        {"id": "fairy_dragon", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 10}
    ],
    "expected_behavior": {
        "description": "25%概率将敌人传送至3格外",
        "verification": "约25%的攻击触发传送，敌人位置突变"
    }
}
```

**验证指标**:
- [ ] 传送概率为25%
- [ ] 敌人被传送至3格外
- [ ] 传送不造成伤害

### 测试场景 2: Lv2 传送概率提升验证
**验证指标**:
- [ ] 传送概率提升至40%

### 测试场景 3: Lv3 相位崩塌验证
```gdscript
{
    "id": "test_fairy_dragon_lv3_collapse",
    "core_type": "butterfly_totem",
    "duration": 25.0,
    "units": [
        {"id": "fairy_dragon", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 5}
    ],
    "expected_behavior": {
        "description": "被传送敌人叠加两层瘟疫debuff",
        "verification": "传送触发后敌人获得2层plague_debuff"
    }
}
```

**验证指标**:
- [ ] 传送触发时叠加2层瘟疫Debuff
- [ ] Debuff使敌人受到更多伤害

## Headless测试配置

### 测试运行命令
```bash
# Lv1 传送测试
godot --path . --headless -- --run-test=test_fairy_dragon_lv1_teleport

# Lv2 传送概率测试
godot --path . --headless -- --run-test=test_fairy_dragon_lv2_probability

# Lv3 相位崩塌测试
godot --path . --headless -- --run-test=test_fairy_dragon_lv3_collapse
```

### 通过标准
- 退出码为 0
- 无 SCRIPT ERROR
- 测试日志正常生成

## 实现步骤

1. **阅读现有代码**:
   - 阅读 `src/Scripts/Tests/TestSuite.gd` 了解测试配置格式
   - 阅读 `src/Scripts/Units/ButterflyTotem/FairyDragon.gd` 了解单位实现

2. **添加测试用例**:
   在 `TestSuite.gd` 的 `get_test_config` 函数中添加:
   ```gdscript
   "test_fairy_dragon_lv1_teleport":
       return {
           "id": "test_fairy_dragon_lv1_teleport",
           "core_type": "butterfly_totem",
           "duration": 30.0,
           "units": [
               {"id": "fairy_dragon", "x": 0, "y": 1, "level": 1}
           ],
           "enemies": [
               {"type": "basic_enemy", "count": 10}
           ],
           "expected_behavior": "25%概率将敌人传送至3格外"
       }

   "test_fairy_dragon_lv2_probability":
       return {
           "id": "test_fairy_dragon_lv2_probability",
           "core_type": "butterfly_totem",
           "duration": 30.0,
           "units": [
               {"id": "fairy_dragon", "x": 0, "y": 1, "level": 2}
           ],
           "enemies": [
               {"type": "basic_enemy", "count": 10}
           ],
           "expected_behavior": "传送概率提升至40%"
       }

   "test_fairy_dragon_lv3_collapse":
       return {
           "id": "test_fairy_dragon_lv3_collapse",
           "core_type": "butterfly_totem",
           "duration": 25.0,
           "units": [
               {"id": "fairy_dragon", "x": 0, "y": 1, "level": 3}
           ],
           "enemies": [
               {"type": "basic_enemy", "count": 5}
           ],
           "expected_behavior": "被传送敌人叠加两层瘟疫debuff"
       }
   ```

3. **运行测试验证**:
   ```bash
   for test in test_fairy_dragon_lv1_teleport test_fairy_dragon_lv2_probability test_fairy_dragon_lv3_collapse; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```

4. **更新测试进度**:
   测试完成后，更新 `docs/test_progress.md` 中仙女龙的验证指标。

## 进度更新要求

完成每个测试场景后，更新 `docs/progress.md`:

```markdown
| TEST-BUTTERFLY-fairy_dragon | in_progress | 添加Lv1传送测试 | 2026-02-20T14:30:00 |
| TEST-BUTTERFLY-fairy_dragon | in_progress | 添加Lv2传送概率测试 | 2026-02-20T14:45:00 |
| TEST-BUTTERFLY-fairy_dragon | completed | 所有测试通过 | 2026-02-20T15:00:00 |
```

同时在 `docs/test_progress.md` 中更新验证指标:
```markdown
**验证指标**:
- [x] 传送概率为25%
- [x] 敌人被传送至3格外
- [x] 传送不造成伤害

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
- `src/Scripts/Units/ButterflyTotem/FairyDragon.gd` - 单位实现

## Task ID

Task being executed: TEST-BUTTERFLY-fairy_dragon
