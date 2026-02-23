# Jules 任务: 龙 (dragon) 自动化测试

## 任务ID
TEST-BUTTERFLY-dragon

## 任务描述
为龙单位创建完整的自动化测试用例，验证其黑洞控制技能机制，确保能在Headless模式下通过。

## 核心机制
**黑洞**: 主动技能，召唤黑洞控制区域，持续4秒，将范围内敌人吸入中心，Lv3结束时造成伤害

## 测试场景

### 测试场景 1: Lv1 黑洞验证
```gdscript
{
    "id": "test_dragon_lv1_blackhole",
    "core_type": "butterfly_totem",
    "duration": 20.0,
    "units": [
        {"id": "dragon", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 5, "positions": [{"x": 2, "y": 2}, {"x": 3, "y": 2}, {"x": 2, "y": 3}]}
    ],
    "scheduled_actions": [
        {"time": 5.0, "type": "skill", "source": "dragon", "target": {"x": 2, "y": 2}}
    ],
    "expected_behavior": {
        "description": "黑洞控制持续4秒，吸入敌人",
        "verification": "敌人被吸入黑洞中心，持续4秒"
    }
}
```

**验证指标**:
- [ ] 技能召唤黑洞
- [ ] 黑洞持续4秒
- [ ] 范围内敌人被吸入中心

### 测试场景 2: Lv2 范围和持续时间提升验证
**验证指标**:
- [ ] 黑洞范围+20%
- [ ] 持续时间提升至6秒

### 测试场景 3: Lv3 星辰坠落验证
```gdscript
{
    "id": "test_dragon_lv3_meteor",
    "core_type": "butterfly_totem",
    "duration": 25.0,
    "units": [
        {"id": "dragon", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 5, "hp": 100}
    ],
    "scheduled_actions": [
        {"time": 5.0, "type": "skill", "source": "dragon", "target": {"x": 2, "y": 2}},
        {"time": 11.0, "type": "verify_damage"}
    ],
    "expected_behavior": {
        "description": "黑洞结束时根据吸入敌人数量造成伤害",
        "verification": "黑洞结束时所有被吸入敌人受到伤害"
    }
}
```

**验证指标**:
- [ ] 黑洞结束时造成伤害
- [ ] 伤害与吸入敌人数量相关

## Headless测试配置

### 测试运行命令
```bash
# Lv1 黑洞测试
godot --path . --headless -- --run-test=test_dragon_lv1_blackhole

# Lv2 范围持续时间测试
godot --path . --headless -- --run-test=test_dragon_lv2_range

# Lv3 星辰坠落测试
godot --path . --headless -- --run-test=test_dragon_lv3_meteor
```

### 通过标准
- 退出码为 0
- 无 SCRIPT ERROR
- 测试日志正常生成

## 实现步骤

1. **阅读现有代码**:
   - 阅读 `src/Scripts/Tests/TestSuite.gd` 了解测试配置格式
   - 阅读 `src/Scripts/Units/ButterflyTotem/Dragon.gd` 了解单位实现

2. **添加测试用例**:
   在 `TestSuite.gd` 的 `get_test_config` 函数中添加:
   ```gdscript
   "test_dragon_lv1_blackhole":
       return {
           "id": "test_dragon_lv1_blackhole",
           "core_type": "butterfly_totem",
           "duration": 20.0,
           "units": [
               {"id": "dragon", "x": 0, "y": 1, "level": 1}
           ],
           "enemies": [
               {"type": "basic_enemy", "count": 5, "positions": [{"x": 2, "y": 2}, {"x": 3, "y": 2}, {"x": 2, "y": 3}]}
           ],
           "scheduled_actions": [
               {"time": 5.0, "type": "skill", "source": "dragon", "target": {"x": 2, "y": 2}}
           ],
           "expected_behavior": "黑洞控制持续4秒，吸入敌人"
       }

   "test_dragon_lv2_range":
       return {
           "id": "test_dragon_lv2_range",
           "core_type": "butterfly_totem",
           "duration": 20.0,
           "units": [
               {"id": "dragon", "x": 0, "y": 1, "level": 2}
           ],
           "expected_behavior": "黑洞范围+20%，持续时间提升至6秒"
       }

   "test_dragon_lv3_meteor":
       return {
           "id": "test_dragon_lv3_meteor",
           "core_type": "butterfly_totem",
           "duration": 25.0,
           "units": [
               {"id": "dragon", "x": 0, "y": 1, "level": 3}
           ],
           "enemies": [
               {"type": "basic_enemy", "count": 5, "hp": 100}
           ],
           "scheduled_actions": [
               {"time": 5.0, "type": "skill", "source": "dragon", "target": {"x": 2, "y": 2}},
               {"time": 11.0, "type": "verify_damage"}
           ],
           "expected_behavior": "黑洞结束时根据吸入敌人数量造成伤害"
       }
   ```

3. **运行测试验证**:
   ```bash
   for test in test_dragon_lv1_blackhole test_dragon_lv2_range test_dragon_lv3_meteor; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```

4. **更新测试进度**:
   测试完成后，更新 `docs/test_progress.md` 中龙的验证指标。

## 进度更新要求

完成每个测试场景后，更新 `docs/progress.md`:

```markdown
| TEST-BUTTERFLY-dragon | in_progress | 添加Lv1黑洞测试 | 2026-02-20T14:30:00 |
| TEST-BUTTERFLY-dragon | in_progress | 添加Lv2范围持续时间测试 | 2026-02-20T14:45:00 |
| TEST-BUTTERFLY-dragon | completed | 所有测试通过 | 2026-02-20T15:00:00 |
```

同时在 `docs/test_progress.md` 中更新验证指标:
```markdown
**验证指标**:
- [x] 技能召唤黑洞
- [x] 黑洞持续4秒
- [x] 范围内敌人被吸入中心

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
- `src/Scripts/Units/ButterflyTotem/Dragon.gd` - 单位实现

## Task ID

Task being executed: TEST-BUTTERFLY-dragon
