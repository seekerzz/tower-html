extends Control

var unit_ref # Reference to the Unit (Node2D)

func setup(unit):
	unit_ref = unit
	# Match unit size
	size = unit.get_node("ColorRect").size
	position = unit.get_node("ColorRect").position
	mouse_filter = MOUSE_FILTER_PASS # Allow clicks to pass to Area2D if needed, but drag might consume?
	# _get_drag_data consumes the event if it returns something.
	# If we want click to work (for info tooltip or selection), we rely on _gui_input?
	# Or the Area2D in Unit still works?
	# If Control is on top and has STOP (default) or PASS, it handles mouse.
	# We want Drag.
	pass

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
		lbl.text = unit_ref.unit_data.icon
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
