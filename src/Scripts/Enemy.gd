extends Area2D

var type_key: String
var hp: float
var max_hp: float
var speed: float
var enemy_data: Dictionary
var slow_timer: float = 0.0

var hit_flash_timer: float = 0.0

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
		# Speed is handled in movement logic

	move_towards_core(delta)

func move_towards_core(delta):
	var target_pos = GameManager.grid_manager.position # Core is at GridManager (0,0) usually?
	# Wait, GridManager stores tiles. Core is at tile 0,0.
	# We need the world position of tile 0,0.
	# Assuming GridManager is at world origin or we get its global position.

	# Actually, the grid is centered at GridManager.position + Tile(0,0).position
	# Tile(0,0) is at (0,0) local to GridManager.
	# So we move towards GridManager.global_position.

	if GameManager.grid_manager:
		var target = GameManager.grid_manager.global_position
		var direction = (target - global_position).normalized()

		var current_speed = speed
		if slow_timer > 0: current_speed *= 0.5

		position += direction * current_speed * delta

		var dist = global_position.distance_to(target)
		if dist < 30: # Reached core
			GameManager.damage_core(enemy_data.dmg)
			queue_free()

func take_damage(amount: float, source_unit = null):
	hp -= amount
	hit_flash_timer = 0.1
	queue_redraw()

	GameManager.spawn_floating_text(global_position, str(floor(amount)), Color.WHITE)
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
