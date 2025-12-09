extends Node2D

const TILE_SCENE = preload("res://src/Scenes/Game/Tile.tscn")
const UNIT_SCENE = preload("res://src/Scenes/Game/Unit.tscn")
const GHOST_TILE_SCRIPT = preload("res://src/Scripts/UI/GhostTile.gd")
const TILE_SIZE = 60

var tiles: Dictionary = {} # Key: "x,y", Value: Tile Instance
var ghost_tiles: Array = []
var expansion_mode: bool = false
var expansion_cost: int = 50 # Base cost

# A* Pathfinding
var astar: AStarGrid2D
var nav_refresh_timer: float = 0.0

signal grid_updated

func _ready():
	GameManager.grid_manager = self

	astar = AStarGrid2D.new()
	astar.cell_size = Vector2(TILE_SIZE, TILE_SIZE)
	# Default estimate is Manhattan, which is fine for grid
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER # Assuming 4-way movement, change if diagonal allowed

	create_initial_grid()

	GameManager.obstacles_changed.connect(update_nav_grid)
	update_nav_grid()

func create_initial_grid():
	create_tile(0, 0, "core")
	create_tile(0, 1)
	create_tile(0, -1)
	create_tile(1, 0)
	create_tile(-1, 0)

func create_tile(x: int, y: int, type: String = "normal"):
	var key = get_tile_key(x, y)
	if tiles.has(key): return

	var tile = TILE_SCENE.instantiate()
	tile.setup(x, y, type)
	tile.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	add_child(tile)
	tiles[key] = tile

	tile.tile_clicked.connect(_on_tile_clicked)
	update_nav_grid()

func get_tile_key(x: int, y: int) -> String:
	return "%d,%d" % [x, y]

# --- Pathfinding Interface ---

func update_nav_grid():
	if tiles.is_empty(): return

	# Determine bounds
	var min_x = 0
	var min_y = 0
	var max_x = 0
	var max_y = 0
	var first = true

	for key in tiles:
		var t = tiles[key]
		if first:
			min_x = t.x
			max_x = t.x
			min_y = t.y
			max_y = t.y
			first = false
		else:
			if t.x < min_x: min_x = t.x
			if t.x > max_x: max_x = t.x
			if t.y < min_y: min_y = t.y
			if t.y > max_y: max_y = t.y

	# Add padding to region to allow movement outside strictly placed tiles if needed,
	# but usually enemies move on tiles. Let's stick to tile bounds.
	var region = Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
	astar.region = region
	astar.update()

	# Set weights
	# 1. Base weights from tiles
	for key in tiles:
		var t = tiles[key]
		var point = Vector2i(t.x, t.y)

		# If tile has unit, high weight
		if t.unit != null or t.occupied_by != Vector2i.ZERO:
			astar.set_point_weight_scale(point, 50.0)
		else:
			astar.set_point_weight_scale(point, 1.0)

	# 2. Rasterize Barricades
	# Barricades are line segments. We need to find which cells they cross.
	var barricades = get_tree().get_nodes_in_group("barricades")
	for b in barricades:
		if b.is_queued_for_deletion(): continue
		if !b.has_node("CollisionShape2D"): continue
		var cs = b.get_node("CollisionShape2D")
		if !cs.shape is SegmentShape2D: continue

		var p1 = cs.to_global(cs.shape.a)
		var p2 = cs.to_global(cs.shape.b)

		_rasterize_line_to_astar(p1, p2)

func _rasterize_line_to_astar(start: Vector2, end: Vector2):
	# Convert world pos to grid coords
	var start_grid = local_to_map(start)
	var end_grid = local_to_map(end)

	# Simple line drawing on grid (Bresenham or just iterating points)
	# Since AStarGrid2D uses integer coordinates, we can iterate along the line.

	var points = _get_grid_line(start_grid, end_grid)
	for p in points:
		if astar.region.has_point(p):
			astar.set_point_weight_scale(p, 50.0)

func local_to_map(pos: Vector2) -> Vector2i:
	return Vector2i(round(pos.x / TILE_SIZE), round(pos.y / TILE_SIZE))

func map_to_local(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE)

func _get_grid_line(p0: Vector2i, p1: Vector2i) -> Array[Vector2i]:
	var points: Array[Vector2i] = []
	var x0 = p0.x
	var y0 = p0.y
	var x1 = p1.x
	var y1 = p1.y

	var dx = abs(x1 - x0)
	var dy = -abs(y1 - y0)
	var sx = 1 if x0 < x1 else -1
	var sy = 1 if y0 < y1 else -1
	var err = dx + dy

	while true:
		points.append(Vector2i(x0, y0))
		if x0 == x1 and y0 == y1: break
		var e2 = 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy
	return points

func get_nav_path(from_pos: Vector2, to_pos: Vector2) -> PackedVector2Array:
	var from_grid = local_to_map(from_pos)
	var to_grid = local_to_map(to_pos)

	# Clamp to region? Or check if in region
	if !astar.region.has_point(from_grid) or !astar.region.has_point(to_grid):
		# If outside, maybe just return direct line or empty?
		# For now return empty, or try to clamp.
		# If enemy spawns outside, it might get stuck.
		pass

	var path_points = astar.get_point_path(from_grid, to_grid)
	# Convert back to world coordinates
	# Ideally, we want the center of the tile, which map_to_local should give (if using round/offset correctly)
	# Our map_to_local uses round(pos/size)*size. Wait.
	# 0,0 tile is at 0,0 world.
	# map_to_local(0,0) -> 0,0. Correct.
	return path_points

# --- Existing Logic ---

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
	recalculate_buffs()
	update_nav_grid() # Update pathfinding
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

func can_place_unit(x: int, y: int, w: int, h: int, exclude_unit = null) -> bool:
	for dx in range(w):
		for dy in range(h):
			var key = get_tile_key(x + dx, y + dy)
			if !tiles.has(key): return false
			var tile = tiles[key]
			if tile.type == "core": return false
			if tile.unit and tile.unit != exclude_unit: return false
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
	_clear_tiles_occupied(unit.grid_pos.x, unit.grid_pos.y, w, h)
	unit.queue_free()
	recalculate_buffs()
	update_nav_grid() # Update pathfinding

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
		update_nav_grid()
		return true

	# Case 2: Interaction (Merge, Devour, Swap)
	var target_unit = to_tile.unit
	if target_unit == null and to_tile.occupied_by != Vector2i.ZERO:
		var origin_key = get_tile_key(to_tile.occupied_by.x, to_tile.occupied_by.y)
		if tiles.has(origin_key):
			target_unit = tiles[origin_key].unit

	if target_unit == null: return false
	if target_unit == unit: return false

	if target_unit.type_key == unit.type_key:
		target_unit.merge_with(unit)
		_clear_tiles_occupied(unit.grid_pos.x, unit.grid_pos.y, w, h)
		unit.queue_free()
		recalculate_buffs()
		update_nav_grid()
		return true

	if can_devour(target_unit, unit):
		target_unit.devour(unit)
		_clear_tiles_occupied(unit.grid_pos.x, unit.grid_pos.y, w, h)
		unit.queue_free()
		recalculate_buffs()
		update_nav_grid()
		return true

	if can_swap(unit, target_unit):
		_perform_swap(unit, target_unit)
		update_nav_grid()
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

# Expansion Logic
func toggle_expansion_mode():
	expansion_mode = !expansion_mode
	if expansion_mode:
		spawn_expansion_ghosts()
	else:
		clear_ghosts()

func spawn_expansion_ghosts():
	clear_ghosts()

	# Find all empty spots adjacent to existing tiles
	var candidates = []
	var visited = {}

	for key in tiles:
		var tile = tiles[key]
		var neighbors = [
			Vector2i(tile.x+1, tile.y), Vector2i(tile.x-1, tile.y),
			Vector2i(tile.x, tile.y+1), Vector2i(tile.x, tile.y-1)
		]

		for n in neighbors:
			var n_key = get_tile_key(n.x, n.y)
			if !tiles.has(n_key) and !visited.has(n_key):
				candidates.append(n)
				visited[n_key] = true

	for pos in candidates:
		var ghost = Button.new() # Using Button as base for GhostTile logic, but better use our script
		# Actually, we created GhostTile.gd which extends Button.
		ghost.set_script(GHOST_TILE_SCRIPT)
		ghost.setup(pos.x, pos.y)

		ghost.position = Vector2(pos.x * TILE_SIZE, pos.y * TILE_SIZE) + Vector2(-30, -30)
		# GhostTile.gd handles size/text

		# Add a tooltip or text for cost
		ghost.tooltip_text = "Expand Cost: %d" % expansion_cost

		add_child(ghost)
		ghost_tiles.append(ghost)

func clear_ghosts():
	for g in ghost_tiles:
		g.queue_free()
	ghost_tiles.clear()

func on_ghost_clicked(x, y):
	if GameManager.gold >= expansion_cost:
		GameManager.spend_gold(expansion_cost)
		create_tile(x, y)
		expansion_cost += 10 # Increase cost
		spawn_expansion_ghosts() # Refresh
	else:
		GameManager.spawn_floating_text(Vector2(x*TILE_SIZE, y*TILE_SIZE), "Need %d Gold" % expansion_cost, Color.RED)
