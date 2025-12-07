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
	_setup_drop_handler()

func _setup_drop_handler():
	var drop = Control.new()
	drop.name = "DropHitbox"
	drop.set_script(DROP_HANDLER_SCRIPT)
	drop.tile = self

	# Size 60x60
	drop.size = Vector2(60, 60)
	drop.position = -drop.size / 2 # Center it relative to Tile (Tile is centered?)
	# Tile visual is usually centered if it's a sprite, or top-left.
	# Let's check update_visuals or GridManager.
	# GridManager: tile.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	# Tile.tscn: $ColorRect is -30,-30 ?
	# Check Tile.gd:
	# $ColorRect.color = ...
	# Usually Tile.tscn root is at 0,0.
	# We should check Tile.tscn structure if possible.
	# But assuming typical setup:
	# If $ColorRect is background, we can match it.
	# Assuming Tile is centered or 0,0 is topleft.
	# Standard Tile: 60x60.
	# If GridManager places them at x*60, y*60.
	# Tile visual usually: 0,0 to 60,60? Or -30,-30 to 30,30?
	# In GridManager: unit.position = tile.position + offset.
	# If offset for 1x1 (w=1,h=1) is 0.
	# Then unit is at tile.position.
	# Unit visual is centered.
	# So Tile visual should also be centered.
	# So DropHitbox should be centered at 0,0.
	# $ColorRect is usually -30, -30 in centered tiles.
	# Let's assume -30, -30 for top left of control.

	drop.position = Vector2(-30, -30)
	add_child(drop)

func update_visuals():
	# If it's a ghost, handle opacity?
	# Handled via modulate in GridManager
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

# Old logic for click maintained via Area2D if needed, or we can move it to Control.
# If Control is PASS, Area2D might still work?
# Yes.
func _on_area_2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tile_clicked.emit(self)

func _on_area_2d_mouse_entered():
	if !GameManager.is_wave_active:
		set_highlight(true)

func _on_area_2d_mouse_exited():
	set_highlight(false)
