extends Node

# Test Inventory Drag Logic
# We can't easily simulate Drag & Drop via script without complex input injection or mocking.
# Instead, we will test the logic of `_get_drag_data`, `_can_drop_data` and `_drop_data` directly.

class MockTile extends Node2D:
	var x: int
	var y: int
	var unit = null
	var occupied_by: Vector2i = Vector2i.ZERO

	func setup(grid_x: int, grid_y: int, tile_type: String = "normal"):
		x = grid_x
		y = grid_y

func test_inventory_drag_data():
	var handler = load("res://src/Scripts/UI/ItemDragHandler.gd").new()
	var item_data = { "item_id": "meat", "count": 1 }
	handler.setup(0, item_data)

	var data = handler._get_drag_data(Vector2.ZERO)

	if data == null:
		print("FAIL: test_inventory_drag_data - Data is null")
		return

	if data.source != "inventory":
		print("FAIL: test_inventory_drag_data - Source is not inventory")
		return

	if data.item.item_id != "meat":
		print("FAIL: test_inventory_drag_data - Item ID mismatch")
		return

	if data.slot_index != 0:
		print("FAIL: test_inventory_drag_data - Slot index mismatch")
		return

	print("PASS: test_inventory_drag_data")

func test_combat_drop_permission():
	var handler = load("res://src/Scripts/UI/TileDropHandler.gd").new()
	GameManager.is_wave_active = true

	var data = { "source": "inventory", "item": {} }
	if not handler._can_drop_data(Vector2.ZERO, data):
		print("FAIL: test_combat_drop_permission - Should allow inventory drop in combat")
		return

	var bench_data = { "source": "bench" }
	if handler._can_drop_data(Vector2.ZERO, bench_data):
		print("FAIL: test_combat_drop_permission - Should NOT allow bench drop in combat")
		return

	print("PASS: test_combat_drop_permission")

func test_meat_devour():
	# Setup mock environment
	var handler = load("res://src/Scripts/UI/TileDropHandler.gd").new()

	# Mock Tile
	var tile = MockTile.new()
	tile.setup(0, 0)
	handler.tile_ref = tile

	# Mock Unit
	var unit = Node2D.new()
	unit.set_script(load("res://src/Scripts/Unit.gd"))
	unit.unit_data = { "hp": 100, "damage": 10, "size": Vector2(1,1), "icon": "?" }
	unit.damage = 10
	unit.level = 1
	tile.unit = unit

	# Mock Inventory
	# We assume GameManager.inventory_manager is set up or we mock it
	var inv_mgr = load("res://src/Scripts/Managers/InventoryManager.gd").new()
	GameManager.inventory_manager = inv_mgr
	inv_mgr.add_item({ "item_id": "meat", "count": 1 })

	# Initial check
	if inv_mgr.get_item_count(0) != 1:
		print("FAIL: test_meat_devour - Setup failed, meat count mismatch")
		return

	# Execute Drop
	var data = { "source": "inventory", "item": { "item_id": "meat" }, "slot_index": 0 }
	handler._drop_data(Vector2.ZERO, data)

	# Assertions
	if inv_mgr.get_item_count(0) != 0:
		print("FAIL: test_meat_devour - Meat not consumed")
		return

	if unit.damage <= 10: # Devour adds 5 damage
		print("FAIL: test_meat_devour - Unit did not devour (damage check). Damage: ", unit.damage)
		return

	print("PASS: test_meat_devour")

func _ready():
	print("Running TestInventoryDrag...")
	test_inventory_drag_data()
	test_combat_drop_permission()
	test_meat_devour()
	print("Tests Completed.")
	get_tree().quit()
