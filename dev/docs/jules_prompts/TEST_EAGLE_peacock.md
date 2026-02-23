# Jules 任务: 孔雀 (peacock) 自动化测试

## 任务ID
TEST-EAGLE-peacock

## 任务描述
为孔雀单位创建完整的自动化测试用例，验证其屏开伤害机制，确保能在Headless模式下通过。

## 核心机制
**屏开伤害**: 范围攻速加成

## 测试场景

### 测试场景 1: Lv1 开屏验证
```gdscript
{
    "id": "test_peacock_lv1_display",
    "core_type": "eagle_totem",
    "duration": 20.0,
    "units": [
        {"id": "peacock", "x": 0, "y": 1, "level": 1},
        {"id": "squirrel", "x": 1, "y": 0}  # 范围内友军
    ],
    "expected_behavior": {
        "description": "每5秒展开尾屏，范围内友军攻速+10%",
        "verification": "每5秒松鼠攻速提升10%持续一定时间"
    }
}
```

**验证指标**:
- [ ] 每5秒触发一次
- [ ] 范围内友军攻速+10%

### 测试场景 2: Lv2 效果和范围提升验证
**验证指标**:
- [ ] 攻速加成+20%
- [ ] 范围扩大

### 测试场景 3: Lv3 鼓舞验证
```gdscript
{
    "id": "test_peacock_lv3_inspire",
    "core_type": "eagle_totem",
    "duration": 25.0,
    "units": [
        {"id": "peacock", "x": 0, "y": 1, "level": 3},
        {"id": "squirrel", "x": 1, "y": 0}
    ],
    "enemies": [
        {"type": "buffed_enemy", "buffs": [{"type": "armor", "stacks": 3}], "count": 3}
    ],
    "expected_behavior": {
        "description": "范围内友军攻击附带驱散效果",
        "verification": "松鼠攻击驱散敌人的Buff"
    }
}
```

**验证指标**:
- [ ] 攻击附带驱散
- [ ] 驱散敌人Buff

## Headless测试配置

### 测试运行命令
```bash
# Lv1 开屏测试
godot --path . --headless -- --run-test=test_peacock_lv1_display

# Lv3 鼓舞测试
godot --path . --headless -- --run-test=test_peacock_lv3_inspire
```

### 通过标准
- 退出码为 0
- 无 SCRIPT ERROR
- 测试日志正常生成

## 实现步骤

1. **阅读现有代码**:
   - 阅读 `src/Scripts/Tests/TestSuite.gd` 了解测试配置格式
   - 阅读 `src/Scripts/Units/EagleTotem/Peacock.gd` 了解单位实现

2. **添加测试用例**:
   在 `TestSuite.gd` 的 `get_test_config` 函数中添加:
   ```gdscript
   "test_peacock_lv1_display":
       return {
           "id": "test_peacock_lv1_display",
           "core_type": "eagle_totem",
           "duration": 20.0,
           "units": [
               {"id": "peacock", "x": 0, "y": 1, "level": 1},
               {"id": "squirrel", "x": 1, "y": 0}
           ],
           "expected_behavior": "每5秒展开尾屏，范围内友军攻速+10%"
       }

   "test_peacock_lv3_inspire":
       return {
           "id": "test_peacock_lv3_inspire",
           "core_type": "eagle_totem",
           "duration": 25.0,
           "units": [
               {"id": "peacock", "x": 0, "y": 1, "level": 3},
               {"id": "squirrel", "x": 1, "y": 0}
           ],
           "enemies": [
               {"type": "buffed_enemy", "buffs": [{"type": "armor", "stacks": 3}], "count": 3}
           ],
           "expected_behavior": "范围内友军攻击附带驱散效果"
       }
   ```

3. **运行测试验证**:
   ```bash
   for test in test_peacock_lv1_display test_peacock_lv3_inspire; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```

4. **更新测试进度**:
   测试完成后，更新 `docs/test_progress.md` 中孔雀的验证指标。

## 进度更新要求

完成每个测试场景后，更新 `docs/progress.md`:

```markdown
| TEST-EAGLE-peacock | in_progress | 添加Lv1开屏测试 | 2026-02-20T14:30:00 |
| TEST-EAGLE-peacock | in_progress | 添加Lv3鼓舞测试 | 2026-02-20T14:45:00 |
| TEST-EAGLE-peacock | completed | 所有测试通过 | 2026-02-20T15:00:00 |
```

同时在 `docs/test_progress.md` 中更新验证指标:
```markdown
**验证指标**:
- [x] 每5秒触发一次
- [x] 范围内友军攻速+10%
- [x] 攻速加成+20%（Lv2）
- [x] 范围扩大（Lv2）
- [x] 攻击附带驱散（Lv3）
- [x] 驱散敌人Buff（Lv3）

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
- `src/Scripts/Units/EagleTotem/Peacock.gd` - 单位实现

## Task ID

Task being executed: TEST-EAGLE-peacock
