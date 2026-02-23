# Jules 任务: 鬣狗 (Hyena) 自动化测试

## 任务ID
TEST-WOLF-HYENA

## 任务描述
为狼图腾流派单位"鬣狗"创建完整的自动化测试用例，添加到 `src/Scripts/Tests/TestSuite.gd`，并确保所有测试能在Headless模式下通过。

## 单位信息

| 属性 | 值 |
|------|-----|
| 单位ID | hyena |
| 中文名 | 鬣狗 |
| 核心机制 | 助攻叠攻击 - 残血收割 |
| 图腾类型 | wolf_totem |

## 技能说明

| 等级 | 技能效果 |
|------|----------|
| Lv1 | 残血收割：攻击HP<30%敌人时额外附加1次20%伤害 |
| Lv2 | 残血收割：攻击HP<30%敌人时额外附加1次50%伤害 |
| Lv3 | 残血收割：攻击HP<30%敌人时额外附加2次50%伤害 |

## 详细测试场景

### 测试场景 1: Lv1 残血收割验证

**测试ID**: `test_hyena_lv1_execute`

**测试配置**:
```gdscript
"test_hyena_lv1_execute":
    return {
        "id": "test_hyena_lv1_execute",
        "core_type": "wolf_totem",
        "duration": 20.0,
        "units": [
            {"id": "hyena", "x": 0, "y": 1, "level": 1}
        ],
        "enemies": [
            {"type": "high_hp_enemy", "count": 2, "hp": 200}
        ],
        "scheduled_actions": [
            {"time": 2.0, "type": "damage_enemy", "enemy_index": 0, "amount": 150},
            {"time": 2.0, "type": "damage_enemy", "enemy_index": 1, "amount": 100},
            {"time": 5.0, "type": "record_damage", "enemy_index": 0},
            {"time": 5.0, "type": "record_damage", "enemy_index": 1}
        ],
        "expected_behavior": "攻击HP<30%敌人时额外附加1次20%伤害"
    }
```

**验证指标**:
- [ ] 敌人HP<30%时触发残血收割
- [ ] 额外附加1次20%伤害
- [ ] 敌人HP>=30%时不触发额外伤害

### 测试场景 2: Lv2 残血收割提升验证

**测试ID**: `test_hyena_lv2_execute`

**测试配置**:
```gdscript
"test_hyena_lv2_execute":
    return {
        "id": "test_hyena_lv2_execute",
        "core_type": "wolf_totem",
        "duration": 20.0,
        "units": [
            {"id": "hyena", "x": 0, "y": 1, "level": 2}
        ],
        "enemies": [
            {"type": "high_hp_enemy", "count": 1, "hp": 200}
        ],
        "scheduled_actions": [
            {"time": 2.0, "type": "damage_enemy", "enemy_index": 0, "amount": 150},
            {"time": 5.0, "type": "record_damage", "enemy_index": 0}
        ],
        "expected_behavior": "攻击HP<30%敌人时额外附加1次50%伤害"
    }
```

**验证指标**:
- [ ] 敌人HP<30%时触发残血收割
- [ ] 额外附加1次50%伤害（比Lv1更高）

### 测试场景 3: Lv3 双重残血收割验证

**测试ID**: `test_hyena_lv3_execute`

**测试配置**:
```gdscript
"test_hyena_lv3_execute":
    return {
        "id": "test_hyena_lv3_execute",
        "core_type": "wolf_totem",
        "duration": 20.0,
        "units": [
            {"id": "hyena", "x": 0, "y": 1, "level": 3}
        ],
        "enemies": [
            {"type": "high_hp_enemy", "count": 1, "hp": 300}
        ],
        "scheduled_actions": [
            {"time": 2.0, "type": "damage_enemy", "enemy_index": 0, "amount": 220},
            {"time": 5.0, "type": "record_damage", "enemy_index": 0}
        ],
        "expected_behavior": "攻击HP<30%敌人时额外附加2次50%伤害"
    }
```

**验证指标**:
- [ ] 敌人HP<30%时触发残血收割
- [ ] 额外附加2次50%伤害（共2次额外攻击）
- [ ] 总伤害显著高于Lv2

## 实现要求

1. **添加到 TestSuite.gd**: 在 `get_test_config` 函数的 match 语句中添加以上3个测试用例

2. **测试运行验证**: 每个测试用例必须能通过 Headless 模式运行：
   ```bash
   godot --path . --headless -- --run-test=test_hyena_lv1_execute
   godot --path . --headless -- --run-test=test_hyena_lv2_execute
   godot --path . --headless -- --run-test=test_hyena_lv3_execute
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
2. 阅读 `docs/GameDesign.md` 了解鬣狗详细设计
3. 在 TestSuite.gd 中添加以上3个测试用例
4. 运行测试验证：
   ```bash
   for test in test_hyena_lv1_execute test_hyena_lv2_execute test_hyena_lv3_execute; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```
5. 更新 `docs/test_progress.md` 中的测试进度（鬣狗部分需要新增）

## 代码提交要求

1. 在独立分支上工作：`feature/TEST-WOLF-HYENA`
2. 提交信息格式：`[TEST-WOLF-HYENA] Add automated tests for Hyena unit`
3. 完成后创建 Pull Request 到 main 分支

## 进度同步

完成每个测试用例后，更新 `docs/progress.md`：

```markdown
| TEST-WOLF-HYENA | in_progress | 添加鬣狗Lv1残血收割测试 | 2026-02-20T14:30:00 |
```

## 相关文档

- `docs/GameDesign.md` - 鬣狗单位设计文档
- `docs/roles/qa_engineer.md` - 测试工程师角色指南
- `src/Scripts/Tests/AutomatedTestRunner.gd` - 测试运行器
- `src/Scripts/Tests/TestSuite.gd` - 测试配置

## 注意事项

鬣狗(hyena)在 `docs/test_progress.md` 中尚未有详细测试场景，需要根据 `docs/GameDesign.md` 中的设计文档创建测试用例。

## Task ID

Task being executed: TEST-WOLF-HYENA
