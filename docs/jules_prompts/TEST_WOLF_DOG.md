# Jules 任务: 恶霸犬 (Dog) 自动化测试

## 任务ID
TEST-WOLF-DOG

## 任务描述
为狼图腾流派单位"恶霸犬"创建完整的自动化测试用例，添加到 `src/Scripts/Tests/TestSuite.gd`，并确保所有测试能在Headless模式下通过。

## 单位信息

| 属性 | 值 |
|------|-----|
| 单位ID | dog |
| 中文名 | 恶霸犬 |
| 核心机制 | 狂暴 - 核心血量越低攻速越快 |
| 图腾类型 | wolf_totem |

## 详细测试场景

### 测试场景 1: Lv1 狂暴验证

**测试ID**: `test_dog_lv1_rampage`

**测试配置**:
```gdscript
"test_dog_lv1_rampage":
    return {
        "id": "test_dog_lv1_rampage",
        "core_type": "wolf_totem",
        "duration": 30.0,
        "core_health": 500,
        "max_core_health": 500,
        "units": [
            {"id": "dog", "x": 0, "y": 1, "level": 1}
        ],
        "scheduled_actions": [
            {"time": 2.0, "type": "record_attack_speed"},
            {"time": 5.0, "type": "damage_core", "amount": 250},
            {"time": 8.0, "type": "record_attack_speed"},
            {"time": 10.0, "type": "damage_core", "amount": 200},
            {"time": 13.0, "type": "record_attack_speed"}
        ],
        "expected_behavior": "核心HP每降低10%，攻速+5%；50%时攻速+25%，10%时攻速+45%"
    }
```

**验证指标**:
- [ ] 核心HP每降低10%，攻速+5%
- [ ] 攻速随血量动态变化
- [ ] 核心50%血量时攻速+25%
- [ ] 核心10%血量时攻速+45%

### 测试场景 2: Lv2 攻速提升验证

**测试ID**: `test_dog_lv2_rampage`

**测试配置**:
```gdscript
"test_dog_lv2_rampage":
    return {
        "id": "test_dog_lv2_rampage",
        "core_type": "wolf_totem",
        "duration": 20.0,
        "core_health": 250,
        "max_core_health": 500,
        "units": [
            {"id": "dog", "x": 0, "y": 1, "level": 2}
        ],
        "expected_behavior": "核心HP每降低10%，攻速+10%；50%时攻速+50%"
    }
```

**验证指标**:
- [ ] 核心HP每降低10%，攻速+10%
- [ ] 核心50%血量时攻速+50%

### 测试场景 3: Lv3 溅射验证

**测试ID**: `test_dog_lv3_splash`

**测试配置**:
```gdscript
"test_dog_lv3_splash":
    return {
        "id": "test_dog_lv3_splash",
        "core_type": "wolf_totem",
        "duration": 25.0,
        "core_health": 50,
        "max_core_health": 500,
        "units": [
            {"id": "dog", "x": 0, "y": 1, "level": 3}
        ],
        "enemies": [
            {"type": "basic_enemy", "count": 3, "positions": [{"x": 2, "y": 0}, {"x": 2, "y": 1}]}
        ],
        "expected_behavior": "攻速+80%以上时，可以造成溅射伤害"
    }
```

**验证指标**:
- [ ] 攻速提升80%以上时触发溅射（核心血量<=20%）
- [ ] 溅射对周围敌人造成伤害
- [ ] 溅射伤害为正常伤害的一定比例

## 实现要求

1. **添加到 TestSuite.gd**: 在 `get_test_config` 函数的 match 语句中添加以上3个测试用例

2. **测试运行验证**: 每个测试用例必须能通过 Headless 模式运行：
   ```bash
   godot --path . --headless -- --run-test=test_dog_lv1_rampage
   godot --path . --headless -- --run-test=test_dog_lv2_rampage
   godot --path . --headless -- --run-test=test_dog_lv3_splash
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
3. 在 TestSuite.gd 中添加以上3个测试用例
4. 运行测试验证：
   ```bash
   for test in test_dog_lv1_rampage test_dog_lv2_rampage test_dog_lv3_splash; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```
5. 更新 `docs/test_progress.md` 中的测试进度

## 代码提交要求

1. 在独立分支上工作：`feature/TEST-WOLF-DOG`
2. 提交信息格式：`[TEST-WOLF-DOG] Add automated tests for Dog unit`
3. 完成后创建 Pull Request 到 main 分支

## 进度同步

完成每个测试用例后，更新 `docs/progress.md`：

```markdown
| TEST-WOLF-DOG | in_progress | 添加恶霸犬Lv1狂暴测试 | 2026-02-20T14:30:00 |
```

## 相关文档

- `docs/test_progress.md` - 详细测试场景规范
- `docs/roles/qa_engineer.md` - 测试工程师角色指南
- `src/Scripts/Tests/AutomatedTestRunner.gd` - 测试运行器
- `src/Scripts/Tests/TestSuite.gd` - 测试配置
- `docs/GameDesign.md` - 恶霸犬单位设计文档

## Task ID

Task being executed: TEST-WOLF-DOG
