extends Node2D

func _ready():
	print("Starting Viper Totem Test")
	# Setup GameManager dependencies
	# GameManager is autoloaded, so we can access it.

	var grid = Node2D.new()
	grid.name = "GridManager"
	add_child(grid)
	GameManager.grid_manager = grid

	var combat = Node.new()
	combat.set_script(load("res://src/Scripts/Tests/MockCombatManager.gd"))
	add_child(combat)
	GameManager.combat_manager = combat

	GameManager.is_wave_active = true

	# Create Enemies
	# Distances: 0, 100, 200, 300, 400
	# Core is at (0,0) (grid.global_position default)
	for i in range(5):
		var enemy = CharacterBody2D.new()
		enemy.add_to_group("enemies")
		enemy.global_position = Vector2(100 * i, 0)
		add_child(enemy)

	# Instantiate Mechanic
	var mechanic = load("res://src/Scripts/CoreMechanics/MechanicViperTotem.gd").new()
	add_child(mechanic)

	# Allow a frame for _ready
	await get_tree().process_frame

	# Trigger timeout manually
	mechanic._on_timer_timeout()

	# Verify
	# Should target furthest 3: 400, 300, 200.
	if combat.spawn_count == 3:
		print("PASS: 3 projectiles spawned")
	else:
		print("FAIL: Spawned ", combat.spawn_count)
		get_tree().quit(1)
		return

	# Check stats of last spawn
	var stats = combat.last_stats
	if stats.get("damageType") == "poison" and stats.get("is_meteor") == true:
		print("PASS: Stats correct")
	else:
		print("FAIL: Stats incorrect ", stats)
		get_tree().quit(1)
		return

	# Check effects
	if stats.has("effects") and stats.effects.get("poison_stacks") == 3:
		print("PASS: Poison stacks correct")
	else:
		print("FAIL: Poison stacks incorrect ", stats.get("effects"))
		get_tree().quit(1)
		return

	print("ALL TESTS PASSED")
	get_tree().quit()
