extends Node2D

var x: int
var y: int
var type: String = "normal"
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

func update_visuals():
	$ColorRect.color = Constants.COLORS.grid
	$Label.text = ""

	if type == "core":
		$ColorRect.color = Color("#4a3045")
		$Label.text = "Core"
	elif type == "core_unlocked":
		$ColorRect.color = Color("#5a4055") # Brighter
		$Label.text = ""
	elif type == "core_locked":
		$ColorRect.color = Color("#2a1015") # Darker
		$Label.text = "🔒"
	elif type == "wilderness":
		$ColorRect.color = Color("#101015") # Very Dark
		$Label.text = ""

func set_highlight(active: bool):
	if active:
		$ColorRect.color = Constants.COLORS.grid.lightened(0.2)
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
