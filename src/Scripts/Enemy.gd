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

var raycast: RayCast2D
var attack_timer: float = 0.0
var attacking_wall: Node = null
var temp_speed_mod: float = 1.0

var bypass_dest = null
var bypass_wall = null
var wobble_scale = Vector2.ONE

func _ready():
	add_to_group("enemies")
	raycast = RayCast2D.new()
	raycast.enabled = true
	raycast.collision_mask = 1 # StaticBody default layer
	add_child(raycast)

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
	check_traps(delta)

	if attacking_wall and is_instance_valid(attacking_wall):
		attack_wall_logic(delta)
	else:
		if attacking_wall != null:
			attacking_wall = null # Reset if invalid or destroyed
			_play_state_particles(false)
		move_towards_core(delta)

func spread_burn():
	var areas = get_overlapping_areas()
	for area in areas:
		if area != self and area.is_in_group("enemies"):
			# Apply burn to other enemy
			if "effects" in area:
				area.effects.burn = 5.0 # Reset/Set burn duration

func check_traps(delta):
	var bodies = get_overlapping_bodies()
	for b in bodies:
		if b.get("type") and Constants.BARRICADE_TYPES.has(b.type):
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
		attacking_wall.take_damage(enemy_data.dmg)
		attack_timer = 1.0

func move_towards_core(delta):
	if !GameManager.grid_manager: return

	var target = GameManager.grid_manager.global_position
	var is_bypassing = false

	if bypass_dest != null:
		target = bypass_dest
		is_bypassing = true
		if global_position.distance_to(target) < 10:
			bypass_dest = null
			bypass_wall = null
			is_bypassing = false
			target = GameManager.grid_manager.global_position

	var direction = (target - global_position).normalized()

	# Raycast Check
	raycast.target_position = Vector2(enemy_data.radius + 15, 0)
	# Adjust for local rotation if any
	raycast.global_rotation = direction.angle()
	raycast.force_raycast_update()

	# Trap Ignore Logic
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if is_trap(collider):
			raycast.add_exception(collider)
			raycast.force_raycast_update()

	if raycast.is_colliding():
		var collider = raycast.get_collider()
		# Only block if it is a blocking wall (not trap)
		if is_blocking_wall(collider):
			if is_bypassing and collider == bypass_wall:
				# Sliding logic
				var tangent = get_slide_tangent(collider, direction)
				direction = tangent
			elif !is_bypassing:
				# Check if we should bypass
				var bypass_point = get_bypass_point(collider)
				if bypass_point != null:
					bypass_dest = bypass_point
					bypass_wall = collider
					# Don't move this frame, wait for next frame to adjust direction
					return
				else:
					start_attacking(collider)
					return
			else:
				# Hit another wall
				start_attacking(collider)
				return

	# Clear exceptions for next frame
	raycast.clear_exceptions()

	var current_speed = speed * temp_speed_mod
	if slow_timer > 0: current_speed *= 0.5

	position += direction * current_speed * delta

	if !is_bypassing:
		var dist = global_position.distance_to(target)
		if dist < 30: # Reached core
			GameManager.damage_core(enemy_data.dmg)
			queue_free()

func get_bypass_point(wall):
	if !wall.has_node("CollisionShape2D"): return null
	var cs = wall.get_node("CollisionShape2D")
	if !cs.shape is SegmentShape2D: return null

	var p1 = cs.to_global(cs.shape.a)
	var p2 = cs.to_global(cs.shape.b)

	var core_pos = GameManager.grid_manager.global_position

	# Choose closer endpoint to Core
	var d1 = p1.distance_squared_to(core_pos)
	var d2 = p2.distance_squared_to(core_pos)

	var target = p1 if d1 < d2 else p2

	# Extend target slightly
	var center = (p1 + p2) / 2
	var ext_dir = (target - center).normalized()
	return target + ext_dir * 25.0

func get_slide_tangent(wall, desired_dir):
	if !wall.has_node("CollisionShape2D"): return desired_dir
	var cs = wall.get_node("CollisionShape2D")
	var p1 = cs.to_global(cs.shape.a)
	var p2 = cs.to_global(cs.shape.b)

	var wall_dir = (p2 - p1).normalized()
	if wall_dir.dot(desired_dir) < 0:
		wall_dir = -wall_dir
	return wall_dir

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
