# Jules 任务: 狐狸 (Fox) 自动化测试

## 任务ID
TEST-WOLF-FOX

## 任务描述
为狼图腾流派单位"狐狸"创建完整的自动化测试用例，添加到 `src/Scripts/Tests/TestSuite.gd`，并确保所有测试能在Headless模式下通过。

## 单位信息

| 属性 | 值 |
|------|-----|
| 单位ID | fox |
| 中文名 | 狐狸 |
| 核心机制 | 魅惑 - 被攻击敌人概率为我方作战 |
| 图腾类型 | wolf_totem |

## 详细测试场景

### 测试场景 1: Lv1 魅惑验证

**测试ID**: `test_fox_lv1_charm`

**测试配置**:
```gdscript
"test_fox_lv1_charm":
    return {
        "id": "test_fox_lv1_charm",
        "core_type": "wolf_totem",
        "duration": 30.0,
        "units": [
            {"id": "fox", "x": 0, "y": 1, "level": 1}
        ],
        "enemies": [
            {"type": "basic_enemy", "count": 10}
        ],
        "expected_behavior": "被攻击敌人有20%概率获得1层魂魄为你作战3秒"
    }
```

**验证指标**:
- [ ] 魅惑概率为20%
- [ ] 魅惑持续3秒
- [ ] 被魅惑敌人为我方作战
- [ ] 魅惑期间敌人攻击其他敌人

### 测试场景 2: Lv2 献祭魅惑验证

**测试ID**: `test_fox_lv2_sacrifice`

**测试配置**:
```gdscript
"test_fox_lv2_sacrifice":
    return {
        "id": "test_fox_lv2_sacrifice",
        "core_type": "wolf_totem",
        "duration": 35.0,
        "units": [
            {"id": "fox", "x": 0, "y": 1, "level": 2},
            {"id": "squirrel", "x": 1, "y": 0}
        ],
        "enemies": [
            {"type": "weak_enemy", "count": 5, "hp": 30}
        ],
        "expected_behavior": "魅惑敌人被核心击杀时获得1层血魂"
    }
```

**验证指标**:
- [ ] 魅惑敌人被友方击杀时获得血魂
- [ ] 血魂层数正确增加
- [ ] 魅惑效果结束后击杀不获得血魂

### 测试场景 3: Lv3 群体魅惑验证

**测试ID**: `test_fox_lv3_charm`

**测试配置**:
```gdscript
"test_fox_lv3_charm":
    return {
        "id": "test_fox_lv3_charm",
        "core_type": "wolf_totem",
        "duration": 30.0,
        "units": [
            {"id": "fox", "x": 0, "y": 1, "level": 3}
        ],
        "enemies": [
            {"type": "basic_enemy", "count": 5}
        ],
        "expected_behavior": "可同时魅惑2个敌人"
    }
```

**验证指标**:
- [ ] 可同时魅惑2个敌人
- [ ] 两个敌人同时为我方作战
- [ ] 魅惑概率仍为20%

## 实现要求

1. **添加到 TestSuite.gd**: 在 `get_test_config` 函数的 match 语句中添加以上3个测试用例

2. **测试运行验证**: 每个测试用例必须能通过 Headless 模式运行：
   ```bash
   godot --path . --headless -- --run-test=test_fox_lv1_charm
   godot --path . --headless -- --run-test=test_fox_lv2_sacrifice
   godot --path . --headless -- --run-test=test_fox_lv3_charm
   ```

3. **通过标准**:
   - 退出码为 0
   - 无 SCRIPT ERROR
   - 测试日志正常生成

4. **更新测试进度**: 测试完成后，更新 `docs/test_progress.md`:
   - 将 `[ ]` 标记为 `[x]` 表示测试通过
   - 更新测试进度概览表
   - 添加测试记录

## 实现步骤

1. 阅读现有 `src/Scripts/Tests/TestSuite.gd` 了解测试配置格式
2. 阅读 `docs/test_progress.md` 了解详细测试场景
3. 在 TestSuite.gd 中添加以上3个测试用例
4. 运行测试验证：
   ```bash
   for test in test_fox_lv1_charm test_fox_lv2_sacrifice test_fox_lv3_charm; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```
5. 更新 `docs/test_progress.md` 中的测试进度

## 代码提交要求

1. 在独立分支上工作：`feature/TEST-WOLF-FOX`
2. 提交信息格式：`[TEST-WOLF-FOX] Add automated tests for Fox unit`
3. 完成后创建 Pull Request 到 main 分支

## 进度同步

完成每个测试用例后，更新 `docs/progress.md`：

```markdown
| TEST-WOLF-FOX | in_progress | 添加狐狸Lv1魅惑测试 | 2026-02-20T14:30:00 |
```

## 相关文档

- `docs/test_progress.md` - 详细测试场景规范
- `docs/roles/qa_engineer.md` - 测试工程师角色指南
- `src/Scripts/Tests/AutomatedTestRunner.gd` - 测试运行器
- `src/Scripts/Tests/TestSuite.gd` - 测试配置
- `docs/GameDesign.md` - 狐狸单位设计文档

## Task ID

Task being executed: TEST-WOLF-FOX
