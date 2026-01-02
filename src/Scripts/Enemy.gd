extends CharacterBody2D

enum State { MOVE, ATTACK_BASE, STUNNED }
var state: State = State.MOVE

var type_key: String
var hp: float
var max_hp: float
var speed: float
var enemy_data: Dictionary
var slow_timer: float = 0.0
var freeze_timer: float = 0.0
var stun_timer: float = 0.0
var effects = { "burn": 0.0, "poison": 0.0 }
var _env_cooldowns = {} # Trap Instance ID -> Cooldown Timer

var poison_stacks: int = 0
var poison_power: float = 0.0
var poison_tick_timer: float = 0.0
var poison_trap_timer: float = 0.0

var burn_source: Node2D = null
var heat_accumulation: float = 0.0

var hit_flash_timer: float = 0.0
var burn_tick_timer: float = 0.0

var temp_speed_mod: float = 1.0

var wobble_scale = Vector2.ONE
var visual_offset = Vector2.ZERO
var visual_rotation = 0.0

var anim_time: float = 0.0
var anim_config: Dictionary = {}
var base_speed: float = 40.0 # Default fallback

var path: PackedVector2Array = []
var nav_timer: float = 0.0
var path_index: int = 0

var current_target_tile: Node2D = null
var base_attack_timer: float = 0.0

var anim_tween: Tween

var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_resistance: float = 1.0

# Boss / Special Properties
var stationary_timer: float = 0.0
var boss_skill: String = ""
var skill_cd_timer: float = 0.0
var is_suicide: bool = false
var is_stationary: bool = false
var last_hit_direction: Vector2 = Vector2.ZERO

# Physics Constants
const WALL_SLAM_FACTOR = 0.5
const HEAVY_IMPACT_THRESHOLD = 50.0
const TRANSFER_RATE = 0.8

# Mass
var mass: float = 1.0

# Sprite Animation System
var sprite_config: Dictionary = {}
var sprite_2d: Sprite2D = null
var current_anim_name: String = ""
var anim_frame_timer: float = 0.0
var is_anim_looping: bool = false
var anim_fps: float = 10.0

func _ready():
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 1 | 2

	input_pickable = false
	GameManager._set_ignore_mouse_recursive(self)

func setup(key: String, wave: int):
	type_key = key
	enemy_data = Constants.ENEMY_VARIANTS[key]
	anim_config = enemy_data.get("anim_config", {})
	sprite_config = enemy_data.get("sprite_config", {})

	var base_hp = 100 + (wave * 80)
	hp = base_hp * enemy_data.hpMod
	max_hp = hp

	# Store the initial speed calculation as base_speed reference for animation freq
	# But actually the requirement says (speed * temp_speed_mod) / base_speed.
	# If we assume base_speed is just the initial speed of this unit type for this wave:
	speed = (40 + (wave * 2)) * enemy_data.spdMod
	base_speed = speed

	stationary_timer = enemy_data.get("stationary_time", 0.0)
	boss_skill = enemy_data.get("boss_skill", "")
	is_suicide = enemy_data.get("is_suicide", false)

	if stationary_timer > 0.0:
		is_stationary = true

	if type_key == "boss" or type_key == "tank":
		knockback_resistance = 10.0
		mass = 5.0
	else:
		mass = 1.0

	var mass_mod = GameManager.get_stat_modifier("enemy_mass")
	mass *= mass_mod
	knockback_resistance *= mass_mod

	update_visuals()

func update_visuals():
	if not sprite_config.is_empty():
		_setup_sprite_visuals()
		if has_node("Label"): $Label.hide()
		if has_node("TextureRect"): $TextureRect.hide()
		return

	var icon_texture = AssetLoader.get_enemy_icon(type_key)

	if icon_texture:
		var tex_rect = get_node_or_null("TextureRect")
		if !tex_rect:
			tex_rect = TextureRect.new()
			tex_rect.name = "TextureRect"
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tex_rect.size = Vector2(40, 40)
			tex_rect.position = -tex_rect.size / 2
			tex_rect.pivot_offset = tex_rect.size / 2
			add_child(tex_rect)

		tex_rect.texture = icon_texture
		tex_rect.show()
		if has_node("Label"):
			$Label.hide()
	else:
		if has_node("TextureRect"):
			$TextureRect.hide()

		if has_node("Label"):
			$Label.show()
			$Label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			$Label.text = enemy_data.icon
			$Label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			$Label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			if $Label.size.x == 0:
				$Label.size = Vector2(40, 40)
				$Label.position = -$Label.size / 2
			$Label.pivot_offset = $Label.size / 2

	queue_redraw()

func _draw():
	draw_set_transform(visual_offset, visual_rotation, wobble_scale)
	var color = enemy_data.color
	if hit_flash_timer > 0:
		color = Color.WHITE

	if not sprite_2d:
		draw_circle(Vector2.ZERO, enemy_data.radius, color)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if hp < max_hp and hp > 0:
		var hp_pct = hp / max_hp
		var bar_w = 20
		var bar_h = 4
		var bar_pos = Vector2(-bar_w/2, -enemy_data.radius - 8)
		draw_rect(Rect2(bar_pos, Vector2(bar_w, bar_h)), Color.RED)
		draw_rect(Rect2(bar_pos, Vector2(bar_w * hp_pct, bar_h)), Color.GREEN)

func _physics_process(delta):
	if !GameManager.is_wave_active: return

	# Update Environmental Cooldowns
	var finished_cooldowns = []
	for trap_id in _env_cooldowns:
		_env_cooldowns[trap_id] -= delta
		if _env_cooldowns[trap_id] <= 0:
			finished_cooldowns.append(trap_id)

	for id in finished_cooldowns:
		_env_cooldowns.erase(id)

	# Process Timers and Effects
	_process_effects(delta)
	_update_animation(delta)
	_process_sprite_animation(delta)

	var is_knockback = knockback_velocity.length() > 10.0

	if is_knockback:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 500.0 * delta)
		move_and_slide()
		handle_collisions(delta)
		return

	if stun_timer > 0:
		state = State.STUNNED
	elif state == State.STUNNED:
		state = State.MOVE

	if freeze_timer > 0:
		return

	check_unit_interactions(delta)

	if is_stationary:
		stationary_timer -= delta
		skill_cd_timer -= delta
		if stationary_timer <= 0:
			is_stationary = false
		else:
			if boss_skill != "" and skill_cd_timer <= 0:
				perform_boss_skill(boss_skill)
				skill_cd_timer = 2.0
			return

	if is_suicide:
		check_suicide_collision()

	match state:
		State.STUNNED:
			velocity = velocity.move_toward(Vector2.ZERO, 500 * delta)
			move_and_slide()

		State.MOVE:
			nav_timer -= delta
			if nav_timer <= 0:
				update_path()
				nav_timer = 0.5

			var desired_velocity = calculate_move_velocity()

			# Check transition to Attack Base
			if _should_attack_base():
				state = State.ATTACK_BASE
				velocity = Vector2.ZERO
			else:
				velocity = desired_velocity
				move_and_slide()

		State.ATTACK_BASE:
			if _should_stop_attacking_base():
				state = State.MOVE
			else:
				attack_base_logic(delta)
				velocity = Vector2.ZERO

	handle_collisions(delta)

func _should_attack_base() -> bool:
	# If ranged, check distance to Core directly if we want to shoot core.
	# But original logic uses current_target_tile which is a path node.
	# For ranged enemies, we want to stop when within range of the CORE, not just the tile.
	# However, update_path() targets the core or closest tile.
	var target_pos = GameManager.grid_manager.global_position

	if enemy_data.get("attackType") == "ranged":
		var dist = global_position.distance_to(target_pos)
		var range_val = enemy_data.get("range", 200.0)
		if dist < range_val:
			return true
	else:
		# Melee logic: close to next tile (which leads to core)
		if current_target_tile and is_instance_valid(current_target_tile):
			var d = global_position.distance_to(current_target_tile.global_position)
			var attack_range = enemy_data.radius + 10.0
			if d < attack_range:
				return true
	return false

func _should_stop_attacking_base() -> bool:
	var target_pos = GameManager.grid_manager.global_position

	if enemy_data.get("attackType") == "ranged":
		var dist = global_position.distance_to(target_pos)
		var range_val = enemy_data.get("range", 200.0)
		# Hysteresis
		return dist > range_val * 1.1
	else:
		if current_target_tile and is_instance_valid(current_target_tile):
			target_pos = current_target_tile.global_position

		var dist = global_position.distance_to(target_pos)
		var attack_range = enemy_data.radius + 10.0

		return dist > attack_range * 1.5

func handle_environmental_impact(trap_node):
	var trap_id = trap_node.get_instance_id()

	if _env_cooldowns.has(trap_id) and _env_cooldowns[trap_id] > 0:
		return

	if not trap_node.props: return
	var type = trap_node.props.get("type")

	if type == "reflect":
		take_damage(trap_node.props.get("strength", 10.0), trap_node, "physical")
		_env_cooldowns[trap_id] = 0.5
	elif type == "poison":
		apply_poison(null, 1, 3.0)
		_env_cooldowns[trap_id] = 0.5
	elif type == "slow":
		slow_timer = 0.1 # Continually refresh while in area

	if trap_node.has_method("spawn_splash_effect"):
		trap_node.spawn_splash_effect(global_position)

func _process_effects(delta):
	if has_node("BurnParticles"): $BurnParticles.emitting = (effects.burn > 0)
	if has_node("PoisonParticles"): $PoisonParticles.emitting = (effects.poison > 0)

	if stun_timer > 0: stun_timer -= delta

	if effects.burn > 0:
		effects.burn -= delta

	if effects.poison > 0:
		effects.poison -= delta
		if effects.poison <= 0:
			poison_stacks = 0
			poison_power = 0.0
			modulate = Color.WHITE

	if poison_stacks > 0:
		poison_tick_timer -= delta
		if poison_tick_timer <= 0:
			poison_tick_timer = Constants.POISON_TICK_INTERVAL
			take_damage(poison_power, null, "poison")
		var t = clamp(float(poison_stacks) / Constants.POISON_VISUAL_SATURATION_STACKS, 0.0, 1.0)
		modulate = Color.WHITE.lerp(Color(0.2, 1.0, 0.2), t)

	if has_node("Label"):
		$Label.scale = wobble_scale
		$Label.position = -$Label.size / 2 + visual_offset
		$Label.rotation = visual_rotation
	if has_node("TextureRect"):
		$TextureRect.scale = wobble_scale
		$TextureRect.position = -$TextureRect.size / 2 + visual_offset
		$TextureRect.rotation = visual_rotation

	if hit_flash_timer > 0:
		hit_flash_timer -= delta
		if hit_flash_timer <= 0: queue_redraw()

	if slow_timer > 0: slow_timer -= delta

	# Modulate handling
	var desired_modulate = Color.WHITE

	if freeze_timer > 0:
		freeze_timer -= delta
		desired_modulate = Color(0.5, 0.5, 1.0)
	elif poison_stacks > 0:
		var t = clamp(float(poison_stacks) / Constants.POISON_VISUAL_SATURATION_STACKS, 0.0, 1.0)
		desired_modulate = Color.WHITE.lerp(Color(0.2, 1.0, 0.2), t)

	if hit_flash_timer > 0 and sprite_2d:
		desired_modulate = Color(3, 3, 3, 1) # Bright flash for sprite

	modulate = desired_modulate

func _update_animation(delta):
	# Skip if attack animation is playing
	if anim_tween and anim_tween.is_valid():
		return

	if anim_config.is_empty():
		return

	var style = anim_config.get("style", "squash")
	var amp = anim_config.get("amplitude", 0.1)
	var freq = anim_config.get("base_freq", 1.0)

	# Avoid division by zero
	var effective_speed = speed
	if effective_speed < 1.0: effective_speed = 1.0

	# Dynamic frequency scaling: freq * (current_speed / base_speed)
	# If stationary (speed=0 in theory, but here speed is stat), use temp_speed_mod
	var speed_factor = (speed * temp_speed_mod) / max(1.0, base_speed)

	anim_time += delta * freq * speed_factor * 2.0 # * 2.0 PI factor approximation or just speed up

	match style:
		"squash":
			# Squash & Stretch
			var s = sin(anim_time)
			var y_scale = 1.0 + s * amp
			var x_scale = 1.0
			if y_scale > 0.01:
				x_scale = 1.0 / y_scale
			wobble_scale = Vector2(x_scale, y_scale)
			visual_offset = Vector2.ZERO
			visual_rotation = 0.0

		"bob":
			# Vertical bobbing
			var s = abs(sin(anim_time)) # Bob up and down (bounce)
			visual_offset = Vector2(0, -s * amp)
			wobble_scale = Vector2.ONE
			visual_rotation = 0.0

		"float":
			# Breathing / Floating
			var s = sin(anim_time)
			wobble_scale = Vector2.ONE * (1.0 + s * amp)
			visual_offset = Vector2.ZERO
			visual_rotation = 0.0

		"stiff":
			# Rotation wobble
			var s = sin(anim_time)
			visual_rotation = s * amp
			wobble_scale = Vector2.ONE
			visual_offset = Vector2.ZERO

	queue_redraw()

func handle_collisions(delta):
	var count = get_slide_collision_count()
	for i in range(count):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		var momentum = knockback_velocity.length() * mass

		if knockback_velocity.length() > 50.0:
			if collider is StaticBody2D or (collider is TileMap) or (collider.get_class() == "StaticBody2D"):
				var impact = momentum
				knockback_velocity = Vector2.ZERO
				velocity = Vector2.ZERO

				var dmg = impact * WALL_SLAM_FACTOR
				if dmg > 1:
					take_damage(dmg, null, "physical", null, 0)
					GameManager.spawn_floating_text(global_position, "Slam!", Color.GRAY)

				if impact > HEAVY_IMPACT_THRESHOLD:
					var impact_dir = -collision.get_normal()
					var norm_strength = clamp(impact / 100.0, 0.0, 3.0)
					GameManager.trigger_impact(impact_dir, norm_strength)

				apply_physics_stagger(1.5)

			elif collider is CharacterBody2D and collider.is_in_group("enemies"):
				var target = collider
				if target.has_method("apply_physics_stagger"):
					var t_mass = 1.0
					if "mass" in target: t_mass = target.mass

					var ratio = mass / t_mass

					if "knockback_velocity" in target:
						target.knockback_velocity = knockback_velocity * ratio * TRANSFER_RATE

					if mass > t_mass * 1.5:
						target.apply_physics_stagger(1.0)

					if t_mass > mass * 2:
						apply_physics_stagger(0.5)
						knockback_velocity = -knockback_velocity * 0.5
					else:
						knockback_velocity = knockback_velocity * 0.5

func calculate_move_velocity() -> Vector2:
	var target_pos = GameManager.grid_manager.global_position
	if current_target_tile and is_instance_valid(current_target_tile):
		target_pos = current_target_tile.global_position

	if path.size() > path_index:
		target_pos = path[path_index]

	var dist = global_position.distance_to(target_pos)
	if dist < 10:
		if path.size() > path_index:
			path_index += 1
			if path_index < path.size():
				target_pos = path[path_index]

	var direction = (target_pos - global_position).normalized()

	temp_speed_mod = 1.0
	if slow_timer > 0: temp_speed_mod = 0.5

	return direction * speed * temp_speed_mod

func apply_physics_stagger(duration: float):
	if anim_tween and anim_tween.is_valid():
		anim_tween.kill()
		wobble_scale = Vector2.ONE

	apply_stun(duration)

func apply_poison(source_unit, stacks_added, duration):
	if poison_stacks == 0:
		poison_tick_timer = Constants.POISON_TICK_INTERVAL
	effects["poison"] = duration
	if poison_stacks < Constants.POISON_MAX_STACKS:
		poison_stacks += stacks_added
		if poison_stacks > Constants.POISON_MAX_STACKS: poison_stacks = Constants.POISON_MAX_STACKS
		var base_dmg = 10.0
		if source_unit and is_instance_valid(source_unit) and source_unit.get("damage"):
			base_dmg = source_unit.damage
		var damage_increment = base_dmg * Constants.POISON_DAMAGE_RATIO * stacks_added
		poison_power += damage_increment

func check_suicide_collision():
	if GameManager.grid_manager:
		var core_dist = global_position.distance_to(GameManager.grid_manager.global_position)
		if core_dist < 40.0:
			explode_suicide(null)

func explode_suicide(target_wall):
	GameManager.damage_core(enemy_data.dmg)
	GameManager.spawn_floating_text(global_position, "BOOM!", Color.RED)
	var effect = load("res://src/Scripts/Effects/SlashEffect.gd").new()
	get_parent().add_child(effect)
	effect.global_position = global_position
	effect.configure("cross", Color.ORANGE)
	effect.scale = Vector2(2, 2)
	effect.play()
	queue_free()

func perform_boss_skill(skill_name: String):
	if not sprite_config.is_empty():
		play_sprite_anim("action")

	if skill_name == "summon":
		GameManager.spawn_floating_text(global_position, "Summon!", Color.PURPLE)
		for i in range(3):
			var offset = Vector2(randf_range(-40, 40), randf_range(-40, 40))
			if GameManager.combat_manager:
				GameManager.combat_manager._spawn_enemy_at_pos(global_position + offset, "minion")
	elif skill_name == "shoot_enemy":
		GameManager.spawn_floating_text(global_position, "Fire!", Color.ORANGE)
		if GameManager.combat_manager:
			GameManager.combat_manager._spawn_enemy_at_pos(global_position, "bullet_entity")

func apply_stun(duration: float):
	stun_timer = duration
	GameManager.spawn_floating_text(global_position, "Stunned!", Color.GRAY)

func apply_freeze(duration: float):
	freeze_timer = duration
	GameManager.spawn_floating_text(global_position, "Frozen!", Color.CYAN)

func check_unit_interactions(delta):
	if !GameManager.grid_manager: return
	var grid_pos = GameManager.grid_manager.local_to_grid(global_position)
	var tile_key = GameManager.grid_manager.get_tile_key(grid_pos.x, grid_pos.y)
	if GameManager.grid_manager.tiles.has(tile_key):
		var tile = GameManager.grid_manager.tiles[tile_key]
		var unit = tile.unit
		if unit and is_instance_valid(unit):
			if unit.unit_data.get("trait") == "dodge_counter":
				_trigger_rabbit_interaction(unit)

var _rabbit_interaction_timer: float = 0.0

func _trigger_rabbit_interaction(unit):
	if _rabbit_interaction_timer > 0:
		_rabbit_interaction_timer -= get_process_delta_time()
		return
	_rabbit_interaction_timer = 1.0
	var dodge_rate = unit.unit_data.get("dodge_rate", 0.3)
	if randf() < dodge_rate:
		GameManager.spawn_floating_text(unit.global_position, "Miss!", Color.YELLOW)
		take_damage(unit.damage, unit, "physical")
	else:
		unit.play_attack_anim("melee", global_position)
		unit.take_damage(enemy_data.dmg, self)

func attack_base_logic(delta):
	var target_pos = GameManager.grid_manager.global_position
	if current_target_tile and is_instance_valid(current_target_tile):
		target_pos = current_target_tile.global_position

	base_attack_timer -= delta
	if base_attack_timer <= 0:
		base_attack_timer = 1.0 / enemy_data.atkSpeed

		if enemy_data.get("attackType") == "ranged":
			play_attack_animation(target_pos, func():
				# Ranged Attack Logic
				if GameManager.combat_manager:
					var proj_type = enemy_data.get("proj", "pinecone")
					# Ranged enemies aim at Core center
					var core_pos = GameManager.grid_manager.global_position

					var stats = {
						"damageType": "physical", # Enemies usually physical?
						"source": self
					}
					GameManager.combat_manager.spawn_projectile(self, global_position, null, {
						"target_pos": core_pos,
						"type": proj_type,
						"damage": enemy_data.dmg,
						"speed": enemy_data.get("projectileSpeed", 300.0),
						"damageType": "physical" # Or from data
					})
			)
		else:
			# Melee Attack Logic
			play_attack_animation(target_pos, func():
				GameManager.damage_core(enemy_data.dmg)
				if current_target_tile and not is_instance_valid(current_target_tile):
					state = State.MOVE
					current_target_tile = null
					update_path()
			)

func update_path():
	if !GameManager.grid_manager: return
	var target_pos = Vector2.ZERO
	current_target_tile = null
	if GameManager.grid_manager.has_method("get_closest_unlocked_tile"):
		current_target_tile = GameManager.grid_manager.get_closest_unlocked_tile(global_position)
		if current_target_tile:
			target_pos = current_target_tile.global_position
		else:
			target_pos = GameManager.grid_manager.global_position
	else:
		target_pos = GameManager.grid_manager.global_position
	path = GameManager.grid_manager.get_nav_path(global_position, target_pos)
	if path.size() == 0:
		path = []
	else:
		path_index = 0
		if path.size() > 0 and global_position.distance_to(path[0]) < 10:
			path_index = 1

func play_attack_animation(target_pos: Vector2, hit_callback: Callable = Callable()):
	if anim_tween and anim_tween.is_valid():
		anim_tween.kill()

	anim_tween = create_tween()
	var original_pos = global_position
	var diff = target_pos - original_pos
	var direction = diff.normalized()

	var anim_type = "melee"
	if enemy_data.get("attackType") == "ranged":
		anim_type = enemy_data.get("rangedAnimType", "recoil")

	if anim_type == "melee":
		# Melee: Windup -> Strike -> Recovery (Unified with Unit.gd)
		# Phase 1: Windup
		anim_tween.set_parallel(true)
		anim_tween.tween_property(self, "global_position", original_pos - direction * Constants.ANIM_WINDUP_DIST, Constants.ANIM_WINDUP_TIME)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		anim_tween.tween_property(self, "wobble_scale", Constants.ANIM_WINDUP_SCALE, Constants.ANIM_WINDUP_TIME)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		anim_tween.set_parallel(false)

		# Phase 2: Strike
		anim_tween.set_parallel(true)
		anim_tween.tween_property(self, "global_position", original_pos + direction * Constants.ANIM_STRIKE_DIST, Constants.ANIM_STRIKE_TIME)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		anim_tween.tween_property(self, "wobble_scale", Constants.ANIM_STRIKE_SCALE, Constants.ANIM_STRIKE_TIME)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		anim_tween.set_parallel(false)

		# Callback on impact
		anim_tween.tween_callback(func():
			spawn_slash_effect(target_pos)
			if hit_callback.is_valid():
				hit_callback.call()
		)

		# Phase 3: Recovery
		anim_tween.set_parallel(true)
		anim_tween.tween_property(self, "global_position", original_pos, Constants.ANIM_RECOVERY_TIME)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		anim_tween.tween_property(self, "wobble_scale", Vector2.ONE, Constants.ANIM_RECOVERY_TIME)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		anim_tween.set_parallel(false)

	elif anim_type == "recoil":
		# Ranged Recoil: Scale 0.8 -> 1.0
		anim_tween.tween_callback(func():
			if hit_callback.is_valid():
				hit_callback.call()
		)
		anim_tween.tween_property(self, "wobble_scale", Vector2(0.8, 0.8), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		anim_tween.tween_property(self, "wobble_scale", Vector2.ONE, 0.2)
		# Ensure position reset if it was modified
		anim_tween.parallel().tween_property(self, "global_position", original_pos, 0.1)

	elif anim_type == "lunge":
		# Ranged Lunge: Small forward dash -> Fire -> Return
		# Lunge forward
		anim_tween.tween_property(self, "global_position", original_pos + direction * 10.0, 0.15)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		# Fire callback
		anim_tween.tween_callback(func():
			if hit_callback.is_valid():
				hit_callback.call()
		)

		# Return
		anim_tween.tween_property(self, "global_position", original_pos, 0.2)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func spawn_slash_effect(pos: Vector2):
	var effect = load("res://src/Scripts/Effects/SlashEffect.gd").new()
	get_parent().add_child(effect)
	effect.global_position = pos
	effect.rotation = randf() * TAU
	var shape = "slash"
	var col = Color.WHITE
	if type_key in ["wolf", "boss"]:
		shape = "bite"
		col = Color.RED
	elif type_key in ["slime", "poison"]:
		shape = "bite"
		col = Color.WHITE
	else:
		shape = "cross"
		col = Color.WHITE
	if randf() > 0.5: col = Color(1.0, 0.8, 0.8)
	effect.configure(shape, col)
	effect.play()

func is_trap(node):
	if node.get("type") and Constants.BARRICADE_TYPES.has(node.type):
		var b_type = Constants.BARRICADE_TYPES[node.type].type
		return b_type == "slow" or b_type == "poison" or b_type == "reflect"
	return false

func take_damage(amount: float, source_unit = null, damage_type: String = "physical", hit_source: Node2D = null, kb_force: float = 0.0):
	hp -= amount
	hit_flash_timer = 0.1
	queue_redraw()
	var hit_dir = Vector2.ZERO
	if hit_source and is_instance_valid(hit_source) and "speed" in hit_source:
		hit_dir = Vector2.RIGHT.rotated(hit_source.rotation)
	last_hit_direction = hit_dir
	if kb_force > 0:
		var applied_force = kb_force / max(0.1, knockback_resistance)
		knockback_velocity += hit_dir * applied_force
	var display_val = max(1, int(amount))
	GameManager.spawn_floating_text(global_position, str(display_val), damage_type, hit_dir)
	if source_unit:
		GameManager.damage_dealt.emit(source_unit, amount)
	if hp <= 0:
		die()

func die():
	if effects.get("burn", 0) > 0:
		effects["burn"] = 0.0
		_trigger_burn_explosion()
	GameManager.add_gold(1)
	if GameManager.reward_manager and "scrap_recycling" in GameManager.reward_manager.acquired_artifacts:
		if GameManager.grid_manager:
			var core_pos = GameManager.grid_manager.global_position
			if global_position.distance_to(core_pos) < 200.0:
				GameManager.damage_core(-5)
				GameManager.add_gold(1)
				GameManager.spawn_floating_text(global_position, "+1💰 (Recycle)", Color.GOLD, last_hit_direction)
	GameManager.spawn_floating_text(global_position, "+1💰", Color.YELLOW, last_hit_direction)
	queue_free()

func _trigger_burn_explosion():
	GameManager.spawn_floating_text(global_position, "BOOM!", Color.ORANGE)
	var effect = load("res://src/Scripts/Effects/SlashEffect.gd").new()
	get_parent().add_child(effect)
	effect.global_position = global_position
	effect.configure("cross", Color.ORANGE)
	effect.scale = Vector2(3, 3)
	effect.play()
	var damage = 50.0
	if burn_source and is_instance_valid(burn_source):
		damage = burn_source.damage * 3.0
	if GameManager.combat_manager:
		GameManager.combat_manager.queue_burn_explosion(global_position, damage, burn_source)

func _setup_sprite_visuals():
	if not sprite_2d:
		sprite_2d = Sprite2D.new()
		sprite_2d.name = "Sprite2D"
		add_child(sprite_2d)

	play_sprite_anim("walk")

func play_sprite_anim(anim_name: String):
	if current_anim_name == anim_name and is_anim_looping: return

	var anims = sprite_config.get("animations", {})
	if not anims.has(anim_name): return

	var data = anims[anim_name]
	if data.is_empty(): return

	var path = data.get("path", "")
	var texture = load(path)
	if not texture: return

	current_anim_name = anim_name
	sprite_2d.texture = texture
	sprite_2d.hframes = data.get("cols", 1)
	sprite_2d.vframes = data.get("rows", 1)
	sprite_2d.frame = 0
	anim_fps = data.get("fps", 10)
	is_anim_looping = data.get("loop", true)
	anim_frame_timer = 0.0

	# Calculate Scale
	var size_in_tiles = sprite_config.get("size_in_tiles", [1.0, 1.0])
	var target_w = size_in_tiles[0] * Constants.TILE_SIZE
	var target_h = size_in_tiles[1] * Constants.TILE_SIZE

	var frame_w = texture.get_width() / sprite_2d.hframes
	var frame_h = texture.get_height() / sprite_2d.vframes

	# "scale = target / max(w, h)" logic
	# Assuming fitting the larger dimension of the frame into the larger dimension of the target box
	var target_max = max(target_w, target_h)
	var frame_max = max(frame_w, frame_h)
	var final_scale = 1.0
	if frame_max > 0:
		final_scale = target_max / frame_max

	sprite_2d.scale = Vector2(final_scale, final_scale)
	sprite_2d.position = Vector2.ZERO

func _process_sprite_animation(delta):
	if not sprite_2d or current_anim_name == "": return

	anim_frame_timer += delta
	if anim_frame_timer >= 1.0 / anim_fps:
		anim_frame_timer -= 1.0 / anim_fps
		var next_frame = sprite_2d.frame + 1
		var total_frames = sprite_2d.hframes * sprite_2d.vframes

		if next_frame >= total_frames:
			if is_anim_looping:
				sprite_2d.frame = 0
			else:
				# Finished one-shot
				_on_anim_finished()
		else:
			sprite_2d.frame = next_frame

func _on_anim_finished():
	if current_anim_name == "action":
		play_sprite_anim("walk")
