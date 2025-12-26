extends Node

# Manual Test Script for Core Mechanics
# To run: Attach to a scene or run via command line if possible.
# Since we are in an editor environment, we will simulate the steps.

func _ready():
	print("Starting Core Mechanics Test...")
	await get_tree().create_timer(1.0).timeout
	run_tests()

func run_tests():
	test_wave_item_distribution()
	test_moon_well_accumulation()
	test_holy_sword_crit()
	print("All tests completed.")

func test_wave_item_distribution():
	print("\n--- Test Case 1: Wave Item Distribution ---")

	# Setup
	GameManager.core_type = "abundance"
	var old_count = count_item_in_inventory("rice_ear")

	# Action
	GameManager.start_wave()

	# Assert
	var new_count = count_item_in_inventory("rice_ear")
	if new_count > old_count:
		print("PASS: Received rice_ear.")
	else:
		print("FAIL: Did not receive rice_ear. Check InventoryManager or Core Type.")

	GameManager.end_wave() # Cleanup

func test_moon_well_accumulation():
	print("\n--- Test Case 2: Moon Well Accumulation ---")

	# Setup
	GameManager.core_type = "moon_well"
	GameManager.moonwell_pool = 0

	# Action
	# Simulate damage dealt signal
	# We need to emit the signal manually as if a unit dealt damage
	GameManager.damage_dealt.emit(null, 1000)

	# Assert
	if abs(GameManager.moonwell_pool - 100.0) < 0.1:
		print("PASS: Moon Well accumulated 100 from 1000 damage.")
	else:
		print("FAIL: Moon Well pool is %s, expected 100." % GameManager.moonwell_pool)

func test_holy_sword_crit():
	print("\n--- Test Case 3: Holy Sword Crit ---")

	# Temporary mock CombatManager
	var combat_mgr_scene = load("res://src/Scenes/Game/CombatManager.tscn")
	var combat_mgr = combat_mgr_scene.instantiate()
	add_child(combat_mgr)
	# CombatManager _ready() assigns itself to GameManager.combat_manager

	# Setup: Create a unit
	var unit_scene = load("res://src/Scenes/Game/Unit.tscn")
	var unit = unit_scene.instantiate()
	unit.unit_data = Constants.UNIT_TYPES["tiger"].duplicate() # Tiger has some crit
	unit.crit_rate = 0.0 # Force 0 base crit
	add_child(unit)

	unit.add_crit_stacks(3)

	if unit.guaranteed_crit_stacks != 3:
		print("FAIL: Unit did not receive 3 crit stacks.")
		return

	if GameManager.combat_manager:
		print("Simulating 3 attacks...")
		for i in range(3):
			# We inspect if stacks decrease.
			GameManager.combat_manager.spawn_projectile(unit, Vector2.ZERO, null)

			if unit.guaranteed_crit_stacks == (2 - i):
				print("Attack %d: Stack consumed. Remaining: %d" % [i+1, unit.guaranteed_crit_stacks])
			else:
				print("FAIL: Stack not consumed correctly on attack %d. Stacks: %d" % [i+1, unit.guaranteed_crit_stacks])

		# 4th attack should not consume (if 0)
		GameManager.combat_manager.spawn_projectile(unit, Vector2.ZERO, null)
		if unit.guaranteed_crit_stacks == 0:
			print("Attack 4: Stacks remain 0.")
			print("PASS: Holy Sword Crit logic verified (via stack consumption).")
		else:
			print("FAIL: Stacks went below 0 or weird behavior.")

	else:
		print("FAIL: CombatManager still not available despite instantiation.")

	unit.queue_free()
	combat_mgr.queue_free()

func count_item_in_inventory(item_id):
	var count = 0
	if GameManager.inventory_manager:
		var items = GameManager.inventory_manager.get_inventory()
		for item in items:
			if item and item.get("item_id") == item_id:
				count += item.get("count", 0)
	return count
