extends Node2D

var current_material: String = ""
var ghost_sprite: ColorRect
var is_dragging: bool = false
const TILE_SIZE = 60

@onready var barricade_scene = preload("res://src/Scenes/Game/Barricade.tscn")

func _ready():
	_create_ghost()
	# Ghost starts hidden
	ghost_sprite.visible = false

func _create_ghost():
	ghost_sprite = ColorRect.new()
	ghost_sprite.size = Vector2(50, 50)
	ghost_sprite.position = Vector2(-25, -25) # Centered relative to its parent
	ghost_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Ensure ghost is on top of everything
	ghost_sprite.z_index = 100
	add_child(ghost_sprite)

func _unhandled_input(event):
	if current_material == "":
		ghost_sprite.visible = false
		return

	if event is InputEventMouseMotion:
		_update_ghost()
		if is_dragging:
			_try_build()

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				_try_build()
			else:
				is_dragging = false

func select_material(mat_key: String):
	if GameManager.materials.has(mat_key):
		current_material = mat_key
		print("Selected material: ", mat_key)
		_update_ghost()
	else:
		push_warning("Material not found: " + mat_key)
		current_material = ""
		ghost_sprite.visible = false

func _update_ghost():
	if current_material == "":
		ghost_sprite.visible = false
		return

	ghost_sprite.visible = true
	var mouse_pos = get_global_mouse_position()
	var grid_pos = _world_to_grid(mouse_pos)

	# Snap ghost to grid center
	ghost_sprite.global_position = Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE) - ghost_sprite.size / 2

	# Check validity for color
	var valid = _is_valid_build_pos(grid_pos)

	if valid:
		ghost_sprite.color = Color(0, 1, 0, 0.5) # Green
	else:
		ghost_sprite.color = Color(1, 0, 0, 0.5) # Red

func _try_build():
	if current_material == "": return

	var mouse_pos = get_global_mouse_position()
	var grid_pos = _world_to_grid(mouse_pos)

	if _is_valid_build_pos(grid_pos):
		# Additional check: Cost
		# Default cost 1 for now, as per original logic which was distance based.
		# But usually block build is 1 per block.
		var cost = 1

		if GameManager.materials[current_material] >= cost:
			GameManager.materials[current_material] -= cost
			GameManager.resource_changed.emit()
			_spawn_barricade(grid_pos, current_material)
			# print("Built barricade at ", grid_pos)
		else:
			# print("Not enough resources")
			pass

func _is_valid_build_pos(grid_pos: Vector2i) -> bool:
	# 1. Check core zone
	if GameManager.grid_manager.is_in_core_zone(grid_pos):
		return false

	# 2. Check if tile exists (we can only build on existing tiles?)
	# The requirements don't explicitly say we must build on tiles, but usually yes.
	# GridManager stores tiles.
	var key = GameManager.grid_manager.get_tile_key(grid_pos.x, grid_pos.y)
	if not GameManager.grid_manager.tiles.has(key):
		return false

	# 3. Check if already occupied by barricade or unit
	var tile = GameManager.grid_manager.tiles[key]
	# If tile.unit is set, it's occupied.
	if tile.unit != null:
		return false
	# We also need to check if there is already a barricade there.
	# Since we haven't implemented 'barricade' property in Tile, and we might not want to rely on 'unit' property collision.
	# We can use a group or check overlaps, but checking GridManager state is cleaner.
	# In `register_obstacle`, we should mark it.
	# If I use `tile.occupied_by` for multi-tile units, I should check that too.
	if tile.occupied_by != Vector2i.ZERO:
		return false

	# Special check: Is there ALREADY a barricade we just built?
	# If we just built one, we shouldn't build another on top.
	# We can check if `tile.has_meta("barricade")` if we use metadata.
	if tile.has_meta("barricade"):
		return false

	return true

func _spawn_barricade(grid_pos: Vector2i, mat_key: String):
	var barricade = barricade_scene.instantiate()
	var world_pos = Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE)

	# Add to main scene (or parent of DrawManager)
	get_parent().add_child(barricade)
	barricade.init(world_pos, mat_key)

	# Register with GridManager
	GameManager.grid_manager.register_obstacle(grid_pos, barricade)

	# Mark tile as having barricade to prevent duplicate build
	var key = GameManager.grid_manager.get_tile_key(grid_pos.x, grid_pos.y)
	if GameManager.grid_manager.tiles.has(key):
		var tile = GameManager.grid_manager.tiles[key]
		tile.set_meta("barricade", barricade)

func _world_to_grid(pos: Vector2) -> Vector2i:
	return Vector2i(round(pos.x / TILE_SIZE), round(pos.y / TILE_SIZE))
