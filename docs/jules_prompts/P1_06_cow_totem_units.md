# Jules 任务: P1-F 牛图腾单位群

## 任务ID
P1-F

## 任务描述
实现牛图腾流派的单位：苦修者，并完善树苗、铁甲龟、刺猬、牦牛守护、岩甲牛、牛椋鸟、菌菇治愈者、奶牛。

## 前置条件（代码库中已存在）

- AggroManager（来自P0-02）
- TauntBehavior（来自P0-02）

## 需要实现的单位

### 1. 苦修者 - 辅助单位

```gdscript
class_name UnitAscetic
extends Unit

@export var damage_to_mana_ratio: float = 0.12

var buffed_units: Array[Unit] = []
var max_buffed_count: int = 1

func _ready():
    super._ready()
    max_buffed_count = 1 if level < 3 else 2
    _auto_select_targets()

func _auto_select_targets():
    # 自动选择最近的友方单位
    var all_units = get_all_player_units()
    all_units.sort_custom(func(a, b):
        return global_position.distance_to(a.global_position) < \
               global_position.distance_to(b.global_position)
    )
    buffed_units = all_units.slice(0, max_buffed_count)

    for unit in buffed_units:
        unit.set_meta("ascetic_buffed", true)
        unit.set_meta("ascetic_source", self)
        if not unit.is_connected("damage_taken", _on_buffed_unit_damaged):
            unit.damage_taken.connect(_on_buffed_unit_damaged)

func _on_buffed_unit_damaged(amount: float, source: Node):
    var ratio = 0.12 if level < 2 else 0.18
    var mana_gain = amount * ratio
    GameManager.add_mana(mana_gain)
    _show_mana_gain_effect(mana_gain)
```

### 2. 树苗完善

```gdscript
# 在 UnitPlant.gd 中更新
func _ready():
    super._ready()
    EventBus.wave_ended.connect(_on_wave_end)
    if level >= 3:
        _apply_nearby_hp_buff()

func _on_wave_end():
    var growth = 0.05 if level < 2 else 0.08
    var hp_bonus = max_hp * growth
    max_hp += hp_bonus
    current_hp += hp_bonus
    _show_growth_effect()

func _apply_nearby_hp_buff():
    var nearby = get_units_in_cell_range(self, 1)
    for unit in nearby:
        if unit != self:
            unit.add_buff("max_hp_percent", 0.05, self)
```

### 3. 铁甲龟完善

```gdscript
# 在 UnitIronTurtle.gd 中更新
@export var damage_reduction: int = 15

func _ready():
    super._ready()
    if level >= 2:
        damage_reduction = 25
    if level >= 3:
        damage_reduction = 35

func _on_damage_incoming(amount: float, source: Node) -> float:
    var reduced = max(0, amount - damage_reduction)

    if level >= 3 and reduced <= 0:
        var heal_amount = GameManager.max_core_health * 0.005
        GameManager.heal_core(heal_amount)
        _show_heal_effect()

    return reduced
```

### 4. 刺猬完善

```gdscript
# 在 UnitHedgehog.gd 中更新
@export var reflect_chance: float = 0.25

func _ready():
    super._ready()
    if level >= 2:
        reflect_chance = 0.40

func _on_damage_taken(amount: float, attacker: Node):
    super._on_damage_taken(amount, attacker)

    if randf() < reflect_chance:
        var reflect_damage = amount
        attacker.take_damage(reflect_damage, self)
        _show_reflect_effect()

        if level >= 3:
            _launch_spikes()

func _launch_spikes():
    for i in range(3):
        var angle = i * (TAU / 3)
        var spike = create_projectile("spike")
        spike.global_position = global_position
        spike.velocity = Vector2(cos(angle), sin(angle)) * 200
        spike.gravity = 300
        spike.arc_height = 50
        fire_projectile(spike)
```

### 5. 牦牛守护完善

```gdscript
# 在 UnitYakGuardian.gd 中更新
var taunt_behavior: TauntBehavior

func _ready():
    super._ready()
    taunt_behavior = TauntBehavior.new()
    taunt_behavior.taunt_interval = 6.0 if level < 2 else 5.0
    add_child(taunt_behavior)

    if level >= 3:
        EventBus.totem_attacked.connect(_on_totem_attack)

func _on_totem_attack(totem_type: String):
    if totem_type != "cow":
        return
    if not taunt_behavior.is_taunting:
        return

    var bonus_damage = max_hp * 0.15
    var enemies = get_enemies_in_range(attack_range)
    for enemy in enemies:
        enemy.take_damage(bonus_damage, self)
        _show_damage_effect(enemy)
```

### 6. 岩甲牛完善

```gdscript
# 在 UnitRockArmorCow.gd 中更新
var shield_amount: float = 0.0
var shield_percent: float = 0.8

func _ready():
    super._ready()
    EventBus.wave_started.connect(_on_wave_start)
    _on_wave_start()

func _on_wave_start():
    shield_percent = 0.8 if level < 2 else 1.2
    shield_amount = max_hp * shield_percent
    _show_shield_effect()

func _on_damage_incoming(amount: float) -> float:
    if shield_amount > 0:
        var shield_absorb = min(shield_amount, amount)
        shield_amount -= shield_absorb
        amount -= shield_absorb

        if current_target:
            var bonus_damage = shield_absorb * 0.4
            current_target.take_damage(bonus_damage, self)

    return amount

func _on_heal_received(amount: float):
    if level >= 3 and current_hp >= max_hp:
        var overflow = (current_hp + amount) - max_hp
        shield_amount += overflow * 0.1
        current_hp = max_hp
```

### 7. 牛椋鸟完善

```gdscript
# 在 UnitOxpecker.gd 中更新
var extra_attack_damage_percent: float = 0.8

func _ready():
    super._ready()
    if level >= 2:
        extra_attack_damage_percent = 1.2

    var host = get_host_unit()
    if host:
        host.on_attack_hit.connect(_on_host_attack)

func _on_host_attack(enemy: Enemy, damage: float):
    var extra_damage = damage * extra_attack_damage_percent
    enemy.take_damage(extra_damage, self)

    if level >= 3:
        enemy.add_debuff("vulnerable", 1, 4.0)
```

### 8. 菌菇治愈者重写

```gdscript
class_name UnitMushroomHealer
extends Unit

@export var spore_stacks: int = 1

var unit_spores: Dictionary = {}

func _ready():
    super._ready()
    if level >= 2:
        spore_stacks = 2

    var timer = Timer.new()
    timer.wait_time = 6.0
    timer.timeout.connect(_apply_spore_shields)
    add_child(timer)
    timer.start()

func _apply_spore_shields():
    var allies = get_units_in_range(global_position, 150.0)
    for ally in allies:
        if ally == self:
            continue

        var current = unit_spores.get(ally.get_instance_id(), 0)
        unit_spores[ally.get_instance_id()] = min(current + spore_stacks, 3)
        ally.set_meta("spore_shield", unit_spores[ally.get_instance_id()])

        if not ally.is_connected("damage_blocked", _on_spore_blocked):
            ally.damage_blocked.connect(_on_spore_blocked)

func _on_spore_blocked(unit: Unit, damage: float):
    var spores = unit_spores.get(unit.get_instance_id(), 0)
    if spores <= 0:
        return

    unit_spores[unit.get_instance_id()] = spores - 1
    unit.set_meta("spore_shield", spores - 1)

    # 给攻击者叠加中毒
    # 需要获取伤害来源...

    if level >= 3 and spores - 1 <= 0:
        _apply_bonus_poison_damage(unit)

func _apply_bonus_poison_damage(unit: Unit):
    if unit.current_target:
        unit.current_target.add_poison_stacks(2)
```

### 9. 奶牛完善

```gdscript
# 在 UnitCow.gd 中更新
@export var heal_interval: float = 6.0

func _ready():
    super._ready()
    if level >= 2:
        heal_interval = 5.0

    var timer = Timer.new()
    timer.wait_time = heal_interval
    timer.timeout.connect(_heal_core)
    add_child(timer)
    timer.start()

func _heal_core():
    var base_heal = GameManager.max_core_health * 0.015

    if level >= 3:
        var health_lost_percent = 1.0 - (GameManager.core_health / GameManager.max_core_health)
        var bonus_multiplier = 1.0 + health_lost_percent
        base_heal *= bonus_multiplier

    GameManager.heal_core(base_heal)
    _show_heal_effect()
```

### 10. 配置更新

更新 data/game_data.json：

```json
{
    "units": [
        {"id": "ascetic", "name": "苦修者", "faction": "cow", "type": "support", "cost": 120}
    ]
}
```

## 实现步骤

1. 创建 UnitAscetic.gd
2. 更新 UnitPlant.gd 添加成长和世界树效果
3. 更新 UnitIronTurtle.gd 添加Lv3回血
4. 更新 UnitHedgehog.gd 添加Lv3尖刺
5. 更新 UnitYakGuardian.gd 添加嘲讽和Lv3联动
6. 更新 UnitRockArmorCow.gd 添加护盾和Lv3溢出
7. 更新 UnitOxpecker.gd 添加Lv3易伤
8. 重写 UnitMushroomHealer.gd 实现孢子护盾
9. 更新 UnitCow.gd 添加Lv3加成
10. 更新 game_data.json
11. 运行测试

## 自动化测试要求

创建测试用例：

```gdscript
"test_cow_ascetic":
    return {
        "id": "test_cow_ascetic",
        "core_type": "cow_totem",
        "initial_gold": 1000,
        "start_wave_index": 1,
        "duration": 20.0,
        "units": [
            {"id": "ascetic", "x": 0, "y": 0},
            {"id": "iron_turtle", "x": 0, "y": 1}
        ]
    }
```

运行测试：
```bash
for test in test_cow_ascetic test_cow_plant test_cow_turtle test_cow_hedgehog test_cow_yak test_cow_rock test_cow_oxpecker test_cow_mushroom test_cow_cow; do
    godot --path . --headless -- --run-test=$test
done
```

验证点：
- 苦修者将友方受到伤害转为法力
- Lv2苦修者18%转化率，Lv3可选两个单位
- 树苗每波结束增加自身Max HP
- Lv3树苗给周围单位Max HP加成5%
- 铁甲龟Lv3在伤害减为0时回复核心HP
- 刺猬Lv3反伤时发射抛物线尖刺
- 牦牛守护触发嘲讽，Lv3图腾联动
- 岩甲牛护盾正确抵消伤害并附加伤害
- Lv3岩甲牛溢出回血转为护盾
- 菌菇治愈者正确实现孢子护盾
- 奶牛Lv3根据核心损失血量额外回复

## 进度同步要求

更新 docs/progress.md 中任务 P1-F 的行：

```markdown
| P1-F | in_progress | 已实现苦修者和树苗 | 2026-02-19T21:00:00 |
```

## 代码提交要求

1. 在独立分支上工作：`feature/P1-F-cow-units`
2. 提交信息格式：`[P1-F] 简要描述`
3. 完成后创建 Pull Request 到 main 分支

## 注意事项

- 依赖P0-02的嘲讽系统
- 苦修者自动选择最近友方
- 菌菇治愈者需要完全重写现有实现
- 刺猬的抛物线弹道需要物理模拟
