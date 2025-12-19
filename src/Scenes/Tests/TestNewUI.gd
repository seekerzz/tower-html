extends Control

@onready var inventory_panel = $VBoxContainer/InventoryPanel
@onready var passive_skill_bar = $VBoxContainer/PassiveSkillBar

var mock_units = []

class MockGridManager:
	var tiles = {}
	signal grid_updated

	func _init(units):
		for i in range(units.size()):
			var tile_key = "tile_%d" % i
			var tile = MockTile.new()
			tile.unit = units[i]
			tiles[tile_key] = tile

class MockTile:
	var unit = null

func _ready():
	print("TestNewUI: Starting verification...")

	# 1. Test InventoryPanel
	var mock_inventory_data = [
		{"key": "meat", "count": 1},
		{"key": "poison", "count": 2},
		{"key": "fang", "count": 5},
		null,
		null,
		null,
		{"key": "unknown", "count": 1},
		null
	]

	if inventory_panel.has_method("_on_inventory_updated"):
		inventory_panel._on_inventory_updated(mock_inventory_data)
		print("TestNewUI: InventoryPanel updated.")

	# 2. Test PassiveSkillBar
	var MockUnitScript = load("res://src/Scenes/Tests/MockUnit.gd")
	if MockUnitScript:
		var u1 = MockUnitScript.new("viper")
		u1.production_timer.wait_time = 3.0

		var u2 = MockUnitScript.new("scorpion")
		u2.production_timer.wait_time = 5.0

		mock_units = [u1, u2]

		# Add units to scene so timers process
		for u in mock_units:
			add_child(u)
			# Start manually if needed or rely on _ready

		# Mock GameManager.grid_manager
		var original_grid_manager = GameManager.grid_manager
		var mock_gm = MockGridManager.new(mock_units)
		GameManager.grid_manager = mock_gm

		# Trigger scan
		passive_skill_bar._scan_units()

		print("TestNewUI: PassiveSkillBar scanned mock units.")

		# Restore (optional, but good practice if we were staying in the same session)
		# GameManager.grid_manager = original_grid_manager
		# But we need it to persist for the duration of the test run visual check.
	else:
		printerr("TestNewUI: Failed to load MockUnit.gd")

	# Auto-quit after 3 seconds for automated verification
	await get_tree().create_timer(3.0).timeout
	print("TestNewUI: Verification complete. Exiting.")
	get_tree().quit()

func _exit_tree():
	# Cleanup if needed
	pass
