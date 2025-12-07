extends Control

var unit_key: String
var bench_index: int

signal drag_started(index)
signal drag_ended

func setup(key: String, index: int):
	unit_key = key
	bench_index = index
	var proto = Constants.UNIT_TYPES[key]

	# Visuals (Using existing children or creating new)
	var label = Label.new()
	label.text = proto.icon
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchors_preset = 15 # Full Rect
	add_child(label)

	custom_minimum_size = Vector2(60, 60)
	mouse_filter = MouseFilter.MOUSE_FILTER_STOP

func _get_drag_data(_at_position):
	if GameManager.is_wave_active: return null

	# Preview
	var preview = Control.new()
	var rect = ColorRect.new()
	rect.size = Vector2(50, 50)
	rect.color = Color(1, 1, 1, 0.5)
	rect.position = -rect.size / 2 # Center it

	var lbl = Label.new()
	var proto = Constants.UNIT_TYPES[unit_key]
	lbl.text = proto.icon
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size = rect.size
	lbl.position = rect.position

	preview.add_child(rect)
	preview.add_child(lbl)
	set_drag_preview(preview)

	return {
		"type": "bench_unit",
		"index": bench_index,
		"key": unit_key
	}
