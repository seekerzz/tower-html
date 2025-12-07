extends Area2D

var type_key: String
var hp: float
var max_hp: float
var speed: float
var enemy_data: Dictionary
var slow_timer: float = 0.0

var hit_flash_timer: float = 0.0

var raycast: RayCast2D
var attack_timer: float = 0.0
var attacking_wall: Node = null
var temp_speed_mod: float = 1.0

func _ready():
	raycast = RayCast2D.new()
	raycast.enabled = true
	raycast.collision_mask = 1 # StaticBody default layer
	add_child(raycast)

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
	# Draw background circle via script or node? Node is easier.
	# We can use a custom draw in a Node2D child or just a Sprite.
	queue_redraw()

func _draw():
	# Draw Enemy Circle
	var color = enemy_data.color
	if hit_flash_timer > 0:
		color = Color.WHITE
	draw_circle(Vector2.ZERO, enemy_data.radius, color)

	# Draw HP Bar
	var hp_pct = hp / max_hp
	var bar_w = 20
	var bar_h = 4
	var bar_pos = Vector2(-bar_w/2, -enemy_data.radius - 8)
	draw_rect(Rect2(bar_pos, Vector2(bar_w, bar_h)), Color.RED)
	draw_rect(Rect2(bar_pos, Vector2(bar_w * hp_pct, bar_h)), Color.GREEN)

func _process(delta):
	if !GameManager.is_wave_active: return

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
		attacking_wall = null # Reset if invalid
		move_towards_core(delta)

func check_traps(delta):
	var bodies = get_overlapping_bodies()
	for b in bodies:
		if b.get("type") and Constants.BARRICADE_TYPES.has(b.type):
			var b_type = Constants.BARRICADE_TYPES[b.type].type
			if b_type == "slow":
				temp_speed_mod = 0.5
			elif b_type == "poison":
				take_damage(max_hp * 0.05 * delta)

func attack_wall_logic(delta):
	attack_timer -= delta
	if attack_timer <= 0:
		attacking_wall.take_damage(enemy_data.dmg)
		attack_timer = 1.0

func move_towards_core(delta):
	if !GameManager.grid_manager: return

	var target = GameManager.grid_manager.global_position
	var direction = (target - global_position).normalized()

	# Raycast Check
	raycast.target_position = Vector2(enemy_data.radius + 15, 0)
	raycast.rotation = direction.angle() - rotation # Adjust for local rotation if any
	# Note: Enemy scene root usually doesn't rotate, but if it did, we'd need to account for it.
	# Assuming Enemy rotation is 0.
	raycast.global_rotation = direction.angle()
	raycast.force_raycast_update()

	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if is_blocking_wall(collider):
			attacking_wall = collider
			attack_timer = 0.5 # First hit delay
			return

	var current_speed = speed * temp_speed_mod
	if slow_timer > 0: current_speed *= 0.5

	position += direction * current_speed * delta

	var dist = global_position.distance_to(target)
	if dist < 30: # Reached core
		GameManager.damage_core(enemy_data.dmg)
		queue_free()

func is_blocking_wall(node):
	if node.get("type") and Constants.BARRICADE_TYPES.has(node.type):
		var b_type = Constants.BARRICADE_TYPES[node.type].type
		return b_type == "block" or b_type == "freeze"
	return false

func take_damage(amount: float):
	hp -= amount
	hit_flash_timer = 0.1
	queue_redraw()
	if hp <= 0:
		die()

func die():
	GameManager.add_gold(1)
	GameManager.food += 2

	# Drop Logic
	if "drop" in enemy_data:
		if randf() < enemy_data.dropRate:
			GameManager.add_material(enemy_data.drop)

	queue_free()
