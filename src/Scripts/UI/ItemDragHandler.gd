extends Control

# Dragging Item Logic
var is_dragging: bool = false
var dragged_item_index: int = -1
var dragged_item_data: Dictionary = {}
var ghost_icon: TextureRect = null
var start_position: Vector2 = Vector2.ZERO

func _process(delta):
	if is_dragging and ghost_icon:
		ghost_icon.global_position = get_global_mouse_position() - (ghost_icon.size / 2)

func start_drag(index: int, item_data: Dictionary, icon_texture: Texture):
	if is_dragging: return

	is_dragging = true
	dragged_item_index = index
	dragged_item_data = item_data

	ghost_icon = TextureRect.new()
	ghost_icon.texture = icon_texture
	ghost_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ghost_icon.size = Vector2(40, 40)
	ghost_icon.modulate.a = 0.7
	ghost_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Add to highest layer (CanvasLayer or just root window)
	var root = get_tree().root
	root.add_child(ghost_icon)
	ghost_icon.global_position = get_global_mouse_position() - (ghost_icon.size / 2)

func end_drag():
	if !is_dragging: return

	is_dragging = false
	if ghost_icon:
		ghost_icon.queue_free()
		ghost_icon = null

	_handle_drop(get_global_mouse_position())

func _handle_drop(mouse_pos: Vector2):
	if !GameManager.grid_manager:
		return

	# Convert global mouse position to grid coordinates using GridManager
	# Assuming grid manager is centered or we can calculate.
	# GridManager logic: tiles key "x,y", position = x * TILE_SIZE, y * TILE_SIZE.
	# GridManager is usually at 0,0 global or centered?
	# In `GridManager.gd`: `to_local(mouse_pos)` might be needed if GridManager moves.

	var grid_mgr = GameManager.grid_manager
	var local_pos = grid_mgr.to_local(mouse_pos)
	var gx = int(round(local_pos.x / Constants.TILE_SIZE))
	var gy = int(round(local_pos.y / Constants.TILE_SIZE))
	var grid_pos = Vector2i(gx, gy)
	var tile_key = grid_mgr.get_tile_key(gx, gy)

	if !grid_mgr.tiles.has(tile_key):
		# Dropped outside grid
		return

	var tile = grid_mgr.tiles[tile_key]

	# Logic 1: Trap Item (has skill_source)
	if dragged_item_data.has("skill_source") and dragged_item_data.skill_source != "":
		if GameManager.execute_skill_effect(dragged_item_data.skill_source, grid_pos):
			_consume_item()

	# Logic 2: Entity Item (e.g. "meat")
	else:
		# If empty tile -> place unit (GridManager.place_unit)
		# We need to map item_id to unit_id.
		# E.g. item_id "meat" might correspond to unit "meat_block" or just use item_id as unit_key if consistent.
		var unit_key = dragged_item_data.item_id

		if tile.unit == null and tile.occupied_by == Vector2i.ZERO:
			if grid_mgr.place_unit(unit_key, gx, gy):
				_consume_item()

		# If friendly unit -> devour
		elif tile.unit != null:
			var target_unit = tile.unit
			# Check if we can feed
			# For now assume any non-trap item can be eaten if it's "meat"?
			# Prompt: "If entity item (e.g. meat)... if on friendly Unit: call targetUnit.devour(), success then consume."
			if target_unit.has_method("devour"):
				target_unit.devour(null) # Devour usually takes a unit, but here we feed an item?
				# Wait, `Unit.gd` `devour(food_unit)` expects a unit instance.
				# I might need to adapt `devour` or pass a dummy object.
				# `Unit.devour` accesses `food_unit.unit_data` etc.
				# I should probably just buff the unit directly or creating a dummy unit is overkill.
				# But `devour` logic: `level += 1, damage += 5...`. It doesn't use `food_unit` except for existence check?
				# `Unit.gd`: `func devour(food_unit): level += 1 ...`. It DOES NOT access food_unit properties in the snippet provided!
				# So passing null might crash if it expects something, but looking at `Unit.gd`:
				# func devour(food_unit):
				#     level += 1
				#     damage += 5
				#     stats_multiplier += 0.2
				#     update_visuals()
				# It ignores the argument. So passing null is fine.

				_consume_item()

func _consume_item():
	if GameManager.inventory_manager:
		GameManager.inventory_manager.remove_item(dragged_item_index)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and !event.pressed:
			end_drag()
