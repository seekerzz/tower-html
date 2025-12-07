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
	mouse_filter = MOUSE_FILTER_PASS

func _get_drag_data(at_position):
	var preview = Control.new()
	var rect = ColorRect.new()
	rect.size = Vector2(50, 50)
	rect.color = Color(1, 1, 1, 0.5)

	var lbl = Label.new()
	var proto = Constants.UNIT_TYPES[unit_key]
	lbl.text = proto.icon
	lbl.size = rect.size
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	preview.add_child(rect)
	preview.add_child(lbl)
	preview.z_index = 100 # On top

	set_drag_preview(preview)

	return {
		"source": "bench",
		"index": bench_index,
		"key": unit_key
	}
