extends Node2D

const TILE_SIZE = 64
var tiles = {}

signal tile_clicked(tile_pos, button_index)

func _ready():
	create_initial_grid()

func create_initial_grid():
	create_tile(Vector2i(0, 0), "core")
	create_tile(Vector2i(0, 1), "normal")
	create_tile(Vector2i(0, -1), "normal")
	create_tile(Vector2i(1, 0), "normal")
	create_tile(Vector2i(-1, 0), "normal")

func create_tile(pos: Vector2i, type: String = "normal"):
	if tiles.has(pos):
		return

	var tile_data = {
		"pos": pos,
		"type": type,
		"unit": null,
		"occupied_by": null
	}
	tiles[pos] = tile_data
	queue_redraw()

func _draw():
	for pos in tiles:
		var tile = tiles[pos]
		var rect = Rect2(pos * TILE_SIZE - Vector2i(TILE_SIZE/2, TILE_SIZE/2), Vector2(TILE_SIZE, TILE_SIZE))
		var color = Color(0.18, 0.18, 0.27)

		if tile.type == "core":
			color = Color(0.29, 0.19, 0.27)

		draw_rect(rect, color, true)
		draw_rect(rect, Color(0.29, 0.29, 0.42), false, 2.0)

		if tile.type == "core":
			var font = ThemeDB.fallback_font
			draw_string(font, rect.get_center() + Vector2(-10, 10), "⚛️", HORIZONTAL_ALIGNMENT_CENTER, -1, 32)

func get_tile_at_position(world_pos: Vector2) -> Vector2i:
	var local_pos = to_local(world_pos)
	return Vector2i(round(local_pos.x / TILE_SIZE), round(local_pos.y / TILE_SIZE))

func place_unit(unit_key: String, pos: Vector2i) -> bool:
	if !tiles.has(pos): return false

	var tile = tiles[pos]
	if tile.unit != null or tile.occupied_by != null: return false
	if tile.type == "core": return false

	var unit_scene = load("res://scenes/unit.tscn")
	var unit_instance = unit_scene.instantiate()
	unit_instance.initialize(unit_key)

	unit_instance.grid_pos = pos
	unit_instance.position = Vector2(pos.x * TILE_SIZE, pos.y * TILE_SIZE)
	add_child(unit_instance)
	tile.unit = unit_instance
	return true

func remove_unit(pos: Vector2i):
	if !tiles.has(pos): return
	var tile = tiles[pos]
	if tile.unit:
		tile.unit.queue_free()
		tile.unit = null

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		var tile_pos = get_tile_at_position(get_global_mouse_position())
		if tiles.has(tile_pos):
			tile_clicked.emit(tile_pos, event.button_index)
