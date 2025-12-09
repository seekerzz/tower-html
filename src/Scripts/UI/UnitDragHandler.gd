extends Control

var unit_ref # Reference to the Unit (Node2D)

func setup(unit):
	unit_ref = unit

	# Match unit size using visual_holder if available
	var color_rect = null
	if unit.has_node("VisualHolder"):
		var vh = unit.get_node("VisualHolder")
		color_rect = vh.get_node_or_null("ColorRect")

	# Fallback if VisualHolder doesn't exist yet or not found (compatibility)
	if !color_rect:
		color_rect = unit.get_node_or_null("ColorRect")

	if color_rect:
		size = color_rect.size
		# position for a Control is relative to parent (Unit).
		# visual_holder is at (0,0). ColorRect is at (-size/2).
		# If we want this DragHandler to cover the unit, it should be at ColorRect's position.
		# Note: unit.get_node("VisualHolder").position is 0,0 usually.
		# unit.get_node("VisualHolder/ColorRect").position is local to holder.

		# If hierarchy is Unit -> VisualHolder -> ColorRect
		# ColorRect global position = Unit.global_position + VisualHolder.position + ColorRect.position
		# DragHandler (child of Unit) position should be VisualHolder.position + ColorRect.position

		var vh_pos = Vector2.ZERO
		if unit.has_node("VisualHolder"):
			vh_pos = unit.get_node("VisualHolder").position

		position = vh_pos + color_rect.position
	else:
		# Fallback size
		size = Vector2(56, 56)
		position = -size / 2

	mouse_filter = MOUSE_FILTER_PASS

func _get_drag_data(at_position):
	if !unit_ref: return null
	if !GameManager.is_wave_active and unit_ref.grid_pos != null:
		var preview = Control.new()
		var rect = ColorRect.new()
		rect.size = size
		rect.color = Color(1, 1, 1, 0.5)
		preview.add_child(rect)

		# Add label?
		var lbl = Label.new()
		if unit_ref.unit_data:
			lbl.text = unit_ref.unit_data.get("icon", "?")
		lbl.size = size
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		preview.add_child(lbl)

		set_drag_preview(preview)

		return {
			"source": "grid",
			"unit": unit_ref,
			"grid_pos": unit_ref.grid_pos
		}
	return null
