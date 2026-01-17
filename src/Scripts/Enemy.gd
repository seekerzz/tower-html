extends CharacterBody2D

enum State { MOVE, ATTACK_BASE, STUNNED, SUPPORT }
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

var visual_controller: Node2D = null

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
const FLIP_THRESHOLD = 15.0

# Mass
var mass: float = 1.0
var is_facing_left: bool = false
var is_dying: bool = false

# Rotation Physics (Crab)
var angular_velocity: float = 0.0
var rotational_damping: float = 5.0
var rotation_sensitivity = 5.0

# Mutant Slime Properties
var split_generation: int = 0
var hit_count: int = 0
var ancestor_max_hp: float = 0.0
var invincible_timer: float = 0.0
var is_splitting: bool = false

func _ready():
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 1 | 2

	input_pickable = false
	GameManager._set_ignore_mouse_recursive(self)

	_ensure_visual_controller()

func setup(key: String, wave: int):
	_ensure_visual_controller()

	type_key = key
	enemy_data = Constants.ENEMY_VARIANTS[key]
	anim_config = enemy_data.get("anim_config", {})

	var base_hp = 100 + (wave * 80)
	hp = base_hp * enemy_data.hpMod
	max_hp = hp

	if split_generation == 0:
		ancestor_max_hp = max_hp
		if type_key == "mutant_slime":
			scale = Vector2(1.5, 1.5)

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

	# Collision Shape Logic
	var col_shape = get_node_or_null("CollisionShape2D")
	if !col_shape:
		col_shape = CollisionShape2D.new()
		col_shape.name = "CollisionShape2D"
		add_child(col_shape)

	if type_key == "boss" or type_key == "tank":
		knockback_resistance = 10.0
		mass = 5.0
		# Boss default shape (Circle)
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = enemy_data.radius
		col_shape.shape = circle_shape

	elif enemy_data.get("shape") == "rect":
		# Crab Setup
		knockback_resistance = 8.0
		mass = 5.0

		# Setup Rectangle Collision
		var size_grid = enemy_data.get("size_grid", [1, 1])
		var tile_size = 60 # Default
		if GameManager.grid_manager:
			tile_size = GameManager.grid_manager.TILE_SIZE

		var rect_size = Vector2(size_grid[0] * tile_size, size_grid[1] * tile_size)

		var rect_shape = RectangleShape2D.new()
		rect_shape.size = rect_size * 0.8 # Slightly smaller than grid to avoid sticking
		col_shape.shape = rect_shape

	else:
		mass = 1.0
		# Default Circle Collision
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = enemy_data.radius
		col_shape.shape = circle_shape

	var mass_mod = GameManager.get_stat_modifier("enemy_mass")
	mass *= mass_mod
	knockback_resistance *= mass_mod

	visual_controller.setup(anim_config, base_speed, speed)
	update_visuals()

func _ensure_visual_controller():
	if not visual_controller:
		visual_controller = load("res://src/Scripts/Components/VisualController.gd").new()
		add_child(visual_controller)

func update_visuals():
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
	if visual_controller:
		draw_set_transform(visual_controller.visual_offset, visual_controller.visual_rotation, visual_controller.wobble_scale)
	var color = enemy_data.color
	if hit_flash_timer > 0:
		color = Color.WHITE

	if enemy_data.get("shape") == "rect":
		var size_grid = enemy_data.get("size_grid", [2, 1])
		var tile_size = 60
		if GameManager.grid_manager:
			tile_size = GameManager.grid_manager.TILE_SIZE

		var w = size_grid[0] * tile_size
		var h = size_grid[1] * tile_size
		var rect = Rect2(-w/2, -h/2, w, h)
		draw_rect(rect, color)
	else:
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

	if invincible_timer > 0:
		invincible_timer -= delta

	# Update Environmental Cooldowns
	var finished_cooldowns = []
	for trap_id in _env_cooldowns:
		_env_cooldowns[trap_id] -= delta
		if _env_cooldowns[trap_id] <= 0:
			finished_cooldowns.append(trap_id)

	for id in finished_cooldowns:
		_env_cooldowns.erase(id)

	# Process Timers and Effects
	if not is_dying:
		if enemy_data.get("shape") == "rect":
			# Apply Physics Rotation
			rotation += angular_velocity * delta * rotation_sensitivity
			angular_velocity = lerp(angular_velocity, 0.0, rotational_damping * delta)
		else:
			_update_facing_logic()

	_process_effects(delta)

	# Update visual controller speed info and apply transforms
	# Note: We must apply visual transforms AFTER _process_effects or carefully coordinate
	# because _process_effects also sets scale (flip X).
	# However, _process_effects relies on visual_controller.wobble_scale.
	# The best approach: Let VisualController set the base transform, then apply facing flip.
	# _process_effects currently does exactly this (reads wobble_scale, sets scale with flip).
	# So we just need to update the speed on the controller here.
	if visual_controller:
		visual_controller.update_speed(speed, temp_speed_mod)
		# Disable idle animation if a legacy attack tween is playing
		var is_legacy_anim_playing = (anim_tween and anim_tween.is_valid())
		visual_controller.set_idle_enabled(not is_legacy_anim_playing)

	if is_dying:
		return

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

	# check_unit_interactions(delta) # Removed Rabbit interaction

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

func _update_facing_logic():
	if !GameManager.grid_manager: return

	var core_pos = GameManager.grid_manager.global_position
	var diff_x = global_position.x - core_pos.x

	if diff_x > FLIP_THRESHOLD:
		is_facing_left = true
	elif diff_x < -FLIP_THRESHOLD:
		is_facing_left = false

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

	# Apply Visual Controller transforms
	if visual_controller:
		if has_node("TextureRect"):
			visual_controller.apply_to($TextureRect)
		elif has_node("Label"):
			visual_controller.apply_to($Label)

	# Handling facing flip on top of visual controller scale
	var final_scale_x = 1.0
	if visual_controller:
		final_scale_x = visual_controller.wobble_scale.x

	if is_facing_left:
		final_scale_x = -abs(final_scale_x)
	else:
		final_scale_x = abs(final_scale_x)

	# Force override X scale for facing
	if has_node("TextureRect"):
		$TextureRect.scale.x = final_scale_x
	if has_node("Label"):
		$Label.scale.x = final_scale_x

	if has_node("Sprite2D"):
		$Sprite2D.flip_h = is_facing_left

	if hit_flash_timer > 0:
		hit_flash_timer -= delta
		if hit_flash_timer <= 0: queue_redraw()

	if slow_timer > 0: slow_timer -= delta
	if freeze_timer > 0:
		freeze_timer -= delta
		modulate = Color(0.5, 0.5, 1.0)
	else:
		if poison_stacks == 0: modulate = Color.WHITE


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
	if visual_controller:
		visual_controller.kill_tween()
		visual_controller.wobble_scale = Vector2.ONE

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
		if visual_controller:
			anim_tween.tween_property(visual_controller, "wobble_scale", Constants.ANIM_WINDUP_SCALE, Constants.ANIM_WINDUP_TIME)\
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		anim_tween.set_parallel(false)

		# Phase 2: Strike
		anim_tween.set_parallel(true)
		anim_tween.tween_property(self, "global_position", original_pos + direction * Constants.ANIM_STRIKE_DIST, Constants.ANIM_STRIKE_TIME)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		if visual_controller:
			anim_tween.tween_property(visual_controller, "wobble_scale", Constants.ANIM_STRIKE_SCALE, Constants.ANIM_STRIKE_TIME)\
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
		if visual_controller:
			anim_tween.tween_property(visual_controller, "wobble_scale", Vector2.ONE, Constants.ANIM_RECOVERY_TIME)\
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		anim_tween.set_parallel(false)

	elif anim_type == "recoil":
		# Ranged Recoil: Scale 0.8 -> 1.0
		anim_tween.tween_callback(func():
			if hit_callback.is_valid():
				hit_callback.call()
		)
		if visual_controller:
			anim_tween.tween_property(visual_controller, "wobble_scale", Vector2(0.8, 0.8), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			anim_tween.tween_property(visual_controller, "wobble_scale", Vector2.ONE, 0.2)
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

	elif anim_type == "elastic_shoot":
		if visual_controller:
			var tween = visual_controller.play_elastic_shoot()
			# Sync firing with the middle of the animation
			tween.tween_callback(func():
				if hit_callback.is_valid():
					hit_callback.call()
			).set_delay(0.4) # Wait for windup (0.3) + shoot (0.1) start
		else:
			if hit_callback.is_valid():
				hit_callback.call()

	elif anim_type == "elastic_slash":
		if visual_controller:
			var tween = visual_controller.play_elastic_slash()
			tween.tween_callback(func():
				spawn_slash_effect(target_pos)
				if hit_callback.is_valid():
					hit_callback.call()
			).set_delay(0.4) # Wait for windup
		else:
			if hit_callback.is_valid():
				hit_callback.call()

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

func heal(amount: float):
	if hp <= 0: return # Can't heal dead
	hp = min(hp + amount, max_hp)
	queue_redraw()
	# Optional: Spawn healing text here if not done by the healer
	# But healer does it.

func take_damage(amount: float, source_unit = null, damage_type: String = "physical", hit_source: Node2D = null, kb_force: float = 0.0):
	if source_unit == GameManager:
		print("[Enemy] Taking global damage from GameManager: ", amount)

	if invincible_timer > 0 or is_splitting:
		return

	hit_count += 1

	if type_key == "mutant_slime" and hit_count >= 5 and split_generation < 2 and hp > 0:
		is_splitting = true
		_perform_split()
		return

	hp -= amount
	hit_flash_timer = 0.1
	queue_redraw()
	var hit_dir = Vector2.ZERO
	if hit_source and is_instance_valid(hit_source) and "speed" in hit_source:
		hit_dir = Vector2.RIGHT.rotated(hit_source.rotation)
	last_hit_direction = hit_dir

	if enemy_data.get("shape") == "rect":
		# Torque calculation
		# hit_source position relative to center
		var hit_pos = global_position # Default
		if hit_source and "global_position" in hit_source:
			hit_pos = hit_source.global_position

		var r = hit_pos - global_position
		# F is force vector. Approximate from hit_dir
		var force_dir = hit_dir
		if force_dir == Vector2.ZERO and hit_source:
			force_dir = (global_position - hit_source.global_position).normalized()

		# Torque = r x F (2D Cross Product is scalar)
		# A x B = Ax*By - Ay*Bx
		var torque = r.x * force_dir.y - r.y * force_dir.x

		# Scale torque
		angular_velocity += torque * 0.05 # Sensitivity factor reduced

	if kb_force > 0:
		var applied_force = kb_force / max(0.1, knockback_resistance)
		knockback_velocity += hit_dir * applied_force
	var display_val = max(1, int(amount))
	GameManager.spawn_floating_text(global_position, str(display_val), damage_type, hit_dir)
	if source_unit:
		GameManager.damage_dealt.emit(source_unit, amount)
	if hp <= 0:
		die(source_unit)

func _perform_split():
	var child_hp = min(hp, max_hp / 2.0)

	for i in range(2):
		var child = load("res://src/Scenes/Game/Enemy.tscn").instantiate()
		child.setup(type_key, GameManager.wave)

		child.split_generation = split_generation + 1
		child.ancestor_max_hp = ancestor_max_hp
		child.max_hp = child_hp
		child.hp = child_hp
		child.hit_count = 0

		var new_scale = 1.0
		if child.split_generation == 1:
			new_scale = 1.0
		elif child.split_generation == 2:
			new_scale = 0.75

		child.scale = Vector2(new_scale, new_scale)
		child.invincible_timer = 0.5

		var offset = Vector2(randf_range(-20, 20), randf_range(-20, 20))
		child.global_position = global_position + offset

		get_parent().add_child(child)

	queue_free()

func die(killer_unit = null):
	# Kill Bonus Check
	if GameManager.combat_manager and killer_unit:
		GameManager.combat_manager.check_kill_bonuses(killer_unit)

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

	if enemy_data.get("is_boss", false) and visual_controller:
		# Disable collision and logic
		collision_layer = 0
		collision_mask = 0
		is_dying = true

		var death_tween = visual_controller.play_death_implosion()

		# Turn gray
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color.GRAY, 0.5)

		await death_tween.finished
		queue_free()
	else:
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
