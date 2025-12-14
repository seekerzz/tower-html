extends Node2D

var x: int
var y: int
var type: String = "normal"
var state: String = "locked_inner" # unlocked, locked_inner, locked_outer, spawn
var unit = null
var occupied_by: Vector2i
var random_frame_index: int = 0

signal tile_clicked(tile)

const DROP_HANDLER_SCRIPT = preload("res://src/Scripts/UI/TileDropHandler.gd")
const TEXTURE_SHEET = preload("res://assets/images/UI/tile_sheet.png")
const TEXTURE_SPAWN = preload("res://assets/images/UI/tile_spawn.png")

func setup(grid_x: int, grid_y: int, tile_type: String = "normal"):
	x = grid_x
	y = grid_y
	type = tile_type

	random_frame_index = randi() % 25

	if has_node("BaseSprite"):
		var bs = $BaseSprite
		bs.hframes = 5
		bs.vframes = 5

	# Cleanup old nodes if they exist
	if has_node("ColorRect"): $ColorRect.queue_free()
	if has_node("VisualPanel"): $VisualPanel.queue_free()

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
	var bs = get_node_or_null("BaseSprite")
	if !bs: return

	bs.visible = true
	bs.modulate = Color.WHITE

	if state == "spawn":
		bs.texture = TEXTURE_SPAWN
		bs.hframes = 5
		bs.vframes = 5
		bs.frame = random_frame_index

		# Scale to fit TILE_SIZE (60)
		if bs.texture:
			var frame_width = bs.texture.get_width() / bs.hframes
			var scale_factor = 60.0 / max(frame_width, 1.0)
			bs.scale = Vector2(scale_factor, scale_factor)

	elif state == "unlocked" or type == "core":
		bs.texture = TEXTURE_SHEET
		bs.hframes = 5
		bs.vframes = 5
		bs.frame = random_frame_index

		# Scale to fit TILE_SIZE (60)
		if bs.texture:
			var frame_width = bs.texture.get_width() / bs.hframes
			var scale_factor = 60.0 / max(frame_width, 1.0)
			bs.scale = Vector2(scale_factor, scale_factor)

	elif "locked" in state:
		bs.visible = false
		bs.texture = null

	if type == "core":
		if has_node("Label"):
			$Label.text = "Core"
	else:
		if has_node("Label"):
			$Label.text = ""

func set_grid_visible(visible_state: bool):
	var b = get_node_or_null("Border")
	if b:
		b.visible = visible_state

func set_highlight(active: bool):
	var bs = get_node_or_null("BaseSprite")
	if !bs: return

	if active:
		bs.modulate = Color(1.2, 1.2, 1.2)
	else:
		bs.modulate = Color.WHITE

func _on_area_2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tile_clicked.emit(self)

func _on_area_2d_mouse_entered():
	if !GameManager.is_wave_active:
		set_highlight(true)

func _on_area_2d_mouse_exited():
	set_highlight(false)
