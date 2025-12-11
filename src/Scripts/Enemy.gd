extends Area2D

var type_key: String
var hp: float
var max_hp: float
var speed: float
var enemy_data: Dictionary
var slow_timer: float = 0.0
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

func _ready():
	add_to_group("enemies")
	# We also need to monitor layer 2 (traps) for overlaps
	collision_mask = 3 # Layer 1 (Walls) + Layer 2 (Traps)

func setup(key: String, wave: int):
	type_key = key
	enemy_data = Constants.ENEMY_VARIANTS[key]

	var base_hp = 100 + (wave * 80)
	hp = base_hp * enemy_data.hpMod
	max_hp = hp

	speed = (40 + (wave * 2)) * enemy_data.spdMod

	update_visuals()

func update_visuals():
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
	var time = Time.get_ticks_msec() * 0.005
	var scale_x = 1.0 + sin(time) * 0.1
	var scale_y = 1.0 + cos(time) * 0.1
	wobble_scale = Vector2(scale_x, scale_y)

	if has_node("Label"):
		$Label.scale = wobble_scale

	queue_redraw()

	if hit_flash_timer > 0:
		hit_flash_timer -= delta
		if hit_flash_timer <= 0: queue_redraw()

	if slow_timer > 0:
		slow_timer -= delta

	temp_speed_mod = 1.0
	check_traps(delta)

	if attacking_wall and is_instance_valid(attacking_wall):
		attack_wall_logic(delta)
	else:
		if attacking_wall != null:
			attacking_wall = null # Reset if invalid or destroyed
			_play_state_particles(false)

		# Update Navigation Path
		nav_timer -= delta
		if nav_timer <= 0:
			update_path()
			nav_timer = 0.5

		move_along_path(delta)

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

func attack_wall_logic(delta):
	attack_timer -= delta
	if attack_timer <= 0:
		attacking_wall.take_damage(enemy_data.dmg)
		attack_timer = 1.0

func update_path():
	if !GameManager.grid_manager: return
	var core_pos = GameManager.grid_manager.global_position
	path = GameManager.grid_manager.get_nav_path(global_position, core_pos)

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
	var target_pos = GameManager.grid_manager.global_position # Default core

	if path.size() > path_index:
		target_pos = path[path_index]

	var dist = global_position.distance_to(target_pos)
	if dist < 10:
		if path.size() > path_index:
			path_index += 1
			if path_index < path.size():
				target_pos = path[path_index]
			else:
				# Reached end of path (Core)
				target_pos = GameManager.grid_manager.global_position

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

	# Check if reached core
	if global_position.distance_to(GameManager.grid_manager.global_position) < 30:
		GameManager.damage_core(enemy_data.dmg)
		queue_free()

func start_attacking(wall):
	if wall.get("props") and wall.props.get("immune"):
		return # Do not attack immune walls (like Ice)

	if attacking_wall != wall:
		attacking_wall = wall
		attack_timer = 0.5
		_play_state_particles(true)

func _play_state_particles(is_attacking: bool):
	var particle = CPUParticles2D.new()
	add_child(particle)
	particle.emitting = true
	particle.one_shot = true
	particle.explosiveness = 1.0
	particle.lifetime = 0.5
	particle.spread = 180
	particle.gravity = Vector2(0, 0)
	particle.initial_velocity_min = 20
	particle.initial_velocity_max = 50
	particle.scale_amount_min = 2
	particle.scale_amount_max = 4

	if is_attacking:
		particle.color = Color.RED
	else:
		particle.color = Color.WHITE

	particle.finished.connect(particle.queue_free)

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
	GameManager.spawn_floating_text(global_position, "+1💰", Color.YELLOW)
	GameManager.food += 2

	# Drop Logic
	if "drop" in enemy_data:
		if randf() < enemy_data.dropRate:
			GameManager.add_material(enemy_data.drop)

	queue_free()
