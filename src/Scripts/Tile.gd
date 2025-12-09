extends Node2D

var x: int
var y: int
var type: String = "normal"
var zone: String = "wilderness" # "core", "wilderness"
var obstacle_type: String = "" # "stone", "wood", etc.

var unit = null
var occupied_by: Vector2i

signal tile_clicked(tile)

const DROP_HANDLER_SCRIPT = preload("res://src/Scripts/UI/TileDropHandler.gd")

func setup(grid_x: int, grid_y: int, tile_type: String = "normal"):
	x = grid_x
	y = grid_y
	type = tile_type
	# zone is set externally by GridManager usually, or we can check here if we passed it.
	update_visuals()

	# Add Drop Target
	var drop_target = Control.new()
	drop_target.set_script(DROP_HANDLER_SCRIPT)
	add_child(drop_target)
	drop_target.setup(self)

func update_visuals():
	if zone == "core":
		$ColorRect.color = Color("#4a3045") # Darker purple for core
		# $Label.text = "Core"
	else:
		if (x + y) % 2 == 0:
			$ColorRect.color = Constants.COLORS.grid
		else:
			$ColorRect.color = Constants.COLORS.grid.lightened(0.05)
		$Label.text = ""

	if obstacle_type != "":
		$Label.text = _get_obstacle_icon(obstacle_type)
		$ColorRect.color = Color("#555555") # Grayish for obstacle bg
	else:
		if zone != "core": $Label.text = ""

func _get_obstacle_icon(obs_type: String) -> String:
	match obs_type:
		"stone": return "🪨"
		"wood": return "🪵"
	return ""

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
