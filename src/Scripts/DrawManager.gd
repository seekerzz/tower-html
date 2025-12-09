extends Node2D

var current_material: String = ""
var ghost_tile: ColorRect
const TILE_SIZE = 60
const BUILD_COST = 10

@onready var barricade_scene = preload("res://src/Scenes/Game/Barricade.tscn")

func _ready():
	_create_ghost_tile()

func _create_ghost_tile():
	ghost_tile = ColorRect.new()
	ghost_tile.size = Vector2(TILE_SIZE, TILE_SIZE)
	ghost_tile.color = Color(0, 1, 0, 0.5) # Green semi-transparent
	ghost_tile.visible = false
	ghost_tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ghost_tile)

func _unhandled_input(event):
	var global_pos = event.global_position if "global_position" in event else get_global_mouse_position()

	if event is InputEventMouseMotion:
		_update_ghost(global_pos)

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_click(global_pos)

func select_material(mat_key: String):
	if GameManager.materials.has(mat_key):
		current_material = mat_key
		print("Selected material: ", mat_key)
		_update_ghost(get_global_mouse_position())
	else:
		push_warning("Material not found: " + mat_key)
		current_material = ""
		_update_ghost(get_global_mouse_position())

func _get_grid_pos(global_mouse_pos: Vector2) -> Vector2i:
	var local_pos = GameManager.grid_manager.to_local(global_mouse_pos)
	return Vector2i(round(local_pos.x / TILE_SIZE), round(local_pos.y / TILE_SIZE))

func _update_ghost(global_mouse_pos: Vector2):
	var grid_pos = _get_grid_pos(global_mouse_pos)

	# Determine state to set color/visibility
	# If no material selected, maybe still show ghost for unlock?
	# Task says "Ghost Tile: Let semi-transparent square align perfectly..."
	# I will show ghost if we can interact.

	var is_locked = GameManager.grid_manager.is_core_locked(grid_pos)
	var is_in_core = GameManager.grid_manager.is_in_core_zone(grid_pos)
	var can_build = current_material != "" and not is_in_core and not is_locked

	if can_build:
		ghost_tile.visible = true
		if _check_build_validity(grid_pos):
			ghost_tile.color = Color(0, 1, 0, 0.5) # Green
		else:
			ghost_tile.color = Color(1, 0, 0, 0.5) # Red
	elif is_locked:
		ghost_tile.visible = true
		# Check gold for unlock
		if GameManager.gold >= GameManager.grid_manager.expansion_cost:
			ghost_tile.color = Color(1, 1, 0, 0.5) # Yellow for unlock
		else:
			ghost_tile.color = Color(1, 0, 0, 0.5) # Red
	elif is_in_core:
		ghost_tile.visible = true
		ghost_tile.color = Color(1, 0, 0, 0.5) # Red (Forbidden)
	else:
		# Unknown state or wilderness with no material
		ghost_tile.visible = false

	# Align ghost tile
	# Calculate center of grid in GridManager local space
	var center_local = Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE)
	# Convert to global
	var center_global = GameManager.grid_manager.to_global(center_local)
	# Set ghost position (top-left)
	ghost_tile.global_position = center_global - ghost_tile.size / 2.0

func _check_build_validity(grid_pos: Vector2i) -> bool:
	if current_material == "": return false

	# 1. Check Core Zone or Locked
	if GameManager.grid_manager.is_in_core_zone(grid_pos): return false
	if GameManager.grid_manager.is_core_locked(grid_pos): return false

	# 2. Check Resources
	if GameManager.materials[current_material] < BUILD_COST:
		return false

	# 3. Check Obstacles
	if GameManager.grid_manager.obstacles.has(grid_pos):
		return false

	return true

func _handle_click(global_pos: Vector2):
	var grid_pos = _get_grid_pos(global_pos)

	if GameManager.grid_manager.is_in_core_zone(grid_pos):
		# Core unlocked: Forbid building
		print("Cannot build in core zone")
		return

	if GameManager.grid_manager.is_core_locked(grid_pos):
		# Core locked: Unlock
		GameManager.grid_manager.unlock_core_tile(grid_pos)
		_update_ghost(global_pos) # Update visual state
		return

	# Wilderness: Build
	_try_build(grid_pos)

func _try_build(grid_pos_or_global):
	# Support both for compatibility if needed, but I should switch to grid_pos mostly.
	# But existing code might call _try_build with global (like my test script).
	var grid_pos
	if grid_pos_or_global is Vector2:
		grid_pos = _get_grid_pos(grid_pos_or_global)
	else:
		grid_pos = grid_pos_or_global

	if not _check_build_validity(grid_pos):
		print("Invalid build location or insufficient resources")
		return

	GameManager.materials[current_material] -= BUILD_COST
	GameManager.resource_changed.emit()

	_spawn_barricade(grid_pos, current_material)
	print("Built barricade at ", grid_pos)

func _spawn_barricade(grid_pos: Vector2i, mat_key: String):
	var barricade = barricade_scene.instantiate()

	# Instantiate Barricade (as a child of GridManager)
	GameManager.grid_manager.add_child(barricade)

	# Set position (GridManager local)
	barricade.position = Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE)

	barricade.init(grid_pos, mat_key)

	GameManager.grid_manager.register_obstacle(grid_pos, barricade)
