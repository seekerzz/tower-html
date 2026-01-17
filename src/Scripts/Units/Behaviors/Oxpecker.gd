extends "res://src/Scripts/Units/DefaultBehavior.gd"

var host: Node2D = null

func on_placement_attempt(grid_pos: Vector2i):
	if !GameManager.grid_manager: return

	var key = GameManager.grid_manager.get_tile_key(grid_pos.x, grid_pos.y)
	if !GameManager.grid_manager.tiles.has(key): return

	var tile = GameManager.grid_manager.tiles[key]
	var target = tile.unit

	# Handle multi-tile units
	if target == null and tile.occupied_by != Vector2i.ZERO:
		var origin_key = GameManager.grid_manager.get_tile_key(tile.occupied_by.x, tile.occupied_by.y)
		if GameManager.grid_manager.tiles.has(origin_key):
			target = GameManager.grid_manager.tiles[origin_key].unit

	if target and target != unit and target.type_key != "oxpecker" and target.attachment == null:
		unit.attach_to_host(target)
		host = target
		if !host.attack_performed.is_connected(_on_host_attack):
			host.attack_performed.connect(_on_host_attack)

func on_combat_tick(delta: float) -> bool:
	# Disable standard combat since we only attack with host
	return true

func _on_host_attack(target_node):
	if !is_instance_valid(unit): return
	if unit.cooldown > 0: return

	await unit.get_tree().create_timer(randf_range(0.1, 0.2)).timeout
	if !is_instance_valid(unit) or !is_instance_valid(host): return

	var dmg = host.max_hp * 0.1

	var final_target = target_node
	if !is_instance_valid(final_target) and GameManager.combat_manager:
		final_target = GameManager.combat_manager.find_nearest_enemy(unit.global_position, unit.range_val)

	if final_target and GameManager.combat_manager:
		unit.cooldown = unit.atk_speed * GameManager.get_stat_modifier("attack_interval")
		GameManager.combat_manager.spawn_projectile(unit, unit.global_position, final_target, {"damage": dmg})

func on_cleanup():
	if host and is_instance_valid(host):
		if host.attack_performed.is_connected(_on_host_attack):
			host.attack_performed.disconnect(_on_host_attack)
