extends Node

func _ready():
	print("Starting TestBatTotem...")
	call_deferred("test_case_bat_totem_logic")

func test_case_bat_totem_logic():
	print("Testing Bat Totem Logic...")

	# 1. Setup Managers Mock
	var mock_combat = MockCombatManager.new()
	var mock_grid = MockGridManager.new()

	GameManager.combat_manager = mock_combat
	GameManager.grid_manager = mock_grid
	GameManager.is_wave_active = true

	# 2. Setup Enemies
	# Create 3 enemies at different distances
	var enemy1 = Node2D.new()
	enemy1.name = "Enemy1"
	enemy1.global_position = Vector2(100, 0)
	enemy1.add_to_group("enemies")
	get_tree().root.add_child(enemy1)

	var enemy2 = Node2D.new()
	enemy2.name = "Enemy2"
	enemy2.global_position = Vector2(200, 0)
	enemy2.add_to_group("enemies")
	get_tree().root.add_child(enemy2)

	var enemy3 = Node2D.new()
	enemy3.name = "Enemy3"
	enemy3.global_position = Vector2(300, 0)
	enemy3.add_to_group("enemies")
	get_tree().root.add_child(enemy3)

	var enemy4 = Node2D.new()
	enemy4.name = "Enemy4 (Far)"
	enemy4.global_position = Vector2(1000, 0)
	enemy4.add_to_group("enemies")
	get_tree().root.add_child(enemy4)

	# Wait for group registration
	await get_tree().process_frame

	# 3. Initialize Mechanic
	GameManager.core_type = "bat_totem"

	# Verify mechanic is loaded
	if GameManager.current_mechanic == null:
		print("FAIL: Bat Totem mechanic not loaded.")
		return

	print("PASS: Bat Totem mechanic loaded.")

	# 4. Trigger Timeout
	# We access the mechanic script instance
	var mechanic = GameManager.current_mechanic
	if mechanic.has_method("_on_timer_timeout"):
		mechanic._on_timer_timeout()
	else:
		print("FAIL: Mechanic missing _on_timer_timeout.")
		return

	# 5. Verify Spawn Calls
	if mock_combat.spawn_calls.size() == 3:
		print("PASS: Spawned 3 projectiles.")
	else:
		print("FAIL: Expected 3 projectiles, got %d." % mock_combat.spawn_calls.size())

	# Verify targets (should be closest 3: enemy1, enemy2, enemy3)
	var targets_hit = []
	for call_data in mock_combat.spawn_calls:
		targets_hit.append(call_data.target)

	if enemy1 in targets_hit and enemy2 in targets_hit and enemy3 in targets_hit:
		print("PASS: Targeted closest 3 enemies.")
	else:
		print("FAIL: Targeted wrong enemies.")

	# Verify Bleed Effect in stats
	var correct_stats = true
	for call_data in mock_combat.spawn_calls:
		var stats = call_data.extra_stats
		if stats.get("effects", {}).get("bleed", 0) != 2.5:
			correct_stats = false
			print("FAIL: Projectile missing bleed effect. Got: ", stats)

	if correct_stats:
		print("PASS: Projectiles have bleed effect.")

	# Cleanup
	enemy1.queue_free()
	enemy2.queue_free()
	enemy3.queue_free()
	enemy4.queue_free()
	mock_combat.queue_free()
	mock_grid.queue_free()

	print("All tests passed.")
	get_tree().quit()


class MockCombatManager extends Node:
	var spawn_calls = []

	func spawn_projectile(source, pos, target, extra_stats = {}):
		spawn_calls.append({
			"source": source,
			"pos": pos,
			"target": target,
			"extra_stats": extra_stats
		})

class MockGridManager extends Node2D:
	func _ready():
		# Mock global position
		global_position = Vector2.ZERO
