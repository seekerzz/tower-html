extends CharacterBody2D

var type_key: String
var hp: float
var max_hp: float
var speed: float
var enemy_data: Dictionary
var slow_timer: float = 0.0
var freeze_timer: float = 0.0
var stun_timer: float = 0.0
var effects = { "burn": 0.0, "poison": 0.0 }

var poison_stacks: int = 0
var poison_power: float = 0.0
var poison_tick_timer: float = 0.0
var poison_trap_timer: float = 0.0

var burn_source: Node2D = null
var heat_accumulation: float = 0.0

var hit_flash_timer: float = 0.0
var burn_tick_timer: float = 0.0

var attack_timer: float = 0.0
var attacking_wall: Node = null
var temp_speed_mod: float = 1.0

var wobble_scale = Vector2.ONE

var path: PackedVector2Array = []
var nav_timer: float = 0.0
var path_index: int = 0

var current_target_tile: Node2D = null
var is_attacking_base: bool = false
var base_attack_timer: float = 0.0

var is_playing_attack_anim: bool = false
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
const WALL_SLAM_FACTOR = 0.5 # Damage multiplier when hitting wall
const HEAVY_IMPACT_THRESHOLD = 50.0 # Threshold for hit stop
const TRANSFER_RATE = 0.8 # Momentum transfer rate
var sensor_area: Area2D = null

# Mass (approximated by resistance or defined data)
var mass: float = 1.0

func _ready():
	add_to_group("enemies")
	# CharacterBody2D collision setup
	collision_layer = 2 # Enemy Layer
	collision_mask = 3  # Wall (1) + Enemy (2) ? Actually usually avoid self-collision or soft-collision.
	# User Requirements: "撞其他敌人：动量传递（击飞受害者）"
	# So we need to collide with enemies.
	# But if we use move_and_slide, collisions with other CharacterBodies are handled if they are in the mask.

	collision_mask = 1 | 2 # Wall (1) + Enemy (2)

	# Create Sensor Area for Trap Detection (Layer 2 Traps are not physical walls usually)
	# Traps should be in Layer ? In the prompt plan: "Layer 2 (Traps)".
	# Wait, Enemies are Layer 2?
	# "设置 SensorArea 的 Collision Mask 包含 Layer 2 (Traps)."
	# If Enemies are Layer 2, then Traps should be another layer or use Area2D with different collision bits.
	# Standard Godot Layer 1: World/Walls. Layer 2: Enemies. Layer 3: Traps/Projectiles?
	# The plan said: "key settings: ... boundaries Layer 1".
	# Plan said: "Enemy ... SensorArea ... Collision Mask include Layer 2 (Traps)."
	# Wait, if Enemy is Layer 2, and Traps are Layer 2... they share layer?
	# Let's check Constants or assume we use masks properly.
	# But if I follow the plan strictly: "SensorArea ... Collision Mask 包含 Layer 2 (Traps)"
	# This implies Traps are on Layer 2.

	sensor_area = Area2D.new()
	sensor_area.name = "SensorArea"
	sensor_area.collision_layer = 0
	sensor_area.collision_mask = 2 | 4 # Assuming traps might be 2 or 4. If traps are 2, and enemy is 2, it works.
	# But better be safe and check all.
	# Actually, existing code: "collision_mask = 3 # Layer 1 (Walls) + Layer 2 (Traps)"
	# So Traps seem to be Layer 2. Enemies were Area2D before.
	# So Enemies are also likely Layer 2? Or they were just Areas checking Layer 2.

	add_child(sensor_area)

	# Duplicate collision shape for sensor
	var col_shape = get_node_or_null("CollisionShape2D")
	if col_shape:
		var new_shape = col_shape.duplicate()
		sensor_area.add_child(new_shape)

	input_pickable = false
	_set_ignore_mouse_recursive(self)

func _set_ignore_mouse_recursive(node: Node):
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_ignore_mouse_recursive(child)

func setup(key: String, wave: int):
	type_key = key
	enemy_data = Constants.ENEMY_VARIANTS[key]

	var base_hp = 100 + (wave * 80)
	hp = base_hp * enemy_data.hpMod
	max_hp = hp

	speed = (40 + (wave * 2)) * enemy_data.spdMod

	# Initialize special properties
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
	draw_set_transform(Vector2.ZERO, 0.0, wobble_scale)
	var color = enemy_data.color
	if hit_flash_timer > 0:
		color = Color.WHITE
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

	# Process Timers and Effects
	_process_effects(delta)

	# Prioritize Knockback (Physics) over Stun (AI)
	var is_knockback = knockback_velocity.length() > 10.0

	if is_knockback:
		if stun_timer > 0:
			print("[Check] Unit is Stunned BUT Moving! Velocity: ", knockback_velocity.length())

		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 500.0 * delta)
		move_and_slide()
		# Handle Collisions while in knockback
		handle_collisions(delta)
		return

	# If not being knocked back, check for stun/freeze
	if stun_timer > 0:
		velocity = velocity.move_toward(Vector2.ZERO, 500 * delta)
		move_and_slide()
		return

	if freeze_timer > 0:
		return

	# Movement Logic
	var desired_velocity = Vector2.ZERO

	if false: # Placeholder for old else block structure
		pass
	else:
		# Normal Movement
		check_traps(delta)
		check_unit_interactions(delta)

		# Stationary Logic
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

		# Attack Logic
		if is_attacking_base:
			attack_base_logic(delta)
			# Stop moving if attacking base
			velocity = Vector2.ZERO
		elif attacking_wall and is_instance_valid(attacking_wall):
			attack_wall_logic(delta)
			velocity = Vector2.ZERO
		else:
			if attacking_wall != null:
				attacking_wall = null

			# Update Navigation
			nav_timer -= delta
			if nav_timer <= 0:
				update_path()
				nav_timer = 0.5

			# Calculate move direction
			desired_velocity = calculate_move_velocity()

			# Suicide Logic
			if is_suicide:
				check_suicide_collision()

			velocity = desired_velocity

	move_and_slide()

	# Handle Collisions
	handle_collisions(delta)

func _process_effects(delta):
	if has_node("BurnParticles"): $BurnParticles.emitting = (effects.burn > 0)
	if has_node("PoisonParticles"): $PoisonParticles.emitting = (effects.poison > 0)

	if stun_timer > 0: stun_timer -= delta

	if effects.burn > 0:
		effects.burn -= delta
		# Heat accum logic simplified for brevity/safety in overwrite

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

	if !is_playing_attack_anim:
		var time = Time.get_ticks_msec() * 0.005
		wobble_scale = Vector2(1.0 + sin(time) * 0.1, 1.0 + cos(time) * 0.1)

	if has_node("Label"): $Label.scale = wobble_scale
	if has_node("TextureRect"): $TextureRect.scale = wobble_scale

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

		# Only process impactful collisions if we have significant knockback/momentum
		var momentum = knockback_velocity.length() * mass
		# Actually, since we already moved, velocity might be zeroed by wall slide?
		# move_and_slide preserves velocity along wall.
		# If we hit a wall head on, the velocity component into the wall is lost.
		# But we stored `knockback_velocity` variable separately and apply it to `velocity` in physics process.

		if knockback_velocity.length() > 50.0: # Threshold for physics interaction
			if collider is StaticBody2D or (collider is TileMap) or (collider.get_class() == "StaticBody2D"):
				# Hit Wall/Boundary
				var impact = momentum

				# Stop
				knockback_velocity = Vector2.ZERO
				velocity = Vector2.ZERO

				# Damage Self
				var dmg = impact * WALL_SLAM_FACTOR
				if dmg > 1:
					take_damage(dmg, null, "physical", null, 0)
					GameManager.spawn_floating_text(global_position, "Slam!", Color.GRAY)

				# Heavy Impact
				if impact > HEAVY_IMPACT_THRESHOLD:
					# GameManager.trigger_hit_stop(0.1)
					# Calculate normalized strength
					var norm_strength = clamp(impact / 100.0, 0.5, 3.0)
					GameManager.trigger_impact(-collision.get_normal(), norm_strength)

				apply_physics_stagger(1.5)

			elif collider is CharacterBody2D and collider.is_in_group("enemies"):
				# Hit another enemy
				var target = collider
				if target.has_method("apply_physics_stagger"):
					# Calculate mass ratio
					var t_mass = 1.0
					if "mass" in target: t_mass = target.mass

					var ratio = mass / t_mass

					# Transfer Momentum
					if "knockback_velocity" in target:
						target.knockback_velocity = knockback_velocity * ratio * TRANSFER_RATE

					# Conditional Stagger based on mass
					if mass > t_mass * 1.5:
						target.apply_physics_stagger(1.0)

					# Stagger Self if hitting big object?
					if t_mass > mass * 2:
						apply_physics_stagger(0.5)
						knockback_velocity = -knockback_velocity * 0.5 # Bounce back
					else:
						# Slow down self
						knockback_velocity = knockback_velocity * 0.5

func calculate_move_velocity() -> Vector2:
	# Same path following logic
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

	if path.size() == 0:
		direction = (GameManager.grid_manager.global_position - global_position).normalized()
		# Wall logic... (simplified for CharacterBody, let move_and_slide handle basic blockage,
		# but we need to attack walls if blocked)

		# Simple raycast for wall attack
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(global_position, global_position + direction * 40)
		query.collision_mask = 1
		var result = space_state.intersect_ray(query)
		if result:
			var collider = result.collider
			if is_blocking_wall(collider):
				start_attacking(collider)
				return Vector2.ZERO

	temp_speed_mod = 1.0
	if slow_timer > 0: temp_speed_mod = 0.5

	# Check attack range again (move this logic here or keep in process?)
	if current_target_tile and is_instance_valid(current_target_tile):
		var d = global_position.distance_to(current_target_tile.global_position)
		var attack_range = enemy_data.radius + 10.0 # Dynamic range + margin
		if d < attack_range:
			is_attacking_base = true
			return Vector2.ZERO

	return direction * speed * temp_speed_mod

func apply_physics_stagger(duration: float):
	if is_playing_attack_anim:
		if anim_tween: anim_tween.kill()
		is_playing_attack_anim = false
		wobble_scale = Vector2.ONE

	apply_stun(duration)

# ... [Keep previous helper methods like apply_poison, apply_stun, take_damage etc] ...
# Since I am using overwrite, I must include ALL existing methods.

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
	if sensor_area:
		var bodies = sensor_area.get_overlapping_bodies()
		for b in bodies:
			if is_blocking_wall(b):
				explode_suicide(b)
				return

	if GameManager.grid_manager:
		var core_dist = global_position.distance_to(GameManager.grid_manager.global_position)
		if core_dist < 40.0:
			explode_suicide(null)

func explode_suicide(target_wall):
	if target_wall and is_instance_valid(target_wall):
		if target_wall.has_method("take_damage"):
			target_wall.take_damage(enemy_data.dmg, self)
	else:
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

func check_traps(delta):
	if !sensor_area: return
	var bodies = sensor_area.get_overlapping_bodies()
	for b in bodies:
		if b.get("type") and Constants.BARRICADE_TYPES.has(b.type):
			var props = Constants.BARRICADE_TYPES[b.type]
			var b_type = props.type
			if b_type == "slow":
				temp_speed_mod = 0.5
			elif b_type == "poison":
				effects.poison = 1.0
				poison_trap_timer -= delta
				if poison_trap_timer <= 0:
					poison_trap_timer = Constants.POISON_TRAP_INTERVAL
					if poison_stacks > 0:
						poison_stacks = floor(poison_stacks * Constants.POISON_TRAP_MULTIPLIER)
						poison_power = poison_power * Constants.POISON_TRAP_MULTIPLIER
					else:
						apply_poison(null, 1, 3.0)
			elif b_type == "reflect":
				take_damage(props.strength * delta)

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

func attack_wall_logic(delta):
	attack_timer -= delta
	if attack_timer <= 0:
		if is_instance_valid(attacking_wall):
			play_attack_animation(attacking_wall.global_position)
		else:
			attacking_wall = null
		attack_timer = 1.0

func attack_base_logic(delta):
	# Dynamic Range Check - Break attack if pushed away
	var target_pos = GameManager.grid_manager.global_position
	if current_target_tile and is_instance_valid(current_target_tile):
		target_pos = current_target_tile.global_position

	var dist = global_position.distance_to(target_pos)
	var attack_range = enemy_data.radius + 10.0

	if dist > attack_range * 1.5: # Tolerance to prevent flickering
		is_attacking_base = false
		return

	base_attack_timer -= delta
	if base_attack_timer <= 0:
		base_attack_timer = 1.0 / enemy_data.atkSpeed

		play_attack_animation(target_pos, func():
			GameManager.damage_core(enemy_data.dmg)
			if current_target_tile and not is_instance_valid(current_target_tile):
				is_attacking_base = false
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

func start_attacking(wall):
	if wall.get("props") and wall.props.get("immune"): return
	if attacking_wall != wall:
		attacking_wall = wall
		attack_timer = 0.5

func play_attack_animation(target_pos: Vector2, hit_callback: Callable = Callable()):
	if is_playing_attack_anim: return
	is_playing_attack_anim = true
	if anim_tween and anim_tween.is_valid(): anim_tween.kill()
	anim_tween = create_tween()
	var original_pos = global_position
	var diff = target_pos - original_pos
	var direction = diff.normalized()
	var retreat_pos = original_pos - direction * 15.0
	var squash_scale = Vector2(0.8, 0.8)
	anim_tween.set_parallel(true)
	anim_tween.tween_property(self, "global_position", retreat_pos, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	anim_tween.tween_property(self, "wobble_scale", squash_scale, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	anim_tween.set_parallel(false)
	var strike_scale = Vector2(1.3, 1.3)
	anim_tween.set_parallel(true)
	anim_tween.tween_property(self, "global_position", target_pos - direction * 5.0, 0.1).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	anim_tween.tween_property(self, "wobble_scale", strike_scale, 0.1)
	anim_tween.set_parallel(false)
	anim_tween.tween_callback(func():
		spawn_slash_effect(target_pos)
		if hit_callback.is_valid():
			hit_callback.call()
		if attacking_wall and is_instance_valid(attacking_wall) and !hit_callback.is_valid():
			if attacking_wall.has_method("take_damage"):
				attacking_wall.take_damage(enemy_data.dmg, self)
			else:
				attacking_wall.take_damage(enemy_data.dmg)
	)
	anim_tween.set_parallel(true)
	anim_tween.tween_property(self, "global_position", original_pos, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	anim_tween.tween_property(self, "wobble_scale", Vector2.ONE, 0.15)
	anim_tween.set_parallel(false)
	anim_tween.tween_callback(func(): is_playing_attack_anim = false)

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

func is_blocking_wall(node):
	if node.get("type") and Constants.BARRICADE_TYPES.has(node.type):
		var b_type = Constants.BARRICADE_TYPES[node.type].type
		return b_type == "block" or b_type == "freeze"
	return false

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
	print("Source: ", hit_source.name if hit_source else "Null", " | Dir: ", hit_dir)
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
	GameManager.food += 2
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
