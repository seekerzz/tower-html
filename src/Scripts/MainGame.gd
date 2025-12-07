extends Node2D

@onready var grid_manager = $GridManager
@onready var combat_manager = $CombatManager
@onready var shop = $CanvasLayer/Shop
@onready var main_gui = $CanvasLayer/MainGUI

# Bench
var bench: Array = [null, null, null, null, null] # Array of Dictionary (Unit Data) or null

func _ready():
	GameManager.ui_manager = main_gui
	GameManager.main_game = self

	# Connect Shop signals
	# shop.unit_bought.connect(_on_unit_bought) # Now handled via add_to_bench in Shop

	# Initial Setup
	grid_manager.place_unit("mouse", 0, 1) # Starting unit

# Bench Logic
func add_to_bench(unit_key: String) -> bool:
	for i in range(bench.size()):
		if bench[i] == null:
			bench[i] = { "key": unit_key, "level": 1 } # Simplified data
			update_bench_ui()
			return true
	return false

func remove_from_bench(index: int):
	if index >= 0 and index < bench.size():
		bench[index] = null
		update_bench_ui()

func try_add_to_bench_from_grid(unit) -> bool:
	for i in range(bench.size()):
		if bench[i] == null:
			bench[i] = {
				"key": unit.type_key,
				"level": unit.level,
				# Add other persistent data here if needed
			}
			update_bench_ui()

			# Remove from grid!
			var w = unit.unit_data.size.x
			var h = unit.unit_data.size.y
			grid_manager._clear_tiles_occupied(unit.grid_pos.x, unit.grid_pos.y, w, h)

			unit.queue_free()
			return true
	print("Bench Full")
	return false

func update_bench_ui():
	shop.update_bench_ui(bench)
