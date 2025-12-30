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

	# Ensure CoreIcon exists
	if not has_node("CoreIcon"):
		var core_icon = Sprite2D.new()
		core_icon.name = "CoreIcon"
		add_child(core_icon)
		core_icon.visible = false

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

func _adjust_sprite_scale(sprite: Sprite2D, target_size: float):
	if sprite.texture:
		var frame_width = sprite.texture.get_width() / sprite.hframes
		var scale_factor = target_size / max(frame_width, 1.0)
		sprite.scale = Vector2(scale_factor, scale_factor)

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
		_adjust_sprite_scale(bs, 60.0)

	elif state == "unlocked" or type == "core":
		bs.texture = TEXTURE_SHEET
		bs.hframes = 5
		bs.vframes = 5
		bs.frame = random_frame_index
		_adjust_sprite_scale(bs, 60.0)

	elif "locked" in state:
		bs.visible = false
		bs.texture = null

	var core_icon = get_node_or_null("CoreIcon")
	var label = get_node_or_null("Label")

	if type == "core":
		var icon = AssetLoader.get_core_icon(GameManager.core_type)
		if icon:
			if core_icon:
				core_icon.texture = icon
				# Core icons are usually single frame, so hframes should be 1
				core_icon.hframes = 1
				core_icon.vframes = 1
				_adjust_sprite_scale(core_icon, 60.0)
				core_icon.visible = true
			if label:
				label.visible = false
		else:
			if core_icon:
				core_icon.visible = false
			if label:
				label.visible = true
				var core_name = "Core"
				if GameManager.data_manager and GameManager.data_manager.data.has("CORE_TYPES"):
					if GameManager.data_manager.data["CORE_TYPES"].has(GameManager.core_type):
						core_name = GameManager.data_manager.data["CORE_TYPES"][GameManager.core_type].get("name", "Core")
				label.text = core_name
	else:
		if core_icon:
			core_icon.visible = false
		if label:
			label.text = ""
			# Assuming we want to show label for other stuff? Or just hide it.
			# Original code set text to "", implying it might be visible but empty.
			# Let's keep it consistent.
			label.visible = true

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
