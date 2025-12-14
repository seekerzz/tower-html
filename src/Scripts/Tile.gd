extends Node2D

var x: int
var y: int
var type: String = "normal"
var state: String = "locked_inner" # unlocked, locked_inner, locked_outer, spawn
var unit = null
var occupied_by: Vector2i

# Random frame index for visual variation
var random_frame_index: int = 0

signal tile_clicked(tile)

const DROP_HANDLER_SCRIPT = preload("res://src/Scripts/UI/TileDropHandler.gd")
const TEXTURE_SHEET = preload("res://assets/images/UI/tile_sheet.png")
const TEXTURE_SPAWN = preload("res://assets/images/UI/tile_spawn.png")

func _init():
	random_frame_index = randi() % 25

func _ready():
	# Redundant but safe if _init didn't catch randomness (e.g. seed set later)
	# But generally _init is fine.
	pass

func setup(grid_x: int, grid_y: int, tile_type: String = "normal"):
	x = grid_x
	y = grid_y
	type = tile_type

	# Remove legacy ColorRect/VisualPanel logic

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

	if type == "core":
		# Keep basic color/label for core? Or use specific texture?
		# The prompt didn't specify Core visual changes, but let's assume it acts like unlocked but labeled
		if has_node("Label"):
			$Label.text = "Core"
	else:
		if has_node("Label"):
			$Label.text = ""

	sprite.visible = true
	sprite.modulate = Color(1, 1, 1, 1) # Reset modulate
	sprite.hframes = 5
	sprite.vframes = 5

	if state == "unlocked":
		sprite.texture = TEXTURE_SHEET
		sprite.frame = random_frame_index
	elif state == "spawn":
		sprite.texture = TEXTURE_SPAWN
		# The prompt says: "设置 frame = random_frame_index (或者生成一个新的随机数，确保出生点也有变化)"
		sprite.frame = random_frame_index
	elif state == "locked_inner":
		sprite.texture = TEXTURE_SHEET
		sprite.frame = random_frame_index
		sprite.modulate = Color(0.3, 0.3, 0.3, 1) # Darken
	elif state == "locked_outer":
		# Hide or darken significantly
		sprite.visible = false
	else:
		sprite.visible = false

func set_grid_visible(active: bool):
	if has_node("GridBorder"):
		$GridBorder.visible = active

func set_highlight(active: bool):
	var sprite = $BaseSprite
	if active:
		sprite.modulate = Color(1.2, 1.2, 1.2, 1) # Brighten
	else:
		update_visuals() # Reset to normal state visuals

func _on_area_2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tile_clicked.emit(self)

func _on_area_2d_mouse_entered():
	if !GameManager.is_wave_active:
		set_highlight(true)

func _on_area_2d_mouse_exited():
	set_highlight(false)
