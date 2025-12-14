extends Node2D

var x: int
var y: int
var type: String = "normal"
var state: String = "locked_inner" # unlocked, locked_inner, locked_outer, spawn
var unit = null
var occupied_by: Vector2i

var tex_ground = preload("res://assets/images/UI/tile_ground.png")
var tex_spawn = preload("res://assets/images/UI/tile_spawn.png")

var rnd_frame_index: int = 0

signal tile_clicked(tile)

const DROP_HANDLER_SCRIPT = preload("res://src/Scripts/UI/TileDropHandler.gd")

func _ready():
	rnd_frame_index = randi() % 25

func setup(grid_x: int, grid_y: int, tile_type: String = "normal"):
	x = grid_x
	y = grid_y
	type = tile_type

	# Ensure setup uses the random frame if ready happened or not
	if rnd_frame_index == 0:
		rnd_frame_index = randi() % 25

	update_visuals()

	# Add Drop Target
	var drop_target = Control.new()
	drop_target.set_script(DROP_HANDLER_SCRIPT)
	add_child(drop_target)
	drop_target.setup(self)

func set_state(new_state: String):
	state = new_state
	update_visuals()

func set_grid_visible(is_visible: bool):
	if has_node("GridBorder"):
		$GridBorder.visible = is_visible

func update_visuals():
	if !has_node("BaseSprite"): return

	var sprite = $BaseSprite

	if type == "core":
		# Keep using ground for core for now, but ensure it is visible
		# Use frame 12 (center) for consistency maybe? or random is fine.
		sprite.texture = tex_ground
		sprite.hframes = 5
		sprite.vframes = 5
		sprite.frame = rnd_frame_index
		sprite.modulate = Color.WHITE
		if has_node("Label"):
			$Label.text = "Core"
		return

	if has_node("Label"):
		$Label.text = ""

	if state == "unlocked":
		sprite.texture = tex_ground
		sprite.hframes = 5
		sprite.vframes = 5
		sprite.frame = rnd_frame_index
		sprite.modulate = Color.WHITE
	elif state == "spawn":
		sprite.texture = tex_spawn
		sprite.hframes = 1
		sprite.vframes = 1
		sprite.frame = 0
		sprite.modulate = Color.WHITE
	elif state == "locked_inner" or state == "locked_outer":
		# Show darker ground or hide
		sprite.texture = tex_ground
		sprite.hframes = 5
		sprite.vframes = 5
		sprite.frame = rnd_frame_index
		sprite.modulate = Color(0.2, 0.2, 0.2)

func set_highlight(active: bool):
	if !has_node("BaseSprite"): return
	var sprite = $BaseSprite

	if active:
		sprite.modulate = sprite.modulate.lightened(0.2)
	else:
		update_visuals()

func _on_area_2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tile_clicked.emit(self)

func _on_area_2d_mouse_entered():
	# Check if GameManager exists and has property
	# Safely access GameManager
	var gm = get_node_or_null("/root/GameManager")
	if !gm or !gm.get("is_wave_active"):
		set_highlight(true)

func _on_area_2d_mouse_exited():
	set_highlight(false)
