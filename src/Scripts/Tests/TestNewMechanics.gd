extends Node

func _ready():
	print("[TestNewMechanics] Starting Tests...")
	await get_tree().create_timer(0.5).timeout

	test_infinite_inventory()
	test_moon_well()
	test_crit_logic()
	test_holy_sword_drop_logic()

	print("[TestNewMechanics] PASS")
	get_tree().quit()

func test_infinite_inventory():
	print("Test 1: Infinite Inventory")
	var inv_mgr = GameManager.inventory_manager
	inv_mgr.items.clear()

	# Add different items to avoid stacking, as implementation stacks same items.
	# Or check count if stacked.
	# The requirement says "Add 20 items. Assert items.size() == 20".
	# If add_item handles stacking, adding 20 "rice_ear" will result in 1 item with count 20.
	# To test infinite inventory slots, we need 20 UNIQUE items or modify test to check dynamic sizing.

	for i in range(20):
		inv_mgr.add_item({"item_id": "unique_item_%d" % i, "count": 1})

	assert(inv_mgr.items.size() == 20, "Inventory size should be 20. Actual: %d" % inv_mgr.items.size())
	print(" -> PASS")

func test_moon_well():
	print("Test 2: Moon Well")
	GameManager.core_type = "moon_well"
	GameManager.moonwell_pool = 0.0
	GameManager.max_core_health = 1000.0
	GameManager.core_health = 1000.0
	GameManager.mana = 0.0

	# Simulate Damage Dealt
	# Signal: damage_dealt(unit, amount)
	GameManager.damage_dealt.emit(null, 1000.0)

	await get_tree().process_frame

	assert(is_equal_approx(GameManager.moonwell_pool, 100.0), "Moonwell pool should be 10% of 1000 (100). Got: %s" % GameManager.moonwell_pool)

	# Test Use Item (Heal + Overflow)
	GameManager.core_health = 950.0 # Missing 50

	var item_data = {"item_id": "moon_water"}
	# Mock data manager if needed, but GameManager reads from it.
	# Assuming data is loaded.

	GameManager.use_item(item_data)

	assert(is_equal_approx(GameManager.core_health, 1000.0), "Core health should be restored to max.")
	# Used 50 from 100 pool -> 50 left. 50 * 1% = 0.5 Mana.
	assert(is_equal_approx(GameManager.mana, 0.5), "Mana should be 0.5. Got: %s" % GameManager.mana)

	print(" -> PASS")

func test_crit_logic():
	print("Test 3: Crit Logic")
	var unit_script = load("res://src/Scripts/Unit.gd")
	var unit = unit_script.new()
	# Minimal setup for unit
	unit.unit_data = {"crit_rate": 0.0, "size": Vector2(1, 1), "icon": "test"} # Missing size caused error in update_visuals
	unit.crit_rate = 0.0
	add_child(unit)

	unit.apply_holy_sword_buff()
	assert(unit.guaranteed_crit_stacks == 3, "Should have 3 stacks")

	# Mock CombatManager logic for crit consumption
	# Since we can't easily spawn projectiles and check them without full scene,
	# we will check the logic directly if possible or simulate the check.
	# But CombatManager.spawn_projectile modifies the unit state.

	# Let's mock CombatManager locally or use the real one if available
	# GameManager.combat_manager might be null in this isolated test scene unless MainGame is loaded.
	# Let's create a dummy CombatManager if needed or just use the logic we wrote.

	# Since we are testing logic, let's replicate the check or ensure CombatManager is available.
	# We can instantiate CombatManager.
	var cm_scene = load("res://src/Scenes/Game/CombatManager.tscn")
	var cm = cm_scene.instantiate()
	add_child(cm)
	GameManager.combat_manager = cm

	# Mock projectile spawn (we don't care about visual, just the logic execution)
	# We need to call spawn_projectile and check if unit.guaranteed_crit_stacks decreases.

	# Attack 1
	cm.spawn_projectile(unit, Vector2.ZERO, null)
	assert(unit.guaranteed_crit_stacks == 2, "Should have 2 stacks left")

	# Attack 2
	cm.spawn_projectile(unit, Vector2.ZERO, null)
	assert(unit.guaranteed_crit_stacks == 1, "Should have 1 stack left")

	# Attack 3
	cm.spawn_projectile(unit, Vector2.ZERO, null)
	assert(unit.guaranteed_crit_stacks == 0, "Should have 0 stacks left")

	# Attack 4
	cm.spawn_projectile(unit, Vector2.ZERO, null)
	assert(unit.guaranteed_crit_stacks == 0, "Should remain 0")

	print(" -> PASS")

func test_holy_sword_drop_logic():
	print("Test 4: Holy Sword Drop Logic")

	# Instantiate Drop Layer
	var DropLayerScript = load("res://src/Scripts/UI/ItemDropLayer.gd")
	var drop_layer = Control.new()
	drop_layer.set_script(DropLayerScript)
	add_child(drop_layer)

	# Create a Unit and put it in GridManager (mock)
	var unit_script = load("res://src/Scripts/Unit.gd")
	var unit = unit_script.new()
	unit.unit_data = {"size": Vector2(1,1), "icon": "test"}
	unit.global_position = Vector2(100, 100)
	add_child(unit)

	# Mock GridManager
	# We can't easily use the real GridManager because it tries to setup tiles in _ready which fails due to missing scenes.
	# We should use a dummy GridManager for this test.
	var gm = MockGridManager.new()
	add_child(gm)
	GameManager.grid_manager = gm

	# Manually inject unit into GridManager tiles for detection
	# GridManager uses tiles dict. { key: TileObject }
	# We need a mock Tile object that has a 'unit' property
	var MockTile = RefCounted.new() # Using RefCounted as lightweight object
	MockTile.set_meta("unit", unit)
	# Actually GDScript dynamic object
	# Create a dummy class or object
	var tile_wrapper = MockTileWrapper.new()
	tile_wrapper.unit = unit

	gm.tiles = { "0,0": tile_wrapper } # Key doesn't matter for iteration in DropLayer

	# Define inner class for mock tile

	# Prepare Drop Data
	var item_data = {"item_id": "holy_sword"}
	var drag_data = {"source": "inventory", "item": item_data}

	# Verify _can_drop_data
	var can_drop = drop_layer._can_drop_data(Vector2.ZERO, drag_data)
	assert(can_drop == true, "Should be able to drop holy_sword")

	# Mock GameManager.use_item to avoid side effects or errors if dependencies missing
	# Actually we want to see if unit.apply_holy_sword_buff is called.
	# But we rely on mouse position for _drop_data.
	# Mouse position in headless is (0,0)?
	# We can override get_global_mouse_position behavior? No.
	# But we can modify ItemDropLayer to accept position arg for testing or refactor detection logic.

	# Refactor ItemDropLayer to separate detection logic?
	# Or just invoke `_apply_item_to_unit` directly to verify that part,
	# and trust logic for position (which uses standard godot functions).

	drop_layer._apply_item_to_unit(unit, item_data)

	assert(unit.guaranteed_crit_stacks == 3, "Unit should receive buff from drop")
	print(" -> PASS")

class MockTileWrapper:
	var unit = null

class MockGridManager:
	extends Node
	var tiles = {}
