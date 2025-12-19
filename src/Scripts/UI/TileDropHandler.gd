extends Control

var tile_ref # Reference to Tile (Node2D)

func setup(tile):
	tile_ref = tile
	# Size is 60x60
	size = Vector2(60, 60)
	position = Vector2(-30, -30) # Centered
	mouse_filter = MOUSE_FILTER_PASS

func _can_drop_data(at_position, data):
	if !data or !data.has("source"): return false

	if data.source == "inventory":
		if data.item:
			var item_id = data.item.get("item_id", "")
			if "trap" in item_id or item_id in ["poison_trap", "fang_trap"]:
				var grid_pos = Vector2i(tile_ref.x, tile_ref.y)
				GameManager.grid_manager.update_placement_preview(grid_pos, item_id)
				return GameManager.grid_manager.can_place_item_at(grid_pos, item_id)

		# Allow dropping inventory items during wave
		return true

	if GameManager.is_wave_active: return false

	if data.source == "grid" or data.source == "bench":
		return true
	return false

func _drop_data(at_position, data):
	if !tile_ref: return

	if data.source == "inventory":
		_handle_inventory_drop(data)
	elif data.source == "bench":
		# Call GridManager to place from bench
		GameManager.grid_manager.handle_bench_drop_at(tile_ref, data)
	elif data.source == "grid":
		# Call GridManager to move unit
		GameManager.grid_manager.handle_grid_move_at(tile_ref, data)

func _handle_inventory_drop(data):
	var item_data = data.item
	var item_id = item_data.get("item_id", "")

	# Trap Logic
	if "trap" in item_id or item_id in ["poison_trap", "fang_trap"]:
		# Check empty tile
		if tile_ref.unit == null and tile_ref.occupied_by == Vector2i.ZERO:
			# Determine trap type
			var trap_type = "poison"
			if item_id == "fang_trap": trap_type = "fang"
			# Or if generic trap id handling needed, for now hardcode as per context or map item_id to trap_type
			# Assuming item_id contains type info or we deduce it.
			# Using "poison" and "fang" as keys for spawn_trap_custom based on unit logic in Unit.gd

			if "poison" in item_id: trap_type = "poison"
			elif "fang" in item_id: trap_type = "fang"

			GameManager.grid_manager.spawn_trap_custom(Vector2i(tile_ref.x, tile_ref.y), trap_type)
			GameManager.inventory_manager.remove_item(data.slot_index)

	# Meat Logic
	elif item_id == "meat":
		if tile_ref.unit != null:
			# Devour
			# Unit.devour expects a food_unit, but logic says it ignores it, so passing null.
			# However, strict typing might complain if Unit.gd had type hint. It doesn't.
			tile_ref.unit.devour(null)
			GameManager.inventory_manager.remove_item(data.slot_index)
