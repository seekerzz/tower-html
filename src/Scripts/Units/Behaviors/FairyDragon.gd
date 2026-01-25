extends UnitBehavior

func on_projectile_hit(target: Node2D, damage: float, projectile: Node2D):
	if target.is_in_group("enemies"):
		# Get knockback resistance
		var resistance = 1.0
		if "knockback_resistance" in target:
			resistance = target.knockback_resistance

		# Get base chance from mechanics
		var teleport_base_chance = 0.0
		# We need to access unit data for current level mechanics
		if unit.unit_data.has("levels") and unit.unit_data["levels"].has(str(unit.level)):
			var level_data = unit.unit_data["levels"][str(unit.level)]
			if level_data.has("mechanics"):
				teleport_base_chance = level_data["mechanics"].get("teleport_base_chance", 0.0)

		# Calculate final chance
		var final_chance = teleport_base_chance / max(1.0, resistance)

		# Roll
		if randf() < final_chance:
			# Execute teleport
			var direction = (target.global_position - unit.global_position).normalized()
			var distance = randf_range(2.0, 3.0) * Constants.TILE_SIZE

			var target_pos = unit.global_position + (direction * distance)

			# Boundary Handling
			var half_width = (Constants.MAP_WIDTH * Constants.TILE_SIZE) / 2.0
			var half_height = (Constants.MAP_HEIGHT * Constants.TILE_SIZE) / 2.0

			# Add a small buffer to keep them strictly inside
			var buffer = 10.0
			target_pos.x = clamp(target_pos.x, -half_width + buffer, half_width - buffer)
			target_pos.y = clamp(target_pos.y, -half_height + buffer, half_height - buffer)

			target.global_position = target_pos

			GameManager.spawn_floating_text(target.global_position, "Warp!", Color.VIOLET)
