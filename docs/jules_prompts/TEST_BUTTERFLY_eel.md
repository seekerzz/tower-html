# Jules 任务: 电鳗 (eel) 自动化测试

## 任务ID
TEST-BUTTERFLY-eel

## 任务描述
为电鳗单位创建完整的自动化测试用例，验证其闪电链弹射机制，确保能在Headless模式下通过。

## 核心机制
**闪电链**: 攻击弹射至多个敌人，最多弹射4次，命中5个敌人，每次弹射伤害递减

## 测试场景

### 测试场景 1: Lv1 闪电链验证
```gdscript
{
    "id": "test_eel_lv1_chain",
    "core_type": "butterfly_totem",
    "duration": 15.0,
    "units": [
        {"id": "eel", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 5, "positions": [{"x": 2, "y": 0}, {"x": 3, "y": 0}, {"x": 4, "y": 0}]}
    ],
    "expected_behavior": {
        "description": "闪电链最多弹射4次",
        "verification": "一次攻击命中5个敌人"
    }
}
```

**验证指标**:
- [ ] 闪电链最多弹射4次
- [ ] 最多命中5个敌人
- [ ] 每次弹射伤害递减

### 测试场景 2: Lv2 伤害提升验证
**验证指标**:
- [ ] 闪电伤害+50%

### 测试场景 3: Lv3 法力震荡验证
```gdscript
{
    "id": "test_eel_lv3_mana",
    "core_type": "butterfly_totem",
    "duration": 20.0,
    "initial_mp": 500,
    "units": [
        {"id": "eel", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 5}
    ],
    "expected_behavior": {
        "description": "每次弹射回复3法力",
        "verification": "攻击命中5个敌人时MP增加12点"
    }
}
```

**验证指标**:
- [ ] 每次弹射回复3MP
- [ ] 回复量正确计算

## Headless测试配置

### 测试运行命令
```bash
# Lv1 闪电链测试
godot --path . --headless -- --run-test=test_eel_lv1_chain

# Lv2 伤害提升测试
godot --path . --headless -- --run-test=test_eel_lv2_damage

# Lv3 法力震荡测试
godot --path . --headless -- --run-test=test_eel_lv3_mana
```

### 通过标准
- 退出码为 0
- 无 SCRIPT ERROR
- 测试日志正常生成

## 实现步骤

1. **阅读现有代码**:
   - 阅读 `src/Scripts/Tests/TestSuite.gd` 了解测试配置格式
   - 阅读 `src/Scripts/Units/ButterflyTotem/Eel.gd` 了解单位实现

2. **添加测试用例**:
   在 `TestSuite.gd` 的 `get_test_config` 函数中添加:
   ```gdscript
   "test_eel_lv1_chain":
       return {
           "id": "test_eel_lv1_chain",
           "core_type": "butterfly_totem",
           "duration": 15.0,
           "units": [
               {"id": "eel", "x": 0, "y": 1, "level": 1}
           ],
           "enemies": [
               {"type": "basic_enemy", "count": 5, "positions": [{"x": 2, "y": 0}, {"x": 3, "y": 0}, {"x": 4, "y": 0}]}
           ],
           "expected_behavior": "闪电链最多弹射4次"
       }

   "test_eel_lv2_damage":
       return {
           "id": "test_eel_lv2_damage",
           "core_type": "butterfly_totem",
           "duration": 15.0,
           "units": [
               {"id": "eel", "x": 0, "y": 1, "level": 2}
           ],
           "expected_behavior": "闪电伤害+50%"
       }

   "test_eel_lv3_mana":
       return {
           "id": "test_eel_lv3_mana",
           "core_type": "butterfly_totem",
           "duration": 20.0,
           "initial_mp": 500,
           "units": [
               {"id": "eel", "x": 0, "y": 1, "level": 3}
           ],
           "enemies": [
               {"type": "basic_enemy", "count": 5}
           ],
           "expected_behavior": "每次弹射回复3法力"
       }
   ```

3. **运行测试验证**:
   ```bash
   for test in test_eel_lv1_chain test_eel_lv2_damage test_eel_lv3_mana; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```

4. **更新测试进度**:
   测试完成后，更新 `docs/test_progress.md` 中电鳗的验证指标。

## 进度更新要求

完成每个测试场景后，更新 `docs/progress.md`:

```markdown
| TEST-BUTTERFLY-eel | in_progress | 添加Lv1闪电链测试 | 2026-02-20T14:30:00 |
| TEST-BUTTERFLY-eel | in_progress | 添加Lv2伤害提升测试 | 2026-02-20T14:45:00 |
| TEST-BUTTERFLY-eel | completed | 所有测试通过 | 2026-02-20T15:00:00 |
```

同时在 `docs/test_progress.md` 中更新验证指标:
```markdown
**验证指标**:
- [x] 闪电链最多弹射4次
- [x] 最多命中5个敌人
- [x] 每次弹射伤害递减

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
- `src/Scripts/Units/ButterflyTotem/Eel.gd` - 单位实现

## Task ID

Task being executed: TEST-BUTTERFLY-eel
