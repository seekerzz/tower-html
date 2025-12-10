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
	if current_material == "":
		ghost_tile.visible = false
		return

	if event is InputEventMouseMotion:
		_update_ghost(event.global_position if "global_position" in event else get_global_mouse_position())

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_try_build(event.global_position if "global_position" in event else get_global_mouse_position())

func select_material(mat_key: String):
	if GameManager.materials.has(mat_key):
		current_material = mat_key
		print("Selected material: ", mat_key)
		_update_ghost(get_global_mouse_position())
	else:
		push_warning("Material not found: " + mat_key)
		current_material = ""
		ghost_tile.visible = false

func _update_ghost(mouse_pos: Vector2):
	var grid_pos = _world_to_grid(mouse_pos)
	var local_pos = Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE)
	var global_center = GameManager.grid_manager.to_global(local_pos)

	ghost_tile.position = global_center - Vector2(TILE_SIZE/2.0, TILE_SIZE/2.0)
	ghost_tile.visible = true

	if _check_validity(grid_pos):
		ghost_tile.color = Color(0, 1, 0, 0.5)
	else:
		ghost_tile.color = Color(1, 0, 0, 0.5)

func _world_to_grid(pos: Vector2) -> Vector2i:
	var local_pos = GameManager.grid_manager.to_local(pos)
	return Vector2i(round(local_pos.x / TILE_SIZE), round(local_pos.y / TILE_SIZE))

func _check_validity(grid_pos: Vector2i) -> bool:
	# 1. Check Core Zone
	if GameManager.grid_manager.is_in_core_zone(grid_pos):
		return false

	# 2. Check Resources
	if GameManager.materials[current_material] < BUILD_COST:
		return false

	# 3. Check Obstacles
	# GridManager.register_obstacle stores in 'obstacles'
	if GameManager.grid_manager.obstacles.has(grid_pos):
		return false

	# 4. Check Path Blocking (Anti-Block)
	var mat_data = Constants.BARRICADE_TYPES.get(current_material, {})
	if mat_data.get("is_solid", false):
		# Temporarily block
		var was_solid = GameManager.grid_manager.astar_grid.is_point_solid(grid_pos)
		GameManager.grid_manager.astar_grid.set_point_solid(grid_pos, true)

		var blocked = false
		var spawn_points = GameManager.grid_manager.get_spawn_points()
		var core_pos = Vector2i(0, 0) # Core is always at 0,0

		for spawn in spawn_points:
			var spawn_grid = GameManager.grid_manager._world_to_grid_pos(spawn)
			var path = GameManager.grid_manager.astar_grid.get_id_path(spawn_grid, core_pos)
			if path.is_empty():
				blocked = true
				break

		# Restore
		GameManager.grid_manager.astar_grid.set_point_solid(grid_pos, was_solid)

		if blocked:
			# print("Cannot block path!")
			return false

	return true

func _try_build(mouse_pos: Vector2):
	var grid_pos = _world_to_grid(mouse_pos)

	if not _check_validity(grid_pos):
		print("Invalid build location or insufficient resources")
		return

	GameManager.materials[current_material] -= BUILD_COST
	GameManager.resource_changed.emit()

	_spawn_barricade(grid_pos, current_material)
	print("Built barricade at ", grid_pos)

func _spawn_barricade(grid_pos: Vector2i, mat_key: String):
	var barricade = barricade_scene.instantiate()

	# Placement logic
	# GridManager uses x*TILE_SIZE, y*TILE_SIZE as center usually if we use round()
	# Barricade is a StaticBody2D.
	# Barricade.init expects grid_pos.

	# Add to parent
	GameManager.grid_manager.add_child(barricade)

	# Set position
	barricade.position = Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE)

	barricade.init(grid_pos, mat_key)

	GameManager.grid_manager.register_obstacle(grid_pos, barricade)
