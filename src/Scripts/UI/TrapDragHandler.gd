extends Control

var trap_ref # Reference to the Barricade (Area2D)

func setup(trap):
	trap_ref = trap
	# Size of a trap is typically TILE_SIZE (60)
	size = Vector2(60, 60)
	position = -size / 2
	mouse_filter = MOUSE_FILTER_PASS

func _get_drag_data(at_position):
	if !trap_ref: return null
	if GameManager.is_wave_active: return null

	var preview = Control.new()
	var icon = Label.new()
	if trap_ref.props:
		icon.text = trap_ref.props.get("icon", "Trap")
	icon.add_theme_font_size_override("font_size", 32)
	preview.add_child(icon)
	icon.position = -Vector2(30, 30) # Center offset
	set_drag_preview(preview)

	return { "source": "trap", "node": trap_ref }
