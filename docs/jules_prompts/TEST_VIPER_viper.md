# Jules 任务: 蝰蛇自动化测试 (TEST-VIPER-viper)

## 任务ID
TEST-VIPER-viper

## 任务描述
为眼镜蛇图腾流派单位"蝰蛇"创建完整的自动化测试用例，验证其中毒Buff赋予机制。

## 单位信息

| 属性 | 值 |
|------|-----|
| 单位ID | viper |
| 名称 | 蝰蛇 |
| 图标 | 🐍 |
| 派系 | viper_totem |
| 攻击类型 | buff |
| 特性 | poison_buff |

**核心机制**: 赋予友方单位中毒Buff，使其攻击附加中毒层数

## 详细测试场景

### 测试场景 1: Lv1 中毒Buff验证

```gdscript
"test_viper_lv1_poison":
    return {
        "id": "test_viper_lv1_poison",
        "core_type": "viper_totem",
        "duration": 20.0,
        "units": [
            {"id": "viper", "x": 0, "y": 1, "level": 1},
            {"id": "squirrel", "x": 1, "y": 0}
        ],
        "setup_actions": [
            {"type": "apply_buff", "buff_id": "poison", "target_unit_id": "squirrel"}
        ],
        "enemies": [
            {"type": "basic_enemy", "count": 3}
        ],
        "expected_behavior": "赋予中毒Buff，攻击附加2层中毒，松鼠攻击使敌人叠加2层中毒"
    }
```

**验证指标**:
- [ ] 可赋予1个单位中毒Buff
- [ ] 攻击附加2层中毒

### 测试场景 2: Lv2 中毒层数提升验证

```gdscript
"test_viper_lv2_poison":
    return {
        "id": "test_viper_lv2_poison",
        "core_type": "viper_totem",
        "duration": 20.0,
        "units": [
            {"id": "viper", "x": 0, "y": 1, "level": 2},
            {"id": "squirrel", "x": 1, "y": 0}
        ],
        "setup_actions": [
            {"type": "apply_buff", "buff_id": "poison", "target_unit_id": "squirrel"}
        ],
        "enemies": [
            {"type": "basic_enemy", "count": 3}
        ],
        "expected_behavior": "攻击附加3层中毒"
    }
```

**验证指标**:
- [ ] 攻击附加3层中毒

### 测试场景 3: Lv3 双目标验证

```gdscript
"test_viper_lv3_poison":
    return {
        "id": "test_viper_lv3_poison",
        "core_type": "viper_totem",
        "duration": 20.0,
        "units": [
            {"id": "viper", "x": 0, "y": 1, "level": 3},
            {"id": "squirrel", "x": 1, "y": 0},
            {"id": "wolf", "x": -1, "y": 0}
        ],
        "setup_actions": [
            {"type": "apply_buff", "buff_id": "poison", "target_unit_id": "squirrel"},
            {"type": "apply_buff", "buff_id": "poison", "target_unit_id": "wolf"}
        ],
        "enemies": [
            {"type": "basic_enemy", "count": 3}
        ],
        "expected_behavior": "可赋予2个单位中毒Buff"
    }
```

**验证指标**:
- [ ] 可赋予2个单位中毒Buff

## 实现要求

1. **添加到 TestSuite.gd**: 在 `get_test_config` 函数的 match 语句中添加以上所有测试用例

2. **测试运行验证**: 每个测试用例必须能通过 Headless 模式运行：
   ```bash
   godot --path . --headless -- --run-test=test_viper_lv1_poison
   godot --path . --headless -- --run-test=test_viper_lv2_poison
   godot --path . --headless -- --run-test=test_viper_lv3_poison
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
   for test in test_viper_lv1_poison test_viper_lv2_poison test_viper_lv3_poison; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```
5. 更新 `docs/test_progress.md` 中的测试进度

## 代码提交要求

1. 在独立分支上工作：`feature/TEST-VIPER-viper`
2. 提交信息格式：`[TEST-VIPER-viper] Add automated tests for Viper unit`
3. 完成后创建 Pull Request 到 main 分支

## 进度同步

完成每个测试用例后，更新 `docs/progress.md`：

```markdown
| TEST-VIPER-viper | in_progress | 添加蝰蛇Lv1测试 | 2026-02-20T14:30:00 |
```

## 相关文档

- `docs/test_progress.md` - 详细测试场景规范
- `docs/roles/qa_engineer.md` - 测试工程师角色指南
- `src/Scripts/Tests/AutomatedTestRunner.gd` - 测试运行器
- `src/Scripts/Tests/TestSuite.gd` - 测试配置
- `data/game_data.json` - 单位数据配置

## Task ID

Task being executed: TEST-VIPER-viper
