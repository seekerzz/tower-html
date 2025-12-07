extends Node2D

const TILE_SCENE = preload("res://src/Scenes/Game/Tile.tscn")
const UNIT_SCENE = preload("res://src/Scenes/Game/Unit.tscn")
const TILE_SIZE = 60

var tiles: Dictionary = {} # Key: "x,y", Value: Tile Instance
var selected_unit = null
var bench_units: Array = [null, null, null, null, null] # Max 5

func _ready():
	GameManager.grid_manager = self
	create_initial_grid()

func try_add_to_bench(unit_key: String) -> bool:
	var index = -1
	for i in range(bench_units.size()):
		if bench_units[i] == null:
			index = i
			break

	if index == -1:
		return false # Bench full

	var unit = UNIT_SCENE.instantiate()
	unit.setup(unit_key)

	# We need to add the unit to the scene tree so it can be seen.
	# Since MainGUI is a CanvasLayer, and we want unit on top of UI?
	# Or unit is typically Node2D in World.
	# If we add it to GridManager, it will be behind UI if UI has background.
	# But MainGUI bench slots are just panels.
	# We will add it to MainGUI's bench container? No, Unit is Node2D.
	# Let's add it to GridManager but position it using MainGUI coordinates.
	# And we might need to adjust Z-index or CanvasLayer.

	# Better: Add to GameManager.ui_manager (MainGUI) if possible, but Unit is Node2D.
	# Node2D child of Control is valid.
	if GameManager.ui_manager:
		GameManager.ui_manager.add_child(unit)
		unit.is_in_bench = true
		unit.bench_index = index
		bench_units[index] = unit
		_update_bench_unit_position(unit)
		return true

	unit.queue_free()
	return false

func _update_bench_unit_position(unit):
	if GameManager.ui_manager and unit.is_in_bench:
		var pos = GameManager.ui_manager.get_bench_slot_global_position(unit.bench_index)
		# Since unit is child of MainGUI (Control), and pos is global...
		# MainGUI is usually at (0,0) so global == local?
		# Actually, get_bench_slot_global_position returns global canvas position.
		# If MainGUI is moved, we need to adjust.
		# But Unit is Node2D inside Control. It uses position relative to parent.
		# If MainGUI is parent, we should use local position relative to MainGUI.

		# Let's convert global pos to local pos of MainGUI
		unit.position = GameManager.ui_manager.get_global_transform().affine_inverse() * pos
		# Unit visual is centered.

func remove_from_bench(unit):
	if unit.is_in_bench and unit.bench_index != -1:
		bench_units[unit.bench_index] = null
		unit.is_in_bench = false
		unit.bench_index = -1
		# Reparent to GridManager so it behaves like a normal unit
		unit.reparent(self)

func move_in_bench(unit, target_index):
	if target_index < 0 or target_index >= bench_units.size():
		unit.return_to_start()
		return

	var target_unit = bench_units[target_index]
	var old_index = unit.bench_index

	if target_unit == null:
		# Move to empty slot
		bench_units[old_index] = null
		bench_units[target_index] = unit
		unit.bench_index = target_index
		_update_bench_unit_position(unit)
		unit.start_position = unit.position
	else:
		# Swap
		bench_units[old_index] = target_unit
		bench_units[target_index] = unit

		unit.bench_index = target_index
		target_unit.bench_index = old_index

		_update_bench_unit_position(unit)
		_update_bench_unit_position(target_unit)

		unit.start_position = unit.position
		target_unit.start_position = target_unit.position

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
func handle_unit_drop(unit):
	# Calculate target grid coords
	# Unit position is local to GridManager
	# However, if unit was in bench, its position is in UI local space (which is likely different or offset)
	# But wait, when dragging, Unit is usually moved using `global_position`
	# And `unit.position` is just `global_position` relative to parent.
	# The drop logic uses `unit.position`.

	# If unit is in Bench, it is child of MainGUI.
	# GridManager is Node2D at some position.
	# We should use global position to determine drop target.

	var w = unit.unit_data.size.x
	var h = unit.unit_data.size.y

	var global_pos = unit.global_position
	var local_pos_in_grid = to_local(global_pos)

	var offset = Vector2((w-1) * TILE_SIZE * 0.5, (h-1) * TILE_SIZE * 0.5)
	var top_left_pos = local_pos_in_grid - offset

	var grid_x = round(top_left_pos.x / TILE_SIZE)
	var grid_y = round(top_left_pos.y / TILE_SIZE)

	var target_tile_key = get_tile_key(grid_x, grid_y)

	# If dragging from Bench
	if unit.is_in_bench:
		if !tiles.has(target_tile_key):
			unit.return_to_start()
			return

		# Check if we can place/merge/swap
		# Since it's from bench, it's essentially an "insert" or "swap with board unit"
		# Simplified: Try to place. If occupied by same type, merge. If occupied by diff type, swap (if space on bench).

		var target_tile = tiles[target_tile_key]

		if can_place_unit(grid_x, grid_y, w, h, null):
			# Place
			remove_from_bench(unit) # Reparents to GridManager
			unit.grid_pos = Vector2i(grid_x, grid_y)
			_set_tiles_occupied(grid_x, grid_y, w, h, unit)

			# Snap visual
			unit.position = target_tile.position + offset
			unit.start_position = unit.position
			return

		# Else check occupancy
		var target_unit = target_tile.unit
		if target_unit == null and target_tile.occupied_by != Vector2i.ZERO:
			var origin_key = get_tile_key(target_tile.occupied_by.x, target_tile.occupied_by.y)
			if tiles.has(origin_key):
				target_unit = tiles[origin_key].unit

		if target_unit:
			# Merge
			if target_unit.type_key == unit.type_key:
				target_unit.merge_with(unit)
				remove_from_bench(unit)
				unit.queue_free() # Destroy bench unit
				return

			# Swap (Bench <-> Grid)
			# Put target_unit into bench slot of 'unit'
			# Put 'unit' into grid
			# Only if target_unit is not "Core" or immovable (usually just check type)

			var bench_idx = unit.bench_index
			remove_from_bench(unit) # unit becomes normal, bench slot empty

			# Remove target from grid
			var t_pos = target_unit.grid_pos
			var t_w = target_unit.unit_data.size.x
			var t_h = target_unit.unit_data.size.y
			_clear_tiles_occupied(t_pos.x, t_pos.y, t_w, t_h)

			# Place unit in grid
			unit.grid_pos = t_pos
			_set_tiles_occupied(t_pos.x, t_pos.y, w, h, unit)
			unit.position = tiles[get_tile_key(t_pos.x, t_pos.y)].position + offset
			unit.start_position = unit.position

			# Place target_unit in bench
			target_unit.reparent(GameManager.ui_manager)
			target_unit.is_in_bench = true
			target_unit.bench_index = bench_idx
			bench_units[bench_idx] = target_unit
			_update_bench_unit_position(target_unit)
			target_unit.start_position = target_unit.position
			return

		unit.return_to_start()
		return

	# From Grid to Grid logic (existing)
	if !tiles.has(target_tile_key):
		unit.return_to_start()
		return

	var target_tile = tiles[target_tile_key]
	var from_tile_key = get_tile_key(unit.grid_pos.x, unit.grid_pos.y)
	var from_tile = tiles[from_tile_key] # Should exist

	if try_move_unit(unit, from_tile, target_tile):
		# Success
		pass
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
		return true

	# Devour
	# If target can devour source
	if can_devour(target_unit, unit):
		target_unit.devour(unit)
		_clear_tiles_occupied(unit.grid_pos.x, unit.grid_pos.y, w, h)
		unit.queue_free()
		return true

	# Swap
	# Only if both are movable and fit
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
