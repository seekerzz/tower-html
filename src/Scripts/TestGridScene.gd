extends Node2D

@onready var grid_manager = $GridManager
@onready var camera = $Camera2D

func _ready():
	# Test: Place some units
	grid_manager.place_unit("mouse", 0, 1)
	grid_manager.place_unit("turtle", 1, 0)

	# Test: Place large unit
	grid_manager.create_tile(0, 2)
	grid_manager.create_tile(1, 2)
	grid_manager.create_tile(0, 3)
	grid_manager.create_tile(1, 3)

	if grid_manager.place_unit("hydra", 0, 2):
		print("Placed Hydra!")
	else:
		print("Failed to place Hydra")

func _process(delta):
	# Simple camera movement
	if Input.is_action_pressed("ui_right"): camera.position.x += 200 * delta
	if Input.is_action_pressed("ui_left"): camera.position.x -= 200 * delta
	if Input.is_action_pressed("ui_down"): camera.position.y += 200 * delta
	if Input.is_action_pressed("ui_up"): camera.position.y -= 200 * delta
