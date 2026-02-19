# Jules 任务: P1-E 鹰图腾单位群

## 任务ID
P1-E

## 任务描述
实现鹰图腾流派的单位：红隼、猫头鹰、喜鹊、鸽子，并完善角雕、疾风鹰、老鹰、秃鹫、啄木鸟。

## 需要实现的单位

### 1. 红隼 - 攻击单位

```gdscript
class_name UnitKestrel
extends Unit

@export var dive_chance: float = 0.20

func _ready():
    super._ready()
    on_attack_hit.connect(_on_attack_check_stun)

func _on_attack_check_stun(enemy: Enemy, damage: float):
    var chance = dive_chance
    if level >= 2:
        chance = 0.30

    if randf() < chance:
        var duration = 1.0 if level < 2 else 1.2
        _apply_dive_stun(enemy, duration)

func _apply_dive_stun(enemy: Enemy, duration: float):
    enemy.apply_stun(duration)
    if level >= 3:
        _sonic_boom(enemy.global_position)

func _sonic_boom(position: Vector2):
    var radius = 80.0
    var damage = self.damage * 0.4
    var enemies = get_enemies_in_radius(position, radius)
    for e in enemies:
        e.take_damage(damage, self)
```

### 2. 猫头鹰 - 辅助单位

```gdscript
class_name UnitOwl
extends Unit

var affected_units: Array[Unit] = []

func _ready():
    super._ready()
    _update_affected_units()
    _apply_crit_buff()
    EventBus.totem_echo_triggered.connect(_on_totem_echo)

func _update_affected_units():
    var range_cells = 1 if level < 2 else 2
    affected_units = get_units_in_cell_range(self, range_cells)

func _apply_crit_buff():
    var bonus = 0.12 if level < 2 else 0.20
    for unit in affected_units:
        unit.add_buff("crit_chance", bonus, self)

func _on_totem_echo(source_unit: Unit, damage: float):
    if not affected_units.has(source_unit):
        return
    if level >= 3:
        source_unit.add_temporary_buff("attack_speed", 0.15, 3.0)
```

### 3. 喜鹊 - Buff单位

```gdscript
class_name UnitMagpie
extends Unit

enum StealType { ATTACK_SPEED, MOVE_SPEED, DEFENSE }

func _on_attack_hit(enemy: Enemy, damage: float):
    var chance = 0.15 if level < 3 else 0.25
    if randf() >= chance:
        return

    var steal_type = StealType.values()[randi() % 3]
    var steal_amount = _calculate_steal_amount(enemy, steal_type)

    if level >= 2:
        steal_amount *= 1.5

    _apply_steal_effect(steal_type, steal_amount)

func _calculate_steal_amount(enemy: Enemy, type: StealType) -> float:
    match type:
        StealType.ATTACK_SPEED: return 0.03
        StealType.MOVE_SPEED: return 0.08
        StealType.DEFENSE: return 0.03
    return 0.0

func _apply_steal_effect(type: StealType, amount: float):
    var targets = [self]
    if level >= 3:
        targets.append_array(get_adjacent_units(self))

    for target in targets:
        match type:
            StealType.ATTACK_SPEED:
                target.add_buff("attack_speed", amount, self)
            StealType.DEFENSE:
                target.add_buff("defense", amount, self)

    if level >= 3:
        _apply_bonus_on_steal()

func _apply_bonus_on_steal():
    if randf() < 0.5:
        GameManager.heal_core(10)
    else:
        GameManager.add_gold(10)
```

### 4. 鸽子 - 辅助单位

```gdscript
class_name UnitPigeon
extends Unit

@export var dodge_chance: float = 0.12

func _ready():
    super._ready()
    EventBus.damage_about_to_be_taken.connect(_on_damage_incoming)

func _on_damage_incoming(target: Node, damage: float, source: Node):
    if target != self:
        return

    var chance = dodge_chance if level < 2 else 0.20
    if randf() < chance:
        _on_dodge_success(source)
        EventBus.damage_about_to_be_taken.disconnect(_on_damage_incoming)

func _on_dodge_success(attacker: Node):
    if level >= 2:
        apply_invulnerable(0.3)

    if level >= 3 and attacker is Enemy:
        _counter_attack(attacker)
        _apply_dodge_buff_to_allies()

func _counter_attack(enemy: Enemy):
    var counter_damage = damage * 0.6
    enemy.take_damage(counter_damage, self)
    if check_crit():
        trigger_totem_echo(enemy, counter_damage)

func _apply_dodge_buff_to_allies():
    var allies = get_units_in_radius(global_position, 150.0)
    for ally in allies:
        ally.add_temporary_buff("crit_chance", 0.08, 3.0)
```

### 5. 角雕完善

```gdscript
# 在 UnitHarpyEagle.gd 中更新
var attack_combo: int = 0

func _on_attack():
    attack_combo += 1
    if attack_combo >= 3:
        _perform_third_strike()
        attack_combo = 0

func _perform_third_strike():
    var base_crit = crit_chance
    if level == 1:
        crit_chance *= 2
    elif level == 2:
        crit_chance *= 3
    elif level >= 3:
        crit_chance = 1.0
        # 附加流血
        if current_target:
            current_target.add_bleed_stacks(2)

    crit_chance = base_crit
```

### 6. 疾风鹰完善

```gdscript
# 在 UnitGaleEagle.gd 中更新
func _perform_attack():
    var wind_blade_count = 2 if level < 3 else 3
    var damage_percent = 0.6 if level < 3 else 0.8

    for i in range(wind_blade_count):
        var blade = create_projectile("wind_blade")
        blade.damage = damage * damage_percent

        if level >= 3:
            blade.can_crit = true
            blade.can_trigger_echo = true
            blade.on_hit.connect(func(enemy):
                if randf() < 0.20:
                    _spawn_extra_wind_blade(enemy.global_position)
            )

        fire_projectile(blade)
```

### 7. 老鹰完善

```gdscript
# 在 UnitEagle.gd 中更新
var first_strike_bonus: bool = true

func _get_target() -> Enemy:
    var enemies = get_all_enemies()
    enemies.sort_custom(func(a, b): return a.current_hp > b.current_hp)
    return enemies[0] if enemies.size() > 0 else null

func _on_attack_hit(enemy: Enemy, damage: float):
    var hp_percent = enemy.current_hp / enemy.max_hp

    if level >= 2 and hp_percent > 0.5:
        damage *= 1.3

    if level >= 3 and first_strike_bonus and hp_percent > 0.8:
        damage *= 2.0
        first_strike_bonus = false
```

### 8. 秃鹫完善

```gdscript
# 在 UnitVulture.gd 中更新
var kill_count: int = 0
var permanent_attack_bonus: int = 0

func _get_target() -> Enemy:
    var enemies = get_all_enemies()
    enemies.sort_custom(func(a, b): return a.current_hp < b.current_hp)
    return enemies[0] if enemies.size() > 0 else null

func _on_attack_hit(enemy: Enemy, damage: float):
    var hp_percent = enemy.current_hp / enemy.max_hp

    if level >= 2 and hp_percent < 0.3:
        damage *= 1.3

    if enemy.current_hp <= damage and permanent_attack_bonus < 15:
        permanent_attack_bonus += 1
        base_damage += 1
        kill_count += 1

        if level >= 3:
            trigger_totem_echo(enemy, damage)
```

### 9. 啄木鸟完善

```gdscript
# 在 UnitWoodpecker.gd 中更新
var drill_target: Enemy = null
var drill_stacks: int = 0
var max_drill_stacks: int = 8

func _get_target() -> Enemy:
    if is_instance_valid(drill_target) and drill_target.current_hp > 0:
        return drill_target
    drill_target = super._get_target()
    drill_stacks = 0
    return drill_target

func _on_attack_hit(enemy: Enemy, damage: float):
    if enemy == drill_target:
        drill_stacks = min(drill_stacks + 1, max_drill_stacks)
    else:
        drill_target = enemy
        drill_stacks = 1

    var bonus = 1.0 + (drill_stacks * 0.08)
    damage *= bonus

    if level >= 3 and drill_stacks >= max_drill_stacks:
        _enter_drill_master_mode()

func _enter_drill_master_mode():
    force_next_crits(3)
    attack_cooldown *= 0.75
    await get_tree().create_timer(attack_cooldown * 3).timeout
    attack_cooldown /= 0.75
```

### 10. 配置更新

更新 data/game_data.json：

```json
{
    "units": [
        {"id": "kestrel", "name": "红隼", "faction": "eagle", "type": "attack", "cost": 120},
        {"id": "owl", "name": "猫头鹰", "faction": "eagle", "type": "support", "cost": 100},
        {"id": "magpie", "name": "喜鹊", "faction": "eagle", "type": "buff", "cost": 100},
        {"id": "pigeon", "name": "鸽子", "faction": "eagle", "type": "support", "cost": 80}
    ]
}
```

## 实现步骤

1. 创建 UnitKestrel.gd
2. 创建 UnitOwl.gd
3. 创建 UnitMagpie.gd
4. 创建 UnitPigeon.gd
5. 更新现有鹰单位添加Lv3效果
6. 更新 game_data.json
7. 运行测试

## 自动化测试要求

创建测试用例：

```gdscript
"test_eagle_kestrel":
    return {
        "id": "test_eagle_kestrel",
        "core_type": "eagle_totem",
        "initial_gold": 1000,
        "start_wave_index": 1,
        "duration": 15.0,
        "units": [{"id": "kestrel", "x": 0, "y": 1}]
    }
```

运行测试：
```bash
for test in test_eagle_kestrel test_eagle_owl test_eagle_magpie test_eagle_pigeon; do
    godot --path . --headless -- --run-test=$test
done
```

验证点：
- 红隼概率眩晕敌人，Lv2增加概率和时间
- Lv3红隼眩晕触发音爆伤害
- 猫头鹰增加相邻友军暴击率
- Lv3猫头鹰在友方触发回响时增加攻速
- 喜鹊攻击概率偷取敌人属性
- Lv3喜鹊偷取成功给核心回复HP或金币
- 鸽子闪避敌人攻击
- Lv2鸽子闪避后0.3秒无敌
- Lv3鸽子闪避时反击并给友方加暴击

## 进度同步要求

更新 docs/progress.md 中任务 P1-E 的行：

```markdown
| P1-E | in_progress | 已实现红隼和猫头鹰 | 2026-02-19T20:00:00 |
```

## 代码提交要求

1. 在独立分支上工作：`feature/P1-E-eagle-units`
2. 提交信息格式：`[P1-E] 简要描述`
3. 完成后创建 Pull Request 到 main 分支

## 注意事项

- 这是独立任务，无前置依赖
- 眩晕效果需要敌人停止移动和攻击
- 图腾回响依赖需要事件系统支持
- 属性偷取需要良好的视觉反馈
