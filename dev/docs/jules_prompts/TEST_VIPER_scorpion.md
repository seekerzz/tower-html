# Jules 任务: 蝎子自动化测试 (TEST-VIPER-scorpion)

## 任务ID
TEST-VIPER-scorpion

## 任务描述
为眼镜蛇图腾流派单位"蝎子"创建完整的自动化测试用例，验证其尖刺陷阱机制和Lv3流血Debuff机制。

## 单位信息

| 属性 | 值 |
|------|-----|
| 单位ID | scorpion |
| 名称 | 蝎子 |
| 图标 | 🦂 |
| 派系 | viper_totem |
| 攻击类型 | trap |
| 特性 | armor_break, bleed |

**核心机制**: 放置尖刺陷阱造成范围破甲，Lv3附加流血Debuff

## 详细测试场景

### 测试场景 1: Lv1 尖刺陷阱验证

```gdscript
"test_scorpion_lv1_spike":
    return {
        "id": "test_scorpion_lv1_spike",
        "core_type": "viper_totem",
        "duration": 20.0,
        "units": [
            {"id": "scorpion", "x": 0, "y": 1, "level": 1}
        ],
        "enemies": [
            {"type": "basic_enemy", "path": [{"x": 2, "y": 0}], "count": 3}
        ],
        "setup_actions": [
            {"type": "place_trap", "trap_id": "spike_trap", "position": {"x": 2, "y": 0}}
        ],
        "expected_behavior": "尖刺陷阱：敌人经过时受到伤害"
    }
```

**验证指标**:
- [ ] 陷阱触发时造成伤害
- [ ] 伤害数值正确

### 测试场景 2: Lv2 倒钩伤害验证

```gdscript
"test_scorpion_lv2_spike":
    return {
        "id": "test_scorpion_lv2_spike",
        "core_type": "viper_totem",
        "duration": 20.0,
        "units": [
            {"id": "scorpion", "x": 0, "y": 1, "level": 2}
        ],
        "enemies": [
            {"type": "basic_enemy", "path": [{"x": 2, "y": 0}], "count": 3}
        ],
        "setup_actions": [
            {"type": "place_trap", "trap_id": "spike_trap", "position": {"x": 2, "y": 0}}
        ],
        "expected_behavior": "陷阱伤害提升"
    }
```

**验证指标**:
- [ ] 陷阱伤害提升

### 测试场景 3: Lv3 流血Debuff验证

```gdscript
"test_scorpion_lv3_bleed":
    return {
        "id": "test_scorpion_lv3_bleed",
        "core_type": "viper_totem",
        "duration": 25.0,
        "units": [
            {"id": "scorpion", "x": 0, "y": 1, "level": 3}
        ],
        "enemies": [
            {"type": "basic_enemy", "path": [{"x": 2, "y": 0}], "count": 3}
        ],
        "expected_behavior": "经过时叠加一层流血Debuff，敌人经过陷阱时获得1层流血"
    }
```

**验证指标**:
- [ ] 陷阱触发时叠加流血
- [ ] 流血层数为1层

## 实现要求

1. **添加到 TestSuite.gd**: 在 `get_test_config` 函数的 match 语句中添加以上所有测试用例

2. **测试运行验证**: 每个测试用例必须能通过 Headless 模式运行：
   ```bash
   godot --path . --headless -- --run-test=test_scorpion_lv1_spike
   godot --path . --headless -- --run-test=test_scorpion_lv2_spike
   godot --path . --headless -- --run-test=test_scorpion_lv3_bleed
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
   for test in test_scorpion_lv1_spike test_scorpion_lv2_spike test_scorpion_lv3_bleed; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```
5. 更新 `docs/test_progress.md` 中的测试进度

## 代码提交要求

1. 在独立分支上工作：`feature/TEST-VIPER-scorpion`
2. 提交信息格式：`[TEST-VIPER-scorpion] Add automated tests for Scorpion unit`
3. 完成后创建 Pull Request 到 main 分支

## 进度同步

完成每个测试用例后，更新 `docs/progress.md`：

```markdown
| TEST-VIPER-scorpion | in_progress | 添加蝎子Lv1测试 | 2026-02-20T14:30:00 |
```

## 相关文档

- `docs/test_progress.md` - 详细测试场景规范
- `docs/roles/qa_engineer.md` - 测试工程师角色指南
- `src/Scripts/Tests/AutomatedTestRunner.gd` - 测试运行器
- `src/Scripts/Tests/TestSuite.gd` - 测试配置
- `data/game_data.json` - 单位数据配置

## Task ID

Task being executed: TEST-VIPER-scorpion
