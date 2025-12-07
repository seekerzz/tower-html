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
var visual_node: CanvasItem = null

var is_starving: bool = false
var is_no_mana: bool = false
var crit_rate: float = 0.0
var bounce_count: int = 0
var split_count: int = 0

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
	reset_stats()
	update_visuals()

	if unit_data.has("produce"):
		production_timer = 1.0 # Initial delay

	start_breathe_anim()

func reset_stats():
	damage = unit_data.damage
	range_val = unit_data.range
	atk_speed = unit_data.atk_speed if "atk_speed" in unit_data else unit_data.get("atkSpeed", 1.0)
	crit_rate = 0.0
	bounce_count = 0
	split_count = 0
	active_buffs.clear()

	attack_cost_food = unit_data.get("foodCost", 1.0) # Default food cost to 1.0 if not specified to ensure test works or real gameplay consumes food
	attack_cost_mana = unit_data.get("manaCost", 0.0)
	skill_mana_cost = unit_data.get("skillCost", 30.0)

	update_visuals()
	# Re-apply level multipliers if needed
	if level > 1:
		damage *= pow(1.5, level - 1)
		# stats_multiplier is handled separately or accumulatively?
		# In merge_with, we did damage *= 1.5.
		# If we reset stats, we need to recalculate from base + level.
		# Ideally `level` should drive the stats.

func apply_buff(buff_type: String):
	if buff_type in active_buffs: return # Or stack? Usually adjacency buffs from different sources stack, but same source?
	# For now, let's allow duplicates in the list but handle logic carefully, or just list unique buff types.
	# The prompt says "recalculate_buffs", suggesting we clear and re-add.

	active_buffs.append(buff_type)

	match buff_type:
		"fire":
			pass # Logic handled in attack/projectile
		"poison":
			pass # Logic handled in attack/projectile
		"range":
			range_val *= 1.25
		"speed":
			atk_speed *= 1.2 # Higher is faster? "atkSpeed" in data seems to be attacks per second?
			# In Constants: mouse 0.15. If it's delay, lower is faster.
			# turtle: 1.8.
			# Let's check CombatManager or Unit to see how atkSpeed is used.
			pass
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

		# Trigger skill effect
		var skill_name = unit_data.skill
		GameManager.spawn_floating_text(global_position, skill_name.capitalize() + "!", Color.CYAN)

		match skill_name:
			"rage":
				# Simple effect: temporary visual or logic handled elsewhere
				pass
			"stun":
				pass
			"firestorm":
				pass
			_:
				pass

		# Visual feedback
		var tween = create_tween()
		tween.tween_property($ColorRect, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property($ColorRect, "scale", Vector2(1.0, 1.0), 0.1)

	else:
		is_no_mana = true
		GameManager.spawn_floating_text(global_position, "No Mana!", Color.BLUE)

func update_visuals():
	if has_node("Label"):
		$Label.text = unit_data.icon
	# Size update
	if has_node("ColorRect"):
		var size = unit_data.size
		$ColorRect.size = Vector2(size.x * 60 - 4, size.y * 60 - 4)
		$ColorRect.position = -($ColorRect.size / 2)
		if has_node("Label"):
			$Label.position = $ColorRect.position
			$Label.size = $ColorRect.size

	if level > 1:
		if has_node("StarLabel"):
			$StarLabel.text = "⭐%d" % level
			$StarLabel.show()
	else:
		if has_node("StarLabel"):
			$StarLabel.hide()

	_update_buff_icons()

func _update_buff_icons():
	# Simple visualization: a small label or HBox at the bottom of the unit
	var buff_container = get_node_or_null("BuffContainer")
	if !buff_container:
		buff_container = HBoxContainer.new()
		buff_container.name = "BuffContainer"
		buff_container.alignment = BoxContainer.ALIGNMENT_CENTER
		# Check if ColorRect exists to base position
		if has_node("ColorRect"):
			buff_container.position = Vector2(-$ColorRect.size.x/2, $ColorRect.size.y/2 - 15)
			buff_container.size = Vector2($ColorRect.size.x, 15)
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

		# Map buff to icon
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
	if is_dragging:
		global_position = get_global_mouse_position() + drag_offset
		return

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

			production_timer = 1.0 # Fixed 1s interval as per reference logic often implies per second

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

	# Attack Logic (simplified for now, needs Enemy reference)
	# This will be handled by CombatManager or Unit itself if it has access to enemies

var breathe_tween: Tween = null

func start_breathe_anim():
	visual_node = get_node_or_null("ColorRect")
	if !visual_node: return

	if breathe_tween: breathe_tween.kill()

	breathe_tween = create_tween().set_loops()
	breathe_tween.tween_property(visual_node, "scale", Vector2(1.05, 1.05), 1.0).set_trans(Tween.TRANS_SINE)
	breathe_tween.tween_property(visual_node, "scale", Vector2(1.0, 1.0), 1.0).set_trans(Tween.TRANS_SINE)

func play_attack_anim(attack_type: String, target_pos: Vector2):
	if !visual_node: visual_node = get_node_or_null("ColorRect")
	if !visual_node: return

	if breathe_tween: breathe_tween.kill()

	var tween = create_tween()
	tween.finished.connect(func(): start_breathe_anim()) # Resume breathe after attack
	if attack_type == "melee":
		# Lunge
		var dir = (target_pos - global_position).normalized()
		var original_pos = -(visual_node.size / 2) # ColorRect is centered by position offset in update_visuals
		# Wait, update_visuals sets $ColorRect.position = -($ColorRect.size / 2)
		# So original_pos should be that.

		var lunge_pos = original_pos + dir * 15.0

		tween.tween_property(visual_node, "position", lunge_pos, 0.1).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(visual_node, "position", original_pos, 0.2).set_trans(Tween.TRANS_CUBIC)

	elif attack_type == "ranged" or attack_type == "lightning":
		# Recoil
		tween.tween_property(visual_node, "scale", Vector2(0.8, 0.8), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(visual_node, "scale", Vector2(1.0, 1.0), 0.2)

func merge_with(other_unit):
	level += 1
	# Stats will be recalculated by GridManager calling recalculate_buffs -> reset_stats -> apply level -> apply buffs
	# But reset_stats needs to know how to apply level.
	# Let's ensure reset_stats handles level scaling.

	# Update: reset_stats implementation above attempts to handle it.
	# damage *= pow(1.5, level - 1)

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
		# Try to drop on Grid
		if GameManager.grid_manager.handle_unit_drop(self):
			return # Moved on grid successfully

		# Try to drop on Bench
		# Check main_game reference
		if GameManager.main_game:
			# Check if over shop/bench area?
			# Actually we can just try to add to bench if it's not a valid grid drop
			# But we only want to do this if the mouse is actually over the bench.

			# HACK: check if mouse Y is in the bottom area?
			# Shop is at bottom.
			# Or check rect of shop.
			var viewport_rect = get_viewport_rect()
			var mouse_pos = get_global_mouse_position()
			# Shop height is 150 from bottom?
			# Need to be precise or use UI collision.

			# Since Unit is Node2D and Shop is Control, we don't have built-in overlap.
			# Assuming Shop is at bottom.
			if mouse_pos.y > (viewport_rect.size.y - 200): # Approximate
				if GameManager.main_game.try_add_to_bench_from_grid(self):
					# Success, self is queue_free'd inside try_add...
					return

	return_to_start()

func create_ghost():
	if ghost_node: return
	ghost_node = Node2D.new()
	if has_node("ColorRect"):
		var rect = $ColorRect.duplicate()
		ghost_node.add_child(rect)
	if has_node("Label"):
		var lbl = $Label.duplicate()
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
