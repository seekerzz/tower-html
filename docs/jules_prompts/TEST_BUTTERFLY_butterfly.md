# Jules 任务: 蝴蝶 (butterfly) 自动化测试

## 任务ID
TEST-BUTTERFLY-butterfly

## 任务描述
为蝴蝶单位创建完整的自动化测试用例，验证其法力消耗增伤机制，确保能在Headless模式下通过。

## 核心机制
**法力光辉**: 消耗法力增加伤害，攻击时消耗5%最大法力，附加消耗法力100%的伤害

## 测试场景

### 测试场景 1: Lv1 法力光辉验证
```gdscript
{
    "id": "test_butterfly_lv1_mana",
    "core_type": "butterfly_totem",
    "duration": 15.0,
    "initial_mp": 500,
    "units": [
        {"id": "butterfly", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3}
    ],
    "expected_behavior": {
        "description": "消耗5%最大法力，附加消耗法力100%的伤害",
        "verification": "攻击时MP减少25点，伤害增加25点"
    }
}
```

**验证指标**:
- [ ] 攻击消耗5%最大法力(25点)
- [ ] 附加伤害等于消耗的法力值
- [ ] MP不足时正常攻击

### 测试场景 2: Lv2 伤害倍率提升验证
**验证指标**:
- [ ] 附加伤害为消耗法力的150%

### 测试场景 3: Lv3 击杀回蓝验证
```gdscript
{
    "id": "test_butterfly_lv3_kill_restore",
    "core_type": "butterfly_totem",
    "duration": 20.0,
    "initial_mp": 400,
    "units": [
        {"id": "butterfly", "x": 0, "y": 1, "level": 3, "attack": 100}
    ],
    "enemies": [
        {"type": "weak_enemy", "count": 5, "hp": 50}
    ],
    "expected_behavior": {
        "description": "每次击杀敌人恢复10%最大法力",
        "verification": "击杀敌人后MP增加50点"
    }
}
```

**验证指标**:
- [ ] 击杀敌人恢复10%最大法力
- [ ] 恢复量为50点(基于1000上限)

## Headless测试配置

### 测试运行命令
```bash
# Lv1 法力光辉测试
godot --path . --headless -- --run-test=test_butterfly_lv1_mana

# Lv2 伤害倍率测试
godot --path . --headless -- --run-test=test_butterfly_lv2_damage

# Lv3 击杀回蓝测试
godot --path . --headless -- --run-test=test_butterfly_lv3_kill_restore
```

### 通过标准
- 退出码为 0
- 无 SCRIPT ERROR
- 测试日志正常生成

## 实现步骤

1. **阅读现有代码**:
   - 阅读 `src/Scripts/Tests/TestSuite.gd` 了解测试配置格式
   - 阅读 `src/Scripts/Units/ButterflyTotem/Butterfly.gd` 了解单位实现

2. **添加测试用例**:
   在 `TestSuite.gd` 的 `get_test_config` 函数中添加:
   ```gdscript
   "test_butterfly_lv1_mana":
       return {
           "id": "test_butterfly_lv1_mana",
           "core_type": "butterfly_totem",
           "duration": 15.0,
           "initial_mp": 500,
           "units": [
               {"id": "butterfly", "x": 0, "y": 1, "level": 1}
           ],
           "enemies": [
               {"type": "basic_enemy", "count": 3}
           ],
           "expected_behavior": "消耗5%最大法力，附加消耗法力100%的伤害"
       }

   "test_butterfly_lv2_damage":
       return {
           "id": "test_butterfly_lv2_damage",
           "core_type": "butterfly_totem",
           "duration": 15.0,
           "initial_mp": 500,
           "units": [
               {"id": "butterfly", "x": 0, "y": 1, "level": 2}
           ],
           "expected_behavior": "附加伤害为消耗法力的150%"
       }

   "test_butterfly_lv3_kill_restore":
       return {
           "id": "test_butterfly_lv3_kill_restore",
           "core_type": "butterfly_totem",
           "duration": 20.0,
           "initial_mp": 400,
           "units": [
               {"id": "butterfly", "x": 0, "y": 1, "level": 3, "attack": 100}
           ],
           "enemies": [
               {"type": "weak_enemy", "count": 5, "hp": 50}
           ],
           "expected_behavior": "击杀敌人恢复10%最大法力"
       }
   ```

3. **运行测试验证**:
   ```bash
   for test in test_butterfly_lv1_mana test_butterfly_lv2_damage test_butterfly_lv3_kill_restore; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```

4. **更新测试进度**:
   测试完成后，更新 `docs/test_progress.md` 中蝴蝶的验证指标。

## 进度更新要求

完成每个测试场景后，更新 `docs/progress.md`:

```markdown
| TEST-BUTTERFLY-butterfly | in_progress | 添加Lv1法力光辉测试 | 2026-02-20T14:30:00 |
| TEST-BUTTERFLY-butterfly | in_progress | 添加Lv2伤害倍率测试 | 2026-02-20T14:45:00 |
| TEST-BUTTERFLY-butterfly | completed | 所有测试通过 | 2026-02-20T15:00:00 |
```

同时在 `docs/test_progress.md` 中更新验证指标:
```markdown
**验证指标**:
- [x] 攻击消耗5%最大法力(25点)
- [x] 附加伤害等于消耗的法力值
- [x] MP不足时正常攻击

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
- `src/Scripts/Units/ButterflyTotem/Butterfly.gd` - 单位实现

## Task ID

Task being executed: TEST-BUTTERFLY-butterfly
