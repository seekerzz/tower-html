extends Node2D

const TILE_SCENE = preload("res://src/Scenes/Game/Tile.tscn")
const UNIT_SCENE = preload("res://src/Scenes/Game/Unit.tscn")
var BARRICADE_SCENE = null
const GHOST_TILE_SCRIPT = preload("res://src/Scripts/UI/GhostTile.gd")
const TILE_SIZE = 60

var tiles: Dictionary = {} # Key: "x,y", Value: Tile Instance
var obstacles: Dictionary = {} # Key: Vector2i, Value: Obstacle
var obstacle_map: Dictionary = {} # Key: Node, Value: Vector2i (Grid Pos)
var ghost_tiles: Array = []
var expansion_mode: bool = false
var expansion_cost: int = 50 # Base cost
var spawn_tiles: Array = [] # List of tiles (Vector2i) used as spawn points
var active_territory_tiles: Array = [] # List of Tile instances that are unlocked or core

var astar_grid: AStarGrid2D

signal grid_updated

func _ready():
	GameManager.grid_manager = self
	if ResourceLoader.exists("res://src/Scenes/Game/Barricade.tscn"):
		BARRICADE_SCENE = load("res://src/Scenes/Game/Barricade.tscn")
	_init_astar()
	create_initial_grid()
	# _generate_random_obstacles()

func try_spawn_trap(world_pos: Vector2, type_key: String):
	var gx = int(round(world_pos.x / TILE_SIZE))
	var gy = int(round(world_pos.y / TILE_SIZE))
	var grid_pos = Vector2i(gx, gy)
	var key = get_tile_key(gx, gy)

	if not tiles.has(key):
		return

	var tile = tiles[key]

	# Check requirements: No unit, No core, No obstacle
	if tile.unit != null: return
	if tile.occupied_by != Vector2i.ZERO: return
	if tile.type == "core": return
	if obstacles.has(grid_pos): return

	# _spawn_barricade(tile, type_key)

	# Inline spawning logic to ensure explicit implementation as requested and avoid confusion
	var data = Constants.BARRICADE_TYPES[type_key]
	var obstacle

	if BARRICADE_SCENE:
		obstacle = BARRICADE_SCENE.instantiate()
	else:
		obstacle = Node2D.new()
		obstacle.name = "Obstacle_" + type_key
		var visual = ColorRect.new()
		visual.size = Vector2(40, 40)
		visual.position = Vector2(-20, -20)
		if "color" in data:
			visual.color = data["color"]
		else:
			visual.color = Color.DARK_SLATE_GRAY
		obstacle.add_child(visual)

	add_child(obstacle)
	obstacle.position = tile.position

	if obstacle.has_method("init"):
		obstacle.init(Vector2i(tile.x, tile.y), type_key)

	register_obstacle(Vector2i(tile.x, tile.y), obstacle)

func _init_astar():
	astar_grid = AStarGrid2D.new()
	astar_grid.region = Rect2i(
		-Constants.MAP_WIDTH / 2,
		-Constants.MAP_HEIGHT / 2,
		Constants.MAP_WIDTH,
		Constants.MAP_HEIGHT
	)
	astar_grid.cell_size = Vector2(TILE_SIZE, TILE_SIZE)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER # Usually tower defense is Manhattan distance
	astar_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.update()

	if GameManager.has_signal("wave_started"):
		GameManager.wave_started.connect(func():
			expansion_mode = false
			# Update visibility of grid lines
			for key in tiles:
				if tiles[key].has_method("set_grid_visible"):
					tiles[key].set_grid_visible(expansion_mode)
			clear_ghosts()
		)

func create_initial_grid():
	# Clear existing
	for key in tiles:
		tiles[key].queue_free()
	tiles.clear()
	spawn_tiles.clear()
	active_territory_tiles.clear()

	var half_w = Constants.MAP_WIDTH / 2
	var half_h = Constants.MAP_HEIGHT / 2

	# Determine spawn candidates (Four corners)
	var chosen_spawns = []
	var corners = [
		Vector2i(-half_w, -half_h),
		Vector2i(half_w, -half_h),
		Vector2i(-half_w, half_h),
		Vector2i(half_w, half_h)
	]

	for corner in corners:
		chosen_spawns.append(corner)
		# Determine direction towards center
		var dx = 1 if corner.x < 0 else -1
		var dy = 1 if corner.y < 0 else -1

		# Horizontal extension
		chosen_spawns.append(Vector2i(corner.x + dx, corner.y))
		chosen_spawns.append(Vector2i(corner.x + dx * 2, corner.y))

		# Vertical extension
		chosen_spawns.append(Vector2i(corner.x, corner.y + dy))
		chosen_spawns.append(Vector2i(corner.x, corner.y + dy * 2))

	for x in range(-half_w, half_w + 1):
		for y in range(-half_h, half_h + 1):
			var type = "wilderness"
			var state = "locked_inner"

			# Check Core Zone
			if abs(x) <= Constants.CORE_ZONE_RADIUS and abs(y) <= Constants.CORE_ZONE_RADIUS:
				type = "core_zone"
				state = "locked_inner"
				if x == 0 and y == 0:
					type = "core" # The absolute center
					state = "unlocked"
			else:
				type = "wilderness"
				state = "locked_outer"

			# Check Unlocked (Cross Shape)
			# (0,0) is core, unlocked. Neighbors (0,1), (0,-1), (1,0), (-1,0) are unlocked.
			if (x == 0 and y == 0) or \
			   (x == 0 and abs(y) == 1) or \
			   (y == 0 and abs(x) == 1):
				state = "unlocked"
				if type == "wilderness":
					type = "normal"
				elif type == "core_zone":
					type = "normal"
				if x == 0 and y == 0:
					type = "core"

			# Check Spawn Points
			if Vector2i(x,y) in chosen_spawns:
				state = "spawn"
				spawn_tiles.append(Vector2i(x,y))

			create_tile(x, y, type, state)

	print("Total Spawn Tiles: ", spawn_tiles.size())

func create_tile(x: int, y: int, type: String = "normal", state: String = "locked_inner"):
	var key = get_tile_key(x, y)
	if tiles.has(key): return

	var tile = TILE_SCENE.instantiate()
	tile.setup(x, y, type)
	# Explicitly call set_state to ensure visuals are updated
	tile.set_state(state)

	tile.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	add_child(tile)
	tiles[key] = tile

	if state == "unlocked" or type == "core":
		if not active_territory_tiles.has(tile):
			active_territory_tiles.append(tile)

	tile.tile_clicked.connect(_on_tile_clicked)

	# Initial weight setup for AStar
	var grid_pos = Vector2i(x, y)
	if astar_grid.is_in_boundsv(grid_pos):
		# Assuming obstacles and locked tiles affect navigation?
		# For now standard weight, obstacles will increase it.
		astar_grid.set_point_weight_scale(grid_pos, 1.0)

func _generate_random_obstacles():
	var candidate_tiles = []
	for key in tiles:
		var tile = tiles[key]
		# Candidates: locked_outer, not spawn, not core_zone (implied by locked_outer check in create_initial_grid logic, but let's be safe)
		if tile.state == "locked_outer":
			candidate_tiles.append(tile)

	# Generate 10-15 obstacles
	var obstacle_count = randi_range(10, 15)
	obstacle_count = min(obstacle_count, candidate_tiles.size())
	candidate_tiles.shuffle()

	var placed_count = 0
	for i in range(candidate_tiles.size()):
		if placed_count >= obstacle_count: break

		var tile = candidate_tiles[i]

		# Pick random type
		var type_keys = Constants.BARRICADE_TYPES.keys()
		var type_key = type_keys.pick_random()

		_spawn_barricade(tile, type_key)

		# Check connectivity
		if not is_path_clear_from_spawns_to_core():
			# Undo
			var grid_pos = Vector2i(tile.x, tile.y)
			var obstacle = obstacles[grid_pos]
			remove_obstacle(obstacle)
			obstacle.queue_free()
		else:
			placed_count += 1

func is_path_clear_from_spawns_to_core() -> bool:
	var core_pos = Vector2i(0, 0) # Assumes core is at 0,0

	# If core itself is blocked (shouldn't happen logic wise but safe to check)
	if obstacles.has(core_pos): return false

	for spawn_pos in spawn_tiles:
		# astar_grid.get_id_path returns Array[Vector2i]
		var path = astar_grid.get_id_path(spawn_pos, core_pos)
		if path.size() == 0:
			return false
	return true

func _spawn_barricade(tile, type_key):
	var data = Constants.BARRICADE_TYPES[type_key]
	var obstacle

	if BARRICADE_SCENE:
		obstacle = BARRICADE_SCENE.instantiate()
	else:
		obstacle = Node2D.new()
		obstacle.name = "Obstacle_" + type_key
		var visual = ColorRect.new()
		visual.size = Vector2(40, 40)
		visual.position = Vector2(-20, -20)
		if "color" in data:
			visual.color = data["color"]
		else:
			visual.color = Color.DARK_SLATE_GRAY
		obstacle.add_child(visual)

	add_child(obstacle)
	obstacle.position = tile.position

	if obstacle.has_method("init"):
		obstacle.init(Vector2i(tile.x, tile.y), type_key)

	register_obstacle(Vector2i(tile.x, tile.y), obstacle)


func register_obstacle(grid_pos: Vector2i, node: Node):
	if astar_grid.is_in_boundsv(grid_pos):
		var is_solid = true
		if node.get("type") and Constants.BARRICADE_TYPES.has(node.type):
			is_solid = Constants.BARRICADE_TYPES[node.type].get("is_solid", true)

		if is_solid:
			astar_grid.set_point_solid(grid_pos, true)
		else:
			# Non-solid obstacles (traps) - ensure it's passable
			astar_grid.set_point_solid(grid_pos, false)
			astar_grid.set_point_weight_scale(grid_pos, 1.0)

	# Map the node to the grid position for later removal
	obstacle_map[node] = grid_pos
	# Add to fast lookup for placement checks
	obstacles[grid_pos] = node

func remove_obstacle(node: Node):
	if not obstacle_map.has(node):
		return

	var grid_pos = obstacle_map[node]
	if astar_grid.is_in_boundsv(grid_pos):
		astar_grid.set_point_solid(grid_pos, false)
		astar_grid.set_point_weight_scale(grid_pos, 1.0)

	obstacles.erase(grid_pos)
	obstacle_map.erase(node)

func get_nav_path(start_pos: Vector2, end_pos: Vector2) -> PackedVector2Array:
	var start_grid = Vector2i(round(start_pos.x / TILE_SIZE), round(start_pos.y / TILE_SIZE))
	var end_grid = Vector2i(round(end_pos.x / TILE_SIZE), round(end_pos.y / TILE_SIZE))

	if not astar_grid.is_in_boundsv(start_grid) or not astar_grid.is_in_boundsv(end_grid):
		return PackedVector2Array()

	return astar_grid.get_point_path(start_grid, end_grid)

func get_spawn_points() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for tile_pos in spawn_tiles:
		var local_pos = Vector2(tile_pos.x * TILE_SIZE, tile_pos.y * TILE_SIZE)
		points.append(to_global(local_pos))
	return points

func get_tile_key(x: int, y: int) -> String:
	return "%d,%d" % [x, y]

# --- Unit Logic ---

func place_unit(unit_key: String, x: int, y: int) -> bool:
	var key = get_tile_key(x, y)
	if !tiles.has(key): return false

	var tile = tiles[key]
	if tile.unit != null or tile.occupied_by != Vector2i.ZERO: return false

	var unit = UNIT_SCENE.instantiate()
	unit.setup(unit_key)

	var w = unit.unit_data.size.x
	var h = unit.unit_data.size.y

	if !can_place_unit(x, y, w, h):
		unit.queue_free()
		return false

	add_child(unit)
	unit.position = tile.position + Vector2((w-1) * TILE_SIZE * 0.5, (h-1) * TILE_SIZE * 0.5)
	unit.start_position = unit.position
	unit.grid_pos = Vector2i(x, y)

	_set_tiles_occupied(x, y, w, h, unit)

	# Register as obstacle if it's a defensive unit
	if unit.unit_data.get("trait") in ["reflect", "flat_reduce"]:
		register_obstacle(Vector2i(x, y), unit)

	recalculate_buffs()
	GameManager.recalculate_max_health()
	return true

func _set_tiles_occupied(x: int, y: int, w: int, h: int, unit):
	for dx in range(w):
		for dy in range(h):
			var t_key = get_tile_key(x + dx, y + dy)
			if tiles.has(t_key):
				var t = tiles[t_key]
				if dx == 0 and dy == 0:
					t.unit = unit
				else:
					t.occupied_by = Vector2i(x, y)

func _clear_tiles_occupied(x: int, y: int, w: int, h: int):
	for dx in range(w):
		for dy in range(h):
			var t_key = get_tile_key(x + dx, y + dy)
			if tiles.has(t_key):
				var t = tiles[t_key]
				t.unit = null
				t.occupied_by = Vector2i.ZERO

func is_in_core_zone(pos: Vector2i) -> bool:
	var key = get_tile_key(pos.x, pos.y)
	if tiles.has(key):
		return tiles[key].type == "core" or tiles[key].type == "core_zone"
	return false

func can_place_unit(x: int, y: int, w: int, h: int, exclude_unit = null) -> bool:
	for dx in range(w):
		for dy in range(h):
			var pos = Vector2i(x + dx, y + dy)
			var key = get_tile_key(x + dx, y + dy)
			if !tiles.has(key): return false
			var tile = tiles[key]
			if tile.state != "unlocked": return false
			if tile.type == "core": return false
			if tile.unit and tile.unit != exclude_unit: return false
			if obstacles.has(pos): return false
			if tile.occupied_by != Vector2i.ZERO:
				if exclude_unit and tile.occupied_by == exclude_unit.grid_pos:
					continue
				return false
	return true

func _on_tile_clicked(tile):
	if GameManager.is_wave_active: return
	# print("Clicked tile: ", tile.x, ",", tile.y)

func remove_unit_from_grid(unit):
	if unit == null: return
	var w = unit.unit_data.size.x
	var h = unit.unit_data.size.y

	if unit.unit_data.get("trait") in ["reflect", "flat_reduce"]:
		remove_obstacle(unit)

	_clear_tiles_occupied(unit.grid_pos.x, unit.grid_pos.y, w, h)
	unit.queue_free()
	recalculate_buffs()
	GameManager.recalculate_max_health()

# Drag and Drop Implementation
func handle_bench_drop_at(target_tile, data):
	var unit_key = data.key
	var bench_index = data.index

	# Try to place
	if place_unit(unit_key, target_tile.x, target_tile.y):
		# Success, remove from bench
		if GameManager.main_game:
			GameManager.main_game.remove_from_bench(bench_index)
		else:
			print("GridManager: GameManager.main_game is null during bench drop!")
		return

	# If place_unit failed, check for interactions (Devour/Merge)
	var target_unit = target_tile.unit
	if target_unit == null and target_tile.occupied_by != Vector2i.ZERO:
		var origin_key = get_tile_key(target_tile.occupied_by.x, target_tile.occupied_by.y)
		if tiles.has(origin_key):
			target_unit = tiles[origin_key].unit

	if target_unit:
		# Create a temporary unit to pass to interactions
		var temp_unit = UNIT_SCENE.instantiate()
		temp_unit.setup(unit_key)

		# Check Merge
		if target_unit.can_merge_with(temp_unit):
			target_unit.merge_with(temp_unit)
			if GameManager.main_game:
				GameManager.main_game.remove_from_bench(bench_index)
			recalculate_buffs()
			temp_unit.queue_free()
			GameManager.recalculate_max_health()
			return

		# Check Devour
		if can_devour(target_unit, temp_unit):
			target_unit.devour(temp_unit)
			if GameManager.main_game:
				GameManager.main_game.remove_from_bench(bench_index)
			recalculate_buffs()
			temp_unit.queue_free()
			GameManager.recalculate_max_health()
			return

		temp_unit.queue_free()

func handle_grid_move_at(target_tile, data):
	var unit = data.unit
	if !unit: return

	try_move_unit(unit, tiles[get_tile_key(unit.grid_pos.x, unit.grid_pos.y)], target_tile)

func try_move_unit(unit, from_tile, to_tile) -> bool:
	if unit == null or from_tile == null or to_tile == null: return false
	if from_tile == to_tile: return true

	var x = to_tile.x
	var y = to_tile.y
	var w = unit.unit_data.size.x
	var h = unit.unit_data.size.y

	# Case 1: Empty Target
	if can_place_unit(x, y, w, h, unit):
		_move_unit_internal(unit, x, y)
		return true

	# Case 2: Interaction (Merge, Devour, Swap)
	var target_unit = to_tile.unit
	if target_unit == null and to_tile.occupied_by != Vector2i.ZERO:
		var origin_key = get_tile_key(to_tile.occupied_by.x, to_tile.occupied_by.y)
		if tiles.has(origin_key):
			target_unit = tiles[origin_key].unit

	if target_unit == null: return false
	if target_unit == unit: return false

	if target_unit.can_merge_with(unit):
		target_unit.merge_with(unit)
		_clear_tiles_occupied(unit.grid_pos.x, unit.grid_pos.y, w, h)
		unit.queue_free()
		recalculate_buffs()
		return true

	if can_devour(target_unit, unit):
		target_unit.devour(unit)
		_clear_tiles_occupied(unit.grid_pos.x, unit.grid_pos.y, w, h)
		unit.queue_free()
		recalculate_buffs()
		return true

	if can_swap(unit, target_unit):
		_perform_swap(unit, target_unit)
		return true

	return false

func _move_unit_internal(unit, new_x, new_y):
	var w = unit.unit_data.size.x
	var h = unit.unit_data.size.y
	_clear_tiles_occupied(unit.grid_pos.x, unit.grid_pos.y, w, h)
	unit.grid_pos = Vector2i(new_x, new_y)
	_set_tiles_occupied(new_x, new_y, w, h, unit)

	var tile = tiles[get_tile_key(new_x, new_y)]
	unit.position = tile.position + Vector2((w-1) * TILE_SIZE * 0.5, (h-1) * TILE_SIZE * 0.5)
	unit.start_position = unit.position
	recalculate_buffs()

func can_devour(eater, food) -> bool:
	if food.unit_data.has("isFood") and food.unit_data.isFood:
		return true
	return false

func can_swap(unit_a, unit_b) -> bool:
	var pos_a = unit_a.grid_pos
	var size_a = unit_a.unit_data.size
	var pos_b = unit_b.grid_pos
	var size_b = unit_b.unit_data.size

	if size_a == size_b: return true
	if !can_place_unit_custom(pos_b.x, pos_b.y, size_a.x, size_a.y, [unit_a, unit_b]): return false
	if !can_place_unit_custom(pos_a.x, pos_a.y, size_b.x, size_b.y, [unit_a, unit_b]): return false
	return true

func can_place_unit_custom(x: int, y: int, w: int, h: int, ignore_units: Array) -> bool:
	for dx in range(w):
		for dy in range(h):
			var key = get_tile_key(x + dx, y + dy)
			if !tiles.has(key): return false
			var tile = tiles[key]
			if tile.type == "core": return false
			if tile.unit and not (tile.unit in ignore_units): return false
			if tile.occupied_by != Vector2i.ZERO:
				var origin_key = get_tile_key(tile.occupied_by.x, tile.occupied_by.y)
				if tiles.has(origin_key):
					var occupant = tiles[origin_key].unit
					if occupant and not (occupant in ignore_units):
						return false
	return true

func _perform_swap(unit_a, unit_b):
	var pos_a = unit_a.grid_pos
	var pos_b = unit_b.grid_pos
	var size_a = unit_a.unit_data.size
	var size_b = unit_b.unit_data.size

	_clear_tiles_occupied(pos_a.x, pos_a.y, size_a.x, size_a.y)
	_clear_tiles_occupied(pos_b.x, pos_b.y, size_b.x, size_b.y)

	unit_a.grid_pos = pos_b
	_set_tiles_occupied(pos_b.x, pos_b.y, size_a.x, size_a.y, unit_a)

	unit_b.grid_pos = pos_a
	_set_tiles_occupied(pos_a.x, pos_a.y, size_b.x, size_b.y, unit_b)

	var tile_for_a = tiles[get_tile_key(pos_b.x, pos_b.y)]
	unit_a.position = tile_for_a.position + Vector2((size_a.x-1) * TILE_SIZE * 0.5, (size_a.y-1) * TILE_SIZE * 0.5)
	unit_a.start_position = unit_a.position

	var tile_for_b = tiles[get_tile_key(pos_a.x, pos_a.y)]
	unit_b.position = tile_for_b.position + Vector2((size_b.x-1) * TILE_SIZE * 0.5, (size_b.y-1) * TILE_SIZE * 0.5)
	unit_b.start_position = unit_b.position

	recalculate_buffs()

func recalculate_buffs():
	var processed_units = []
	for key in tiles:
		var tile = tiles[key]
		if tile.unit and not (tile.unit in processed_units):
			tile.unit.reset_stats()
			processed_units.append(tile.unit)

	for unit in processed_units:
		if "buffProvider" in unit.unit_data:
			var buff_type = unit.unit_data["buffProvider"]
			_apply_buff_to_neighbors(unit, buff_type)

	for unit in processed_units:
		unit.update_visuals()

	grid_updated.emit()

func _apply_buff_to_neighbors(provider_unit, buff_type):
	var cx = provider_unit.grid_pos.x
	var cy = provider_unit.grid_pos.y
	var w = provider_unit.unit_data.size.x
	var h = provider_unit.unit_data.size.y
	var neighbors = []

	for dx in range(w):
		neighbors.append(Vector2i(cx + dx, cy - 1))
		neighbors.append(Vector2i(cx + dx, cy + h))

	for dy in range(h):
		neighbors.append(Vector2i(cx - 1, cy + dy))
		neighbors.append(Vector2i(cx + w, cy + dy))

	for n_pos in neighbors:
		var n_key = get_tile_key(n_pos.x, n_pos.y)
		if tiles.has(n_key):
			var tile = tiles[n_key]
			var target_unit = tile.unit
			if target_unit == null and tile.occupied_by != Vector2i.ZERO:
				var origin_key = get_tile_key(tile.occupied_by.x, tile.occupied_by.y)
				if tiles.has(origin_key):
					target_unit = tiles[origin_key].unit
			if target_unit and target_unit != provider_unit:
				target_unit.apply_buff(buff_type)

func toggle_expansion_mode():
	expansion_mode = !expansion_mode

	# Toggle grid lines on all tiles
	for key in tiles:
		if tiles[key].has_method("set_grid_visible"):
			tiles[key].set_grid_visible(expansion_mode)

	if expansion_mode:
		spawn_expansion_ghosts()
	else:
		clear_ghosts()

func spawn_expansion_ghosts():
	clear_ghosts()

	for key in tiles:
		var tile = tiles[key]

		# Limit expansion ghost tiles to center 5x5 area (plus minus 2 from center)
		if abs(tile.x) > 2 or abs(tile.y) > 2:
			continue

		# Find locked tiles that can be unlocked
		if tile.state == "locked_inner" or tile.state == "locked_outer":
			# Check neighbors
			var x = tile.x
			var y = tile.y
			var neighbors = [
				Vector2i(x+1, y), Vector2i(x-1, y),
				Vector2i(x, y+1), Vector2i(x, y-1)
			]

			var can_expand = false
			for n_pos in neighbors:
				var n_key = get_tile_key(n_pos.x, n_pos.y)
				if tiles.has(n_key):
					var n_tile = tiles[n_key]
					# If neighbor is unlocked or core (which is unlocked), we can expand
					if n_tile.state == "unlocked":
						can_expand = true
						break

			if can_expand:
				var ghost = GHOST_TILE_SCRIPT.new()
				add_child(ghost)
				ghost.setup(tile.x, tile.y)
				ghost.position = tile.position - (ghost.custom_minimum_size / 2)
				# ghost.clicked.connect(on_ghost_clicked) # GhostTile calls grid_manager.on_ghost_clicked directly
				ghost_tiles.append(ghost)

func clear_ghosts():
	for ghost in ghost_tiles:
		ghost.queue_free()
	ghost_tiles.clear()

func on_ghost_clicked(x, y):
	var cost = expansion_cost
	if GameManager.reward_manager and "rapid_expansion" in GameManager.reward_manager.acquired_artifacts:
		cost = int(cost * 0.7)

	if GameManager.gold >= cost:
		if GameManager.spend_gold(cost):
			expansion_cost += 10
			var key = get_tile_key(x, y)
			if tiles.has(key):
				var tile = tiles[key]
				tile.set_state("unlocked")
				if not active_territory_tiles.has(tile):
					active_territory_tiles.append(tile)

				# Artifact: Rapid Expansion Bonus
				if GameManager.reward_manager and "rapid_expansion" in GameManager.reward_manager.acquired_artifacts:
					GameManager.permanent_health_bonus += 50.0
					GameManager.max_core_health += 50.0
					GameManager.core_health += 50.0 # Heal by the added amount
					GameManager.resource_changed.emit()

			# Refresh ghosts to show new expansion options
			# Must use call_deferred or just call it?
			# The prompt says: "call clear_ghosts() then immediately re-spawn_expansion_ghosts()"
			clear_ghosts()
			spawn_expansion_ghosts()
	else:
		# Feedback for not enough gold?
		GameManager.spawn_floating_text(Vector2(x*TILE_SIZE, y*TILE_SIZE), "Need Gold!", Color.RED)

func get_closest_unlocked_tile(world_pos: Vector2) -> Node2D:
	if active_territory_tiles.is_empty():
		# Fallback to core if exists
		var core_key = get_tile_key(0, 0)
		if tiles.has(core_key):
			return tiles[core_key]
		return null

	var closest_tile = null
	var min_dist_sq = INF

	for tile in active_territory_tiles:
		# Check if valid instance
		if not is_instance_valid(tile): continue

		var dist_sq = tile.global_position.distance_squared_to(world_pos)
		if dist_sq < min_dist_sq:
			min_dist_sq = dist_sq
			closest_tile = tile

	return closest_tile
