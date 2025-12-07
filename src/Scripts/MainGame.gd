extends Node2D

@onready var grid_manager = $GridManager
@onready var combat_manager = $CombatManager
@onready var shop = $CanvasLayer/Shop
@onready var main_gui = $CanvasLayer/MainGUI

# Bench
var bench: Array = [null, null, null, null, null] # Array of Unit Nodes (or null)
# @onready var bench_container = $CanvasLayer/Shop/Panel/BenchContainer # Commented out until added

func _ready():
	GameManager.ui_manager = main_gui

	# Connect Shop signals
	# For simplified integration without full drag & drop implementation:
	shop.unit_bought.connect(_on_unit_bought_simplified)

	# Initial Setup
	grid_manager.place_unit("mouse", 0, 1) # Starting unit

func _on_unit_bought_simplified(unit_key):
	# Find free tile
	for x in range(-2, 3):
		for y in range(-2, 3):
			if grid_manager.place_unit(unit_key, x, y):
				return
	print("No space!")
	GameManager.add_gold(Constants.UNIT_TYPES[unit_key].cost)
