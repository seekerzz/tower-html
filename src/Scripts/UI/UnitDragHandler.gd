extends Control

var unit

func _init():
	mouse_filter = MouseFilter.MOUSE_FILTER_STOP

func _get_drag_data(_at_position):
	if !unit or GameManager.is_wave_active: return null

	var preview = Control.new()
	var rect = ColorRect.new()
	rect.size = Vector2(50, 50)
	rect.color = Color(1, 1, 1, 0.5)
	rect.position = -rect.size / 2

	var lbl = Label.new()
	if unit.unit_data:
		lbl.text = unit.unit_data.icon
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size = rect.size
	lbl.position = rect.position

	preview.add_child(rect)
	preview.add_child(lbl)

	set_drag_preview(preview)

	unit.visible = false

	return {
		"type": "grid_unit",
		"unit": unit
	}

func _notification(what):
	if what == NOTIFICATION_DRAG_END:
		if is_instance_valid(unit) and !unit.is_queued_for_deletion():
			unit.visible = true

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if is_instance_valid(unit) and unit.has_signal("unit_clicked"):
				unit.unit_clicked.emit(unit)

func _mouse_entered():
	if is_instance_valid(unit) and unit.has_method("_on_mouse_entered_control"):
		unit._on_mouse_entered_control()

func _mouse_exited():
	if is_instance_valid(unit) and unit.has_method("_on_mouse_exited_control"):
		unit._on_mouse_exited_control()
