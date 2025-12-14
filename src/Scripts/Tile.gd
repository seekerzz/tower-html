extends Node2D

var x: int
var y: int
var type: String = "normal"
var state: String = "locked_inner" # unlocked, locked_inner, locked_outer, spawn
var unit = null
var occupied_by: Vector2i

signal tile_clicked(tile)

const DROP_HANDLER_SCRIPT = preload("res://src/Scripts/UI/TileDropHandler.gd")

# Textures
static var tex_unlocked: Texture2D
static var tex_spawn: Texture2D
static var textures_loaded: bool = false

func _init():
	if not textures_loaded:
		_load_textures()
		textures_loaded = true

func _load_textures():
	tex_unlocked = _load_texture_or_fallback("res://assets/images/UI/tile_unlocked.png", Color(0.4, 0.4, 0.4))
	tex_spawn = _load_texture_or_fallback("res://assets/images/UI/tile_spawn.png", Color(0.4, 0.2, 0.2))

func _load_texture_or_fallback(path: String, fallback_color: Color) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	else:
		var grad = GradientTexture2D.new()
		grad.width = 60
		grad.height = 60
		grad.fill = GradientTexture2D.FILL_SQUARE
		grad.fill_from = Vector2(0.5, 0.5)
		grad.fill_to = Vector2(1, 0.5)
		var gradient = Gradient.new()
		gradient.set_color(0, fallback_color.lightened(0.1))
		gradient.set_color(1, fallback_color)
		grad.gradient = gradient
		return grad

func setup(grid_x: int, grid_y: int, tile_type: String = "normal"):
	x = grid_x
	y = grid_y
	type = tile_type

	# Ensure visuals are updated based on type/state
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
	var sprite = $BaseSprite
	if not sprite: return

	sprite.visible = true
	sprite.modulate = Color.WHITE

	if state == "unlocked":
		sprite.texture = tex_unlocked
	elif state == "spawn":
		sprite.texture = tex_spawn
	elif state == "locked_inner":
		sprite.texture = tex_unlocked
		sprite.modulate = Color(0.3, 0.3, 0.3)
	elif state == "locked_outer":
		sprite.texture = tex_unlocked
		sprite.modulate = Color(0.1, 0.1, 0.1)

	if type == "core":
		# Keep core distinguishable
		sprite.modulate = Color(0.5, 0.5, 1.0)
		if has_node("Label"):
			$Label.text = "Core"
	else:
		if has_node("Label"):
			$Label.text = ""

func set_grid_visible(is_visible: bool):
	if has_node("GridBorder"):
		$GridBorder.visible = is_visible

func set_highlight(active: bool):
	if has_node("Highlight"):
		$Highlight.visible = active

	# Fallback if Highlight node is missing for some reason
	elif has_node("BaseSprite"):
		if active:
			$BaseSprite.modulate = $BaseSprite.modulate.lightened(0.2)
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
