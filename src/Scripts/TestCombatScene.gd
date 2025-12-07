extends Node2D

@onready var grid_manager = $GridManager
@onready var combat_manager = $CombatManager

func _ready():
	# Setup simple scene
	grid_manager.place_unit("ranger", 1, 0)
	grid_manager.place_unit("knight", -1, 0)

	# Start Wave manually after 1 second
	await get_tree().create_timer(1.0).timeout
	GameManager.start_wave()
