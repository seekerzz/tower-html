extends Node2D

var x: int
var y: int
var type: String = "normal"
var state: String = "locked_inner" # unlocked, locked_inner, locked_outer, spawn
var unit = null
var occupied_by: Vector2i

signal tile_clicked(tile)

const DROP_HANDLER_SCRIPT = preload("res://src/Scripts/UI/TileDropHandler.gd")

func setup(grid_x: int, grid_y: int, tile_type: String = "normal"):
	x = grid_x
	y = grid_y
	type = tile_type

	if has_node("ColorRect") and !has_node("VisualPanel"):
		var cr = $ColorRect
		var panel = Panel.new()
		panel.name = "VisualPanel"
		panel.size = cr.size
		panel.position = cr.position
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var style = StyleMaker.get_flat_style(cr.color, 4)
		panel.add_theme_stylebox_override("panel", style)

		add_child(panel)
		move_child(panel, cr.get_index())
		cr.visible = false

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
	# Default base color based on state
	var base_color = Constants.COLORS.grid

	if state == "unlocked":
		base_color = Constants.COLORS.unlocked
	elif state == "locked_inner":
		base_color = Constants.COLORS.locked_inner
		# Debug color for visibility if needed, but using Constants is safer for style
		# base_color = Color.DARK_GRAY
	elif state == "locked_outer":
		base_color = Constants.COLORS.locked_outer
		# base_color = Color.BLACK
	elif state == "spawn":
		base_color = Constants.COLORS.spawn_point

	if type == "core":
		base_color = Constants.COLORS.core
		if has_node("Label"):
			$Label.text = "Core"
	else:
		if has_node("Label"):
			$Label.text = ""

	if has_node("VisualPanel"):
		var panel = $VisualPanel
		var style = panel.get_theme_stylebox("panel")
		if style:
			create_tween().tween_property(style, "bg_color", base_color, 0.2)
	elif has_node("ColorRect"):
		create_tween().tween_property($ColorRect, "color", base_color, 0.2)

func set_highlight(active: bool):
	var target = null
	var current_color = Color.BLACK
	var property = ""

	if has_node("VisualPanel"):
		target = $VisualPanel.get_theme_stylebox("panel")
		current_color = target.bg_color
		property = "bg_color"
	elif has_node("ColorRect"):
		target = $ColorRect
		current_color = target.color
		property = "color"

	if !target: return

	if active:
		create_tween().tween_property(target, property, current_color.lightened(0.2), 0.1)
	else:
		update_visuals()

func _on_area_2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tile_clicked.emit(self)

func _on_area_2d_mouse_entered():
	if !GameManager.is_wave_active:
		set_highlight(true)

func _on_area_2d_mouse_exited():
	set_highlight(false)
