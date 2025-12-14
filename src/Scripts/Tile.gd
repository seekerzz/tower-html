extends Node2D

var x: int
var y: int
var type: String = "normal"
var state: String = "locked_inner" # unlocked, locked_inner, locked_outer, spawn
var unit = null
var occupied_by: Vector2i
var _random_frame: int = 0

signal tile_clicked(tile)

const DROP_HANDLER_SCRIPT = preload("res://src/Scripts/UI/TileDropHandler.gd")
# We load textures dynamically to allow for safe fallback if missing
const AssetGenerator = preload("res://src/Scripts/Utils/AssetGenerator.gd")

var tile_sheet_texture: Texture2D
var tile_spawn_texture: Texture2D

func _ready():
	# Fallback/Lazy load if not already loaded (e.g. if instanced manually without setup)
	if not tile_sheet_texture:
		_load_textures()

func _load_textures():
	if ResourceLoader.exists("res://src/assets/images/UI/tile_sheet.png"):
		tile_sheet_texture = load("res://src/assets/images/UI/tile_sheet.png")
	else:
		tile_sheet_texture = AssetGenerator.get_tile_sheet()

	if ResourceLoader.exists("res://src/assets/images/UI/tile_spawn.png"):
		tile_spawn_texture = load("res://src/assets/images/UI/tile_spawn.png")
	else:
		tile_spawn_texture = AssetGenerator.get_spawn_texture()

func setup(grid_x: int, grid_y: int, tile_type: String = "normal"):
	x = grid_x
	y = grid_y
	type = tile_type

	if not tile_sheet_texture:
		_load_textures()

	# Setup Sprite
	var sprite = $BaseSprite
	sprite.texture = tile_sheet_texture
	sprite.hframes = 5
	sprite.vframes = 5

	# Randomize frame once
	_random_frame = randi() % 25
	sprite.frame = _random_frame

	update_visuals()

	# Add Drop Target
	var drop_target = Control.new()
	drop_target.set_script(DROP_HANDLER_SCRIPT)
	add_child(drop_target)
	drop_target.setup(self)

func set_state(new_state: String):
	state = new_state
	update_visuals()

func update_visuals():
	if !has_node("BaseSprite"): return
	var sprite = $BaseSprite

	if not tile_sheet_texture:
		_load_textures()

	# Reset defaults
	sprite.texture = tile_sheet_texture
	sprite.hframes = 5
	sprite.vframes = 5
	sprite.frame = _random_frame
	sprite.modulate = Color.WHITE

	if state == "unlocked":
		sprite.modulate = Color.WHITE
	elif state == "locked_inner":
		sprite.modulate = Color(0.2, 0.2, 0.2)
	elif state == "locked_outer":
		sprite.modulate = Color(0.1, 0.1, 0.1)
	elif state == "spawn":
		sprite.texture = tile_spawn_texture
		sprite.hframes = 1
		sprite.vframes = 1
		sprite.frame = 0
		sprite.modulate = Color.WHITE

	if type == "core":
		# Optional: distinct color for core
		sprite.modulate = Color(0.6, 0.6, 1.0)
		if has_node("Label"):
			$Label.text = "Core"
	else:
		if has_node("Label"):
			$Label.text = ""

func set_grid_visible(active: bool):
	if has_node("GridBorder"):
		$GridBorder.visible = active

func set_highlight(active: bool):
	if !has_node("BaseSprite"): return
	var sprite = $BaseSprite

	if active:
		# Lighten the current modulate
		var current = sprite.modulate
		create_tween().tween_property(sprite, "modulate", current.lightened(0.2), 0.1)
	else:
		# Restore original state visuals
		update_visuals()

func _on_area_2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tile_clicked.emit(self)

func _on_area_2d_mouse_entered():
	if !GameManager.is_wave_active:
		set_highlight(true)

func _on_area_2d_mouse_exited():
	set_highlight(false)
