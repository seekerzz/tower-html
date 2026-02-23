# Jules 任务: 美杜莎自动化测试 (TEST-VIPER-medusa)

## 任务ID
TEST-VIPER-medusa

## 任务描述
为眼镜蛇图腾流派单位"美杜莎"创建完整的自动化测试用例，验证其石化凝视机制和Lv3石块伤害机制。

## 单位信息

| 属性 | 值 |
|------|-----|
| 单位ID | medusa |
| 名称 | 美杜莎 |
| 图标 | 🧟‍♀️ |
| 派系 | viper_totem |
| 攻击类型 | ranged |
| 特性 | petrify, burst_damage |

**核心机制**: 周期性石化最近敌人，Lv3石化结束时造成敌人最大HP伤害

## 详细测试场景

### 测试场景 1: Lv1 石化验证

```gdscript
"test_medusa_lv1_petrify":
    return {
        "id": "test_medusa_lv1_petrify",
        "core_type": "viper_totem",
        "duration": 20.0,
        "units": [
            {"id": "medusa", "x": 0, "y": 1, "level": 1}
        ],
        "enemies": [
            {"type": "basic_enemy", "count": 3}
        ],
        "expected_behavior": "每5秒石化最近敌人1秒，石化时敌人变为石块"
    }
```

**验证指标**:
- [ ] 每5秒触发一次
- [ ] 石化最近的敌人
- [ ] 石化持续1秒
- [ ] 石化时敌人变为石块

### 测试场景 2: Lv2 石化时间提升验证

```gdscript
"test_medusa_lv2_petrify":
    return {
        "id": "test_medusa_lv2_petrify",
        "core_type": "viper_totem",
        "duration": 20.0,
        "units": [
            {"id": "medusa", "x": 0, "y": 1, "level": 2}
        ],
        "enemies": [
            {"type": "basic_enemy", "count": 3}
        ],
        "expected_behavior": "石化持续时间增加"
    }
```

**验证指标**:
- [ ] 石化持续时间增加

### 测试场景 3: Lv3 石块伤害验证

```gdscript
"test_medusa_lv3_damage":
    return {
        "id": "test_medusa_lv3_damage",
        "core_type": "viper_totem",
        "duration": 25.0,
        "units": [
            {"id": "medusa", "x": 0, "y": 1, "level": 3}
        ],
        "enemies": [
            {"type": "high_hp_enemy", "count": 1, "hp": 500}
        ],
        "expected_behavior": "石块额外造成敌人MaxHP的伤害，石化结束时石块对敌人造成500点伤害"
    }
```

**验证指标**:
- [ ] 石化结束时造成伤害
- [ ] 伤害等于敌人最大血量

## 实现要求

1. **添加到 TestSuite.gd**: 在 `get_test_config` 函数的 match 语句中添加以上所有测试用例

2. **测试运行验证**: 每个测试用例必须能通过 Headless 模式运行：
   ```bash
   godot --path . --headless -- --run-test=test_medusa_lv1_petrify
   godot --path . --headless -- --run-test=test_medusa_lv2_petrify
   godot --path . --headless -- --run-test=test_medusa_lv3_damage
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
   for test in test_medusa_lv1_petrify test_medusa_lv2_petrify test_medusa_lv3_damage; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```
5. 更新 `docs/test_progress.md` 中的测试进度

## 代码提交要求

1. 在独立分支上工作：`feature/TEST-VIPER-medusa`
2. 提交信息格式：`[TEST-VIPER-medusa] Add automated tests for Medusa unit`
3. 完成后创建 Pull Request 到 main 分支

## 进度同步

完成每个测试用例后，更新 `docs/progress.md`：

```markdown
| TEST-VIPER-medusa | in_progress | 添加美杜莎Lv1测试 | 2026-02-20T14:30:00 |
```

## 相关文档

- `docs/test_progress.md` - 详细测试场景规范
- `docs/roles/qa_engineer.md` - 测试工程师角色指南
- `src/Scripts/Tests/AutomatedTestRunner.gd` - 测试运行器
- `src/Scripts/Tests/TestSuite.gd` - 测试配置
- `data/game_data.json` - 单位数据配置
- `docs/jules_prompts/P2_04b_medusa_petrify_redesign.md` - 美杜莎 redesign 文档

## Task ID

Task being executed: TEST-VIPER-medusa
