extends Node2D

var x: int
var y: int
var type: String = "normal"
var unit = null
var occupied_by: Vector2i
var is_locked: bool = false

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

func update_visuals():
	if is_locked:
		$ColorRect.color = Color.DARK_GRAY
		$Label.text = ""
		# Disable interaction
		$Area2D.input_pickable = false
	else:
		$ColorRect.color = Constants.COLORS.grid
		$Area2D.input_pickable = true
		if type == "core":
			$ColorRect.color = Color("#4a3045")
			$Label.text = "Core"
		else:
			$Label.text = ""

func set_locked(locked: bool):
	is_locked = locked
	update_visuals()

func set_highlight(active: bool):
	if is_locked: return
	if active:
		$ColorRect.color = Constants.COLORS.grid.lightened(0.2)
	else:
		update_visuals()

func _on_area_2d_input_event(viewport, event, shape_idx):
	if is_locked: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tile_clicked.emit(self)

func _on_area_2d_mouse_entered():
	if !GameManager.is_wave_active:
		set_highlight(true)

func _on_area_2d_mouse_exited():
	set_highlight(false)
