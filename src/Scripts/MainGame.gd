extends Node2D

@onready var grid_manager = $GridManager
@onready var combat_manager = $CombatManager
@onready var shop = $CanvasLayer/Shop
@onready var bench_ui = $CanvasLayer/Bench
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

func move_unit_from_grid_to_bench(unit_node, target_index: int):
	if target_index < 0 or target_index >= bench.size():
		return

	if bench[target_index] != null:
		# If target is occupied, we might want to swap or just fail.
		# For now, simplistic approach: fail if occupied.
		print("Bench slot occupied")
		return

	# Logic to move
	bench[target_index] = {
		"key": unit_node.type_key,
		"level": unit_node.level
	}

	# Remove from grid
	grid_manager.remove_unit_from_grid(unit_node)

	update_bench_ui()

func try_add_to_bench_from_grid(unit) -> bool:
	for i in range(bench.size()):
		if bench[i] == null:
			move_unit_from_grid_to_bench(unit, i)
			return true
	print("Bench Full")
	return false

func update_bench_ui():
	if bench_ui:
		bench_ui.update_bench_ui(bench)
