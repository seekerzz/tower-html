# Jules 任务: 老鼠自动化测试 (TEST-VIPER-rat)

## 任务ID
TEST-VIPER-rat

## 任务描述
为眼镜蛇图腾流派单位"老鼠"创建完整的自动化测试用例，验证其瘟疫传播机制和Lv3多Debuff传播机制。

## 单位信息

| 属性 | 值 |
|------|-----|
| 单位ID | rat |
| 名称 | 老鼠 |
| 图标 | 🐀 |
| 派系 | viper_totem |
| 攻击类型 | melee |
| 特性 | plague_spread, multi_debuff |

**核心机制**: 命中敌人在4秒内死亡时传播毒素，Lv3额外传播其他Debuff

## 详细测试场景

### 测试场景 1: Lv1 瘟疫传播验证

```gdscript
"test_rat_lv1_plague":
    return {
        "id": "test_rat_lv1_plague",
        "core_type": "viper_totem",
        "duration": 30.0,
        "units": [
            {"id": "rat", "x": 0, "y": 1, "level": 1}
        ],
        "enemies": [
            {"type": "low_hp_enemy", "hp": 30, "count": 3}
        ],
        "expected_behavior": "命中敌人在4秒内死亡时传递2层毒给周围敌人，被老鼠攻击的敌人在4秒内死亡时，周围敌人获得2层中毒"
    }
```

**验证指标**:
- [ ] 4秒内死亡的敌人触发传播
- [ ] 传递2层中毒给周围敌人

### 测试场景 2: Lv2 传播效果提升验证

```gdscript
"test_rat_lv2_plague":
    return {
        "id": "test_rat_lv2_plague",
        "core_type": "viper_totem",
        "duration": 30.0,
        "units": [
            {"id": "rat", "x": 0, "y": 1, "level": 2}
        ],
        "enemies": [
            {"type": "low_hp_enemy", "hp": 30, "count": 3}
        ],
        "expected_behavior": "传播层数或范围提升，传递4层中毒给周围敌人"
    }
```

**验证指标**:
- [ ] 传播层数或范围提升

### 测试场景 3: Lv3 多Debuff传播验证

```gdscript
"test_rat_lv3_multi_debuff":
    return {
        "id": "test_rat_lv3_multi_debuff",
        "core_type": "viper_totem",
        "duration": 30.0,
        "units": [
            {"id": "rat", "x": 0, "y": 1, "level": 3}
        ],
        "enemies": [
            {"type": "low_hp_enemy", "hp": 30, "debuffs": [{"type": "poison", "stacks": 3}, {"type": "burn", "stacks": 2}], "count": 3}
        ],
        "expected_behavior": "传递时额外增加其他Debuff，传播时不仅传递中毒，还传递其他Debuff"
    }
```

**验证指标**:
- [ ] 传播时传递多种Debuff
- [ ] 包括中毒以外的Debuff

## 实现要求

1. **添加到 TestSuite.gd**: 在 `get_test_config` 函数的 match 语句中添加以上所有测试用例

2. **测试运行验证**: 每个测试用例必须能通过 Headless 模式运行：
   ```bash
   godot --path . --headless -- --run-test=test_rat_lv1_plague
   godot --path . --headless -- --run-test=test_rat_lv2_plague
   godot --path . --headless -- --run-test=test_rat_lv3_multi_debuff
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
   for test in test_rat_lv1_plague test_rat_lv2_plague test_rat_lv3_multi_debuff; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```
5. 更新 `docs/test_progress.md` 中的测试进度

## 代码提交要求

1. 在独立分支上工作：`feature/TEST-VIPER-rat`
2. 提交信息格式：`[TEST-VIPER-rat] Add automated tests for Rat unit`
3. 完成后创建 Pull Request 到 main 分支

## 进度同步

完成每个测试用例后，更新 `docs/progress.md`：

```markdown
| TEST-VIPER-rat | in_progress | 添加老鼠Lv1测试 | 2026-02-20T14:30:00 |
```

## 相关文档

- `docs/test_progress.md` - 详细测试场景规范
- `docs/roles/qa_engineer.md` - 测试工程师角色指南
- `src/Scripts/Tests/AutomatedTestRunner.gd` - 测试运行器
- `src/Scripts/Tests/TestSuite.gd` - 测试配置
- `data/game_data.json` - 单位数据配置
- `docs/jules_prompts/P1_02_viper_cobra_units.md` - 老鼠实现参考

## Task ID

Task being executed: TEST-VIPER-rat
