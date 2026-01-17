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

var attachment: Node2D = null
var host: Node2D = null

# Stats
var damage: float
var range_val: float
var atk_speed: float
var attack_cost_mana: float = 0.0
var skill_mana_cost: float = 30.0

var max_hp: float = 0.0

var production_timer: float = 0.0
var max_production_timer: float = 1.0

# Visual Holder for animations and structure
var visual_holder: Node2D = null

var is_no_mana: bool = false
var crit_rate: float = 0.0
var crit_dmg: float = 1.5
var bounce_count: int = 0
var split_count: int = 0

var guaranteed_crit_stacks: int = 0

# Parrot Mechanics
var ammo_queue: Array = []
var max_ammo: int = 0
var mimicked_bullet_timer: float = 0.0
var is_discharging: bool = false

# Grid
var grid_pos: Vector2i = Vector2i.ZERO
var start_position: Vector2 = Vector2.ZERO

# Interaction
var interaction_target_pos = null # Vector2i or null
var associated_traps: Array = [] # Stores references to traps placed by this unit

# Missing variables required for the old drag logic at the bottom to compile
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var ghost_node: Node2D = null
var is_hovered: bool = false
var focus_target: Node2D = null
var focus_stacks: int = 0

# Skill Logic
var skill_active_timer: float = 0.0
var _skill_interval_timer: float = 0.0
var original_atk_speed: float = 0.0
var _is_skill_highlight_active: bool = false
var _highlight_color: Color = Color.WHITE

# Highlighting
var is_force_highlighted: bool = false

# Porcupine Variables
var attack_counter: int = 0
var feather_refs: Array = []

const MAX_LEVEL = 3
const DRAG_HANDLER_SCRIPT = preload("res://src/Scripts/UI/UnitDragHandler.gd")

signal unit_clicked(unit)
signal attack_performed(target_node)

func _start_skill_cooldown(base_duration: float):
	if GameManager.cheat_fast_cooldown and base_duration > 1.0:
		skill_cooldown = 1.0
	else:
		skill_cooldown = base_duration * GameManager.get_stat_modifier("cooldown")

func _ready():
	_ensure_visual_hierarchy()

	if type_key == "peacock":
		tree_exiting.connect(_on_peacock_cleanup)

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

	if key == "oxpecker" and not Constants.UNIT_TYPES.has(key):
		# Fallback if oxpecker not in constants
		unit_data = {
			"size": Vector2(1, 1),
			"hp": 100,
			"damage": 10,
			"range": 300,
			"atkSpeed": 1.0,
			"attackType": "ranged",
			"icon": "Ox"
		}
	else:
		unit_data = Constants.UNIT_TYPES[key].duplicate()

	if type_key == "oxpecker":
		unit_data["attackType"] = "ranged"

	# reset_stats will handle reading stats from levels
	reset_stats()
	# Initialize production timer
	production_timer = max_production_timer
	update_visuals()

	start_breathe_anim()

	var drag_handler = Control.new()
	drag_handler.set_script(DRAG_HANDLER_SCRIPT)
	add_child(drag_handler)
	drag_handler.setup(self)

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
	if unit_data.has("produce"):
		max_production_timer = 1.0
	elif unit_data.has("production_type") and unit_data["production_type"] == "item":
		var base_interval = unit_data.get("production_interval", 5.0)
		var new_interval = base_interval

		if stats.has("mechanics") and stats["mechanics"].has("production_interval"):
			new_interval = stats["mechanics"]["production_interval"]

		max_production_timer = new_interval
	elif unit_data.has("skill") and unit_data.skill == "milk_aura":
		max_production_timer = 5.0

	max_hp = stats.get("hp", unit_data.get("hp", 0))

	# Non-leveled stats (unless moved to levels, which range/atkSpeed weren't in my script)
	range_val = unit_data.get("range", 0)
	atk_speed = unit_data.get("atkSpeed", 1.0)

	# Parrot Max Ammo
	if type_key == "parrot":
		if stats.has("mechanics") and stats["mechanics"].has("max_ammo"):
			max_ammo = stats["mechanics"]["max_ammo"]
		else:
			max_ammo = 5 # Default fallback
		update_parrot_range()

	crit_rate = unit_data.get("crit_rate", 0.1)
	crit_dmg = unit_data.get("crit_dmg", 1.5)

	# Costs
	attack_cost_mana = unit_data.get("manaCost", 0.0)
	skill_mana_cost = unit_data.get("skillCost", 30.0)

	# Mechanics from Level
	if stats.has("mechanics"):
		var mechs = stats["mechanics"]
		if mechs.has("crit_rate_bonus"):
			crit_rate += mechs["crit_rate_bonus"]

	bounce_count = 0
	split_count = 0
	active_buffs.clear()
	buff_sources.clear()
	feather_refs.clear()

	# Artifact Effects
	if GameManager.reward_manager and "focus_fire" in GameManager.reward_manager.acquired_artifacts:
		range_val *= 1.2

	if type_key == "parrot":
		update_parrot_range()

	broadcast_buffs()
	update_visuals()

func broadcast_buffs():
	if !unit_data.has("buff_id"): return
	var buff = unit_data.get("buff_id")
	if buff == "": return

	# Currently simplistic: apply to all neighbors if it's a provider
	var neighbors = _get_neighbor_units()
	for neighbor in neighbors:
		if neighbor != self:
			neighbor.apply_buff(buff, self)

func update_parrot_range():
	if type_key != "parrot": return
	if !GameManager.grid_manager: return

	var neighbors = _get_neighbor_units()
	var min_range = 9999.0
	var has_ranged_neighbor = false

	for unit in neighbors:
		if unit.unit_data.get("attackType") == "ranged":
			has_ranged_neighbor = true
			if unit.range_val < min_range:
				min_range = unit.range_val

	if has_ranged_neighbor:
		range_val = min_range
	else:
		range_val = 0.0

func capture_bullet(bullet_snapshot: Dictionary):
	if type_key != "parrot": return
	if is_discharging: return # Don't capture while firing
	if ammo_queue.size() >= max_ammo: return

	# Clone to prevent reference issues
	ammo_queue.append(bullet_snapshot.duplicate(true))

	# Visual Feedback?
	if visual_holder:
		var tween = create_tween()
		tween.tween_property(visual_holder, "scale", Vector2(1.1, 1.1), 0.1)
		tween.tween_property(visual_holder, "scale", Vector2(1.0, 1.0), 0.1)

func calculate_damage_against(target_node: Node2D) -> float:
	var final_damage = damage

	if GameManager.reward_manager and "focus_fire" in GameManager.reward_manager.acquired_artifacts:
		if target_node == focus_target:
			focus_stacks = min(focus_stacks + 1, 10)
		else:
			focus_target = target_node
			focus_stacks = 0

		final_damage *= (1.0 + 0.05 * focus_stacks)

	final_damage *= GameManager.get_stat_modifier("damage")

	return final_damage

func apply_buff(buff_type: String, source_unit: Node2D = null):
	# Allow stacking for specific buffs like bounce
	if buff_type in active_buffs and buff_type != "bounce": return

	if not (buff_type in active_buffs):
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
	queue_redraw()

func set_force_highlight(active: bool):
	is_force_highlighted = active
	queue_redraw()

func execute_skill_at(grid_pos: Vector2i):
	if skill_cooldown > 0: return

	if not unit_data.has("skill"): return

	if GameManager.consume_resource("mana", skill_mana_cost):
		is_no_mana = false
		_start_skill_cooldown(unit_data.get("skillCd", 10.0))

		var skill_name = unit_data.skill
		GameManager.spawn_floating_text(global_position, skill_name.capitalize() + "!", Color.CYAN)
		GameManager.skill_activated.emit(self)

		print("[DEBUG] Unit.execute_skill_at: ", grid_pos)

		if type_key == "dragon":
			var extra_stats = {
				"duration": unit_data.get("skillDuration", 8.0),
				"skillRadius": unit_data.get("skillRadius", 150.0),
				"skillStrength": unit_data.get("skillStrength", 3000.0),
				"skillColor": unit_data.get("skillColor", "#330066"),
				"damage": 0,
				"hide_visuals": false # Ensure visuals are shown for the field
			}
			if GameManager.grid_manager:
				var world_pos = GameManager.grid_manager.get_world_pos_from_grid(grid_pos)
				if GameManager.combat_manager:
					GameManager.combat_manager.spawn_projectile(self, world_pos, null, extra_stats)
		else:
			GameManager.execute_skill_effect(type_key, grid_pos)

	else:
		is_no_mana = true
		GameManager.spawn_floating_text(global_position, "No Mana!", Color.BLUE)

func add_crit_stacks(amount: int):
	guaranteed_crit_stacks += amount
	# Visual feedback if needed
	GameManager.spawn_floating_text(global_position, "Crit Ready!", Color.ORANGE)

func _on_skill_ended():
	set_highlight(false)

	if type_key == "dog":
		atk_speed = original_atk_speed

func activate_skill():
	if !unit_data.has("skill"): return

	if skill_cooldown > 0:
		return

	# Point Skill Handling (Phoenix and Dragon)
	if unit_data.get("skillType") == "point" and (type_key == "phoenix" or type_key == "dragon"):
		if GameManager.grid_manager:
			GameManager.grid_manager.enter_skill_targeting(self)
		return

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
			"tiger":
				skill_active_timer = unit_data.get("skillDuration", 5.0)
				_skill_interval_timer = 0.0
				set_highlight(true, Color.ORANGE)

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
		"wealth": return "💰"
	return "?"

func _process(delta):
	if !GameManager.is_wave_active: return

	_process_combat(delta)

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
					added = true

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

			var icon = "💎"
			var color = Color.CYAN
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

		if type_key == "tiger":
			_skill_interval_timer -= delta
			if _skill_interval_timer <= 0:
				_skill_interval_timer = 0.2
				_spawn_meteor_at_random_enemy()

		if skill_active_timer <= 0:
			_on_skill_ended()

	if skill_cooldown > 0:
		skill_cooldown -= delta

	# Visual State
	if is_no_mana and unit_data.has("skill"):
		modulate = Color(0.7, 0.7, 1.0, 1.0)
	else:
		modulate = Color.WHITE

func _process_combat(delta):
	if !unit_data.has("attackType") or unit_data.attackType == "none":
		return

	if cooldown > 0:
		cooldown -= delta
		return

	# Resource Check (Pre-check)
	if attack_cost_mana > 0:
		if !GameManager.check_resource("mana", attack_cost_mana):
			is_no_mana = true
			return
		else:
			is_no_mana = false

	# Find target
	var combat_manager = GameManager.combat_manager
	if !combat_manager: return

	# Delegate to specific handlers
	if type_key == "parrot":
		# Parrot finds its own target usually to check range, but standard behavior is fine to integrate
		var target = combat_manager.find_nearest_enemy(global_position, range_val)
		_do_mimic_attack(target, combat_manager)
		return

	# Common Target Logic
	var target = combat_manager.find_nearest_enemy(global_position, range_val)
	if !target and type_key != "peacock": return # Peacock might need to recall without target? Checked in handler.

	if type_key == "peacock":
		_handle_peacock_attack(target, combat_manager)
	elif type_key == "bee":
		if target: _do_bow_attack(target)
	elif unit_data.attackType == "melee":
		if target: _do_melee_attack(target)
	elif unit_data.attackType == "mimic":
		if target: _do_mimic_attack(target, combat_manager)
	else:
		if target: _do_standard_ranged_attack(target)

func _do_mimic_attack(target, combat_manager):
	if !is_discharging:
		# Check Start Condition: Full Ammo AND Enemy in Range
		if ammo_queue.size() >= max_ammo:
			if target:
				is_discharging = true

	if is_discharging:
		if ammo_queue.size() > 0:
			var aim_target = target
			if !aim_target or !is_instance_valid(aim_target):
				aim_target = combat_manager.find_nearest_enemy(global_position, range_val)

			if aim_target:
				if attack_cost_mana > 0: GameManager.consume_resource("mana", attack_cost_mana)
				cooldown = atk_speed

				var bullet_data = ammo_queue.pop_front()
				play_attack_anim("ranged", aim_target.global_position)

				var extra = bullet_data.duplicate()
				extra["mimic_damage"] = bullet_data.get("damage", 10.0)
				extra["proj_override"] = bullet_data.get("type", "pinecone")

				combat_manager.spawn_projectile(self, global_position, aim_target, extra)
				attack_performed.emit(aim_target)
		else:
			is_discharging = false

func _do_bow_attack(target, on_release_callback: Callable = Callable()):
	# Capture target position immediately (Blind Fire)
	var target_last_pos = target.global_position

	if attack_cost_mana > 0:
		GameManager.consume_resource("mana", attack_cost_mana)

	var anim_duration = clamp(atk_speed * 0.8, 0.1, 0.6)
	cooldown = atk_speed * GameManager.get_stat_modifier("attack_interval")

	play_attack_anim("bow", target_last_pos, anim_duration)

	# Wait for Pull
	var pull_time = anim_duration * 0.6
	await get_tree().create_timer(pull_time).timeout

	if !is_instance_valid(self): return

	# Fire!
	if on_release_callback.is_valid():
		# Pass last pos to callback
		on_release_callback.call(target_last_pos)
	else:
		# Default (Bee)
		if GameManager.combat_manager:
			if is_instance_valid(target):
				GameManager.combat_manager.spawn_projectile(self, global_position, target)
				attack_performed.emit(target)
			else:
				# Target dead, use last pos
				var angle = (target_last_pos - global_position).angle()
				GameManager.combat_manager.spawn_projectile(self, global_position, null, {"angle": angle, "target_pos": target_last_pos})
				attack_performed.emit(null)

func _do_melee_attack(target):
	var target_last_pos = target.global_position

	if attack_cost_mana > 0:
		GameManager.consume_resource("mana", attack_cost_mana)

	cooldown = atk_speed * GameManager.get_stat_modifier("attack_interval")

	play_attack_anim("melee", target_last_pos)

	await get_tree().create_timer(Constants.ANIM_WINDUP_TIME).timeout
	if !is_instance_valid(self): return

	if is_instance_valid(target):
		_spawn_melee_projectiles(target)
		attack_performed.emit(target)
	else:
		_spawn_melee_projectiles_blind(target_last_pos)
		attack_performed.emit(null)

func _spawn_melee_projectiles_blind(target_pos: Vector2):
	var combat_manager = GameManager.combat_manager
	if !combat_manager: return

	var swing_hit_list = []
	var attack_dir = (target_pos - global_position).normalized()

	var proj_speed = 600.0
	var proj_life = (range_val + 30.0) / proj_speed
	var count = 5
	var spread = PI / 2.0

	var base_angle = attack_dir.angle()
	var start_angle = base_angle - spread / 2.0
	var step = spread / max(1, count - 1)

	for i in range(count):
		var angle = start_angle + (i * step)
		var stats = {
			"pierce": 100,
			"hide_visuals": true,
			"life": proj_life,
			"angle": angle,
			"speed": proj_speed,
			"shared_hit_list": swing_hit_list
		}
		combat_manager.spawn_projectile(self, global_position, null, stats)

func _do_standard_ranged_attack(target):
	var combat_manager = GameManager.combat_manager
	if !combat_manager: return

	if attack_cost_mana > 0:
		GameManager.consume_resource("mana", attack_cost_mana)

	cooldown = atk_speed * GameManager.get_stat_modifier("attack_interval")

	if unit_data.get("proj") == "lightning":
		play_attack_anim("lightning", target.global_position)
		combat_manager.perform_lightning_attack(self, global_position, target, unit_data.get("chain", 0))
		return

	play_attack_anim("ranged", target.global_position)

	# Multi-shot logic
	var proj_count = unit_data.get("projCount", 1)
	var spread = unit_data.get("spread", 0.5)

	if "multishot" in active_buffs:
		proj_count += 2
		spread = max(spread, 0.5)

	if proj_count == 1:
		combat_manager.spawn_projectile(self, global_position, target)
		attack_performed.emit(target)
	else:
		var base_angle = (target.global_position - global_position).angle()
		var start_angle = base_angle - spread / 2.0
		var step = spread / max(1, proj_count - 1)

		for i in range(proj_count):
			var angle = start_angle + (i * step)
			combat_manager.spawn_projectile(self, global_position, target, {"angle": angle})

	attack_performed.emit(target)

func _handle_peacock_attack(target, combat_manager):
	# Peacock: 3 attacks then 1 recall
	if attack_counter >= 3:
		cooldown = atk_speed * GameManager.get_stat_modifier("attack_interval")
		attack_counter = 0

		if visual_holder:
			var tween = create_tween()
			tween.tween_property(visual_holder, "scale", Vector2(1.3, 1.3), 0.1)
			tween.tween_property(visual_holder, "scale", Vector2(1.0, 1.0), 0.1)

		for q in feather_refs:
			if is_instance_valid(q) and q.has_method("recall"):
				q.recall()
		feather_refs.clear()

	elif target:
		# SHOOT ACTION with Bow Animation
		var spawn_logic = func(saved_target_pos: Vector2):
			if !is_instance_valid(combat_manager): return

			var extra_shots = 0
			var multi_chance = 0.0

			if unit_data.has("levels") and unit_data["levels"].has(str(level)):
				var mech = unit_data["levels"][str(level)].get("mechanics", {})
				multi_chance = mech.get("multi_shot_chance", 0.0)

			if multi_chance > 0.0 and randf() < multi_chance:
				extra_shots += 1

			# Determine target or angle
			var use_target = null
			var base_angle = 0.0

			if is_instance_valid(target):
				use_target = target
				base_angle = (target.global_position - global_position).angle()
			else:
				base_angle = (saved_target_pos - global_position).angle()
				# use_target remains null

			# Fire Primary Feather
			var proj_args = {}
			if !use_target:
				proj_args["angle"] = base_angle
				proj_args["target_pos"] = saved_target_pos

			var proj = combat_manager.spawn_projectile(self, global_position, use_target, proj_args)
			if proj and is_instance_valid(proj):
				feather_refs.append(proj)

			# Fire Extra Shots
			if extra_shots > 0:
				var spread_angle = 0.2
				var angles = [base_angle - spread_angle, base_angle + spread_angle]

				for i in range(extra_shots):
					var angle_mod = angles[i % 2]
					var dist = global_position.distance_to(saved_target_pos)
					var extra_target_pos = global_position + Vector2.RIGHT.rotated(angle_mod) * dist

					var extra_args = {"angle": angle_mod}
					if !use_target:
						extra_args["target_pos"] = extra_target_pos

					var extra_proj = combat_manager.spawn_projectile(self, global_position, use_target, extra_args)
					if extra_proj and is_instance_valid(extra_proj):
						feather_refs.append(extra_proj)

			attack_counter += 1

		_do_bow_attack(target, spawn_logic)

func play_attack_anim(attack_type: String, target_pos: Vector2, duration: float = -1.0):
	if !visual_holder: return

	if breathe_tween: breathe_tween.kill()
	if attack_tween: attack_tween.kill()

	attack_tween = create_tween()

	if attack_type == "melee":
		var dir = (target_pos - global_position).normalized()
		var original_pos = Vector2.ZERO

		# Phase 1: Windup
		attack_tween.tween_property(visual_holder, "position", -dir * Constants.ANIM_WINDUP_DIST, Constants.ANIM_WINDUP_TIME)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		attack_tween.parallel().tween_property(visual_holder, "scale", Constants.ANIM_WINDUP_SCALE, Constants.ANIM_WINDUP_TIME)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		# Phase 2: Strike
		attack_tween.tween_property(visual_holder, "position", dir * Constants.ANIM_STRIKE_DIST, Constants.ANIM_STRIKE_TIME)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		attack_tween.parallel().tween_property(visual_holder, "scale", Constants.ANIM_STRIKE_SCALE, Constants.ANIM_STRIKE_TIME)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

		# Phase 3: Recovery
		attack_tween.tween_property(visual_holder, "position", original_pos, Constants.ANIM_RECOVERY_TIME)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		attack_tween.parallel().tween_property(visual_holder, "scale", Vector2.ONE, Constants.ANIM_RECOVERY_TIME)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	elif attack_type == "bow":
		var total_time = duration if duration > 0 else 0.5
		var pull_time = total_time * 0.6
		var recover_time = total_time * 0.3

		var dir = (target_pos - global_position).normalized()

		# Phase 1: Pull
		attack_tween.tween_property(visual_holder, "position", -dir * 10.0, pull_time)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		attack_tween.parallel().tween_property(visual_holder, "scale", Vector2(0.8, 1.2), pull_time)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		# Phase 2: Snap
		attack_tween.tween_callback(func():
			visual_holder.position = Vector2.ZERO
			visual_holder.scale = Vector2.ONE
		)

		# Phase 3: Recovery
		attack_tween.tween_property(visual_holder, "scale", Vector2(1.1, 0.9), recover_time * 0.5)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		attack_tween.tween_property(visual_holder, "scale", Vector2.ONE, recover_time * 0.5)

	elif attack_type == "ranged" or attack_type == "lightning":
		# Recoil
		attack_tween.tween_property(visual_holder, "scale", Vector2(0.8, 0.8), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		attack_tween.tween_property(visual_holder, "scale", Vector2(1.0, 1.0), 0.2)
		# Reset position in parallel just in case
		attack_tween.parallel().tween_property(visual_holder, "position", Vector2.ZERO, 0.3)

	attack_tween.finished.connect(func(): start_breathe_anim())

func _spawn_meteor_at_random_enemy():
	var combat_manager = GameManager.combat_manager
	if !combat_manager: return
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty(): return

	var target = enemies.pick_random()
	if !is_instance_valid(target): return

	var ground_pos = target.global_position
	var spawn_pos = ground_pos + Vector2(randf_range(-100, 100), -600)

	var stats = {
		"is_meteor": true,
		"ground_pos": ground_pos,
		"damageType": "physical",
		"life": 3.0,
		"source": self
	}

	combat_manager.spawn_projectile(self, spawn_pos, target, stats)

func _spawn_melee_projectiles(target: Node2D):
	var combat_manager = GameManager.combat_manager
	if !combat_manager: return

	var swing_hit_list = []
	var attack_dir = (target.global_position - global_position).normalized()

	var proj_speed = 600.0
	var proj_life = (range_val + 30.0) / proj_speed
	var count = 5
	var spread = PI / 2.0

	var base_angle = attack_dir.angle()
	var start_angle = base_angle - spread / 2.0
	var step = spread / max(1, count - 1)

	for i in range(count):
		var angle = start_angle + (i * step)
		var stats = {
			"pierce": 100,
			"hide_visuals": true,
			"life": proj_life,
			"angle": angle,
			"speed": proj_speed,
			"shared_hit_list": swing_hit_list
		}
		combat_manager.spawn_projectile(self, global_position, null, stats)

var breathe_tween: Tween = null
var attack_tween: Tween = null

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
	broadcast_buffs()

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

	# --- Static Hover Feedback ---
	# Receiver View: Highlight sources
	for buff_type in buff_sources:
		var source = buff_sources[buff_type]
		if is_instance_valid(source) and source.has_method("set_force_highlight"):
			source.set_force_highlight(true)

	# Provider View: Show icons on potential receivers
	if GameManager.grid_manager and GameManager.grid_manager.has_method("show_provider_icons"):
		GameManager.grid_manager.show_provider_icons(self)

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

	# --- Cleanup Hover Feedback ---
	# Receiver View
	for buff_type in buff_sources:
		var source = buff_sources[buff_type]
		if is_instance_valid(source) and source.has_method("set_force_highlight"):
			source.set_force_highlight(false)

	# Provider View
	if GameManager.grid_manager and GameManager.grid_manager.has_method("hide_provider_icons"):
		GameManager.grid_manager.hide_provider_icons()

	GameManager.hide_tooltip.emit()

func _draw():
	if is_hovered:
		var draw_radius = range_val
		if unit_data.get("attackType") == "melee":
			draw_radius = max(range_val, 100.0)

		draw_circle(Vector2.ZERO, draw_radius, Color(1, 1, 1, 0.1))
		draw_arc(Vector2.ZERO, draw_radius, 0, TAU, 64, Color(1, 1, 1, 0.3), 1.0)

	if _is_skill_highlight_active:
		# Draw a thick outline
		var size = Vector2(Constants.TILE_SIZE, Constants.TILE_SIZE)
		if unit_data and unit_data.has("size"):
			size = Vector2(unit_data.size.x * Constants.TILE_SIZE, unit_data.size.y * Constants.TILE_SIZE)

		var rect = Rect2(-size / 2, size)
		draw_rect(rect, _highlight_color, false, 4.0)

	if is_force_highlighted:
		var size = Vector2(Constants.TILE_SIZE, Constants.TILE_SIZE)
		if unit_data and unit_data.has("size"):
			size = Vector2(unit_data.size.x * Constants.TILE_SIZE, unit_data.size.y * Constants.TILE_SIZE)

		var rect = Rect2(-size / 2, size)
		draw_rect(rect, Color.WHITE, false, 4.0)

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

func _on_peacock_cleanup():
	for q in feather_refs:
		if is_instance_valid(q):
			q.queue_free()
	feather_refs.clear()

func play_buff_receive_anim():
	if visual_holder:
		var tween = create_tween()
		tween.tween_property(visual_holder, "scale", Vector2(1.3, 1.3), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(visual_holder, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func spawn_buff_effect(icon_char: String):
	# Create a temporary node for the effect
	var effect_node = Node2D.new()
	effect_node.name = "BuffEffect"
	effect_node.z_index = 101 # Above normal units

	# Create label
	var lbl = Label.new()
	lbl.text = icon_char
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Center label (approximate since sizing is tricky without rect control, but 0,0 with grow directions works)
	lbl.anchors_preset = Control.PRESET_CENTER
	lbl.position = Vector2(-20, -20) # Approx centering for 40x40 area
	lbl.size = Vector2(40, 40)

	effect_node.add_child(lbl)
	add_child(effect_node)

	effect_node.position = Vector2.ZERO # Local to unit

	var tween = create_tween()
	# Scale 1.0 -> 2.5
	tween.tween_property(effect_node, "scale", Vector2(2.5, 2.5), 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# Parallel Opacity 1.0 -> 0.0
	tween.parallel().tween_property(effect_node, "modulate:a", 0.0, 0.6)

	tween.finished.connect(effect_node.queue_free)


func attach_to_host(target_unit: Node2D):
	if !is_instance_valid(target_unit): return

	# Remove from current parent if any
	if get_parent():
		get_parent().remove_child(self)

	target_unit.add_child(self)
	self.host = target_unit
	target_unit.attachment = self

	# Visual adjustment
	# 0.35 * TILE_SIZE offset
	var offset_val = Constants.TILE_SIZE * 0.35
	self.position = Vector2(offset_val, -offset_val)
	self.scale = Vector2(0.5, 0.5)

	# Z-Index: host is usually 0 (or inherits), we want to be slightly higher.
	self.z_index = 1

	# Connect signal
	if !target_unit.attack_performed.is_connected(_on_host_attack_performed):
		target_unit.attack_performed.connect(_on_host_attack_performed)

	# Disable collision to prevent clicking/blocking
	var area = get_node_or_null("Area2D")
	if area:
		area.monitoring = false
		area.monitorable = false
		# Also disable input pickable just in case
		area.input_pickable = false

func _on_host_attack_performed(target):
	if type_key != "oxpecker": return
	if !host or !is_instance_valid(host): return

	# Brief delay
	await get_tree().create_timer(randf_range(0.1, 0.2)).timeout

	if !is_instance_valid(self) or !is_instance_valid(host): return

	# Calculate damage
	var dmg = host.max_hp * 0.1

	if GameManager.combat_manager:
		# Use self as source
		var target_node = target
		# If target is null or invalid, try find one? The prompt says "attack host's current target".

		# If target is null, we can try to find nearest enemy or just skip
		if target_node == null or !is_instance_valid(target_node):
			target_node = GameManager.combat_manager.find_nearest_enemy(global_position, range_val)

		if target_node:
			GameManager.combat_manager.spawn_projectile(self, global_position, target_node, {"damage": dmg})
