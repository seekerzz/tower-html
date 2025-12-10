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
	ghost_tile.position = Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE)
	ghost_tile.visible = true

	if _check_validity(grid_pos):
		ghost_tile.color = Color(0, 1, 0, 0.5)
	else:
		ghost_tile.color = Color(1, 0, 0, 0.5)

func _world_to_grid(pos: Vector2) -> Vector2i:
	return Vector2i(round(pos.x / TILE_SIZE), round(pos.y / TILE_SIZE))

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
	get_parent().add_child(barricade)

	# Set position
	barricade.position = Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE)

	barricade.init(grid_pos, mat_key)

	GameManager.grid_manager.register_obstacle(grid_pos, barricade)
