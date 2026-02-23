# Jules 任务: 牛图腾单位自动化测试 (Batch 1)

## 任务ID
TEST-COW-01

## 任务描述
为牛图腾流派的9个单位创建完整的自动化测试用例，添加到 `src/Scripts/Tests/TestSuite.gd`，并确保所有测试能在Headless模式下通过。

## 测试范围

### 需要测试的单位 (9个)

| 单位ID | 名称 | 核心机制 | 优先级 |
|--------|------|----------|--------|
| yak_guardian | 牦牛守护 | 嘲讽/守护领域 | P0 |
| iron_turtle | 铁甲龟 | 固定减伤 | P0 |
| hedgehog | 刺猬 | 伤害反弹 | P0 |
| cow_golem | 牛魔像 | 怒火中烧（受击叠攻击） | P0 |
| rock_armor_cow | 岩甲牛 | 脱战护盾 | P0 |
| mushroom_healer | 菌菇治愈者 | 孢子护盾 | P0 |
| cow | 奶牛 | 产奶回血 | P1 |
| plant | 树苗 | 成长机制 | P1 |
| ascetic | 苦修者 | 挨打叠攻击 | P1 |

## 详细测试场景

### 1. 牦牛守护 (yak_guardian)

**Lv1 嘲讽机制验证**:
```gdscript
"test_yak_guardian_lv1_taunt":
    return {
        "id": "test_yak_guardian_lv1_taunt",
        "core_type": "cow_totem",
        "duration": 15.0,
        "units": [
            {"id": "squirrel", "x": 0, "y": -1},
            {"id": "yak_guardian", "x": 0, "y": 1, "level": 1}
        ],
        "enemies": [
            {"type": "basic_enemy", "count": 3, "spawn_delay": 1.0}
        ],
        "expected_behavior": "敌人初始攻击松鼠，5秒后转为攻击牦牛守护"
    }
```

**Lv2 嘲讽频率提升**:
```gdscript
"test_yak_guardian_lv2_taunt":
    return {
        "id": "test_yak_guardian_lv2_taunt",
        "core_type": "cow_totem",
        "duration": 12.0,
        "units": [
            {"id": "squirrel", "x": 0, "y": -1},
            {"id": "yak_guardian", "x": 0, "y": 1, "level": 2}
        ],
        "expected_behavior": "嘲讽间隔为4秒，Buff提供10%减伤"
    }
```

### 2. 铁甲龟 (iron_turtle)

**Lv1 固定减伤验证**:
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
```

### 3. 刺猬 (hedgehog)

**Lv1 反弹概率验证**:
```gdscript
"test_hedgehog_lv1_reflect":
    return {
        "id": "test_hedgehog_lv1_reflect",
        "core_type": "cow_totem",
        "duration": 30.0,
        "units": [
            {"id": "hedgehog", "x": 0, "y": 1, "level": 1}
        ],
        "enemies": [
            {"type": "attacker_enemy", "attack_damage": 20, "count": 5}
        ],
        "expected_behavior": "30%概率反弹伤害，反弹伤害等于敌人造成的伤害"
    }
```

### 4. 牛魔像 (cow_golem)

**Lv1 怒火中烧验证**:
```gdscript
"test_cow_golem_lv1_rage":
    return {
        "id": "test_cow_golem_lv1_rage",
        "core_type": "cow_totem",
        "duration": 25.0,
        "units": [
            {"id": "cow_golem", "x": 0, "y": 1, "level": 1}
        ],
        "enemies": [
            {"type": "attacker_enemy", "attack_damage": 10, "attack_speed": 2.0, "count": 1}
        ],
        "expected_behavior": "每次受击攻击力+3%，上限30%(10层)"
    }
```

### 5. 岩甲牛 (rock_armor_cow)

**Lv1 脱战护盾验证**:
```gdscript
"test_rock_armor_cow_lv1_shield":
    return {
        "id": "test_rock_armor_cow_lv1_shield",
        "core_type": "cow_totem",
        "duration": 20.0,
        "units": [
            {"id": "rock_armor_cow", "x": 0, "y": 1, "level": 1}
        ],
        "expected_behavior": "脱战5秒后生成10%最大HP的护盾"
    }
```

### 6. 菌菇治愈者 (mushroom_healer)

**Lv1 孢子护盾验证**:
```gdscript
"test_mushroom_healer_lv1_spores":
    return {
        "id": "test_mushroom_healer_lv1_spores",
        "core_type": "cow_totem",
        "duration": 20.0,
        "units": [
            {"id": "mushroom_healer", "x": 0, "y": 1, "level": 1},
            {"id": "squirrel", "x": 1, "y": 0}
        ],
        "enemies": [
            {"type": "basic_enemy", "count": 3}
        ],
        "expected_behavior": "为周围友方添加孢子Buff，抵消1次伤害并使敌人叠加3层中毒"
    }
```

### 7-9. 其他单位基础测试

为 cow, plant, ascetic 创建基础测试用例，验证它们能正常放置和攻击：

```gdscript
"test_cow_totem_cow":
    return {
        "id": "test_cow_totem_cow",
        "core_type": "cow_totem",
        "duration": 15.0,
        "units": [{"id": "cow", "x": 0, "y": 1}]
    }

"test_cow_totem_plant":
    return {
        "id": "test_cow_totem_plant",
        "core_type": "cow_totem",
        "duration": 15.0,
        "units": [{"id": "plant", "x": 0, "y": 1}]
    }

"test_cow_totem_ascetic":
    return {
        "id": "test_cow_totem_ascetic",
        "core_type": "cow_totem",
        "duration": 15.0,
        "units": [{"id": "ascetic", "x": 0, "y": 1}]
    }
```

## 实现要求

1. **添加到 TestSuite.gd**: 在 `get_test_config` 函数的 match 语句中添加以上所有测试用例

2. **测试运行验证**: 每个测试用例必须能通过 Headless 模式运行：
   ```bash
   godot --path . --headless -- --run-test=test_yak_guardian_lv1_taunt
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
3. 在 TestSuite.gd 中添加以上 11 个测试用例
4. 运行测试验证：
   ```bash
   # 验证所有牛图腾测试
   for test in test_yak_guardian_lv1_taunt test_yak_guardian_lv2_taunt test_iron_turtle_lv1_reduction test_hedgehog_lv1_reflect test_cow_golem_lv1_rage test_rock_armor_cow_lv1_shield test_mushroom_healer_lv1_spores test_cow_totem_cow test_cow_totem_plant test_cow_totem_ascetic; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```
5. 更新 `docs/test_progress.md` 中的测试进度

## 代码提交要求

1. 在独立分支上工作：`feature/TEST-COW-01-unit-tests`
2. 提交信息格式：`[TEST-COW-01] Add automated tests for Cow Totem units`
3. 完成后创建 Pull Request 到 main 分支

## 进度同步

完成每个测试用例后，更新 `docs/progress.md`：

```markdown
| TEST-COW-01 | in_progress | 添加牦牛守护测试 | 2026-02-20T14:30:00 |
```

## 相关文档

- `docs/test_progress.md` - 详细测试场景规范
- `docs/roles/qa_engineer.md` - 测试工程师角色指南
- `src/Scripts/Tests/AutomatedTestRunner.gd` - 测试运行器
- `src/Scripts/Tests/TestSuite.gd` - 测试配置

## Task ID

Task being executed: TEST-COW-01
