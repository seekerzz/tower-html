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
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.is_wave_active: return false

	if data.source == "grid" or data.source == "bench":
		return true
	return false

func _drop_data(at_position, data):
	if !tile_ref: return
	var gm = get_node_or_null("/root/GameManager")
	if !gm or !gm.grid_manager: return

	if data.source == "bench":
		# Call GridManager to place from bench
		gm.grid_manager.handle_bench_drop_at(tile_ref, data)
	elif data.source == "grid":
		# Call GridManager to move unit
		gm.grid_manager.handle_grid_move_at(tile_ref, data)
