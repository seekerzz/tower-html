extends Node2D

const TILE_SCENE = preload("res://src/Scenes/Game/Tile.tscn")
const UNIT_SCENE = preload("res://src/Scenes/Game/Unit.tscn")
const TILE_SIZE = Constants.TILE_SIZE

var tiles: Dictionary = {} # Key: "x,y", Value: Tile Instance
var astar: AStarGrid2D
var obstacles: Dictionary = {} # Key: "x,y", Value: Node (Obstacle)

signal grid_updated

func _ready():
	GameManager.grid_manager = self
	_init_astar()
	generate_grid()

func _init_astar():
	astar = AStarGrid2D.new()
	# Region covering from (-9, -5) to (9, 5). Size is 19x11.
	astar.region = Rect2i(-9, -5, 19, 11)
	astar.cell_size = Vector2(TILE_SIZE, TILE_SIZE)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.update()

func generate_grid():
	for x in range(-9, 10):
		for y in range(-5, 6):
			_create_tile_at(x, y)

	grid_updated.emit()

func _create_tile_at(x: int, y: int):
	var tile = TILE_SCENE.instantiate()
	var zone = _get_zone(x, y)

	tile.setup(x, y, "normal")
	tile.zone = zone
	tile.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	add_child(tile)

	var key = get_tile_key(x, y)
	tiles[key] = tile

	if zone == "wilderness":
		if randf() < 0.125: # 10%-15%
			_spawn_obstacle(x, y)

	tile.tile_clicked.connect(_on_tile_clicked)
	_update_tile_visuals(tile)

func _get_zone(x: int, y: int) -> String:
	if abs(x) <= Constants.CORE_ZONE_RADIUS and abs(y) <= Constants.CORE_ZONE_RADIUS:
		return "core"
	return "wilderness"

func _spawn_obstacle(x: int, y: int):
	var types = ["stone", "wood"]
	var type = types.pick_random()

	var key = get_tile_key(x, y)
	if tiles.has(key):
		var tile = tiles[key]
		tile.obstacle_type = type
		update_tile_weight(Vector2i(x, y), true)

func update_tile_weight(grid_pos: Vector2i, is_obstacle: bool):
	if !astar.region.has_point(grid_pos): return
	var weight = 50.0 if is_obstacle else 1.0
	astar.set_point_weight_scale(grid_pos, weight)

func get_nav_path(start_world_pos: Vector2, end_world_pos: Vector2) -> PackedVector2Array:
	var start_grid = world_to_grid(start_world_pos)
	var end_grid = world_to_grid(end_world_pos)

	if !astar.region.has_point(start_grid) or !astar.region.has_point(end_grid):
		return PackedVector2Array()

	var path_points = astar.get_point_path(start_grid, end_grid)
	var world_path = PackedVector2Array()

	for point in path_points:
		world_path.append(grid_to_world(point))

	return world_path

func get_spawn_points() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for x in range(-9, 10):
		points.append(grid_to_world(Vector2i(x, -5)))
		points.append(grid_to_world(Vector2i(x, 5)))

	for y in range(-4, 5):
		points.append(grid_to_world(Vector2i(-9, y)))
		points.append(grid_to_world(Vector2i(9, y)))

	return points

func world_to_grid(pos: Vector2) -> Vector2i:
	return Vector2i(round(pos.x / TILE_SIZE), round(pos.y / TILE_SIZE))

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE)

func get_tile_key(x: int, y: int) -> String:
	return "%d,%d" % [x, y]

func _on_tile_clicked(tile):
	if GameManager.is_wave_active: return

func _update_tile_visuals(tile):
	tile.update_visuals()

# Unit Placement
func place_unit(unit_key: String, x: int, y: int) -> bool:
	var key = get_tile_key(x, y)
	if !tiles.has(key): return false

	var tile = tiles[key]

	# Strict zone check for UNITS
	if tile.zone != "core":
		GameManager.spawn_floating_text(tile.position, "Can only place units in Core Zone!", Color.RED)
		return false

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
	return true

func can_place_unit(x: int, y: int, w: int, h: int, exclude_unit = null) -> bool:
	for dx in range(w):
		for dy in range(h):
			var key = get_tile_key(x + dx, y + dy)
			if !tiles.has(key): return false
			var tile = tiles[key]

			if tile.zone != "core": return false

			if tile.unit and tile.unit != exclude_unit: return false
			if tile.occupied_by != Vector2i.ZERO:
				if exclude_unit and tile.occupied_by == exclude_unit.grid_pos:
					continue
				return false
			if tile.obstacle_type != "": return false
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

func handle_unit_drop(unit):
	var m_pos = get_global_mouse_position()
	var grid_pos = world_to_grid(m_pos)

	var key = get_tile_key(grid_pos.x, grid_pos.y)
	if tiles.has(key):
		var target_tile = tiles[key]
		return try_move_unit(unit, tiles[get_tile_key(unit.grid_pos.x, unit.grid_pos.y)], target_tile)

	return false

func try_move_unit(unit, from_tile, to_tile) -> bool:
	if unit == null or from_tile == null or to_tile == null: return false
	if from_tile == to_tile: return true

	var x = to_tile.x
	var y = to_tile.y
	var w = unit.unit_data.size.x
	var h = unit.unit_data.size.y

	if to_tile.zone != "core":
		GameManager.spawn_floating_text(to_tile.position, "Only in Core!", Color.RED)
		return false

	if can_place_unit(x, y, w, h, unit):
		_move_unit_internal(unit, x, y)
		return true

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
	# If sizes differ, checking swap is harder, so return false for now to avoid bugs
	return false

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

func handle_bench_drop_at(target_tile, data):
	var unit_key = data.key
	var bench_index = data.index
	if place_unit(unit_key, target_tile.x, target_tile.y):
		if GameManager.main_game:
			GameManager.main_game.remove_from_bench(bench_index)
