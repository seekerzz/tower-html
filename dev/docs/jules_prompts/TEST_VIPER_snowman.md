# Jules 任务: 雪人自动化测试 (TEST-VIPER-snowman)

## 任务ID
TEST-VIPER-snowman

## 任务描述
为眼镜蛇图腾流派单位"雪人"创建完整的自动化测试用例，验证其冰冻陷阱机制和Lv3冰封剧毒机制。

## 单位信息

| 属性 | 值 |
|------|-----|
| 单位ID | snowman |
| 名称 | 雪人 |
| 图标 | ⛄ |
| 派系 | viper_totem |
| 攻击类型 | trap |
| 特性 | freeze, area_damage |

**核心机制**: 制造冰冻陷阱冻结敌人，Lv3冰冻结束时造成Debuff层数伤害

## 详细测试场景

### 测试场景 1: Lv1 冰冻陷阱验证

```gdscript
"test_snowman_lv1_freeze":
    return {
        "id": "test_snowman_lv1_freeze",
        "core_type": "viper_totem",
        "duration": 20.0,
        "units": [
            {"id": "snowman", "x": 0, "y": 1, "level": 1}
        ],
        "enemies": [
            {"type": "basic_enemy", "path": [{"x": 2, "y": 0}], "count": 3}
        ],
        "scheduled_actions": [
            {"time": 2.0, "type": "place_trap", "trap_id": "freeze_trap", "position": {"x": 2, "y": 0}}
        ],
        "expected_behavior": "制造冰冻陷阱，延迟1.5秒后触发冰冻，范围内敌人被冻结2秒"
    }
```

**验证指标**:
- [ ] 陷阱延迟1.5秒触发
- [ ] 冻结范围内敌人
- [ ] 冻结持续2秒

### 测试场景 2: Lv2 冻结时间提升验证

```gdscript
"test_snowman_lv2_freeze":
    return {
        "id": "test_snowman_lv2_freeze",
        "core_type": "viper_totem",
        "duration": 20.0,
        "units": [
            {"id": "snowman", "x": 0, "y": 1, "level": 2}
        ],
        "enemies": [
            {"type": "basic_enemy", "path": [{"x": 2, "y": 0}], "count": 3}
        ],
        "scheduled_actions": [
            {"time": 2.0, "type": "place_trap", "trap_id": "freeze_trap", "position": {"x": 2, "y": 0}}
        ],
        "expected_behavior": "冻结时间提升至3秒"
    }
```

**验证指标**:
- [ ] 冻结时间提升至3秒

### 测试场景 3: Lv3 冰封剧毒验证

```gdscript
"test_snowman_lv3_ice_poison":
    return {
        "id": "test_snowman_lv3_ice_poison",
        "core_type": "viper_totem",
        "duration": 25.0,
        "units": [
            {"id": "snowman", "x": 0, "y": 1, "level": 3}
        ],
        "enemies": [
            {"type": "poisoned_enemy", "hp": 100, "debuffs": [{"type": "poison", "stacks": 5}], "count": 3}
        ],
        "expected_behavior": "冰冻结束时敌人受到Debuff层数伤害，冻结结束时敌人受到5层中毒的伤害"
    }
```

**验证指标**:
- [ ] 冰冻结束时造成伤害
- [ ] 伤害与Debuff层数相关

## 实现要求

1. **添加到 TestSuite.gd**: 在 `get_test_config` 函数的 match 语句中添加以上所有测试用例

2. **测试运行验证**: 每个测试用例必须能通过 Headless 模式运行：
   ```bash
   godot --path . --headless -- --run-test=test_snowman_lv1_freeze
   godot --path . --headless -- --run-test=test_snowman_lv2_freeze
   godot --path . --headless -- --run-test=test_snowman_lv3_ice_poison
   ```

3. **通过标准**:
   - 退出码为 0
   - 无 SCRIPT ERROR
   - 测试日志正常生成

4. **更新测试进度**: 测试完成后，更新 `docs/test_progress.md`:
   - 将 `[ ]` 标记为 `[x]` 表示测试通过
   - 更新测试进度概览表
   - 添加测试记录

## 实现步骤

1. 阅读现有 `src/Scripts/Tests/TestSuite.gd` 了解测试配置格式
2. 阅读 `docs/test_progress.md` 了解详细测试场景
3. 在 TestSuite.gd 中添加以上 3 个测试用例
4. 运行测试验证：
   ```bash
   for test in test_snowman_lv1_freeze test_snowman_lv2_freeze test_snowman_lv3_ice_poison; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```
5. 更新 `docs/test_progress.md` 中的测试进度

## 代码提交要求

1. 在独立分支上工作：`feature/TEST-VIPER-snowman`
2. 提交信息格式：`[TEST-VIPER-snowman] Add automated tests for Snowman unit`
3. 完成后创建 Pull Request 到 main 分支

## 进度同步

完成每个测试用例后，更新 `docs/progress.md`：

```markdown
| TEST-VIPER-snowman | in_progress | 添加雪人Lv1测试 | 2026-02-20T14:30:00 |
```

## 相关文档

- `docs/test_progress.md` - 详细测试场景规范
- `docs/roles/qa_engineer.md` - 测试工程师角色指南
- `src/Scripts/Tests/AutomatedTestRunner.gd` - 测试运行器
- `src/Scripts/Tests/TestSuite.gd` - 测试配置
- `data/game_data.json` - 单位数据配置

## Task ID

Task being executed: TEST-VIPER-snowman
