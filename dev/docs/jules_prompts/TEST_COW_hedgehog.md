# Jules 任务: 刺猬 (hedgehog) 自动化测试

## 任务ID
TEST-COW-hedgehog

## 任务描述
为刺猬单位创建完整的自动化测试用例，验证其伤害反弹机制，确保能在Headless模式下通过。

## 核心机制
**尖刺反弹**: 受到伤害时概率反弹伤害

## 测试场景

### 测试场景 1: Lv1 反弹概率验证
```gdscript
{
    "id": "test_hedgehog_lv1_reflect",
    "core_type": "cow_totem",
    "duration": 30.0,
    "units": [
        {"id": "hedgehog", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 10, "hp": 100}
    ],
    "expected_behavior": {
        "description": "30%概率反弹敌人伤害",
        "verification": "统计多次攻击中反弹发生的次数，概率应在30%左右"
    }
}
```

**验证指标**:
- [ ] 反弹概率为30%
- [ ] 反弹伤害等于敌人造成的伤害

### 测试场景 2: Lv2 反弹概率提升验证
**验证指标**:
- [ ] 反弹概率提升至50%

### 测试场景 3: Lv3 刚毛散射验证
```gdscript
{
    "id": "test_hedgehog_lv3_spikes",
    "core_type": "cow_totem",
    "duration": 20.0,
    "units": [
        {"id": "hedgehog", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 5, "positions": [{"x": 2, "y": 0}, {"x": -2, "y": 0}, {"x": 0, "y": 2}]},
        {"type": "attacker_enemy", "count": 1}
    ],
    "expected_behavior": {
        "description": "反伤时向周围发射3枚尖刺",
        "verification": "检查周围敌人是否受到尖刺伤害"
    }
}
```

**验证指标**:
- [ ] 反弹时触发尖刺散射
- [ ] 散射尖刺数量为3枚
- [ ] 尖刺对范围内敌人造成伤害

## Headless测试配置

### 测试运行命令
```bash
# Lv1 反弹概率测试
godot --path . --headless -- --run-test=test_hedgehog_lv1_reflect

# Lv3 刚毛散射测试
godot --path . --headless -- --run-test=test_hedgehog_lv3_spikes
```

### 通过标准
- 退出码为 0
- 无 SCRIPT ERROR
- 测试日志正常生成

## 实现步骤

1. **阅读现有代码**:
   - 阅读 `src/Scripts/Tests/TestSuite.gd` 了解测试配置格式
   - 阅读 `src/Scripts/Units/CowTotem/Hedgehog.gd` 了解单位实现

2. **添加测试用例**:
   在 `TestSuite.gd` 的 `get_test_config` 函数中添加:
   ```gdscript
   "test_hedgehog_lv1_reflect":
       return {
           "id": "test_hedgehog_lv1_reflect",
           "core_type": "cow_totem",
           "duration": 30.0,
           "units": [
               {"id": "hedgehog", "x": 0, "y": 1, "level": 1}
           ],
           "enemies": [
               {"type": "attacker_enemy", "attack_damage": 20, "count": 5}
           ],
           "expected_behavior": "30%概率反弹伤害，反弹伤害等于敌人造成的伤害"
       }

   "test_hedgehog_lv3_spikes":
       return {
           "id": "test_hedgehog_lv3_spikes",
           "core_type": "cow_totem",
           "duration": 20.0,
           "units": [
               {"id": "hedgehog", "x": 0, "y": 1, "level": 3}
           ],
           "enemies": [
               {"type": "basic_enemy", "count": 5, "positions": [{"x": 2, "y": 0}, {"x": -2, "y": 0}, {"x": 0, "y": 2}]},
               {"type": "attacker_enemy", "count": 1}
           ],
           "expected_behavior": "反伤时向周围发射3枚尖刺"
       }
   ```

3. **运行测试验证**:
   ```bash
   for test in test_hedgehog_lv1_reflect test_hedgehog_lv3_spikes; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```

4. **更新测试进度**:
   测试完成后，更新 `docs/test_progress.md` 中刺猬的验证指标。

## 进度更新要求

完成每个测试场景后，更新 `docs/progress.md`:

```markdown
| TEST-COW-hedgehog | in_progress | 添加Lv1反弹概率测试 | 2026-02-20T14:30:00 |
| TEST-COW-hedgehog | in_progress | 添加Lv3刚毛散射测试 | 2026-02-20T14:45:00 |
| TEST-COW-hedgehog | completed | 所有测试通过 | 2026-02-20T15:00:00 |
```

同时在 `docs/test_progress.md` 中更新验证指标:
```markdown
**验证指标**:
- [x] 反弹概率为30%
- [x] 反弹伤害等于敌人造成的伤害
- [x] 反弹概率提升至50%（Lv2）
- [x] 反弹时触发尖刺散射（Lv3）
- [x] 散射尖刺数量为3枚
- [x] 尖刺对范围内敌人造成伤害

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
- `src/Scripts/Units/CowTotem/Hedgehog.gd` - 单位实现

## Task ID

Task being executed: TEST-COW-hedgehog
