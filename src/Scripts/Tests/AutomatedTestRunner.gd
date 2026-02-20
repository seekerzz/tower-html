extends Node

var config: Dictionary = {}
var elapsed_time: float = 0.0
var logs: Array = []
var scheduled_actions_executed: Array = []
var _frame_events: Array = []
var _is_tearing_down: bool = false
var _wave_has_started: bool = false

var _damage_records: Dictionary = {}
var _attack_speed_records: Dictionary = {}
var _lifesteal_records: Dictionary = {}

func _ready():
	config = GameManager.current_test_scenario

	print("[TestRunner] Starting test: ", config.get("id", "Unknown"))

	if config.has("start_wave_index"):
		GameManager.wave = config["start_wave_index"]

	if config.has("core_type"):
		GameManager.core_type = config["core_type"]

	call_deferred("_setup_test")

func _setup_test():
	if !GameManager.grid_manager:
		printerr("[TestRunner] GridManager not ready!")
		return

	# Place units
	if config.has("units"):
		for u in config["units"]:
			# Force unlock tile if needed (Test requirement override)
			var key = GameManager.grid_manager.get_tile_key(u.x, u.y)
			if GameManager.grid_manager.tiles.has(key):
				var tile = GameManager.grid_manager.tiles[key]
				if tile.state != "unlocked":
					tile.set_state("unlocked")
					if not GameManager.grid_manager.active_territory_tiles.has(tile):
						GameManager.grid_manager.active_territory_tiles.append(tile)

			GameManager.grid_manager.place_unit(u.id, u.x, u.y)

	# Setup actions
	if config.has("setup_actions"):
		for action in config["setup_actions"]:
			_execute_setup_action(action)

	GameManager.game_over.connect(_on_game_over)
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.enemy_spawned.connect(_on_enemy_spawned)
	GameManager.enemy_hit.connect(_on_enemy_hit)

	GameManager.start_wave()
	# GameManager.wave_ended is only emitted after UI interaction, which we skip in headless.
	# So we monitor is_wave_active in _process instead.

func _on_wave_started():
	_wave_has_started = true
	if config.has("enemies"):
		_spawn_custom_enemies(config["enemies"])

func _spawn_custom_enemies(enemies_config: Array):
	print("[TestRunner] Spawning custom enemies...")
	var gm = GameManager.grid_manager
	var spawn_points = []
	if gm:
		spawn_points = gm.get_spawn_points()

	if spawn_points.is_empty():
		spawn_points.append(Vector2(100, 300)) # Fallback

	for enemy_conf in enemies_config:
		var count = enemy_conf.get("count", 1)
		var type = _map_enemy_type(enemy_conf.get("type", "slime"))

		for i in range(count):
			var pos = spawn_points.pick_random()
			# Add random spread
			pos += Vector2(randf_range(-20, 20), randf_range(-20, 20))

			_create_test_enemy(type, pos, enemy_conf)

			# Stagger spawns slightly if many
			if count > 1:
				await get_tree().create_timer(0.1).timeout

func _map_enemy_type(custom_type: String) -> String:
	match custom_type:
		"weak_enemy": return "slime"
		"high_hp_enemy": return "golem" # Or tank
		"full_hp_enemy": return "slime"
		"fast_enemy": return "wolf" # Or dog/fast
		"attacker_enemy": return "wolf"
		"poisoned_enemy": return "slime"
		"buffed_enemy": return "slime"
		_: return custom_type # Direct mapping or fallback

func _create_test_enemy(type_key: String, pos: Vector2, config_data: Dictionary):
	var enemy_scene = load("res://src/Scenes/Game/Enemy.tscn")
	if not enemy_scene:
		printerr("[TestRunner] Failed to load Enemy scene")
		return

	var enemy = enemy_scene.instantiate()
	enemy.setup(type_key, GameManager.wave)
	enemy.global_position = pos

	# Apply overrides
	if config_data.has("hp"):
		enemy.max_hp = config_data.hp
		enemy.hp = config_data.hp

	if config_data.has("speed"):
		enemy.speed = config_data.speed
		enemy.base_speed = config_data.speed

	if config_data.has("attack_damage"):
		# Enemy.gd usually doesn't have attack_damage property directly exposed for melee collision logic,
		# unless it's an attacker unit behavior.
		# But we can store it in enemy_data or meta for custom behavior if needed.
		if enemy.enemy_data:
			# Clone dictionary to avoid modifying global constant
			enemy.enemy_data = enemy.enemy_data.duplicate()
			enemy.enemy_data["damage"] = config_data.attack_damage

	if config_data.has("attack_speed"):
		if enemy.enemy_data:
			enemy.enemy_data = enemy.enemy_data.duplicate()
			enemy.enemy_data["attack_interval"] = 1.0 / config_data.attack_speed

	get_tree().current_scene.add_child(enemy)

	# Apply Buffs/Debuffs after adding to tree
	if config_data.has("debuffs"):
		for debuff in config_data.debuffs:
			enemy.apply_debuff(debuff.type, debuff.get("stacks", 1))

	if config_data.has("buffs"):
		# If Enemy supports buffs via apply_buff or similar, use it.
		# Currently Enemy.gd only has apply_debuff or apply_status.
		# We assume buffs are just status effects for now.
		for buff in config_data.buffs:
			# Mocking buff application if specific method exists, else ignore or use apply_status
			pass

	print("[TestRunner] Spawned custom enemy: ", type_key, " at ", pos)

func _on_enemy_spawned(enemy):
	var pos = enemy.global_position
	if "enemy_data" in enemy:
		pos = enemy.global_position # Redundant but safe

	_frame_events.append({
		"type": "spawn",
		"enemy_id": enemy.get_instance_id(),
		"enemy_type": enemy.type_key,
		"pos_x": pos.x,
		"pos_y": pos.y
	})

func _on_enemy_hit(enemy, source, amount):
	var source_id = "unknown"
	if source:
		if source is Node:
			source_id = source.name
		if "type_key" in source:
			source_id = source.type_key

	_frame_events.append({
		"type": "hit",
		"target_id": enemy.get_instance_id(),
		"source": source_id,
		"damage": amount,
		"target_hp_after": enemy.hp
	})

func _execute_setup_action(action: Dictionary):
	match action.type:
		"spawn_trap":
			if action.strategy == "random_valid":
				_spawn_random_trap(action.trap_id)
		"apply_buff":
			_apply_buff_to_unit(action.target_unit_id, action.buff_id)

func _spawn_random_trap(trap_id: String):
	# Map test IDs to game IDs
	var real_trap_id = trap_id
	if trap_id == "poison_trap": real_trap_id = "poison"

	var valid_positions = []
	var gm = GameManager.grid_manager

	for key in gm.tiles:
		var tile = gm.tiles[key]
		var grid_pos = Vector2i(tile.x, tile.y)
		if gm.can_place_trap_at(grid_pos):
			valid_positions.append(grid_pos)

	if valid_positions.size() > 0:
		var pos = valid_positions.pick_random()
		gm.spawn_trap_custom(pos, real_trap_id)
		print("[TestRunner] Spawned trap ", real_trap_id, " at ", pos)
	else:
		printerr("[TestRunner] No valid position for trap ", real_trap_id)

func _apply_buff_to_unit(unit_id: String, buff_id: String):
	var gm = GameManager.grid_manager
	var found = false
	for key in gm.tiles:
		var tile = gm.tiles[key]
		if tile.unit and tile.unit.type_key == unit_id:
			tile.unit.apply_buff(buff_id)
			print("[TestRunner] Applied buff ", buff_id, " to ", unit_id)
			found = true
			break
	if !found:
		printerr("[TestRunner] Unit not found for buff: ", unit_id)

func _process(delta):
	if _is_tearing_down: return
	elapsed_time += delta

	# Scheduled Actions
	if config.has("scheduled_actions"):
		for i in range(config["scheduled_actions"].size()):
			if i in scheduled_actions_executed: continue
			var action = config["scheduled_actions"][i]
			if elapsed_time >= action.time:
				_execute_scheduled_action(action)
				scheduled_actions_executed.append(i)

	# Logging (Every Frame)
	_log_status()

	# Shop Validation
	if config.has("validate_shop_faction"):
		_validate_shop_faction(config["validate_shop_faction"])

	# End conditions
	if config.has("duration") and elapsed_time >= config["duration"]:
		_teardown("Duration Reached")

	if config.get("end_condition") == "wave_end_or_fail":
		if _wave_has_started and not GameManager.is_wave_active:
			_teardown("Wave Combat Ended")

	# Fallback safety if wave logic fails or infinite loop
	if elapsed_time > 300.0:
		_teardown("Timeout Safety")

func _execute_scheduled_action(action: Dictionary):
	match action.type:
		"skill":
			var source_id = action.source
			var target_pos = Vector2i(action.target.x, action.target.y)
			var gm = GameManager.grid_manager
			for key in gm.tiles:
				var tile = gm.tiles[key]
				if tile.unit and tile.unit.type_key == source_id:
					tile.unit.execute_skill_at(target_pos)
					print("[TestRunner] Executed skill for ", source_id, " at ", target_pos)
					break
		"summon_test":
			var summon_type = action.summon_type
			var pos_dict = action.position

			var pos = Vector2.ZERO
			if GameManager.grid_manager:
				pos = GameManager.grid_manager.get_world_pos_from_grid(Vector2i(pos_dict.x, pos_dict.y))
			else:
				pos = Vector2(pos_dict.x * 60, pos_dict.y * 60) # Fallback TILE_SIZE=60

			if GameManager.summon_manager:
				var data = {
					"unit_id": summon_type,
					"position": pos,
					"lifetime": 5.0 # Test lifetime override if needed, or rely on default
				}
				GameManager.summon_manager.create_summon(data)
				print("[TestRunner] Summoned ", summon_type, " at ", pos)
			else:
				printerr("[TestRunner] SummonManager not available")
		"test_enemy_death":
			_run_enemy_death_test()
		"damage_core":
			GameManager.damage_core(float(action.amount))
			print("[TestRunner] Action: damage_core ", action.amount)
		"heal_core":
			GameManager.heal_core(float(action.amount))
			print("[TestRunner] Action: heal_core ", action.amount)
		"add_soul":
			if SoulManager:
				SoulManager.add_souls(int(action.amount))
				print("[TestRunner] Action: add_soul ", action.amount)
		"record_damage":
			_record_unit_stat(action.unit_id, "damage", action.label)
		"record_attack_speed":
			_record_unit_stat(action.unit_id, "attack_speed", action.label)
		"record_lifesteal":
			_record_unit_stat(action.unit_id, "lifesteal", action.label)
		"verify_shield":
			# verify_shield doesn't necessarily need a unit_id if verifying core shield or similar,
			# but task example says unit_id implies "verify_hp" style.
			# Actually verify_shield example didn't have unit_id, but "units": [{"id": "rock_armor_cow"}]
			# We'll assume we look for the first unit of interest or a specified unit_id.
			var uid = action.get("unit_id", "")
			_verify_unit_stat(uid, "shield_percent", action.expected_shield_percent, action.get("tolerance", 0.05))
		"verify_hp":
			_verify_unit_stat(action.unit_id, "hp_percent", action.expected_hp_percent, action.get("tolerance", 0.05))
		"devour":
			_trigger_unit_interaction(action.source, action.target, "devour")
		"merge":
			_trigger_unit_interaction(action.source, action.target, "merge")
		"attach":
			_trigger_unit_interaction(action.source, action.target, "attach")
		"mimic":
			_trigger_unit_interaction(action.source, action.target, "mimic")
		"end_wave":
			GameManager.end_wave()
			print("[TestRunner] Action: end_wave triggered")

func _find_unit_by_id(unit_id: String):
	var gm = GameManager.grid_manager
	if !gm: return null
	for key in gm.tiles:
		var tile = gm.tiles[key]
		if tile.unit and tile.unit.type_key == unit_id:
			return tile.unit
	return null

func _record_unit_stat(unit_id: String, stat: String, label: String):
	var unit = _find_unit_by_id(unit_id)
	if !unit:
		printerr("[TestRunner] Record failed: Unit not found ", unit_id)
		return

	var value = 0.0
	match stat:
		"damage": value = unit.damage
		"attack_speed": value = unit.atk_speed # Record interval as speed representation? Or 1/interval
		"lifesteal": value = unit.get("lifesteal_rate", 0.0)

	var record = {"time": elapsed_time, "value": value, "stat": stat}

	if stat == "damage":
		if !_damage_records.has(unit_id): _damage_records[unit_id] = {}
		_damage_records[unit_id][label] = record
	elif stat == "attack_speed":
		if !_attack_speed_records.has(unit_id): _attack_speed_records[unit_id] = {}
		_attack_speed_records[unit_id][label] = record

	print("[TestRunner] Recorded ", stat, " for ", unit_id, " [", label, "]: ", value)

func _verify_unit_stat(unit_id: String, stat_type: String, expected_val: float, tolerance: float):
	var unit = null
	if unit_id != "":
		unit = _find_unit_by_id(unit_id)
	else:
		# If no unit_id, maybe verify first available unit? Or assume caller knows context.
		# For verify_shield in task, it seems implicit.
		# We'll try to find any unit if unit_id is empty, but better to require it or pick first.
		if GameManager.grid_manager:
			for k in GameManager.grid_manager.tiles:
				if GameManager.grid_manager.tiles[k].unit:
					unit = GameManager.grid_manager.tiles[k].unit
					break

	if !unit:
		printerr("[TestRunner] Verify failed: Unit not found ", unit_id)
		return

	var actual_val = 0.0
	match stat_type:
		"hp_percent":
			actual_val = unit.current_hp / unit.max_hp
		"shield_percent":
			var shield = unit.get("shield", 0.0)
			actual_val = shield / unit.max_hp

	if abs(actual_val - expected_val) <= tolerance:
		print("[TestRunner] ✓ Verified ", stat_type, ": Expected ", expected_val, " Actual ", actual_val)
	else:
		printerr("[TestRunner] ✗ Verify ", stat_type, " FAILED: Expected ", expected_val, " Actual ", actual_val)

func _trigger_unit_interaction(source_id: String, target_id: String, method: String):
	var source = _find_unit_by_id(source_id)
	var target = _find_unit_by_id(target_id)

	if !source:
		printerr("[TestRunner] Interaction ", method, " failed: Source not found ", source_id)
		return

	# Target might be a unit or enemy? Task examples use unit ids.
	# But target_id in task example is a string.

	if source.has_method(method):
		source.call(method, target)
		print("[TestRunner] Triggered ", method, " from ", source_id, " to ", target_id)
	else:
		printerr("[TestRunner] Source unit ", source_id, " does not have method ", method)

func _run_enemy_death_test():
	print("[TestRunner] ========== 开始敌人死亡重复调用测试 ==========")

	# 使用一个独立节点来跟踪信号计数（避免lambda的变量捕获问题）
	var tracker = Node.new()
	tracker.set_meta("death_count", 0)
	tracker.set_meta("soul_before", SoulManager.current_souls)
	get_tree().current_scene.add_child(tracker)

	# 创建测试敌人
	var enemy_scene = load("res://src/Scenes/Game/Enemy.tscn")
	if not enemy_scene:
		printerr("[TestRunner] 无法加载敌人场景")
		return

	var enemy = enemy_scene.instantiate()
	enemy.global_position = Vector2(400, 400)
	enemy.setup("slime", 1)
	enemy.hp = 100
	enemy.max_hp = 100

	# 连接信号
	enemy.died.connect(func():
		var count = tracker.get_meta("death_count") + 1
		tracker.set_meta("death_count", count)
		print("[TestRunner] died 信号触发 #", count)
	)

	get_tree().current_scene.add_child(enemy)
	print("[TestRunner] 测试敌人创建完成，HP: ", enemy.hp, ", 初始魂魄: ", tracker.get_meta("soul_before"))

	await get_tree().process_frame

	# 模拟多段伤害
	print("[TestRunner] 模拟多段伤害 (3次 take_damage 调用)...")
	enemy.take_damage(40, null)
	enemy.take_damage(40, null)
	enemy.take_damage(40, null)

	await get_tree().process_frame
	await get_tree().process_frame

	# 验证结果
	print("\n[TestRunner] ========== 测试结果 ==========")
	var test_passed = true

	var death_count = tracker.get_meta("death_count")
	var soul_increase = SoulManager.current_souls - tracker.get_meta("soul_before")

	# 验证1: died 信号只应该触发一次
	if death_count == 0:
		printerr("[TestRunner] ✗ died 信号没有被触发")
		test_passed = false
	elif death_count > 1:
		printerr("[TestRunner] ✗ died 信号被触发了 ", death_count, " 次 - 存在重复调用bug!")
		test_passed = false
	else:
		print("[TestRunner] ✓ died 信号正确触发1次")

	# 验证2: 魂魄只应该增加1次
	if soul_increase == 0:
		printerr("[TestRunner] ✗ 魂魄没有增加")
		test_passed = false
	elif soul_increase > 1:
		printerr("[TestRunner] ✗ 魂魄增加了 ", soul_increase, " 次!")
		test_passed = false
	else:
		print("[TestRunner] ✓ 魂魄正确增加1次 (", SoulManager.current_souls, ")")

	if test_passed:
		print("\n[TestRunner] ========== 测试通过 ✓ ==========")
	else:
		print("\n[TestRunner] ========== 测试失败 ✗ ==========")

	# 清理
	if is_instance_valid(enemy):
		enemy.queue_free()
	tracker.queue_free()

	print("[TestRunner] ========== 敌人死亡测试结束 ==========\n")

# ==========================================
# Extended Verification & Helpers
# ==========================================

func compare_damage(unit_id: String, label_before: String, label_after: String) -> Dictionary:
	if !_damage_records.has(unit_id): return {}
	var records = _damage_records[unit_id]
	if !records.has(label_before) or !records.has(label_after): return {}

	var val_before = records[label_before].value
	var val_after = records[label_after].value
	return {
		"before": val_before,
		"after": val_after,
		"diff": val_after - val_before,
		"ratio": val_after / val_before if val_before != 0 else 0
	}

func assert_damaged(enemy_type: String, min_damage: float = 0.0) -> bool:
	for frame_log in logs:
		var events = frame_log.get("events", [])
		for evt in events:
			if evt.type == "hit" and evt.damage >= min_damage:
				var target_id = evt.target_id
				# Find enemy type in this frame's enemies list
				for e_info in frame_log.enemies:
					if e_info.instance_id == target_id:
						if e_info.type == enemy_type:
							return true
	return false

func assert_buff_applied(unit_id: String, buff_id: String) -> bool:
	var unit = _find_unit_by_id(unit_id)
	if !unit: return false
	if unit.has_method("has_buff"):
		return unit.has_buff(buff_id)
	# Check active_buffs array if method not present
	if "active_buffs" in unit:
		return unit.active_buffs.has(buff_id)
	return false

func assert_debuff_applied(enemy_filter: Dictionary, debuff_id: String) -> bool:
	var target_type = _map_enemy_type(enemy_filter.get("type", ""))
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e.type_key == target_type:
			if e.has_method("has_status"):
				if e.has_status(debuff_id): return true
	return false

func assert_hp_changed(unit_id: String, expected_change: float, tolerance: float = 0.0) -> bool:
	var initial_hp = -1.0
	var final_hp = -1.0

	# Find initial HP
	for entry in logs:
		for u_info in entry.units:
			if u_info.id == unit_id:
				initial_hp = u_info.hp
				break
		if initial_hp != -1.0: break

	# Find final HP (current)
	var unit = _find_unit_by_id(unit_id)
	if unit:
		final_hp = unit.current_hp

	if initial_hp == -1.0 or final_hp == -1.0:
		printerr("[TestRunner] assert_hp_changed failed: Unit not found or not tracked. Init: ", initial_hp, " Final: ", final_hp)
		return false

	var actual_change = final_hp - initial_hp
	if abs(actual_change - expected_change) <= tolerance:
		print("[TestRunner] ✓ Verified hp_changed for ", unit_id, ": Expected ", expected_change, " Actual ", actual_change)
		return true
	else:
		printerr("[TestRunner] ✗ Verify hp_changed for ", unit_id, " FAILED: Expected ", expected_change, " Actual ", actual_change)
		return false

func assert_mp_changed(expected_change: float, tolerance: float = 0.0) -> bool:
	var initial_mp = -1.0
	if logs.size() > 0:
		initial_mp = logs[0].mana

	var final_mp = GameManager.mana

	if initial_mp == -1.0:
		printerr("[TestRunner] assert_mp_changed failed: No logs")
		return false

	var actual_change = final_mp - initial_mp
	if abs(actual_change - expected_change) <= tolerance:
		print("[TestRunner] ✓ Verified mp_changed: Expected ", expected_change, " Actual ", actual_change)
		return true
	else:
		printerr("[TestRunner] ✗ Verify mp_changed FAILED: Expected ", expected_change, " Actual ", actual_change)
		return false

func assert_target_switched(enemy_id: int, from_unit_id: String, to_unit_id: String) -> bool:
	# Scan logs for hit events from this enemy
	var hit_from = false
	var switched = false

	for entry in logs:
		for evt in entry.events:
			if evt.type == "hit" and evt.source == "enemy" and evt.has("enemy_id") and evt.enemy_id == enemy_id:
				# How to identify target unit? evt.target_id is instance_id.
				# We need to map target_id to unit type.
				var target_unit_type = ""
				for u in entry.units:
					if u.instance_id == evt.target_id:
						target_unit_type = u.id
						break

				if target_unit_type == from_unit_id:
					hit_from = true
				elif target_unit_type == to_unit_id and hit_from:
					switched = true
					break
		if switched: break

	if switched:
		print("[TestRunner] ✓ Verified target switched from ", from_unit_id, " to ", to_unit_id)
		return true
	else:
		# Note: Tracking specific enemy ID from external test config is hard unless we captured it.
		# This assertion is best effort.
		printerr("[TestRunner] ✗ Verify target switch FAILED")
		return false

func assert_clone_spawned(original_type: String, clone_attrs: Dictionary = {}) -> bool:
	# Check if units list contains a unit with is_clone=true or similar?
	var gm = GameManager.grid_manager
	if !gm: return false
	for key in gm.tiles:
		var u = gm.tiles[key].unit
		if u and u.type_key == original_type:
			# How to identify clone? Maybe different ID or meta?
			if u.has_meta("is_clone"): return true
	return false

func _log_status():
	var units_info = []
	var gm = GameManager.grid_manager
	if gm:
		for key in gm.tiles:
			var tile = gm.tiles[key]
			if tile.unit:
				var u = tile.unit
				units_info.append({
					"id": u.type_key,
					"instance_id": u.get_instance_id(),
					"grid_x": tile.x,
					"grid_y": tile.y,
					"level": u.level,
					"damage_stat": u.damage, # Base damage stat
					"hp": u.current_hp,
					"max_hp": u.max_hp
				})

	var enemies_info = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			enemies_info.append({
				"instance_id": enemy.get_instance_id(),
				"type": enemy.type_key,
				"hp": enemy.hp,
				"max_hp": enemy.max_hp,
				"pos_x": enemy.global_position.x,
				"pos_y": enemy.global_position.y
			})

	var entry = {
		"frame": Engine.get_process_frames(),
		"time": elapsed_time,
		"gold": GameManager.gold,
		"mana": GameManager.mana,
		"core_health": GameManager.core_health,
		"units": units_info,
		"enemies": enemies_info,
		"events": _frame_events.duplicate()
	}
	logs.append(entry)
	_frame_events.clear()

func _on_game_over():
	_teardown("Game Over Signal")

func _validate_shop_faction(faction: String):
	var shop = get_tree().root.find_child("Shop", true, false)
	if not shop:
		# Try MainGame CanvasLayer
		if GameManager.main_game:
			shop = GameManager.main_game.find_child("Shop", true, false)

	if not shop:
		# Shop might not be instantiated yet
		return

	# Assuming shop has 'shop_items' array of strings (unit keys)
	if "shop_items" in shop:
		var items = shop.shop_items
		if items.size() == 0:
			# Shop might not be ready yet
			return

		var all_valid = true
		for item in items:
			var unit_data = Constants.UNIT_TYPES.get(item, {})
			var unit_faction = unit_data.get("faction", "universal")

			if unit_faction != faction and unit_faction != "universal":
				all_valid = false
				printerr("[TestRunner] Shop validation FAILED. Found unit '%s' (faction: %s) but expected faction '%s'" % [item, unit_faction, faction])
				_teardown("Shop Validation Failed")
				return

		if all_valid:
			print("[TestRunner] Shop validation PASSED for faction: ", faction, ". Items: ", items)
			# Only validate once successfully then stop checking to avoid log spam
			config.erase("validate_shop_faction")

func _teardown(reason: String):
	if _is_tearing_down: return
	_is_tearing_down = true

	print("[TestRunner] Finishing test. Reason: ", reason)

	var user_dir = "user://test_logs/"
	if !DirAccess.dir_exists_absolute(user_dir):
		DirAccess.make_dir_absolute(user_dir)

	var file_path = user_dir + config.id + ".json"
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(logs, "\t"))
		file.close()
		print("[TestRunner] Logs saved to ", file_path)
	else:
		printerr("[TestRunner] Failed to save logs to ", file_path)

	get_tree().quit()
