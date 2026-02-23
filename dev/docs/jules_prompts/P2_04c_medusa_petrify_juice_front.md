# P2-04c: 美杜莎石化系统Juice Front重设计

## 任务背景

当前石化效果已经实现了基础功能（敌人变灰、碎裂效果），但需要进一步打磨(Juice Front)：
1. 石化敌人应保持原有图像冻结在石化那一刻（停止动画）
2. 石化敌人死亡时，尸体应沿攻击方向射出
3. 碎裂效果应使用敌人原有图像，而不是通用灰色方块
4. 石块击中其他敌人时造成伤害

## 需求规格

### 1. 石化效果修改

**冻结动画：**
- 石化时停止敌人的visual_controller动画（调用 `set_idle_enabled(false)`）
- 石化解除后恢复动画
- 移除当前修改碰撞层的逻辑（石化敌人保持正常碰撞）

### 2. 死亡效果重设计

**石块抛射物系统：**

```gdscript
# 石块属性
- 飞散方向: 沿 last_hit_direction（最后一击的攻击方向）
- 飞散速度: 300-450 (根据质量调整)
- 扩散角度: ±30度随机
- 碎块数量: 3-6个
- 碎块形状: 使用敌人原图像分割（Polygon2D + UV映射）
- 碎块颜色: Color.GRAY（石化色调）
- 重力影响: 0.5倍重力
- 持续时间: 3秒后淡出消失
```

**伤害机制：**
```gdscript
- 伤害来源: 被石化敌人的 max_hp × damage_percent
- LV1: 伤害百分比 = 10%
- LV2: 伤害百分比 = 10%
- LV3: 伤害百分比 = 20%
- 每个敌人只能被击中一次（防止多个碎片同时命中造成多次伤害）
```

### 3. 具体实现步骤

**Step 1: 修改 PetrifiedStatus.gd**

```gdscript
class_name PetrifiedStatus
extends StatusEffect

var original_color: Color
var petrify_color: Color = Color.GRAY
var petrify_source: Node = null  # 新增：引用美杜莎单位用于等级判断

func _init(duration: float = 1.0):
    type_key = "petrified"
    self.duration = duration

func setup(target: Node, source: Object, params: Dictionary):
    super.setup(target, source, params)
    petrify_source = source
    if params.has("duration"):
        self.duration = params.duration

    if target is Node2D:
        original_color = target.modulate
        target.modulate = petrify_color
        target.set_meta("is_petrified", true)
        target.set_meta("petrify_source", source)  # 保存引用用于伤害计算

        # 冻结动画
        if target.visual_controller:
            target.visual_controller.set_idle_enabled(false)

    # 停止移动
    if target.has_method("apply_stun"):
        target.apply_stun(duration)

func _exit_tree():
    var target = get_parent()
    if is_instance_valid(target) and (target is Node2D):
        target.modulate = original_color
        target.remove_meta("is_petrified")
        target.remove_meta("petrify_source")

        # 恢复动画
        if target.visual_controller:
            target.visual_controller.set_idle_enabled(true)
```

**Step 2: 修改 Enemy.gd**

修改 `_play_petrified_death_effect` 函数：

```gdscript
func _play_petrified_death_effect():
    # 计算伤害百分比
    var damage_percent = 0.1  # 默认LV1/LV2
    var petrify_source = get_meta("petrify_source", null)
    if petrify_source and petrify_source.level >= 3:
        damage_percent = 0.2  # LV3: 20%

    var shatter = load("res://src/Scenes/Effects/PetrifiedShatterEffect.tscn").instantiate()
    shatter.global_position = global_position
    shatter.launch_direction = last_hit_direction
    shatter.damage_percent = damage_percent
    shatter.source_max_hp = max_hp
    shatter.enemy_texture = AssetLoader.get_enemy_icon(type_key)
    shatter.enemy_color = enemy_data.color

    get_tree().current_scene.add_child(shatter)
```

**Step 3: 重写 PetrifiedShatterEffect.gd**

```gdscript
extends Node2D

var launch_direction: Vector2 = Vector2.RIGHT
var damage_percent: float = 0.1
var source_max_hp: float = 100
var enemy_texture: Texture2D = null
var enemy_color: Color = Color.GRAY

const BASE_SPEED: float = 300.0
const SPEED_VARIATION: float = 150.0
const LIFETIME: float = 3.0
const FRAGMENT_COUNT_MIN: int = 3
const FRAGMENT_COUNT_MAX: int = 6
const SPREAD_ANGLE: float = 30.0  # 度

var fragments: Array = []
var hit_enemies: Dictionary = {}

func _ready():
    if launch_direction == Vector2.ZERO:
        launch_direction = Vector2.RIGHT
    _create_fragments()

    # 延迟后开始淡出
    var timer = get_tree().create_timer(LIFETIME)
    timer.timeout.connect(_fade_out)

func _create_fragments():
    var count = randi_range(FRAGMENT_COUNT_MIN, FRAGMENT_COUNT_MAX)

    # 预定义几种碎块形状（相对坐标，-0.5到0.5范围）
    var shape_templates = [
        [Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0, 0.5)],  # 三角形
        [Vector2(-0.5, -0.5), Vector2(0.3, -0.5), Vector2(0.5, 0.5), Vector2(-0.3, 0.5)],  # 四边形1
        [Vector2(-0.3, -0.5), Vector2(0.5, -0.3), Vector2(0.3, 0.5), Vector2(-0.5, 0.3)],  # 四边形2
        [Vector2(0, -0.5), Vector2(0.5, -0.2), Vector2(0.3, 0.5), Vector2(-0.3, 0.5), Vector2(-0.5, -0.2)],  # 五边形
    ]

    var texture_size = enemy_texture.get_size() if enemy_texture else Vector2(40, 40)
    var fragment_scale = 30.0  # 基础碎块大小

    for i in range(count):
        var shape_points = shape_templates[i % shape_templates.size()]
        var fragment = _create_single_fragment(i, count, shape_points, texture_size, fragment_scale)
        add_child(fragment)
        fragments.append(fragment)

func _create_single_fragment(index: int, total: int, shape_points: Array, tex_size: Vector2, scale: float) -> RigidBody2D:
    var fragment = RigidBody2D.new()
    fragment.collision_layer = 0  # 不与其他碎块碰撞
    fragment.collision_mask = 2   # 只检测敌人层

    # 创建碰撞形状
    var scaled_points = PackedVector2Array()
    for p in shape_points:
        scaled_points.append(p * scale)

    var collision_shape = CollisionPolygon2D.new()
    collision_shape.polygon = scaled_points
    fragment.add_child(collision_shape)

    # 创建视觉 - 使用Polygon2D显示纹理的一部分
    var visual = Polygon2D.new()
    visual.polygon = scaled_points
    visual.color = Color.GRAY  # 石化色调

    if enemy_texture:
        visual.texture = enemy_texture
        visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

        # 计算UV坐标，将图像分割显示
        var cols = ceil(sqrt(float(total)))
        var rows = ceil(float(total) / cols)
        var col = index % int(cols)
        var row = index / int(cols)

        var u_size = 1.0 / cols
        var v_size = 1.0 / rows

        var uvs = PackedVector2Array()
        for p in shape_points:
            var u = (col + p.x + 0.5) / cols
            var v = (row + p.y + 0.5) / rows
            uvs.append(Vector2(u, v))
        visual.uv = uvs

    fragment.add_child(visual)

    # 设置物理属性
    fragment.mass = randf_range(0.5, 2.0)
    fragment.gravity_scale = 0.5

    # 计算飞散速度
    var spread_rad = deg_to_rad(SPREAD_ANGLE)
    var angle_offset = randf_range(-spread_rad, spread_rad)
    var fly_direction = launch_direction.rotated(angle_offset).normalized()

    var speed = (BASE_SPEED + randf_range(-SPEED_VARIATION, SPEED_VARIATION)) / fragment.mass
    fragment.linear_velocity = fly_direction * speed
    fragment.angular_velocity = randf_range(-10.0, 10.0)

    # 连接碰撞信号
    fragment.body_entered.connect(_on_fragment_hit_enemy.bind(fragment))

    return fragment

func _on_fragment_hit_enemy(enemy: Node2D, _fragment: RigidBody2D):
    if not enemy.is_in_group("enemies"):
        return
    if not enemy.has_method("take_damage"):
        return

    var enemy_id = enemy.get_instance_id()
    if hit_enemies.has(enemy_id):
        return

    hit_enemies[enemy_id] = true

    var damage = source_max_hp * damage_percent
    enemy.take_damage(damage, null, "physical", self, 0)

    GameManager.spawn_floating_text(
        enemy.global_position,
        "石块冲击!",
        Color.GRAY
    )

func _fade_out():
    var tween = create_tween()
    tween.set_parallel(true)
    for fragment in fragments:
        if is_instance_valid(fragment):
            tween.tween_property(fragment, "modulate:a", 0.0, 0.5)
    await tween.finished
    queue_free()
```

**Step 4: 修改 Medusa.gd**

确保正确传递美杜莎单位引用：

```gdscript
func _petrify_enemy(enemy: Node2D):
    var duration = 1.0
    if unit.level >= 2:
        duration = 1.5
    if unit.level >= 3:
        duration = 2.0

    # Apply PetrifiedStatus with source reference
    if enemy.has_method("apply_status"):
        enemy.apply_status(PetrifiedStatus, {"duration": duration, "source": unit})

    # Visual feedback
    GameManager.spawn_floating_text(enemy.global_position, "石化!", Color.GRAY)
    _play_petrify_effect(enemy.global_position)
```

### 4. 文件清单

**需要修改：**
- `src/Scripts/Effects/PetrifiedStatus.gd` - 添加动画冻结，保存petrify_source
- `src/Scripts/Enemy.gd` - 修改死亡效果，传递伤害参数
- `src/Scripts/Units/Behaviors/Medusa.gd` - 确保正确传递source引用
- `src/Scripts/Effects/PetrifiedShatterEffect.gd` - 完全重写

**需要确认存在的文件：**
- `src/Scenes/Effects/PetrifiedShatterEffect.tscn` - 场景文件

### 5. 验收标准

- [ ] 石化时敌人动画冻结（停止idle动画）
- [ ] 石化解除后动画恢复
- [ ] 石化敌人死亡时产生3-6个碎块
- [ ] 碎块显示敌人原图像的一部分（UV分割）
- [ ] 碎块沿攻击方向飞散（±30度扩散）
- [ ] 碎块碰撞敌人造成伤害
- [ ] 伤害计算：LV1/LV2 = 10% MaxHP，LV3 = 20% MaxHP
- [ ] 每个敌人只能被石块击中一次
- [ ] 碎块3秒后淡出消失

### 6. 测试用例

在 `src/Scripts/Tests/TestSuite.gd` 中添加：

```gdscript
"test_medusa_petrify_juice":
    return {
        "id": "test_medusa_petrify_juice",
        "core_type": "viper_totem",
        "initial_gold": 1000,
        "start_wave_index": 1,
        "duration": 30.0,
        "units": [
            {"id": "medusa", "x": 0, "y": 1}
        ],
        "description": "测试美杜莎石化Juice效果：动画冻结、碎裂图像、石块伤害"
    }
```

### 7. 注意事项

1. 确保 `AssetLoader.get_enemy_icon()` 返回有效的 Texture2D
2. 如果敌人没有TextureRect或Sprite，使用enemy_data.color作为备用
3. 碰撞检测使用RigidBody2D的body_entered信号
4. 碎片应该只检测敌人层（layer 2），不影响其他物体
5. 石化期间敌人应保持正常碰撞（与原版一致）

---

## 任务标识

Task being executed: P2-04c
