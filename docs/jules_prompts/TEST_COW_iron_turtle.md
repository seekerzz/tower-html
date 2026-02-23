# Jules 任务: 铁甲龟 (iron_turtle) 自动化测试

## 任务ID
TEST-COW-iron_turtle

## 任务描述
为铁甲龟单位创建完整的自动化测试用例，验证其固定减伤机制，确保能在Headless模式下通过。

## 核心机制
**硬化皮肤**: 受到伤害时减去固定数值

## 测试场景

### 测试场景 1: Lv1 固定减伤验证
```gdscript
{
    "id": "test_iron_turtle_lv1_reduction",
    "core_type": "cow_totem",
    "duration": 15.0,
    "units": [
        {"id": "iron_turtle", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "attack_damage": 30, "count": 3}
    ],
    "expected_behavior": {
        "description": "敌人攻击铁甲龟时，伤害减少20点",
        "verification": "核心血量减少量 = 原伤害 - 20"
    }
}
```

**验证指标**:
- [ ] 敌人攻击伤害30点，核心实际损失10点
- [ ] 减伤数值为固定20点

### 测试场景 2: Lv2 减伤提升验证
**验证指标**:
- [ ] 减伤数值提升至35点

### 测试场景 3: Lv3 绝对防御与回血验证
```gdscript
{
    "id": "test_iron_turtle_lv3_absolute_defense",
    "core_type": "cow_totem",
    "duration": 15.0,
    "core_health": 500,
    "units": [
        {"id": "iron_turtle", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "weak_enemy", "attack_damage": 10, "count": 5}
    ],
    "expected_behavior": {
        "description": "当伤害被减为0或miss时，回复1%核心HP",
        "verification": "观察核心血量是否增加"
    }
}
```

**验证指标**:
- [ ] 减伤数值提升至50点
- [ ] 当敌人伤害≤50时，核心不扣血反而回血
- [ ] 回血量为最大核心血量的1%

## Headless测试配置

### 测试运行命令
```bash
# Lv1 固定减伤测试
godot --path . --headless -- --run-test=test_iron_turtle_lv1_reduction

# Lv3 绝对防御测试
godot --path . --headless -- --run-test=test_iron_turtle_lv3_absolute_defense
```

### 通过标准
- 退出码为 0
- 无 SCRIPT ERROR
- 测试日志正常生成

## 实现步骤

1. **阅读现有代码**:
   - 阅读 `src/Scripts/Tests/TestSuite.gd` 了解测试配置格式
   - 阅读 `src/Scripts/Units/CowTotem/IronTurtle.gd` 了解单位实现

2. **添加测试用例**:
   在 `TestSuite.gd` 的 `get_test_config` 函数中添加:
   ```gdscript
   "test_iron_turtle_lv1_reduction":
       return {
           "id": "test_iron_turtle_lv1_reduction",
           "core_type": "cow_totem",
           "core_health": 500,
           "duration": 15.0,
           "units": [
               {"id": "iron_turtle", "x": 0, "y": 1, "level": 1}
           ],
           "enemies": [
               {"type": "attacker_enemy", "attack_damage": 30, "count": 3}
           ],
           "expected_behavior": "敌人攻击30点伤害，核心实际损失10点（减伤20点）"
       }

   "test_iron_turtle_lv3_absolute_defense":
       return {
           "id": "test_iron_turtle_lv3_absolute_defense",
           "core_type": "cow_totem",
           "duration": 15.0,
           "core_health": 500,
           "units": [
               {"id": "iron_turtle", "x": 0, "y": 1, "level": 3}
           ],
           "enemies": [
               {"type": "weak_enemy", "attack_damage": 10, "count": 5}
           ],
           "expected_behavior": "当伤害被减为0时，回复1%核心HP"
       }
   ```

3. **运行测试验证**:
   ```bash
   for test in test_iron_turtle_lv1_reduction test_iron_turtle_lv3_absolute_defense; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```

4. **更新测试进度**:
   测试完成后，更新 `docs/test_progress.md` 中铁甲龟的验证指标。

## 进度更新要求

完成每个测试场景后，更新 `docs/progress.md`:

```markdown
| TEST-COW-iron_turtle | in_progress | 添加Lv1固定减伤测试 | 2026-02-20T14:30:00 |
| TEST-COW-iron_turtle | in_progress | 添加Lv3绝对防御测试 | 2026-02-20T14:45:00 |
| TEST-COW-iron_turtle | completed | 所有测试通过 | 2026-02-20T15:00:00 |
```

同时在 `docs/test_progress.md` 中更新验证指标:
```markdown
**验证指标**:
- [x] 敌人攻击伤害30点，核心实际损失10点
- [x] 减伤数值为固定20点
- [x] 减伤数值提升至35点（Lv2）
- [x] 减伤数值提升至50点（Lv3）
- [x] 当敌人伤害≤50时，核心不扣血反而回血
- [x] 回血量为最大核心血量的1%

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
- `src/Scripts/Units/CowTotem/IronTurtle.gd` - 单位实现

## Task ID

Task being executed: TEST-COW-iron_turtle
