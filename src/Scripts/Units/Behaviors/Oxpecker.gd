extends DefaultBehavior

func on_setup():
	# Oxpecker setup: try to attach to unit on the grid
	var grid_manager = GameManager.grid_manager
	if !grid_manager: return

	var gx = unit.grid_pos.x
	var gy = unit.grid_pos.y
	var key = grid_manager.get_tile_key(gx, gy)
	if grid_manager.tiles.has(key):
		var tile = grid_manager.tiles[key]
		var target = tile.unit

		# Check occupied_by if target is null (for big units)
		if target == null and tile.occupied_by != Vector2i.ZERO:
			var origin_key = grid_manager.get_tile_key(tile.occupied_by.x, tile.occupied_by.y)
			if grid_manager.tiles.has(origin_key):
				target = grid_manager.tiles[origin_key].unit

		if target and target != unit and target.type_key != "oxpecker" and target.attachment == null:
			unit.attach_to_host(target)
			if !target.attack_performed.is_connected(_on_host_attack):
				target.attack_performed.connect(_on_host_attack)

func on_combat_tick(delta: float) -> bool:
	if unit.host:
		return true
	return false

func _on_host_attack(target):
	if !unit.host or !is_instance_valid(unit.host): return
	if unit.cooldown > 0: return

	# Brief delay
	await unit.get_tree().create_timer(randf_range(0.1, 0.2)).timeout

	if !is_instance_valid(unit) or !is_instance_valid(unit.host): return
	if unit.cooldown > 0: return

	var dmg = unit.host.max_hp * 0.1

	if GameManager.combat_manager:
		var target_node = target
		if target_node == null or !is_instance_valid(target_node):
			target_node = GameManager.combat_manager.find_nearest_enemy(unit.global_position, unit.range_val)

		if target_node:
			unit.cooldown = unit.atk_speed * GameManager.get_stat_modifier("attack_interval")
			GameManager.combat_manager.spawn_projectile(unit, unit.global_position, target_node, {"damage": dmg})
