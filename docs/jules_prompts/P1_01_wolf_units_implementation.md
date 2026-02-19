# Jules 任务: P1-A 狼图腾单位群

## 任务ID
P1-A

## 任务描述
实现狼图腾阵营的所有单位。这些单位依赖魂魄系统（P0-01）和召唤系统（P0-03）已存在于代码库中。

## 前置条件（代码库中已存在）

- SoulManager（来自P0-01）
- SummonManager（来自P0-03）
- MechanicWolfTotem（来自P0-01）

## 需要实现的单位

### 1. 血食 - Buff单位

```gdscript
class_name UnitBloodFood
extends Unit

func _ready():
    super._ready()
    SoulManager.soul_count_changed.connect(_on_soul_changed)
    _update_buff()

func _on_soul_changed(_new_count: int, _delta: int):
    _update_buff()

func _update_buff():
    var bonus_per_soul = 0.005 if level < 3 else 0.008
    var total_bonus = SoulManager.current_souls * bonus_per_soul
    GameManager.apply_global_buff("damage_percent", total_bonus)
```

### 2. 猛虎 - 攻击单位

```gdscript
class_name UnitTiger
extends Unit

var soul_stacks: int = 0
var max_soul_stacks: int = 8

func _ready():
    super._ready()
    EventBus.enemy_died.connect(_on_enemy_died)

func _on_enemy_died(enemy: Enemy, killer: Node):
    if killer == self:
        soul_stacks = min(soul_stacks + 1, max_soul_stacks)
        _update_crit()

func _update_crit():
    var crit_bonus = soul_stacks * 0.025
    crit_chance = base_crit_chance + crit_bonus

func _on_skill_activated():
    _cast_meteor_shower()

func _cast_meteor_shower():
    var meteor_count = 8 if level < 2 else 10
    for i in range(meteor_count):
        await get_tree().create_timer(i * 0.2).timeout
        _spawn_meteor()
```

### 3. 恶霸犬 - 攻击单位

```gdscript
class_name UnitDog
extends Unit

func _ready():
    super._ready()
    GameManager.core_health_changed.connect(_on_core_health_changed)
    _update_attack_speed()

func _on_core_health_changed(_new: float, _max: float):
    _update_attack_speed()

func _update_attack_speed():
    var health_percent = GameManager.core_health / GameManager.max_core_health
    var health_lost = 1.0 - health_percent
    var bonus_per_10 = 0.04 if level < 2 else 0.10
    var speed_bonus = floor(health_lost * 10) * bonus_per_10
    attack_speed_multiplier = 1.0 + speed_bonus

    if level >= 3 and attack_speed_multiplier >= 1.75:
        enable_splash_damage()
```

### 4. 狼 - 攻击单位

```gdscript
class_name UnitWolf
extends Unit

var consumed_data: Dictionary = {}

func _ready():
    super._ready()
    # 放置时自动吞噬最近单位
    _auto_devour()

func _auto_devour():
    var nearest = _get_nearest_unit()
    if nearest:
        _devour_unit(nearest)

func _devour_unit(target: Unit):
    base_damage += target.base_damage * 0.4
    max_hp += target.max_hp * 0.4
    current_hp = max_hp
    consumed_data = {"unit_id": target.unit_id}
    SoulManager.add_souls(10, "wolf_devour")
    target.queue_free()

func can_upgrade() -> bool:
    return level < 2  # 最高2级
```

### 5. 鬣狗 - 攻击单位

```gdscript
class_name UnitHyena
extends Unit

func _on_attack_hit(enemy: Enemy):
    super._on_attack_hit(enemy)
    var enemy_hp_percent = enemy.current_hp / enemy.max_hp

    if enemy_hp_percent < 0.25:
        var extra_hits = 1 if level < 3 else 2
        var damage_percent = 0.2 if level < 2 else 0.4
        for i in range(extra_hits):
            await get_tree().create_timer(0.1).timeout
            enemy.take_damage(damage * damage_percent, self)
```

### 6. 狐狸 - Buff单位

```gdscript
class_name UnitFox
extends Unit

@export var charm_chance: float = 0.15
var charmed_enemies: Array[Enemy] = []
var max_charms: int = 1

func _ready():
    super._ready()
    if level >= 3:
        max_charms = 2

func _on_attacked_by_enemy(enemy: Enemy):
    if charmed_enemies.size() < max_charms and randf() < charm_chance:
        _charm_enemy(enemy)

func _charm_enemy(enemy: Enemy):
    enemy.set_meta("charmed", true)
    enemy.set_meta("charm_source", self)
    charmed_enemies.append(enemy)
    # 敌人攻击其他敌人
    enemy.faction = "player"
```

### 7. 羊灵 - 辅助单位

```gdscript
class_name UnitSheepSpirit
extends Unit

func _ready():
    super._ready()
    EventBus.enemy_died.connect(_on_enemy_died)

func _on_enemy_died(enemy: Enemy, _killer: Node):
    if global_position.distance_to(enemy.global_position) > attack_range:
        return

    var num_clones = 1 if level < 3 else 2
    var inherit = 0.4 if level < 2 else 0.6

    for i in range(num_clones):
        var offset = Vector2(randf() * 100 - 50, randf() * 100 - 50)
        SummonManager.create_summon({
            "type": "enemy_clone",
            "position": enemy.global_position + offset,
            "source_enemy": enemy,
            "inherit_ratio": inherit,
            "lifetime": -1,
            "faction": "player"
        })
```

### 8. 狮子 - 攻击单位

```gdscript
class_name UnitLion
extends Unit

func _ready():
    super._ready()
    attack_type = "circular_shockwave"

func _perform_attack():
    var shockwave = preload("res://src/Scenes/Effects/Shockwave.tscn").instantiate()
    shockwave.global_position = global_position
    shockwave.damage = damage
    shockwave.radius = attack_range
    get_tree().current_scene.add_child(shockwave)
```

## 配置更新

更新 data/game_data.json 添加全部8个单位：

```json
{
    "units": [
        {"id": "blood_food", "name": "血食", "faction": "wolf", "type": "buff", "cost": 100},
        {"id": "tiger", "name": "猛虎", "faction": "wolf", "type": "attack", "cost": 150},
        {"id": "dog", "name": "恶霸犬", "faction": "wolf", "type": "attack", "cost": 80},
        {"id": "wolf", "name": "狼", "faction": "wolf", "type": "attack", "cost": 120},
        {"id": "hyena", "name": "鬣狗", "faction": "wolf", "type": "attack", "cost": 100},
        {"id": "fox", "name": "狐狸", "faction": "wolf", "type": "buff", "cost": 120},
        {"id": "sheep_spirit", "name": "羊灵", "faction": "wolf", "type": "support", "cost": 150},
        {"id": "lion", "name": "狮子", "faction": "wolf", "type": "attack", "cost": 200}
    ]
}
```

## 实现步骤

1. 创建 UnitBloodFood.gd
2. 创建 UnitTiger.gd
3. 创建 UnitDog.gd
4. 创建 UnitWolf.gd
5. 创建 UnitHyena.gd
6. 创建 UnitFox.gd
7. 创建 UnitSheepSpirit.gd
8. 创建 UnitLion.gd
9. 更新 game_data.json
10. 创建测试用例
11. 运行测试

## 自动化测试要求

为每个单位创建测试用例：

```gdscript
"test_wolf_tiger":
    return {
        "id": "test_wolf_tiger",
        "core_type": "wolf_totem",
        "initial_gold": 1000,
        "start_wave_index": 1,
        "duration": 15.0,
        "units": [{"id": "tiger", "x": 0, "y": 1}]
    }
```

运行所有测试：
```bash
for test in test_wolf_tiger test_wolf_dog test_wolf_wolf test_wolf_hyena test_wolf_fox test_wolf_sheep test_wolf_lion; do
    godot --path . --headless -- --run-test=$test
done
```

## 进度同步要求

实现每个单位后，更新 docs/progress.md：

```markdown
| P1-A | in_progress | 已实现猛虎、恶霸犬、狼 | 2026-02-19T16:00:00 |
```

## 代码提交要求

1. 在独立分支上工作：`feature/P1-A-wolf-units`
2. 提交信息格式：`[P1-A] 简要描述`
3. 完成后创建 Pull Request 到 main 分支

## 注意事项

- 此任务假设P0-01和P0-03已在代码库中
- 不要重新实现SoulManager或SummonManager
- 每个单位应独立工作
- 只专注于狼阵营单位
