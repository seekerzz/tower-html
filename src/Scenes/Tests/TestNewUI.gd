extends Node2D

@onready var inventory_panel = $VBoxContainer/InventoryPanel
@onready var passive_bar = $VBoxContainer/PassiveSkillBar

func _ready():
	print("TestNewUI: Starting test...")

	# Mock Inventory Manager
	var mock_inv = MockInventoryManager.new()
	if GameManager.inventory_manager == null:
		GameManager.inventory_manager = mock_inv
		print("TestNewUI: Mock Inventory Manager injected.")

	# Mock Grid Manager (for PassiveSkillBar)
	var mock_grid = MockGridManager.new()
	if GameManager.grid_manager == null:
		GameManager.grid_manager = mock_grid
		print("TestNewUI: Mock Grid Manager injected.")

	# Setup Mock Data
	# 1. Inventory Items
	var items = []
	for i in range(5):
		var item = {
			"icon": _create_placeholder_texture(Color.RED if i % 2 == 0 else Color.BLUE),
			"count": i + 1,
			"id": "item_%d" % i
		}
		items.append(item)

	mock_inv.items = items
	# Manually connect signals for InventoryPanel since it was already ready
	if inventory_panel.has_method("connect_signals"):
		inventory_panel.connect_signals()

	mock_inv.emit_signal("inventory_updated", items)
	print("TestNewUI: Inventory Updated signal emitted.")

	# 2. Units for Passive Bar
	var viper = MockUnit.new("viper", 2.0)
	var scorpion = MockUnit.new("scorpion", 3.0)
	mock_grid.tiles["0,0"] = MockTile.new(viper)
	mock_grid.tiles["1,0"] = MockTile.new(scorpion)
	add_child(viper) # Add to tree so timers work
	add_child(scorpion)

	print("TestNewUI: Mock Units created (Viper, Scorpion).")

func _create_placeholder_texture(color):
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)

# --- Mocks ---

class MockInventoryManager extends Node:
	signal inventory_updated(items)
	var items = []
	func get_inventory():
		return items

class MockGridManager extends Node:
	var tiles = {} # key: MockTile

class MockTile:
	var unit = null
	func _init(u):
		unit = u

class MockUnit extends Node:
	var type_key = ""
	var production_timer = null

	func _init(key, time):
		type_key = key
		production_timer = Timer.new()
		production_timer.wait_time = time
		production_timer.one_shot = false

	func _ready():
		add_child(production_timer)
		production_timer.start()

	func get_type():
		return type_key
