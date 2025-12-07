extends Node2D

const TILE_SCENE = preload("res://src/Scenes/Game/Tile.tscn")
const UNIT_SCENE = preload("res://src/Scenes/Game/Unit.tscn")
const TILE_SIZE = 60

var tiles: Dictionary = {} # Key: "x,y", Value: Tile Instance
var selected_unit = null

func _ready():
	GameManager.grid_manager = self
	create_initial_grid()

func create_initial_grid():
	create_tile(0, 0, "core")
	create_tile(0, 1)
	create_tile(0, -1)
	create_tile(1, 0)
	create_tile(-1, 0)

func create_tile(x: int, y: int, type: String = "normal"):
	var key = get_tile_key(x, y)
	if tiles.has(key): return

	var tile = TILE_SCENE.instantiate()
	tile.setup(x, y, type)
	tile.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	add_child(tile)
	tiles[key] = tile

	tile.tile_clicked.connect(_on_tile_clicked)

func get_tile_key(x: int, y: int) -> String:
	return "%d,%d" % [x, y]

func place_unit(unit_key: String, x: int, y: int) -> bool:
	var key = get_tile_key(x, y)
	if !tiles.has(key): return false

	var tile = tiles[key]
	if tile.unit != null or tile.occupied_by != Vector2i.ZERO: return false # Occupied

	var unit = UNIT_SCENE.instantiate()
	unit.setup(unit_key)

	# Check size
	var w = unit.unit_data.size.x
	var h = unit.unit_data.size.y

	if !can_place_unit(x, y, w, h):
		unit.queue_free()
		return false

	add_child(unit)
	unit.position = tile.position + Vector2((w-1) * TILE_SIZE * 0.5, (h-1) * TILE_SIZE * 0.5)

	# Mark tiles as occupied
	for dx in range(w):
		for dy in range(h):
			var t_key = get_tile_key(x + dx, y + dy)
			var t = tiles[t_key]
			if dx == 0 and dy == 0:
				t.unit = unit
			else:
				t.occupied_by = Vector2i(x, y)

	return true

func can_place_unit(x: int, y: int, w: int, h: int, exclude_unit = null) -> bool:
	for dx in range(w):
		for dy in range(h):
			var key = get_tile_key(x + dx, y + dy)
			if !tiles.has(key): return false
			var tile = tiles[key]
			if tile.type == "core": return false
			if tile.unit and tile.unit != exclude_unit: return false
			if tile.occupied_by != Vector2i.ZERO and (!exclude_unit or tile.occupied_by != Vector2i(x,y)): # Simplified check
				return false
	return true

func _on_tile_clicked(tile):
	if GameManager.is_wave_active: return
	# Handling selection/movement logic would go here
	print("Clicked tile: ", tile.x, ",", tile.y)
