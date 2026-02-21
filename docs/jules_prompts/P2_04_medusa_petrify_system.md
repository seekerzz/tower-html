# Jules 任务: P2-04 美杜莎石化凝视与石块利用系统

## 任务ID
P2-04

## 任务描述
完善美杜莎单位的石化凝视机制，实现石化敌人死亡后生成可利用的石块，对经过的敌人造成伤害和阻挡效果。

## 当前代码位置

- 美杜莎单位: `src/Scripts/Units/Viper/UnitMedusa.gd`
- 敌人基类: `src/Scripts/Enemy.gd`
- 敌人行为: `src/Scripts/Enemies/Behaviors/DefaultBehavior.gd`
- 障碍物系统: `src/Scripts/Barricade.gd` (参考)

## 当前实现分析

`UnitMedusa.gd` 已实现基础石化凝视：
- 每5秒石化最近敌人1秒
- 石化期间敌人无法移动和攻击

**缺失功能**:
1. 石化敌人死亡后未生成石块
2. 没有可交互的石块障碍物系统
3. Lv3: 石块未造成敌人MaxHP伤害

## 实现要求

### 1. 创建 PetrifiedStatus 组件

创建 `src/Scripts/Effects/PetrifiedStatus.gd`：

```gdscript
class_name PetrifiedStatus
extends StatusEffect

var petrify_source: Node = null
var original_color: Color
var petrify_color: Color = Color(0.6, 0.6, 0.6, 1.0)  # 灰色石化

func _init(duration: float = 1.0):
    super._init("petrified", duration)
    is_stun = true  # 石化是一种晕眩效果

func on_apply(enemy: Enemy):
    super.on_apply(enemy)
    original_color = enemy.modulate
    enemy.modulate = petrify_color

    # 停止移动
    enemy.speed = 0
    enemy.velocity = Vector2.ZERO

func on_remove(enemy: Enemy):
    super.on_remove(enemy)
    enemy.modulate = original_color
    enemy.speed = enemy.base_speed

func on_expire(enemy: Enemy):
    # 石化结束时恢复正常
    pass
```

### 2. 修改 UnitMedusa.gd

完善石化凝视和石块生成：

```gdscript
class_name UnitMedusa
extends Unit

@export var petrify_interval: float = 5.0
@export var petrify_duration: float = 1.0
@export var petrify_range: float = 150.0

var timer: float = 0.0
var petrified_enemies: Array[Enemy] = []

func _ready():
    super._ready()
    # Lv2/Lv3 升级
    if level >= 2:
        petrify_duration = 1.5
    if level >= 3:
        petrify_duration = 2.0

func _process(delta):
    timer += delta
    if timer >= petrify_interval:
        timer = 0
        _cast_petrify_gaze()

func _cast_petrify_gaze():
    var target = _find_nearest_enemy()
    if target and is_instance_valid(target):
        _petrify_enemy(target)

func _find_nearest_enemy() -> Enemy:
    var min_dist = 9999.0
    var nearest = null

    for enemy in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(enemy) or enemy.is_dying:
            continue
        if enemy in petrified_enemies:  # 跳过已石化的敌人
            continue

        var dist = global_position.distance_to(enemy.global_position)
        if dist < petrify_range and dist < min_dist:
            min_dist = dist
            nearest = enemy

    return nearest

func _petrify_enemy(enemy: Enemy):
    # 应用石化效果
    var petrify = PetrifiedStatus.new(petrify_duration)
    petrify.petrify_source = self
    enemy.apply_status_effect(petrify)

    petrified_enemies.append(enemy)

    # 视觉反馈
    GameManager.spawn_floating_text(enemy.global_position, "石化!", Color.GRAY)
    _play_petrify_effect(enemy.global_position)

    # 连接死亡信号 - 石化状态下死亡生成石块
    if not enemy.died.is_connected(_on_petrified_enemy_died):
        enemy.died.connect(_on_petrified_enemy_died.bind(enemy))

func _on_petrified_enemy_died(enemy: Enemy):
    if enemy in petrified_enemies:
        petrified_enemies.erase(enemy)

    # 检查是否处于石化状态死亡
    if enemy.has_meta("was_petrified"):
        _spawn_stone_block(enemy.global_position, enemy)

func _spawn_stone_block(pos: Vector2, source_enemy: Enemy):
    var stone = load("res://src/Scenes/Obstacles/StoneBlock.tscn").instantiate()
    stone.global_position = pos

    # 根据美杜莎等级设置石块属性
    stone.max_hp = 100 + (level * 50)
    stone.damage_to_enemies = 20 + (level * 10)

    # Lv3: 石块造成敌人MaxHP的伤害
    if level >= 3 and source_enemy:
        stone.damage_formula = "max_hp_percent"
        stone.damage_percent = 0.1  # 10% MaxHP

    get_tree().current_scene.add_child(stone)

    GameManager.spawn_floating_text(pos, "石块!", Color.DARK_GRAY)

func _play_petrify_effect(pos: Vector2):
    var effect = preload("res://src/Scenes/Effects/PetrifyEffect.tscn").instantiate()
    effect.global_position = pos
    get_tree().current_scene.add_child(effect)
```

### 3. 修改 Enemy.gd

在死亡时标记是否处于石化状态：

```gdscript
func die(killer_source = null):
    if is_dying:
        return
    is_dying = true

    # 检查是否处于石化状态
    if has_status("petrified"):
        set_meta("was_petrified", true)

    died.emit()

    # 其他死亡处理...
    queue_free()

func has_status(status_name: String) -> bool:
    for child in get_children():
        if child is StatusEffect and child.effect_name == status_name:
            return true
    return false
```

### 4. 创建石块障碍物

创建 `src/Scenes/Obstacles/StoneBlock.tscn` 和脚本：

```gdscript
class_name StoneBlock
extends StaticBody2D

var max_hp: float = 100
var current_hp: float = 100
var damage_to_enemies: float = 20
var damage_formula: String = "fixed"  # "fixed" or "max_hp_percent"
var damage_percent: float = 0.0

var affected_enemies: Dictionary = {}  # enemy_instance_id -> last_damage_time
const DAMAGE_COOLDOWN: float = 0.5

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D

func _ready():
    current_hp = max_hp
    add_to_group("obstacles")
    add_to_group("stone_blocks")

    # 设置碰撞
    collision_layer = 8  # 障碍物层
    collision_mask = 2   # 与敌人碰撞

    # 视觉设置
    modulate = Color(0.5, 0.5, 0.5, 1.0)

func _process(delta):
    _check_enemy_collisions()
    _update_visual()

func _check_enemy_collisions():
    # 获取与石块重叠的敌人
    var space_state = get_world_2d().direct_space_state
    var query = PhysicsShapeQueryParameters2D.new()
    query.shape = collision.shape
    query.transform = global_transform
    query.collision_mask = 2  # 敌人层

    var results = space_state.intersect_shape(query)

    for result in results:
        var enemy = result.collider
        if enemy is Enemy:
            _damage_enemy(enemy)

func _damage_enemy(enemy: Enemy):
    var now = Time.get_time_dict_from_system()["second"]
    var enemy_id = enemy.get_instance_id()

    # 检查冷却
    if affected_enemies.has(enemy_id):
        if now - affected_enemies[enemy_id] < DAMAGE_COOLDOWN:
            return

    affected_enemies[enemy_id] = now

    # 计算伤害
    var damage = damage_to_enemies
    if damage_formula == "max_hp_percent":
        damage = enemy.max_hp * damage_percent

    enemy.take_damage(damage, self)

    # 视觉反馈
    GameManager.spawn_floating_text(enemy.global_position, "-%d" % damage, Color.GRAY)

func take_damage(amount: float, source = null):
    current_hp -= amount

    # 受击闪烁
    modulate = Color.WHITE
    await get_tree().create_timer(0.1).timeout
    modulate = Color(0.5, 0.5, 0.5, 1.0)

    if current_hp <= 0:
        _break_stone()

func _break_stone():
    # 破碎特效
    _play_break_effect()

    # 清理
    queue_free()

func _play_break_effect():
    var effect = preload("res://src/Scenes/Effects/StoneBreakEffect.tscn").instantiate()
    effect.global_position = global_position
    get_tree().current_scene.add_child(effect)

func _update_visual():
    # 根据血量调整外观
    var hp_percent = current_hp / max_hp
    sprite.modulate = Color(0.5, 0.5, 0.5, hp_percent)

func get_description() -> String:
    var desc = "石化石块\n"
    desc += "阻挡敌人并对其造成伤害\n"
    desc += "HP: %d/%d" % [current_hp, max_hp]
    if damage_formula == "max_hp_percent":
        desc += "\n伤害: %.0f%% 敌人MaxHP" % (damage_percent * 100)
    else:
        desc += "\n伤害: %.0f" % damage_to_enemies
    return desc
```

### 5. 创建特效场景

**石化特效** (`src/Scenes/Effects/PetrifyEffect.tscn`):
```gdscript
class_name PetrifyEffect
extends Node2D

func _ready():
    var particles = CPUParticles2D.new()
    particles.amount = 15
    particles.lifetime = 0.6
    particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
    particles.emission_sphere_radius = 25
    particles.direction = Vector2.UP
    particles.spread = 45
    particles.gravity = Vector2(0, -50)
    particles.initial_velocity_min = 30
    particles.initial_velocity_max = 60
    particles.scale_amount_min = 2
    particles.scale_amount_max = 5
    particles.color = Color(0.6, 0.6, 0.6, 1.0)
    add_child(particles)
    particles.emitting = true

    await get_tree().create_timer(0.8).timeout
    queue_free()
```

**石块破碎特效** (`src/Scenes/Effects/StoneBreakEffect.tscn`):
```gdscript
class_name StoneBreakEffect
extends Node2D

func _ready():
    var particles = CPUParticles2D.new()
    particles.amount = 20
    particles.lifetime = 0.8
    particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
    particles.emission_sphere_radius = 20
    particles.direction = Vector2.UP
    particles.spread = 180
    particles.gravity = Vector2(0, 100)
    particles.initial_velocity_min = 50
    particles.initial_velocity_max = 100
    particles.scale_amount_min = 3
    particles.scale_amount_max = 6
    particles.color = Color(0.5, 0.5, 0.5, 1.0)
    add_child(particles)
    particles.emitting = true
    particles.one_shot = true

    # 播放破碎音效
    # AudioManager.play_sfx("stone_break")

    await get_tree().create_timer(1.0).timeout
    queue_free()
```

### 6. 在 data/game_data.json 中添加配置

```json
{
    "obstacles": {
        "stone_block": {
            "name": "石化石块",
            "description": "美杜莎石化敌人死亡后留下的石块，阻挡敌人并造成伤害",
            "base_hp": 100,
            "base_damage": 20
        }
    }
}
```

## 自动化测试要求

在 `src/Scripts/Tests/TestSuite.gd` 中添加测试用例：

```gdscript
"test_medusa_petrify":
    return {
        "id": "test_medusa_petrify",
        "core_type": "viper_totem",
        "initial_gold": 1000,
        "start_wave_index": 1,
        "duration": 30.0,
        "units": [
            {"id": "medusa", "x": 0, "y": 1}
        ],
        "description": "测试美杜莎石化凝视和石块生成（需要等待石化触发）"
    }
```

运行测试：
```bash
godot --path . --headless -- --run-test=test_medusa_petrify
```

验证点：
- 美杜莎每5秒石化最近敌人
- 石化敌人无法移动和攻击
- 石化敌人死亡后生成石块
- 石块对经过的敌人造成伤害
- Lv3石块造成敌人MaxHP百分比伤害

## 进度同步要求

更新 `docs/progress.md`：

```markdown
| P2-04 | in_progress | 完善美杜莎石化与石块系统 | 2026-02-20T12:00:00 |
```

完成后更新为：
```markdown
| P2-04 | completed | 石化石块系统完整实现 PR#XXX | 2026-02-20TXX:00:00 |
```

## 代码提交要求

1. 在独立分支上工作：`feature/P2-04-medusa-petrify`
2. 提交信息格式：`[P2-04] 完善美杜莎石化凝视与石块利用系统`
3. 完成后创建 Pull Request 到 main 分支

## 注意事项

- 石化是一种强控制，持续时间不宜过长
- 石块需要有合理的血量，避免过于强大
- 石块数量可能需要上限控制，避免场景过于拥挤
- 考虑石块对路径的影响，不要完全阻断敌人路径

---

## 任务标识

Task being executed: P2-04
