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

	if has_node("ColorRect"):
		$ColorRect.color = base_color

func set_highlight(active: bool):
	if !has_node("ColorRect"): return
	if active:
		$ColorRect.color = $ColorRect.color.lightened(0.2)
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
