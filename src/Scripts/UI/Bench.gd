extends Control

const SLOT_COUNT = 5
var bench_data = []

@onready var slots_container = $PanelContainer/SlotsContainer

const BENCH_UNIT_SCRIPT = preload("res://src/Scripts/UI/BenchUnit.gd")
const BENCH_SLOT_SCRIPT = preload("res://src/Scripts/UI/BenchSlot.gd")

func _ready():
	if slots_container:
		slots_container.add_theme_constant_override("separation", 10)
		var parent = slots_container.get_parent()
		if parent is PanelContainer:
			var style = StyleBoxEmpty.new()
			parent.add_theme_stylebox_override("panel", style)

func update_bench_ui(data):
	if !slots_container: return

	bench_data = data

	# Clear existing slots
	for child in slots_container.get_children():
		slots_container.remove_child(child)
		child.queue_free()

	# Create 5 slots
	for i in range(SLOT_COUNT):
		var slot = Control.new()
		slot.custom_minimum_size = Vector2(60, 60)
		slot.set_script(BENCH_SLOT_SCRIPT)
		slot.slot_index = i

		# Visual style: Panel child
		var panel = Panel.new()
		panel.anchors_preset = 15 # Full rect
		panel.mouse_filter = MOUSE_FILTER_IGNORE # Let the slot handle events

		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.2, 0.2, 1) # Dark gray background
		style.set_corner_radius_all(8) # Corner Radius: 8
		# Add clear rounded rectangle border
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.6, 0.6, 0.6, 0.8) # Light gray border

		panel.add_theme_stylebox_override("panel", style)
		slot.add_child(panel)

		# Add Unit if data exists
		if i < bench_data.size() and bench_data[i] != null:
			var unit_data = bench_data[i]
			var unit_display = Control.new()
			unit_display.set_script(BENCH_UNIT_SCRIPT)
			unit_display.setup(unit_data.key, i)

			# Ensure unit display fills slot but respects logic
			unit_display.layout_mode = 1
			unit_display.anchors_preset = 15

			slot.add_child(unit_display)

		slots_container.add_child(slot)
