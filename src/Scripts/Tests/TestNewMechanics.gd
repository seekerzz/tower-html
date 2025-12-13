extends Node2D

var grid_manager
var combat_manager

func _ready():
	print("TestNewMechanics: Starting...")
	# Setup Managers
	grid_manager = load("res://src/Scripts/GridManager.gd").new()
	grid_manager.name = "GridManager"
	add_child(grid_manager)
	GameManager.grid_manager = grid_manager

	combat_manager = load("res://src/Scripts/CombatManager.gd").new()
	combat_manager.name = "CombatManager"
	add_child(combat_manager)

	# Start Wave manually to enable logic
	GameManager.start_wave()
	print("Wave started.")

	# Unlock an extra tile for Mosquito
	# (1,1) is valid to unlock (diagonally adjacent to center, usually need expansion logic but force it here)
	var tile_key = grid_manager.get_tile_key(1, 1)
	if grid_manager.tiles.has(tile_key):
		grid_manager.tiles[tile_key].set_state("unlocked")
		grid_manager.active_territory_tiles.append(grid_manager.tiles[tile_key])

	# 1. Test Cow (Heal)
	# Damage Core first
	GameManager.core_health = 500
	_place_unit("cow", 0, 1)

	# 2. Test Hedgehog (Reflect)
	_place_unit("hedgehog", 1, 0)

	# 3. Test Rabbit (Dodge)
	_place_unit("rabbit", -1, 0)

	# 4. Test Snowman (Freeze)
	_place_unit("snowman", 0, -1)

	# 5. Test Mosquito (Lifesteal)
	# Place at (1,1)
	_place_unit("mosquito", 1, 1)

	# Spawn Enemies to interact
	# Spawn enemy at (300, 0) -> Moving to Core (0,0). Will hit Hedgehog at (1,0) (approx 60,0)
	_spawn_enemy(Vector2(300, 0), "wolf")

	# Spawn enemy to trigger Rabbit (-1,0)
	_spawn_enemy(Vector2(-300, 0), "wolf")

	# Spawn enemy for Mosquito (1,1) to shoot at.
	# Mosquito at (60, 60). Range 200.
	# Enemy at (200, 200) -> distance to (60,60) is ~200 (140^2 + 140^2 = 19800+19800 = 39600. sqrt = 199).
	# Just within range.
	_spawn_enemy(Vector2(200, 200), "wolf")

	# Wait and Check
	await get_tree().create_timer(10.0).timeout

	print("Core Health: ", GameManager.core_health)
	print("Test Finished.")
	get_tree().quit()

func _place_unit(key, x, y):
	if grid_manager.place_unit(key, x, y):
		print("Placed " + key + " at " + str(x) + "," + str(y))
	else:
		print("Failed to place " + key)

func _spawn_enemy(pos, key):
	var enemy = load("res://src/Scenes/Game/Enemy.tscn").instantiate()
	enemy.setup(key, 1)
	enemy.global_position = pos
	add_child(enemy)
	print("Spawned " + key + " at " + str(pos))
