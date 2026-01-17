extends DefaultBehavior

func can_attach_to(target: Node2D) -> bool:
	if target.type_key != "oxpecker" and target.attachment == null:
		return true
	return false

func perform_attach(target_unit: Node2D):
	if !is_instance_valid(target_unit): return

	if unit.get_parent():
		unit.get_parent().remove_child(unit)

	target_unit.add_child(unit)
	unit.host = target_unit
	target_unit.attachment = unit

	var offset_val = 60.0 * 0.35 # Constants.TILE_SIZE
	unit.position = Vector2(offset_val, -offset_val)
	unit.scale = Vector2(0.5, 0.5)
	unit.z_index = 1

	if !target_unit.attack_performed.is_connected(_on_host_attack_performed):
		target_unit.attack_performed.connect(_on_host_attack_performed)

	var area = unit.get_node_or_null("Area2D")
	if area:
		area.monitoring = false
		area.monitorable = false
		area.input_pickable = false

func _on_host_attack_performed(target):
	if !unit or !is_instance_valid(unit): return
	# Use call_deferred or timer for delay
	var timer = unit.get_tree().create_timer(randf_range(0.1, 0.2))
	timer.timeout.connect(func(): _do_attack(target))

func _do_attack(target):
	if !unit or !is_instance_valid(unit): return
	if !unit.host or !is_instance_valid(unit.host): return
	if unit.cooldown > 0: return

	var dmg = unit.host.max_hp * 0.1
	var target_node = target

	if target_node == null or !is_instance_valid(target_node):
		if GameManager.combat_manager:
			target_node = GameManager.combat_manager.find_nearest_enemy(unit.global_position, unit.range_val)

	if target_node:
		unit.cooldown = unit.atk_speed * GameManager.get_stat_modifier("attack_interval")
		if GameManager.combat_manager:
			GameManager.combat_manager.spawn_projectile(unit, unit.global_position, target_node, {"damage": dmg})

func on_combat_tick(delta: float) -> bool:
	if unit.cooldown > 0:
		unit.cooldown -= delta
	return true
