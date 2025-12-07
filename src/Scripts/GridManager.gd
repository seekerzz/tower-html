extends Node2D

const TILE_SCENE = preload("res://src/Scenes/Game/Tile.tscn")
const UNIT_SCENE = preload("res://src/Scenes/Game/Unit.tscn")
const TILE_SIZE = 60

var tiles: Dictionary = {} # Key: "x,y", Value: Tile Instance
var selected_unit = null

func _ready():
	GameManager.grid_manager = self
	create_initial_grid()

func create_initial_grid():
	create_tile(0, 0, "core")
	create_tile(0, 1)
	create_tile(0, -1)
	create_tile(1, 0)
	create_tile(-1, 0)

	# Ensure enough tiles for tests (e.g. 1,1 for placement, 2,2 for bench drop)
	# MainGame.gd loop adds -2..2 in both axis when buying.
	# But manual test might need specific tiles if not auto-generated.
	# Let's add a few more for robustness.
	for x in range(-2, 3):
		for y in range(-2, 3):
			create_tile(x, y)

func create_tile(x: int, y: int, type: String = "normal"):
	var key = get_tile_key(x, y)
	if tiles.has(key): return

	var tile = TILE_SCENE.instantiate()
	tile.setup(x, y, type)
	tile.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	add_child(tile)
	tiles[key] = tile

	tile.tile_clicked.connect(_on_tile_clicked)

func get_tile_key(x: int, y: int) -> String:
	return "%d,%d" % [x, y]

func place_unit(unit_key: String, x: int, y: int) -> bool:
	var key = get_tile_key(x, y)
	if !tiles.has(key): return false

	var tile = tiles[key]
	if tile.unit != null or tile.occupied_by != Vector2i.ZERO: return false # Occupied

	var unit = UNIT_SCENE.instantiate()
	unit.setup(unit_key)

	# Check size
	var w = unit.unit_data.size.x
	var h = unit.unit_data.size.y

	if !can_place_unit(x, y, w, h):
		unit.queue_free()
		return false

	add_child(unit)
	unit.position = tile.position + Vector2((w-1) * TILE_SIZE * 0.5, (h-1) * TILE_SIZE * 0.5)

	unit.grid_pos = Vector2i(x, y) # Set grid pos

	# Mark tiles as occupied
	_set_tiles_occupied(x, y, w, h, unit)

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

			# If checking for swap (exclude_unit is set), we are more permissive?
			# Actually, standard check:
			if tile.unit and tile.unit != exclude_unit: return false

			# Occupied by multi-tile unit
			if tile.occupied_by != Vector2i.ZERO:
				# If we are excluding a unit, we should also ignore occupancy from that unit
				if exclude_unit and tile.occupied_by == exclude_unit.grid_pos:
					continue
				return false
	return true

func _on_tile_clicked(tile):
	if GameManager.is_wave_active: return
	# Handling selection/movement logic would go here
	print("Clicked tile: ", tile.x, ",", tile.y)

# Drag and Drop Logic
func handle_unit_drop(unit) -> bool:
	# Calculate target grid coords
	var w = unit.unit_data.size.x
	var h = unit.unit_data.size.y

	var offset = Vector2((w-1) * TILE_SIZE * 0.5, (h-1) * TILE_SIZE * 0.5)
	var top_left_pos = unit.position - offset

	var grid_x = round(top_left_pos.x / TILE_SIZE)
	var grid_y = round(top_left_pos.y / TILE_SIZE)

	var target_tile_key = get_tile_key(grid_x, grid_y)
	if !tiles.has(target_tile_key):
		# Returning false indicates grid didn't handle it
		return false

	var target_tile = tiles[target_tile_key]
	var from_tile_key = get_tile_key(unit.grid_pos.x, unit.grid_pos.y)
	var from_tile = tiles[from_tile_key]

	if try_move_unit(unit, from_tile, target_tile):
		return true
	else:
		return false

func handle_bench_drop(ghost_unit, unit_key, bench_index) -> bool:
	# Calculate target grid coords from ghost position
	# Ghost position is center
	var unit_data = Constants.UNIT_TYPES[unit_key]
	var w = unit_data.size.x
	var h = unit_data.size.y

	var offset = Vector2((w-1) * TILE_SIZE * 0.5, (h-1) * TILE_SIZE * 0.5)
	# Ghost global position needs to be converted to local
	var local_pos = to_local(ghost_unit.global_position)
	var top_left_pos = local_pos - offset

	var grid_x = round(top_left_pos.x / TILE_SIZE)
	var grid_y = round(top_left_pos.y / TILE_SIZE)

	if place_unit(unit_key, grid_x, grid_y):
		if GameManager.main_game:
			GameManager.main_game.remove_from_bench(bench_index)
		return true

	return false

func try_move_unit(unit, from_tile, to_tile) -> bool:
	if unit == null or from_tile == null or to_tile == null: return false

	if from_tile == to_tile:
		# Dropped on same tile, technically a success (no move needed)
		unit.return_to_start()
		return true

	var x = to_tile.x
	var y = to_tile.y
	var w = unit.unit_data.size.x
	var h = unit.unit_data.size.y

	# Case 1: Empty Target
	if can_place_unit(x, y, w, h, unit):
		_move_unit_internal(unit, x, y)
		return true

	# Case 2: Target Occupied
	var target_unit = to_tile.unit
	if target_unit == null and to_tile.occupied_by != Vector2i.ZERO:
		var origin_key = get_tile_key(to_tile.occupied_by.x, to_tile.occupied_by.y)
		if tiles.has(origin_key):
			target_unit = tiles[origin_key].unit

	if target_unit == null: return false

	if target_unit == unit: return false

	# Merge
	if target_unit.type_key == unit.type_key:
		target_unit.merge_with(unit)
		_clear_tiles_occupied(unit.grid_pos.x, unit.grid_pos.y, w, h)
		unit.queue_free()
		return true

	# Devour
	if can_devour(target_unit, unit):
		target_unit.devour(unit)
		_clear_tiles_occupied(unit.grid_pos.x, unit.grid_pos.y, w, h)
		unit.queue_free()
		return true

	# Swap
	if can_swap(unit, target_unit):
		_perform_swap(unit, target_unit)
		return true

	return false

func _move_unit_internal(unit, new_x, new_y):
	var w = unit.unit_data.size.x
	var h = unit.unit_data.size.y

	# Clear old
	_clear_tiles_occupied(unit.grid_pos.x, unit.grid_pos.y, w, h)

	# Set new
	unit.grid_pos = Vector2i(new_x, new_y)
	_set_tiles_occupied(new_x, new_y, w, h, unit)

	# Update position visual
	var tile = tiles[get_tile_key(new_x, new_y)]
	unit.position = tile.position + Vector2((w-1) * TILE_SIZE * 0.5, (h-1) * TILE_SIZE * 0.5)
	unit.start_position = unit.position

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

	# Clear both
	_clear_tiles_occupied(pos_a.x, pos_a.y, size_a.x, size_a.y)
	_clear_tiles_occupied(pos_b.x, pos_b.y, size_b.x, size_b.y)

	# Place A at B's old pos
	unit_a.grid_pos = pos_b
	_set_tiles_occupied(pos_b.x, pos_b.y, size_a.x, size_a.y, unit_a)

	# Place B at A's old pos
	unit_b.grid_pos = pos_a
	_set_tiles_occupied(pos_a.x, pos_a.y, size_b.x, size_b.y, unit_b)

	# Update visuals
	var tile_for_a = tiles[get_tile_key(pos_b.x, pos_b.y)]
	unit_a.position = tile_for_a.position + Vector2((size_a.x-1) * TILE_SIZE * 0.5, (size_a.y-1) * TILE_SIZE * 0.5)
	unit_a.start_position = unit_a.position

	var tile_for_b = tiles[get_tile_key(pos_a.x, pos_a.y)]
	unit_b.position = tile_for_b.position + Vector2((size_b.x-1) * TILE_SIZE * 0.5, (size_b.y-1) * TILE_SIZE * 0.5)
	unit_b.start_position = unit_b.position
