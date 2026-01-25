extends "res://src/Scripts/Units/Behaviors/FlyingMeleeBehavior.gd"

func _find_target() -> Node2D:
	# Priority: Furthest unit within range
	if !unit or !unit.is_inside_tree(): return null

	var enemies = unit.get_tree().get_nodes_in_group("enemies")
	var furthest: Node2D = null
	var max_dist = -1.0

	for enemy in enemies:
		if !is_instance_valid(enemy): continue
		var dist = unit.global_position.distance_to(enemy.global_position)
		if dist <= unit.range_val:
			if dist > max_dist:
				max_dist = dist
				furthest = enemy

	return furthest

func _apply_damage_logic(target: Node2D):
	if !is_instance_valid(target): return

	var multiplier = 1.0
	# Check for full health (allow small float error)
	if "hp" in target and "max_hp" in target:
		if target.hp >= (target.max_hp - 0.1):
			multiplier = 2.0
			if GameManager.has_method("spawn_floating_text"):
				GameManager.spawn_floating_text(target.global_position, "CRUSH!", Color.RED)

	var dmg = unit.calculate_damage_against(target) * multiplier
	target.take_damage(dmg, unit)

func on_combat_tick(delta: float) -> bool:
	var result = super.on_combat_tick(delta)

	# Handle rotation during WINDUP to face target
	if _state == State.WINDUP and is_instance_valid(_current_target):
		_face_target(_current_target.global_position)
	elif _state == State.ATTACK_OUT and is_instance_valid(_current_target):
		# Keep facing target during attack dash
		_face_target(_current_target.global_position)

	return result

func _face_target(target_pos: Vector2):
	if !unit.visual_holder: return

	var dir = target_pos - unit.global_position
	# Default facing is LEFT (-1, 0) as per requirements
	var angle = Vector2.LEFT.angle_to(dir)
	unit.visual_holder.rotation = angle

func _enter_return(total_duration: float):
	super._enter_return(total_duration)

	# Face towards home (original position)
	if unit.visual_holder:
		# Current position is unit.visual_holder.position (local)
		# Destination is _original_local_pos
		var dir = _original_local_pos - unit.visual_holder.position
		if dir.length_squared() > 1:
			var angle = Vector2.LEFT.angle_to(dir)
			unit.visual_holder.rotation = angle

func _enter_landing(total_duration: float):
	super._enter_landing(total_duration)

	# Rotate back to 0 (default orientation) during landing
	if unit.visual_holder:
		var tween = unit.create_tween()
		tween.tween_property(unit.visual_holder, "rotation", 0.0, total_duration * RATIO_LANDING)
