extends Node2D

var type_key: String
var level: int = 1
var stats_multiplier: float = 1.0
var cooldown: float = 0.0
var skill_cooldown: float = 0.0
var active_buffs: Array = []
var buff_sources: Dictionary = {} # Key: buff_type, Value: source_unit (Node2D)
var traits: Array = []
var unit_data: Dictionary

# Stats
var damage: float
var range_val: float
var atk_speed: float
var attack_cost_food: float = 0.0
var attack_cost_mana: float = 0.0
var skill_mana_cost: float = 30.0

var max_hp: float = 0.0

var production_timer: float = 0.0
var max_production_timer: float = 1.0

# Visual Holder for animations and structure
var visual_holder: Node2D = null
# Keeping this for compatibility if other scripts access it, though it was local-ish before
var visual_node: CanvasItem = null

var is_starving: bool = false
var is_no_mana: bool = false
var crit_rate: float = 0.0
var crit_dmg: float = 1.5
var bounce_count: int = 0
var split_count: int = 0

# Grid
var grid_pos: Vector2i = Vector2i.ZERO
var start_position: Vector2 = Vector2.ZERO

# Interaction
var interaction_target_pos = null # Vector2i or null

# Missing variables required for the old drag logic at the bottom to compile
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var ghost_node: Node2D = null
var is_hovered: bool = false
var focus_target: Node2D = null
var focus_stacks: int = 0

# Skill Logic
var skill_active_timer: float = 0.0
var original_atk_speed: float = 0.0
var _is_skill_highlight_active: bool = false
var _highlight_color: Color = Color.WHITE

var connection_overlay: Node2D = null

const MAX_LEVEL = 3
const DRAG_HANDLER_SCRIPT = preload("res://src/Scripts/UI/UnitDragHandler.gd")

signal unit_clicked(unit)

func _start_skill_cooldown(base_duration: float):
	if GameManager.cheat_fast_cooldown and base_duration > 1.0:
		skill_cooldown = 1.0
	else:
		skill_cooldown = base_duration

func _ready():
	_ensure_visual_hierarchy()

	connection_overlay = Node2D.new()
	connection_overlay.name = "ConnectionOverlay"
	connection_overlay.z_index = 100
	connection_overlay.draw.connect(_on_connection_overlay_draw)
	add_child(connection_overlay)

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
		var visual_elements = ["Label", "StarLabel"]
		for child_name in visual_elements:
			var child = get_node_or_null(child_name)
			if child:
				remove_child(child)
				visual_holder.add_child(child)

	var highlight = visual_holder.get_node_or_null("HighlightBorder")
	if !highlight:
		highlight = ReferenceRect.new()
		highlight.name = "HighlightBorder"
		highlight.border_width = 4.0
		highlight.editor_only = false
		highlight.visible = false
		highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
		visual_holder.add_child(highlight)

	if unit_data and unit_data.has("size"):
		var size_val = unit_data["size"]
		var target_size = Vector2(size_val.x * Constants.TILE_SIZE - 4, size_val.y * Constants.TILE_SIZE - 4)
		highlight.size = target_size
		highlight.position = -(target_size / 2)



func setup(key: String):
	_ensure_visual_hierarchy()
	type_key = key
	unit_data = Constants.UNIT_TYPES[key].duplicate()
	# reset_stats will handle reading stats from levels
	reset_stats()
	update_visuals()

	# Preserve interaction target if reloading/upgrading?
	# Actually setup is called on creation.
	# If we upgrade (merge), we might need to copy it, but merge creates new unit or modifies existing?
	# Merge in GridManager: target_unit.merge_with(temp_unit). Unit instance persists.
	# So interaction_target_pos is preserved in target_unit.

	# --- Merged Logic Start ---
	if unit_data.has("produce"):
		production_timer = 1.0
		max_production_timer = 1.0

	if unit_data.has("production_type") and unit_data["production_type"] == "item":
		max_production_timer = unit_data.get("production_interval", 5.0)
		production_timer = max_production_timer

	# Cow Healing logic setup - Removed implicit setup here, handled in _process or logic
	if unit_data.has("skill") and unit_data.skill == "milk_aura":
		production_timer = 5.0 # Keep this for PASSIVE healing if any, or just skill logic?
		max_production_timer = 5.0
		# Original Unit.gd had a passive milk_aura logic: "Cow Milk Aura Logic" block in _process
		# The new requirements say: "If Cow and skill active: ... extra call GameManager.damage_core(-200 * delta)"
		# It seems the passive "milk_aura" (every 5s heal 50) is still there unless I remove it?
		# The prompt didn't say to remove the passive.

	start_breathe_anim()

	var drag_handler = Control.new()
	drag_handler.set_script(DRAG_HANDLER_SCRIPT)
	add_child(drag_handler)
	drag_handler.setup(self)
	# --- Merged Logic End ---

func take_damage(amount: float, source_enemy = null):
	# Handle Reflect (Hedgehog)
	if unit_data.get("trait") == "reflect":
		var reflect_pct = unit_data.get("reflect_percent", 0.3)
		var reflect_dmg = amount * reflect_pct
		if source_enemy and is_instance_valid(source_enemy):
			source_enemy.take_damage(reflect_dmg, self, "physical")
			GameManager.spawn_floating_text(global_position, "Reflect!", Color.RED)

	# Handle Flat Reduction (Iron Turtle)
	if unit_data.get("trait") == "flat_reduce":
		var reduce = unit_data.get("flat_amount", 0)
		amount = max(1, amount - reduce)
		# Visual feedback for block?
		# GameManager.spawn_floating_text(global_position, "Block", Color.GRAY)

	# Shared Health Logic: Unit acts as a wall/entity linked to Core
	GameManager.damage_core(amount)

	# Trigger breathe anim or shake to show impact
	if visual_holder:
		var tween = create_tween()
		tween.tween_property(visual_holder, "position", Vector2(randf_range(-2,2), randf_range(-2,2)), 0.05).set_trans(Tween.TRANS_BOUNCE)
		tween.tween_property(visual_holder, "position", Vector2.ZERO, 0.05)


func reset_stats():
	# Retrieve stats from levels dict if available
	var stats = {}
	if unit_data.has("levels") and unit_data["levels"].has(str(level)):
		stats = unit_data["levels"][str(level)]
	else:
		# Fallback to root (should not happen with refactor, but safe)
		stats = unit_data

	# Load core stats
	damage = stats.get("damage", unit_data.get("damage", 0))

	# Update production interval from mechanics if available
	if unit_data.has("production_type") and unit_data["production_type"] == "item":
		var base_interval = unit_data.get("production_interval", 5.0)
		var new_interval = base_interval

		if stats.has("mechanics") and stats["mechanics"].has("production_interval"):
			new_interval = stats["mechanics"]["production_interval"]

		max_production_timer = new_interval
		# Do not reset current timer to avoid exploit/punishment on upgrade,
		# but ensure it's not above new max if we want to be strict.

	# Handle hp: if max_hp changes, should we heal?
	# For now, just set max_hp. Current HP handling is done by GameManager (Core Health) or Barricades.
	# But some units act as walls? If so, they need local HP.
	# The current Unit.gd seems to delegate damage to core usually, but let's set max_hp.
	max_hp = stats.get("hp", unit_data.get("hp", 0))

	# Non-leveled stats (unless moved to levels, which range/atkSpeed weren't in my script)
	range_val = unit_data.get("range", 0)
	atk_speed = unit_data.get("atkSpeed", 1.0)

	crit_rate = unit_data.get("crit_rate", 0.1)
	crit_dmg = unit_data.get("crit_dmg", 1.5)

	# Costs
	attack_cost_food = unit_data.get("foodCost", 1.0)
	attack_cost_mana = unit_data.get("manaCost", 0.0)
	skill_mana_cost = unit_data.get("skillCost", 30.0)

	# Mechanics from Level
	if stats.has("mechanics"):
		var mechs = stats["mechanics"]
		if mechs.has("crit_rate_bonus"):
			crit_rate += mechs["crit_rate_bonus"]
		# Add other mechanics here
		# e.g. multi_shot_chance is handled in combat/projectile logic,
		# so we might need to store it or apply it to a variable if Unit.gd handles shooting.
		# Unit.gd doesn't seem to fire projectiles directly, usually CombatManager or Projectile.gd?
		# Wait, Unit.gd doesn't have attack logic loop in _process?
		# Ah, CombatManager handles attacks. We need to expose stats for CombatManager.

	bounce_count = 0
	split_count = 0
	active_buffs.clear()
	buff_sources.clear()

	# Artifact Effects
	if GameManager.reward_manager and "focus_fire" in GameManager.reward_manager.acquired_artifacts:
		range_val *= 1.2

	update_visuals()

func calculate_damage_against(target_node: Node2D) -> float:
	var final_damage = damage

	if GameManager.reward_manager and "focus_fire" in GameManager.reward_manager.acquired_artifacts:
		if target_node == focus_target:
			focus_stacks = min(focus_stacks + 1, 10)
		else:
			focus_target = target_node
			focus_stacks = 0

		final_damage *= (1.0 + 0.05 * focus_stacks)

	return final_damage

func apply_buff(buff_type: String, source_unit: Node2D = null):
	if buff_type in active_buffs: return
	active_buffs.append(buff_type)
	if source_unit:
		buff_sources[buff_type] = source_unit

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

func set_highlight(active: bool, color: Color = Color.WHITE):
	_is_skill_highlight_active = active
	_highlight_color = color

	if active:
		if visual_holder:
			# Use modulate on visual_holder or simple drawing?
			# Drawing a border is better but Unit needs _draw() logic for that.
			# Let's use modulate or just add a color rect/border.
			# Or simpler: use self.modulate but mix with original color.
			# But self.modulate affects everything.
			# The requirement says "Unit appears green/red outline (stroke)".
			# Godot _draw is easiest for stroke.
			queue_redraw()
	else:
		queue_redraw()

	if connection_overlay: connection_overlay.queue_redraw()

func execute_skill_at(grid_pos: Vector2i):
	if skill_cooldown > 0: return

	# Units with item production (generic) usually don't have active skills in this context,
	# or at least we shouldn't block by name.
	# If the unit data has no "skill" field or skillType is not point, this won't be called normally.
	if not unit_data.has("skill"): return

	if GameManager.consume_resource("mana", skill_mana_cost):
		is_no_mana = false
		_start_skill_cooldown(unit_data.get("skillCd", 10.0))

		var skill_name = unit_data.skill
		GameManager.spawn_floating_text(global_position, skill_name.capitalize() + "!", Color.CYAN)
		GameManager.skill_activated.emit(self)

		print("[DEBUG] Unit.execute_skill_at: ", grid_pos)

		GameManager.execute_skill_effect(type_key, grid_pos)

	else:
		is_no_mana = true
		GameManager.spawn_floating_text(global_position, "No Mana!", Color.BLUE)

func _on_skill_ended():
	set_highlight(false)

	if type_key == "dog":
		atk_speed = original_atk_speed

func activate_skill():
	if !unit_data.has("skill"): return

	if skill_cooldown > 0:
		return

	# Point Skill Handling (Phoenix only now)
	if unit_data.get("skillType") == "point" and type_key == "phoenix":
		if GameManager.grid_manager:
			GameManager.grid_manager.enter_skill_targeting(self)
		return

	# Check cost but proceed only if successful.
	# Note: Cow regeneration logic is powerful, verify cost.

	if GameManager.consume_resource("mana", skill_mana_cost):
		is_no_mana = false
		_start_skill_cooldown(unit_data.get("skillCd", 10.0))

		var skill_name = unit_data.skill
		GameManager.spawn_floating_text(global_position, skill_name.capitalize() + "!", Color.CYAN)
		GameManager.skill_activated.emit(self)

		# Use visual_holder for scale effect
		if visual_holder:
			var tween = create_tween()
			tween.tween_property(visual_holder, "scale", Vector2(1.2, 1.2), 0.1)
			tween.tween_property(visual_holder, "scale", Vector2(1.0, 1.0), 0.1)

		# --- New Logic ---
		match type_key:
			"cow":
				skill_active_timer = 5.0
				set_highlight(true, Color.GREEN)

			"dog":
				skill_active_timer = 5.0
				set_highlight(true, Color.RED)
				original_atk_speed = atk_speed
				atk_speed *= 0.3 # Accelerate (smaller interval = faster)

			"bear":
				var enemies = get_tree().get_nodes_in_group("enemies")
				for enemy in enemies:
					if global_position.distance_to(enemy.global_position) <= range_val:
						if enemy.has_method("apply_stun"):
							enemy.apply_stun(2.0)

			"butterfly":
				# Do nothing or print
				print("Butterfly skill activated (No effect implemented)")

	else:
		is_no_mana = true
		GameManager.spawn_floating_text(global_position, "No Mana!", Color.BLUE)

func update_visuals():
	_ensure_visual_hierarchy()
	var label = visual_holder.get_node_or_null("Label")
	var star_label = visual_holder.get_node_or_null("StarLabel")

	# Try to load icon image
	var icon_texture = AssetLoader.get_unit_icon(type_key)

	var tex_rect = visual_holder.get_node_or_null("TextureRect")
	if !tex_rect:
		tex_rect = TextureRect.new()
		tex_rect.name = "TextureRect"
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		visual_holder.add_child(tex_rect)
		# Ensure TextureRect is below labels if possible, though visual_holder order matters
		if label: visual_holder.move_child(tex_rect, label.get_index())

	if icon_texture:
		tex_rect.texture = icon_texture
		tex_rect.show()
		if label: label.hide()
	else:
		tex_rect.hide()
		if label:
			label.text = unit_data.icon
			label.show()
	
	# Size update based on unit_data
	var size = unit_data["size"]
	var target_size = Vector2(size.x * Constants.TILE_SIZE - 4, size.y * Constants.TILE_SIZE - 4)
	var target_pos = -(target_size / 2) # Center inside parent (Unit node)

	if tex_rect:
		tex_rect.size = target_size
		tex_rect.position = target_pos
		tex_rect.pivot_offset = tex_rect.size / 2

	if label:
		label.size = target_size
		label.position = target_pos
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

		# Calculate size based on unit data since ColorRect is gone
		var size = Vector2(Constants.TILE_SIZE, Constants.TILE_SIZE) # Default
		if unit_data and unit_data.has("size"):
			size = Vector2(unit_data["size"].x * Constants.TILE_SIZE, unit_data["size"].y * Constants.TILE_SIZE)

		buff_container.position = Vector2(-size.x/2, size.y/2 - 20) # Just an approximation
		buff_container.size = Vector2(size.x, 15)

		buff_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(buff_container)

	for child in buff_container.get_children():
		child.queue_free()

	for buff in active_buffs:
		var lbl = Label.new()
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		lbl.text = _get_buff_icon(buff)
		buff_container.add_child(lbl)

func _get_buff_icon(buff_type: String) -> String:
	match buff_type:
		"fire": return "🔥"
		"poison": return "🧪"
		"range": return "🔭"
		"speed": return "⚡"
		"crit": return "💥"
		"bounce": return "🪞"
		"split": return "💠"
		"multishot": return "📶"
	return "?"

func _process(delta):
	if !GameManager.is_wave_active: return

	# Generic Item Production Logic
	if unit_data.has("production_type") and unit_data["production_type"] == "item":
		production_timer -= delta
		if production_timer <= 0:
			var item_id = unit_data.get("produce_item_id", "")
			if item_id != "":
				var item_data = { "item_id": item_id, "count": 1 }

				var added = false
				if GameManager.inventory_manager:
					if GameManager.inventory_manager.add_item(item_data):
						added = true
				else:
					# Fallback for testing
					print("Attempting to add %s to inventory (No InvManager)" % item_id)
					added = true # Assume success in tests without manager

				if added:
					var trap_name = "Trap"
					if Constants.BARRICADE_TYPES.has(item_id):
						trap_name = Constants.BARRICADE_TYPES[item_id].get("icon", "Trap")
					GameManager.spawn_floating_text(global_position, "%s Produced!" % trap_name, Color.GREEN)
					production_timer = max_production_timer
				else:
					# Inventory full, keep timer at 0 to retry
					production_timer = 0.0

	# Production Logic (Resources)
	elif unit_data.has("produce"):
		production_timer -= delta
		if production_timer <= 0:
			var p_type = unit_data.produce
			var p_amt = unit_data.get("produceAmt", 1)

			GameManager.add_resource(p_type, p_amt)

			var icon = "🌽" if p_type == "food" else "💎"
			var color = Color.YELLOW if p_type == "food" else Color.CYAN
			GameManager.spawn_floating_text(global_position, "+%d%s" % [p_amt, icon], color)

			production_timer = 1.0
	# Cow Passive Logic (Existing)
	if unit_data.has("skill") and unit_data.skill == "milk_aura":
		production_timer -= delta
		if production_timer <= 0:
			# Heal core
			GameManager.damage_core(-50)
			GameManager.spawn_floating_text(global_position, "+50", Color.GREEN)
			production_timer = 5.0

	# Active Skill Timer Logic
	if skill_active_timer > 0:
		skill_active_timer -= delta

		# Cow Active Regeneration
		if type_key == "cow":
			GameManager.damage_core(-200 * delta)

		if skill_active_timer <= 0:
			_on_skill_ended()

	if cooldown > 0:
		cooldown -= delta

	if skill_cooldown > 0:
		skill_cooldown -= delta

	# Visual State
	if is_starving:
		modulate = Color(0.5, 0.5, 0.5, 1.0)
	elif is_no_mana and unit_data.has("skill"):
		modulate = Color(0.7, 0.7, 1.0, 1.0)
	else:
		modulate = Color.WHITE

var breathe_tween: Tween = null

func get_interaction_info() -> Dictionary:
	var info = { "has_interaction": false, "buff_id": "" }
	if unit_data.has("has_interaction") and unit_data.has_interaction:
		info.has_interaction = true
		info.buff_id = unit_data.get("buff_id", "")
	return info

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

func can_merge_with(other_unit) -> bool:
	if other_unit == null: return false
	if other_unit == self: return false
	if other_unit.type_key != type_key: return false
	if other_unit.level != level: return false
	if level >= MAX_LEVEL: return false
	return true

func merge_with(other_unit):
	level += 1
	reset_stats()

	# Visual Effect
	GameManager.spawn_floating_text(global_position, "Level Up!", Color.GOLD)
	if visual_holder:
		var tween = create_tween()
		tween.tween_property(visual_holder, "scale", Vector2(1.5, 1.5), 0.2).set_trans(Tween.TRANS_BOUNCE)
		tween.tween_property(visual_holder, "scale", Vector2(1.0, 1.0), 0.2)

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
	is_hovered = true
	queue_redraw()
	if connection_overlay: connection_overlay.queue_redraw()
	var current_stats = {
		"level": level,
		"damage": damage,
		"range": range_val,
		"atk_speed": atk_speed,
		"crit_rate": crit_rate,
		"crit_dmg": crit_dmg
	}
	GameManager.show_tooltip.emit(unit_data, current_stats, active_buffs, global_position)

func _on_area_2d_mouse_exited():
	is_hovered = false
	queue_redraw()
	if connection_overlay: connection_overlay.queue_redraw()
	GameManager.hide_tooltip.emit()

func _draw():
	if is_hovered:
		var draw_radius = range_val
		if unit_data.get("attackType") == "melee":
			# For melee, use actual range if it's reasonable, or a fixed visual range if range_val is too small (e.g. < 50)
			# But prompt suggests "fixed smaller range (e.g. 100) or actual range".
			# Most melee units have range around 80-100.
			draw_radius = max(range_val, 100.0)

		draw_circle(Vector2.ZERO, draw_radius, Color(1, 1, 1, 0.1))
		draw_arc(Vector2.ZERO, draw_radius, 0, TAU, 64, Color(1, 1, 1, 0.3), 1.0)

	if _is_skill_highlight_active:
		# Draw a thick outline
		var size = Vector2(Constants.TILE_SIZE, Constants.TILE_SIZE)
		if unit_data and unit_data.has("size"):
			size = Vector2(unit_data.size.x * Constants.TILE_SIZE, unit_data.size.y * Constants.TILE_SIZE)

		# Assuming pivot is center
		var rect = Rect2(-size / 2, size)
		draw_rect(rect, _highlight_color, false, 4.0)

func _on_connection_overlay_draw():
	if is_hovered:
		# --- Receiver View (Trace Back) ---
		for buff_type in buff_sources:
			var source = buff_sources[buff_type]
			if is_instance_valid(source):
				var self_pos = Vector2.ZERO
				var source_pos = connection_overlay.to_local(source.global_position)
				# Draw from Source to Self so arrow points to Self (Receiver)
				_draw_curve_connection(source_pos, self_pos, Color.BLACK, buff_type)

		# --- Provider View (Trace Forward) ---
		if unit_data.has("buffProvider") or (unit_data.has("has_interaction") and unit_data.has_interaction):
			if GameManager.grid_manager:
				var neighbors = _get_neighbor_units()
				for neighbor in neighbors:
					if neighbor == self: continue
					# Check if neighbor has a buff from me.
					var provided_buff = ""
					for b_type in neighbor.buff_sources:
						if neighbor.buff_sources[b_type] == self:
							provided_buff = b_type
							break

					if provided_buff != "":
						var start_pos = Vector2.ZERO
						var end_pos = connection_overlay.to_local(neighbor.global_position)
						_draw_curve_connection(start_pos, end_pos, Color.WHITE, provided_buff)

func _get_neighbor_units() -> Array:
	var list = []
	if !GameManager.grid_manager: return list

	var cx = grid_pos.x
	var cy = grid_pos.y
	var w = unit_data.size.x
	var h = unit_data.size.y

	var neighbors_pos = []
	# Top and Bottom
	for dx in range(-1, w + 1):
		neighbors_pos.append(Vector2i(cx + dx, cy - 1))
		neighbors_pos.append(Vector2i(cx + dx, cy + h))
	# Left and Right
	for dy in range(0, h):
		neighbors_pos.append(Vector2i(cx - 1, cy + dy))
		neighbors_pos.append(Vector2i(cx + w, cy + dy))

	for n_pos in neighbors_pos:
		var key = GameManager.grid_manager.get_tile_key(n_pos.x, n_pos.y)
		if GameManager.grid_manager.tiles.has(key):
			var tile = GameManager.grid_manager.tiles[key]
			var u = tile.unit
			if u == null and tile.occupied_by != Vector2i.ZERO:
				var origin_key = GameManager.grid_manager.get_tile_key(tile.occupied_by.x, tile.occupied_by.y)
				if GameManager.grid_manager.tiles.has(origin_key):
					u = GameManager.grid_manager.tiles[origin_key].unit

			if u and is_instance_valid(u) and not (u in list):
				list.append(u)
	return list

func _draw_curve_connection(start: Vector2, end: Vector2, color: Color, buff_type: String = ""):
	var diff = end - start
	var control_point = (start + end) / 2

	if start.distance_squared_to(end) < 1.0:
		control_point.y -= 40 # Self loop vertical offset
	else:
		var normal = Vector2(-diff.y, diff.x).normalized()
		var offset_amount = 30.0
		control_point += normal * offset_amount

	var points = PackedVector2Array()
	var segments = 15
	for i in range(segments + 1):
		var t = float(i) / segments
		var q0 = start.lerp(control_point, t)
		var q1 = control_point.lerp(end, t)
		var p = q0.lerp(q1, t)
		points.append(p)

	# Arrow Calculation
	var arrow_len = 15.0
	var direction = Vector2.RIGHT
	if points.size() >= 2:
		direction = (points[-1] - points[-2]).normalized()
	else:
		direction = (end - control_point).normalized()

	var arrow_tip = end
	var arrow_back = end - direction * arrow_len
	var arrow_side1 = arrow_back + direction.orthogonal() * (arrow_len * 0.5)
	var arrow_side2 = arrow_back - direction.orthogonal() * (arrow_len * 0.5)

	# Trim line to arrow back
	if points.size() > 1:
		points[-1] = arrow_back

	connection_overlay.draw_polyline(points, color, 2.0, true)
	connection_overlay.draw_colored_polygon(PackedVector2Array([arrow_tip, arrow_side1, arrow_side2]), color)

	if buff_type != "":
		# Draw Buff Icon at source (near start of curve)
		var icon_t = 0.15
		var q0 = start.lerp(control_point, icon_t)
		var q1 = control_point.lerp(end, icon_t)
		var icon_pos = q0.lerp(q1, icon_t)

		var icon_text = _get_buff_icon(buff_type)

		# Draw background circle
		connection_overlay.draw_circle(icon_pos, 10, Color(0, 0, 0, 0.7))

		# Draw text
		# Note: draw_string uses position as baseline-ish. Need to center.
		# A default font is usually available via ThemeDB
		var font = ThemeDB.fallback_font
		var font_size = 14
		if font:
			var text_size = font.get_string_size(icon_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
			connection_overlay.draw_string(font, icon_pos + Vector2(-text_size.x/2, text_size.y/3), icon_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)

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

	# Clone visuals
	# Since visual_holder contains TextureRect and Label, we can try to duplicate it or its children
	# NOTE: Duplicate() is shallow by default but can be deep.

	if visual_holder:
		var dup_visual = visual_holder.duplicate(7) # Duplicate scripts, signals, groups
		ghost_node.add_child(dup_visual)

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
