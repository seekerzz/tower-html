# P2-04b: 美杜莎石化效果重新设计

## 任务背景

当前美杜莎的石化效果会生成石块障碍物，需要重新设计为更流畅的视觉效果。

## 需求变更

### 1. 石化效果重新设计

**旧设计（需要移除）：**
- 石化敌人消失，生成石块障碍物
- 石块会阻挡其他敌人移动

**新设计要求：**
- 石化时：敌人保持原有图像，颜色变为灰色（modulate = Color.GRAY），停止移动和攻击
- 石化期间：敌人变为"幽灵状态"，不阻挡其他敌人的路径（碰撞层修改）
- 石化解除或死亡时：如果是死亡，触发碎裂效果

### 2. 碎裂效果设计

当石化的敌人被击败时：

```
碎裂效果要求：
1. 敌人图像保持灰度状态
2. 分裂成3-6个随机大小的碎块
3. 每个碎块具有不同的质量（mass），影响飞散速度
4. 碎块使用简单的矩形或圆形（Color.DARK_GRAY）
5. 碎块向随机方向飞散（速度基于质量：质量越小飞得越快）
6. 碎块具有物理效果（重力、碰撞）
7. 2-3秒后碎块淡出并消失
```

### 3. 具体实现步骤

**Step 1: 修改 PetrifiedStatus.gd**
- 石化时设置 `target.modulate = Color.GRAY`
- 石化时设置敌人的 collision_layer 为不阻挡其他敌人
- 石化结束时恢复原始颜色和碰撞层
- 添加标记 `is_petrified` 用于死亡判断

**Step 2: 修改 Enemy.gd**
- 死亡时检查是否有石化标记
- 如果有，调用新的碎裂效果而不是普通死亡动画

**Step 3: 创建 PetrifiedShatterEffect.gd / .tscn**
- 创建新的碎裂效果场景
- 生成随机3-6个碎块（RigidBody2D）
- 每个碎块：
  - 随机大小（10-30像素）
  - 随机质量（1.0-3.0），质量影响飞散力度
  - 随机飞散方向（360度）
  - 飞散速度 = 基础速度 / mass
  - 受到重力影响
  - 与墙壁和其他碎块碰撞
  - 2-3秒后淡出消失

**Step 4: 修改 Medusa.gd**
- 移除生成 StoneBlock 的逻辑（_spawn_stone_block 函数）
- 保留石化凝视的计时器和目标选择逻辑
- 石化持续时间：Lv1=3秒, Lv2=5秒, Lv3=8秒（与game_data.json一致）

**Step 5: 删除旧文件（如不再需要）**
- StoneBlock.gd 和 StoneBlock.tscn（确认其他地方不使用后可删除）

### 4. 关键代码参考

**PetrifiedStatus.gd 修改：**
```gdscript
func setup(target: Node, source: Object, params: Dictionary):
    super.setup(target, source, params)
    petrify_source = source

    if params.has("duration"):
        self.duration = params.duration

    if target is Node2D:
        original_color = target.modulate
        target.modulate = Color.GRAY  # 变灰
        target.set_meta("is_petrified", true)  # 标记石化状态

        # 修改碰撞层，不阻挡其他敌人
        if target.has_method("set_petrified_collision"):
            target.set_petrified_collision(true)

    # 停止移动
    if target.has_method("apply_stun"):
        target.apply_stun(duration)

func _exit_tree():
    var target = get_parent()
    if is_instance_valid(target) and (target is Node2D):
        target.modulate = original_color  # 恢复颜色
        target.remove_meta("is_petrified")  # 移除标记

        # 恢复碰撞层
        if target.has_method("set_petrified_collision"):
            target.set_petrified_collision(false)
```

**Enemy.gd 死亡处理修改：**
```gdscript
func die(killer_unit = null):
    if is_dying: return
    is_dying = true

    # 检查是否处于石化状态
    if has_meta("is_petrified") and get_meta("is_petrified"):
        _play_petrified_death_effect()
    else:
        # 普通死亡动画
        pass

    # ... 其余死亡逻辑

func _play_petrified_death_effect():
    # 创建碎裂效果
    var shatter = load("res://src/Scenes/Effects/PetrifiedShatterEffect.tscn").instantiate()
    shatter.global_position = global_position
    shatter.enemy_sprite = sprite.texture  # 传递敌人图像（可选）
    get_tree().current_scene.add_child(shatter)
```

**PetrifiedShatterEffect.gd 框架：**
```gdscript
extends Node2D

var debris_count: int = 0
var debris_pieces: Array = []

func _ready():
    _create_shatter()

func _create_shatter():
    var count = randi_range(3, 6)  # 3-6个碎块

    for i in range(count):
        var debris = _create_debris()
        add_child(debris)
        debris_pieces.append(debris)

    # 2-3秒后淡出
    await get_tree().create_timer(2.5).timeout
    _fade_out()

func _create_debris() -> RigidBody2D:
    var debris = RigidBody2D.new()

    # 随机大小
    var size = randf_range(10, 30)

    # 碰撞形状
    var shape = RectangleShape2D.new()
    shape.extents = Vector2(size, size)
    var collision = CollisionShape2D.new()
    collision.shape = shape
    debris.add_child(collision)

    # 视觉
    var visual = Polygon2D.new()
    visual.polygon = [Vector2(-size, -size), Vector2(size, -size), Vector2(size, size), Vector2(-size, size)]
    visual.color = Color.DARK_GRAY
    debris.add_child(visual)

    # 随机质量
    var mass = randf_range(1.0, 3.0)
    debris.mass = mass

    # 随机飞散方向和速度（质量越小飞得越快）
    var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
    var speed = randf_range(200, 400) / mass
    debris.linear_velocity = direction * speed

    # 添加随机旋转
    debris.angular_velocity = randf_range(-5, 5)

    return debris

func _fade_out():
    # 所有碎块淡出并删除
    for debris in debris_pieces:
        if is_instance_valid(debris):
            # Tween淡出
            pass
    await get_tree().create_timer(0.5).timeout
    queue_free()
```

### 5. 验收标准

- [ ] 美杜莎攻速正常（atkSpeed=1.5，已修复）
- [ ] 石化时敌人变灰，不阻挡其他敌人路径
- [ ] 石化敌人死亡时产生3-6个碎块
- [ ] 碎块大小、质量随机，飞散方向随机
- [ ] 碎块受物理影响（重力、碰撞）
- [ ] 碎块2-3秒后自动消失
- [ ] 石化解除后敌人恢复正常颜色和碰撞

### 6. 文件清单

**需要修改：**
- `src/Scripts/Effects/PetrifiedStatus.gd`
- `src/Scripts/Enemy.gd`
- `src/Scripts/Units/Behaviors/Medusa.gd`
- `data/game_data.json`（atkSpeed已改为1.5）

**需要创建：**
- `src/Scripts/Effects/PetrifiedShatterEffect.gd`
- `src/Scenes/Effects/PetrifiedShatterEffect.tscn`

**需要删除（如没有其他依赖）：**
- `src/Scripts/Obstacles/StoneBlock.gd`
- `src/Scenes/Obstacles/StoneBlock.tscn`

### 7. 注意事项

1. 确保石化状态的敌人在被其他单位攻击时不会异常（伤害正常计算）
2. 碎块不需要造成伤害，仅为视觉效果
3. 碎块的物理碰撞应该只与墙壁碰撞，不影响敌人路径
4. 保持现有石化持续时间逻辑（与Medusa等级相关）
