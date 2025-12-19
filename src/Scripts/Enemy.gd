extends Area2D

var type_key: String
var hp: float
var max_hp: float
var speed: float
var enemy_data: Dictionary
var slow_timer: float = 0.0
var freeze_timer: float = 0.0
var stun_timer: float = 0.0
var effects = { "burn": 0.0, "poison": 0.0 }
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

# Boss / Special Properties
var stationary_timer: float = 0.0
var boss_skill: String = ""
var skill_cd_timer: float = 0.0
var is_suicide: bool = false
var is_stationary: bool = false

func _ready():
	add_to_group("enemies")
	# We also need to monitor layer 2 (traps) for overlaps
	collision_mask = 3 # Layer 1 (Walls) + Layer 2 (Traps)

	# Ensure Area2D does not pick up input (only physics collisions)
	input_pickable = false

	# Fix for occlusion issue: Ensure all UI components ignore mouse (recursively)
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
			# Ensure label is centered and pivot is set for correct scaling
			$Label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			$Label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			# Label size is not explicitly set here, relying on default or scene.
			# Assuming Label is centered on (0,0) via position or anchors.
			# If Label is centered:
			if $Label.size.x == 0:
				$Label.size = Vector2(40, 40) # Estimate
				$Label.position = -$Label.size / 2
			$Label.pivot_offset = $Label.size / 2

	queue_redraw()

func _draw():
	draw_set_transform(Vector2.ZERO, 0.0, wobble_scale)

	# Draw Enemy Circle
	var color = enemy_data.color
	if hit_flash_timer > 0:
		color = Color.WHITE
	draw_circle(Vector2.ZERO, enemy_data.radius, color)

	# Reset Transform for HP Bar
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Draw HP Bar
	if hp < max_hp and hp > 0:
		var hp_pct = hp / max_hp
		var bar_w = 20
		var bar_h = 4
		var bar_pos = Vector2(-bar_w/2, -enemy_data.radius - 8)
		draw_rect(Rect2(bar_pos, Vector2(bar_w, bar_h)), Color.RED)
		draw_rect(Rect2(bar_pos, Vector2(bar_w * hp_pct, bar_h)), Color.GREEN)

func _process(delta):
	if !GameManager.is_wave_active: return

	# Update Particle Effects
	if has_node("BurnParticles"):
		$BurnParticles.emitting = (effects.burn > 0)
	if has_node("PoisonParticles"):
		$PoisonParticles.emitting = (effects.poison > 0)

	# Stun Logic
	if stun_timer > 0:
		stun_timer -= delta
		if stun_timer <= 0:
			# Stun ended
			pass
		return # Stop all logic (movement, attack) if stunned

	# Handle Heat Accumulation
	if effects.burn <= 0:
		var nearby_burn = false
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if enemy != self and enemy.get("effects") and enemy.effects.burn > 0:
				var dist = global_position.distance_to(enemy.global_position)
				if dist < 60.0:
					nearby_burn = true
					heat_accumulation += delta
					break # Found one source, enough to accumulate

		if nearby_burn:
			if heat_accumulation > 1.0:
				effects.burn = 5.0 # Ignite!
				heat_accumulation = 0.0
		else:
			heat_accumulation -= delta * 0.5 # Decay
			if heat_accumulation < 0: heat_accumulation = 0
	else:
		heat_accumulation = 0.0

	# Handle Effects
	if effects.burn > 0:
		hp -= 2.0 * delta
		effects.burn -= delta

		if effects.burn <= 0: effects.burn = 0
		if hp <= 0: die()

	if effects.poison > 0:
		hp -= (max_hp * 0.05) * delta
		effects.poison -= delta
		if effects.poison <= 0: effects.poison = 0
		if hp <= 0: die()

	# Wobble Effect
	if !is_playing_attack_anim:
		var time = Time.get_ticks_msec() * 0.005
		var scale_x = 1.0 + sin(time) * 0.1
		var scale_y = 1.0 + cos(time) * 0.1
		wobble_scale = Vector2(scale_x, scale_y)

	if has_node("Label"):
		$Label.scale = wobble_scale
	if has_node("TextureRect"):
		$TextureRect.scale = wobble_scale

	queue_redraw()

	if hit_flash_timer > 0:
		hit_flash_timer -= delta
		if hit_flash_timer <= 0: queue_redraw()

	if slow_timer > 0:
		slow_timer -= delta

	if freeze_timer > 0:
		freeze_timer -= delta
		# Frozen visual
		modulate = Color(0.5, 0.5, 1.0)
	else:
		modulate = Color.WHITE

	temp_speed_mod = 1.0

	if freeze_timer > 0:
		temp_speed_mod = 0.0
		queue_redraw()
		return # Stop all logic if frozen

	check_traps(delta)
	check_unit_interactions(delta)

	# Suicide Logic
	if is_suicide:
		check_suicide_collision()

	# Stationary / Boss Skill Logic
	if is_stationary:
		stationary_timer -= delta
		skill_cd_timer -= delta
		if stationary_timer <= 0:
			is_stationary = false # Transition to moving phase
		else:
			# Stationary Phase: Execute Skills
			if boss_skill != "" and skill_cd_timer <= 0:
				perform_boss_skill(boss_skill)
				skill_cd_timer = 2.0 # Internal CD for skill usage

			return # Skip movement logic while stationary

	if is_attacking_base:
		attack_base_logic(delta)
	elif attacking_wall and is_instance_valid(attacking_wall):
		attack_wall_logic(delta)
	else:
		if attacking_wall != null:
			attacking_wall = null # Reset if invalid or destroyed
			# _play_state_particles(false) # Removed legacy particle

		# Update Navigation Path
		nav_timer -= delta
		if nav_timer <= 0:
			update_path()
			nav_timer = 0.5

		move_along_path(delta)

func check_suicide_collision():
	# Check for overlapping bodies (walls) or distance to core
	var bodies = get_overlapping_bodies()
	for b in bodies:
		if is_blocking_wall(b):
			explode_suicide(b)
			return

	if GameManager.grid_manager:
		var core_dist = global_position.distance_to(GameManager.grid_manager.global_position)
		if core_dist < 40.0:
			explode_suicide(null) # Null target means core (or we deal damage directly)

func explode_suicide(target_wall):
	# Deal damage to target and die
	if target_wall and is_instance_valid(target_wall):
		if target_wall.has_method("take_damage"):
			target_wall.take_damage(enemy_data.dmg, self)
	else:
		# Assume core
		GameManager.damage_core(enemy_data.dmg)

	# Visual effect
	GameManager.spawn_floating_text(global_position, "BOOM!", Color.RED)
	# Use SlashEffect as Explosion for now
	var effect = load("res://src/Scripts/Effects/SlashEffect.gd").new()
	get_parent().add_child(effect)
	effect.global_position = global_position
	effect.configure("cross", Color.ORANGE)
	effect.scale = Vector2(2, 2)
	effect.play()

	queue_free()

func perform_boss_skill(skill_name: String):
	if skill_name == "summon":
		# Summon Minions
		GameManager.spawn_floating_text(global_position, "Summon!", Color.PURPLE)
		for i in range(3):
			var offset = Vector2(randf_range(-40, 40), randf_range(-40, 40))
			# We need to access CombatManager to spawn enemies ideally, but we can do it via MainGame or signal.
			# But here we are in Enemy.gd. CombatManager has `_spawn_enemy_at_pos` but it is private-ish.
			# However, CombatManager is global via GameManager.combat_manager
			if GameManager.combat_manager:
				GameManager.combat_manager._spawn_enemy_at_pos(global_position + offset, "minion")

	elif skill_name == "shoot_enemy":
		# Shoot Bullet Entity
		GameManager.spawn_floating_text(global_position, "Fire!", Color.ORANGE)
		if GameManager.combat_manager:
			GameManager.combat_manager._spawn_enemy_at_pos(global_position, "bullet_entity")

func apply_stun(duration: float):
	stun_timer = duration
	GameManager.spawn_floating_text(global_position, "Stunned!", Color.GRAY)

func check_traps(delta):
	var bodies = get_overlapping_bodies()
	for b in bodies:
		if b.get("type") and Constants.BARRICADE_TYPES.has(b.type):
			var props = Constants.BARRICADE_TYPES[b.type]
			var b_type = props.type

			# Only interact with non-solid traps here, or any?
			# The logic is fine for both, but usually we move through traps.
			if b_type == "slow":
				temp_speed_mod = 0.5
			elif b_type == "poison":
				effects.poison = 1.0
			elif b_type == "reflect":
				# Fang trap reflects damage or deals damage
				take_damage(props.strength * delta)

func check_unit_interactions(delta):
	if !GameManager.grid_manager: return

	# Check for unit on current tile (for Rabbit or others)
	var tile_key = GameManager.grid_manager.get_tile_key(int(round(global_position.x / GameManager.grid_manager.TILE_SIZE)), int(round(global_position.y / GameManager.grid_manager.TILE_SIZE)))
	if GameManager.grid_manager.tiles.has(tile_key):
		var tile = GameManager.grid_manager.tiles[tile_key]
		var unit = tile.unit
		if unit and is_instance_valid(unit):
			# Rabbit Logic
			if unit.unit_data.get("trait") == "dodge_counter":
				_trigger_rabbit_interaction(unit)

var _rabbit_interaction_timer: float = 0.0

func _trigger_rabbit_interaction(unit):
	if _rabbit_interaction_timer > 0:
		_rabbit_interaction_timer -= get_process_delta_time()
		return

	_rabbit_interaction_timer = 1.0 # Interact once per second

	var dodge_rate = unit.unit_data.get("dodge_rate", 0.3)
	if randf() < dodge_rate:
		# Dodge success: Enemy takes damage (Counter), Unit safe
		GameManager.spawn_floating_text(unit.global_position, "Miss!", Color.YELLOW)
		take_damage(unit.damage, unit, "physical")
	else:
		# Dodge fail: Damage Core (via Unit)
		# Note: Rabbit is not a wall, so we walk through it, but we "attack" it on passing.
		# Since we are overlapping, we just apply damage logic.
		# But wait, Rabbit is "Melee". It attacks enemies normally via CombatManager.
		# This "interaction" represents the Enemy attacking the Rabbit.

		unit.play_attack_anim("melee", global_position) # Visual only?
		# Apply damage to Unit (Core)
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
	base_attack_timer -= delta
	if base_attack_timer <= 0:
		# GameManager.damage_core(enemy_data.dmg) # Moved to animation
		base_attack_timer = 1.0 / enemy_data.atkSpeed
		# _play_state_particles(true) # Replaced

		var target_pos = GameManager.grid_manager.global_position
		if current_target_tile and is_instance_valid(current_target_tile):
			target_pos = current_target_tile.global_position

		play_attack_animation(target_pos, func():
			GameManager.damage_core(enemy_data.dmg)
			# Check validity after attack
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
		# Fallback
		target_pos = GameManager.grid_manager.global_position

	path = GameManager.grid_manager.get_nav_path(global_position, target_pos)

	# If path is empty, it means no path found (blocked)
	# But AStarGrid2D returns empty if no path.
	# If no path, we might need to attack the nearest wall blocking us?
	# Or just move towards core directly and hit the wall.
	if path.size() == 0:
		# Fallback: simple direction
		path = []
	else:
		path_index = 0
		# The first point is usually the current cell or close to it, so start index 0
		# But if we are already there, skip
		if path.size() > 0 and global_position.distance_to(path[0]) < 10:
			path_index = 1

func move_along_path(delta):
	if !GameManager.grid_manager: return

	# Check for attack range to current target tile
	if current_target_tile and is_instance_valid(current_target_tile):
		var dist_to_target = global_position.distance_to(current_target_tile.global_position)
		if dist_to_target < 40.0:
			is_attacking_base = true
			# _play_state_particles(true) # Removed legacy
			return

	var target_pos = GameManager.grid_manager.global_position # Default core
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
			else:
				# Reached end of path
				pass

	var direction = (target_pos - global_position).normalized()

	# Simple wall detection for attacking (if we are stuck or path leads to a wall we must break)
	# Wait, if AStar gives a path, it avoids walls.
	# If AStar returns NO path, we need to break walls.

	if path.size() == 0:
		# No path found -> Blocked completely. Move towards core and attack what's in front.
		direction = (GameManager.grid_manager.global_position - global_position).normalized()

		# We need to detect what's blocking us
		# Use a small raycast or just check for collision?
		# Since we removed the raycast member, let's just use overlapping bodies if we are very close,
		# OR re-add a small raycast for attack logic.
		# Let's create a temporary RayCast logic or just check distance to walls.

		# For simplicity, if no path, we are likely near a wall.
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(global_position, global_position + direction * 40)
		query.collision_mask = 1 # Walls
		var result = space_state.intersect_ray(query)

		if result:
			var collider = result.collider
			if is_blocking_wall(collider):
				if collider.get("props") and collider.props.get("immune"):
					# Do not attack immune walls. Jitter to avoid logic lock.
					position += Vector2(randf(), randf()) * 0.1
					return
				start_attacking(collider)
				return

	var current_speed = speed * temp_speed_mod
	if slow_timer > 0: current_speed *= 0.5

	position += direction * current_speed * delta

	# Legacy check if reached core (GridManager center) - Fallback
	if !current_target_tile and global_position.distance_to(GameManager.grid_manager.global_position) < 30:
		GameManager.damage_core(enemy_data.dmg)
		queue_free()

func start_attacking(wall):
	if wall.get("props") and wall.props.get("immune"):
		return # Do not attack immune walls (like Ice)

	if attacking_wall != wall:
		attacking_wall = wall
		attack_timer = 0.5
		# _play_state_particles(true) # Removed legacy

func play_attack_animation(target_pos: Vector2, hit_callback: Callable = Callable()):
	if is_playing_attack_anim: return # Prevent overlapping attacks

	is_playing_attack_anim = true

	# If we have an existing tween, kill it
	if anim_tween and anim_tween.is_valid():
		anim_tween.kill()

	anim_tween = create_tween()
	var original_pos = global_position
	var diff = target_pos - original_pos
	var direction = diff.normalized()

	# 1. Anticipation (Retreat + Squash)
	# Retreat slightly away from target
	var retreat_pos = original_pos - direction * 15.0
	var squash_scale = Vector2(0.8, 0.8) # Squash

	anim_tween.set_parallel(true)
	anim_tween.tween_property(self, "global_position", retreat_pos, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	anim_tween.tween_property(self, "wobble_scale", squash_scale, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	anim_tween.set_parallel(false)

	# 2. Strike (Dash + Stretch)
	# Dash to target (or slightly before/past to simulate impact)
	# User requirement: "Position at 'Strike' contact ... instantiate SlashEffect".
	# We move to target_pos (or close to it).
	var strike_scale = Vector2(1.3, 1.3) # Stretch/Enlarge

	anim_tween.set_parallel(true)
	anim_tween.tween_property(self, "global_position", target_pos - direction * 5.0, 0.1).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	anim_tween.tween_property(self, "wobble_scale", strike_scale, 0.1)
	anim_tween.set_parallel(false)

	# Impact Effect Callback
	anim_tween.tween_callback(func():
		spawn_slash_effect(target_pos)
		if hit_callback.is_valid():
			hit_callback.call()

		# Also handle wall damage here if no callback passed (legacy fallback or specific logic)
		if attacking_wall and is_instance_valid(attacking_wall) and !hit_callback.is_valid():
			if attacking_wall.has_method("take_damage"):
				# Pass source self for Reflect logic
				attacking_wall.take_damage(enemy_data.dmg, self)
			else:
				# Fallback for old barricades without source param or different signature
				if attacking_wall.has_method("take_damage_legacy"):
					attacking_wall.take_damage_legacy(enemy_data.dmg)
				else:
					# Assuming Barricade.gd has take_damage(amount)
					# We should check argument count or just pass amount if standard
					attacking_wall.take_damage(enemy_data.dmg)
	)

	# 3. Recovery (Return + Normal Scale)
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

	# Override color for "Strike" feeling
	if randf() > 0.5: col = Color(1.0, 0.8, 0.8) # Slightly red tint

	effect.configure(shape, col)
	effect.play()

func is_blocking_wall(node):
	if node.get("type") and Constants.BARRICADE_TYPES.has(node.type):
		var b_type = Constants.BARRICADE_TYPES[node.type].type
		# Explicitly check for wall types that block
		return b_type == "block" or b_type == "freeze"
	return false

func is_trap(node):
	if node.get("type") and Constants.BARRICADE_TYPES.has(node.type):
		var b_type = Constants.BARRICADE_TYPES[node.type].type
		# Traps: slow (mucus), poison, reflect (fang)
		return b_type == "slow" or b_type == "poison" or b_type == "reflect"
	return false

func take_damage(amount: float, source_unit = null, damage_type: String = "physical"):
	hp -= amount
	hit_flash_timer = 0.1
	queue_redraw()

	var display_val = max(1, int(amount))
	GameManager.spawn_floating_text(global_position, str(display_val), damage_type)
	if source_unit:
		GameManager.damage_dealt.emit(source_unit, amount)

	if hp <= 0:
		die()

func die():
	GameManager.add_gold(1)

	# Artifact: Scrap Recycling
	if GameManager.reward_manager and "scrap_recycling" in GameManager.reward_manager.acquired_artifacts:
		if GameManager.grid_manager:
			var core_pos = GameManager.grid_manager.global_position
			if global_position.distance_to(core_pos) < 200.0:
				GameManager.damage_core(-5)
				GameManager.add_gold(1)
				GameManager.spawn_floating_text(global_position, "+1💰 (Recycle)", Color.GOLD)

	GameManager.spawn_floating_text(global_position, "+1💰", Color.YELLOW)
	GameManager.food += 2

	queue_free()
