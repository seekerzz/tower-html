extends Node

func _ready():
	print("TestGridConfig starting...")
	# Wait for GridManager to initialize
	await get_tree().process_frame
	await get_tree().process_frame

	var gm_scene = load("res://src/Scenes/Game/GridManager.tscn")
	var grid_manager = gm_scene.instantiate()
	add_child(grid_manager)

	# Ensure _ready is called and grid is created
	# GridManager._ready calls create_initial_grid()

	# 1. Assert spawn_tiles count
	var spawn_count = grid_manager.spawn_tiles.size()
	if spawn_count == 4:
		print("PASS: Spawn tiles count is 4.")
	else:
		push_error("FAIL: Spawn tiles count is %d, expected 4." % spawn_count)

	# 2. Assert spawn_tiles contains corners
	var corners = [
		Vector2i(-5, -5),
		Vector2i(5, -5),
		Vector2i(-5, 5),
		Vector2i(5, 5)
	]

	var all_corners_found = true
	for corner in corners:
		if not (corner in grid_manager.spawn_tiles):
			push_error("FAIL: Corner %s not found in spawn_tiles." % str(corner))
			all_corners_found = false

	if all_corners_found:
		print("PASS: All 4 corners found in spawn_tiles.")

	# 3. Assert map boundaries
	# Based on 11x11, radius is 5 (from -5 to 5).
	# So 5,5 should be valid, 6,6 should not.

	var key_in = grid_manager.get_tile_key(5, 5)
	var key_out = grid_manager.get_tile_key(6, 6)

	if grid_manager.tiles.has(key_in):
		print("PASS: Tile (5,5) exists.")
	else:
		push_error("FAIL: Tile (5,5) missing.")

	if not grid_manager.tiles.has(key_out):
		print("PASS: Tile (6,6) correctly missing.")
	else:
		push_error("FAIL: Tile (6,6) exists but shouldn't.")

	print("TestGridConfig finished.")
