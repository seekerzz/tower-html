# Jules 任务: 鸽子 (pigeon) 自动化测试

## 任务ID
TEST-EAGLE-pigeon

## 任务描述
为鸽子单位创建完整的自动化测试用例，验证其信鸽传书机制，确保能在Headless模式下通过。

## 核心机制
**信鸽传书**: 闪避敌人攻击

## 测试场景

### 测试场景 1: Lv1 闪避验证
```gdscript
{
    "id": "test_pigeon_lv1_dodge",
    "core_type": "eagle_totem",
    "duration": 30.0,
    "units": [
        {"id": "pigeon", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "attacker_enemy", "count": 10, "attack_speed": 2.0}  # 多次攻击触发概率
    ],
    "expected_behavior": {
        "description": "敌人攻击有12%概率Miss",
        "verification": "约12%的敌人攻击Miss"
    }
}
```

**验证指标**:
- [ ] 闪避概率12%
- [ ] 闪避时不受伤害

### 测试场景 2: Lv2 闪避提升和无敌验证
**验证指标**:
- [ ] 闪避概率20%
- [ ] 闪避后0.3秒内无敌

### 测试场景 3: Lv3 闪避反击验证
```gdscript
{
    "id": "test_pigeon_lv3_counter",
    "core_type": "eagle_totem",
    "duration": 25.0,
    "units": [
        {"id": "pigeon", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "attacker_enemy", "count": 5}
    ],
    "expected_behavior": {
        "description": "闪避时反击，反击可暴击并触发图腾回响",
        "verification": "闪避时自动反击敌人，伤害可暴击"
    }
}
```

**验证指标**:
- [ ] 闪避时自动反击
- [ ] 反击可暴击
- [ ] 触发图腾回响

## Headless测试配置

### 测试运行命令
```bash
# Lv1 闪避测试
godot --path . --headless -- --run-test=test_pigeon_lv1_dodge

# Lv3 闪避反击测试
godot --path . --headless -- --run-test=test_pigeon_lv3_counter
```

### 通过标准
- 退出码为 0
- 无 SCRIPT ERROR
- 测试日志正常生成

## 实现步骤

1. **阅读现有代码**:
   - 阅读 `src/Scripts/Tests/TestSuite.gd` 了解测试配置格式
   - 阅读 `src/Scripts/Units/EagleTotem/Pigeon.gd` 了解单位实现

2. **添加测试用例**:
   在 `TestSuite.gd` 的 `get_test_config` 函数中添加:
   ```gdscript
   "test_pigeon_lv1_dodge":
       return {
           "id": "test_pigeon_lv1_dodge",
           "core_type": "eagle_totem",
           "duration": 30.0,
           "units": [
               {"id": "pigeon", "x": 0, "y": 1, "level": 1}
           ],
           "enemies": [
               {"type": "attacker_enemy", "count": 10, "attack_speed": 2.0}
           ],
           "expected_behavior": "敌人攻击有12%概率Miss"
       }

   "test_pigeon_lv3_counter":
       return {
           "id": "test_pigeon_lv3_counter",
           "core_type": "eagle_totem",
           "duration": 25.0,
           "units": [
               {"id": "pigeon", "x": 0, "y": 1, "level": 3}
           ],
           "enemies": [
               {"type": "attacker_enemy", "count": 5}
           ],
           "expected_behavior": "闪避时反击，反击可暴击并触发图腾回响"
       }
   ```

3. **运行测试验证**:
   ```bash
   for test in test_pigeon_lv1_dodge test_pigeon_lv3_counter; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```

4. **更新测试进度**:
   测试完成后，更新 `docs/test_progress.md` 中鸽子的验证指标。

## 进度更新要求

完成每个测试场景后，更新 `docs/progress.md`:

```markdown
| TEST-EAGLE-pigeon | in_progress | 添加Lv1闪避测试 | 2026-02-20T14:30:00 |
| TEST-EAGLE-pigeon | in_progress | 添加Lv3闪避反击测试 | 2026-02-20T14:45:00 |
| TEST-EAGLE-pigeon | completed | 所有测试通过 | 2026-02-20T15:00:00 |
```

同时在 `docs/test_progress.md` 中更新验证指标:
```markdown
**验证指标**:
- [x] 闪避概率12%
- [x] 闪避时不受伤害
- [x] 闪避概率20%（Lv2）
- [x] 闪避后0.3秒内无敌（Lv2）
- [x] 闪避时自动反击（Lv3）
- [x] 反击可暴击（Lv3）
- [x] 触发图腾回响（Lv3）

**测试记录**:
- 测试日期: 2026-02-20
- 测试人员: Jules
- 测试结果: 通过
- 备注: 无
```

## 相关文档

- `docs/test_progress.md` - 详细测试场景规范
- `docs/roles/qa_engineer.md` - 测试工程师角色指南
- `src/Scripts/Tests/AutomatedTestRunner.gd` - 测试运行器
- `src/Scripts/Tests/TestSuite.gd` - 测试配置
- `src/Scripts/Units/EagleTotem/Pigeon.gd` - 单位实现

## Task ID

Task being executed: TEST-EAGLE-pigeon
