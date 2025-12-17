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

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# If GridManager is in targeting mode, the Control (this) consumes the event
			# preventing _unhandled_input from firing. We must manually trigger it.
			if GameManager.grid_manager and GameManager.grid_manager.is_targeting_mode:
				GameManager.grid_manager.handle_tile_click_for_skill(tile_ref)
