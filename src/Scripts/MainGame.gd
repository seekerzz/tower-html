extends Node2D

@onready var grid_manager = $GridManager
@onready var combat_manager = $CombatManager
@onready var shop = $CanvasLayer/Shop
@onready var bench_ui = find_child("Bench", true, false)
@onready var main_gui = $CanvasLayer/MainGUI
@onready var camera = $Camera2D

# Bench
var bench: Array = [] # Array of Dictionary (Unit Data) or null

# Camera Control
var zoom_target: Vector2 = Vector2(0.8, 0.8)
var zoom_tween: Tween
var default_zoom: Vector2 = Vector2(0.8, 0.8)
var default_position: Vector2 = Vector2(640, 400)

const AssetGenerator = preload("res://src/Scripts/Utils/AssetGenerator.gd")

func _ready():
	# Ensure assets exist before anything else tries to load them
	# Ideally this should be an Autoload, but MainGame is the entry point for now.
	AssetGenerator.ensure_assets_exist()

	# Set Background Texture
	if has_node("Background"):
		$Background.texture = AssetGenerator.get_bg_battle()

	# Initialize bench array with nulls based on constant
	bench.resize(Constants.BENCH_SIZE)
	bench.fill(null)

	GameManager.ui_manager = main_gui
	GameManager.main_game = self

	GameManager.wave_started.connect(_on_wave_started)
	GameManager.wave_ended.connect(_on_wave_ended)

	# Camera Setup
	# camera.zoom = default_zoom
	# camera.position = default_position
	# Initial camera position will be set by zoom_to_fit_board later or we call it now to verify
	call_deferred("zoom_to_shop_open")

	# Connect Shop signals
	# shop.unit_bought.connect(_on_unit_bought) # Now handled via add_to_bench in Shop

	# Initial Setup
	grid_manager.place_unit("squirrel", 0, 1) # Starting unit
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

func zoom_to_fit_board():
	# Shop Closed (Combat)
	var map_width = Constants.MAP_WIDTH * Constants.TILE_SIZE
	var map_height = Constants.MAP_HEIGHT * Constants.TILE_SIZE

	var viewport_size = get_viewport_rect().size

	# Calculate zoom to fit map with 5% margin
	var zoom_x = viewport_size.x / (map_width * 1.05)
	var zoom_y = viewport_size.y / (map_height * 1.05)
	var final_zoom = min(zoom_x, zoom_y)

	var target_zoom = Vector2(final_zoom, final_zoom)

	# Center of board is GridManager's position
	var target_pos = grid_manager.position

	print("Combat Zoom: ", target_zoom, " Target Pos: ", target_pos)

	if zoom_tween and zoom_tween.is_valid():
		zoom_tween.kill()

	zoom_tween = create_tween()
	zoom_tween.set_parallel(true)
	zoom_tween.tween_property(camera, "zoom", target_zoom, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	zoom_tween.tween_property(camera, "position", target_pos, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func zoom_to_shop_open():
	# Shop Open (Planning)
	var map_width = Constants.MAP_WIDTH * Constants.TILE_SIZE
	var map_height = Constants.MAP_HEIGHT * Constants.TILE_SIZE

	# Updated Shop Height: ~160px (per feedback to fit bench)
	# We use 180px to be safe with margins
	var SHOP_HEIGHT = 180
	var viewport_size = get_viewport_rect().size
	var visible_height = viewport_size.y - SHOP_HEIGHT

	# Calculate Zoom to fit visible_height area (with margin)
	var zoom_x = viewport_size.x / (map_width * 1.05)
	var zoom_y = visible_height / (map_height * 1.05)
	var final_zoom = min(zoom_x, zoom_y)

	var target_zoom = Vector2(final_zoom, final_zoom)

	# Calculate Camera Offset
	# We want the map center to be at the center of the available visible area (above shop)
	# Map center is at (0,0) in our camera world if grid_manager is centered?
	# GridManager position is center of grid.

	# The visible area center in screen coordinates is:
	# X: viewport_size.x / 2
	# Y: visible_height / 2

	# The full viewport center is:
	# Y: viewport_size.y / 2

	# The offset from center of screen we want to shift the camera:
	var screen_center_y = viewport_size.y / 2.0
	var visible_center_y = visible_height / 2.0
	var shift_y = screen_center_y - visible_center_y

	# Since camera position is where the center of the screen points to in world space.
	# If we want the map center (grid_manager.position) to appear at visible_center_y,
	# we need to move the camera DOWN (positive Y) so the map moves UP relative to center.

	var target_pos = grid_manager.position
	target_pos.y += shift_y / final_zoom

	print("Shop Zoom: ", target_zoom, " Target Pos: ", target_pos)

	if zoom_tween and zoom_tween.is_valid():
		zoom_tween.kill()

	zoom_tween = create_tween()
	zoom_tween.set_parallel(true)
	zoom_tween.tween_property(camera, "zoom", target_zoom, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	zoom_tween.tween_property(camera, "position", target_pos, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_wave_started():
	zoom_to_fit_board()

func _on_wave_ended():
	zoom_to_shop_open()

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
