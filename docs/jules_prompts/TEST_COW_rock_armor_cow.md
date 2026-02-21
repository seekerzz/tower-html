# Jules 任务: 岩甲牛 (rock_armor_cow) 自动化测试

## 任务ID
TEST-COW-rock_armor_cow

## 任务描述
为岩甲牛单位创建完整的自动化测试用例，验证其脱战护盾机制，确保能在Headless模式下通过。

## 核心机制
**脱战护盾**: 脱战生成护盾，攻击附加护盾伤害

## 测试场景

### 测试场景 1: Lv1 脱战护盾生成验证
```gdscript
{
    "id": "test_rock_armor_cow_lv1_shield",
    "core_type": "cow_totem",
    "duration": 20.0,
    "units": [
        {"id": "rock_armor_cow", "x": 0, "y": 1, "level": 1}
    ],
    "scheduled_actions": [
        {"time": 3.0, "type": "spawn_enemy", "enemy_type": "basic", "count": 2},
        {"time": 10.0, "type": "verify_shield", "expected_shield_percent": 0.1}
    ],
    "expected_behavior": {
        "description": "脱战5秒后生成10%最大HP的护盾",
        "verification": "检查护盾值是否为最大血量的10%"
    }
}
```

**验证指标**:
- [ ] 脱战5秒后生成护盾
- [ ] 护盾值为最大血量的10%
- [ ] 攻击附加护盾值50%的伤害

### 测试场景 2: Lv2 护盾值提升验证
**验证指标**:
- [ ] 护盾值为最大血量的15%
- [ ] 脱战时间缩短至4秒

### 测试场景 3: Lv3 溢出回血转护盾验证
```gdscript
{
    "id": "test_rock_armor_cow_lv3_overflow",
    "core_type": "cow_totem",
    "duration": 25.0,
    "core_health": 500,
    "max_core_health": 500,
    "units": [
        {"id": "rock_armor_cow", "x": 0, "y": 1, "level": 3},
        {"id": "mushroom_healer", "x": 1, "y": 0, "level": 3}
    ],
    "expected_behavior": {
        "description": "核心满血时，溢出回血的10%转为护盾",
        "verification": "核心满血后，观察护盾是否继续增加"
    }
}
```

**验证指标**:
- [ ] 核心满血时，治疗溢出部分转化为护盾
- [ ] 转化比例为10%

## Headless测试配置

### 测试运行命令
```bash
# Lv1 脱战护盾测试
godot --path . --headless -- --run-test=test_rock_armor_cow_lv1_shield

# Lv3 溢出回血测试
godot --path . --headless -- --run-test=test_rock_armor_cow_lv3_overflow
```

### 通过标准
- 退出码为 0
- 无 SCRIPT ERROR
- 测试日志正常生成

## 实现步骤

1. **阅读现有代码**:
   - 阅读 `src/Scripts/Tests/TestSuite.gd` 了解测试配置格式
   - 阅读 `src/Scripts/Units/CowTotem/RockArmorCow.gd` 了解单位实现

2. **添加测试用例**:
   在 `TestSuite.gd` 的 `get_test_config` 函数中添加:
   ```gdscript
   "test_rock_armor_cow_lv1_shield":
       return {
           "id": "test_rock_armor_cow_lv1_shield",
           "core_type": "cow_totem",
           "duration": 20.0,
           "units": [
               {"id": "rock_armor_cow", "x": 0, "y": 1, "level": 1}
           ],
           "expected_behavior": "脱战5秒后生成10%最大HP的护盾"
       }

   "test_rock_armor_cow_lv3_overflow":
       return {
           "id": "test_rock_armor_cow_lv3_overflow",
           "core_type": "cow_totem",
           "duration": 25.0,
           "core_health": 500,
           "max_core_health": 500,
           "units": [
               {"id": "rock_armor_cow", "x": 0, "y": 1, "level": 3},
               {"id": "mushroom_healer", "x": 1, "y": 0, "level": 3}
           ],
           "expected_behavior": "核心满血时，溢出回血的10%转为护盾"
       }
   ```

3. **运行测试验证**:
   ```bash
   for test in test_rock_armor_cow_lv1_shield test_rock_armor_cow_lv3_overflow; do
       echo "Testing: $test"
       godot --path . --headless -- --run-test=$test
   done
   ```

4. **更新测试进度**:
   测试完成后，更新 `docs/test_progress.md` 中岩甲牛的验证指标。

## 进度更新要求

完成每个测试场景后，更新 `docs/progress.md`:

```markdown
| TEST-COW-rock_armor_cow | in_progress | 添加Lv1脱战护盾测试 | 2026-02-20T14:30:00 |
| TEST-COW-rock_armor_cow | in_progress | 添加Lv3溢出回血测试 | 2026-02-20T14:45:00 |
| TEST-COW-rock_armor_cow | completed | 所有测试通过 | 2026-02-20T15:00:00 |
```

同时在 `docs/test_progress.md` 中更新验证指标:
```markdown
**验证指标**:
- [x] 脱战5秒后生成护盾
- [x] 护盾值为最大血量的10%
- [x] 攻击附加护盾值50%的伤害
- [x] 护盾值为最大血量的15%（Lv2）
- [x] 脱战时间缩短至4秒（Lv2）
- [x] 核心满血时，治疗溢出部分转化为护盾（Lv3）
- [x] 转化比例为10%

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
- `src/Scripts/Units/CowTotem/RockArmorCow.gd` - 单位实现

## Task ID

Task being executed: TEST-COW-rock_armor_cow
