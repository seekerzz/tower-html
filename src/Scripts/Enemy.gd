extends Area2D

var type_key: String
var hp: float
var max_hp: float
var speed: float
var enemy_data: Dictionary
var slow_timer: float = 0.0
var effects = { "burn": 0.0, "poison": 0.0 }

var hit_flash_timer: float = 0.0

var attack_timer: float = 0.0
var attacking_wall: Node = null
var temp_speed_mod: float = 1.0

var wobble_scale = Vector2.ONE

# Pathfinding
var current_path: PackedVector2Array
var repath_timer: float = 0.0
var repath_interval: float = 0.5
var current_path_index: int = 0
var wall_check_ray: RayCast2D

enum State { MOVING, ATTACKING }
var current_state: State = State.MOVING

func _ready():
	add_to_group("enemies")
	wall_check_ray = RayCast2D.new()
	wall_check_ray.enabled = true
	wall_check_ray.collision_mask = 1 # StaticBody default layer
	add_child(wall_check_ray)

	if GameManager.grid_manager:
		# Snap to grid center
		var grid_pos = GameManager.grid_manager.local_to_map(global_position)
		global_position = GameManager.grid_manager.map_to_local(grid_pos)

func setup(key: String, wave: int):
	type_key = key
	enemy_data = Constants.ENEMY_VARIANTS[key]

	var base_hp = 10 + (wave * 8)
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

	# Draw Path (Debug)
	#if !current_path.is_empty():
	#	for i in range(current_path_index, current_path.size()):
	#		var p = to_local(current_path[i])
	#		draw_circle(p, 2, Color.BLUE)

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

	if current_state == State.ATTACKING:
		if attacking_wall and is_instance_valid(attacking_wall):
			attack_wall_logic(delta)
		else:
			attacking_wall = null
			current_state = State.MOVING
			repath_timer = 0 # Force repath immediately

	if current_state == State.MOVING:
		move_logic(delta)

func check_traps(delta):
	var bodies = get_overlapping_bodies()
	for b in bodies:
		if b.get("type") and Constants.BARRICADE_TYPES.has(b.type):
			var b_type = Constants.BARRICADE_TYPES[b.type].type
			if b_type == "slow":
				temp_speed_mod = 0.5
			elif b_type == "poison":
				effects.poison = 1.0
				# take_damage(max_hp * 0.05 * delta) # Now handled in _process

func attack_wall_logic(delta):
	attack_timer -= delta
	if attack_timer <= 0:
		attacking_wall.take_damage(enemy_data.dmg)
		attack_timer = 1.0

func move_logic(delta):
	repath_timer -= delta
	if repath_timer <= 0 or current_path.is_empty():
		refresh_path()
		repath_timer = repath_interval

	if current_path.is_empty():
		# If path is still empty after refresh, try direct movement fallback
		# move_towards_point(GameManager.grid_manager.global_position, delta)
		return

	if current_path_index >= current_path.size():
		return # End of path

	var target = current_path[current_path_index]
	var dist = global_position.distance_to(target)

	if dist < 5.0:
		current_path_index += 1
		if current_path_index >= current_path.size():
			return
		target = current_path[current_path_index]

	var direction = (target - global_position).normalized()

	# Wall collision check
	wall_check_ray.target_position = Vector2(enemy_data.radius + 10, 0)
	wall_check_ray.global_rotation = direction.angle()
	wall_check_ray.force_raycast_update()

	if wall_check_ray.is_colliding():
		var collider = wall_check_ray.get_collider()
		if is_blocking_wall(collider):
			attacking_wall = collider
			current_state = State.ATTACKING
			attack_timer = 0.5
			return

	var current_speed = speed * temp_speed_mod
	if slow_timer > 0: current_speed *= 0.5

	position += direction * current_speed * delta

	var dist_to_core = global_position.distance_to(Vector2(0,0))
	if dist_to_core < 30: # Reached core (approx)
		GameManager.damage_core(enemy_data.dmg)
		queue_free()

func refresh_path():
	if !GameManager.grid_manager: return
	current_path = GameManager.grid_manager.get_nav_path(global_position, Vector2(0,0))
	current_path_index = 0
	# Remove first point if it's the start node (current pos) to avoid jitter?
	# get_nav_path usually returns center of start tile.
	if !current_path.is_empty():
		if global_position.distance_to(current_path[0]) < 10:
			current_path_index = 1

func is_blocking_wall(node):
	if node.get("type") and Constants.BARRICADE_TYPES.has(node.type):
		var b_type = Constants.BARRICADE_TYPES[node.type].type
		return b_type == "block" or b_type == "freeze"
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
