extends Node2D

@onready var grid_manager = $GridManager
@onready var camera = $Camera2D

func _ready():
	# Wait for grid manager to initialize
	await get_tree().process_frame

	# Clear existing obstacles for test
	for obs in grid_manager.obstacles.values():
		grid_manager.remove_obstacle(obs)
		obs.queue_free()

	print("Running Pathfinding Verification Test...")

	var start = Vector2i(0, 0)
	var end = Vector2i(0, 5)

	# 1. Test with a gap reasonably close
	print("\nTest 1: Wood Wall with nearby gap (High Cost vs Detour)")
	_build_wall_with_gap(3, -5, 5, 2, "wood")

	var path1 = grid_manager.astar_grid.get_id_path(start, end)
	var path_through_wall1 = false
	for p in path1:
		if p.y == 3 and p.x != 2:
			path_through_wall1 = true
			break

	if not path_through_wall1:
		print("PASS: Path took detour through gap at (2,3) instead of breaking wood.")
	else:
		print("FAIL: Path broke through wood wall despite nearby gap.")
		print("Path: ", path1)

	# 2. Test with a gap very far away
	print("\nTest 2: Wood Wall with far gap (High Cost vs Long Detour)")
	_clear_wall_at_y(3, -5, 5)
	# Make a solid wood wall
	for x in range(-5, 6):
		_spawn_obstacle(x, 3, "wood")

	var path2 = grid_manager.astar_grid.get_id_path(start, end)
	if path2.size() > 0:
		var on_wall = false
		for p in path2:
			if p.y == 3: on_wall = true
		if on_wall:
			print("PASS: Path found through wood wall (breaking it) when no gap exists.")
		else:
			print("FAIL: Path found but didn't cross wall? " + str(path2))
	else:
		print("FAIL: No path found through wood wall! It should be walkable with high cost.")

	# 3. Test Stone Wall (Immune)
	print("\nTest 3: Stone Wall (Immune)")
	_clear_wall_at_y(3, -5, 5)
	for x in range(-5, 6):
		_spawn_obstacle(x, 3, "stone")

	var path3 = grid_manager.astar_grid.get_id_path(start, end)
	if path3.size() == 0:
		print("PASS: No path through complete Stone wall.")
	else:
		print("FAIL: Path found through Stone wall! " + str(path3))

func _build_wall_with_gap(y, x_min, x_max, gap_x, type):
	_clear_wall_at_y(y, x_min, x_max)
	for x in range(x_min, x_max + 1):
		if x == gap_x: continue
		_spawn_obstacle(x, y, type)

func _clear_wall_at_y(y, x_min, x_max):
	for x in range(x_min, x_max + 1):
		var pos = Vector2i(x, y)
		if grid_manager.obstacles.has(pos):
			var obs = grid_manager.obstacles[pos]
			grid_manager.remove_obstacle(obs)
			obs.queue_free()

func _spawn_obstacle(x, y, type):
	# Mock obstacle node
	var obs = Node2D.new()
	if ResourceLoader.exists("res://src/Scripts/Barricade.gd"):
		obs.set_script(load("res://src/Scripts/Barricade.gd"))

	if not obs.get_script():
		obs = Node.new()
		var script = GDScript.new()
		script.source_code = "extends Node\nvar type = '%s'" % type
		script.reload()
		obs.set_script(script)
	else:
		obs.type = type

	grid_manager.register_obstacle(Vector2i(x, y), obs)

func _process(delta):
	# Simple camera movement
	if Input.is_action_pressed("ui_right"): camera.position.x += 200 * delta
	if Input.is_action_pressed("ui_left"): camera.position.x -= 200 * delta
	if Input.is_action_pressed("ui_down"): camera.position.y += 200 * delta
	if Input.is_action_pressed("ui_up"): camera.position.y -= 200 * delta
