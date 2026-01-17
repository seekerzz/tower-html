extends "res://src/Scripts/Units/UnitBehavior.gd"

func attach_to_host(target_unit: Node2D):
	if !is_instance_valid(target_unit): return

	# Remove from current parent if any
	if unit.get_parent():
		unit.get_parent().remove_child(unit)

	target_unit.add_child(unit)
	unit.host = target_unit
	target_unit.attachment = unit

	# Visual adjustment
	# 0.35 * TILE_SIZE offset
	var offset_val = Constants.TILE_SIZE * 0.35
	unit.position = Vector2(offset_val, -offset_val)
	unit.scale = Vector2(0.5, 0.5)

	# Z-Index: host is usually 0 (or inherits), we want to be slightly higher.
	unit.z_index = 1

	# Connect signal to behavior's method
	if !target_unit.attack_performed.is_connected(_on_host_attack_performed):
		target_unit.attack_performed.connect(_on_host_attack_performed)

	# Disable collision to prevent clicking/blocking
	var area = unit.get_node_or_null("Area2D")
	if area:
		area.monitoring = false
		area.monitorable = false
		# Also disable input pickable just in case
		area.input_pickable = false

func _on_host_attack_performed(target):
	if !unit.host or !is_instance_valid(unit.host): return

	# Cooldown check
	if unit.cooldown > 0: return

	# Brief delay
	await unit.get_tree().create_timer(randf_range(0.1, 0.2)).timeout

	if !is_instance_valid(unit) or !is_instance_valid(unit.host): return

	# Double check cooldown after delay just in case
	if unit.cooldown > 0: return

	# Calculate damage
	var dmg = unit.host.max_hp * 0.1

	if GameManager.combat_manager:
		var target_node = target

		# If target is null or invalid, try find one?
		if target_node == null or !is_instance_valid(target_node):
			target_node = GameManager.combat_manager.find_nearest_enemy(unit.global_position, unit.range_val)

		if target_node:
			unit.cooldown = unit.atk_speed * GameManager.get_stat_modifier("attack_interval")
			GameManager.combat_manager.spawn_projectile(unit, unit.global_position, target_node, {"damage": dmg})
