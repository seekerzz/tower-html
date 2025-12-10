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
var attack_cost_food: float = 0.0
var attack_cost_mana: float = 0.0
var skill_mana_cost: float = 30.0

var production_timer: float = 0.0

# Visual Holder for animations and structure
var visual_holder: Node2D = null
# Keeping this for compatibility if other scripts access it, though it was local-ish before
var visual_node: CanvasItem = null

var is_starving: bool = false
var is_no_mana: bool = false
var crit_rate: float = 0.0
var bounce_count: int = 0
var split_count: int = 0

# Grid
var grid_pos: Vector2i = Vector2i.ZERO
var start_position: Vector2 = Vector2.ZERO

# Missing variables required for the old drag logic at the bottom to compile
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var ghost_node: Node2D = null

const DRAG_HANDLER_SCRIPT = preload("res://src/Scripts/UI/UnitDragHandler.gd")

signal unit_clicked(unit)

func _ready():
	_ensure_visual_hierarchy()
	# If unit_data is already populated (e.g. from scene or prior setup), update visuals
	if !unit_data.is_empty():
		update_visuals()

func _ensure_visual_hierarchy():
	if visual_holder and is_instance_valid(visual_holder):
		return

	visual_holder = get_node_or_null("VisualHolder")
	if !visual_holder:
		visual_holder = Node2D.new()
		visual_holder.name = "VisualHolder"
		add_child(visual_holder)

		# Move existing visual elements into holder
		# NOTE: Exclude "ColorRect" from moving to visual_holder to keep it static (not affected by breathe/attack anims)
		var visual_elements = ["Label", "StarLabel"]
		for child_name in visual_elements:
			var child = get_node_or_null(child_name)
			if child:
				remove_child(child)
				visual_holder.add_child(child)

		# Ensure visual_holder is rendered *after* ColorRect (so icons are on top)
		# Since ColorRect stays in root, and visual_holder is added via add_child (which appends to end),
		# check if ColorRect exists and make sure visual_holder is above it.
		var color_rect = get_node_or_null("ColorRect")
		if color_rect:
			# If color_rect index is greater than visual_holder, swap or move visual_holder
			if color_rect.get_index() > visual_holder.get_index():
				move_child(visual_holder, color_rect.get_index() + 1)

func setup(key: String):
	_ensure_visual_hierarchy()
	type_key = key
	unit_data = Constants.UNIT_TYPES[key].duplicate()
	reset_stats()
	update_visuals()

	# --- Merged Logic Start ---
	if unit_data.has("produce"):
		production_timer = 1.0

	start_breathe_anim()

	var drag_handler = Control.new()
	drag_handler.set_script(DRAG_HANDLER_SCRIPT)
	add_child(drag_handler)
	drag_handler.setup(self)
	# --- Merged Logic End ---

func reset_stats():
	damage = unit_data.damage
	range_val = unit_data.range
	atk_speed = unit_data.atk_speed if "atk_speed" in unit_data else unit_data.get("atkSpeed", 1.0)
	crit_rate = 0.0
	bounce_count = 0
	split_count = 0
	active_buffs.clear()

	attack_cost_food = unit_data.get("foodCost", 1.0)
	attack_cost_mana = unit_data.get("manaCost", 0.0)
	skill_mana_cost = unit_data.get("skillCost", 30.0)

	update_visuals()
	if level > 1:
		damage *= pow(1.5, level - 1)

func apply_buff(buff_type: String):
	if buff_type in active_buffs: return
	active_buffs.append(buff_type)

	match buff_type:
		"range":
			range_val *= 1.25
		"speed":
			atk_speed *= 1.2
		"crit":
			crit_rate += 0.25
		"bounce":
			bounce_count += 1
		"split":
			split_count += 1

func activate_skill():
	if !unit_data.has("skill"): return

	if skill_cooldown > 0:
		return

	if GameManager.consume_resource("mana", skill_mana_cost):
		is_no_mana = false
		skill_cooldown = unit_data.get("skillCd", 10.0)

		var skill_name = unit_data.skill
		GameManager.spawn_floating_text(global_position, skill_name.capitalize() + "!", Color.CYAN)

		# Find ColorRect in self, or fallback
		var color_rect = get_node_or_null("ColorRect")
		if !color_rect and visual_holder:
			color_rect = visual_holder.get_node_or_null("ColorRect")

		if color_rect:
			var tween = create_tween()
			tween.tween_property(color_rect, "scale", Vector2(1.2, 1.2), 0.1)
			tween.tween_property(color_rect, "scale", Vector2(1.0, 1.0), 0.1)

	else:
		is_no_mana = true
		GameManager.spawn_floating_text(global_position, "No Mana!", Color.BLUE)

func update_visuals():
	_ensure_visual_hierarchy()
	var label = visual_holder.get_node_or_null("Label")

	# ColorRect should now be in self, but check logic to be safe
	var color_rect = get_node_or_null("ColorRect")
	if !color_rect and visual_holder:
		color_rect = visual_holder.get_node_or_null("ColorRect")

	var star_label = visual_holder.get_node_or_null("StarLabel")

	if label:
		label.text = unit_data.icon
	
	# Size update
	if color_rect:
		var size = unit_data.size
		color_rect.size = Vector2(size.x * 60 - 4, size.y * 60 - 4)
		color_rect.position = -(color_rect.size / 2) # Center inside parent (Unit node)

		if label:
			label.position = color_rect.position
			label.size = color_rect.size
			label.pivot_offset = label.size / 2

	if level > 1:
		if star_label:
			star_label.text = "⭐%d" % level
			star_label.show()
	else:
		if star_label:
			star_label.hide()

	_update_buff_icons()

func _update_buff_icons():
	var buff_container = get_node_or_null("BuffContainer")
	if !buff_container:
		buff_container = HBoxContainer.new()
		buff_container.name = "BuffContainer"
		buff_container.alignment = BoxContainer.ALIGNMENT_CENTER

		# Find ColorRect in self first, then fallback
		var color_rect = get_node_or_null("ColorRect")
		if !color_rect and visual_holder:
			color_rect = visual_holder.get_node_or_null("ColorRect")

		if color_rect:
			buff_container.position = Vector2(-color_rect.size.x/2, color_rect.size.y/2 - 15)
			buff_container.size = Vector2(color_rect.size.x, 15)
		else:
			buff_container.position = Vector2(0, 20)

		buff_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(buff_container)

	for child in buff_container.get_children():
		child.queue_free()

	for buff in active_buffs:
		var lbl = Label.new()
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		var icon = "?"
		match buff:
			"fire": icon = "🔥"
			"poison": icon = "🧪"
			"range": icon = "🔭"
			"speed": icon = "⚡"
			"crit": icon = "💥"
			"bounce": icon = "🪞"
			"split": icon = "💠"

		lbl.text = icon
		buff_container.add_child(lbl)

func _process(delta):
	if !GameManager.is_wave_active: return

	# Production Logic
	if unit_data.has("produce"):
		production_timer -= delta
		if production_timer <= 0:
			var p_type = unit_data.produce
			var p_amt = unit_data.get("produceAmt", 1)

			GameManager.add_resource(p_type, p_amt)

			var icon = "🌽" if p_type == "food" else "💎"
			var color = Color.YELLOW if p_type == "food" else Color.CYAN
			GameManager.spawn_floating_text(global_position, "+%d%s" % [p_amt, icon], color)

			production_timer = 1.0

	if cooldown > 0:
		cooldown -= delta

	if skill_cooldown > 0:
		skill_cooldown -= delta

	if is_starving:
		modulate = Color(0.5, 0.5, 0.5, 1.0)
	elif is_no_mana and unit_data.has("skill"):
		modulate = Color(0.7, 0.7, 1.0, 1.0)
	else:
		modulate = Color.WHITE

var breathe_tween: Tween = null

func start_breathe_anim():
	if !visual_holder: return

	if breathe_tween: breathe_tween.kill()

	# Start loop
	breathe_tween = create_tween().set_loops()
	breathe_tween.tween_property(visual_holder, "scale", Vector2(1.05, 1.05), 1.0).set_trans(Tween.TRANS_SINE)
	breathe_tween.tween_property(visual_holder, "scale", Vector2(1.0, 1.0), 1.0).set_trans(Tween.TRANS_SINE)

func play_attack_anim(attack_type: String, target_pos: Vector2):
	if !visual_holder: return

	if breathe_tween: breathe_tween.kill()

	var tween = create_tween()

	if attack_type == "melee":
		# Lunge
		var dir = (target_pos - global_position).normalized()
		var original_pos = Vector2.ZERO # visual_holder is centered at 0,0 locally
		var lunge_pos = original_pos + dir * 15.0

		tween.tween_property(visual_holder, "position", lunge_pos, 0.1).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(visual_holder, "position", original_pos, 0.2).set_trans(Tween.TRANS_CUBIC)
		# Smoothly reset scale in parallel if needed, though usually pos only
		tween.parallel().tween_property(visual_holder, "scale", Vector2.ONE, 0.3)

	elif attack_type == "ranged" or attack_type == "lightning":
		# Recoil
		tween.tween_property(visual_holder, "scale", Vector2(0.8, 0.8), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(visual_holder, "scale", Vector2(1.0, 1.0), 0.2)
		# Reset position in parallel just in case
		tween.parallel().tween_property(visual_holder, "position", Vector2.ZERO, 0.3)

	tween.finished.connect(func(): start_breathe_anim())

func merge_with(other_unit):
	level += 1
	update_visuals()

func devour(food_unit):
	level += 1
	damage += 5
	stats_multiplier += 0.2
	update_visuals()

func _on_area_2d_input_event(viewport, event, shape_idx):
	if !GameManager.is_wave_active:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			unit_clicked.emit(self)

func _on_area_2d_mouse_entered():
	var current_stats = {
		"level": level,
		"damage": damage,
		"range": range_val,
		"atk_speed": atk_speed
	}
	GameManager.show_tooltip.emit(unit_data, current_stats, active_buffs, global_position)

func _on_area_2d_mouse_exited():
	GameManager.hide_tooltip.emit()

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
		if GameManager.grid_manager.handle_unit_drop(self):
			return

		if GameManager.main_game:
			var viewport_rect = get_viewport_rect()
			var mouse_pos = get_global_mouse_position()
			if mouse_pos.y > (viewport_rect.size.y - 200):
				if GameManager.main_game.try_add_to_bench_from_grid(self):
					return

	return_to_start()

func create_ghost():
	if ghost_node: return
	ghost_node = Node2D.new()

	var color_rect = get_node_or_null("ColorRect")
	if !color_rect and visual_holder:
		color_rect = visual_holder.get_node_or_null("ColorRect")

	if color_rect:
		var rect = color_rect.duplicate()
		ghost_node.add_child(rect)

	var label = visual_holder.get_node_or_null("Label") if visual_holder else get_node_or_null("Label")
	if label:
		var lbl = label.duplicate()
		ghost_node.add_child(lbl)

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
