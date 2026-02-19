# Jules 任务: P1-D 蝴蝶图腾单位群

## 任务ID
P1-D

## 任务描述
实现蝴蝶图腾流派的单位：冰晶蝶、萤火虫、木精灵，并完善蝴蝶、凤凰、龙Lv3。

## 需要实现的单位

### 1. 冰晶蝶 - Buff单位

```gdscript
class_name UnitIceButterfly
extends Unit

@export var freeze_threshold: int = 3

var frozen_enemies: Dictionary = {}

func _ready():
    super._ready()
    on_attack_hit.connect(_on_attack_apply_ice)

func _on_attack_apply_ice(enemy: Enemy, damage: float):
    if not enemy.has_meta("ice_stacks"):
        enemy.set_meta("ice_stacks", 0)

    var stacks = enemy.get_meta("ice_stacks") + 1
    enemy.set_meta("ice_stacks", stacks)

    if stacks >= freeze_threshold:
        _freeze_enemy(enemy)
        enemy.set_meta("ice_stacks", 0)

func _freeze_enemy(enemy: Enemy):
    var duration = 1.0 if level < 2 else 1.5
    enemy.apply_freeze(duration)
    frozen_enemies[enemy.get_instance_id()] = duration
    _play_freeze_effect(enemy)
```

### 2. 萤火虫 - 攻击单位

```gdscript
class_name UnitFirefly
extends Unit

@export var blind_duration: float = 2.5

func _ready():
    super._ready()
    deals_damage = false
    on_attack_hit.connect(_on_apply_blind)

func _on_apply_blind(enemy: Enemy, damage: float):
    var actual_duration = blind_duration
    if level >= 2:
        actual_duration += 2.0

    enemy.apply_blind(actual_duration)

    if level >= 3:
        if not enemy.is_connected("attack_missed", _on_enemy_miss):
            enemy.attack_missed.connect(_on_enemy_miss)

func _on_enemy_miss(enemy: Enemy):
    if level >= 3:
        GameManager.add_mana(8)
        _show_mana_restore_effect()
```

### 3. 木精灵 - Buff单位

```gdscript
class_name UnitForestSprite
extends Unit

var debuff_types: Array[String] = ["poison", "burn", "bleed", "slow"]

func get_debuff_chance() -> float:
    if level >= 3:
        return 0.15
    elif level >= 2:
        return 0.12
    return 0.08

static func on_unit_attack_hit(attacker: Unit, enemy: Enemy):
    var sprites = get_units_in_range(attacker.global_position, 150.0, "forest_sprite")
    for sprite in sprites:
        if randf() < sprite.get_debuff_chance():
            var debuff = sprite.debuff_types[randi() % sprite.debuff_types.size()]
            var stacks = 1
            if sprite.level >= 3 and randf() < 0.15:
                stacks = 2
            enemy.apply_debuff(debuff, stacks)
```

### 4. 蝴蝶技能实现

```gdscript
# 在 UnitButterfly.gd 中更新
var skill_active: bool = false
var pending_bonus_damage: float = 0

func _on_skill_activated():
    var mana_cost = GameManager.max_mana * 0.08
    if GameManager.current_mana < mana_cost:
        return

    GameManager.consume_mana(mana_cost)

    var damage_multiplier = 1.2 if level < 2 else 1.8
    pending_bonus_damage = mana_cost * damage_multiplier
    skill_active = true

func _on_attack_hit(enemy: Enemy):
    super._on_attack_hit(enemy)

    if skill_active:
        enemy.take_damage(pending_bonus_damage, self)
        skill_active = false
        pending_bonus_damage = 0

    if level >= 3 and enemy.current_hp <= 0:
        var restore = GameManager.max_mana * 0.1
        GameManager.add_mana(restore)
```

### 5. 凤凰Lv3完善

```gdscript
# 在 UnitPhoenix.gd 中更新
func _cast_fire_rain():
    var hit_enemies = 0
    var rain_duration = 3.0
    var damage_per_tick = damage * 0.3

    var timer = Timer.new()
    timer.wait_time = 0.5
    var ticks = 0
    var max_ticks = int(rain_duration / 0.5)

    timer.timeout.connect(func():
        ticks += 1
        var enemies = get_enemies_in_range(skill_range)
        for e in enemies:
            e.take_damage(damage_per_tick, self)
            hit_enemies += 1
            if level >= 3:
                _restore_ally_mana(e.global_position)

        if ticks >= max_ticks:
            timer.stop()
            if level >= 3:
                _on_fire_rain_end(hit_enemies)
    )

    add_child(timer)
    timer.start()

func _restore_ally_mana(center: Vector2):
    var allies = get_units_in_range(center, 100.0)
    for ally in allies:
        if ally != self:
            GameManager.add_mana_to_unit(ally, 5)

func _on_fire_rain_end(total_hits: int):
    var bonus_orbs = min(floor(total_hits / 5), 2)
    _spawn_temp_orbs(bonus_orbs)
```

### 6. 龙Lv3完善

```gdscript
# 在 UnitDragon.gd 中更新
func _create_black_hole():
    var black_hole = preload("res://src/Scenes/Effects/BlackHole.tscn").instantiate()
    black_hole.global_position = get_skill_target_position()

    var duration = 4.0 if level < 2 else 6.0
    var radius = 100.0 if level < 3 else 120.0

    black_hole.duration = duration
    black_hole.radius = radius

    if level >= 3:
        GameManager.apply_global_buff("skill_mana_cost_reduction", 0.30)

    black_hole.enemy_entered.connect(func(e): black_hole_enemies.append(e))

    await get_tree().create_timer(duration).timeout

    if level >= 3:
        GameManager.remove_global_buff("skill_mana_cost_reduction")
        _cast_meteor_fall(black_hole.global_position, black_hole_enemies.size())
```

### 7. 配置更新

更新 data/game_data.json：

```json
{
    "units": [
        {"id": "ice_butterfly", "name": "冰晶蝶", "faction": "butterfly", "type": "buff", "cost": 120},
        {"id": "firefly", "name": "萤火虫", "faction": "butterfly", "type": "attack", "cost": 100},
        {"id": "forest_sprite", "name": "木精灵", "faction": "butterfly", "type": "buff", "cost": 120}
    ]
}
```

## 实现步骤

1. 创建 UnitIceButterfly.gd
2. 创建 UnitFirefly.gd
3. 创建 UnitForestSprite.gd
4. 更新 UnitButterfly.gd 添加技能
5. 更新 UnitPhoenix.gd 完善Lv3
6. 更新 UnitDragon.gd 完善Lv3
7. 更新 game_data.json
8. 运行测试

## 自动化测试要求

创建测试用例：

```gdscript
"test_butterfly_ice":
    return {
        "id": "test_butterfly_ice",
        "core_type": "butterfly_totem",
        "initial_gold": 1000,
        "start_wave_index": 1,
        "duration": 15.0,
        "units": [{"id": "ice_butterfly", "x": 0, "y": 1}]
    }
```

运行测试：
```bash
for test in test_butterfly_ice test_butterfly_firefly test_butterfly_sprite; do
    godot --path . --headless -- --run-test=$test
done
```

验证点：
- 冰晶蝶攻击叠加冰冻，3层冻结敌人
- 萤火虫攻击不造成伤害，只致盲
- Lv3萤火虫在敌人Miss时回复法力
- 木精灵使友方攻击概率附加Debuff
- 蝴蝶技能消耗法力附加伤害
- 凤凰Lv3燃烧回蓝和临时法球
- 龙Lv3黑洞期间友方技能消耗-30%

## 进度同步要求

更新 docs/progress.md 中任务 P1-D 的行：

```markdown
| P1-D | in_progress | 已实现冰晶蝶和萤火虫 | 2026-02-19T19:00:00 |
```

## 代码提交要求

1. 在独立分支上工作：`feature/P1-D-butterfly-units`
2. 提交信息格式：`[P1-D] 简要描述`
3. 完成后创建 Pull Request 到 main 分支

## 注意事项

- 这是独立任务，无前置依赖
- 冰冻效果需要Debuff系统支持
- 萤火虫不造成伤害的设计需要在UI中明确说明
- 木精灵被动需要修改所有单位攻击逻辑
