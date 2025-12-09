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

	# If drag data has 'is_food', allow drop even if tile is occupied
	if data.get("is_food", false):
		return true

	# For other units, if tile is occupied, return false
	if tile_ref and tile_ref.unit != null:
		return false

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
