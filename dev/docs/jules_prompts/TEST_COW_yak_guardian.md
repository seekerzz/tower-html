# Jules 任务: 牦牛守护 (yak_guardian) 自动化测试

## 任务ID
TEST-COW-yak_guardian

## 任务描述
为牦牛守护单位创建完整的自动化测试用例，验证其嘲讽/守护领域机制，确保能在Headless模式下通过。

## 核心机制
**嘲讽/守护领域**: 周期性吸引敌人攻击自己，并为周围友方提供减伤Buff

## 测试场景

### 测试场景 1: Lv1 嘲讽机制验证
```gdscript
{
    "id": "test_yak_guardian_lv1_taunt",
    "core_type": "cow_totem",
    "initial_gold": 1000,
    "start_wave_index": 1,
    "duration": 15.0,
    "units": [
        {"id": "squirrel", "x": 0, "y": -1},
        {"id": "yak_guardian", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3, "spawn_delay": 1.0}
    ],
    "expected_behavior": {
        "description": "敌人初始攻击松鼠，5秒后转为攻击牦牛守护",
        "verification": "检查日志中敌人target切换记录",
        "taunt_interval": 5.0
    }
}
```

**验证指标**:
- [ ] 敌人生成后首先锁定松鼠
- [ ] 5秒后敌人目标切换为牦牛守护
- [ ] 牦牛守护周围的友方单位获得guardian_shield buff
- [ ] Buff提供的减伤为5%

### 测试场景 2: Lv2 嘲讽频率提升验证
```gdscript
{
    "id": "test_yak_guardian_lv2_taunt",
    "core_type": "cow_totem",
    "duration": 12.0,
    "units": [
        {"id": "squirrel", "x": 0, "y": -1},
        {"id": "yak_guardian", "x": 0, "y": 1, "level": 2}
    ],
    "expected_behavior": {
        "taunt_interval": 4.0,
        "damage_reduction": 0.10
    }
}
```

**验证指标**:
- [ ] 嘲讽间隔为4秒
- [ ] Buff提供的减伤为10%

### 测试场景 3: Lv3 图腾反击联动验证
```gdscript
{
    "id": "test_yak_guardian_lv3_totem_counter",
    "core_type": "cow_totem",
    "duration": 20.0,
    "units": [
        {"id": "yak_guardian", "x": 0, "y": 1, "level": 3}
    ],
    "scheduled_actions": [
        {
            "time": 5.0,
            "type": "damage_core",
            "amount": 50
        }
    ],
    "expected_behavior": {
        "description": "牛图腾反击时，牦牛攻击范围内敌人受到牦牛血量15%的额外伤害",
        "verification": "检查反击时敌人受到的伤害数值"
    }
}
```

**验证指标**:
- [ ] 核心受到伤害后，牛图腾触发全屏反击
- [ ] 牦牛守护攻击范围内的敌人受到额外伤害
- [ ] 额外伤害 = 牦牛当前血量 × 15%

## Headless测试配置

### 测试运行命令
```bash
# Lv1 嘲讽测试
godot --path . --headless -- --run-test=test_yak_guardian_lv1_taunt

# Lv2 嘲讽频率测试
godot --path . --headless -- --run-test=test_yak_guardian_lv2_taunt

# Lv3 图腾反击联动测试
godot --path . --headless -- --run-test=test_yak_guardian_lv3_totem_counter
```

### 通过标准
- 退出码为 0
- 无 SCRIPT ERROR
- 测试日志正常生成

## 实现步骤

1. **阅读现有代码**:
   - 阅读 `src/Scripts/Tests/TestSuite.gd` 了解测试配置格式
   - 阅读 `src/Scripts/Units/CowTotem/YakGuardian.gd` 了解单位实现

2. **添加测试用例**:
   在 `TestSuite.gd` 的 `get_test_config` 函数中添加:
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

   "test_yak_guardian_lv3_totem_counter":
       return {
           "id": "test_yak_guardian_lv3_totem_counter",
           "core_type": "cow_totem",
           "duration": 20.0,
           "units": [
               {"id": "yak_guardian", "x": 0, "y": 1, "level": 3}
           ],
           "expected_behavior": "牛图腾反击时，范围内敌人受到牦牛血量15%额外伤害"
       }
   ```

3. **运行测试验证**:
   ```bash
   for test in test_yak_guardian_lv1_taunt test_yak_guardian_lv2_taunt test_yak_guardian_lv3_totem_counter; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```

4. **更新测试进度**:
   测试完成后，更新 `docs/test_progress.md` 中牦牛守护的验证指标。

## 进度更新要求

完成每个测试场景后，更新 `docs/progress.md`:

```markdown
| TEST-COW-yak_guardian | in_progress | 添加Lv1嘲讽测试 | 2026-02-20T14:30:00 |
| TEST-COW-yak_guardian | in_progress | 添加Lv2嘲讽频率测试 | 2026-02-20T14:45:00 |
| TEST-COW-yak_guardian | completed | 所有测试通过 | 2026-02-20T15:00:00 |
```

同时在 `docs/test_progress.md` 中更新验证指标:
```markdown
**验证指标**:
- [x] 敌人生成后首先锁定松鼠
- [x] 5秒后敌人目标切换为牦牛守护
- [x] 牦牛守护周围的友方单位获得guardian_shield buff
- [x] Buff提供的减伤为5%

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
- `src/Scripts/Units/CowTotem/YakGuardian.gd` - 单位实现

## Task ID

Task being executed: TEST-COW-yak_guardian
