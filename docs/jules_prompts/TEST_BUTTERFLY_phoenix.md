# Jules 任务: 凤凰 (phoenix) 自动化测试

## 任务ID
TEST-BUTTERFLY-phoenix

## 任务描述
为凤凰单位创建完整的自动化测试用例，验证其火雨AOE技能机制，确保能在Headless模式下通过。

## 核心机制
**火雨**: 主动技能，召唤火雨AOE区域，持续3秒，对区域内敌人造成伤害

## 测试场景

### 测试场景 1: Lv1 火雨验证
```gdscript
{
    "id": "test_phoenix_lv1_rain",
    "core_type": "butterfly_totem",
    "duration": 20.0,
    "units": [
        {"id": "phoenix", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 5, "positions": [{"x": 2, "y": 2}, {"x": 2, "y": 3}, {"x": 3, "y": 2}]}
    ],
    "scheduled_actions": [
        {"time": 5.0, "type": "skill", "source": "phoenix", "target": {"x": 2, "y": 2}}
    ],
    "expected_behavior": {
        "description": "火雨AOE持续3秒",
        "verification": "目标区域内敌人持续受到伤害"
    }
}
```

**验证指标**:
- [ ] 技能召唤火雨区域
- [ ] 火雨持续3秒
- [ ] 区域内敌人受到伤害

### 测试场景 2: Lv2 伤害提升验证
**验证指标**:
- [ ] 火雨伤害+50%

### 测试场景 3: Lv3 燃烧回蓝与临时法球验证
```gdscript
{
    "id": "test_phoenix_lv3_orb",
    "core_type": "butterfly_totem",
    "duration": 25.0,
    "initial_mp": 500,
    "units": [
        {"id": "phoenix", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3}
    ],
    "expected_behavior": {
        "description": "燃烧敌人时回复法力，获得临时法球",
        "verification": "燃烧敌人时MP增加，图腾法球数量增加"
    }
}
```

**验证指标**:
- [ ] 燃烧敌人时回复法力
- [ ] 获得临时法球
- [ ] 临时法球持续一定时间

## Headless测试配置

### 测试运行命令
```bash
# Lv1 火雨测试
godot --path . --headless -- --run-test=test_phoenix_lv1_rain

# Lv2 伤害提升测试
godot --path . --headless -- --run-test=test_phoenix_lv2_damage

# Lv3 燃烧回蓝测试
godot --path . --headless -- --run-test=test_phoenix_lv3_orb
```

### 通过标准
- 退出码为 0
- 无 SCRIPT ERROR
- 测试日志正常生成

## 实现步骤

1. **阅读现有代码**:
   - 阅读 `src/Scripts/Tests/TestSuite.gd` 了解测试配置格式
   - 阅读 `src/Scripts/Units/ButterflyTotem/Phoenix.gd` 了解单位实现

2. **添加测试用例**:
   在 `TestSuite.gd` 的 `get_test_config` 函数中添加:
   ```gdscript
   "test_phoenix_lv1_rain":
       return {
           "id": "test_phoenix_lv1_rain",
           "core_type": "butterfly_totem",
           "duration": 20.0,
           "units": [
               {"id": "phoenix", "x": 0, "y": 1, "level": 1}
           ],
           "enemies": [
               {"type": "basic_enemy", "count": 5, "positions": [{"x": 2, "y": 2}, {"x": 2, "y": 3}, {"x": 3, "y": 2}]}
           ],
           "scheduled_actions": [
               {"time": 5.0, "type": "skill", "source": "phoenix", "target": {"x": 2, "y": 2}}
           ],
           "expected_behavior": "火雨AOE持续3秒"
       }

   "test_phoenix_lv2_damage":
       return {
           "id": "test_phoenix_lv2_damage",
           "core_type": "butterfly_totem",
           "duration": 20.0,
           "units": [
               {"id": "phoenix", "x": 0, "y": 1, "level": 2}
           ],
           "expected_behavior": "火雨伤害+50%"
       }

   "test_phoenix_lv3_orb":
       return {
           "id": "test_phoenix_lv3_orb",
           "core_type": "butterfly_totem",
           "duration": 25.0,
           "initial_mp": 500,
           "units": [
               {"id": "phoenix", "x": 0, "y": 1, "level": 3}
           ],
           "enemies": [
               {"type": "basic_enemy", "count": 3}
           ],
           "expected_behavior": "燃烧敌人时回复法力，获得临时法球"
       }
   ```

3. **运行测试验证**:
   ```bash
   for test in test_phoenix_lv1_rain test_phoenix_lv2_damage test_phoenix_lv3_orb; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```

4. **更新测试进度**:
   测试完成后，更新 `docs/test_progress.md` 中凤凰的验证指标。

## 进度更新要求

完成每个测试场景后，更新 `docs/progress.md`:

```markdown
| TEST-BUTTERFLY-phoenix | in_progress | 添加Lv1火雨测试 | 2026-02-20T14:30:00 |
| TEST-BUTTERFLY-phoenix | in_progress | 添加Lv2伤害提升测试 | 2026-02-20T14:45:00 |
| TEST-BUTTERFLY-phoenix | completed | 所有测试通过 | 2026-02-20T15:00:00 |
```

同时在 `docs/test_progress.md` 中更新验证指标:
```markdown
**验证指标**:
- [x] 技能召唤火雨区域
- [x] 火雨持续3秒
- [x] 区域内敌人受到伤害

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
- `src/Scripts/Units/ButterflyTotem/Phoenix.gd` - 单位实现

## Task ID

Task being executed: TEST-BUTTERFLY-phoenix
