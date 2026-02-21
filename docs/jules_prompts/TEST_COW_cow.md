# Jules 任务: 奶牛 (cow) 自动化测试

## 任务ID
TEST-COW-cow

## 任务描述
为奶牛单位创建完整的自动化测试用例，验证其产奶回血机制，确保能在Headless模式下通过。

## 核心机制
**周期性治疗核心**: 每波/每隔一段时间回复核心HP

## 测试场景

### 测试场景 1: Lv1 产奶治疗验证
```gdscript
{
    "id": "test_cow_lv1_heal",
    "core_type": "cow_totem",
    "duration": 20.0,
    "core_health": 400,
    "max_core_health": 500,
    "units": [
        {"id": "cow", "x": 0, "y": 1, "level": 1}
    ],
    "expected_behavior": {
        "description": "每5秒回复1%核心HP",
        "verification": "观察核心血量每5秒增加5点(500×1%)"
    }
}
```

**验证指标**:
- [ ] 治疗间隔为5秒
- [ ] 治疗量为最大核心血量的1%

### 测试场景 2: Lv2 治疗频率提升验证
**验证指标**:
- [ ] 治疗间隔缩短至4秒

### 测试场景 3: Lv3 损失血量额外治疗验证
```gdscript
{
    "id": "test_cow_lv3_heal_boost",
    "core_type": "cow_totem",
    "duration": 25.0,
    "core_health": 250,
    "max_core_health": 500,
    "units": [
        {"id": "cow", "x": 0, "y": 1, "level": 3}
    ],
    "expected_behavior": {
        "description": "根据核心已损失血量额外回复",
        "verification": "血量越低，每次治疗量越高"
    }
}
```

**验证指标**:
- [ ] 核心损失50%血量时，治疗量增加
- [ ] 治疗量与损失血量百分比相关

## Headless测试配置

### 测试运行命令
```bash
# Lv1 产奶治疗测试
godot --path . --headless -- --run-test=test_cow_lv1_heal

# Lv3 损失血量额外治疗测试
godot --path . --headless -- --run-test=test_cow_lv3_heal_boost
```

### 通过标准
- 退出码为 0
- 无 SCRIPT ERROR
- 测试日志正常生成

## 实现步骤

1. **阅读现有代码**:
   - 阅读 `src/Scripts/Tests/TestSuite.gd` 了解测试配置格式
   - 阅读 `src/Scripts/Units/CowTotem/Cow.gd` 了解单位实现

2. **添加测试用例**:
   在 `TestSuite.gd` 的 `get_test_config` 函数中添加:
   ```gdscript
   "test_cow_lv1_heal":
       return {
           "id": "test_cow_lv1_heal",
           "core_type": "cow_totem",
           "duration": 20.0,
           "core_health": 400,
           "max_core_health": 500,
           "units": [
               {"id": "cow", "x": 0, "y": 1, "level": 1}
           ],
           "expected_behavior": "每5秒回复1%核心HP"
       }

   "test_cow_lv3_heal_boost":
       return {
           "id": "test_cow_lv3_heal_boost",
           "core_type": "cow_totem",
           "duration": 25.0,
           "core_health": 250,
           "max_core_health": 500,
           "units": [
               {"id": "cow", "x": 0, "y": 1, "level": 3}
           ],
           "expected_behavior": "根据核心已损失血量额外回复"
       }
   ```

3. **运行测试验证**:
   ```bash
   for test in test_cow_lv1_heal test_cow_lv3_heal_boost; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```

4. **更新测试进度**:
   测试完成后，更新 `docs/test_progress.md` 中奶牛的验证指标。

## 进度更新要求

完成每个测试场景后，更新 `docs/progress.md`:

```markdown
| TEST-COW-cow | in_progress | 添加Lv1产奶治疗测试 | 2026-02-20T14:30:00 |
| TEST-COW-cow | in_progress | 添加Lv3损失血量额外治疗测试 | 2026-02-20T14:45:00 |
| TEST-COW-cow | completed | 所有测试通过 | 2026-02-20T15:00:00 |
```

同时在 `docs/test_progress.md` 中更新验证指标:
```markdown
**验证指标**:
- [x] 治疗间隔为5秒
- [x] 治疗量为最大核心血量的1%
- [x] 治疗间隔缩短至4秒（Lv2）
- [x] 核心损失50%血量时，治疗量增加（Lv3）
- [x] 治疗量与损失血量百分比相关（Lv3）

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
- `src/Scripts/Units/CowTotem/Cow.gd` - 单位实现

## Task ID

Task being executed: TEST-COW-cow
