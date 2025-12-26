extends Node2D

var x: int
var y: int
var type: String = "normal"
var state: String = "locked_inner" # unlocked, locked_inner, locked_outer, spawn
var unit = null
var occupied_by: Vector2i
var random_frame_index: int = 0

signal tile_clicked(tile)

# Use load instead of preload to avoid crash if assets are missing
const TEXTURE_SHEET_PATH = "res://assets/images/UI/tile_sheet.png"
const TEXTURE_SPAWN_PATH = "res://assets/images/UI/tile_spawn.png"

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
	var drop_handler_script = load("res://src/Scripts/UI/TileDropHandler.gd")
	drop_target.set_script(drop_handler_script)
	# Ensure drop_target does not block clicks on the tile itself.
	# It should rely on NOTIFICATION_DRAG_BEGIN to enable interaction (handled in script ideally),
	# or we set it to IGNORE here if the script handles it.
	# Assuming TileDropHandler behaves like ItemDropLayer:
	drop_target.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
		if ResourceLoader.exists(TEXTURE_SPAWN_PATH):
			bs.texture = load(TEXTURE_SPAWN_PATH)
			bs.hframes = 5
			bs.vframes = 5
			bs.frame = random_frame_index

			# Scale to fit TILE_SIZE (60)
			if bs.texture:
				var frame_width = bs.texture.get_width() / bs.hframes
				var scale_factor = 60.0 / max(frame_width, 1.0)
				bs.scale = Vector2(scale_factor, scale_factor)
		else:
			# Fallback if texture missing
			bs.texture = null
			# Add visual indication if needed, e.g. ColorRect or Modulate
			bs.modulate = Color(0.5, 0.2, 0.2) # Reddish

	elif state == "unlocked" or type == "core":
		if ResourceLoader.exists(TEXTURE_SHEET_PATH):
			bs.texture = load(TEXTURE_SHEET_PATH)
			bs.hframes = 5
			bs.vframes = 5
			bs.frame = random_frame_index

			# Scale to fit TILE_SIZE (60)
			if bs.texture:
				var frame_width = bs.texture.get_width() / bs.hframes
				var scale_factor = 60.0 / max(frame_width, 1.0)
				bs.scale = Vector2(scale_factor, scale_factor)
		else:
			bs.texture = null
			bs.modulate = Color(0.3, 0.3, 0.3) # Dark Gray

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
