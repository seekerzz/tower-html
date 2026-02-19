# Jules 任务: P1-B 眼镜蛇图腾单位群

## 任务ID
P1-B

## 任务描述
实现眼镜蛇图腾流派的单位：老鼠、蟾蜍，并完善美杜莎Lv3。

## 需要实现的单位

### 1. 老鼠 - Buff单位

```gdscript
class_name UnitRat
extends Unit

@export var plague_duration: float = 4.0

func _ready():
    super._ready()
    EventBus.debuff_applied.connect(_on_debuff_applied)

func _on_debuff_applied(enemy: Enemy, debuff_type: String, stacks: int):
    if debuff_type == "poison":
        enemy.set_meta("plague_infected", true)
        enemy.set_meta("plague_duration", plague_duration)
        if not enemy.is_connected("tree_exited", _on_plagued_enemy_died):
            enemy.tree_exited.connect(_on_plagued_enemy_died.bind(enemy))

func _on_plagued_enemy_died(enemy: Enemy):
    if not enemy.has_meta("plague_infected"):
        return

    var spread_stacks = 2 if level < 2 else 4
    var nearby = get_enemies_in_radius(enemy.global_position, 120.0)
    for e in nearby:
        e.add_poison_stacks(spread_stacks)

        if level >= 3:
            _spread_additional_debuff(e)

func _spread_additional_debuff(enemy: Enemy):
    var debuffs = ["burn", "bleed", "slow"]
    var random_debuff = debuffs[randi() % debuffs.size()]
    enemy.apply_debuff(random_debuff, 1)
```

### 2. 蟾蜍 - 辅助单位

```gdscript
class_name UnitToad
extends Unit

@export var max_traps: int = 1
@export var trap_duration: float = 25.0

var placed_traps: Array[Node] = []

func _ready():
    super._ready()
    if level >= 2:
        max_traps = 2

func _on_skill_activated():
    if placed_traps.size() >= max_traps:
        placed_traps[0].queue_free()
        placed_traps.remove_at(0)
    _place_trap()

func _place_trap():
    var trap = preload("res://src/Scenes/Units/ToadTrap.tscn").instantiate()
    trap.global_position = get_skill_target_position()
    trap.duration = trap_duration
    trap.owner_toad = self
    trap.level = level

    get_tree().current_scene.add_child(trap)
    placed_traps.append(trap)
    trap.trap_triggered.connect(_on_trap_triggered)

func _on_trap_triggered(enemy: Enemy, trap: Node):
    enemy.add_poison_stacks(2)
    if level >= 3:
        _apply_distance_damage_debuff(enemy)

func _apply_distance_damage_debuff(enemy: Enemy):
    var debuff = DistanceDamageDebuff.new()
    debuff.duration = 2.5
    debuff.tick_interval = 0.5
    debuff.damage_calculation = func(e: Enemy):
        var dist_to_core = e.global_position.distance_to(Vector2.ZERO)
        return dist_to_core * 0.08
    enemy.add_child(debuff)
```

### 3. 毒陷阱场景 (ToadTrap.tscn)

```gdscript
class_name ToadTrap
extends Area2D

@export var duration: float = 25.0
@export var trigger_radius: float = 30.0

var owner_toad: Unit
var level: int
var triggered: bool = false

signal trap_triggered(enemy: Enemy, trap: Node)

func _ready():
    var timer = Timer.new()
    timer.wait_time = duration
    timer.one_shot = true
    timer.timeout.connect(queue_free)
    add_child(timer)
    timer.start()

    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node):
    if triggered or not body is Enemy:
        return
    triggered = true
    trap_triggered.emit(body, self)
    _play_trigger_effect()
    queue_free()
```

### 4. 距离伤害Debuff

```gdscript
class_name DistanceDamageDebuff
extends Node

@export var duration: float = 2.5
@export var tick_interval: float = 0.5

var damage_calculation: Callable
var tick_timer: Timer

func _ready():
    tick_timer = Timer.new()
    tick_timer.wait_time = tick_interval
    tick_timer.timeout.connect(_apply_damage)
    add_child(tick_timer)
    tick_timer.start()

    var duration_timer = Timer.new()
    duration_timer.wait_time = duration
    duration_timer.one_shot = true
    duration_timer.timeout.connect(queue_free)
    add_child(duration_timer)
    duration_timer.start()

func _apply_damage():
    var enemy = get_parent() as Enemy
    if not enemy:
        return
    var damage = damage_calculation.call(enemy)
    enemy.take_damage(damage, null)
```

### 5. 美杜莎Lv3完善

```gdscript
# 在 UnitMedusa.gd 中添加
func _on_petrified_enemy_killed(enemy: Enemy):
    var stone = _create_stone_projectile(enemy.global_position)
    if level >= 3 and stone:
        stone.damage = enemy.max_hp * 0.8

func _create_stone_projectile(pos: Vector2) -> Node:
    var stone = preload("res://src/Scenes/Projectiles/StoneProjectile.tscn").instantiate()
    stone.global_position = pos
    var target = get_nearest_enemy(pos)
    if target:
        stone.target = target
        stone.damage = damage * 0.5
        stone.pierce = 1
        get_tree().current_scene.add_child(stone)
        return stone
    return null
```

### 6. 配置更新

更新 data/game_data.json：

```json
{
    "units": [
        {
            "id": "rat",
            "name": "老鼠",
            "faction": "viper",
            "type": "buff",
            "cost": 80,
            "ability": "plague_spread"
        },
        {
            "id": "toad",
            "name": "蟾蜍",
            "faction": "viper",
            "type": "support",
            "cost": 100,
            "ability": "poison_trap"
        }
    ]
}
```

## 实现步骤

1. 创建 UnitRat.gd
2. 创建 UnitToad.gd
3. 创建 ToadTrap.gd 和场景
4. 创建 DistanceDamageDebuff.gd
5. 更新 UnitMedusa.gd 添加Lv3效果
6. 更新 game_data.json
7. 运行测试

## 自动化测试要求

在 src/Scripts/Tests/TestSuite.gd 中创建测试：

```gdscript
"test_viper_rat":
    return {
        "id": "test_viper_rat",
        "core_type": "viper_totem",
        "initial_gold": 1000,
        "start_wave_index": 1,
        "duration": 15.0,
        "units": [{"id": "rat", "x": 0, "y": 1}]
    }
```

运行测试：
```bash
godot --path . --headless -- --run-test=test_viper_rat
godot --path . --headless -- --run-test=test_viper_toad
```

验证点：
- 老鼠使中毒敌人死亡时传播毒素
- Lv2老鼠传播更多层数
- Lv3老鼠额外传播其他Debuff
- 蟾蜍可以放置毒陷阱
- Lv2蟾蜍可放置2个陷阱
- Lv3蟾蜍陷阱附加距离伤害Debuff
- 美杜莎Lv3石块造成80%最大HP伤害

## 进度同步要求

完成每个单位后，更新 docs/progress.md 中任务 P1-B 的行：

```markdown
| P1-B | in_progress | 已实现老鼠和蟾蜍 | 2026-02-19T17:00:00 |
```

## 代码提交要求

1. 在独立分支上工作：`feature/P1-B-viper-units`
2. 提交信息格式：`[P1-B] 简要描述`
3. 完成后创建 Pull Request 到 main 分支

## 注意事项

- 这是独立任务，无前置依赖
- 瘟疫传播机制需要事件系统支持
- 陷阱可以被敌人触发
- 距离伤害与敌人到核心的距离成正比
