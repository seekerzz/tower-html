extends Control

var unit_key: String
var bench_index: int
var is_dragging: bool = false
var drag_preview = null

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

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_drag()
			elif is_dragging:
				_end_drag()
	elif event is InputEventMouseMotion:
		if is_dragging and drag_preview:
			drag_preview.global_position = get_global_mouse_position()

func _start_drag():
	is_dragging = true
	drag_started.emit(bench_index)
	modulate.a = 0.5

	# Create ghost
	drag_preview = Node2D.new()
	# Add a visual rect/label
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

	drag_preview.add_child(rect)
	drag_preview.add_child(lbl)

	# Add to main scene so it draws on top
	get_tree().root.add_child(drag_preview)
	drag_preview.global_position = get_global_mouse_position()

func _end_drag():
	is_dragging = false
	modulate.a = 1.0

	if drag_preview:
		# Check drop
		var handled = false
		if GameManager.grid_manager:
			# Mocking a Unit object structure for the manager to read position
			# But GridManager expects a Unit instance or we need a new method.
			# Let's use the new handle_bench_drop method.
			handled = GameManager.grid_manager.handle_bench_drop(drag_preview, unit_key, bench_index)

		drag_preview.queue_free()
		drag_preview = null

	drag_ended.emit()
