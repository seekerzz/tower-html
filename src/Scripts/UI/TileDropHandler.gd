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
		if GameManager.is_wave_active:
			return true
		# Also allow out of combat? Usually yes.
		return true

	if GameManager.is_wave_active: return false

	if data.source == "grid" or data.source == "bench":
		return true
	return false

func _drop_data(at_position, data):
	if !tile_ref: return

	if data.source == "bench":
		# Call GridManager to place from bench
		GameManager.grid_manager.handle_bench_drop_at(tile_ref, data)
	elif data.source == "grid":
		# Call GridManager to move unit
		GameManager.grid_manager.handle_grid_move_at(tile_ref, data)
	elif data.source == "inventory":
		_handle_inventory_drop(data)

func _handle_inventory_drop(data):
	var item_data = data.item
	var slot_index = data.slot_index
	var item_id = item_data.get("item_id", "")

	if "trap" in item_id or item_id in ["poison_trap", "fang_trap"]:
		# Trap Logic
		if tile_ref.unit == null and tile_ref.occupied_by == Vector2i.ZERO:
			# Map item_id to trap_type key if needed.
			# "poison_trap" -> "poison" (for spawn_trap_custom(pos, "poison"))
			var trap_type = ""
			if item_id == "poison_trap": trap_type = "poison"
			elif item_id == "fang_trap": trap_type = "fang"
			else: trap_type = item_id.replace("_trap", "")

			GameManager.grid_manager.spawn_trap_custom(Vector2i(tile_ref.x, tile_ref.y), trap_type)
			GameManager.inventory_manager.remove_item(slot_index)

	elif item_id == "meat":
		# Meat Logic
		if tile_ref.unit != null:
			tile_ref.unit.devour(null)
			GameManager.inventory_manager.remove_item(slot_index)
