# Jules 任务: 蜘蛛自动化测试 (TEST-VIPER-spider)

## 任务ID
TEST-VIPER-spider

## 任务描述
为眼镜蛇图腾流派单位"蜘蛛"创建完整的自动化测试用例，验证其减速蛛网机制和Lv3剧毒茧召唤小蜘蛛机制。

## 单位信息

| 属性 | 值 |
|------|-----|
| 单位ID | spider |
| 名称 | 蜘蛛 |
| 图标 | 🕷️ |
| 派系 | viper_totem |
| 攻击类型 | ranged |
| 特性 | slow, summon |

**核心机制**: 攻击使敌人减速，Lv3被网住死亡的敌人生成小蜘蛛

## 详细测试场景

### 测试场景 1: Lv1 减速验证

```gdscript
"test_spider_lv1_slow":
    return {
        "id": "test_spider_lv1_slow",
        "core_type": "viper_totem",
        "duration": 20.0,
        "units": [
            {"id": "spider", "x": 0, "y": 1, "level": 1}
        ],
        "enemies": [
            {"type": "fast_enemy", "speed": 100, "count": 3}
        ],
        "expected_behavior": "攻击使敌人减速40%，被攻击的敌人移动速度降至60"
    }
```

**验证指标**:
- [ ] 攻击使敌人减速40%
- [ ] 减速效果持续

### 测试场景 2: Lv2 减速提升验证

```gdscript
"test_spider_lv2_slow":
    return {
        "id": "test_spider_lv2_slow",
        "core_type": "viper_totem",
        "duration": 20.0,
        "units": [
            {"id": "spider", "x": 0, "y": 1, "level": 2}
        ],
        "enemies": [
            {"type": "fast_enemy", "speed": 100, "count": 3}
        ],
        "expected_behavior": "减速效果提升至60%，被攻击的敌人移动速度降至40"
    }
```

**验证指标**:
- [ ] 减速效果提升至60%

### 测试场景 3: Lv3 剧毒茧验证

```gdscript
"test_spider_lv3_cocoon":
    return {
        "id": "test_spider_lv3_cocoon",
        "core_type": "viper_totem",
        "duration": 25.0,
        "units": [
            {"id": "spider", "x": 0, "y": 1, "level": 3}
        ],
        "enemies": [
            {"type": "weak_enemy", "count": 3, "hp": 50}
        ],
        "expected_behavior": "被网住并死亡的敌人生成小蜘蛛，小蜘蛛为我方作战"
    }
```

**验证指标**:
- [ ] 减速敌人死亡时生成小蜘蛛
- [ ] 小蜘蛛为我方作战

## 实现要求

1. **添加到 TestSuite.gd**: 在 `get_test_config` 函数的 match 语句中添加以上所有测试用例

2. **测试运行验证**: 每个测试用例必须能通过 Headless 模式运行：
   ```bash
   godot --path . --headless -- --run-test=test_spider_lv1_slow
   godot --path . --headless -- --run-test=test_spider_lv2_slow
   godot --path . --headless -- --run-test=test_spider_lv3_cocoon
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
3. 在 TestSuite.gd 中添加以上 3 个测试用例
4. 运行测试验证：
   ```bash
   for test in test_spider_lv1_slow test_spider_lv2_slow test_spider_lv3_cocoon; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```
5. 更新 `docs/test_progress.md` 中的测试进度

## 代码提交要求

1. 在独立分支上工作：`feature/TEST-VIPER-spider`
2. 提交信息格式：`[TEST-VIPER-spider] Add automated tests for Spider unit`
3. 完成后创建 Pull Request 到 main 分支

## 进度同步

完成每个测试用例后，更新 `docs/progress.md`：

```markdown
| TEST-VIPER-spider | in_progress | 添加蜘蛛Lv1测试 | 2026-02-20T14:30:00 |
```

## 相关文档

- `docs/test_progress.md` - 详细测试场景规范
- `docs/roles/qa_engineer.md` - 测试工程师角色指南
- `src/Scripts/Tests/AutomatedTestRunner.gd` - 测试运行器
- `src/Scripts/Tests/TestSuite.gd` - 测试配置
- `data/game_data.json` - 单位数据配置

## Task ID

Task being executed: TEST-VIPER-spider
