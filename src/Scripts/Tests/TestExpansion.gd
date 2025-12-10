extends Node

func _ready():
	print("Starting TestExpansion...")
	test_initial_grid()
	test_expansion_mode()
	test_expansion_purchase()
	print("TestExpansion Completed Successfully")
	get_tree().quit()

func test_initial_grid():
	var grid_manager = load("res://src/Scripts/GridManager.gd").new()
	add_child(grid_manager)

	# Wait for ready? _ready is called on add_child

	# Check Center (0,0)
	var center_key = grid_manager.get_tile_key(0, 0)
	var center_tile = grid_manager.tiles[center_key]
	assert_true(!center_tile.is_locked, "Center tile (0,0) should be unlocked")

	# Check (3,3) which is outside radius 2 (2,2) is max
	var locked_key = grid_manager.get_tile_key(3, 3)
	if grid_manager.tiles.has(locked_key):
		var locked_tile = grid_manager.tiles[locked_key]
		assert_true(locked_tile.is_locked, "Tile (3,3) should be locked")
	else:
		print("Tile (3,3) not found in grid, skipping specific check")

	grid_manager.queue_free()

func test_expansion_mode():
	var grid_manager = load("res://src/Scripts/GridManager.gd").new()
	add_child(grid_manager)

	grid_manager.toggle_expansion_mode()

	assert_true(grid_manager.expansion_mode, "Expansion mode should be active")
	assert_true(grid_manager.ghost_tiles.size() > 0, "Ghost tiles should be spawned")

	# Verify ghost positions (should be adjacent to unlocked zone)
	var found_valid_ghost = false
	for ghost in grid_manager.ghost_tiles:
		var x = ghost.grid_x
		var y = ghost.grid_y
		# Radius 2 is unlocked. (2,0) is unlocked. (3,0) should be ghost.
		if x == 3 and y == 0:
			found_valid_ghost = true

	assert_true(found_valid_ghost, "Should find ghost at (3,0)")

	grid_manager.queue_free()

func test_expansion_purchase():
	var grid_manager = load("res://src/Scripts/GridManager.gd").new()
	add_child(grid_manager)

	# Setup gold
	GameManager.gold = 1000

	grid_manager.toggle_expansion_mode()
	var initial_gold = GameManager.gold
	var cost = grid_manager.expansion_cost

	# Pick a ghost to click (e.g., 3,0)
	var target_ghost = null
	for ghost in grid_manager.ghost_tiles:
		if ghost.grid_x == 3 and ghost.grid_y == 0:
			target_ghost = ghost
			break

	assert_true(target_ghost != null, "Target ghost (3,0) not found")

	# Click it
	grid_manager.on_ghost_clicked(3, 0)

	# Verify
	assert_true(GameManager.gold == initial_gold - cost, "Gold should be deducted")
	assert_true(grid_manager.unlocked_zones.has(Vector2i(3, 0)), "(3,0) should be unlocked")

	var tile = grid_manager.tiles[grid_manager.get_tile_key(3, 0)]
	assert_true(!tile.is_locked, "Tile (3,0) should be unlocked visually")

	# Ghost should be gone from that pos (new ghosts spawned)
	var still_has_ghost = false
	for ghost in grid_manager.ghost_tiles:
		if ghost.grid_x == 3 and ghost.grid_y == 0:
			still_has_ghost = true
			break
	assert_true(!still_has_ghost, "Ghost at (3,0) should be removed")

	# New ghosts should be at (4,0)
	var new_ghost_found = false
	for ghost in grid_manager.ghost_tiles:
		if ghost.grid_x == 4 and ghost.grid_y == 0:
			new_ghost_found = true
			break
	assert_true(new_ghost_found, "New ghost should appear at (4,0)")

	grid_manager.queue_free()

func assert_true(condition, message):
	if !condition:
		print("FAILED: ", message)
		get_tree().quit(1)
	else:
		print("PASSED: ", message)
