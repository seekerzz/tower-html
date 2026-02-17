extends Node

var config: Dictionary = {}
var elapsed_time: float = 0.0
var logs: Array = []
var next_log_time: float = 0.0
var log_interval: float = 0.5
var scheduled_actions_executed: Array = []
var _is_tearing_down: bool = false
var _wave_has_started: bool = false

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
	GameManager.start_wave()
	# GameManager.wave_ended is only emitted after UI interaction, which we skip in headless.
	# So we monitor is_wave_active in _process instead.

func _on_wave_started():
	_wave_has_started = true

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

	# Logging
	if elapsed_time >= next_log_time:
		_log_status()
		next_log_time += log_interval

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

func _log_status():
	var unit_count = 0
	var gm = GameManager.grid_manager
	if gm:
		for key in gm.tiles:
			if gm.tiles[key].unit:
				unit_count += 1

	var entry = {
		"time": elapsed_time,
		"gold": GameManager.gold,
		"mana": GameManager.mana,
		"core_health": GameManager.core_health,
		"unit_count": unit_count
	}
	logs.append(entry)

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
