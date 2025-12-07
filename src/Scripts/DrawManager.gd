extends Node2D

var is_drawing: bool = false
var start_pos: Vector2
var current_material: String = ""

@onready var preview_line = $PreviewLine
@onready var barricade_scene = preload("res://src/Scenes/Game/Barricade.tscn")

func _ready():
	preview_line.visible = false
	# Ensure preview line doesn't block mouse input
	preview_line.top_level = true
	# Actually Line2D doesn't block input unless it has a control parent or something, but good to be safe.

func _unhandled_input(event):
	if current_material == "":
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_draw(get_global_mouse_position())
			else:
				_end_draw(get_global_mouse_position())

	elif event is InputEventMouseMotion and is_drawing:
		_update_draw(get_global_mouse_position())

func select_material(mat_key: String):
	if GameManager.materials.has(mat_key):
		current_material = mat_key
		print("Selected material: ", mat_key)
	else:
		push_warning("Material not found: " + mat_key)
		current_material = ""

func _start_draw(pos: Vector2):
	if current_material == "":
		return

	if GameManager.materials[current_material] <= 0:
		print("Not enough material: ", current_material)
		return

	is_drawing = true
	start_pos = pos
	preview_line.points = [pos, pos]
	preview_line.visible = true

	var mat_info = Constants.MATERIAL_TYPES[current_material]
	if mat_info:
		preview_line.default_color = mat_info.color

	var bar_info = Constants.BARRICADE_TYPES[current_material]
	if bar_info:
		preview_line.width = bar_info.width

func _update_draw(pos: Vector2):
	if is_drawing:
		preview_line.set_point_position(1, pos)

func _end_draw(pos: Vector2):
	if not is_drawing:
		return

	is_drawing = false
	preview_line.visible = false

	var dist = start_pos.distance_to(pos)
	if dist < 20:
		print("Wall too short")
		return

	var cost = ceil(dist / 10.0)

	if GameManager.materials[current_material] >= cost:
		GameManager.materials[current_material] -= cost
		GameManager.resource_changed.emit()
		_spawn_barricade(start_pos, pos, current_material)
		print("Built wall. Cost: ", cost)
	else:
		print("Not enough materials for this length. Cost: ", cost, " Available: ", GameManager.materials[current_material])

func _spawn_barricade(p1: Vector2, p2: Vector2, mat_key: String):
	var barricade = barricade_scene.instantiate()
	# Add to scene first so ready is called if needed, or call init after.
	# Barricade logic uses global coordinates, so we add it to the game world.
	# Assuming DrawManager is child of MainGame (Node2D), we can add child here or to parent.
	# Ideally add to parent so it's not deleted if DrawManager is removed (though DrawManager is likely permanent).
	# Requirements say "instantiate Barricade to scene".
	get_parent().add_child(barricade)
	barricade.init(p1, p2, mat_key)
