extends Control

func _can_drop_data(at_position, data):
	if typeof(data) == TYPE_DICTIONARY and data.get("source") == "inventory":
		var item = data.get("item", {})
		if item.get("item_id") == "holy_sword":
			return true
	return false

func _drop_data(at_position, data):
	if typeof(data) == TYPE_DICTIONARY and data.get("source") == "inventory":
		var item = data.get("item", {})

		# Find target unit under mouse
		# Convert UI position to Global World Position
		# MainGUI is a CanvasLayer or overlay. We need viewport coordinates.
		# `at_position` is local to this Control. Since this control fills screen, it matches viewport pos mostly.
		var viewport_pos = get_global_mouse_position() # Control method
		# Wait, for Node2D (Units), we need world coordinates.
		# If the game uses a Camera2D, we need to transform.
		var canvas_transform = get_viewport().canvas_transform
		var world_pos = canvas_transform.affine_inverse() * viewport_pos

		# Raycast or distance check for units
		# Since we don't have direct access to physics world easily without setup,
		# we can iterate units in GridManager or 'enemies'/'units' group.
		# Units are typically not in a group unless we put them there.
		# GridManager stores tiles.

		if GameManager.grid_manager:
			var units = []
			for key in GameManager.grid_manager.tiles:
				var tile = GameManager.grid_manager.tiles[key]
				if is_instance_valid(tile.unit):
					units.append(tile.unit)

			var target_unit = null
			for unit in units:
				# Simple AABB or Distance check
				# Units have visual size approx TILE_SIZE (64)
				var dist = unit.global_position.distance_to(world_pos)
				if dist < 40: # Approx radius
					target_unit = unit
					break

			if target_unit:
				_apply_item_to_unit(target_unit, item)
			else:
				print("No unit found at ", world_pos)
		else:
			print("GridManager not found")

func _apply_item_to_unit(unit, item_data):
	var item_id = item_data.get("item_id")
	if item_id == "holy_sword":
		if unit.has_method("apply_holy_sword_buff"):
			unit.apply_holy_sword_buff()
			GameManager.use_item(item_data) # Consume item
