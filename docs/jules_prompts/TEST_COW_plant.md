# Jules 任务: 树苗 (plant) 自动化测试

## 任务ID
TEST-COW-plant

## 任务描述
为树苗单位创建完整的自动化测试用例，验证其成长机制，确保能在Headless模式下通过。

## 核心机制
**扎根成长**: 每波增加自身Max HP，Lv3提供范围加成

## 测试场景

### 测试场景 1: Lv1 扎根成长验证
```gdscript
{
    "id": "test_plant_lv1_growth",
    "core_type": "cow_totem",
    "duration": 60.0,
    "start_wave_index": 1,
    "units": [
        {"id": "plant", "x": 0, "y": 1, "level": 1, "initial_hp": 100}
    ],
    "scheduled_actions": [
        {"time": 5.0, "type": "end_wave"},
        {"time": 10.0, "type": "verify_hp", "expected_hp_percent": 1.05}
    ],
    "expected_behavior": {
        "description": "每波结束后自身Max HP+5%",
        "verification": "波次结束后检查血量是否增加"
    }
}
```

**验证指标**:
- [ ] 每波结束后最大血量增加5%
- [ ] 当前血量同步增加

### 测试场景 2: Lv2 成长速度提升验证
**验证指标**:
- [ ] 每波最大血量增加8%

### 测试场景 3: Lv3 世界树范围加成验证
```gdscript
{
    "id": "test_plant_lv3_world_tree",
    "core_type": "cow_totem",
    "duration": 30.0,
    "units": [
        {"id": "plant", "x": 0, "y": 1, "level": 3},
        {"id": "squirrel", "x": 1, "y": 0, "initial_hp": 100},
        {"id": "bee", "x": 0, "y": 2, "initial_hp": 80}
    ],
    "scheduled_actions": [
        {"time": 5.0, "type": "end_wave"},
        {"time": 10.0, "type": "verify_hp", "target": "squirrel", "expected_hp_percent": 1.05}
    ],
    "expected_behavior": {
        "description": "周围一圈单位Max HP加成5%",
        "verification": "周围友方单位血量增加5%"
    }
}
```

**验证指标**:
- [ ] 周围一圈友方单位最大血量增加5%
- [ ] 效果每波触发

## Headless测试配置

### 测试运行命令
```bash
# Lv1 扎根成长测试
godot --path . --headless -- --run-test=test_plant_lv1_growth

# Lv3 世界树范围加成测试
godot --path . --headless -- --run-test=test_plant_lv3_world_tree
```

### 通过标准
- 退出码为 0
- 无 SCRIPT ERROR
- 测试日志正常生成

## 实现步骤

1. **阅读现有代码**:
   - 阅读 `src/Scripts/Tests/TestSuite.gd` 了解测试配置格式
   - 阅读 `src/Scripts/Units/CowTotem/Plant.gd` 了解单位实现

2. **添加测试用例**:
   在 `TestSuite.gd` 的 `get_test_config` 函数中添加:
   ```gdscript
   "test_plant_lv1_growth":
       return {
           "id": "test_plant_lv1_growth",
           "core_type": "cow_totem",
           "duration": 60.0,
           "start_wave_index": 1,
           "units": [
               {"id": "plant", "x": 0, "y": 1, "level": 1, "initial_hp": 100}
           ],
           "expected_behavior": "每波结束后自身Max HP+5%"
       }

   "test_plant_lv3_world_tree":
       return {
           "id": "test_plant_lv3_world_tree",
           "core_type": "cow_totem",
           "duration": 30.0,
           "units": [
               {"id": "plant", "x": 0, "y": 1, "level": 3},
               {"id": "squirrel", "x": 1, "y": 0, "initial_hp": 100},
               {"id": "bee", "x": 0, "y": 2, "initial_hp": 80}
           ],
           "expected_behavior": "周围一圈单位Max HP加成5%"
       }
   ```

3. **运行测试验证**:
   ```bash
   for test in test_plant_lv1_growth test_plant_lv3_world_tree; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```

4. **更新测试进度**:
   测试完成后，更新 `docs/test_progress.md` 中树苗的验证指标。

## 进度更新要求

完成每个测试场景后，更新 `docs/progress.md`:

```markdown
| TEST-COW-plant | in_progress | 添加Lv1扎根成长测试 | 2026-02-20T14:30:00 |
| TEST-COW-plant | in_progress | 添加Lv3世界树范围加成测试 | 2026-02-20T14:45:00 |
| TEST-COW-plant | completed | 所有测试通过 | 2026-02-20T15:00:00 |
```

同时在 `docs/test_progress.md` 中更新验证指标:
```markdown
**验证指标**:
- [x] 每波结束后最大血量增加5%
- [x] 当前血量同步增加
- [x] 每波最大血量增加8%（Lv2）
- [x] 周围一圈友方单位最大血量增加5%（Lv3）
- [x] 效果每波触发

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
- `src/Scripts/Units/CowTotem/Plant.gd` - 单位实现

## Task ID

Task being executed: TEST-COW-plant
