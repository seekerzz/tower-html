extends Node

var config: Dictionary = {}
var elapsed_time: float = 0.0
var logs: Array = []
var scheduled_actions_executed: Array = []
var _frame_events: Array = []
var _is_tearing_down: bool = false
var _wave_has_started: bool = false

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

			# Apply stats overrides
			key = GameManager.grid_manager.get_tile_key(u.x, u.y)
			if GameManager.grid_manager.tiles.has(key):
				var tile = GameManager.grid_manager.tiles[key]
				if tile.unit:
					var unit = tile.unit
					if u.has("level"):
						unit.level = u.level
						if unit.behavior and unit.behavior.has_method("on_stats_updated"):
							unit.behavior.on_stats_updated()
					if u.has("attack"):
						unit.damage = u.attack
					if u.has("hp"):
						unit.hp = u.hp
						unit.max_hp = u.hp
				else:
					printerr("[TestRunner] No unit found at tile ", key, " after placement!")
			else:
				printerr("[TestRunner] Tile key not found: ", key)

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
					"grid_x": tile.x,
					"grid_y": tile.y,
					"level": u.level,
					"damage_stat": u.damage # Base damage stat
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
