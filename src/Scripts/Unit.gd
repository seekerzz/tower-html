extends Node2D

var type_key: String
var level: int = 1
var stats_multiplier: float = 1.0
var cooldown: float = 0.0
var skill_cooldown: float = 0.0
var active_buffs: Array = []
var traits: Array = []
var unit_data: Dictionary

# Stats
var damage: float
var range_val: float
var atk_speed: float

# Grid / Drag logic
var grid_pos: Vector2i = Vector2i.ZERO
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var start_position: Vector2 = Vector2.ZERO
var ghost_node: Node2D = null
var is_in_bench: bool = false
var bench_index: int = -1

signal unit_clicked(unit)

func setup(key: String):
	type_key = key
	unit_data = Constants.UNIT_TYPES[key].duplicate()
	damage = unit_data.damage
	range_val = unit_data.range
	atk_speed = unit_data.atk_speed if "atk_speed" in unit_data else unit_data.atkSpeed

	if "skill" in unit_data and unit_data.skill != "":
		skill_cooldown = 0.0

	update_visuals()

func update_visuals():
	$Label.text = unit_data.icon
	# Size update
	var size = unit_data.size
	$ColorRect.size = Vector2(size.x * 60 - 4, size.y * 60 - 4)
	$ColorRect.position = -($ColorRect.size / 2)
	$Label.position = $ColorRect.position
	$Label.size = $ColorRect.size

	if level > 1:
		$StarLabel.text = "⭐%d" % level
		$StarLabel.show()
	else:
		$StarLabel.hide()

func _process(delta):
	if is_dragging:
		global_position = get_global_mouse_position() + drag_offset
		return

	# Cooldowns should process even if wave is not active?
	# Or only during wave?
	# Typically skills in AutoChess recharge during combat.
	# But if we can use skills manually (active skills), maybe they recharge always?
	# The requirement says "Active Skills... Click to release... Deduct mana".
	# If wave is not active, can we use skills? Probably not.

	if skill_cooldown > 0:
		skill_cooldown -= delta

	if !GameManager.is_wave_active: return

	if cooldown > 0:
		cooldown -= delta

	# Attack Logic (simplified for now, needs Enemy reference)
	# This will be handled by CombatManager or Unit itself if it has access to enemies

func merge_with(other_unit):
	level += 1
	damage *= 1.5
	stats_multiplier += 0.5
	update_visuals()
	# Play animation

func devour(food_unit):
	level += 1
	damage += 5
	stats_multiplier += 0.2
	update_visuals()

func _on_area_2d_input_event(viewport, event, shape_idx):
	if !GameManager.is_wave_active:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			start_drag(get_global_mouse_position())
			unit_clicked.emit(self)

func _input(event):
	if is_dragging:
		if event is InputEventMouseButton and !event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			end_drag()

func start_drag(mouse_pos_global):
	is_dragging = true
	start_position = position
	drag_offset = global_position - mouse_pos_global
	z_index = 100
	create_ghost()

func end_drag():
	is_dragging = false
	z_index = 0
	remove_ghost()

	if !GameManager.grid_manager:
		return_to_start()
		return

	# Check Sell Zone
	if GameManager.ui_manager and GameManager.ui_manager.is_point_in_sell_zone(get_global_mouse_position()):
		# Sell logic
		GameManager.add_gold(floor(unit_data.cost / 2.0)) # 50% refund?
		if is_in_bench:
			GameManager.grid_manager.remove_from_bench(self)
		else:
			# Remove from grid
			GameManager.grid_manager._clear_tiles_occupied(grid_pos.x, grid_pos.y, unit_data.size.x, unit_data.size.y)

		queue_free()
		return

	# Check Bench Zone
	if GameManager.ui_manager:
		var target_bench_idx = GameManager.ui_manager.is_point_in_bench(get_global_mouse_position())
		if target_bench_idx != -1:
			if is_in_bench:
				GameManager.grid_manager.move_in_bench(self, target_bench_idx)
			else:
				# From Grid to Bench
				# We need to see if we can move it to bench
				# Just try to move to that slot
				var target_unit = GameManager.grid_manager.bench_units[target_bench_idx]
				if target_unit == null:
					# Clear grid
					GameManager.grid_manager._clear_tiles_occupied(grid_pos.x, grid_pos.y, unit_data.size.x, unit_data.size.y)

					# Add to bench
					is_in_bench = true
					bench_index = target_bench_idx
					GameManager.grid_manager.bench_units[target_bench_idx] = self

					# Reparent to UI for visual consistency?
					# GridManager is Node2D, MainGUI is Control.
					# If we are in grid, we are child of GridManager.
					# If we move to bench, we should reparent to MainGUI to match other bench units logic.
					reparent(GameManager.ui_manager)
					GameManager.grid_manager._update_bench_unit_position(self)
					start_position = position
				else:
					# Swap with bench unit? Or just fail?
					# Implementing swap grid <-> bench is complex because grid unit might not fit.
					# For now, return to start.
					return_to_start()
			return

	if GameManager.grid_manager:
		GameManager.grid_manager.handle_unit_drop(self)
	else:
		return_to_start()

func create_ghost():
	if ghost_node: return
	ghost_node = Node2D.new()
	var rect = $ColorRect.duplicate()
	var lbl = $Label.duplicate()
	ghost_node.add_child(rect)
	ghost_node.add_child(lbl)
	# Visual copies need to be reset in position because they were children of unit centered at 0,0
	# Wait, rect position is -size/2.
	# If I add them to ghost_node, and set ghost_node position to start_position, it should match.

	get_parent().add_child(ghost_node)
	ghost_node.position = start_position
	ghost_node.modulate.a = 0.5
	ghost_node.z_index = -1

func remove_ghost():
	if ghost_node:
		ghost_node.queue_free()
		ghost_node = null

func return_to_start():
	position = start_position
	# If in bench, ensure it snaps correctly just in case
	if is_in_bench and GameManager.grid_manager:
		GameManager.grid_manager._update_bench_unit_position(self)

func has_active_skill() -> bool:
	return "skill" in unit_data and unit_data.skill != ""

func cast_skill():
	if skill_cooldown > 0 or !has_active_skill(): return

	if GameManager.mana < 10: # Assume constant mana cost for now or from data
		return

	GameManager.mana -= 10
	skill_cooldown = 10.0 # Default CD

	# Simple effects
	var skill_name = unit_data.skill
	print("Unit cast skill: ", skill_name)

	if skill_name == "GlobalStun":
		# Iterate enemies and stun
		# Needs access to enemies.
		pass
	elif skill_name == "FireStorm":
		pass
