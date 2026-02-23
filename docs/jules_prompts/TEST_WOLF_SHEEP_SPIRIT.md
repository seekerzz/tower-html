# Jules 任务: 羊灵 (Sheep Spirit) 自动化测试

## 任务ID
TEST-WOLF-SHEEP-SPIRIT

## 任务描述
为狼图腾流派单位"羊灵"创建完整的自动化测试用例，添加到 `src/Scripts/Tests/TestSuite.gd`，并确保所有测试能在Headless模式下通过。

## 单位信息

| 属性 | 值 |
|------|-----|
| 单位ID | sheep_spirit |
| 中文名 | 羊灵 |
| 核心机制 | 羊灵克隆 - 敌人阵亡时复制克隆体 |
| 图腾类型 | wolf_totem |

## 详细测试场景

### 测试场景 1: Lv1 克隆验证

**测试ID**: `test_sheep_spirit_lv1_clone`

**测试配置**:
```gdscript
"test_sheep_spirit_lv1_clone":
    return {
        "id": "test_sheep_spirit_lv1_clone",
        "core_type": "wolf_totem",
        "duration": 25.0,
        "units": [
            {"id": "sheep_spirit", "x": 0, "y": 1, "level": 1}
        ],
        "enemies": [
            {"type": "weak_enemy", "count": 3, "hp": 50, "positions": [{"x": 1, "y": 1}, {"x": 2, "y": 0}]}
        ],
        "expected_behavior": "附近敌人阵亡时复制1个40%属性的克隆体为你作战"
    }
```

**验证指标**:
- [ ] 敌人阵亡时生成克隆体
- [ ] 克隆体属性为原敌人的40%
- [ ] 克隆体为我方作战
- [ ] 克隆体攻击敌人

### 测试场景 2: Lv2 属性提升验证

**测试ID**: `test_sheep_spirit_lv2_clone`

**测试配置**:
```gdscript
"test_sheep_spirit_lv2_clone":
    return {
        "id": "test_sheep_spirit_lv2_clone",
        "core_type": "wolf_totem",
        "duration": 25.0,
        "units": [
            {"id": "sheep_spirit", "x": 0, "y": 1, "level": 2}
        ],
        "enemies": [
            {"type": "weak_enemy", "count": 3, "hp": 50}
        ],
        "expected_behavior": "附近敌人阵亡时复制1个60%属性的克隆体为你作战"
    }
```

**验证指标**:
- [ ] 克隆体属性为原敌人的60%
- [ ] 比Lv1的克隆体更强

### 测试场景 3: Lv3 双克隆验证

**测试ID**: `test_sheep_spirit_lv3_clone`

**测试配置**:
```gdscript
"test_sheep_spirit_lv3_clone":
    return {
        "id": "test_sheep_spirit_lv3_clone",
        "core_type": "wolf_totem",
        "duration": 25.0,
        "units": [
            {"id": "sheep_spirit", "x": 0, "y": 1, "level": 3}
        ],
        "enemies": [
            {"type": "weak_enemy", "count": 2, "hp": 50}
        ],
        "expected_behavior": "附近敌人阵亡时复制2个60%属性的克隆体为你作战"
    }
```

**验证指标**:
- [ ] 生成2个克隆体
- [ ] 每个克隆体属性为60%
- [ ] 两个克隆体都为我方作战

## 实现要求

1. **添加到 TestSuite.gd**: 在 `get_test_config` 函数的 match 语句中添加以上3个测试用例

2. **测试运行验证**: 每个测试用例必须能通过 Headless 模式运行：
   ```bash
   godot --path . --headless -- --run-test=test_sheep_spirit_lv1_clone
   godot --path . --headless -- --run-test=test_sheep_spirit_lv2_clone
   godot --path . --headless -- --run-test=test_sheep_spirit_lv3_clone
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
   for test in test_sheep_spirit_lv1_clone test_sheep_spirit_lv2_clone test_sheep_spirit_lv3_clone; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```
5. 更新 `docs/test_progress.md` 中的测试进度

## 代码提交要求

1. 在独立分支上工作：`feature/TEST-WOLF-SHEEP-SPIRIT`
2. 提交信息格式：`[TEST-WOLF-SHEEP-SPIRIT] Add automated tests for Sheep Spirit unit`
3. 完成后创建 Pull Request 到 main 分支

## 进度同步

完成每个测试用例后，更新 `docs/progress.md`：

```markdown
| TEST-WOLF-SHEEP-SPIRIT | in_progress | 添加羊灵Lv1克隆测试 | 2026-02-20T14:30:00 |
```

## 相关文档

- `docs/test_progress.md` - 详细测试场景规范
- `docs/roles/qa_engineer.md` - 测试工程师角色指南
- `src/Scripts/Tests/AutomatedTestRunner.gd` - 测试运行器
- `src/Scripts/Tests/TestSuite.gd` - 测试配置
- `docs/GameDesign.md` - 羊灵单位设计文档

## Task ID

Task being executed: TEST-WOLF-SHEEP-SPIRIT
