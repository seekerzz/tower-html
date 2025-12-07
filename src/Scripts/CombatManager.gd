extends Node

const ENEMY_SCENE = preload("res://src/Scenes/Game/Enemy.tscn")
const PROJECTILE_SCENE = preload("res://src/Scenes/Game/Projectile.tscn")

var enemies_to_spawn: int = 0
var spawn_timer: float = 0.0

func _ready():
	GameManager.combat_manager = self
	GameManager.wave_started.connect(_on_wave_started)

func _process(delta):
	if !GameManager.is_wave_active: return

	if enemies_to_spawn > 0:
		spawn_timer -= delta
		if spawn_timer <= 0:
			spawn_enemy()
			spawn_timer = 0.5 # Spawn rate

	# Check for win condition
	if enemies_to_spawn <= 0 and get_tree().get_nodes_in_group("enemies").size() == 0:
		GameManager.end_wave()

	# Unit Logic (Iterate over grid units)
	if GameManager.grid_manager:
		for key in GameManager.grid_manager.tiles:
			var tile = GameManager.grid_manager.tiles[key]
			if tile.unit and tile.type != "core":
				process_unit_combat(tile.unit, tile, delta)

func _on_wave_started():
	var wave = GameManager.wave
	enemies_to_spawn = 20 + floor(wave * 6)

func spawn_enemy():
	var angle = randf() * PI * 2
	var distance = 600 # Offscreen
	var spawn_pos = GameManager.grid_manager.global_position + Vector2(cos(angle), sin(angle)) * distance

	show_warning_indicator(spawn_pos)

	enemies_to_spawn -= 1

	# Schedule spawn
	get_tree().create_timer(1.5).timeout.connect(func(): _spawn_enemy_at(spawn_pos))

func show_warning_indicator(pos: Vector2):
	var label = Label.new()
	label.text = "⚠️"
	label.add_theme_font_size_override("font_size", 32)
	label.modulate = Color.RED
	label.global_position = pos - Vector2(16, 16) # Center approx
	add_child(label)

	# Blink animation using Tween
	var tween = create_tween().set_loops()
	tween.tween_property(label, "modulate:a", 0.2, 0.2)
	tween.tween_property(label, "modulate:a", 1.0, 0.2)

	# Remove after 1.5s
	get_tree().create_timer(1.5).timeout.connect(label.queue_free)

func _spawn_enemy_at(pos: Vector2):
	if !GameManager.is_wave_active: return # Avoid spawning if wave ended? Or just let it spawn.

	var type_key = "slime" # Randomize later

	var enemy = ENEMY_SCENE.instantiate()
	enemy.setup(type_key, GameManager.wave)
	enemy.global_position = pos
	add_child(enemy)

func process_unit_combat(unit, tile, delta):
	if unit.cooldown > 0: return

	# Resource Check
	var can_afford = true

	if unit.attack_cost_food > 0:
		if !GameManager.check_resource("food", unit.attack_cost_food):
			unit.is_starving = true
			# print("Unit %s is starving (Cost: %s, Food: %s)" % [unit.name, unit.attack_cost_food, GameManager.food])
			can_afford = false
		else:
			unit.is_starving = false

	if unit.attack_cost_mana > 0:
		if !GameManager.check_resource("mana", unit.attack_cost_mana):
			unit.is_no_mana = true
			can_afford = false
		else:
			unit.is_no_mana = false

	if !can_afford: return

	# Find target
	var target = find_nearest_enemy(tile.global_position, unit.range_val)
	if target:
		# Consume Resources
		if unit.attack_cost_food > 0:
			GameManager.consume_resource("food", unit.attack_cost_food)
		if unit.attack_cost_mana > 0:
			GameManager.consume_resource("mana", unit.attack_cost_mana)

		# Attack
		unit.cooldown = unit.atk_speed

		if unit.unit_data.attackType == "melee":
			target.take_damage(unit.damage, unit)
		else:
			# Check for Multi-shot (projCount)
			var proj_count = unit.unit_data.get("projCount", 1)
			if proj_count > 1:
				spawn_multishot_projectile(unit, tile.global_position, target, proj_count, unit.unit_data.get("spread", 0.5))
			else:
				spawn_projectile(unit, tile.global_position, target)

func find_nearest_enemy(pos: Vector2, range_val: float):
	var nearest = null
	var min_dist = range_val

	for enemy in get_tree().get_nodes_in_group("enemies"):
		var dist = pos.distance_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = enemy

	return nearest

func spawn_projectile(source_unit, pos, target):
	_spawn_single_projectile(source_unit, pos, target, {})

func spawn_multishot_projectile(source_unit, pos, target, count, spread):
	var base_angle = (target.global_position - pos).angle()
	var start_angle = base_angle - spread / 2.0
	var step = spread / max(1, count - 1)

	for i in range(count):
		var angle = start_angle + (i * step)
		# We pass specific angle. But Projectile.setup normally looks at target.
		# We can pass angle in stats to override.
		_spawn_single_projectile(source_unit, pos, target, {"angle": angle})

func _spawn_single_projectile(source_unit, pos, target, extra_stats):
	var proj = PROJECTILE_SCENE.instantiate()

	# Gather stats from unit data + active buffs
	var stats = {
		"pierce": source_unit.unit_data.get("pierce", 0),
		"bounce": source_unit.unit_data.get("bounce", 0),
		"split": source_unit.unit_data.get("split", 0), # Default split prop?
		"chain": source_unit.unit_data.get("chain", 0)
	}

	# Merge buffs from Unit.gd (if present)
	if "active_buffs" in source_unit:
		for buff in source_unit.active_buffs:
			if buff == "bounce": stats.bounce += 1
			if buff == "split": stats.split += 1
			# ... other buffs

	# Merge extra stats (like angle from multishot)
	stats.merge(extra_stats, true)
	stats.source = source_unit

	proj.setup(pos, target, source_unit.damage, 400.0, source_unit.unit_data.proj, stats)
	add_child(proj)
