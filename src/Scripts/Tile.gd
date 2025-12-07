extends Node2D

var x: int
var y: int
var type: String = "normal"
var unit = null # Reference to the unit on this tile
var occupied_by: Vector2i # If occupied by a multi-tile unit origin

signal tile_clicked(tile)

func setup(grid_x: int, grid_y: int, tile_type: String = "normal"):
	x = grid_x
	y = grid_y
	type = tile_type
	update_visuals()

func update_visuals():
	$ColorRect.color = Constants.COLORS.grid
	if type == "core":
		$ColorRect.color = Color("#4a3045")
		$Label.text = "Core"
	else:
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
