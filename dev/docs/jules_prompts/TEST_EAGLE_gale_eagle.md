# Jules 任务: 疾风鹰 (gale_eagle) 自动化测试

## 任务ID
TEST-EAGLE-gale_eagle

## 任务描述
为疾风鹰单位创建完整的自动化测试用例，验证其直线穿透机制，确保能在Headless模式下通过。

## 核心机制
**直线穿透**: 多道风刃

## 测试场景

### 测试场景 1: Lv1 风刃连击验证
```gdscript
{
    "id": "test_gale_eagle_lv1_wind",
    "core_type": "eagle_totem",
    "duration": 15.0,
    "units": [
        {"id": "gale_eagle", "x": 0, "y": 1, "level": 1, "attack": 100}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3}
    ],
    "expected_behavior": {
        "description": "每次攻击发射2道风刃，每道60%伤害",
        "verification": "每次攻击造成2次60点伤害"
    }
}
```

**验证指标**:
- [ ] 每次攻击2道风刃
- [ ] 每道60%伤害

### 测试场景 2: Lv2 风刃数量和伤害提升验证
**验证指标**:
- [ ] 风刃数量3道
- [ ] 每道80%伤害

### 测试场景 3: Lv3 风刃暴击验证
**验证指标**:
- [ ] 风刃可暴击
- [ ] 暴击触发图腾回响

## Headless测试配置

### 测试运行命令
```bash
# Lv1 风刃连击测试
godot --path . --headless -- --run-test=test_gale_eagle_lv1_wind

# Lv2 风刃数量和伤害提升测试
godot --path . --headless -- --run-test=test_gale_eagle_lv2_wind

# Lv3 风刃暴击测试
godot --path . --headless -- --run-test=test_gale_eagle_lv3_crit
```

### 通过标准
- 退出码为 0
- 无 SCRIPT ERROR
- 测试日志正常生成

## 实现步骤

1. **阅读现有代码**:
   - 阅读 `src/Scripts/Tests/TestSuite.gd` 了解测试配置格式
   - 阅读 `src/Scripts/Units/EagleTotem/GaleEagle.gd` 了解单位实现

2. **添加测试用例**:
   在 `TestSuite.gd` 的 `get_test_config` 函数中添加:
   ```gdscript
   "test_gale_eagle_lv1_wind":
       return {
           "id": "test_gale_eagle_lv1_wind",
           "core_type": "eagle_totem",
           "duration": 15.0,
           "units": [
               {"id": "gale_eagle", "x": 0, "y": 1, "level": 1, "attack": 100}
           ],
           "enemies": [
               {"type": "basic_enemy", "count": 3}
           ],
           "expected_behavior": "每次攻击发射2道风刃，每道60%伤害"
       }

   "test_gale_eagle_lv2_wind":
       return {
           "id": "test_gale_eagle_lv2_wind",
           "core_type": "eagle_totem",
           "duration": 15.0,
           "units": [
               {"id": "gale_eagle", "x": 0, "y": 1, "level": 2, "attack": 100}
           ],
           "enemies": [
               {"type": "basic_enemy", "count": 3}
           ],
           "expected_behavior": "每次攻击发射3道风刃，每道80%伤害"
       }

   "test_gale_eagle_lv3_crit":
       return {
           "id": "test_gale_eagle_lv3_crit",
           "core_type": "eagle_totem",
           "duration": 15.0,
           "units": [
               {"id": "gale_eagle", "x": 0, "y": 1, "level": 3, "attack": 100}
           ],
           "enemies": [
               {"type": "basic_enemy", "count": 3}
           ],
           "expected_behavior": "风刃可暴击并触发图腾回响"
       }
   ```

3. **运行测试验证**:
   ```bash
   for test in test_gale_eagle_lv1_wind test_gale_eagle_lv2_wind test_gale_eagle_lv3_crit; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```

4. **更新测试进度**:
   测试完成后，更新 `docs/test_progress.md` 中疾风鹰的验证指标。

## 进度更新要求

完成每个测试场景后，更新 `docs/progress.md`:

```markdown
| TEST-EAGLE-gale_eagle | in_progress | 添加Lv1风刃连击测试 | 2026-02-20T14:30:00 |
| TEST-EAGLE-gale_eagle | in_progress | 添加Lv2风刃数量和伤害提升测试 | 2026-02-20T14:40:00 |
| TEST-EAGLE-gale_eagle | in_progress | 添加Lv3风刃暴击测试 | 2026-02-20T14:50:00 |
| TEST-EAGLE-gale_eagle | completed | 所有测试通过 | 2026-02-20T15:00:00 |
```

同时在 `docs/test_progress.md` 中更新验证指标:
```markdown
**验证指标**:
- [x] 每次攻击2道风刃
- [x] 每道60%伤害
- [x] 风刃数量3道（Lv2）
- [x] 每道80%伤害（Lv2）
- [x] 风刃可暴击（Lv3）
- [x] 暴击触发图腾回响（Lv3）

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
- `src/Scripts/Units/EagleTotem/GaleEagle.gd` - 单位实现

## Task ID

Task being executed: TEST-EAGLE-gale_eagle
