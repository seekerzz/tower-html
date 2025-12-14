extends Node2D

var x: int
var y: int
var type: String = "normal"
var state: String = "locked_inner" # unlocked, locked_inner, locked_outer, spawn
var unit = null
var occupied_by: Vector2i

# Random frame index for sprite randomization
var random_frame_index: int = 0

signal tile_clicked(tile)

const DROP_HANDLER_SCRIPT = preload("res://src/Scripts/UI/TileDropHandler.gd")

const TILE_SHEET = preload("res://assets/images/UI/tile_sheet.png")
const TILE_SPAWN = preload("res://assets/images/UI/tile_spawn.png")

func _ready():
	random_frame_index = randi() % 25

func setup(grid_x: int, grid_y: int, tile_type: String = "normal"):
	x = grid_x
	y = grid_y
	type = tile_type

	random_frame_index = randi() % 25

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
	var sprite = $BaseSprite
	if not sprite: return

	sprite.hframes = 5
	sprite.vframes = 5

	# Reset modulation
	sprite.modulate = Color.WHITE

	if state == "unlocked":
		sprite.texture = TILE_SHEET
		sprite.frame = random_frame_index
	elif state == "locked_inner":
		sprite.texture = TILE_SHEET
		sprite.frame = random_frame_index
		sprite.modulate = Color(0.3, 0.3, 0.3) # Darkened
	elif state == "locked_outer":
		sprite.texture = TILE_SHEET
		sprite.frame = random_frame_index
		sprite.modulate = Color(0.1, 0.1, 0.1) # Very dark
	elif state == "spawn":
		sprite.texture = TILE_SPAWN
		# For spawn points, maybe use the same random frame, or a different one.
		# Requirement: "randomly display one of the frames"
		sprite.frame = random_frame_index

	if type == "core":
		# Core might need special visual or just label
		if has_node("Label"):
			$Label.text = "Core"
	else:
		if has_node("Label"):
			$Label.text = ""

func set_grid_visible(active: bool):
	if has_node("GridBorder"):
		$GridBorder.visible = active

func set_highlight(active: bool):
	var sprite = $BaseSprite
	if !sprite: return

	if active:
		# Lighten slightly
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", sprite.modulate.lightened(0.2), 0.1)
	else:
		# Revert to normal visual state (which sets modulate based on state)
		update_visuals()

func _on_area_2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tile_clicked.emit(self)

func _on_area_2d_mouse_entered():
	if !GameManager.is_wave_active:
		set_highlight(true)

func _on_area_2d_mouse_exited():
	set_highlight(false)
