extends UnitBehavior

func on_damage_taken(amount: float, source: Node2D) -> float:
	if is_instance_valid(source) and source.is_in_group("enemies"):
		var direction = (source.global_position - unit.global_position).normalized()
		var distance = randf_range(2.0, 3.0) * Constants.TILE_SIZE
		var new_pos = unit.global_position + (direction * distance)

		# Move the enemy
		source.global_position = new_pos

		# Visual effect
		GameManager.spawn_floating_text(unit.global_position, "Begone!", Color.MAGENTA)

	return amount
