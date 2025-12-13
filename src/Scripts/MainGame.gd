extends Node2D

@onready var grid_manager = $GridManager
@onready var combat_manager = $CombatManager
@onready var shop = $CanvasLayer/Shop
@onready var bench_ui = find_child("Bench", true, false)
@onready var main_gui = $CanvasLayer/MainGUI
@onready var camera = $Camera2D

# Bench
var bench: Array = [null, null, null, null, null] # Array of Dictionary (Unit Data) or null

# Camera Control
var zoom_target: Vector2 = Vector2(0.8, 0.8)
var zoom_tween: Tween

func _ready():
	GameManager.ui_manager = main_gui
	GameManager.main_game = self

	# Camera Setup
	camera.zoom = Vector2(0.8, 0.8)
	camera.position = Vector2(640, 400)

	# Connect Shop signals
	# shop.unit_bought.connect(_on_unit_bought) # Now handled via add_to_bench in Shop

	# Initial Setup
	grid_manager.place_unit("mouse", 0, 1) # Starting unit
	update_bench_ui() # Ensure UI is initialized

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if event.button_mask == MOUSE_BUTTON_MASK_RIGHT:
			camera.position -= event.relative / camera.zoom

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_adjust_zoom(0.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_adjust_zoom(-0.1)

func _adjust_zoom(amount: float):
	zoom_target += Vector2(amount, amount)
	zoom_target.x = clamp(zoom_target.x, 0.5, 1.2)
	zoom_target.y = clamp(zoom_target.y, 0.5, 1.2)

	if zoom_tween and zoom_tween.is_valid():
		zoom_tween.kill()

	zoom_tween = create_tween()
	zoom_tween.tween_property(camera, "zoom", zoom_target, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# Bench Logic
func add_to_bench(unit_key: String) -> bool:
	for i in range(bench.size()):
		if bench[i] == null:
			bench[i] = { "key": unit_key, "level": 1 } # Simplified data
			update_bench_ui()
			return true
	return false

func remove_from_bench(index: int):
	if index >= 0 and index < bench.size():
		bench[index] = null
		update_bench_ui()

func move_unit_from_grid_to_bench(unit_node, target_index: int):
	if target_index < 0 or target_index >= bench.size():
		return

	if bench[target_index] != null:
		# If target is occupied, we might want to swap or just fail.
		# For now, simplistic approach: fail if occupied.
		print("Bench slot occupied")
		return

	# Logic to move
	bench[target_index] = {
		"key": unit_node.type_key,
		"level": unit_node.level
	}

	# Remove from grid
	grid_manager.remove_unit_from_grid(unit_node)

	update_bench_ui()

func try_add_to_bench_from_grid(unit) -> bool:
	for i in range(bench.size()):
		if bench[i] == null:
			move_unit_from_grid_to_bench(unit, i)
			return true
	print("Bench Full")
	return false

func update_bench_ui():
	if bench_ui:
		bench_ui.update_bench_ui(bench)
