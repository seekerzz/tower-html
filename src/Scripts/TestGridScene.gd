extends Node2D

@onready var grid_manager = $GridManager
@onready var camera = $Camera2D

func _ready():
	print("Starting Verification...")

	# Wait a frame or ensure init is done
	await get_tree().process_frame

	verify_pathfinding()

	get_tree().quit()

func verify_pathfinding():
	print("Verifying Pathfinding...")
	var start = Vector2(0, 0)
	var end = Vector2(180, 0) # (3,0) roughly

	# 1. Straight path
	var path = grid_manager.get_nav_path(start, end)
	print("Path straight size: ", path.size())
	if path.size() > 0:
		print("Path start: ", path[0])
		print("Path end: ", path[-1])
		# With center offset, (0,0) -> (30,30)? No, (0,0) is center of tile (0,0) usually in this game?
		# Tile position: x * TILE_SIZE. So (0,0) is center of tile (0,0)?
		# Let's check create_tile: tile.position = Vector2(x * TILE_SIZE, y * TILE_SIZE).
		# If TILE_SIZE=60. (0,0) is at world (0,0).
		# astar_grid.offset = cell_size / 2. This means the point returned is offset by half cell size from the cell's top-left.
		# AStarGrid2D coordinates: usually (0,0) is the top-left-most cell if region is 0,0 based.
		# But here region is -9 to 9.
		# If I ask for path from (0,0) world, that's grid (0,0).
		# The returned path points will be center of cells.
		# Grid (0,0) center should be ... wait.
		# If region.position is (-9, -5). Grid (0,0) is at index relative to region?
		# No, AStarGrid2D uses absolute coordinates if region is set.
		# So get_point_path(Vector2i(0,0), Vector2i(3,0)) returns world positions corresponding to those grid cells.
		# If cell_size is (60,60).
		# Cell (0,0) top-left is (0,0) * 60 = (0,0).
		# With offset (30,30). Center is (30,30).
		# Wait, if `create_tile` puts tile at (0,0) world for grid (0,0).
		# That means the tile sprite is centered at (0,0)?
		# `tile.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)`
		# If Tile is a Node2D/Sprite, where is its origin? Usually center.
		# If so, the world (0,0) is the center of tile (0,0).
		# But AStarGrid2D (0,0) with offset (30,30) would be (30,30) world.
		# This is a mismatch.
		# If I want AStarGrid2D point to align with Tile center (0,0), I should NOT add offset?
		# Or `offset` should be (0,0) and `cell_size` is just for distance?
		# Or maybe `region` handling shifts things?
		# AStarGrid2D: "The position of a point is calculated as (id * cell_size) + offset".
		# So for id(0,0), pos = (0,0) + offset.
		# If I want pos to be (0,0), offset must be (0,0).
		# If I verified `tile.position` is (0,0).
		# So I should REMOVE `astar_grid.offset = ...` or set it to (0,0).
		# BUT earlier I added `astar_grid.offset = Vector2(TILE_SIZE, TILE_SIZE) / 2.0`.
		# This would make point (0,0) be at (30,30).
		# Let's verify this in the test.
		pass

	# 2. Obstacle (Wall)
	var wall_pos = Vector2i(1, 0)
	var wall_node = Node.new()
	grid_manager.register_obstacle(wall_pos, "wall", wall_node)

	var path_obs = grid_manager.get_nav_path(start, end)
	print("Path with wall size: ", path_obs.size())

	var deviated = false
	for p in path_obs:
		if abs(p.y) > 10:
			deviated = true

	if deviated:
		print("PASS: Path deviated with wall.")
	else:
		print("FAIL: Path did not deviate with wall. Points: ", path_obs)

	# 3. Obstacle (Trap)
	grid_manager.remove_obstacle(wall_node)
	wall_node.queue_free()

	var trap_pos = Vector2i(1, 0)
	var trap_node = Node.new()
	grid_manager.register_obstacle(trap_pos, "trap", trap_node)

	var path_trap = grid_manager.get_nav_path(start, end)
	print("Path with trap size: ", path_trap.size())

	var straight_trap = true
	for p in path_trap:
		if abs(p.y) > 10:
			straight_trap = false

	if straight_trap:
		print("PASS: Path straight with trap.")
	else:
		print("FAIL: Path deviated with trap.")

	trap_node.queue_free()

func _process(delta):
	pass
