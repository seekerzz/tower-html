extends Control

@onready var container = $Container
const BENCH_UNIT_SCRIPT = preload("res://src/Scripts/UI/BenchUnit.gd")

func update_bench_ui(bench_data: Array):
	if !container: return

	for child in container.get_children():
		child.queue_free()

	for i in range(bench_data.size()):
		var data = bench_data[i]
		if data != null:
			var item = Control.new()
			item.set_script(BENCH_UNIT_SCRIPT)
			item.setup(data.key, i)
			container.add_child(item)
		else:
			var placeholder = Control.new()
			placeholder.custom_minimum_size = Vector2(60, 60)

			var rect = Panel.new()
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0, 0, 0, 0.3)
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
			style.border_color = Color(1, 1, 1, 0.3)
			style.set_corner_radius_all(4)

			rect.add_theme_stylebox_override("panel", style)
			rect.anchors_preset = 15

			placeholder.add_child(rect)
			container.add_child(placeholder)

func _can_drop_data(at_position, data):
	if !data or !data.has("source"): return false
	# Can accept from Grid
	if data.source == "grid": return true
	return false

func _drop_data(at_position, data):
	if data.source == "grid":
		if GameManager.main_game:
			GameManager.main_game.try_add_to_bench_from_grid(data.unit)
