extends Node

const ENEMY_SCENE = preload("res://src/Scenes/Game/Enemy.tscn")
const PROJECTILE_SCENE = preload("res://src/Scenes/Game/Projectile.tscn")
const LIGHTNING_SCENE = preload("res://src/Scenes/Game/LightningArc.tscn")

var enemies_to_spawn: int = 0
var total_enemies_for_wave: int = 0
# spawn_timer removed as we use coroutines now

func _ready():
	GameManager.combat_manager = self
	GameManager.wave_started.connect(_on_wave_started)

func _process(delta):
	# Unit Logic (Iterate over grid units)
	if GameManager.is_wave_active and GameManager.grid_manager:
		for key in GameManager.grid_manager.tiles:
			var tile = GameManager.grid_manager.tiles[key]
			if tile.unit and tile.type != "core":
				process_unit_combat(tile.unit, tile, delta)

func _on_wave_started():
	start_wave_logic()

func get_wave_type(n: int) -> String:
	var types = ['slime', 'wolf', 'poison', 'treant', 'yeti', 'golem']
	if n % 10 == 0: return 'boss'
	if n % 3 == 0: return 'event'

	# Logic from ref.html: const idx = Math.min(types.length - 1, Math.floor((n-1)/2));
	var idx = min(types.size() - 1, floor((n - 1) / 2.0))
	return types[int(idx) % types.size()]

func start_wave_logic():
	var wave = GameManager.wave

	# Calculate total enemies (Increased difficulty logic from ref.html)
	# const baseCount = 20 + Math.floor(game.wave * 6);
	total_enemies_for_wave = 20 + floor(wave * 6)
	enemies_to_spawn = total_enemies_for_wave

	# Batch calculation
	# const batchCount = 3 + Math.floor(game.wave / 2);
	var batch_count = 3 + floor(wave / 2.0)
	var enemies_per_batch = ceil(float(total_enemies_for_wave) / batch_count)

	_run_batch_sequence(batch_count, int(enemies_per_batch))

func _run_batch_sequence(batches_left: int, enemies_per_batch: int):
	if !GameManager.is_wave_active or batches_left <= 0:
		return

	# Determine type for this batch
	var wave_type = get_wave_type(GameManager.wave)
	var type_key = wave_type

	# Logic from ref.html simplified/fixed:
	# If it's a normal wave (not boss), we might want variation?
	# ref.html logic: if 'normal' (which is default for non-boss/tank/fast), pick random variant.
	# But get_wave_type returns specific types like 'slime', 'wolf'.
	# We will respect get_wave_type unless it is 'event'.

	if wave_type == 'boss':
		type_key = 'boss'
	elif wave_type == 'event':
		# Random variant for event waves (or maybe mixed)
		var variants = ['slime', 'wolf', 'poison', 'shooter']
		type_key = variants.pick_random()
	else:
		# It returned a specific type like 'slime' or 'wolf'
		# We use that. However, ref.html seemed to fallback to random 'normal' often.
		# To make it more interesting and match "Game Expert" role, let's keep specific types
		# to give distinct wave feel, but maybe mix in some randoms if needed.
		# For now, strict adherence to the returned type.
		pass

	# Pick random angle for this batch
	var angle = randf() * TAU # TAU is 2*PI

	# Show Warning
	show_warning_indicator(angle, type_key)

	# Wait 1.5s
	await get_tree().create_timer(1.5).timeout

	if !GameManager.is_wave_active: return

	# Spawn Batch
	await _spawn_batch(angle, type_key, enemies_per_batch)

	# Schedule next batch
	if batches_left > 1:
		# Wait between batches (2s - 4s depending on wave)
		# const nextDelay = Math.max(2000, 4000 - (game.wave * 100));
		var delay = max(2.0, 4.0 - (GameManager.wave * 0.1))
		await get_tree().create_timer(delay).timeout
		_run_batch_sequence(batches_left - 1, enemies_per_batch)
	else:
		# Last batch spawned, wait for clear
		pass

	# Check win condition is handled in unit death logic usually,
	# but we need to ensure we track "enemies_to_spawn" correctly.
	# Actually, enemies_to_spawn is decremented when we spawn.
	# Game over/Win check should be in _process or signal based.
	# Existing _process had: if enemies_to_spawn <= 0 and active_enemies == 0: end_wave
	# We should keep that check but maybe optimized.
	start_win_check_loop()

func start_win_check_loop():
	# Simple polling for win condition
	while GameManager.is_wave_active:
		if enemies_to_spawn <= 0 and get_tree().get_nodes_in_group("enemies").size() == 0:
			GameManager.end_wave()
			break
		await get_tree().create_timer(0.5).timeout

func _spawn_batch(base_angle: float, type_key: String, count: int):
	for i in range(count):
		if !GameManager.is_wave_active: break
		if enemies_to_spawn <= 0: break

		# Spawn with slight spread
		# angle + (Math.random() - 0.5) * 0.8
		var angle = base_angle + randf_range(-0.4, 0.4)
		_spawn_enemy_at_angle(angle, type_key)

		enemies_to_spawn -= 1

		# Fast spawn (0.1s)
		await get_tree().create_timer(0.1).timeout

func _spawn_enemy_at_angle(angle: float, type_key: String):
	var distance = 600 # Offscreen radius, assuming center 0,0 or adjust relative to camera
	# If GridManager is at center (0,0 implied by setup usually), fine.
	# If not, we should add GridManager.global_position.
	var center = Vector2.ZERO
	if GameManager.grid_manager:
		center = GameManager.grid_manager.global_position

	var spawn_pos = center + Vector2(cos(angle), sin(angle)) * distance

	var enemy = ENEMY_SCENE.instantiate()
	enemy.setup(type_key, GameManager.wave)
	enemy.global_position = spawn_pos
	add_child(enemy)

func show_warning_indicator(angle: float, type_key: String):
	# Calculate position at screen edge
	var viewport_rect = get_viewport().get_visible_rect()
	var center = viewport_rect.size / 2
	# Or use Grid center if camera is fixed there?
	# Let's assume viewport center is relevant for UI overlay.

	# Radius should be slightly less than half screen
	var r = min(viewport_rect.size.x, viewport_rect.size.y) / 2.0 - 50.0

	var pos = center + Vector2(cos(angle), sin(angle)) * r

	# Create Warning UI
	var container = Node2D.new()
	container.global_position = pos

	# Rotation removed to keep icons upright.
	# container.rotation = angle - PI/2

	var label = Label.new()
	label.text = "⚠️"
	label.add_theme_font_size_override("font_size", 32)
	label.modulate = Color.RED
	# Center the label
	label.position = Vector2(-16, -24)

	# Add Enemy Icon if available
	if Constants.ENEMY_VARIANTS.has(type_key):
		var icon_label = Label.new()
		icon_label.text = Constants.ENEMY_VARIANTS[type_key].icon
		icon_label.add_theme_font_size_override("font_size", 24)
		icon_label.position = Vector2(-12, 10) # Below the warning
		container.add_child(icon_label)

	container.add_child(label)

	# Add to a CanvasLayer if possible to be on top of game, or just add_child if CombatManager is in world
	# Ideally add to UI manager, but adding to self (CombatManager) works if it is in the scene.
	# Warning: If CombatManager is just a Node, and Camera moves, this might drift.
	# But prompt says "screen edge".
	# If we use CanvasLayer, coordinates are screen relative.
	# If we use Node2D in world, coordinates are world relative.
	# Currently `_spawn_enemy_at_angle` uses world coords.
	# Let's assume the game view is centered on Grid.
	# If I add it as a child of CombatManager, and CombatManager is in MainGame (Node2D), it's world space.
	# If the camera doesn't move (it seems static in ref.html), world space matches screen space with offset.
	# However, `min(w,h)/2 - 40` implies a circle fitting in screen.
	# I'll stick to world space relative to GridManager center, which ensures it points to the Core.

	if GameManager.grid_manager:
		var grid_pos = GameManager.grid_manager.global_position
		container.global_position = grid_pos + Vector2(cos(angle), sin(angle)) * r

	add_child(container)

	# Animate
	var tween = create_tween().set_loops()
	tween.tween_property(container, "modulate:a", 0.2, 0.2)
	tween.tween_property(container, "modulate:a", 1.0, 0.2)

	# Remove
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(container):
		container.queue_free()

# ... Keep existing process_unit_combat logic ...
func process_unit_combat(unit, tile, delta):
	if unit.cooldown > 0: return

	# Resource Check
	var can_afford = true

	if unit.attack_cost_food > 0:
		if !GameManager.check_resource("food", unit.attack_cost_food):
			unit.is_starving = true
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

		unit.play_attack_anim(unit.unit_data.attackType, target.global_position)

		if unit.unit_data.attackType == "melee":
			target.take_damage(unit.damage, unit)
		elif unit.unit_data.attackType == "ranged" and unit.unit_data.get("proj") == "lightning":
			# Lightning handling
			# "tesla": "attackType": "ranged", "proj": "lightning", "chain": 4
			perform_lightning_attack(unit, tile.global_position, target, unit.unit_data.get("chain", 0))
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

func perform_lightning_attack(source_unit, start_pos, target, chain_left, hit_list = null):
	if hit_list == null: hit_list = []
	if !is_instance_valid(target): return

	# Apply damage
	target.take_damage(source_unit.damage, source_unit)
	hit_list.append(target)

	# Visual
	var arc = LIGHTNING_SCENE.instantiate()
	add_child(arc)
	arc.setup(start_pos, target.global_position)

	# Chain
	if chain_left > 0:
		var next_target = find_nearest_enemy_excluding(target.global_position, 300.0, hit_list)
		if next_target:
			# Delay slightly for visual effect? Or instant recursive. Instant is fine for "chain lightning"
			# But recursion in one frame might be too instant.
			# Let's use a tiny delay or just recurse. Recursion is fine.
			perform_lightning_attack(source_unit, target.global_position, next_target, chain_left - 1, hit_list)

func find_nearest_enemy_excluding(pos: Vector2, range_val: float, exclude_list: Array):
	var nearest = null
	var min_dist = range_val

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy in exclude_list: continue

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
		_spawn_single_projectile(source_unit, pos, target, {"angle": angle})

func _spawn_single_projectile(source_unit, pos, target, extra_stats):
	# FIX: Shotgun logic - force straight flight by removing target
	if source_unit.unit_data.get("proj") == "pellet":
		target = null

	var proj = PROJECTILE_SCENE.instantiate()

	# Gather stats from unit data + active buffs
	var stats = {
		"pierce": source_unit.unit_data.get("pierce", 0),
		"bounce": source_unit.unit_data.get("bounce", 0),
		"split": source_unit.unit_data.get("split", 0),
		"chain": source_unit.unit_data.get("chain", 0)
	}

	# Merge buffs from Unit.gd (if present)
	if "active_buffs" in source_unit:
		for buff in source_unit.active_buffs:
			if buff == "bounce": stats.bounce += 1
			if buff == "split": stats.split += 1

	# Merge extra stats
	stats.merge(extra_stats, true)
	stats.source = source_unit

	proj.setup(pos, target, source_unit.damage, 400.0, source_unit.unit_data.proj, stats)
	add_child(proj)
