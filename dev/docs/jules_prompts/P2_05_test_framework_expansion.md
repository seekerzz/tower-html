# Jules 任务: P2-05 测试框架扩展

## 任务ID
P2-05

## 任务描述
根据 `docs/test_progress.md` 第8章"测试框架扩展需求"，扩展自动化测试框架，支持更多测试动作类型、敌人类型和验证方法。

## 背景说明
当前测试框架位于 `src/Scripts/Tests/AutomatedTestRunner.gd`，已实现以下功能：
- 基础测试场景配置（单位放置、波次设置）
- `skill` 动作：触发单位技能
- `summon_test` 动作：创建召唤物
- `spawn_trap` 动作：放置陷阱
- `apply_buff` 动作：施加Buff
- `test_enemy_death` 动作：测试敌人死亡处理
- 商店阵营验证

但需要更多测试能力来覆盖完整的单位机制测试。

## 实现要求

### 1. 扩展动作类型（Action Types）

在 `AutomatedTestRunner.gd` 的 `_execute_scheduled_action` 和 `_execute_setup_action` 函数中添加以下动作支持：

#### 1.1 damage_core - 扣除核心血量
```gdscript
{
    "time": 2.0,
    "type": "damage_core",
    "amount": 50  # 扣除50点核心血量
}
```
用途：测试血量触发机制（如恶霸犬狂暴）

#### 1.2 heal_core - 回复核心血量
```gdscript
{
    "time": 5.0,
    "type": "heal_core",
    "amount": 30  # 回复30点核心血量
}
```
用途：测试治疗相关机制

#### 1.3 record_damage - 记录伤害数值
```gdscript
{
    "time": 2.0,
    "type": "record_damage",
    "unit_id": "cow_golem",  # 记录该单位的伤害输出
    "label": "before_rage"   # 用于对比的标识
}
```
用途：记录特定时间点的伤害，用于对比机制触发前后的变化

#### 1.4 record_attack_speed - 记录攻击速度
```gdscript
{
    "time": 3.0,
    "type": "record_attack_speed",
    "unit_id": "dog",
    "label": "after_damage"
}
```
用途：验证攻速变化机制

#### 1.5 record_lifesteal - 记录吸血量
```gdscript
{
    "time": 5.0,
    "type": "record_lifesteal",
    "source_unit_id": "mosquito"
}
```
用途：验证吸血机制

#### 1.6 verify_shield - 验证护盾值
```gdscript
{
    "time": 10.0,
    "type": "verify_shield",
    "expected_shield_percent": 0.1,  # 期望护盾为最大血量的10%
    "tolerance": 0.01                # 误差容忍度
}
```
用途：验证岩甲牛等单位的护盾机制

#### 1.7 verify_hp - 验证血量
```gdscript
{
    "time": 5.0,
    "type": "verify_hp",
    "unit_id": "iron_turtle",
    "expected_hp_percent": 0.8,
    "tolerance": 0.05
}
```
用途：验证单位血量变化

#### 1.8 add_soul - 添加魂魄
```gdscript
{
    "time": 1.0,
    "type": "add_soul",
    "amount": 10
}
```
用途：测试魂魄相关机制

#### 1.9 devour - 吞噬单位
```gdscript
{
    "time": 3.0,
    "type": "devour",
    "source": "wolf",      # 吞噬者
    "target": "squirrel"   # 被吞噬单位
}
```
用途：测试狼图腾吞噬继承机制

#### 1.10 merge - 合并单位（蝴蝶图腾）
```gdscript
{
    "time": 5.0,
    "type": "merge",
    "source": "butterfly",
    "target": "torch"
}
```
用途：测试蝴蝶图腾合并机制

#### 1.11 attach - 附身/连接
```gdscript
{
    "time": 2.0,
    "type": "attach",
    "source": "chain_unit",
    "target": "ally_unit"
}
```
用途：测试生命链等连接机制

#### 1.12 mimic - 模仿特效
```gdscript
{
    "time": 3.0,
    "type": "mimic",
    "source": "parrot",
    "target": "woodpecker"
}
```
用途：测试鹦鹉模仿机制

#### 1.13 end_wave - 结束波次
```gdscript
{
    "time": 20.0,
    "type": "end_wave"
}
```
用途：强制结束当前波次测试

---

### 2. 扩展敌人类型

在敌人生成时支持更多类型配置。修改 `AutomatedTestRunner.gd` 中的敌人处理逻辑，支持以下敌人类型参数：

#### 2.1 weak_enemy - 低血量敌人
```gdscript
{
    "type": "weak_enemy",
    "hp": 30,
    "count": 3
}
```

#### 2.2 high_hp_enemy - 高血量敌人
```gdscript
{
    "type": "high_hp_enemy",
    "hp": 500,
    "count": 1
}
```

#### 2.3 full_hp_enemy - 满血敌人（用于处决测试）
```gdscript
{
    "type": "full_hp_enemy",
    "hp": 100,
    "count": 3
}
```

#### 2.4 fast_enemy - 快速敌人
```gdscript
{
    "type": "fast_enemy",
    "speed": 150,
    "count": 3
}
```

#### 2.5 attacker_enemy - 会攻击的敌人
```gdscript
{
    "type": "attacker_enemy",
    "attack_damage": 30,
    "attack_speed": 2.0,
    "count": 2
}
```

#### 2.6 poisoned_enemy - 带中毒的敌人
```gdscript
{
    "type": "poisoned_enemy",
    "hp": 100,
    "debuffs": [{"type": "poison", "stacks": 5}],
    "count": 3
}
```
用途：直接给敌人设置Debuff，测试Debuff依赖机制

#### 2.7 buffed_enemy - 带Buff的敌人
```gdscript
{
    "type": "buffed_enemy",
    "hp": 100,
    "buffs": [{"type": "armor", "stacks": 3}],
    "count": 3
}
```
用途：测试驱散等机制

**实现说明**：
- 这些类型映射到现有的敌人类型（如 "slime", "goblin" 等），但覆盖指定的属性
- 在 `_on_enemy_spawned` 或专门的敌人配置处理中应用这些属性

---

### 3. 扩展验证方法

在 `AutomatedTestRunner.gd` 中添加验证辅助函数：

#### 3.1 assert_damaged - 验证受到伤害
```gdscript
func assert_damaged(enemy_type: String, min_damage: float = 0.0) -> bool:
    # 验证指定类型的敌人受到了伤害
    pass
```

#### 3.2 assert_buff_applied - 验证Buff已施加
```gdscript
func assert_buff_applied(unit_id: String, buff_id: String) -> bool:
    # 验证单位已获得指定Buff
    pass
```

#### 3.3 assert_debuff_applied - 验证Debuff已施加
```gdscript
func assert_debuff_applied(enemy_filter: Dictionary, debuff_id: String) -> bool:
    # 验证敌人获得指定Debuff
    pass
```

#### 3.4 assert_hp_changed - 验证血量变化
```gdscript
func assert_hp_changed(unit_id: String, expected_change: float, tolerance: float = 0.0) -> bool:
    # 验证单位血量变化符合预期
    pass
```

#### 3.5 assert_mp_changed - 验证法力变化
```gdscript
func assert_mp_changed(expected_change: float, tolerance: float = 0.0) -> bool:
    # 验证核心法力变化
    pass
```

#### 3.6 assert_target_switched - 验证目标切换
```gdscript
func assert_target_switched(enemy_id: int, from_unit: String, to_unit: String) -> bool:
    # 验证敌人攻击目标切换（用于嘲讽测试）
    pass
```

#### 3.7 assert_clone_spawned - 验证克隆体生成
```gdscript
func assert_clone_spawned(original_type: String, clone_attrs: Dictionary = {}) -> bool:
    # 验证羊灵等单位的克隆机制
    pass
```

---

### 4. 数据记录与对比系统

添加测试数据记录系统，支持对比机制：

```gdscript
# 在 AutomatedTestRunner 中添加
var _damage_records: Dictionary = {}
var _attack_speed_records: Dictionary = {}

func record_damage_snapshot(unit_id: String, label: String):
    # 记录当前单位的伤害统计快照
    pass

func compare_damage(unit_id: String, label_before: String, label_after: String) -> Dictionary:
    # 对比两个时间点的伤害输出
    pass
```

---

### 5. 测试用例验证

实现后，验证以下测试用例可以正常工作：

#### 测试1: damage_core 动作
```gdscript
"test_damage_core_action":
    return {
        "id": "test_damage_core_action",
        "core_type": "wolf_totem",
        "duration": 10.0,
        "units": [{"id": "dog", "x": 0, "y": 1}],
        "scheduled_actions": [
            {"time": 2.0, "type": "record_attack_speed", "unit_id": "dog", "label": "before"},
            {"time": 3.0, "type": "damage_core", "amount": 250},
            {"time": 5.0, "type": "record_attack_speed", "unit_id": "dog", "label": "after"}
        ]
    }
```

#### 测试2: debuff 敌人
```gdscript
"test_enemy_with_debuff":
    return {
        "id": "test_enemy_with_debuff",
        "core_type": "bat_totem",
        "duration": 15.0,
        "units": [{"id": "mosquito", "x": 0, "y": 1}],
        "enemies": [
            {"type": "poisoned_enemy", "hp": 200, "debuffs": [{"type": "bleed", "stacks": 5}], "count": 3}
        ]
    }
```

#### 测试3: 护盾验证
```gdscript
"test_shield_verification":
    return {
        "id": "test_shield_verification",
        "core_type": "cow_totem",
        "duration": 20.0,
        "units": [{"id": "rock_armor_cow", "x": 0, "y": 1}],
        "scheduled_actions": [
            {"time": 10.0, "type": "verify_shield", "expected_shield_percent": 0.1}
        ]
    }
```

---

## 实现步骤

1. **分析现有代码**
   - 阅读 `src/Scripts/Tests/AutomatedTestRunner.gd`
   - 理解当前动作执行流程

2. **实现动作类型扩展**
   - 在 `_execute_scheduled_action` 添加新动作
   - 在 `_execute_setup_action` 添加新动作
   - 添加辅助函数支持

3. **实现敌人类型扩展**
   - 修改敌人生成逻辑，支持属性覆盖
   - 在 `_on_enemy_spawned` 或配置处理中应用debuffs/buffs

4. **实现验证方法**
   - 添加验证辅助函数
   - 集成到测试日志系统

5. **实现数据记录系统**
   - 添加记录数据结构
   - 实现快照和对比功能

6. **添加测试用例到 TestSuite.gd**
   - 添加至少3个验证新功能的测试配置

7. **运行验证测试**
   ```bash
   # 测试 damage_core 动作
   godot --path . --headless -- --run-test=test_damage_core_action

   # 测试 debuff 敌人
   godot --path . --headless -- --run-test=test_enemy_with_debuff

   # 测试护盾验证
   godot --path . --headless -- --run-test=test_shield_verification
   ```

---

## 验证方法（如何确认本任务完成）

### 验证策略

测试框架扩展的验证采用**自举验证**方式：使用框架自身的新功能来验证框架工作正常。

### 验证测试用例清单

在 `TestSuite.gd` 中添加以下专门的框架验证测试：

#### V1. 验证 damage_core 和 heal_core
```gdscript
"test_verify_damage_heal_core":
    return {
        "id": "test_verify_damage_heal_core",
        "core_type": "wolf_totem",
        "core_health": 500,
        "max_core_health": 500,
        "duration": 10.0,
        "units": [],
        "scheduled_actions": [
            {"time": 1.0, "type": "heal_core", "amount": 0},  # 先充满血
            {"time": 2.0, "type": "damage_core", "amount": 100},
            {"time": 4.0, "type": "heal_core", "amount": 50},
            {"time": 6.0, "type": "damage_core", "amount": 200}
        ],
        "expected_log_checks": [
            {"at_time": 2.5, "core_health": 400},
            {"at_time": 4.5, "core_health": 450},
            {"at_time": 6.5, "core_health": 250}
        ]
    }
```
**验证标准**：
- Headless测试退出码为0
- 日志中核心血量变化符合预期

#### V2. 验证 add_soul
```gdscript
"test_verify_add_soul":
    return {
        "id": "test_verify_add_soul",
        "core_type": "wolf_totem",
        "duration": 8.0,
        "initial_souls": 0,
        "units": [],
        "scheduled_actions": [
            {"time": 2.0, "type": "add_soul", "amount": 5},
            {"time": 4.0, "type": "add_soul", "amount": 10}
        ],
        "expected_log_checks": [
            {"at_time": 2.5, "souls": 5},
            {"at_time": 4.5, "souls": 15}
        ]
    }
```

#### V3. 验证 debuffed 敌人生成
```gdscript
"test_verify_debuffed_enemy":
    return {
        "id": "test_verify_debuffed_enemy",
        "core_type": "bat_totem",
        "duration": 12.0,
        "units": [{"id": "mosquito", "x": 0, "y": 1}],
        "enemies": [
            {"type": "poisoned_enemy", "hp": 100, "debuffs": [{"type": "bleed", "stacks": 3}], "count": 2}
        ],
        "description": "验证敌人生成时带有debuff，蚊子攻击流血敌人应该触发吸血"
    }
```
**验证标准**：
- 测试运行不报错
- 敌人正确生成（可在日志中验证敌人类型）

#### V4. 验证 record_damage 和对比
```gdscript
"test_verify_damage_recording":
    return {
        "id": "test_verify_damage_recording",
        "core_type": "cow_totem",
        "duration": 15.0,
        "units": [{"id": "cow_golem", "x": 0, "y": 1}],
        "enemies": [
            {"type": "attacker_enemy", "attack_damage": 10, "count": 1}
        ],
        "scheduled_actions": [
            {"time": 3.0, "type": "record_damage", "unit_id": "cow_golem", "label": "before_rage"},
            {"time": 8.0, "type": "record_damage", "unit_id": "cow_golem", "label": "after_rage"}
        ],
        "description": "牛魔像受击后攻击力应该增加，通过damage记录验证"
    }
```

#### V5. 验证所有动作类型执行不报错
创建一个综合验证测试：
```gdscript
"test_verify_all_actions_execute":
    return {
        "id": "test_verify_all_actions_execute",
        "core_type": "wolf_totem",
        "duration": 25.0,
        "core_health": 500,
        "max_core_health": 500,
        "initial_gold": 1000,
        "initial_mp": 500,
        "units": [
            {"id": "dog", "x": 0, "y": 1},
            {"id": "squirrel", "x": 1, "y": 0}
        ],
        "enemies": [
            {"type": "weak_enemy", "hp": 50, "count": 2}
        ],
        "setup_actions": [
            {"type": "apply_buff", "buff_id": "test_buff", "target_unit_id": "squirrel"},
            {"type": "spawn_trap", "trap_id": "poison_trap", "strategy": "random_valid"}
        ],
        "scheduled_actions": [
            {"time": 1.0, "type": "damage_core", "amount": 50},
            {"time": 2.0, "type": "heal_core", "amount": 30},
            {"time": 3.0, "type": "add_soul", "amount": 5},
            {"time": 4.0, "type": "record_damage", "unit_id": "dog", "label": "test"},
            {"time": 5.0, "type": "record_attack_speed", "unit_id": "dog", "label": "test"},
            {"time": 6.0, "type": "verify_hp", "unit_id": "dog", "expected_hp_percent": 1.0},
            {"time": 7.0, "type": "end_wave"}
        ]
    }
```
**验证标准**：
- 所有动作执行时无SCRIPT ERROR
- 测试正常结束（不是崩溃）

### 验证执行命令

```bash
# 验证1: 核心血量操作
godot --path . --headless -- --run-test=test_verify_damage_heal_core

# 验证2: 魂魄系统
godot --path . --headless -- --run-test=test_verify_add_soul

# 验证3: 带debuff的敌人
godot --path . --headless -- --run-test=test_verify_debuffed_enemy

# 验证4: 伤害记录
godot --path . --headless -- --run-test=test_verify_damage_recording

# 验证5: 所有动作综合测试（最关键的验证）
godot --path . --headless -- --run-test=test_verify_all_actions_execute
```

### 通过标准

所有验证测试必须满足：
1. **退出码为0** - 无崩溃、无未捕获异常
2. **无SCRIPT ERROR** - 日志中无脚本错误
3. **动作执行日志** - 每个动作都有执行日志输出
4. **无重复连接错误** - 信号连接正确处理

### 验证日志检查清单

测试完成后，检查日志文件（`user://test_logs/test_verify_*.json`）：
- [ ] 动作执行事件正确记录
- [ ] 核心血量变化符合预期
- [ ] 单位状态变化可追踪
- [ ] 无异常错误事件

### 可选：框架验证脚本

创建一个 `src/Scripts/Tests/TestFrameworkValidator.gd` 脚本，用于程序化验证：

```gdscript
class_name TestFrameworkValidator
extends RefCounted

## 验证所有新动作类型是否已注册
static func validate_action_types() -> Dictionary:
    var runner = AutomatedTestRunner.new()
    var required_actions = [
        "damage_core", "heal_core", "record_damage", "record_attack_speed",
        "record_lifesteal", "verify_shield", "verify_hp", "add_soul",
        "devour", "merge", "attach", "mimic", "end_wave"
    ]

    var result = {"passed": true, "missing": []}

    for action in required_actions:
        # 检查动作是否在 match 语句中处理
        if not _action_is_handled(runner, action):
            result.passed = false
            result.missing.append(action)

    return result

static func _action_is_handled(runner: AutomatedTestRunner, action_type: String) -> bool:
    # 通过反射或代码结构检查动作是否被处理
    # 简化版：检查方法是否存在
    return runner.has_method("_execute_%s_action" % action_type) or \
           runner.has_method("_handle_%s" % action_type)
```

---

## 代码提交要求

1. 在独立分支上工作：`feature/P2-05-test-framework-expansion`
2. 提交信息格式：`[P2-05] 简要描述`
3. 完成后创建 Pull Request 到 main 分支

---

## 进度同步要求

完成每个步骤后，更新 `docs/progress.md` 中任务 P2-05 的行：

```markdown
| P2-05 | in_progress | 实现 damage_core 动作 | 2026-02-20T14:30:00 |
```

---

## 注意事项

1. **向后兼容**：确保新功能不会破坏现有的测试用例
2. **错误处理**：新动作应该有适当的错误处理和日志输出
3. **类型安全**：使用 GDScript 的类型注解
4. **文档更新**：在 `docs/GameDesign.md` 中更新自动化测试框架文档（如果存在相关章节）

---

## 相关文档

- `docs/test_progress.md` - 测试用例详细规范
- `src/Scripts/Tests/TestSuite.gd` - 测试配置
- `src/Scripts/Tests/AutomatedTestRunner.gd` - 测试运行器
