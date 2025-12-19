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
		# Allow inventory drop even during wave
		if GameManager.is_wave_active:
			return true
		# Also allow outside wave
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
	var item = data.item
	var item_id = item.get("item_id", "")

	# Logic for Trap Items
	# Traps usually have "trap" in ID or specific IDs
	if "trap" in item_id or item_id in ["poison_trap", "fang_trap"]:
		# Check target tile
		if tile_ref.unit == null and tile_ref.occupied_by == Vector2i.ZERO:
			# Verify obstacles too just in case GridManager doesn't
			# Although spawn_trap_custom assumes checks are done, we do them here.
			if GameManager.grid_manager.obstacles.has(Vector2i(tile_ref.x, tile_ref.y)):
				return

			var trap_type = _get_trap_type(item_id)
			# Use grid_pos if available, otherwise construct from x,y
			var pos = Vector2i(tile_ref.x, tile_ref.y)
			if "grid_pos" in tile_ref:
				pos = tile_ref.grid_pos

			GameManager.grid_manager.spawn_trap_custom(pos, trap_type)
			GameManager.inventory_manager.remove_item(data.slot_index)

	# Logic for Meat
	elif item_id == "meat":
		if tile_ref.unit != null:
			# Devour (feed) the unit
			if tile_ref.unit.has_method("devour"):
				tile_ref.unit.devour(null)
				GameManager.inventory_manager.remove_item(data.slot_index)

func _get_trap_type(item_id: String) -> String:
	if item_id == "poison_trap": return "poison"
	if item_id == "fang_trap": return "fang"
	# Fallback: remove "_trap" suffix if present
	return item_id.replace("_trap", "")
