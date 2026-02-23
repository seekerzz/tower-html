# Jules 任务: 诱捕蛇自动化测试 (TEST-VIPER-lure_snake)

## 任务ID
TEST-VIPER-lure_snake

## 任务描述
为眼镜蛇图腾流派单位"诱捕蛇"创建完整的自动化测试用例，验证其陷阱放置机制和毒素伤害机制。

## 单位信息

| 属性 | 值 |
|------|-----|
| 单位ID | lure_snake |
| 名称 | 诱捕蛇/蟾蜍 |
| 图标 | 🐍 |
| 派系 | viper_totem |
| 攻击类型 | trap |
| 特性 | poison_trap, distance_damage |

**核心机制**: 放置毒陷阱，敌人触发后受到伤害并中毒，Lv3附加距离伤害Debuff

## 详细测试场景

### 测试场景 1: Lv1 毒陷阱验证

```gdscript
"test_lure_snake_lv1_trap":
    return {
        "id": "test_lure_snake_lv1_trap",
        "core_type": "viper_totem",
        "duration": 25.0,
        "units": [
            {"id": "lure_snake", "x": 0, "y": 1, "level": 1}
        ],
        "enemies": [
            {"type": "basic_enemy", "path": [{"x": 2, "y": 0}, {"x": 2, "y": 1}], "count": 3}
        ],
        "setup_actions": [
            {"type": "place_trap", "trap_id": "poison_trap", "position": {"x": 2, "y": 0}}
        ],
        "expected_behavior": "放置毒陷阱，敌人触发后受到伤害并中毒，敌人经过陷阱时受到伤害和中毒"
    }
```

**验证指标**:
- [ ] 可放置1个毒陷阱
- [ ] 陷阱触发时敌人受到伤害
- [ ] 陷阱触发时敌人获得中毒

### 测试场景 2: Lv2 陷阱数量提升验证

```gdscript
"test_lure_snake_lv2_trap":
    return {
        "id": "test_lure_snake_lv2_trap",
        "core_type": "viper_totem",
        "duration": 25.0,
        "units": [
            {"id": "lure_snake", "x": 0, "y": 1, "level": 2}
        ],
        "enemies": [
            {"type": "basic_enemy", "path": [{"x": 2, "y": 0}, {"x": 2, "y": 1}], "count": 3}
        ],
        "setup_actions": [
            {"type": "place_trap", "trap_id": "poison_trap", "position": {"x": 2, "y": 0}},
            {"type": "place_trap", "trap_id": "poison_trap", "position": {"x": 2, "y": 1}}
        ],
        "expected_behavior": "可放置2个毒陷阱"
    }
```

**验证指标**:
- [ ] 可放置2个毒陷阱

### 测试场景 3: Lv3 额外伤害验证

```gdscript
"test_lure_snake_lv3_damage":
    return {
        "id": "test_lure_snake_lv3_damage",
        "core_type": "viper_totem",
        "duration": 25.0,
        "units": [
            {"id": "lure_snake", "x": 0, "y": 1, "level": 3}
        ],
        "enemies": [
            {"type": "basic_enemy", "count": 3}
        ],
        "expected_behavior": "敌人获得Debuff：每0.5秒受到额外伤害，中毒敌人每0.5秒受到额外伤害"
    }
```

**验证指标**:
- [ ] 中毒敌人每0.5秒受到额外伤害
- [ ] 额外伤害数值正确

## 实现要求

1. **添加到 TestSuite.gd**: 在 `get_test_config` 函数的 match 语句中添加以上所有测试用例

2. **测试运行验证**: 每个测试用例必须能通过 Headless 模式运行：
   ```bash
   godot --path . --headless -- --run-test=test_lure_snake_lv1_trap
   godot --path . --headless -- --run-test=test_lure_snake_lv2_trap
   godot --path . --headless -- --run-test=test_lure_snake_lv3_damage
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
   for test in test_lure_snake_lv1_trap test_lure_snake_lv2_trap test_lure_snake_lv3_damage; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```
5. 更新 `docs/test_progress.md` 中的测试进度

## 代码提交要求

1. 在独立分支上工作：`feature/TEST-VIPER-lure_snake`
2. 提交信息格式：`[TEST-VIPER-lure_snake] Add automated tests for Lure Snake unit`
3. 完成后创建 Pull Request 到 main 分支

## 进度同步

完成每个测试用例后，更新 `docs/progress.md`：

```markdown
| TEST-VIPER-lure_snake | in_progress | 添加诱捕蛇Lv1测试 | 2026-02-20T14:30:00 |
```

## 相关文档

- `docs/test_progress.md` - 详细测试场景规范
- `docs/roles/qa_engineer.md` - 测试工程师角色指南
- `src/Scripts/Tests/AutomatedTestRunner.gd` - 测试运行器
- `src/Scripts/Tests/TestSuite.gd` - 测试配置
- `data/game_data.json` - 单位数据配置
- `docs/jules_prompts/P1_02_viper_cobra_units.md` - 蟾蜍实现参考

## Task ID

Task being executed: TEST-VIPER-lure_snake
