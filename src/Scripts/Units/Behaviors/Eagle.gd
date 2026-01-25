extends FlyingMeleeBehavior

func _get_target() -> Node2D:
	var enemies = unit.get_tree().get_nodes_in_group("enemies")
	var furthest_enemy = null
	var max_dist = -1.0

	for enemy in enemies:
		if !is_instance_valid(enemy): continue

		var dist = unit.global_position.distance_to(enemy.global_position)
		if dist <= unit.range_val:
			if dist > max_dist:
				max_dist = dist
				furthest_enemy = enemy

	return furthest_enemy

func _calculate_damage(target: Node2D) -> float:
	var dmg = unit.calculate_damage_against(target)

	# Eagle Trait: 200% Damage to Full HP enemies
	if target.hp >= target.max_hp:
		dmg *= 2.0
		# Visual feedback for bonus damage
		GameManager.spawn_floating_text(target.global_position, "CRUSH!", Color.RED)

	return dmg
