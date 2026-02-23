# Jules 任务: 猛虎 (Tiger) 自动化测试

## 任务ID
TEST-WOLF-TIGER

## 任务描述
为狼图腾流派单位"猛虎"创建完整的自动化测试用例，添加到 `src/Scripts/Tests/TestSuite.gd`，并确保所有测试能在Headless模式下通过。

## 单位信息

| 属性 | 值 |
|------|-----|
| 单位ID | tiger |
| 中文名 | 猛虎 |
| 核心机制 | 斩杀/处决 - 主动技能吞噬释放流星雨 |
| 图腾类型 | wolf_totem |

## 详细测试场景

### 测试场景 1: Lv1 猛虎吞噬验证

**测试ID**: `test_tiger_lv1_devour`

**测试配置**:
```gdscript
"test_tiger_lv1_devour":
    return {
        "id": "test_tiger_lv1_devour",
        "core_type": "wolf_totem",
        "duration": 25.0,
        "units": [
            {"id": "tiger", "x": 0, "y": 1, "level": 1},
            {"id": "squirrel", "x": 1, "y": 0}
        ],
        "enemies": [
            {"type": "basic_enemy", "count": 3, "positions": [{"x": 2, "y": 2}]}
        ],
        "scheduled_actions": [
            {"time": 5.0, "type": "skill", "source": "tiger", "target": "squirrel"}
        ],
        "expected_behavior": "吞噬相邻友方单位，立即释放流星雨，伤害+被吞噬单位攻击力25%"
    }
```

**验证指标**:
- [ ] 技能释放后吞噬相邻单位
- [ ] 立即释放流星雨
- [ ] 流星雨伤害增加被吞噬单位攻击力的25%

### 测试场景 2: Lv2 血怒暴击验证

**测试ID**: `test_tiger_lv2_blood_rage`

**测试配置**:
```gdscript
"test_tiger_lv2_blood_rage":
    return {
        "id": "test_tiger_lv2_blood_rage",
        "core_type": "wolf_totem",
        "duration": 30.0,
        "units": [
            {"id": "tiger", "x": 0, "y": 1, "level": 2}
        ],
        "setup_actions": [
            {"type": "add_soul", "count": 8}
        ],
        "enemies": [
            {"type": "basic_enemy", "count": 5}
        ],
        "expected_behavior": "每层血魂使暴击率+3%，最多8层(+24%暴击率)"
    }
```

**验证指标**:
- [ ] 每层血魂暴击率+3%
- [ ] 最多8层(+24%暴击率)
- [ ] 暴击率正确计算

### 测试场景 3: Lv3 流星雨增强验证

**测试ID**: `test_tiger_lv3_meteor`

**测试配置**:
```gdscript
"test_tiger_lv3_meteor":
    return {
        "id": "test_tiger_lv3_meteor",
        "core_type": "wolf_totem",
        "duration": 25.0,
        "units": [
            {"id": "tiger", "x": 0, "y": 1, "level": 3},
            {"id": "wolf", "x": 1, "y": 0}
        ],
        "enemies": [
            {"type": "basic_enemy", "count": 3}
        ],
        "scheduled_actions": [
            {"time": 5.0, "type": "skill", "source": "tiger", "target": "wolf"}
        ],
        "expected_behavior": "流星雨流星数+2颗，吞噬狼图腾单位时额外+2颗(共+4颗)"
    }
```

**验证指标**:
- [ ] 流星雨流星数+2颗
- [ ] 吞噬狼图腾单位额外+2颗
- [ ] 吞噬非狼单位只+2颗

## 实现要求

1. **添加到 TestSuite.gd**: 在 `get_test_config` 函数的 match 语句中添加以上3个测试用例

2. **测试运行验证**: 每个测试用例必须能通过 Headless 模式运行：
   ```bash
   godot --path . --headless -- --run-test=test_tiger_lv1_devour
   godot --path . --headless -- --run-test=test_tiger_lv2_blood_rage
   godot --path . --headless -- --run-test=test_tiger_lv3_meteor
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
   for test in test_tiger_lv1_devour test_tiger_lv2_blood_rage test_tiger_lv3_meteor; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```
5. 更新 `docs/test_progress.md` 中的测试进度

## 代码提交要求

1. 在独立分支上工作：`feature/TEST-WOLF-TIGER`
2. 提交信息格式：`[TEST-WOLF-TIGER] Add automated tests for Tiger unit`
3. 完成后创建 Pull Request 到 main 分支

## 进度同步

完成每个测试用例后，更新 `docs/progress.md`：

```markdown
| TEST-WOLF-TIGER | in_progress | 添加猛虎Lv1吞噬测试 | 2026-02-20T14:30:00 |
```

## 相关文档

- `docs/test_progress.md` - 详细测试场景规范
- `docs/roles/qa_engineer.md` - 测试工程师角色指南
- `src/Scripts/Tests/AutomatedTestRunner.gd` - 测试运行器
- `src/Scripts/Tests/TestSuite.gd` - 测试配置
- `docs/GameDesign.md` - 猛虎单位设计文档

## Task ID

Task being executed: TEST-WOLF-TIGER
