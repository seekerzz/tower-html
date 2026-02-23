# Jules 任务: 啄木鸟 (woodpecker) 自动化测试

## 任务ID
TEST-EAGLE-woodpecker

## 任务描述
为啄木鸟单位创建完整的自动化测试用例，验证其眩晕机制，确保能在Headless模式下通过。

## 核心机制
**眩晕**: 叠加伤害

## 测试场景

### 测试场景 1: Lv1 钻孔验证
```gdscript
{
    "id": "test_woodpecker_lv1_drill",
    "core_type": "eagle_totem",
    "duration": 25.0,
    "units": [
        {"id": "woodpecker", "x": 0, "y": 1, "level": 1, "attack": 10}
    ],
    "enemies": [
        {"type": "high_hp_enemy", "count": 1, "hp": 500}
    ],
    "expected_behavior": {
        "description": "攻击同一目标时每次伤害+10%(上限+100%)",
        "verification": "连续攻击同一敌人，伤害逐渐增加到20点"
    }
}
```

**验证指标**:
- [ ] 每次攻击同一目标伤害+10%
- [ ] 上限+100%(伤害翻倍)
- [ ] 切换目标重置叠加

### 测试场景 2: Lv2 叠加速度和上限提升验证
**验证指标**:
- [ ] 叠加速度+50%(每次+15%)
- [ ] 上限150%

### 测试场景 3: Lv3 必定暴击验证
```gdscript
{
    "id": "test_woodpecker_lv3_crit",
    "core_type": "eagle_totem",
    "duration": 30.0,
    "units": [
        {"id": "woodpecker", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "high_hp_enemy", "count": 1, "hp": 1000}
    ],
    "expected_behavior": {
        "description": "叠满后下3次攻击必定暴击并触发图腾回响",
        "verification": "叠满后3次攻击必定暴击，触发回响"
    }
}
```

**验证指标**:
- [ ] 叠满后3次攻击必定暴击
- [ ] 必定触发图腾回响

## Headless测试配置

### 测试运行命令
```bash
# Lv1 钻孔测试
godot --path . --headless -- --run-test=test_woodpecker_lv1_drill

# Lv3 必定暴击测试
godot --path . --headless -- --run-test=test_woodpecker_lv3_crit
```

### 通过标准
- 退出码为 0
- 无 SCRIPT ERROR
- 测试日志正常生成

## 实现步骤

1. **阅读现有代码**:
   - 阅读 `src/Scripts/Tests/TestSuite.gd` 了解测试配置格式
   - 阅读 `src/Scripts/Units/EagleTotem/Woodpecker.gd` 了解单位实现

2. **添加测试用例**:
   在 `TestSuite.gd` 的 `get_test_config` 函数中添加:
   ```gdscript
   "test_woodpecker_lv1_drill":
       return {
           "id": "test_woodpecker_lv1_drill",
           "core_type": "eagle_totem",
           "duration": 25.0,
           "units": [
               {"id": "woodpecker", "x": 0, "y": 1, "level": 1, "attack": 10}
           ],
           "enemies": [
               {"type": "high_hp_enemy", "count": 1, "hp": 500}
           ],
           "expected_behavior": "攻击同一目标时每次伤害+10%(上限+100%)"
       }

   "test_woodpecker_lv3_crit":
       return {
           "id": "test_woodpecker_lv3_crit",
           "core_type": "eagle_totem",
           "duration": 30.0,
           "units": [
               {"id": "woodpecker", "x": 0, "y": 1, "level": 3}
           ],
           "enemies": [
               {"type": "high_hp_enemy", "count": 1, "hp": 1000}
           ],
           "expected_behavior": "叠满后下3次攻击必定暴击并触发图腾回响"
       }
   ```

3. **运行测试验证**:
   ```bash
   for test in test_woodpecker_lv1_drill test_woodpecker_lv3_crit; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```

4. **更新测试进度**:
   测试完成后，更新 `docs/test_progress.md` 中啄木鸟的验证指标。

## 进度更新要求

完成每个测试场景后，更新 `docs/progress.md`:

```markdown
| TEST-EAGLE-woodpecker | in_progress | 添加Lv1钻孔测试 | 2026-02-20T14:30:00 |
| TEST-EAGLE-woodpecker | in_progress | 添加Lv3必定暴击测试 | 2026-02-20T14:45:00 |
| TEST-EAGLE-woodpecker | completed | 所有测试通过 | 2026-02-20T15:00:00 |
```

同时在 `docs/test_progress.md` 中更新验证指标:
```markdown
**验证指标**:
- [x] 每次攻击同一目标伤害+10%
- [x] 上限+100%(伤害翻倍)
- [x] 切换目标重置叠加
- [x] 叠加速度+50%(每次+15%)（Lv2）
- [x] 上限150%（Lv2）
- [x] 叠满后3次攻击必定暴击（Lv3）
- [x] 必定触发图腾回响（Lv3）

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
- `src/Scripts/Units/EagleTotem/Woodpecker.gd` - 单位实现

## Task ID

Task being executed: TEST-EAGLE-woodpecker
