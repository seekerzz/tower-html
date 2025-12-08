extends Node2D

const TILE_SCENE = preload("res://src/Scenes/Game/Tile.tscn")
const UNIT_SCENE = preload("res://src/Scenes/Game/Unit.tscn")
const TILE_SIZE = 60

var tiles: Dictionary = {} # Key: "x,y", Value: Tile Instance
var ghost_tiles: Dictionary = {} # Key: "x,y", Value: Tile Instance
var is_expansion_mode: bool = false
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

	recalculate_buffs()
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
	if is_expansion_mode:
		if tile.type == "ghost":
			if GameManager.spend_gold(GameManager.tile_cost):
				# Convert ghost to real
				var x = tile.x
				var y = tile.y

				# Remove ghost
				var key = get_tile_key(x, y)
				if ghost_tiles.has(key):
					ghost_tiles.erase(key)
				tile.queue_free()

				# Create real
				create_tile(x, y, "normal")

				# Refresh ghosts
				clear_ghost_tiles()
				show_ghost_tiles()
		return

	if GameManager.is_wave_active: return
	# Handling selection/movement logic would go here
	print("Clicked tile: ", tile.x, ",", tile.y)

# Drag and Drop Logic
func handle_unit_drop(unit):
	# Calculate target grid coords
	# Unit position is local to GridManager
	# The unit's position is its center.
	# To get the top-left tile coordinate, we need to adjust for size.

	var w = unit.unit_data.size.x
	var h = unit.unit_data.size.y

	var offset = Vector2((w-1) * TILE_SIZE * 0.5, (h-1) * TILE_SIZE * 0.5)
	var top_left_pos = unit.position - offset

	var grid_x = round(top_left_pos.x / TILE_SIZE)
	var grid_y = round(top_left_pos.y / TILE_SIZE)

	var target_tile_key = get_tile_key(grid_x, grid_y)
	if !tiles.has(target_tile_key):
		unit.return_to_start()
		return

	var target_tile = tiles[target_tile_key]
	var from_tile_key = get_tile_key(unit.grid_pos.x, unit.grid_pos.y)
	var from_tile = tiles[from_tile_key] # Should exist

	if try_move_unit(unit, from_tile, target_tile):
		recalculate_buffs()
	else:
		unit.return_to_start()

func try_move_unit(unit, from_tile, to_tile) -> bool:
	if unit == null or from_tile == null or to_tile == null: return false

	if from_tile == to_tile: return false

	var x = to_tile.x
	var y = to_tile.y
	var w = unit.unit_data.size.x
	var h = unit.unit_data.size.y

	# Case 1: Empty Target
	# Check if we can place unit there (ignoring itself)
	if can_place_unit(x, y, w, h, unit):
		_move_unit_internal(unit, x, y)
		recalculate_buffs()
		return true

	# Case 2: Target Occupied
	# Get the unit at target position
	# It might be `to_tile.unit` or `to_tile` might be `occupied_by` another unit.
	var target_unit = to_tile.unit
	if target_unit == null and to_tile.occupied_by != Vector2i.ZERO:
		# Find the origin of the unit occupying this tile
		var origin_key = get_tile_key(to_tile.occupied_by.x, to_tile.occupied_by.y)
		if tiles.has(origin_key):
			target_unit = tiles[origin_key].unit

	if target_unit == null: return false # Should have been caught by can_place_unit if truly empty or invalid

	if target_unit == unit: return false # Same unit

	# Merge
	if target_unit.type_key == unit.type_key:
		# Check if merge-able (usually check max level etc, but simplified here)
		target_unit.merge_with(unit)

		# Remove source unit
		_clear_tiles_occupied(unit.grid_pos.x, unit.grid_pos.y, w, h)
		unit.queue_free()
		recalculate_buffs()
		return true

	# Devour
	# If target can devour source
	if can_devour(target_unit, unit):
		target_unit.devour(unit)
		_clear_tiles_occupied(unit.grid_pos.x, unit.grid_pos.y, w, h)
		unit.queue_free()
		recalculate_buffs()
		return true

	# Swap
	# Only if both are movable and fit
	if can_swap(unit, target_unit):
		_perform_swap(unit, target_unit)
		recalculate_buffs()
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
	unit.start_position = unit.position # Update start pos for next drag

func can_devour(eater, food) -> bool:
	if food.unit_data.has("isFood") and food.unit_data.isFood:
		return true
	return false

func can_swap(unit_a, unit_b) -> bool:
	# Check if unit_a fits in unit_b's spot AND unit_b fits in unit_a's spot
	# ignoring each other.

	var pos_a = unit_a.grid_pos
	var size_a = unit_a.unit_data.size

	var pos_b = unit_b.grid_pos
	var size_b = unit_b.unit_data.size

	# To check accurately, we need to pretend both are removed, then check if they fit in swapped pos.
	# But `can_place_unit` only excludes ONE unit.
	# We need `can_place_unit` to exclude BOTH.

	# Temporary simpler check: if same size, always swap?
	if size_a == size_b: return true

	# If different sizes, it's complicated.
	# Let's try to verify A fits at B (excluding B) and B fits at A (excluding A).
	# BUT `can_place_unit(pos_b..., exclude=unit_a)` is wrong, because unit_a is at pos_a.
	# We want to place A at pos_b. We should exclude unit_b (currently at pos_b) from collision check.
	# AND we should exclude unit_a (because it's moving).

	# Actually, if we are swapping A and B:
	# Check A at pos_b, excluding B. (A is moving there, B is moving away).
	# Check B at pos_a, excluding A. (B is moving there, A is moving away).

	# However, if there are OTHER units overlapping?
	# `can_place_unit` checks against ALL tiles in the rect.

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

func recalculate_buffs():
	# 1. Clear all buffs
	var all_units = []
	for key in tiles:
		var tile = tiles[key]
		if tile.unit and not (tile.unit in all_units):
			all_units.append(tile.unit)
			tile.unit.active_buffs = []

	# 2. Find providers and apply buffs
	for unit in all_units:
		if unit.unit_data.has("buffProvider"):
			var buff_type = unit.unit_data.buffProvider
			var neighbors = get_neighboring_units(unit)
			for neighbor in neighbors:
				neighbor.active_buffs.append(buff_type)

	# 3. Recalculate stats
	for unit in all_units:
		unit.recalculate_stats()

func get_neighboring_units(unit):
	var neighbors = []
	var x = unit.grid_pos.x
	var y = unit.grid_pos.y
	var w = unit.unit_data.size.x
	var h = unit.unit_data.size.y

	# Up: (x to x+w-1, y-1)
	for dx in range(w):
		var n_key = get_tile_key(x + dx, y - 1)
		add_unit_from_tile_key(n_key, neighbors)

	# Down: (x to x+w-1, y+h)
	for dx in range(w):
		var n_key = get_tile_key(x + dx, y + h)
		add_unit_from_tile_key(n_key, neighbors)

	# Left: (x-1, y to y+h-1)
	for dy in range(h):
		var n_key = get_tile_key(x - 1, y + dy)
		add_unit_from_tile_key(n_key, neighbors)

	# Right: (x+w, y to y+h-1)
	for dy in range(h):
		var n_key = get_tile_key(x + w, y + dy)
		add_unit_from_tile_key(n_key, neighbors)

	return neighbors

func add_unit_from_tile_key(key, list):
	if tiles.has(key):
		var tile = tiles[key]
		var u = tile.unit
		# if tile has no unit directly, check if it is occupied by one
		if u == null and tile.occupied_by != Vector2i.ZERO:
			var origin_key = get_tile_key(tile.occupied_by.x, tile.occupied_by.y)
			if tiles.has(origin_key):
				u = tiles[origin_key].unit

		if u and not (u in list):
			list.append(u)

func toggle_expansion_mode():
	is_expansion_mode = !is_expansion_mode
	if is_expansion_mode:
		show_ghost_tiles()
	else:
		clear_ghost_tiles()

func show_ghost_tiles():
	# Find all empty spots adjacent to current grid
	var candidates = {} # "x,y" : true

	for key in tiles:
		var tile = tiles[key]
		var tx = tile.x
		var ty = tile.y

		var neighbors = [
			Vector2i(tx, ty-1),
			Vector2i(tx, ty+1),
			Vector2i(tx-1, ty),
			Vector2i(tx+1, ty)
		]

		for n in neighbors:
			var n_key = get_tile_key(n.x, n.y)
			if !tiles.has(n_key):
				candidates[n_key] = n

	for key in candidates:
		var pos = candidates[key]
		create_ghost_tile(pos.x, pos.y)

func create_ghost_tile(x, y):
	var key = get_tile_key(x, y)
	if ghost_tiles.has(key): return

	var tile = TILE_SCENE.instantiate()
	tile.setup(x, y, "ghost") # We need to handle this type in Tile.gd or here
	tile.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	tile.modulate = Color(1, 1, 1, 0.5) # Semi-transparent
	add_child(tile)
	ghost_tiles[key] = tile

	tile.tile_clicked.connect(_on_tile_clicked)

func clear_ghost_tiles():
	for key in ghost_tiles:
		ghost_tiles[key].queue_free()
	ghost_tiles.clear()
