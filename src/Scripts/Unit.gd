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

signal unit_clicked(unit)

func setup(key: String):
	type_key = key
	unit_data = Constants.UNIT_TYPES[key].duplicate()
	damage = unit_data.damage
	range_val = unit_data.range
	atk_speed = unit_data.atk_speed if "atk_speed" in unit_data else unit_data.atkSpeed

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

	if !GameManager.is_wave_active: return

	if cooldown > 0:
		cooldown -= delta

	if skill_cooldown > 0:
		skill_cooldown -= delta

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
