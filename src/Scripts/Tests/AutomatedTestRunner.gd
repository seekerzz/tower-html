extends Node

var config: Dictionary = {}
var elapsed_time: float = 0.0
var logs: Array = []
var scheduled_actions_executed: Array = []
var _is_tearing_down: bool = false
var _wave_has_started: bool = false
var _frame_events: Array = []

func _ready():
	config = GameManager.current_test_scenario

	print("[TestRunner] Starting test: ", config.get("id", "Unknown"))

	if config.has("start_wave_index"):
		GameManager.wave = config["start_wave_index"]

	call_deferred("_setup_test")

func _setup_test():
	if !GameManager.grid_manager:
		printerr("[TestRunner] GridManager not ready!")
		return

	# Set Core Type and force shop refresh if needed
	if config.has("core_type"):
		GameManager.core_type = config["core_type"]
		if GameManager.main_game and GameManager.main_game.shop:
			GameManager.main_game.shop.refresh_shop(true)
			print("[TestRunner] Set core_type to ", config["core_type"], " and refreshed shop.")

	# Validate Shop immediately if requested
	if config.has("validate_shop_faction"):
		_validate_shop_faction(config["validate_shop_faction"])

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
	GameManager.wave_ended.connect(_on_wave_ended_custom)
	GameManager.enemy_spawned.connect(_on_enemy_spawned)
	GameManager.enemy_hit.connect(_on_enemy_hit)

	GameManager.start_wave()
	# GameManager.wave_ended is only emitted after UI interaction, which we skip in headless.
	# So we monitor is_wave_active in _process instead.

func _on_wave_ended_custom():
	if config.has("validate_shop_faction"):
		_validate_shop_faction(config["validate_shop_faction"])

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

func _validate_shop_faction(expected_faction):
	var main_game = GameManager.main_game
	if !main_game or !main_game.shop:
		printerr("[TestRunner] Shop not found for validation")
		return

	var shop = main_game.shop
	var items = shop.shop_items

	if items.size() == 0:
		printerr("[TestRunner] Shop is empty!")
		return

	print("[TestRunner] Validating shop items: ", items, " for faction: ", expected_faction)

	for unit_key in items:
		var unit_data = Constants.UNIT_TYPES[unit_key]
		var faction = unit_data.get("faction", "universal")
		if faction != "universal" and faction != expected_faction:
			printerr("[TestRunner] FAIL: Shop item ", unit_key, " has faction ", faction, " expected ", expected_faction)
			_teardown("Shop Faction Validation Failed")
			return

	print("[TestRunner] Shop validation PASSED for this check.")

func _on_game_over():
	_teardown("Game Over Signal")

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
