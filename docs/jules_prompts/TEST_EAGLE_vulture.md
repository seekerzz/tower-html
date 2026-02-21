# Jules 任务: 秃鹫 (vulture) 自动化测试

## 任务ID
TEST-EAGLE-vulture

## 任务描述
为秃鹫单位创建完整的自动化测试用例，验证其尸体吞噬机制，确保能在Headless模式下通过。

## 核心机制
**尸体吞噬**: 优先攻击低HP敌人

## 测试场景

### 测试场景 1: Lv1 死神验证
```gdscript
{
    "id": "test_vulture_lv1_reaper",
    "core_type": "eagle_totem",
    "duration": 20.0,
    "units": [
        {"id": "vulture", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "hp": 100, "count": 2},
        {"type": "low_hp_enemy", "hp": 30, "count": 1}
    ],
    "expected_behavior": {
        "description": "优先攻击HP最低的敌人",
        "verification": "秃鹫优先攻击低血量敌人"
    }
}
```

**验证指标**:
- [ ] 优先攻击HP最低的敌人

### 测试场景 2: Lv2 伤害和击杀成长验证
**验证指标**:
- [ ] 对低HP敌人伤害+30%
- [ ] 击杀后永久攻击力+1

### 测试场景 3: Lv3 腐肉大餐验证
**验证指标**:
- [ ] 击杀敌人后永久增加自身攻击力
- [ ] 可无限叠加

## Headless测试配置

### 测试运行命令
```bash
# Lv1 死神测试
godot --path . --headless -- --run-test=test_vulture_lv1_reaper

# Lv2 伤害和击杀成长测试
godot --path . --headless -- --run-test=test_vulture_lv2_growth

# Lv3 腐肉大餐测试
godot --path . --headless -- --run-test=test_vulture_lv3_feast
```

### 通过标准
- 退出码为 0
- 无 SCRIPT ERROR
- 测试日志正常生成

## 实现步骤

1. **阅读现有代码**:
   - 阅读 `src/Scripts/Tests/TestSuite.gd` 了解测试配置格式
   - 阅读 `src/Scripts/Units/EagleTotem/Vulture.gd` 了解单位实现

2. **添加测试用例**:
   在 `TestSuite.gd` 的 `get_test_config` 函数中添加:
   ```gdscript
   "test_vulture_lv1_reaper":
       return {
           "id": "test_vulture_lv1_reaper",
           "core_type": "eagle_totem",
           "duration": 20.0,
           "units": [
               {"id": "vulture", "x": 0, "y": 1, "level": 1}
           ],
           "enemies": [
               {"type": "basic_enemy", "hp": 100, "count": 2},
               {"type": "low_hp_enemy", "hp": 30, "count": 1}
           ],
           "expected_behavior": "优先攻击HP最低的敌人"
       }

   "test_vulture_lv2_growth":
       return {
           "id": "test_vulture_lv2_growth",
           "core_type": "eagle_totem",
           "duration": 30.0,
           "units": [
               {"id": "vulture", "x": 0, "y": 1, "level": 2}
           ],
           "enemies": [
               {"type": "basic_enemy", "hp": 50, "count": 5}
           ],
           "expected_behavior": "对低HP敌人伤害+30%，击杀后永久攻击力+1"
       }

   "test_vulture_lv3_feast":
       return {
           "id": "test_vulture_lv3_feast",
           "core_type": "eagle_totem",
           "duration": 30.0,
           "units": [
               {"id": "vulture", "x": 0, "y": 1, "level": 3}
           ],
           "enemies": [
               {"type": "basic_enemy", "hp": 50, "count": 10}
           ],
           "expected_behavior": "击杀敌人后永久增加自身攻击力，可无限叠加"
       }
   ```

3. **运行测试验证**:
   ```bash
   for test in test_vulture_lv1_reaper test_vulture_lv2_growth test_vulture_lv3_feast; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```

4. **更新测试进度**:
   测试完成后，更新 `docs/test_progress.md` 中秃鹫的验证指标。

## 进度更新要求

完成每个测试场景后，更新 `docs/progress.md`:

```markdown
| TEST-EAGLE-vulture | in_progress | 添加Lv1死神测试 | 2026-02-20T14:30:00 |
| TEST-EAGLE-vulture | in_progress | 添加Lv2伤害和击杀成长测试 | 2026-02-20T14:40:00 |
| TEST-EAGLE-vulture | in_progress | 添加Lv3腐肉大餐测试 | 2026-02-20T14:50:00 |
| TEST-EAGLE-vulture | completed | 所有测试通过 | 2026-02-20T15:00:00 |
```

同时在 `docs/test_progress.md` 中更新验证指标:
```markdown
**验证指标**:
- [x] 优先攻击HP最低的敌人
- [x] 对低HP敌人伤害+30%（Lv2）
- [x] 击杀后永久攻击力+1（Lv2）
- [x] 击杀敌人后永久增加自身攻击力（Lv3）
- [x] 可无限叠加（Lv3）

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
- `src/Scripts/Units/EagleTotem/Vulture.gd` - 单位实现

## Task ID

Task being executed: TEST-EAGLE-vulture
