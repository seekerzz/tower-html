extends FlyingMeleeBehavior

# Eagle Specific Behavior
# Targeting: Furthest unit in range.
# Damage: 200% to full HP enemies.

func _get_target() -> Node2D:
	var enemies = unit.get_tree().get_nodes_in_group("enemies")
	var furthest: Node2D = null
	var max_dist: float = -1.0
	# Use squared distance for optimization
	var range_sq = unit.range_val * unit.range_val

	for enemy in enemies:
		if !is_instance_valid(enemy): continue

		var dist_sq = unit.global_position.distance_squared_to(enemy.global_position)
		if dist_sq <= range_sq:
			if dist_sq > max_dist:
				max_dist = dist_sq
				furthest = enemy

	return furthest

func _calculate_damage(target: Node2D) -> float:
	var base_dmg = unit.calculate_damage_against(target)

	# Bonus against Full HP targets
	if target.hp >= target.max_hp:
		# Show a visual indicator or text?
		# Maybe just execute usage.
		# GameManager.spawn_floating_text(unit.global_position, "Predator!", Color.RED)
		return base_dmg * 2.0

	return base_dmg
