extends Control

var tile

func _init():
	mouse_filter = MouseFilter.MOUSE_FILTER_PASS

func _can_drop_data(_at_position, data):
	if GameManager.is_wave_active: return false
	if typeof(data) == TYPE_DICTIONARY:
		if data.has("type") and (data.type == "grid_unit" or data.type == "bench_unit"):
			return true
	return false

func _drop_data(_at_position, data):
	if !tile: return

	if data.type == "grid_unit":
		var unit = data.unit
		GameManager.grid_manager.handle_unit_drop_on_tile(unit, tile)

	elif data.type == "bench_unit":
		GameManager.grid_manager.handle_bench_drop_on_tile(data.key, data.index, tile)
