# Jules 任务: 菌菇治愈者 (mushroom_healer) 自动化测试

## 任务ID
TEST-COW-mushroom_healer

## 任务描述
为菌菇治愈者单位创建完整的自动化测试用例，验证其孢子护盾机制，确保能在Headless模式下通过。

## 核心机制
**孢子护盾**: 为友方提供可抵消伤害的Buff

## 测试场景

### 测试场景 1: Lv1 孢子Buff验证
```gdscript
{
    "id": "test_mushroom_healer_lv1_spores",
    "core_type": "cow_totem",
    "duration": 20.0,
    "units": [
        {"id": "mushroom_healer", "x": 0, "y": 1, "level": 1},
        {"id": "squirrel", "x": 1, "y": 0}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3}
    ],
    "expected_behavior": {
        "description": "为周围友方添加1层孢子Buff，抵消1次伤害并使敌人叠加3层中毒",
        "verification": "松鼠第一次受击时不掉血，敌人获得中毒Debuff"
    }
}
```

**验证指标**:
- [ ] 周围友方获得孢子Buff
- [ ] Buff抵消1次伤害
- [ ] 抵消时敌人叠加3层中毒

### 测试场景 2: Lv2 孢子层数提升验证
**验证指标**:
- [ ] 孢子层数为3层

### 测试场景 3: Lv3 孢子耗尽伤害验证
```gdscript
{
    "id": "test_mushroom_healer_lv3_spore_damage",
    "core_type": "cow_totem",
    "duration": 20.0,
    "units": [
        {"id": "mushroom_healer", "x": 0, "y": 1, "level": 3},
        {"id": "squirrel", "x": 1, "y": 0}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 5}
    ],
    "expected_behavior": {
        "description": "孢子耗尽时额外造成一次中毒伤害",
        "verification": "孢子层数归零时，敌人受到额外中毒伤害"
    }
}
```

**验证指标**:
- [ ] 孢子层数耗尽时触发额外伤害
- [ ] 伤害类型为中毒伤害

## Headless测试配置

### 测试运行命令
```bash
# Lv1 孢子护盾测试
godot --path . --headless -- --run-test=test_mushroom_healer_lv1_spores

# Lv3 孢子耗尽伤害测试
godot --path . --headless -- --run-test=test_mushroom_healer_lv3_spore_damage
```

### 通过标准
- 退出码为 0
- 无 SCRIPT ERROR
- 测试日志正常生成

## 实现步骤

1. **阅读现有代码**:
   - 阅读 `src/Scripts/Tests/TestSuite.gd` 了解测试配置格式
   - 阅读 `src/Scripts/Units/CowTotem/MushroomHealer.gd` 了解单位实现

2. **添加测试用例**:
   在 `TestSuite.gd` 的 `get_test_config` 函数中添加:
   ```gdscript
   "test_mushroom_healer_lv1_spores":
       return {
           "id": "test_mushroom_healer_lv1_spores",
           "core_type": "cow_totem",
           "duration": 20.0,
           "units": [
               {"id": "mushroom_healer", "x": 0, "y": 1, "level": 1},
               {"id": "squirrel", "x": 1, "y": 0}
           ],
           "enemies": [
               {"type": "basic_enemy", "count": 3}
           ],
           "expected_behavior": "为周围友方添加孢子Buff，抵消1次伤害并使敌人叠加3层中毒"
       }

   "test_mushroom_healer_lv3_spore_damage":
       return {
           "id": "test_mushroom_healer_lv3_spore_damage",
           "core_type": "cow_totem",
           "duration": 20.0,
           "units": [
               {"id": "mushroom_healer", "x": 0, "y": 1, "level": 3},
               {"id": "squirrel", "x": 1, "y": 0}
           ],
           "enemies": [
               {"type": "basic_enemy", "count": 5}
           ],
           "expected_behavior": "孢子耗尽时额外造成一次中毒伤害"
       }
   ```

3. **运行测试验证**:
   ```bash
   for test in test_mushroom_healer_lv1_spores test_mushroom_healer_lv3_spore_damage; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```

4. **更新测试进度**:
   测试完成后，更新 `docs/test_progress.md` 中菌菇治愈者的验证指标。

## 进度更新要求

完成每个测试场景后，更新 `docs/progress.md`:

```markdown
| TEST-COW-mushroom_healer | in_progress | 添加Lv1孢子护盾测试 | 2026-02-20T14:30:00 |
| TEST-COW-mushroom_healer | in_progress | 添加Lv3孢子耗尽伤害测试 | 2026-02-20T14:45:00 |
| TEST-COW-mushroom_healer | completed | 所有测试通过 | 2026-02-20T15:00:00 |
```

同时在 `docs/test_progress.md` 中更新验证指标:
```markdown
**验证指标**:
- [x] 周围友方获得孢子Buff
- [x] Buff抵消1次伤害
- [x] 抵消时敌人叠加3层中毒
- [x] 孢子层数为3层（Lv2）
- [x] 孢子层数耗尽时触发额外伤害（Lv3）
- [x] 伤害类型为中毒伤害

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
- `src/Scripts/Units/CowTotem/MushroomHealer.gd` - 单位实现

## Task ID

Task being executed: TEST-COW-mushroom_healer
