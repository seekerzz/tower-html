# Jules 任务: P2-02 魅惑/控制敌人系统完善

## 任务ID
P2-02

## 任务描述
完善狐狸单位的魅惑机制，实现完整的敌人控制敌人系统。被魅惑的敌人会攻击其他敌人，并在被核心击杀时为玩家提供魂魄。

## 当前代码位置

- 狐狸单位: `src/Scripts/Units/Wolf/UnitFox.gd`
- 敌人基类: `src/Scripts/Enemy.gd`
- 敌人行为: `src/Scripts/Enemies/Behaviors/DefaultBehavior.gd`
- 魂魄系统: `src/Autoload/SoulManager.gd`

## 当前实现分析

`UnitFox.gd` 已实现基础魅惑：
- 被敌人攻击时有15%概率魅惑敌人
- 被魅惑敌人 faction 设为 "player"
- 视觉反馈：粉色色调 + "Charmed!" 文字

**缺失功能**:
1. 被魅惑敌人不会主动攻击其他敌人
2. 魅惑敌人被核心击杀时未获得魂魄
3. 没有魅惑持续时间限制
4. 魅惑状态下敌人的AI目标选择未完善

## 实现要求

### 1. 完善 CharmedEnemyBehavior

创建 `src/Scripts/Enemies/Behaviors/CharmedEnemyBehavior.gd`:

```gdscript
class_name CharmedEnemyBehavior
extends EnemyBehavior

var charm_duration: float = 3.0
var charm_timer: float = 0.0
var charm_source: Node = null
var target_enemy: Enemy = null

func init(enemy_node: CharacterBody2D, enemy_data: Dictionary):
    super.init(enemy_node, enemy_data)
    charm_timer = charm_duration
    _find_target()

func _find_target():
    # 寻找最近的非魅惑敌人作为目标
    var min_dist = 9999.0
    var nearest = null

    for e in enemy.get_tree().get_nodes_in_group("enemies"):
        if e == enemy or not is_instance_valid(e):
            continue
        if e.get("faction") == "player":  # 跳过其他被魅惑的敌人
            continue
        var dist = enemy.global_position.distance_to(e.global_position)
        if dist < min_dist:
            min_dist = dist
            nearest = e

    target_enemy = nearest

func physics_process(delta: float) -> bool:
    charm_timer -= delta

    if charm_timer <= 0:
        _end_charm()
        return false  # 让默认行为接管

    if not is_instance_valid(target_enemy) or target_enemy.is_dying:
        _find_target()

    if target_enemy:
        # 向目标移动
        var dir = (target_enemy.global_position - enemy.global_position).normalized()
        enemy.velocity = dir * enemy.speed * 1.2  # 魅惑时移速+20%
        enemy.move_and_slide()

        # 攻击检测
        if enemy.global_position.distance_to(target_enemy.global_position) < 30:
            _attack_target()
    else:
        # 没有目标时向核心反方向移动
        var away_from_core = (enemy.global_position - GameManager.core_position).normalized()
        enemy.velocity = away_from_core * enemy.speed
        enemy.move_and_slide()

    return true

func _attack_target():
    if target_enemy and is_instance_valid(target_enemy):
        var damage = enemy.enemy_data.get("damage", 10)
        target_enemy.take_damage(damage, enemy)

func _end_charm():
    enemy.set("faction", "enemy")
    enemy.modulate = Color.WHITE
    if charm_source and is_instance_valid(charm_source):
        charm_source.charmed_enemies.erase(enemy)
    # 切换回默认行为
    enemy._init_behavior()
```

### 2. 修改 Enemy.gd

添加魅惑状态管理和行为切换：

```gdscript
# 在 Enemy.gd 中添加
func apply_charm(source_unit, duration: float = 3.0):
    if behavior:
        behavior.queue_free()

    var charmed_behavior = load("res://src/Scripts/Enemies/Behaviors/CharmedEnemyBehavior.gd").new()
    charmed_behavior.charm_duration = duration
    charmed_behavior.charm_source = source_unit
    add_child(charmed_behavior)
    behavior = charmed_behavior

    faction = "player"
    modulate = Color(1.0, 0.5, 1.0)

func _on_death_from_core(killer_source):
    # 如果被魅惑且被核心/玩家单位击杀
    if get("faction") == "player" and has_meta("charm_source"):
        # 获得1层魂魄
        SoulManager.add_souls(1, "charm_kill")
        var source = get_meta("charm_source")
        if is_instance_valid(source):
            GameManager.spawn_floating_text(global_position, "+1 魂魄", Color.MAGENTA)
```

### 3. 完善 UnitFox.gd

更新魅惑逻辑以使用新的行为系统：

```gdscript
func _charm_enemy(enemy: Enemy):
    if enemy.has_method("apply_charm"):
        var duration = 3.0
        if level >= 2:
            duration = 4.0
        enemy.apply_charm(self, duration)
        charmed_enemies.append(enemy)

        GameManager.spawn_floating_text(enemy.global_position, "魅惑!", Color.MAGENTA)

        # 连接死亡信号
        if not enemy.died.is_connected(_on_charmed_enemy_died):
            enemy.died.connect(_on_charmed_enemy_died.bind(enemy))

func _on_charmed_enemy_died(enemy: Enemy):
    if enemy in charmed_enemies:
        charmed_enemies.erase(enemy)
        # Lv3: 群体魅惑可同时魅惑2个敌人，已在 _ready 中设置 max_charms
```

### 4. 更新 UnitFox Lv3 机制

```gdscript
func _ready():
    super._ready()
    max_charms = 1
    if level >= 2:
        charm_chance = 0.25  # Lv2: 25%概率
    if level >= 3:
        max_charms = 2  # Lv3: 可同时魅惑2个敌人
```

### 5. 添加魅惑特效

在 `src/Scripts/Effects/CharmEffect.gd` 创建：

```gdscript
class_name CharmEffect
extends Node2D

var particles: CPUParticles2D

func _ready():
    particles = CPUParticles2D.new()
    particles.amount = 20
    particles.lifetime = 0.5
    particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
    particles.emission_sphere_radius = 20
    particles.direction = Vector2.UP
    particles.spread = 30
    particles.gravity = Vector2.ZERO
    particles.initial_velocity_min = 20
    particles.initial_velocity_max = 40
    particles.scale_amount_min = 2
    particles.scale_amount_max = 4
    particles.color = Color.MAGENTA
    add_child(particles)
    particles.emitting = true

    await get_tree().create_timer(1.0).timeout
    queue_free()
```

## 自动化测试要求

在 `src/Scripts/Tests/TestSuite.gd` 中添加测试用例：

```gdscript
"test_charm_system":
    return {
        "id": "test_charm_system",
        "core_type": "wolf_totem",
        "initial_gold": 1000,
        "start_wave_index": 1,
        "duration": 25.0,
        "units": [
            {"id": "fox", "x": 1, "y": 0},
            {"id": "yak_guardian", "x": 0, "y": 1}
        ],
        "description": "测试狐狸魅惑系统（需要等待敌人攻击触发魅惑）"
    }
```

运行测试：
```bash
godot --path . --headless -- --run-test=test_charm_system
```

验证点：
- 狐狸被攻击时有概率魅惑敌人
- 被魅惑敌人会攻击其他敌人
- 魅惑敌人被击杀时获得魂魄
- 魅惑有持续时间限制

## 进度同步要求

更新 `docs/progress.md`：

```markdown
| P2-02 | in_progress | 完善魅惑/控制敌人系统 | 2026-02-20T12:00:00 |
```

完成后更新为：
```markdown
| P2-02 | completed | 魅惑系统完整实现 PR#XXX | 2026-02-20TXX:00:00 |
```

## 代码提交要求

1. 在独立分支上工作：`feature/P2-02-charm-system`
2. 提交信息格式：`[P2-02] 完善魅惑/控制敌人系统`
3. 完成后创建 Pull Request 到 main 分支

## 注意事项

- 魅惑的敌人需要有明显的视觉区分（粉色色调）
- 确保魅惑结束时正确恢复敌人AI
- 避免魅惑敌人和正常敌人重叠时的问题
- 考虑性能：定期检查目标而不是每帧

---

## 任务标识

Task being executed: P2-02
