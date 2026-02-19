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

func _get_nearest_unit() -> Unit:
    if !GameManager.grid_manager: return null
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

func _devour_unit(target: Unit):
    base_damage += target.damage * 0.4
    damage = base_damage
    max_hp += target.max_hp * 0.4
    current_hp = max_hp
    consumed_data = {"unit_id": target.type_key}
    SoulManager.add_souls(10, "wolf_devour")

    GameManager.grid_manager.remove_unit_from_grid(target)
    target.queue_free()

    # Update visuals or show effect
    GameManager.spawn_floating_text(global_position, "Devoured!", Color.RED)

func can_upgrade() -> bool:
    return level < 2  # 最高2级

var base_damage = 0.0

func reset_stats():
    super.reset_stats()
    base_damage = damage
    # Re-apply devoured stats if stored?
    # Unit reset_stats resets damage to base.
    # We should probably store devoured bonus separately and re-apply.
    # But for now, assume devour happens once.
