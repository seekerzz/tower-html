# Jules 任务: P2-03 狼的吞噬继承系统完善

## 任务ID
P2-03

## 任务描述
完善狼单位的吞噬机制，实现选择目标吞噬、继承攻击机制、以及合并升级时保留双狼攻击机制的功能。

## 当前代码位置

- 狼单位: `src/Scripts/Units/Wolf/UnitWolf.gd`
- 单位基类: `src/Scripts/Unit.gd`
- 单位拖拽: `src/Scripts/UI/UnitDragHandler.gd`
- 魂魄系统: `src/Autoload/SoulManager.gd`

## 当前实现分析

`UnitWolf.gd` 已实现基础吞噬：
- 放置时自动吞噬最近的单位
- 继承40%攻击力和血量
- 狼最高只能升到2级

**缺失功能**:
1. 吞噬目标不能手动选择，是自动的
2. 没有继承被吞噬单位的攻击机制（如弹射、分裂等）
3. 合并升级时没有保留两只狼各自的攻击机制
4. 需要UI提示玩家选择吞噬目标

## 实现要求

### 1. 创建 WolfDevourUI

创建 `src/Scenes/UI/WolfDevourUI.tscn` 和对应的脚本：

```gdscript
class_name WolfDevourUI
extends Control

var wolf_unit: Unit
var selectable_units: Array[Unit] = []
var selected_unit: Unit = null

@onready var panel = $Panel
@onready var unit_list = $Panel/UnitList

func show_for_wolf(wolf: Unit):
    wolf_unit = wolf
    _populate_unit_list()
    visible = true
    get_tree().paused = true  # 暂停游戏让玩家选择

func _populate_unit_list():
    # 清除旧项
    for child in unit_list.get_children():
        child.queue_free()

    selectable_units.clear()

    # 获取周围可吞噬的单位
    if not GameManager.grid_manager:
        return

    var wolf_pos = wolf_unit.global_position
    var my_tile = GameManager.grid_manager.get_tile_at_position(wolf_pos)

    for key in GameManager.grid_manager.tiles:
        var tile = GameManager.grid_manager.tiles[key]
        var unit = tile.unit
        if unit and unit != wolf_unit and is_instance_valid(unit):
            # 计算距离
            var dist = wolf_pos.distance_to(unit.global_position)
            if dist <= 120:  # 周围2格范围内
                selectable_units.append(unit)
                _create_unit_button(unit)

    if selectable_units.is_empty():
        # 没有可吞噬单位，显示提示
        _show_no_target_message()

func _create_unit_button(unit: Unit):
    var btn = Button.new()
    btn.text = "%s (Lv.%d)" % [unit.unit_name, unit.level]

    # 显示单位特性图标
    var buff_text = ""
    for buff in unit.active_buffs:
        buff_text += buff.icon if buff.has("icon") else ""
    if buff_text:
        btn.text += " " + buff_text

    btn.pressed.connect(_on_unit_selected.bind(unit))
    unit_list.add_child(btn)

func _show_no_target_message():
    var label = Label.new()
    label.text = "周围没有可吞噬的单位\n点击确认继续"
    unit_list.add_child(label)

    var confirm_btn = Button.new()
    confirm_btn.text = "确认"
    confirm_btn.pressed.connect(_on_cancel)
    unit_list.add_child(confirm_btn)

func _on_unit_selected(unit: Unit):
    selected_unit = unit
    _close_and_devour()

func _on_cancel():
    selected_unit = null
    _close_ui()

func _close_and_devour():
    _close_ui()
    if wolf_unit and is_instance_valid(wolf_unit):
        wolf_unit.devour_target(selected_unit)

func _close_ui():
    visible = false
    get_tree().paused = false
```

### 2. 完善 UnitWolf.gd

重写吞噬逻辑：

```gdscript
class_name UnitWolf
extends Unit

var consumed_data: Dictionary = {}
var consumed_mechanics: Array[String] = []
var base_damage: float = 0.0
var has_selected_devour: bool = false

func _ready():
    super._ready()
    base_damage = damage

    # 如果是第一次放置（非加载存档），显示选择UI
    if not has_selected_devour:
        _show_devour_ui()

func _show_devour_ui():
    var ui = load("res://src/Scenes/UI/WolfDevourUI.tscn").instantiate()
    get_tree().current_scene.add_child(ui)
    ui.show_for_wolf(self)
    ui.tree_exited.connect(_on_devour_ui_closed)

func _on_devour_ui_closed():
    has_selected_devour = true
    # 如果没有选择目标，自动选择最近的
    if consumed_data.is_empty():
        _auto_devour()

func devour_target(target: Unit):
    if not target or not is_instance_valid(target):
        return

    _perform_devour(target)

func _auto_devour():
    var nearest = _get_nearest_unit()
    if nearest:
        _perform_devour(nearest)

func _perform_devour(target: Unit):
    # 记录被吞噬单位的数据
    consumed_data = {
        "unit_id": target.type_key,
        "unit_name": target.unit_name,
        "level": target.level,
        "damage_bonus": target.damage * 0.5,
        "hp_bonus": target.max_hp * 0.5
    }

    # 继承攻击机制
    _inherit_mechanics(target)

    # 应用属性加成
    base_damage += consumed_data.damage_bonus
    damage = base_damage
    max_hp += consumed_data.hp_bonus
    current_hp = max_hp

    # 获得魂魄
    SoulManager.add_souls(10, "wolf_devour")

    # 移除被吞噬单位
    GameManager.grid_manager.remove_unit_from_grid(target)
    target.queue_free()

    # 视觉反馈
    GameManager.spawn_floating_text(global_position, "吞噬 %s!" % consumed_data.unit_name, Color.RED)
    _play_devour_effect()

func _inherit_mechanics(target: Unit):
    """继承被吞噬单位的特殊攻击机制"""
    consumed_mechanics.clear()

    # 检查目标单位的buff来继承机制
    for buff in target.active_buffs:
        match buff.type:
            "bounce":
                consumed_mechanics.append("bounce")
                if not has_buff("bounce"):
                    add_buff("bounce", 1)
            "split":
                consumed_mechanics.append("split")
                if not has_buff("split"):
                    add_buff("split", 1)
            "multishot":
                consumed_mechanics.append("multishot")
                if not has_buff("multishot"):
                    add_buff("multishot", 1)
            "poison":
                consumed_mechanics.append("poison")
                if not has_buff("poison"):
                    add_buff("poison", 1)
            "fire":
                consumed_mechanics.append("fire")
                if not has_buff("fire"):
                    add_buff("fire", 1)

    # 记录继承的机制
    if not consumed_mechanics.is_empty():
        consumed_data["inherited_mechanics"] = consumed_mechanics.duplicate()

func _get_nearest_unit() -> Unit:
    if not GameManager.grid_manager:
        return null

    var min_dist = 9999.0
    var nearest = null
    var my_pos = global_position

    for key in GameManager.grid_manager.tiles:
        var tile = GameManager.grid_manager.tiles[key]
        var unit = tile.unit
        if unit and unit != self and is_instance_valid(unit):
            var dist = my_pos.distance_to(unit.global_position)
            if dist < min_dist:
                min_dist = dist
                nearest = unit

    return nearest

func _play_devour_effect():
    # 播放吞噬特效
    var effect = preload("res://src/Scenes/Effects/DevourEffect.tscn").instantiate()
    effect.global_position = global_position
    get_tree().current_scene.add_child(effect)

func can_upgrade() -> bool:
    return level < 2  # 狼最高2级

func on_merged_with(other_unit: Unit):
    """合并升级时调用，保留双狼的吞噬机制"""
    if other_unit is UnitWolf:
        var other_wolf = other_unit as UnitWolf

        # 合并属性加成
        if other_wolf.consumed_data.has("damage_bonus"):
            base_damage += other_wolf.consumed_data.damage_bonus * 0.5
            damage = base_damage

        if other_wolf.consumed_data.has("hp_bonus"):
            max_hp += other_wolf.consumed_data.hp_bonus * 0.5
            current_hp = max_hp

        # 合并继承的机制（去重）
        for mechanic in other_wolf.consumed_mechanics:
            if mechanic not in consumed_mechanics:
                consumed_mechanics.append(mechanic)
                # 确保buff存在
                if not has_buff(mechanic):
                    add_buff(mechanic, 1)

        # 记录合并信息
        consumed_data["merged_with"] = other_wolf.consumed_data

        GameManager.spawn_floating_text(global_position, "双狼融合!", Color.GOLD)

func get_description() -> String:
    var desc = super.get_description()
    if not consumed_data.is_empty():
        desc += "\n[吞噬] %s" % consumed_data.get("unit_name", "未知")
        if consumed_mechanics.size() > 0:
            desc += " - 继承: " + ", ".join(consumed_mechanics)
    return desc
```

### 3. 创建吞噬特效场景

创建 `src/Scenes/Effects/DevourEffect.tscn`：

```gdscript
class_name DevourEffect
extends Node2D

@onready var particles: CPUParticles2D = $CPUParticles2D
@onready var tween = create_tween()

func _ready():
    # 红色漩涡效果
    particles.amount = 30
    particles.lifetime = 0.8
    particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
    particles.emission_sphere_radius = 10
    particles.orbit_velocity_min = 2.0
    particles.orbit_velocity_max = 3.0
    particles.scale_amount_min = 3
    particles.scale_amount_max = 6
    particles.color = Color.DARK_RED

    # 放大后消失
    tween.tween_property(self, "scale", Vector2(2, 2), 0.5)
    tween.tween_callback(queue_free)
```

### 4. 修改 UnitDragHandler.gd

在合并时调用狼的特殊合并逻辑：

```gdscript
func _on_units_merged(consumed_unit: Unit, target_unit: Unit):
    # 魂魄系统
    SoulManager.add_souls_from_unit_merge({
        "level": consumed_unit.level,
        "type": consumed_unit.unit_id
    })

    # 如果是狼合并，调用特殊逻辑
    if target_unit is UnitWolf and consumed_unit is UnitWolf:
        target_unit.on_merged_with(consumed_unit)
```

## 自动化测试要求

在 `src/Scripts/Tests/TestSuite.gd` 中添加测试用例：

```gdscript
"test_wolf_devour_system":
    return {
        "id": "test_wolf_devour_system",
        "core_type": "wolf_totem",
        "initial_gold": 1000,
        "start_wave_index": 1,
        "duration": 15.0,
        "units": [
            {"id": "wolf", "x": 1, "y": 0},
            {"id": "tiger", "x": 0, "y": 1}  # 狼可以吞噬猛虎
        ],
        "description": "测试狼的吞噬继承系统"
    }
```

运行测试：
```bash
godot --path . --headless -- --run-test=test_wolf_devour_system
```

验证点：
- 狼放置时弹出选择UI
- 吞噬后继承目标50%攻击力和血量
- 继承被吞噬单位的特殊攻击机制（如弹射、分裂）
- 双狼合并时保留双方的吞噬加成

## 进度同步要求

更新 `docs/progress.md`：

```markdown
| P2-03 | in_progress | 完善狼的吞噬继承系统 | 2026-02-20T12:00:00 |
```

完成后更新为：
```markdown
| P2-03 | completed | 吞噬继承系统完整实现 PR#XXX | 2026-02-20TXX:00:00 |
```

## 代码提交要求

1. 在独立分支上工作：`feature/P2-03-wolf-devour`
2. 提交信息格式：`[P2-03] 完善狼的吞噬继承系统`
3. 完成后创建 Pull Request 到 main 分支

## 注意事项

- UI需要支持鼠标/触摸选择
- 考虑游戏暂停时选择吞噬目标
- 确保继承的机制与现有buff系统兼容
- 吞噬特效不应影响游戏性能

---

## 任务标识

Task being executed: P2-03
