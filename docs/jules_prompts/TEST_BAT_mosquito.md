# Jules 任务: 蚊子自动化测试 (TEST-BAT-mosquito)

## 任务ID
TEST-BAT-mosquito

## 任务描述
为蝙蝠图腾流派单位"蚊子"创建完整的自动化测试用例，验证其攻击回血机制和对流血敌人增伤机制。

## 单位信息

| 属性 | 值 |
|------|-----|
| 单位ID | mosquito |
| 名称 | 蚊子 |
| 图标 | 🦟 |
| 派系 | bat_totem |
| 攻击类型 | ranged |
| 特性 | lifesteal |

**核心机制**: 攻击回血，对流血敌人增伤

## 详细测试场景

### 测试场景 1: Lv1 攻击回血验证

```gdscript
"test_mosquito_lv1_lifesteal":
    return {
        "id": "test_mosquito_lv1_lifesteal",
        "core_type": "bat_totem",
        "duration": 15.0,
        "units": [
            {"id": "mosquito", "x": 0, "y": 1, "level": 1, "hp": 100}
        ],
        "enemies": [
            {"type": "basic_enemy", "count": 5}
        ],
        "expected_behavior": "造成30%攻击力伤害，回复该单位HP的10%"
    }
```

**验证指标**:
- [ ] 攻击伤害为攻击力的30%
- [ ] 回血量为蚊子当前HP的10%
- [ ] 核心血量因吸血效果而增加

### 测试场景 2: Lv2 伤害和回血提升验证

```gdscript
"test_mosquito_lv2_lifesteal":
    return {
        "id": "test_mosquito_lv2_lifesteal",
        "core_type": "bat_totem",
        "duration": 15.0,
        "units": [
            {"id": "mosquito", "x": 0, "y": 1, "level": 2, "hp": 100}
        ],
        "enemies": [
            {"type": "basic_enemy", "count": 5}
        ],
        "expected_behavior": "伤害提升至50%攻击力，回血比例提升至30%"
    }
```

**验证指标**:
- [ ] 伤害提升至50%攻击力
- [ ] 回血比例提升至30%

### 测试场景 3: Lv3 登革热验证

```gdscript
"test_mosquito_lv3_dengue":
    return {
        "id": "test_mosquito_lv3_dengue",
        "core_type": "bat_totem",
        "duration": 20.0,
        "units": [
            {"id": "mosquito", "x": 0, "y": 1, "level": 3}
        ],
        "enemies": [
            {"type": "basic_enemy", "debuffs": [{"type": "bleed", "stacks": 3}], "count": 3, "hp": 50}
        ],
        "expected_behavior": "对流血敌人伤害+100%，击杀时爆炸造成范围伤害"
    }
```

**验证指标**:
- [ ] 对流血敌人伤害翻倍
- [ ] 击杀敌人时触发范围爆炸
- [ ] 爆炸对周围敌人造成伤害

## 实现要求

1. **添加到 TestSuite.gd**: 在 `get_test_config` 函数的 match 语句中添加以上所有测试用例

2. **测试运行验证**: 每个测试用例必须能通过 Headless 模式运行：
   ```bash
   godot --path . --headless -- --run-test=test_mosquito_lv1_lifesteal
   godot --path . --headless -- --run-test=test_mosquito_lv2_lifesteal
   godot --path . --headless -- --run-test=test_mosquito_lv3_dengue
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
   for test in test_mosquito_lv1_lifesteal test_mosquito_lv2_lifesteal test_mosquito_lv3_dengue; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```
5. 更新 `docs/test_progress.md` 中的测试进度

## 代码提交要求

1. 在独立分支上工作：`feature/TEST-BAT-mosquito`
2. 提交信息格式：`[TEST-BAT-mosquito] Add automated tests for Mosquito unit`
3. 完成后创建 Pull Request 到 main 分支

## 进度同步

完成每个测试用例后，更新 `docs/progress.md`：

```markdown
| TEST-BAT-mosquito | in_progress | 添加蚊子Lv1测试 | 2026-02-20T14:30:00 |
```

## 相关文档

- `docs/test_progress.md` - 详细测试场景规范
- `docs/roles/qa_engineer.md` - 测试工程师角色指南
- `src/Scripts/Tests/AutomatedTestRunner.gd` - 测试运行器
- `src/Scripts/Tests/TestSuite.gd` - 测试配置
- `data/game_data.json` - 单位数据配置

## Task ID

Task being executed: TEST-BAT-mosquito
