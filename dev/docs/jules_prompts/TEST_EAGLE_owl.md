# Jules 任务: 猫头鹰 (owl) 自动化测试

## 任务ID
TEST-EAGLE-owl

## 任务描述
为猫头鹰单位创建完整的自动化测试用例，验证其范围致盲机制，确保能在Headless模式下通过。

## 核心机制
**范围致盲**: 增加友军暴击率

## 测试场景

### 测试场景 1: Lv1 洞察验证
```gdscript
{
    "id": "test_owl_lv1_insight",
    "core_type": "eagle_totem",
    "duration": 20.0,
    "units": [
        {"id": "owl", "x": 0, "y": 1, "level": 1},
        {"id": "squirrel", "x": 1, "y": 0}  # 相邻友军
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 5}
    ],
    "expected_behavior": {
        "description": "增加相邻友军12%暴击率",
        "verification": "松鼠暴击率增加12%"
    }
}
```

**验证指标**:
- [ ] 相邻友军暴击率+12%
- [ ] 仅影响相邻单位

### 测试场景 2: Lv2 效果和范围提升验证
**验证指标**:
- [ ] 暴击率加成20%
- [ ] 影响范围2格

### 测试场景 3: Lv3 回响洞察验证
```gdscript
{
    "id": "test_owl_lv3_echo",
    "core_type": "eagle_totem",
    "duration": 25.0,
    "units": [
        {"id": "owl", "x": 0, "y": 1, "level": 3},
        {"id": "squirrel", "x": 1, "y": 0}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 5}
    ],
    "expected_behavior": {
        "description": "相邻友军触发图腾回响时攻速+15%持续3秒",
        "verification": "松鼠触发回响时，攻速提升15%持续3秒"
    }
}
```

**验证指标**:
- [ ] 触发回响时攻速+15%
- [ ] 持续3秒

## Headless测试配置

### 测试运行命令
```bash
# Lv1 洞察测试
godot --path . --headless -- --run-test=test_owl_lv1_insight

# Lv3 回响洞察测试
godot --path . --headless -- --run-test=test_owl_lv3_echo
```

### 通过标准
- 退出码为 0
- 无 SCRIPT ERROR
- 测试日志正常生成

## 实现步骤

1. **阅读现有代码**:
   - 阅读 `src/Scripts/Tests/TestSuite.gd` 了解测试配置格式
   - 阅读 `src/Scripts/Units/EagleTotem/Owl.gd` 了解单位实现

2. **添加测试用例**:
   在 `TestSuite.gd` 的 `get_test_config` 函数中添加:
   ```gdscript
   "test_owl_lv1_insight":
       return {
           "id": "test_owl_lv1_insight",
           "core_type": "eagle_totem",
           "duration": 20.0,
           "units": [
               {"id": "owl", "x": 0, "y": 1, "level": 1},
               {"id": "squirrel", "x": 1, "y": 0}
           ],
           "enemies": [
               {"type": "basic_enemy", "count": 5}
           ],
           "expected_behavior": "增加相邻友军12%暴击率"
       }

   "test_owl_lv3_echo":
       return {
           "id": "test_owl_lv3_echo",
           "core_type": "eagle_totem",
           "duration": 25.0,
           "units": [
               {"id": "owl", "x": 0, "y": 1, "level": 3},
               {"id": "squirrel", "x": 1, "y": 0}
           ],
           "enemies": [
               {"type": "basic_enemy", "count": 5}
           ],
           "expected_behavior": "相邻友军触发图腾回响时攻速+15%持续3秒"
       }
   ```

3. **运行测试验证**:
   ```bash
   for test in test_owl_lv1_insight test_owl_lv3_echo; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```

4. **更新测试进度**:
   测试完成后，更新 `docs/test_progress.md` 中猫头鹰的验证指标。

## 进度更新要求

完成每个测试场景后，更新 `docs/progress.md`:

```markdown
| TEST-EAGLE-owl | in_progress | 添加Lv1洞察测试 | 2026-02-20T14:30:00 |
| TEST-EAGLE-owl | in_progress | 添加Lv3回响洞察测试 | 2026-02-20T14:45:00 |
| TEST-EAGLE-owl | completed | 所有测试通过 | 2026-02-20T15:00:00 |
```

同时在 `docs/test_progress.md` 中更新验证指标:
```markdown
**验证指标**:
- [x] 相邻友军暴击率+12%
- [x] 仅影响相邻单位
- [x] 暴击率加成20%（Lv2）
- [x] 影响范围2格（Lv2）
- [x] 触发回响时攻速+15%（Lv3）
- [x] 持续3秒（Lv3）

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
- `src/Scripts/Units/EagleTotem/Owl.gd` - 单位实现

## Task ID

Task being executed: TEST-EAGLE-owl
