# Jules 任务: 血祖自动化测试 (TEST-BAT-blood_ancestor)

## 任务ID
TEST-BAT-blood_ancestor

## 任务描述
为蝙蝠图腾流派单位"血祖"创建完整的自动化测试用例，验证其血池技能和鲜血领域机制。

## 单位信息

| 属性 | 值 |
|------|-----|
| 单位ID | blood_ancestor |
| 名称 | 血祖 |
| 图标 | 👑 |
| 派系 | bat_totem |
| 攻击类型 | ranged |
| 投射物 | magic_missile |
| 伤害类型 | magic |

**核心机制**: 场上每有1个受伤敌人，自身攻击+10%且吸血+20%

## 详细测试场景

### 测试场景 1: Lv1 鲜血领域基础验证

```gdscript
"test_blood_ancestor_lv1_domain":
    return {
        "id": "test_blood_ancestor_lv1_domain",
        "core_type": "bat_totem",
        "duration": 20.0,
        "units": [
            {"id": "blood_ancestor", "x": 0, "y": 1, "level": 1}
        ],
        "enemies": [
            {"type": "basic_enemy", "hp": 50, "count": 3}
        ],
        "scheduled_actions": [
            {"time": 2.0, "type": "record_damage", "unit_id": "blood_ancestor", "label": "no_injured"},
            {"time": 5.0, "type": "damage_enemies", "amount": 30},
            {"time": 8.0, "type": "record_damage", "unit_id": "blood_ancestor", "label": "with_injured"}
        ],
        "expected_behavior": "场上每有1个受伤敌人，自身攻击+10%(上限30%)"
    }
```

**验证指标**:
- [ ] 无受伤敌人时基础攻击力
- [ ] 每有1个受伤敌人攻击力+10%
- [ ] 攻击力上限+30%(3个敌人)

### 测试场景 2: Lv2 加成上限提升验证

```gdscript
"test_blood_ancestor_lv2_domain":
    return {
        "id": "test_blood_ancestor_lv2_domain",
        "core_type": "bat_totem",
        "duration": 20.0,
        "units": [
            {"id": "blood_ancestor", "x": 0, "y": 1, "level": 2}
        ],
        "enemies": [
            {"type": "basic_enemy", "hp": 100, "count": 5}
        ],
        "scheduled_actions": [
            {"time": 5.0, "type": "damage_enemies", "amount": 50},
            {"time": 8.0, "type": "record_damage", "unit_id": "blood_ancestor", "label": "max_bonus"}
        ],
        "expected_behavior": "场上每有1个受伤敌人，自身攻击+15%"
    }
```

**验证指标**:
- [ ] 每有1个受伤敌人攻击力+15%
- [ ] Lv2暴击率+10%

### 测试场景 3: Lv3 吸血加成验证

```gdscript
"test_blood_ancestor_lv3_lifesteal":
    return {
        "id": "test_blood_ancestor_lv3_lifesteal",
        "core_type": "bat_totem",
        "duration": 25.0,
        "units": [
            {"id": "blood_ancestor", "x": 0, "y": 1, "level": 3}
        ],
        "enemies": [
            {"type": "basic_enemy", "hp": 100, "count": 3}
        ],
        "scheduled_actions": [
            {"time": 5.0, "type": "damage_enemies", "amount": 50},
            {"time": 8.0, "type": "record_lifesteal", "source_unit_id": "blood_ancestor", "label": "with_lifesteal_bonus"}
        ],
        "expected_behavior": "场上每有1个受伤敌人，自身攻击+20%且吸血+20%"
    }
```

**验证指标**:
- [ ] 每有1个受伤敌人攻击力+20%
- [ ] 每有1个受伤敌人吸血+20%
- [ ] Lv3暴击率+20%

### 测试场景 4: 实时更新验证

```gdscript
"test_blood_ancestor_realtime_update":
    return {
        "id": "test_blood_ancestor_realtime_update",
        "core_type": "bat_totem",
        "duration": 30.0,
        "units": [
            {"id": "blood_ancestor", "x": 0, "y": 1, "level": 3}
        ],
        "enemies": [
            {"type": "basic_enemy", "hp": 100, "count": 3}
        ],
        "scheduled_actions": [
            {"time": 2.0, "type": "record_damage", "unit_id": "blood_ancestor", "label": "initial"},
            {"time": 5.0, "type": "damage_enemies", "amount": 50},
            {"time": 8.0, "type": "record_damage", "unit_id": "blood_ancestor", "label": "enemies_injured"},
            {"time": 12.0, "type": "kill_enemies", "count": 2},
            {"time": 15.0, "type": "record_damage", "unit_id": "blood_ancestor", "label": "enemies_killed"}
        ],
        "expected_behavior": "加成随受伤敌人数量实时变化"
    }
```

**验证指标**:
- [ ] 敌人受伤时加成增加
- [ ] 敌人死亡时加成减少
- [ ] 加成实时更新无延迟

### 测试场景 5: 多敌人上限验证

```gdscript
"test_blood_ancestor_max_bonus":
    return {
        "id": "test_blood_ancestor_max_bonus",
        "core_type": "bat_totem",
        "duration": 20.0,
        "units": [
            {"id": "blood_ancestor", "x": 0, "y": 1, "level": 3}
        ],
        "enemies": [
            {"type": "basic_enemy", "hp": 200, "count": 10}
        ],
        "scheduled_actions": [
            {"time": 5.0, "type": "damage_enemies", "amount": 100},
            {"time": 8.0, "type": "record_damage", "unit_id": "blood_ancestor", "label": "max_bonus_check"}
        ],
        "expected_behavior": "即使有更多受伤敌人，加成也有上限"
    }
```

**验证指标**:
- [ ] 超过上限数量的敌人不增加额外加成
- [ ] 加成保持在最大值

## 实现要求

1. **添加到 TestSuite.gd**: 在 `get_test_config` 函数的 match 语句中添加以上所有测试用例

2. **测试运行验证**: 每个测试用例必须能通过 Headless 模式运行：
   ```bash
   godot --path . --headless -- --run-test=test_blood_ancestor_lv1_domain
   godot --path . --headless -- --run-test=test_blood_ancestor_lv2_domain
   godot --path . --headless -- --run-test=test_blood_ancestor_lv3_lifesteal
   godot --path . --headless -- --run-test=test_blood_ancestor_realtime_update
   godot --path . --headless -- --run-test=test_blood_ancestor_max_bonus
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
3. 在 TestSuite.gd 中添加以上 5 个测试用例
4. 运行测试验证：
   ```bash
   for test in test_blood_ancestor_lv1_domain test_blood_ancestor_lv2_domain test_blood_ancestor_lv3_lifesteal test_blood_ancestor_realtime_update test_blood_ancestor_max_bonus; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```
5. 更新 `docs/test_progress.md` 中的测试进度

## 代码提交要求

1. 在独立分支上工作：`feature/TEST-BAT-blood_ancestor`
2. 提交信息格式：`[TEST-BAT-blood_ancestor] Add automated tests for Blood Ancestor unit`
3. 完成后创建 Pull Request 到 main 分支

## 进度同步

完成每个测试用例后，更新 `docs/progress.md`：

```markdown
| TEST-BAT-blood_ancestor | in_progress | 添加血祖Lv1测试 | 2026-02-20T14:30:00 |
```

## 相关文档

- `docs/test_progress.md` - 详细测试场景规范
- `docs/roles/qa_engineer.md` - 测试工程师角色指南
- `src/Scripts/Tests/AutomatedTestRunner.gd` - 测试运行器
- `src/Scripts/Tests/TestSuite.gd` - 测试配置
- `data/game_data.json` - 单位数据配置

## Task ID

Task being executed: TEST-BAT-blood_ancestor
