# Jules 任务: 吸血蝠自动化测试 (TEST-BAT-vampire_bat)

## 任务ID
TEST-BAT-vampire_bat

## 任务描述
为蝙蝠图腾流派单位"吸血蝠"创建完整的自动化测试用例，验证其流血层数增伤机制和生命越低吸血越高机制。

## 单位信息

| 属性 | 值 |
|------|-----|
| 单位ID | vampire_bat |
| 名称 | 吸血蝠 |
| 图标 | 🦇 |
| 派系 | bat_totem |
| 攻击类型 | melee |
| 伤害类型 | physical |

**核心机制**: 流血层数增伤，生命值越低吸血越高

## 详细测试场景

### 测试场景 1: Lv1 鲜血狂噬基础验证

```gdscript
"test_vampire_bat_lv1_lifesteal":
    return {
        "id": "test_vampire_bat_lv1_lifesteal",
        "core_type": "bat_totem",
        "duration": 20.0,
        "units": [
            {"id": "vampire_bat", "x": 0, "y": 1, "level": 1, "hp": 200, "max_hp": 200}
        ],
        "enemies": [
            {"type": "basic_enemy", "count": 5, "hp": 100}
        ],
        "scheduled_actions": [
            {"time": 2.0, "type": "record_lifesteal", "source_unit_id": "vampire_bat", "label": "full_hp"},
            {"time": 5.0, "type": "damage_unit", "unit_id": "vampire_bat", "amount": 150},
            {"time": 8.0, "type": "record_lifesteal", "source_unit_id": "vampire_bat", "label": "low_hp"}
        ],
        "expected_behavior": "生命值越低吸血越高，最低生命时+50%吸血"
    }
```

**验证指标**:
- [ ] 满血时基础吸血为0%
- [ ] 低血量时吸血增加
- [ ] 最低生命值时吸血+50%

### 测试场景 2: Lv2 基础吸血提升验证

```gdscript
"test_vampire_bat_lv2_lifesteal":
    return {
        "id": "test_vampire_bat_lv2_lifesteal",
        "core_type": "bat_totem",
        "duration": 20.0,
        "units": [
            {"id": "vampire_bat", "x": 0, "y": 1, "level": 2, "hp": 300, "max_hp": 300}
        ],
        "enemies": [
            {"type": "basic_enemy", "count": 5, "hp": 100}
        ],
        "scheduled_actions": [
            {"time": 2.0, "type": "record_lifesteal", "source_unit_id": "vampire_bat", "label": "full_hp"}
        ],
        "expected_behavior": "基础吸血+20%，生命值越低吸血越高"
    }
```

**验证指标**:
- [ ] 满血时基础吸血为20%
- [ ] 低血量时吸血进一步增加
- [ ] 最低生命值时总吸血达70%

### 测试场景 3: Lv3 流血层数增伤验证

```gdscript
"test_vampire_bat_lv3_bleed_damage":
    return {
        "id": "test_vampire_bat_lv3_bleed_damage",
        "core_type": "bat_totem",
        "duration": 25.0,
        "units": [
            {"id": "vampire_bat", "x": 0, "y": 1, "level": 3}
        ],
        "enemies": [
            {"type": "basic_enemy", "count": 3, "hp": 150, "debuffs": [{"type": "bleed", "stacks": 1}]},
            {"type": "basic_enemy", "count": 2, "hp": 150, "debuffs": [{"type": "bleed", "stacks": 5}]}
        ],
        "scheduled_actions": [
            {"time": 2.0, "type": "record_damage", "unit_id": "vampire_bat", "label": "bleed_1"},
            {"time": 5.0, "type": "record_damage", "unit_id": "vampire_bat", "label": "bleed_5"}
        ],
        "expected_behavior": "根据敌人流血层数增加伤害，每层流血增加一定比例伤害"
    }
```

**验证指标**:
- [ ] 对流血层数高的敌人造成更高伤害
- [ ] 伤害随流血层数线性增加
- [ ] Lv3暴击率+10%

### 测试场景 4: 吸血上限验证

```gdscript
"test_vampire_bat_lifesteal_cap":
    return {
        "id": "test_vampire_bat_lifesteal_cap",
        "core_type": "bat_totem",
        "duration": 20.0,
        "units": [
            {"id": "vampire_bat", "x": 0, "y": 1, "level": 3, "hp": 10, "max_hp": 450}
        ],
        "enemies": [
            {"type": "basic_enemy", "count": 5, "hp": 100}
        ],
        "expected_behavior": "吸血总量不超过造成伤害的一定比例"
    }
```

**验证指标**:
- [ ] 吸血量有合理上限
- [ ] 吸血不会超过实际造成伤害

## 实现要求

1. **添加到 TestSuite.gd**: 在 `get_test_config` 函数的 match 语句中添加以上所有测试用例

2. **测试运行验证**: 每个测试用例必须能通过 Headless 模式运行：
   ```bash
   godot --path . --headless -- --run-test=test_vampire_bat_lv1_lifesteal
   godot --path . --headless -- --run-test=test_vampire_bat_lv2_lifesteal
   godot --path . --headless -- --run-test=test_vampire_bat_lv3_bleed_damage
   godot --path . --headless -- --run-test=test_vampire_bat_lifesteal_cap
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
3. 在 TestSuite.gd 中添加以上 4 个测试用例
4. 运行测试验证：
   ```bash
   for test in test_vampire_bat_lv1_lifesteal test_vampire_bat_lv2_lifesteal test_vampire_bat_lv3_bleed_damage test_vampire_bat_lifesteal_cap; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```
5. 更新 `docs/test_progress.md` 中的测试进度

## 代码提交要求

1. 在独立分支上工作：`feature/TEST-BAT-vampire_bat`
2. 提交信息格式：`[TEST-BAT-vampire_bat] Add automated tests for Vampire Bat unit`
3. 完成后创建 Pull Request 到 main 分支

## 进度同步

完成每个测试用例后，更新 `docs/progress.md`：

```markdown
| TEST-BAT-vampire_bat | in_progress | 添加吸血蝠Lv1测试 | 2026-02-20T14:30:00 |
```

## 相关文档

- `docs/test_progress.md` - 详细测试场景规范
- `docs/roles/qa_engineer.md` - 测试工程师角色指南
- `src/Scripts/Tests/AutomatedTestRunner.gd` - 测试运行器
- `src/Scripts/Tests/TestSuite.gd` - 测试配置
- `data/game_data.json` - 单位数据配置

## Task ID

Task being executed: TEST-BAT-vampire_bat
