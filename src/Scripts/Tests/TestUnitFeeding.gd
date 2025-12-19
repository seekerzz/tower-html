extends Node

# --- Mocks ---
class MockInventoryManager:
	var items = {} # slot -> item
	var remove_called = false
	var removed_slot = -1

	func remove_item(slot_index):
		remove_called = true
		removed_slot = slot_index

class MockGridManager:
	var tiles = {} # key -> tile
	var spawn_trap_called = false
	var trap_pos = Vector2i.ZERO
	var trap_type = ""

	func get_tile_key(x, y):
		return "%d,%d" % [x, y]

	func spawn_trap_custom(pos, type):
		spawn_trap_called = true
		trap_pos = pos
		trap_type = type

class MockUnit:
	extends Node2D
	var devour_called = false
	var grid_pos = Vector2i(0, 0)

	func devour(food):
		devour_called = true

class MockTile:
	extends Node2D
	var unit = null
	var occupied_by = Vector2i.ZERO
	var x = 0
	var y = 0

# --- Test Script ---

var unit_drag_handler
var tile_drop_handler
var mock_unit
var mock_tile
var mock_inv_manager
var mock_grid_manager

var original_inv_manager
var original_grid_manager

func _ready():
	print("Running TestUnitFeeding...")

	# Setup GameManager mocks
	mock_inv_manager = MockInventoryManager.new()
	mock_grid_manager = MockGridManager.new()

	# Inject mocks into GameManager
	if GameManager:
		original_inv_manager = GameManager.inventory_manager
		original_grid_manager = GameManager.grid_manager

		GameManager.inventory_manager = mock_inv_manager
		GameManager.grid_manager = mock_grid_manager
	else:
		print("Error: GameManager not found!")
		get_tree().quit(1)
		return

	_test_can_drop_meat_on_unit()
	_test_can_drop_trap_on_unit()
	_test_tile_drop_ignores_meat()

	# Restore GameManager
	if GameManager:
		GameManager.inventory_manager = original_inv_manager
		GameManager.grid_manager = original_grid_manager

	print("All Tests Completed.")
	get_tree().quit()

func _test_can_drop_meat_on_unit():
	print("Test: Can Drop Meat On Unit")

	mock_unit = MockUnit.new()
	add_child(mock_unit)

	unit_drag_handler = preload("res://src/Scripts/UI/UnitDragHandler.gd").new()
	mock_unit.add_child(unit_drag_handler)
	unit_drag_handler.setup(mock_unit)

	var data = { "source": "inventory", "item": { "item_id": "meat" }, "slot_index": 0 }

	var can_drop = unit_drag_handler._can_drop_data(Vector2.ZERO, data)
	if can_drop:
		print("  [PASS] _can_drop_data returned true for meat.")
	else:
		print("  [FAIL] _can_drop_data returned false for meat.")

	# Test drop action
	unit_drag_handler._drop_data(Vector2.ZERO, data)

	if mock_unit.devour_called:
		print("  [PASS] Unit.devour called.")
	else:
		print("  [FAIL] Unit.devour NOT called.")

	if mock_inv_manager.remove_called and mock_inv_manager.removed_slot == 0:
		print("  [PASS] Item removed from inventory.")
	else:
		print("  [FAIL] Item NOT removed from inventory.")

	# Cleanup
	mock_unit.queue_free()
	mock_inv_manager.remove_called = false
	mock_unit = null

func _test_can_drop_trap_on_unit():
	print("Test: Can Drop Trap On Unit")

	mock_unit = MockUnit.new()
	add_child(mock_unit)

	unit_drag_handler = preload("res://src/Scripts/UI/UnitDragHandler.gd").new()
	mock_unit.add_child(unit_drag_handler)
	unit_drag_handler.setup(mock_unit)

	var data = { "source": "inventory", "item": { "item_id": "poison_trap" }, "slot_index": 1 }

	var can_drop = unit_drag_handler._can_drop_data(Vector2.ZERO, data)
	if not can_drop:
		print("  [PASS] _can_drop_data returned false for trap.")
	else:
		print("  [FAIL] _can_drop_data returned true for trap.")

	# Cleanup
	mock_unit.queue_free()

func _test_tile_drop_ignores_meat():
	print("Test: Tile Drop Ignores Meat")

	mock_tile = MockTile.new()
	mock_unit = MockUnit.new()
	mock_tile.unit = mock_unit
	add_child(mock_tile)

	tile_drop_handler = preload("res://src/Scripts/UI/TileDropHandler.gd").new()
	mock_tile.add_child(tile_drop_handler)
	tile_drop_handler.setup(mock_tile)

	# Reset mocks
	mock_inv_manager.remove_called = false
	mock_unit.devour_called = false

	var data = { "source": "inventory", "item": { "item_id": "meat" }, "slot_index": 2 }

	# Directly calling _handle_inventory_drop since that's where the logic was
	tile_drop_handler._handle_inventory_drop(data)

	if not mock_inv_manager.remove_called:
		print("  [PASS] Inventory item NOT removed by TileDropHandler.")
	else:
		print("  [FAIL] Inventory item removed by TileDropHandler.")

	if not mock_unit.devour_called:
		print("  [PASS] Unit.devour NOT called by TileDropHandler.")
	else:
		print("  [FAIL] Unit.devour called by TileDropHandler.")

	# Cleanup
	mock_tile.queue_free()
