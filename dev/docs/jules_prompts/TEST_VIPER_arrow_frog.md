# Jules 任务: 箭毒蛙自动化测试 (TEST-VIPER-arrow_frog)

## 任务ID
TEST-VIPER-arrow_frog

## 任务描述
为眼镜蛇图腾流派单位"箭毒蛙"创建完整的自动化测试用例，验证其斩杀低血量敌人机制和Lv3毒素传播机制。

## 单位信息

| 属性 | 值 |
|------|-----|
| 单位ID | arrow_frog |
| 名称 | 箭毒蛙 |
| 图标 | 🐸 |
| 派系 | viper_totem |
| 攻击类型 | ranged |
| 特性 | execute, poison_spread |

**核心机制**: 斩杀低血量中毒敌人，Lv3斩杀时传播中毒层数

## 详细测试场景

### 测试场景 1: Lv1 斩杀验证

```gdscript
"test_arrow_frog_lv1_execute":
    return {
        "id": "test_arrow_frog_lv1_execute",
        "core_type": "viper_totem",
        "duration": 20.0,
        "units": [
            {"id": "arrow_frog", "x": 0, "y": 1, "level": 1}
        ],
        "enemies": [
            {"type": "poisoned_enemy", "hp": 100, "debuffs": [{"type": "poison", "stacks": 10}], "count": 3}
        ],
        "expected_behavior": "若敌人HP<Debuff层数*200%，则引爆斩杀，10层中毒时，HP<2000的敌人被斩杀"
    }
```

**验证指标**:
- [ ] 斩杀条件: HP < 层数×200%
- [ ] 斩杀时引爆敌人
- [ ] 引爆造成伤害

### 测试场景 2: Lv2 斩杀伤害提升验证

```gdscript
"test_arrow_frog_lv2_execute":
    return {
        "id": "test_arrow_frog_lv2_execute",
        "core_type": "viper_totem",
        "duration": 20.0,
        "units": [
            {"id": "arrow_frog", "x": 0, "y": 1, "level": 2}
        ],
        "enemies": [
            {"type": "poisoned_enemy", "hp": 100, "debuffs": [{"type": "poison", "stacks": 10}], "count": 3}
        ],
        "expected_behavior": "引爆伤害提升至250%"
    }
```

**验证指标**:
- [ ] 引爆伤害提升至250%

### 测试场景 3: Lv3 传染引爆验证

```gdscript
"test_arrow_frog_lv3_spread":
    return {
        "id": "test_arrow_frog_lv3_spread",
        "core_type": "viper_totem",
        "duration": 25.0,
        "units": [
            {"id": "arrow_frog", "x": 0, "y": 1, "level": 3}
        ],
        "enemies": [
            {"type": "poisoned_enemy", "hp": 50, "debuffs": [{"type": "poison", "stacks": 5}], "count": 5, "positions": [{"x": 2, "y": 0}, {"x": 2, "y": 1}]}
        ],
        "expected_behavior": "斩杀时将中毒层数传播给周围敌人，敌人被斩杀时，周围敌人获得5层中毒"
    }
```

**验证指标**:
- [ ] 斩杀时传播中毒层数
- [ ] 传播给周围敌人

## 实现要求

1. **添加到 TestSuite.gd**: 在 `get_test_config` 函数的 match 语句中添加以上所有测试用例

2. **测试运行验证**: 每个测试用例必须能通过 Headless 模式运行：
   ```bash
   godot --path . --headless -- --run-test=test_arrow_frog_lv1_execute
   godot --path . --headless -- --run-test=test_arrow_frog_lv2_execute
   godot --path . --headless -- --run-test=test_arrow_frog_lv3_spread
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
   for test in test_arrow_frog_lv1_execute test_arrow_frog_lv2_execute test_arrow_frog_lv3_spread; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```
5. 更新 `docs/test_progress.md` 中的测试进度

## 代码提交要求

1. 在独立分支上工作：`feature/TEST-VIPER-arrow_frog`
2. 提交信息格式：`[TEST-VIPER-arrow_frog] Add automated tests for Arrow Frog unit`
3. 完成后创建 Pull Request 到 main 分支

## 进度同步

完成每个测试用例后，更新 `docs/progress.md`：

```markdown
| TEST-VIPER-arrow_frog | in_progress | 添加箭毒蛙Lv1测试 | 2026-02-20T14:30:00 |
```

## 相关文档

- `docs/test_progress.md` - 详细测试场景规范
- `docs/roles/qa_engineer.md` - 测试工程师角色指南
- `src/Scripts/Tests/AutomatedTestRunner.gd` - 测试运行器
- `src/Scripts/Tests/TestSuite.gd` - 测试配置
- `data/game_data.json` - 单位数据配置

## Task ID

Task being executed: TEST-VIPER-arrow_frog
