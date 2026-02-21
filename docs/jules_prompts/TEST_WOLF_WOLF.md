# Jules 任务: 狼 (Wolf) 自动化测试

## 任务ID
TEST-WOLF-WOLF

## 任务描述
为狼图腾流派单位"狼"创建完整的自动化测试用例，添加到 `src/Scripts/Tests/TestSuite.gd`，并确保所有测试能在Headless模式下通过。

## 单位信息

| 属性 | 值 |
|------|-----|
| 单位ID | wolf |
| 中文名 | 狼 |
| 核心机制 | 吞噬继承 - 登场时吞噬单位继承其属性 |
| 图腾类型 | wolf_totem |

## 详细测试场景

### 测试场景 1: Lv1 吞噬继承验证

**测试ID**: `test_wolf_lv1_devour`

**测试配置**:
```gdscript
"test_wolf_lv1_devour":
    return {
        "id": "test_wolf_lv1_devour",
        "core_type": "wolf_totem",
        "duration": 20.0,
        "units": [
            {"id": "wolf", "x": 0, "y": 1, "level": 1},
            {"id": "squirrel", "x": 1, "y": 0}
        ],
        "setup_actions": [
            {"type": "devour", "source": "wolf", "target": "squirrel"}
        ],
        "expected_behavior": "登场时吞噬一个单位，继承50%攻击力和血量及攻击机制"
    }
```

**验证指标**:
- [ ] 必须选择一个单位吞噬
- [ ] 继承被吞噬单位50%攻击力
- [ ] 继承被吞噬单位50%血量
- [ ] 继承被吞噬单位的攻击机制

### 测试场景 2: Lv2 双重继承验证

**测试ID**: `test_wolf_lv2_dual_inherit`

**测试配置**:
```gdscript
"test_wolf_lv2_dual_inherit":
    return {
        "id": "test_wolf_lv2_dual_inherit",
        "core_type": "wolf_totem",
        "duration": 25.0,
        "units": [
            {"id": "wolf", "x": 0, "y": 1, "level": 1},
            {"id": "wolf2", "x": 1, "y": 0, "level": 1, "devoured": "bee"},
            {"id": "squirrel", "x": -1, "y": 0}
        ],
        "setup_actions": [
            {"type": "devour", "source": "wolf", "target": "squirrel"},
            {"type": "merge", "source": "wolf", "target": "wolf2"}
        ],
        "expected_behavior": "合并升级时保留两只狼各自的攻击机制"
    }
```

**验证指标**:
- [ ] 合并后保留两只狼的继承机制
- [ ] 可以同时使用两种攻击方式
- [ ] 升级后的狼同时拥有松鼠和蜜蜂的攻击方式

### 测试场景 3: Lv3 不可升级验证

**测试ID**: `test_wolf_lv3_limit`

**测试配置**:
```gdscript
"test_wolf_lv3_limit":
    return {
        "id": "test_wolf_lv3_limit",
        "core_type": "wolf_totem",
        "duration": 15.0,
        "units": [
            {"id": "wolf", "x": 0, "y": 1, "level": 2},
            {"id": "wolf2", "x": 1, "y": 0, "level": 2}
        ],
        "setup_actions": [
            {"type": "merge", "source": "wolf", "target": "wolf2"}
        ],
        "expected_behavior": "狼无法升到Lv.3，合并时最多到Lv.2"
    }
```

**验证指标**:
- [ ] 狼无法升到Lv.3
- [ ] 合并时最多到Lv.2
- [ ] 两只Lv.2狼合并后仍为Lv.2

## 实现要求

1. **添加到 TestSuite.gd**: 在 `get_test_config` 函数的 match 语句中添加以上3个测试用例

2. **测试运行验证**: 每个测试用例必须能通过 Headless 模式运行：
   ```bash
   godot --path . --headless -- --run-test=test_wolf_lv1_devour
   godot --path . --headless -- --run-test=test_wolf_lv2_dual_inherit
   godot --path . --headless -- --run-test=test_wolf_lv3_limit
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
   for test in test_wolf_lv1_devour test_wolf_lv2_dual_inherit test_wolf_lv3_limit; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```
5. 更新 `docs/test_progress.md` 中的测试进度

## 代码提交要求

1. 在独立分支上工作：`feature/TEST-WOLF-WOLF`
2. 提交信息格式：`[TEST-WOLF-WOLF] Add automated tests for Wolf unit`
3. 完成后创建 Pull Request 到 main 分支

## 进度同步

完成每个测试用例后，更新 `docs/progress.md`：

```markdown
| TEST-WOLF-WOLF | in_progress | 添加狼Lv1吞噬继承测试 | 2026-02-20T14:30:00 |
```

## 相关文档

- `docs/test_progress.md` - 详细测试场景规范
- `docs/roles/qa_engineer.md` - 测试工程师角色指南
- `src/Scripts/Tests/AutomatedTestRunner.gd` - 测试运行器
- `src/Scripts/Tests/TestSuite.gd` - 测试配置
- `docs/GameDesign.md` - 狼单位设计文档

## Task ID

Task being executed: TEST-WOLF-WOLF
