# Jules 任务: 血法师自动化测试 (TEST-BAT-blood_mage)

## 任务ID
TEST-BAT-blood_mage

## 任务描述
为蝙蝠图腾流派单位"血法师"创建完整的自动化测试用例，验证其鲜血法球技能机制。

## 单位信息

| 属性 | 值 |
|------|-----|
| 单位ID | blood_mage |
| 名称 | 血法师 |
| 图标 | 🩸 |
| 派系 | bat_totem |
| 攻击类型 | ranged |
| 投射物 | magic_missile |
| 技能 | blood_pool |
| 技能类型 | point |
| 伤害类型 | magic |

**核心机制**: 召唤血池区域，敌人受伤友方回血

## 详细测试场景

### 测试场景 1: Lv1 血池召唤验证

```gdscript
"test_blood_mage_lv1_pool":
    return {
        "id": "test_blood_mage_lv1_pool",
        "core_type": "bat_totem",
        "duration": 20.0,
        "units": [
            {"id": "blood_mage", "x": 0, "y": 1, "level": 1}
        ],
        "enemies": [
            {"type": "basic_enemy", "count": 3, "positions": [{"x": 2, "y": 2}, {"x": 2, "y": 3}]}
        ],
        "scheduled_actions": [
            {"time": 5.0, "type": "skill", "source": "blood_mage", "target": {"x": 2, "y": 2}}
        ],
        "expected_behavior": "召唤1x1血池区域，区域内敌人每秒受到dot伤害"
    }
```

**验证指标**:
- [ ] 技能召唤1x1血池区域
- [ ] 区域内敌人每秒受到伤害
- [ ] 血池持续一定时间
- [ ] 技能CD 15秒生效

### 测试场景 2: Lv2 血池范围提升验证

```gdscript
"test_blood_mage_lv2_pool":
    return {
        "id": "test_blood_mage_lv2_pool",
        "core_type": "bat_totem",
        "duration": 25.0,
        "units": [
            {"id": "blood_mage", "x": 0, "y": 1, "level": 2}
        ],
        "enemies": [
            {"type": "basic_enemy", "count": 5, "positions": [{"x": 2, "y": 2}, {"x": 3, "y": 2}, {"x": 2, "y": 3}, {"x": 3, "y": 3}]}
        ],
        "scheduled_actions": [
            {"time": 5.0, "type": "skill", "source": "blood_mage", "target": {"x": 2, "y": 2}}
        ],
        "expected_behavior": "召唤2x2血池区域，更大范围内敌人受到伤害"
    }
```

**验证指标**:
- [ ] 血池范围为2x2
- [ ] 更大范围内敌人都受到伤害
- [ ] Lv2暴击率+10%

### 测试场景 3: Lv3 血池效果增强验证

```gdscript
"test_blood_mage_lv3_pool":
    return {
        "id": "test_blood_mage_lv3_pool",
        "core_type": "bat_totem",
        "duration": 25.0,
        "units": [
            {"id": "blood_mage", "x": 0, "y": 1, "level": 3}
        ],
        "enemies": [
            {"type": "basic_enemy", "count": 5, "positions": [{"x": 2, "y": 2}, {"x": 4, "y": 2}, {"x": 2, "y": 4}]}
        ],
        "scheduled_actions": [
            {"time": 5.0, "type": "skill", "source": "blood_mage", "target": {"x": 2, "y": 2}}
        ],
        "expected_behavior": "召唤3x3血池区域，效果+50%"
    }
```

**验证指标**:
- [ ] 血池范围为3x3
- [ ] 伤害效果+50%
- [ ] Lv3暴击率+20%

### 测试场景 4: 友方回血验证

```gdscript
"test_blood_mage_heal":
    return {
        "id": "test_blood_mage_heal",
        "core_type": "bat_totem",
        "duration": 25.0,
        "core_health": 300,
        "max_core_health": 500,
        "units": [
            {"id": "blood_mage", "x": 0, "y": 1, "level": 3},
            {"id": "squirrel", "x": 2, "y": 2, "hp": 50, "max_hp": 100}
        ],
        "enemies": [
            {"type": "basic_enemy", "count": 3, "positions": [{"x": 2, "y": 2}]}
        ],
        "scheduled_actions": [
            {"time": 5.0, "type": "skill", "source": "blood_mage", "target": {"x": 2, "y": 2}},
            {"time": 10.0, "type": "verify_hp", "unit_id": "squirrel", "expected_hp_percent": 0.8}
        ],
        "expected_behavior": "血池内友方单位回血，核心也会回血"
    }
```

**验证指标**:
- [ ] 血池内友方单位回血
- [ ] 核心血量增加
- [ ] 回血效率随等级提升

## 实现要求

1. **添加到 TestSuite.gd**: 在 `get_test_config` 函数的 match 语句中添加以上所有测试用例

2. **测试运行验证**: 每个测试用例必须能通过 Headless 模式运行：
   ```bash
   godot --path . --headless -- --run-test=test_blood_mage_lv1_pool
   godot --path . --headless -- --run-test=test_blood_mage_lv2_pool
   godot --path . --headless -- --run-test=test_blood_mage_lv3_pool
   godot --path . --headless -- --run-test=test_blood_mage_heal
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
   for test in test_blood_mage_lv1_pool test_blood_mage_lv2_pool test_blood_mage_lv3_pool test_blood_mage_heal; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```
5. 更新 `docs/test_progress.md` 中的测试进度

## 代码提交要求

1. 在独立分支上工作：`feature/TEST-BAT-blood_mage`
2. 提交信息格式：`[TEST-BAT-blood_mage] Add automated tests for Blood Mage unit`
3. 完成后创建 Pull Request 到 main 分支

## 进度同步

完成每个测试用例后，更新 `docs/progress.md`：

```markdown
| TEST-BAT-blood_mage | in_progress | 添加血法师Lv1测试 | 2026-02-20T14:30:00 |
```

## 相关文档

- `docs/test_progress.md` - 详细测试场景规范
- `docs/roles/qa_engineer.md` - 测试工程师角色指南
- `src/Scripts/Tests/AutomatedTestRunner.gd` - 测试运行器
- `src/Scripts/Tests/TestSuite.gd` - 测试配置
- `data/game_data.json` - 单位数据配置

## Task ID

Task being executed: TEST-BAT-blood_mage
