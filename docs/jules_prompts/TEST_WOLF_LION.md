# Jules 任务: 狮子 (Lion) 自动化测试

## 任务ID
TEST-WOLF-LION

## 任务描述
为狼图腾流派单位"狮子"创建完整的自动化测试用例，添加到 `src/Scripts/Tests/TestSuite.gd`，并确保所有测试能在Headless模式下通过。

## 单位信息

| 属性 | 值 |
|------|-----|
| 单位ID | lion |
| 中文名 | 狮子 |
| 核心机制 | 王者威严/冲击波 - 圆形范围攻击 |
| 图腾类型 | wolf_totem |

## 详细测试场景

### 测试场景 1: Lv1 冲击波验证

**测试ID**: `test_lion_lv1_shockwave`

**测试配置**:
```gdscript
"test_lion_lv1_shockwave":
    return {
        "id": "test_lion_lv1_shockwave",
        "core_type": "wolf_totem",
        "duration": 15.0,
        "units": [
            {"id": "lion", "x": 0, "y": 1, "level": 1}
        ],
        "enemies": [
            {"type": "basic_enemy", "count": 5, "positions": [{"x": 2, "y": 1}, {"x": -1, "y": 1}, {"x": 0, "y": 2}]}
        ],
        "expected_behavior": "攻击变为圆形冲击波，对范围内所有敌人造成伤害"
    }
```

**验证指标**:
- [ ] 攻击为圆形冲击波
- [ ] 冲击波对范围内所有敌人造成伤害
- [ ] 多个敌人同时受到伤害

### 测试场景 2: Lv2 威压回蓝验证

**测试ID**: `test_lion_lv2_mana`

**测试配置**:
```gdscript
"test_lion_lv2_mana":
    return {
        "id": "test_lion_lv2_mana",
        "core_type": "wolf_totem",
        "duration": 20.0,
        "initial_mp": 500,
        "units": [
            {"id": "lion", "x": 0, "y": 1, "level": 2}
        ],
        "enemies": [
            {"type": "basic_enemy", "count": 5, "positions": [{"x": 2, "y": 0}, {"x": 2, "y": 1}, {"x": 2, "y": 2}]}
        ],
        "expected_behavior": "冲击波命中敌人时，所有友方恢复5点法力；命中3个以上额外恢复10点"
    }
```

**验证指标**:
- [ ] 命中敌人时所有友方回蓝5点
- [ ] 命中3个以上额外回蓝10点
- [ ] 回蓝量正确计算
- [ ] 回蓝效果应用于所有友方单位

### 测试场景 3: Lv3 狮吼恐惧验证

**测试ID**: `test_lion_lv3_fear`

**测试配置**:
```gdscript
"test_lion_lv3_fear":
    return {
        "id": "test_lion_lv3_fear",
        "core_type": "wolf_totem",
        "duration": 20.0,
        "units": [
            {"id": "lion", "x": 0, "y": 1, "level": 3}
        ],
        "enemies": [
            {"type": "basic_enemy", "count": 3}
        ],
        "expected_behavior": "冲击波附加1秒恐惧效果，敌人朝随机方向逃跑"
    }
```

**验证指标**:
- [ ] 冲击波附加恐惧效果
- [ ] 恐惧持续1秒
- [ ] 恐惧时敌人朝反方向逃跑
- [ ] 恐惧结束后敌人恢复正常行为

## 实现要求

1. **添加到 TestSuite.gd**: 在 `get_test_config` 函数的 match 语句中添加以上3个测试用例

2. **测试运行验证**: 每个测试用例必须能通过 Headless 模式运行：
   ```bash
   godot --path . --headless -- --run-test=test_lion_lv1_shockwave
   godot --path . --headless -- --run-test=test_lion_lv2_mana
   godot --path . --headless -- --run-test=test_lion_lv3_fear
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
   for test in test_lion_lv1_shockwave test_lion_lv2_mana test_lion_lv3_fear; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```
5. 更新 `docs/test_progress.md` 中的测试进度

## 代码提交要求

1. 在独立分支上工作：`feature/TEST-WOLF-LION`
2. 提交信息格式：`[TEST-WOLF-LION] Add automated tests for Lion unit`
3. 完成后创建 Pull Request 到 main 分支

## 进度同步

完成每个测试用例后，更新 `docs/progress.md`：

```markdown
| TEST-WOLF-LION | in_progress | 添加狮子Lv1冲击波测试 | 2026-02-20T14:30:00 |
```

## 相关文档

- `docs/test_progress.md` - 详细测试场景规范
- `docs/roles/qa_engineer.md` - 测试工程师角色指南
- `src/Scripts/Tests/AutomatedTestRunner.gd` - 测试运行器
- `src/Scripts/Tests/TestSuite.gd` - 测试配置
- `docs/GameDesign.md` - 狮子单位设计文档

## Task ID

Task being executed: TEST-WOLF-LION
