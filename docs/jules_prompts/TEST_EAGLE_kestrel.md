# Jules 任务: 红隼 (kestrel) 自动化测试

## 任务ID
TEST-EAGLE-kestrel

## 任务描述
为红隼单位创建完整的自动化测试用例，验证其击杀加攻速机制，确保能在Headless模式下通过。

## 核心机制
**击杀加攻速**: 红隼击杀敌人后获得攻速加成

## 测试场景

### 测试场景 1: Lv1 俯冲眩晕验证
```gdscript
{
    "id": "test_kestrel_lv1_dive",
    "core_type": "eagle_totem",
    "duration": 30.0,
    "units": [
        {"id": "kestrel", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 10}  # 多次攻击触发概率
    ],
    "expected_behavior": {
        "description": "攻击有20%概率造成1秒眩晕",
        "verification": "约20%的攻击使敌人眩晕1秒"
    }
}
```

**验证指标**:
- [ ] 眩晕概率20%
- [ ] 眩晕持续1秒

### 测试场景 2: Lv2 概率和时间提升验证
**验证指标**:
- [ ] 眩晕概率30%
- [ ] 眩晕时间1.2秒

### 测试场景 3: Lv3 音爆验证
```gdscript
{
    "id": "test_kestrel_lv3_sonic",
    "core_type": "eagle_totem",
    "duration": 25.0,
    "units": [
        {"id": "kestrel", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3, "positions": [{"x": 2, "y": 0}, {"x": 2, "y": 1}]}
    ],
    "expected_behavior": {
        "description": "眩晕触发时造成小范围震荡伤害",
        "verification": "眩晕触发时，周围敌人也受到伤害"
    }
}
```

**验证指标**:
- [ ] 眩晕时触发范围伤害
- [ ] 范围内敌人受到伤害

## Headless测试配置

### 测试运行命令
```bash
# Lv1 俯冲眩晕测试
godot --path . --headless -- --run-test=test_kestrel_lv1_dive

# Lv3 音爆测试
godot --path . --headless -- --run-test=test_kestrel_lv3_sonic
```

### 通过标准
- 退出码为 0
- 无 SCRIPT ERROR
- 测试日志正常生成

## 实现步骤

1. **阅读现有代码**:
   - 阅读 `src/Scripts/Tests/TestSuite.gd` 了解测试配置格式
   - 阅读 `src/Scripts/Units/EagleTotem/Kestrel.gd` 了解单位实现

2. **添加测试用例**:
   在 `TestSuite.gd` 的 `get_test_config` 函数中添加:
   ```gdscript
   "test_kestrel_lv1_dive":
       return {
           "id": "test_kestrel_lv1_dive",
           "core_type": "eagle_totem",
           "duration": 30.0,
           "units": [
               {"id": "kestrel", "x": 0, "y": 1, "level": 1}
           ],
           "enemies": [
               {"type": "basic_enemy", "count": 10}
           ],
           "expected_behavior": "攻击有20%概率造成1秒眩晕"
       }

   "test_kestrel_lv3_sonic":
       return {
           "id": "test_kestrel_lv3_sonic",
           "core_type": "eagle_totem",
           "duration": 25.0,
           "units": [
               {"id": "kestrel", "x": 0, "y": 1, "level": 3}
           ],
           "enemies": [
               {"type": "basic_enemy", "count": 3, "positions": [{"x": 2, "y": 0}, {"x": 2, "y": 1}]}
           ],
           "expected_behavior": "眩晕触发时造成小范围震荡伤害"
       }
   ```

3. **运行测试验证**:
   ```bash
   for test in test_kestrel_lv1_dive test_kestrel_lv3_sonic; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```

4. **更新测试进度**:
   测试完成后，更新 `docs/test_progress.md` 中红隼的验证指标。

## 进度更新要求

完成每个测试场景后，更新 `docs/progress.md`:

```markdown
| TEST-EAGLE-kestrel | in_progress | 添加Lv1俯冲眩晕测试 | 2026-02-20T14:30:00 |
| TEST-EAGLE-kestrel | in_progress | 添加Lv3音爆测试 | 2026-02-20T14:45:00 |
| TEST-EAGLE-kestrel | completed | 所有测试通过 | 2026-02-20T15:00:00 |
```

同时在 `docs/test_progress.md` 中更新验证指标:
```markdown
**验证指标**:
- [x] 眩晕概率20%
- [x] 眩晕持续1秒
- [x] 眩晕概率30%（Lv2）
- [x] 眩晕时间1.2秒（Lv2）
- [x] 眩晕时触发范围伤害（Lv3）
- [x] 范围内敌人受到伤害（Lv3）

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
- `src/Scripts/Units/EagleTotem/Kestrel.gd` - 单位实现

## Task ID

Task being executed: TEST-EAGLE-kestrel
