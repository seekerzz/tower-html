# Jules 任务: 瘟疫使者自动化测试 (TEST-BAT-plague_spreader)

## 任务ID
TEST-BAT-plague_spreader

## 任务描述
为蝙蝠图腾流派单位"瘟疫使者"创建完整的自动化测试用例，验证其攻击传播疾病机制。

## 单位信息

| 属性 | 值 |
|------|-----|
| 单位ID | plague_spreader |
| 名称 | 瘟疫使者 |
| 图标 | 🦇 |
| 派系 | bat_totem |
| 攻击类型 | ranged |
| 投射物 | stinger |
| 伤害类型 | poison |

**核心机制**: 攻击使敌人中毒，中毒敌人死亡时传播给附近敌人

## 详细测试场景

### 测试场景 1: Lv1 毒血传播基础验证

```gdscript
"test_plague_spreader_lv1_spread":
    return {
        "id": "test_plague_spreader_lv1_spread",
        "core_type": "bat_totem",
        "duration": 20.0,
        "units": [
            {"id": "plague_spreader", "x": 0, "y": 1, "level": 1}
        ],
        "enemies": [
            {"type": "basic_enemy", "count": 3, "hp": 80}
        ],
        "expected_behavior": "攻击使敌人中毒，中毒敌人死亡时传播给附近敌人"
    }
```

**验证指标**:
- [ ] 攻击使敌人获得中毒Debuff
- [ ] 中毒敌人每秒受到伤害
- [ ] 中毒敌人死亡时传播给附近敌人

### 测试场景 2: Lv2 传播范围提升验证

```gdscript
"test_plague_spreader_lv2_range":
    return {
        "id": "test_plague_spreader_lv2_range",
        "core_type": "bat_totem",
        "duration": 25.0,
        "units": [
            {"id": "plague_spreader", "x": 0, "y": 1, "level": 2}
        ],
        "enemies": [
            {"type": "basic_enemy", "count": 5, "hp": 80, "positions": [{"x": 2, "y": 0}, {"x": 3, "y": 0}, {"x": 4, "y": 0}]}
        ],
        "expected_behavior": "传播范围+1格(60像素)，更远处的敌人也会被传播"
    }
```

**验证指标**:
- [ ] 传播范围为60像素(1格)
- [ ] 超出攻击范围但在此范围内的敌人也会被传播中毒
- [ ] Lv2暴击率+10%

### 测试场景 3: Lv3 传播范围最大化验证

```gdscript
"test_plague_spreader_lv3_range":
    return {
        "id": "test_plague_spreader_lv3_range",
        "core_type": "bat_totem",
        "duration": 25.0,
        "units": [
            {"id": "plague_spreader", "x": 0, "y": 1, "level": 3}
        ],
        "enemies": [
            {"type": "basic_enemy", "count": 5, "hp": 80, "positions": [{"x": 2, "y": 0}, {"x": 4, "y": 0}, {"x": 6, "y": 0}]}
        ],
        "expected_behavior": "传播范围+2格(120像素)，大范围内敌人都会被传播"
    }
```

**验证指标**:
- [ ] 传播范围为120像素(2格)
- [ ] 大范围传播生效
- [ ] Lv3暴击率+20%

### 测试场景 4: 传播链式反应验证

```gdscript
"test_plague_spreader_chain_reaction":
    return {
        "id": "test_plague_spreader_chain_reaction",
        "core_type": "bat_totem",
        "duration": 30.0,
        "units": [
            {"id": "plague_spreader", "x": 0, "y": 1, "level": 3}
        ],
        "enemies": [
            {"type": "weak_enemy", "count": 8, "hp": 30, "positions": [{"x": 2, "y": 0}, {"x": 3, "y": 0}, {"x": 4, "y": 0}, {"x": 5, "y": 0}]}
        ],
        "expected_behavior": "多个中毒敌人死亡时产生链式传播反应"
    }
```

**验证指标**:
- [ ] 多个中毒敌人死亡时各自传播
- [ ] 传播产生连锁反应
- [ ] 所有范围内敌人都获得中毒

## 实现要求

1. **添加到 TestSuite.gd**: 在 `get_test_config` 函数的 match 语句中添加以上所有测试用例

2. **测试运行验证**: 每个测试用例必须能通过 Headless 模式运行：
   ```bash
   godot --path . --headless -- --run-test=test_plague_spreader_lv1_spread
   godot --path . --headless -- --run-test=test_plague_spreader_lv2_range
   godot --path . --headless -- --run-test=test_plague_spreader_lv3_range
   godot --path . --headless -- --run-test=test_plague_spreader_chain_reaction
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
3. 在 TestSuite.gd 中添加以上 4 个测试用例
4. 运行测试验证：
   ```bash
   for test in test_plague_spreader_lv1_spread test_plague_spreader_lv2_range test_plague_spreader_lv3_range test_plague_spreader_chain_reaction; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```
5. 更新 `docs/test_progress.md` 中的测试进度

## 代码提交要求

1. 在独立分支上工作：`feature/TEST-BAT-plague_spreader`
2. 提交信息格式：`[TEST-BAT-plague_spreader] Add automated tests for Plague Spreader unit`
3. 完成后创建 Pull Request 到 main 分支

## 进度同步

完成每个测试用例后，更新 `docs/progress.md`：

```markdown
| TEST-BAT-plague_spreader | in_progress | 添加瘟疫使者Lv1测试 | 2026-02-20T14:30:00 |
```

## 相关文档

- `docs/test_progress.md` - 详细测试场景规范
- `docs/roles/qa_engineer.md` - 测试工程师角色指南
- `src/Scripts/Tests/AutomatedTestRunner.gd` - 测试运行器
- `src/Scripts/Tests/TestSuite.gd` - 测试配置
- `data/game_data.json` - 单位数据配置

## Task ID

Task being executed: TEST-BAT-plague_spreader
