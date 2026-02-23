# Jules 任务: 牛魔像 (cow_golem) 自动化测试

## 任务ID
TEST-COW-cow_golem

## 任务描述
为牛魔像单位创建完整的自动化测试用例，验证其怒火中烧机制（受击叠攻击），确保能在Headless模式下通过。

## 核心机制
**怒火中烧**: 受击叠加攻击力；Lv3触发瘟疫易伤Debuff

## 测试场景

### 测试场景 1: Lv1 受击叠加攻击力验证
```gdscript
{
    "id": "test_cow_golem_lv1_rage",
    "core_type": "cow_totem",
    "duration": 20.0,
    "units": [
        {"id": "cow_golem", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "fast_attacker", "attack_speed": 2.0, "count": 1}
    ],
    "scheduled_actions": [
        {"time": 2.0, "type": "record_damage"},
        {"time": 10.0, "type": "record_damage"}
    ],
    "expected_behavior": {
        "description": "每次受击攻击力+3%，上限30%(10层)",
        "verification": "对比不同时间点的攻击伤害"
    }
}
```

**验证指标**:
- [ ] 每次受击攻击力增加3%
- [ ] 攻击力上限为30%(10层)
- [ ] 伤害输出随受击次数增加

### 测试场景 2: Lv2 叠加上限提升验证
**验证指标**:
- [ ] 攻击力上限提升至50%(约17层)

### 测试场景 3: Lv3 充能震荡验证
```gdscript
{
    "id": "test_cow_golem_lv3_shockwave",
    "core_type": "cow_totem",
    "duration": 30.0,
    "units": [
        {"id": "cow_golem", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3, "positions": [{"x": 1, "y": 1}, {"x": -1, "y": 1}]}
    ],
    "expected_behavior": {
        "description": "受击时20%概率给敌人叠加瘟疫易伤Debuff",
        "verification": "检查敌人是否获得plague_debuff"
    }
}
```

**验证指标**:
- [ ] 受击时有20%概率触发
- [ ] 敌人获得瘟疫易伤Debuff
- [ ] Debuff可叠加

## Headless测试配置

### 测试运行命令
```bash
# Lv1 怒火中烧测试
godot --path . --headless -- --run-test=test_cow_golem_lv1_rage

# Lv3 充能震荡测试
godot --path . --headless -- --run-test=test_cow_golem_lv3_shockwave
```

### 通过标准
- 退出码为 0
- 无 SCRIPT ERROR
- 测试日志正常生成

## 实现步骤

1. **阅读现有代码**:
   - 阅读 `src/Scripts/Tests/TestSuite.gd` 了解测试配置格式
   - 阅读 `src/Scripts/Units/CowTotem/CowGolem.gd` 了解单位实现

2. **添加测试用例**:
   在 `TestSuite.gd` 的 `get_test_config` 函数中添加:
   ```gdscript
   "test_cow_golem_lv1_rage":
       return {
           "id": "test_cow_golem_lv1_rage",
           "core_type": "cow_totem",
           "duration": 25.0,
           "units": [
               {"id": "cow_golem", "x": 0, "y": 1, "level": 1}
           ],
           "enemies": [
               {"type": "attacker_enemy", "attack_damage": 10, "attack_speed": 2.0, "count": 1}
           ],
           "expected_behavior": "每次受击攻击力+3%，上限30%(10层)"
       }

   "test_cow_golem_lv3_shockwave":
       return {
           "id": "test_cow_golem_lv3_shockwave",
           "core_type": "cow_totem",
           "duration": 30.0,
           "units": [
               {"id": "cow_golem", "x": 0, "y": 1, "level": 3}
           ],
           "enemies": [
               {"type": "basic_enemy", "count": 3, "positions": [{"x": 1, "y": 1}, {"x": -1, "y": 1}]}
           ],
           "expected_behavior": "受击时20%概率给敌人叠加瘟疫易伤Debuff"
       }
   ```

3. **运行测试验证**:
   ```bash
   for test in test_cow_golem_lv1_rage test_cow_golem_lv3_shockwave; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```

4. **更新测试进度**:
   测试完成后，更新 `docs/test_progress.md` 中牛魔像的验证指标。

## 进度更新要求

完成每个测试场景后，更新 `docs/progress.md`:

```markdown
| TEST-COW-cow_golem | in_progress | 添加Lv1怒火中烧测试 | 2026-02-20T14:30:00 |
| TEST-COW-cow_golem | in_progress | 添加Lv3充能震荡测试 | 2026-02-20T14:45:00 |
| TEST-COW-cow_golem | completed | 所有测试通过 | 2026-02-20T15:00:00 |
```

同时在 `docs/test_progress.md` 中更新验证指标:
```markdown
**验证指标**:
- [x] 每次受击攻击力增加3%
- [x] 攻击力上限为30%(10层)
- [x] 伤害输出随受击次数增加
- [x] 攻击力上限提升至50%(约17层)（Lv2）
- [x] 受击时有20%概率触发（Lv3）
- [x] 敌人获得瘟疫易伤Debuff
- [x] Debuff可叠加

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
- `src/Scripts/Units/CowTotem/CowGolem.gd` - 单位实现

## Task ID

Task being executed: TEST-COW-cow_golem
