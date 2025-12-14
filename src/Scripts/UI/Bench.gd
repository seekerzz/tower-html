extends Control

# Uses Constants.BENCH_SIZE which is now 8
const BENCH_UNIT_SCRIPT = preload("res://src/Scripts/UI/BenchUnit.gd")
const BENCH_SLOT_SCRIPT = preload("res://src/Scripts/UI/BenchSlot.gd")

@onready var slots_container = $PanelContainer/SlotsContainer

func _ready():
	if slots_container:
		# Configure Grid
		slots_container.columns = 4

		var parent = slots_container.get_parent()
		if parent is PanelContainer:
			var style = StyleBoxEmpty.new()
			parent.add_theme_stylebox_override("panel", style)

func update_bench_ui(bench_data: Array):
	if !slots_container: return

	# Clear existing slots
	for child in slots_container.get_children():
		slots_container.remove_child(child)
		child.queue_free()

	# Create slots based on BENCH_SIZE (8)
	var slot_count = Constants.BENCH_SIZE

	# If bench_data is smaller (e.g. 5 from old save/code), we pad it or just use index check.
	# bench_data should be handled by MainGame, ensuring it has correct size.
	# But just in case, we iterate up to slot_count.

	for i in range(slot_count):
		var slot = Control.new()
		# GridContainer cell size control
		slot.custom_minimum_size = Vector2(40, 40) # Smaller slots for 4x2
		slot.size_flags_horizontal = SIZE_EXPAND_FILL
		slot.size_flags_vertical = SIZE_EXPAND_FILL
		slot.set_script(BENCH_SLOT_SCRIPT)
		slot.slot_index = i

		# Visual style for Empty Slot
		var panel = Panel.new()
		panel.anchors_preset = 15 # Full rect
		panel.mouse_filter = MOUSE_FILTER_IGNORE

		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.2, 0.2, 0.8) # Visible dark background
		style.set_corner_radius_all(4)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.5, 0.5, 0.5, 0.3)

		panel.add_theme_stylebox_override("panel", style)
		slot.add_child(panel)

		# Add Unit if data exists
		if i < bench_data.size() and bench_data[i] != null:
			var unit_data = bench_data[i]
			var unit_display = Control.new()
			unit_display.set_script(BENCH_UNIT_SCRIPT)
			unit_display.setup(unit_data.key, i)

			unit_display.layout_mode = 1
			unit_display.anchors_preset = 15

			# Scale unit display to fit if needed
			# unit_display.scale = Vector2(0.8, 0.8) # Optional adjustment

			slot.add_child(unit_display)

		slots_container.add_child(slot)
