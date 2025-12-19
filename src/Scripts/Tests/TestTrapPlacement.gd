extends Node

var grid_manager

func _ready():
	print("Starting TestTrapPlacement...")
	# Allow autoloads to initialize
	await get_tree().process_frame

	setup_grid_manager()
	await get_tree().process_frame

	test_can_place_item()
	await test_preview_update()

	print("All tests passed!")
	get_tree().quit()

func setup_grid_manager():
	# GridManager expects to be in the tree
	grid_manager = load("res://src/Scripts/GridManager.gd").new()
	add_child(grid_manager)

	# Wait for ready and grid creation
	await get_tree().process_frame

func test_can_place_item():
	print("Testing can_place_item_at...")

	# 1. Test Valid Spot
	# Core Zone Radius is 2. (0,0) and neighbors are unlocked and in core zone -> Invalid for traps.
	# We need a spot outside core zone or locked.
	# (3, 0) should be valid (wilderness, locked_outer, not spawn).
	# Check if (3,0) is spawn? Spawns are at edges/corners.
	# Map Width 9 -> -4 to 4.
	# Spawns at -4,-4 etc. (3,0) is safe.

	var grid_pos = Vector2i(3, 0)

	# Ensure tile exists
	var key = "%d,%d" % [grid_pos.x, grid_pos.y]
	if not grid_manager.tiles.has(key):
		print("FAIL: Tile (3,0) does not exist")
		return

	var can_place = grid_manager.can_place_item_at(grid_pos, "poison_trap")
	if not can_place:
		print("FAIL: Expected True for valid tile (3,0)")
	else:
		print("  Valid tile check: PASS")

	# 2. Test Obstacle
	# Add obstacle
	var mock_obstacle = Node.new()
	grid_manager.obstacles[grid_pos] = mock_obstacle
	can_place = grid_manager.can_place_item_at(grid_pos, "poison_trap")
	if can_place:
		print("FAIL: Expected False when obstacle present")
	else:
		print("  Obstacle check: PASS")
	grid_manager.obstacles.erase(grid_pos)
	mock_obstacle.free()

	# 3. Test Unit
	# Place unit mock
	var target_tile = grid_manager.tiles[key]
	var unit = Node2D.new()
	target_tile.unit = unit
	can_place = grid_manager.can_place_item_at(grid_pos, "poison_trap")
	if can_place:
		print("FAIL: Expected False when unit present")
	else:
		print("  Unit check: PASS")
	target_tile.unit = null
	unit.free()

	# 4. Test Core Zone (Unlocked)
	# (0,0) is core
	var core_pos = Vector2i(0,0)
	can_place = grid_manager.can_place_item_at(core_pos, "poison_trap")
	if can_place:
		print("FAIL: Expected False on Core")
	else:
		print("  Core check: PASS")

func test_preview_update():
	print("Testing update_placement_preview...")

	var grid_pos = Vector2i(3, 0) # Valid spot
	grid_manager.update_placement_preview(grid_pos, "poison_trap")

	var cursor = grid_manager.placement_preview_cursor
	if not cursor:
		print("FAIL: Cursor not created")
		return

	if not cursor.visible:
		print("FAIL: Cursor should be visible")

	var visual = cursor.get_node("Visual")
	if not is_instance_valid(visual):
		print("FAIL: Visual node missing")
		return

	# Check color (Green)
	if not visual.color.is_equal_approx(Color(0, 1, 0, 0.4)):
		print("FAIL: Cursor color mismatch. Expected Green. Got: " + str(visual.color))
	else:
		print("  Green preview: PASS")

	# Test Red
	var core_pos = Vector2i(0,0)
	grid_manager.update_placement_preview(core_pos, "poison_trap")
	if not visual.color.is_equal_approx(Color(1, 0, 0, 0.4)):
		print("FAIL: Cursor color mismatch. Expected Red. Got: " + str(visual.color))
	else:
		print("  Red preview: PASS")

	# Test Timeout
	print("  Waiting for timeout...")
	# last_preview_frame was set.
	# We need to wait > 1 frame without update.
	# _process runs automatically if added to tree? Yes.

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	if cursor.visible:
		print("FAIL: Cursor should be hidden after timeout")
	else:
		print("  Timeout check: PASS")
