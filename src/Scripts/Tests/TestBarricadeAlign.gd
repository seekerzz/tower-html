extends Node2D

var draw_manager
var grid_manager

func _ready():
	# Since this script runs attached to a Node in a Scene that includes Autoloads (if run properly),
	# GameManager should be available.

	if not get_node("/root/GameManager"):
		print("GameManager Autoload not found! Attempting manual setup (risky)")
		# This happens if we run godot -s? No, if we run the SCENE, autoloads should be there.
		# But godot --headless path/to/scene.tscn works.
	else:
		print("GameManager found.")

	_run_test()
	get_tree().quit()

func _run_test():
	print("Starting TestBarricadeAlign verification...")

	# 1. Setup Environment
	grid_manager = load("res://src/Scripts/GridManager.gd").new()
	add_child(grid_manager)

	# DrawManager
	draw_manager = load("res://src/Scripts/DrawManager.gd").new()
	add_child(draw_manager)

	# Inject GridManager into GameManager (since GridManager._ready does it, but we want to be sure)
	# GridManager._ready() calls GameManager.grid_manager = self
	# So it should be set.

	if GameManager.grid_manager != grid_manager:
		print("Error: GridManager not registered in GameManager")
		return

	# Setup Materials
	GameManager.materials["wood"] = 100 # Ensure enough resources

	# 2. Simulate Mouse Move to (65, 65)
	var mouse_pos = Vector2(65, 65)
	var TILE_SIZE = 60

	print("Simulating mouse move to: ", mouse_pos)
	draw_manager.current_material = "wood" # Select material to enable ghost
	draw_manager._update_ghost(mouse_pos)

	# 3. Verify Ghost Position
	var ghost = draw_manager.ghost_tile
	if ghost == null:
		print("Error: Ghost tile not created")
		return

	print("Ghost Tile Position: ", ghost.position)
	var expected_ghost_pos = Vector2(60, 60)

	if ghost.position.is_equal_approx(expected_ghost_pos):
		print("PASS: Ghost Tile Position is correct.")
	else:
		print("FAIL: Ghost Tile Position is ", ghost.position, ", expected ", expected_ghost_pos)

	# 4. Simulate Build
	# Note: Build might fail if (65, 65) is in core zone or has obstacle.
	# (1, 1) is likely in core zone if radius is 2?
	# Constants.CORE_ZONE_RADIUS = 2.
	# If radius 2, then -2 to 2 are core zone. (1, 1) is inside.

	# If build fails, we cannot verify Barricade Position.
	# We should try to build outside core zone.
	# Or we assume the user wanted to test functionality.

	# Let's check if (1,1) is valid.
	if GameManager.grid_manager.is_in_core_zone(Vector2i(1, 1)):
		print("Warning: (1, 1) is in Core Zone. Build will fail.")
		# Try to move to outside core zone for build verification?
		# Or just mock the core zone check?
		# Let's try (3, 3).
		mouse_pos = Vector2(185, 185) # 3 * 60 + 5
		print("Retrying build at valid location: ", mouse_pos)
		draw_manager._update_ghost(mouse_pos)

		# Verify ghost at new pos
		expected_ghost_pos = Vector2(180, 180)
		if draw_manager.ghost_tile.position.is_equal_approx(expected_ghost_pos):
			print("PASS: Ghost Tile Position (3,3) is correct.")
		else:
			print("FAIL: Ghost Tile Position (3,3) is ", draw_manager.ghost_tile.position)

	print("Simulating build at: ", mouse_pos)
	draw_manager._try_build(mouse_pos)

	# 5. Verify Barricade Position
	var barricade = null
	for child in get_children():
		if child.name.begins_with("Barricade") or child is StaticBody2D: # Barricade extends StaticBody2D
			barricade = child
			break

	if barricade == null:
		print("Error: Barricade not found among children")
		print("Children: ", get_children())
	else:
		print("Barricade Position: ", barricade.position)
		var expected_barricade_pos = Vector2(mouse_pos.x, mouse_pos.y).snapped(Vector2(TILE_SIZE, TILE_SIZE))
		# Actually snapped gives nearest multiple. 185 -> 180.
		# _world_to_grid uses round.
		# round(185/60) = 3. 3*60 = 180.

		if barricade.position.is_equal_approx(expected_ghost_pos):
			print("PASS: Barricade Position is correct.")
		else:
			print("FAIL: Barricade Position is ", barricade.position, ", expected ", expected_ghost_pos)
