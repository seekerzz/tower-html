# Jules 任务: P1-C 蝙蝠图腾单位群

## 任务ID
P1-C

## 任务描述
实现蝙蝠图腾流派的单位：石像鬼、生命链条、鲜血圣杯、血祭术士，并完善蚊子和血法师Lv3。

## 前置条件（代码库中已存在）

- LifestealManager（来自P0-04）
- Bleed系统（来自P0-04）

## 需要实现的单位

### 1. 石像鬼 - 攻击单位

```gdscript
class_name UnitGargoyle
extends Unit

enum State { NORMAL, PETRIFIED }
var current_state: State = State.NORMAL
var reflect_count: int = 0

func _ready():
    super._ready()
    GameManager.core_health_changed.connect(_check_petrify_state)

func _check_petrify_state():
    var health_percent = GameManager.core_health / GameManager.max_core_health
    if health_percent < 0.35 and current_state == State.NORMAL:
        _enter_petrified_state()
    elif health_percent > 0.65 and current_state == State.PETRIFIED:
        _exit_petrified_state()

func _enter_petrified_state():
    current_state = State.PETRIFIED
    can_attack = false
    reflect_count = 1 if level < 2 else 2
    _play_petrify_effect()

func _exit_petrified_state():
    current_state = State.NORMAL
    can_attack = true
    reflect_count = 0
    _play_unpetrify_effect()

func _on_take_damage(attacker: Node, damage: float):
    if current_state == State.PETRIFIED and reflect_count > 0:
        var reflect_damage = damage * 0.15
        if attacker and attacker.has_method("take_damage"):
            attacker.take_damage(reflect_damage, self)
            reflect_count -= 1
```

### 2. 生命链条 - Buff单位

```gdscript
class_name UnitLifeChain
extends Unit

var chained_enemies: Array[Enemy] = []
@export var drain_interval: float = 1.0

func _ready():
    super._ready()
    var timer = Timer.new()
    timer.wait_time = drain_interval
    timer.timeout.connect(_drain_life)
    add_child(timer)
    timer.start()
    _update_chain_targets()

func _update_chain_targets():
    var enemies = get_all_enemies()
    enemies.sort_custom(func(a, b):
        return global_position.distance_to(a.global_position) > \
               global_position.distance_to(b.global_position)
    )
    var max_chains = 1 if level < 2 else 2
    chained_enemies = enemies.slice(0, max_chains)
    _draw_life_chains()

func _drain_life():
    var total_drained = 0.0
    for enemy in chained_enemies:
        if not is_instance_valid(enemy):
            continue
        var drain_amount = 4.0
        enemy.take_damage(drain_amount, self)
        total_drained += drain_amount
        _play_drain_effect(enemy)

    if total_drained > 0:
        GameManager.heal_core(total_drained)

    if level >= 3:
        _apply_damage_distribution()
```

### 3. 鲜血圣杯 - 辅助单位

```gdscript
class_name UnitBloodChalice
extends Unit

@export var overflow_decay: float = 0.15

var overflowed_units: Dictionary = {}

func _ready():
    super._ready()
    EventBus.lifesteal_occurred.connect(_on_lifesteal)

    var timer = Timer.new()
    timer.wait_time = 0.5
    timer.timeout.connect(_apply_effects)
    add_child(timer)
    timer.start()

func _on_lifesteal(unit: Unit, amount: float):
    if unit.current_hp + amount > unit.max_hp:
        var overflow = (unit.current_hp + amount) - unit.max_hp
        overflowed_units[unit.get_instance_id()] = overflow
        unit.current_hp = unit.max_hp

func _apply_effects():
    var decay = 0.10 if level >= 2 else 0.15
    for unit_id in overflowed_units.keys():
        var amount = overflowed_units[unit_id]
        amount *= (1.0 - decay)
        if amount < 1.0:
            overflowed_units.erase(unit_id)
        else:
            overflowed_units[unit_id] = amount

    if level >= 3:
        _apply_core_loss_damage()

func _apply_core_loss_damage():
    var core_lost = GameManager.max_core_health - GameManager.core_health
    var damage = core_lost * 0.5
    var enemies = get_enemies_in_range(attack_range)
    for enemy in enemies:
        enemy.take_damage(damage * 0.5, self)
```

### 4. 血祭术士 - 辅助单位

```gdscript
class_name UnitBloodRitualist
extends Unit

@export var hp_cost_percent: float = 0.20

func _on_skill_activated():
    var hp_cost = GameManager.core_health * hp_cost_percent
    if GameManager.core_health - hp_cost <= 0:
        return

    GameManager.damage_core(hp_cost)

    var bleed_stacks = 2 if level < 2 else 3
    var enemies = get_enemies_in_range(attack_range)
    for enemy in enemies:
        enemy.add_bleed_stacks(bleed_stacks)

    if level >= 3:
        _start_ritual_buff()

func _start_ritual_buff():
    GameManager.apply_global_buff("lifesteal_multiplier", 2.0)
    await get_tree().create_timer(4.0).timeout
    GameManager.remove_global_buff("lifesteal_multiplier")
```

### 5. 蚊子Lv3完善

```gdscript
# 在 UnitMosquito.gd 中更新
func _on_attack_hit(enemy: Enemy):
    super._on_attack_hit(enemy)

    var heal_amount = damage * get_lifesteal_ratio()
    self.heal(heal_amount)

    if level >= 3:
        if enemy.bleed_stacks > 0:
            enemy.take_damage(damage, self)

        if enemy.current_hp <= 0:
            _explode_on_kill(enemy.global_position)

func _explode_on_kill(position: Vector2):
    var explosion = preload("res://src/Scenes/Effects/Explosion.tscn").instantiate()
    explosion.global_position = position
    explosion.radius = 80.0
    explosion.damage = damage * 0.4
    get_tree().current_scene.add_child(explosion)
```

### 6. 血法师Lv3完善

```gdscript
# 在 UnitBloodMage.gd 中更新
func _create_blood_pool():
    # ... existing code ...

    if level >= 3:
        var bleed_timer = Timer.new()
        bleed_timer.wait_time = 1.0
        bleed_timer.timeout.connect(_apply_blood_pool_bleed)
        blood_pool_area.add_child(bleed_timer)
        bleed_timer.start()

func _apply_blood_pool_bleed():
    var bodies = blood_pool_area.get_overlapping_bodies()
    for body in bodies:
        if body is Enemy:
            body.add_bleed_stacks(1)
```

### 7. 配置更新

更新 data/game_data.json：

```json
{
    "units": [
        {"id": "gargoyle", "name": "石像鬼", "faction": "bat", "type": "attack", "cost": 150},
        {"id": "life_chain", "name": "生命链条", "faction": "bat", "type": "buff", "cost": 120},
        {"id": "blood_chalice", "name": "鲜血圣杯", "faction": "bat", "type": "support", "cost": 150},
        {"id": "blood_ritualist", "name": "血祭术士", "faction": "bat", "type": "support", "cost": 120}
    ]
}
```

## 实现步骤

1. 创建 UnitGargoyle.gd
2. 创建 UnitLifeChain.gd
3. 创建 UnitBloodChalice.gd
4. 创建 UnitBloodRitualist.gd
5. 更新 UnitMosquito.gd 添加Lv3效果
6. 更新 UnitBloodMage.gd 添加Lv3效果
7. 更新 game_data.json
8. 运行测试

## 自动化测试要求

创建测试用例：

```gdscript
"test_bat_gargoyle":
    return {
        "id": "test_bat_gargoyle",
        "core_type": "bat_totem",
        "initial_gold": 1000,
        "start_wave_index": 1,
        "duration": 20.0,
        "units": [{"id": "gargoyle", "x": 0, "y": 1}]
    }
```

运行测试：
```bash
for test in test_bat_gargoyle test_bat_life_chain test_bat_chalice test_bat_ritualist; do
    godot --path . --headless -- --run-test=$test
done
```

验证点：
- 石像鬼在核心HP<35%时石化
- 石化时反弹15%伤害
- 生命链条连接最远敌人并偷取生命
- 鲜血圣杯允许吸血超过上限
- 血祭术士消耗20%核心HP施加流血

**测试框架扩展权限：**
如果当前测试框架无法覆盖本任务所需的测试场景（如需要验证石像鬼状态切换、生命偷取数值、吸血溢出处理等），你有权：
1. 修改 `src/Scripts/Tests/AutomatedTestRunner.gd` 以增加新的测试能力
2. 更新 `docs/GameDesign.md` 中的自动化测试框架文档，记录新的测试功能和配置方法
3. 确保新增的测试功能不会破坏现有的其他测试用例

## 进度同步要求

更新 docs/progress.md 中任务 P1-C 的行：

```markdown
| P1-C | in_progress | 已实现石像鬼和生命链条 | 2026-02-19T18:00:00 |
```

## 代码提交要求

1. 在独立分支上工作：`feature/P1-C-bat-units`
2. 提交信息格式：`[P1-C] 简要描述`
3. 完成后创建 Pull Request 到 main 分支

## 注意事项

- 依赖P0-04的流血吸血系统
- 石像鬼状态切换需要视觉反馈
- 血祭术士消耗核心HP需要谨慎处理
