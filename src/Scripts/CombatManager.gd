extends Node

const ENEMY_SCENE = preload("res://src/Scenes/Game/Enemy.tscn")
const PROJECTILE_SCENE = preload("res://src/Scenes/Game/Projectile.tscn")
const LIGHTNING_SCENE = preload("res://src/Scenes/Game/LightningArc.tscn")
const SLASH_EFFECT_SCRIPT = preload("res://src/Scripts/Effects/SlashEffect.gd")

var enemies_to_spawn: int = 0
var total_enemies_for_wave: int = 0
# spawn_timer removed as we use coroutines now

var explosion_queue: Array = []

func _ready():
	GameManager.combat_manager = self
	GameManager.wave_started.connect(_on_wave_started)

func _process(delta):
	# Process Explosion Queue (Burn Chain Reaction)
	if explosion_queue.size() > 0:
		var current_batch = explosion_queue.duplicate()
		explosion_queue.clear()
		for expl in current_batch:
			_process_burn_explosion(expl)

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

	if wave == 5:
		spawn_boss_wave()
		return

	# Calculate total enemies (Increased difficulty logic from ref.html)
	# const baseCount = 20 + Math.floor(game.wave * 6);
	total_enemies_for_wave = 20 + floor(wave * 6)
	enemies_to_spawn = total_enemies_for_wave

	# Batch calculation
	# const batchCount = 3 + Math.floor(game.wave / 2);
	var batch_count = 3 + floor(wave / 2.0)
	var enemies_per_batch = ceil(float(total_enemies_for_wave) / batch_count)

	_run_batch_sequence(batch_count, int(enemies_per_batch))

func spawn_boss_wave():
	# Hardcoded Wave 5 Event
	# Pick 2 different bosses from [summoner, ranger, tank]
	var boss_options = ["summoner", "ranger", "tank"]
	boss_options.shuffle()

	var boss1 = boss_options[0]
	var boss2 = boss_options[1]

	total_enemies_for_wave = 2
	enemies_to_spawn = 2

	GameManager.spawn_floating_text(Vector2(0, -200), "DOUBLE BOSS WAVE!", Color.RED)

	# Spawn Boss 1 on Left, Boss 2 on Right (Assuming standard spawn points)
	# We need to find valid spawn points.
	var spawn_points = []
	if GameManager.grid_manager:
		spawn_points = GameManager.grid_manager.get_spawn_points()

	if spawn_points.is_empty():
		spawn_points.append(Vector2(-300, 0))
		spawn_points.append(Vector2(300, 0))

	# Try to find left-most and right-most points
	spawn_points.sort_custom(func(a, b): return a.x < b.x)

	var left_point = spawn_points[0]
	var right_point = spawn_points[spawn_points.size() - 1]

	_spawn_enemy_at_pos(left_point, boss1)
	enemies_to_spawn -= 1
	await get_tree().create_timer(1.0).timeout
	_spawn_enemy_at_pos(right_point, boss2)
	enemies_to_spawn -= 1

	start_win_check_loop()

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

	# Spawn Batch
	await _spawn_batch(type_key, enemies_per_batch)

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

func _spawn_batch(type_key: String, count: int):
	var points = []
	if GameManager.grid_manager:
		points = GameManager.grid_manager.get_spawn_points()

	if points.size() == 0:
		# Fallback to map center or some default
		points.append(Vector2.ZERO)

	for i in range(count):
		if !GameManager.is_wave_active: break
		if enemies_to_spawn <= 0: break

		var spawn_point = points.pick_random()

		# Spawn with slight spread around the chosen spawn point
		var pos = spawn_point + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		_spawn_enemy_at_pos(pos, type_key)

		enemies_to_spawn -= 1

		# Fast spawn (0.1s)
		await get_tree().create_timer(0.1).timeout

func _spawn_enemy_at_pos(pos: Vector2, type_key: String):
	var enemy = ENEMY_SCENE.instantiate()
	enemy.setup(type_key, GameManager.wave)
	enemy.global_position = pos
	add_child(enemy)


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

		# [New Logic] Melee as Projectile
		if unit.unit_data.attackType == "melee":
			unit.cooldown = unit.atk_speed
			unit.play_attack_anim(unit.unit_data.attackType, target.global_position)

			# 区分攻击模式
			if unit.type_key == "bear":
				# 模式A: 暴躁熊 - 左右横扫 (Side Swipe)
				_perform_swipe_attack(unit, target)
			else:
				# 模式B: 普通近战 - 正向突刺 (Forward Thrust)
				# 将普通近战也转化为投射物，以获得正确的飘字方向
				_perform_direct_melee_attack(unit, target)

		elif unit.unit_data.attackType == "ranged" and unit.unit_data.get("proj") == "lightning":
			# Lightning handling
			# "eel": "attackType": "ranged", "proj": "lightning", "chain": 4
			perform_lightning_attack(unit, tile.global_position, target, unit.unit_data.get("chain", 0))
		else:
			# Check for Multi-shot (projCount)
			var proj_count = unit.unit_data.get("projCount", 1)
			var spread = unit.unit_data.get("spread", 0.5)

			if "multishot" in unit.active_buffs:
				proj_count += 2
				spread = max(spread, 0.5)

			if proj_count > 1:
				spawn_multishot_projectile(unit, tile.global_position, target, proj_count, spread)
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
	var dmg = source_unit.calculate_damage_against(target)
	target.take_damage(dmg, source_unit, "lightning")
	hit_list.append(target)

	# Visual
	var arc = LIGHTNING_SCENE.instantiate()
	add_child(arc)
	arc.setup(start_pos, target.global_position)

	# Chain
	if chain_left > 0:
		var next_target = find_nearest_enemy_excluding(target.global_position, 300.0, hit_list)
		if next_target:
			var next_start_pos = target.global_position
			await get_tree().create_timer(0.15).timeout
			if is_instance_valid(source_unit):
				perform_lightning_attack(source_unit, next_start_pos, next_target, chain_left - 1, hit_list)

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
	if source_unit.unit_data.get("proj") == "ink" or extra_stats.has("angle"):
		target = null

	var proj = PROJECTILE_SCENE.instantiate()

	# Crit Calculation
	var is_critical = randf() < source_unit.crit_rate
	var base_dmg = source_unit.calculate_damage_against(target) if target else source_unit.damage
	var final_damage = base_dmg
	if is_critical:
		final_damage *= source_unit.crit_dmg

	# Gather stats from unit data + active buffs
	var stats = {
		"pierce": source_unit.unit_data.get("pierce", 0),
		"bounce": source_unit.unit_data.get("bounce", 0),
		"split": source_unit.unit_data.get("split", 0),
		"chain": source_unit.unit_data.get("chain", 0),
		"damageType": source_unit.unit_data.get("damageType", "physical"),
		"is_critical": is_critical
	}

	# Merge buffs from Unit.gd (if present)
	var effects = {}
	if "active_buffs" in source_unit:
		for buff in source_unit.active_buffs:
			if buff == "bounce": stats["bounce"] += 1
			if buff == "split": stats["split"] += 1
			if buff == "fire": effects["burn"] = 3.0
			if buff == "poison": effects["poison"] = 5.0

	# Check native unit traits/attributes if they have intrinsic effects (Optional, based on task)
	# But Task says "fire" buff or attribute.
	if source_unit.unit_data.get("buffProvider") == "fire": # Although Torch doesn't shoot usually
		effects["burn"] = 3.0
	if source_unit.unit_data.get("buffProvider") == "poison":
		effects["poison"] = 5.0

	# New Traits Logic
	var unit_trait = source_unit.unit_data.get("trait")
	if unit_trait == "poison_touch":
		effects["poison"] = 5.0 # Accumulates
	elif unit_trait == "slow":
		effects["slow"] = 2.0 # Duration
	elif unit_trait == "freeze":
		effects["freeze"] = 2.0 # Duration

	stats["effects"] = effects

	# Merge extra stats
	stats.merge(extra_stats, true)
	stats.source = source_unit

	var proj_speed = source_unit.unit_data.get("projectile_speed", 400.0)
	proj.setup(pos, target, final_damage, proj_speed, source_unit.unit_data.proj, stats)
	add_child(proj)

func queue_burn_explosion(pos: Vector2, damage: float, source: Node2D):
	explosion_queue.append({ "pos": pos, "damage": damage, "source": source })

func _process_burn_explosion(expl):
	var pos = expl.pos
	var damage = expl.damage
	var source = expl.source
	var radius = 120.0

	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if !is_instance_valid(enemy): continue
		# Note: We can't check 'enemy == self' easily here as source is the Killer, not the Victim.
		# The victim is already dead/dying at 'pos'.
		# However, checking distance > 0 might help avoid some issues, but distance check covers it.

		var dist = pos.distance_to(enemy.global_position)
		if dist <= radius:
			enemy.take_damage(damage, source, "fire")
			enemy.effects["burn"] = 5.0
			enemy.burn_source = source

# 模式A: 左右交替横扫 (Bear)
func _perform_swipe_attack(source_unit, target_enemy):
	if not is_instance_valid(target_enemy): return

	var to_target_dir = (target_enemy.global_position - source_unit.global_position).normalized()
	var right_dir = Vector2(-to_target_dir.y, to_target_dir.x)

	var start_pos = Vector2.ZERO
	var fly_dir = Vector2.ZERO
	var swipe_width = 80.0 # 挥击半宽

	# 交替方向
	if source_unit.swipe_right_next:
		# 右 -> 左
		start_pos = target_enemy.global_position + (right_dir * swipe_width)
		fly_dir = -right_dir
	else:
		# 左 -> 右
		start_pos = target_enemy.global_position - (right_dir * swipe_width)
		fly_dir = right_dir

	source_unit.swipe_right_next = !source_unit.swipe_right_next

	# 稍微修正起点，避免过于贴脸导致判定失效，往回拉一点
	start_pos -= fly_dir * 10.0

	# 配置横扫子弹: 穿透所有(99)，极快速度，极短生存时间
	var stats = {
		"pierce": 99,
		"angle": fly_dir.angle(),
		"lifetime": 0.2, # 0.2秒扫过屏幕
		"source": source_unit
	}

	# 使用高速度 (1000) 确保瞬间扫过
	_spawn_melee_projectile(source_unit, start_pos, null, 1000.0, stats)

	# 播放爪痕特效 (SlashEffect)
	var slash = SLASH_EFFECT_SCRIPT.new()
	add_child(slash)
	slash.global_position = target_enemy.global_position
	slash.rotation = fly_dir.angle()
	slash.play()

# 模式B: 正向突刺 (Standard Melee)
func _perform_direct_melee_attack(source_unit, target_enemy):
	if not is_instance_valid(target_enemy): return

	var start_pos = source_unit.global_position
	var dir = (target_enemy.global_position - start_pos).normalized()

	# 配置突刺子弹: 速度适中，射程覆盖攻击范围即可
	var stats = {
		"pierce": source_unit.unit_data.get("pierce", 0), # 继承单位穿透属性
		"angle": dir.angle(),
		"source": source_unit
	}

	# 速度 600，目标为 null (走直线)，依靠碰撞造成伤害
	_spawn_melee_projectile(source_unit, start_pos, null, 600.0, stats)

# 通用近战投射物生成器
func _spawn_melee_projectile(source_unit, pos, target, speed, extra_stats):
	var proj = PROJECTILE_SCENE.instantiate()

	# 计算伤害 (如果有目标则针对目标计算，否则取面板)
	var dmg = source_unit.calculate_damage_against(target) if target else source_unit.damage
	# 暴击判定
	var is_critical = randf() < source_unit.crit_rate
	if is_critical: dmg *= source_unit.crit_dmg
	extra_stats["is_critical"] = is_critical

	# 强制设置为隐形类型
	proj.setup(pos, target, dmg, speed, "melee_invisible", extra_stats)
	add_child(proj)
