extends Area2D

var type_key: String
var hp: float
var max_hp: float
var speed: float
var enemy_data: Dictionary
var slow_timer: float = 0.0
var effects = { "burn": 0.0, "poison": 0.0 }

var hit_flash_timer: float = 0.0
var burn_tick_timer: float = 0.0

var attack_timer: float = 0.0
var attacking_wall: Node = null
var temp_speed_mod: float = 1.0

var wobble_scale = Vector2.ONE

var current_path: Array = []
var path_index: int = 0

func _ready():
	add_to_group("enemies")

func setup(key: String, wave: int):
	type_key = key
	enemy_data = Constants.ENEMY_VARIANTS[key]

	var base_hp = 10 + (wave * 8)
	hp = base_hp * enemy_data.hpMod
	max_hp = hp

	speed = (40 + (wave * 2)) * enemy_data.spdMod

	update_visuals()

func update_visuals():
	if has_node("Label"):
		$Label.text = enemy_data.icon
		# Ensure label is centered and pivot is set for correct scaling
		$Label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		$Label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		# Label size is not explicitly set here, relying on default or scene.
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

	# Draw Status Effects
	if effects.burn > 0:
		draw_circle(Vector2.ZERO, enemy_data.radius, Color(1, 0.5, 0, 0.5))
	if effects.poison > 0:
		draw_circle(Vector2.ZERO, enemy_data.radius, Color(0, 1, 0, 0.5))

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

	# Handle Effects
	if effects.burn > 0:
		hp -= 2.0 * delta
		effects.burn -= delta

		# Burn Contagion
		burn_tick_timer -= delta
		if burn_tick_timer <= 0:
			burn_tick_timer = 0.5
			spread_burn()

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
	check_collisions(delta) # Handles both traps and blocking walls

	if attacking_wall and is_instance_valid(attacking_wall):
		attack_wall_logic(delta)
	else:
		if attacking_wall != null:
			attacking_wall = null # Reset if invalid or destroyed
			_play_state_particles(false)
		
		if current_path.is_empty():
			recalculate_path()
		move_along_path(delta)

func recalculate_path():
	if !GameManager.grid_manager: return
	# Get path to (0,0) which is roughly the core
	current_path = GameManager.grid_manager.get_nav_path(global_position, Vector2.ZERO)
	path_index = 0

func move_along_path(delta):
	if current_path.is_empty():
		# Path finished or empty, attack core
		var dist = global_position.distance_to(Vector2.ZERO)
		if dist < 30:
			GameManager.damage_core(enemy_data.dmg)
			queue_free()
		return

	if path_index >= current_path.size():
		GameManager.damage_core(enemy_data.dmg)
		queue_free()
		return

	var target_point = current_path[path_index]
	var current_speed = speed * temp_speed_mod
	if slow_timer > 0: current_speed *= 0.5

	position = position.move_toward(target_point, current_speed * delta)

	if position.distance_to(target_point) < 1.0:
		path_index += 1

func spread_burn():
	var areas = get_overlapping_areas()
	for area in areas:
		if area != self and area.is_in_group("enemies"):
			# Apply burn to other enemy
			if "effects" in area:
				area.effects.burn = 5.0 # Reset/Set burn duration

func check_collisions(delta):
	var bodies = get_overlapping_bodies()
	for b in bodies:
		# Check for Blocking Walls (Attack Trigger)
		if is_blocking_wall(b):
			# If we hit a wall, start attacking it
			# We only attack if we are NOT already attacking something else
			if attacking_wall != b:
				start_attacking(b)
			return # Stop processing movement/traps if blocked

		# Check for Traps (Modifiers)
		if is_trap(b):
			var props = Constants.BARRICADE_TYPES[b.type]
			var b_type = props.type

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
		if is_instance_valid(attacking_wall):
			attacking_wall.take_damage(enemy_data.dmg)
			attack_timer = 1.0
		else:
			attacking_wall = null

func start_attacking(wall):
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

func take_damage(amount: float, source_unit = null):
	hp -= amount
	hit_flash_timer = 0.1
	queue_redraw()

	GameManager.spawn_floating_text(global_position, str(int(amount)), Color.WHITE)
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