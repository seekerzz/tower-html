extends UnitBehavior

# Fairy Dragon behavior: Teleports attacker away when damaged
func on_damage_taken(amount: float, source: Node2D) -> float:
	# Check if source is valid and is an enemy
	if source and source.is_in_group("enemies"):
		# Calculate direction from unit to source
		var direction = (source.global_position - unit.global_position).normalized()

		# Random distance: 2 to 3 tiles
		var distance = randf_range(2.0, 3.0) * Constants.TILE_SIZE

		# Calculate new position
		var new_pos = unit.global_position + (direction * distance)

		# Teleport the attacker
		source.global_position = new_pos

	# Return original damage (Fairy Dragon still takes damage)
	return amount
