extends Node

signal resource_changed
signal core_type_changed
signal wave_started
signal wave_ended
signal wave_reset
signal game_over
signal unit_purchased(unit_data)
signal unit_sold(amount)
signal skill_activated(unit)
signal damage_dealt(unit, amount)
signal world_impact(direction: Vector2, strength: float)
signal ftext_spawn_requested(pos, value, color, direction)
signal show_tooltip(data, stats, buffs, pos)
signal hide_tooltip()
signal projectile_crit(source_unit, target, damage)
signal enemy_hit(enemy, source, amount)
signal enemy_spawned(enemy)
signal enemy_died(enemy, killer_unit)
signal debuff_applied(enemy, debuff_type, stacks)
signal totem_echo_triggered(source_unit, damage)

var is_running_test: bool = false
var current_test_scenario: Dictionary = {}

var core_type: String = "":
	set(value):
		core_type = value
		_initialize_mechanic()
		core_type_changed.emit()

# ===== 资源系统 =====
# 法力系统
var mana: float = 500.0          # 当前法力
var max_mana: float = 1000.0     # 最大法力
var base_mana_rate: float = 10.0 # 每秒基础回蓝

# 金币系统
var gold: int = 150              # 初始金币

# 波次状态
var wave: int = 1
var is_wave_active: bool = false

# ===== 核心血量系统 =====
# 基础核心血量（固定值）+ 单位血量加成
# 初始没有单位时：core_health = max_core_health = BASE_CORE_HP(500)
var core_health: float = 500.0
var max_core_health: float = 500.0

var damage_multiplier: float = 1.0

var tile_cost: int = 50

var upgrade_selection_scene = preload("res://src/Scenes/UI/UpgradeSelection.tscn")

# Global references
var grid_manager = null
var inventory_manager = null
var combat_manager = null
var ui_manager = null
var main_game = null
var reward_manager: Node = null
var data_manager: Node = null
var lifesteal_manager: Node = null
var summon_manager: Node = null

var permanent_health_bonus: float = 0.0

# ===== 全局Buff系统 =====
var _global_buffs: Dictionary = {}

func apply_global_buff(buff_name: String, value: float):
	_global_buffs[buff_name] = value

func remove_global_buff(buff_name: String):
	_global_buffs.erase(buff_name)

func get_global_buff(buff_name: String, default_value: float = 1.0) -> float:
	return _global_buffs.get(buff_name, default_value)

# Relic Logic
var indomitable_triggered: bool = false
var indomitable_timer: float = 0.0

# Cheat Flags
var cheat_god_mode: bool = false
var cheat_infinite_resources: bool = false
var cheat_fast_cooldown: bool = false

var _hit_stop_end_time: int = 0

# Core Mechanics Variables
var current_mechanic: Node = null

func set_test_scenario(scenario: Dictionary):
	current_test_scenario = scenario
	is_running_test = true
	if scenario.has("initial_gold"):
		gold = scenario["initial_gold"]
	if scenario.has("initial_mp"):
		mana = scenario["initial_mp"]

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Connect signals for Core mechanics
	damage_dealt.connect(_on_damage_dealt)
	wave_started.connect(_on_wave_started)

	# Initialize DataManager and load data first
	var DataManagerScript = load("res://src/Scripts/Managers/DataManager.gd")
	data_manager = DataManagerScript.new()
	add_child(data_manager)
	data_manager.load_data()

	# Initialize InventoryManager
	var InvMgrScript = load("res://src/Scripts/Managers/InventoryManager.gd")
	inventory_manager = InvMgrScript.new()
	add_child(inventory_manager)

	if reward_manager == null:
		var rm_scene = load("res://src/Scripts/Managers/RewardManager.gd")
		if rm_scene:
			reward_manager = rm_scene.new()
			add_child(reward_manager)
			reward_manager.sacrifice_state_changed.connect(_on_sacrifice_state_changed)

	# Initialize LifestealManager
	var LSManagerScript = load("res://src/Scripts/Managers/LifestealManager.gd")
	lifesteal_manager = LSManagerScript.new()
	add_child(lifesteal_manager)

	_initialize_mechanic()

func _initialize_mechanic():
	if current_mechanic:
		current_mechanic.queue_free()
		current_mechanic = null

	var mech_script = null
	match core_type:
		"cow_totem": mech_script = load("res://src/Scripts/CoreMechanics/MechanicCowTotem.gd")
		"bat_totem": mech_script = load("res://src/Scripts/CoreMechanics/MechanicBatTotem.gd")
		"viper_totem": mech_script = load("res://src/Scripts/CoreMechanics/MechanicViperTotem.gd")
		"butterfly_totem": mech_script = load("res://src/Scripts/CoreMechanics/MechanicButterflyTotem.gd")
		"eagle_totem": mech_script = load("res://src/Scripts/CoreMechanics/MechanicEagleTotem.gd")
		_: mech_script = load("res://src/Scripts/CoreMechanics/MechanicGeneral.gd")

	if mech_script:
		current_mechanic = mech_script.new()
		add_child(current_mechanic)

func _set_ignore_mouse_recursive(node: Node):
	node.set_process_input(false)
	node.set_process_unhandled_input(false)
	if node is CollisionObject2D:
		node.input_pickable = false
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for child in node.get_children():
		_set_ignore_mouse_recursive(child)


func _on_damage_dealt(unit, amount):
	if current_mechanic:
		current_mechanic.on_damage_dealt_by_unit(unit, amount)

func _on_wave_started():
	if current_mechanic:
		current_mechanic.on_wave_started()

func use_item_effect(item_id: String, target_unit = null) -> bool:
	# 物品系统已移除，保留函数结构用于后续扩展
	return false

func trigger_hit_stop(duration_sec: float, time_scale: float = 0.05):
	var current_time = Time.get_ticks_msec()
	var duration_msec = int(duration_sec * 1000)
	var new_end_time = current_time + duration_msec

	# If currently in hit stop (end time > current), check if new duration extends it
	if current_time < _hit_stop_end_time:
		if new_end_time <= _hit_stop_end_time:
			return # New stop is shorter or equal, ignore

	_hit_stop_end_time = new_end_time
	Engine.time_scale = time_scale

	# Create a timer that ignores time scale
	var timer = get_tree().create_timer(duration_sec, true, false, true)
	timer.timeout.connect(_on_hit_stop_end)

func _on_hit_stop_end():
	Engine.time_scale = 1.0

func _process(delta):
	if indomitable_timer > 0:
		indomitable_timer -= delta
		if indomitable_timer <= 0:
			indomitable_timer = 0
			spawn_floating_text(grid_manager.global_position if grid_manager else Vector2.ZERO, "Mortality Restored", Color.RED)

	if is_wave_active and core_health > 0:
		update_resources(delta)

func get_stat_modifier(stat_type: String, context: Dictionary = {}) -> float:
	if not reward_manager:
		return 1.0

	var modifier: float = 1.0

	match stat_type:
		"cooldown":
			if "demon_manual" in reward_manager.acquired_artifacts:
				modifier *= 0.8
		"damage":
			if "raven_feather" in reward_manager.acquired_artifacts:
				# 1.0 + (1.0 - current/max) -> Lower HP, Higher Damage
				# If full HP: 1.0 + 0 = 1.0
				# If 0 HP: 1.0 + 1.0 = 2.0
				modifier *= (1.0 + (1.0 - (core_health / max_core_health)))
		"attack_interval":
			if "berserker_horn" in reward_manager.acquired_artifacts:
				if core_health < max_core_health * 0.2:
					modifier *= 0.5
		"enemy_mass":
			if "moon_soil" in reward_manager.acquired_artifacts:
				modifier *= 0.8

	if current_mechanic:
		modifier *= current_mechanic.get_stat_modifier(stat_type, context)

	return modifier

func update_resources(delta):
	if mana < max_mana:
		mana = min(max_mana, mana + base_mana_rate * delta)
	resource_changed.emit()

func start_wave():
	if is_wave_active: return
	is_wave_active = true
	indomitable_triggered = false
	wave_started.emit()

func end_wave():
	is_wave_active = false

	# Pause logic implicitly by not emitting wave_ended immediately if we want to block new wave
	# But actually we usually want to show the UI now.

	if upgrade_selection_scene:
		var upgrade_ui = upgrade_selection_scene.instantiate()
		# Add directly to GameManager (Autoload) since the scene is a CanvasLayer
		# This ensures it overlays on top of everything regardless of the current scene.
		add_child(upgrade_ui)

		# Connect signal
		upgrade_ui.upgrade_selected.connect(_on_upgrade_selected)
	else:
		# Fallback if no scene
		_finish_wave_process()

func _finish_wave_process():
	wave += 1
	# 每波结束固定获得金币：20 + 波次×5
	gold += 20 + (wave * 5)

	# 每波结束恢复法力至满值（血量不自动恢复）
	mana = max_mana

	wave_ended.emit()
	resource_changed.emit()

func _on_upgrade_selected(upgrade_data):
	match upgrade_data.id:
		"heal_core":
			core_health = min(max_core_health, core_health + (max_core_health * 0.1))
		"gold_boost":
			gold += 50
		"damage_boost":
			damage_multiplier += 0.1

	resource_changed.emit()
	_finish_wave_process()

func heal_core(amount: float):
	damage_core(-amount)

func damage_core(amount: float):
	if current_mechanic:
		current_mechanic.on_core_damaged(amount)

	if cheat_god_mode and amount > 0:
		print("[GodMode] Damage blocked. Original amount: ", amount)
		amount = 0

	# Indomitable Will Immunity
	if indomitable_timer > 0 and amount > 0:
		spawn_floating_text(grid_manager.global_position if grid_manager else Vector2.ZERO, "Immune!", Color.GOLD)
		return

	if amount > 0 and reward_manager and "biomass_armor" in reward_manager.acquired_artifacts:
		amount = min(amount, max_core_health * 0.05)

	# Indomitable Will Trigger Check (Prevent Death)
	if amount > 0 and (core_health - amount <= 0):
		if reward_manager and "indomitable_will" in reward_manager.acquired_artifacts and not indomitable_triggered:
			indomitable_triggered = true
			core_health = 1.0
			indomitable_timer = 5.0
			spawn_floating_text(grid_manager.global_position if grid_manager else Vector2.ZERO, "UNDYING!", Color.PURPLE)
			resource_changed.emit()
			return

	core_health -= amount
	resource_changed.emit()
	if core_health <= 0:
		core_health = 0
		is_wave_active = false
		get_tree().call_group("enemies", "queue_free")
		game_over.emit()

func retry_wave():
	# 重试波次：完全恢复核心血量（包括基础血量+单位加成）
	core_health = max_core_health

	# Clear enemies
	get_tree().call_group("enemies", "queue_free")

	# Reset state
	is_wave_active = false

	# Notify systems that wave is reset (so they can re-enable UI etc)
	wave_reset.emit()

	# Update UI
	resource_changed.emit()

func recalculate_max_health():
	"""
	核心血量计算机制：
	max_core_health = BASE_CORE_HP(500) + 所有单位max_hp之和 + permanent_health_bonus

	开局时没有单位：max_core_health = 500, core_health = 500
	添加单位时：max_core_health增加该单位的hp，当前血量也同步增加
	移除单位时：max_core_health减少该单位的hp，当前血量也同步减少
	"""
	if !grid_manager: return

	var total_unit_hp = 0.0

	# 遍历所有格子统计单位血量
	var processed_units = {}
	for key in grid_manager.tiles:
		var tile = grid_manager.tiles[key]
		if tile.unit and not processed_units.has(tile.unit):
			total_unit_hp += tile.unit.max_hp
			processed_units[tile.unit] = true

	var old_max = max_core_health
	# 计算公式：基础血量 + 单位血量总和 + 永久加成
	max_core_health = Constants.BASE_CORE_HP + total_unit_hp + permanent_health_bonus

	if max_core_health != old_max:
		var diff = max_core_health - old_max
		# 血量变化时，当前血量同步调整（保持血量比例或简单加减）
		core_health += diff
		if core_health > max_core_health:
			core_health = max_core_health
		if core_health <= 0:
			core_health = 0
			# 如果移除单位导致血量归零，游戏结束
			game_over.emit()

		resource_changed.emit()

func _on_sacrifice_state_changed(is_active: bool):
	if is_active:
		damage_core(core_health * 0.1)
		damage_multiplier *= 2.0
	else:
		damage_multiplier /= 2.0
	resource_changed.emit()

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		resource_changed.emit()
		return true
	return false

func add_gold(amount: int):
	gold += amount
	resource_changed.emit()

func activate_cheat():
	gold += 1000
	mana = max_mana

	resource_changed.emit()
func check_resource(type: String, amount: float) -> bool:
	if type == "mana":
		return mana >= amount
	return true

func consume_resource(type: String, amount: float) -> bool:
	if cheat_infinite_resources:
		return true

	if !check_resource(type, amount): return false

	if type == "mana":
		mana -= amount

	resource_changed.emit()
	return true

func add_resource(type: String, amount: float):
	if type == "mana":
		mana = min(max_mana, mana + amount)
	elif type == "gold":
		gold += int(amount)

	resource_changed.emit()

func trigger_impact(direction: Vector2, strength: float):
	if main_game:
		# Shake camera via MainGame
		main_game.apply_impulse_shake(direction, strength * 5.0)

	# Notify environment
	world_impact.emit(direction, strength)

func spawn_floating_text(pos: Vector2, value: String, type_or_color: Variant, direction: Vector2 = Vector2.ZERO):
	var color = Color.WHITE

	if typeof(type_or_color) == TYPE_COLOR:
		color = type_or_color
	elif typeof(type_or_color) == TYPE_STRING:
		match type_or_color:
			"physical": color = Color.WHITE
			"fire": color = Color.ORANGE
			"poison": color = Color.GREEN
			"lightning": color = Color.PURPLE
			"magic": color = Color.BLUE
			"crit": color = Color(1, 0.8, 0.2)
			"eagle_crit": color = Color(0.8, 0.5, 0.0)
			_: color = Color.WHITE

	ftext_spawn_requested.emit(pos, value, color, direction)

func execute_skill_effect(source_key: String, target_pos: Vector2i) -> bool:
	if !grid_manager: return false

	match source_key:
		"viper":
			grid_manager.spawn_trap_custom(target_pos, "poison")
			return true
		"scorpion":
			grid_manager.spawn_trap_custom(target_pos, "fang")
			return true
		"phoenix":
			var world_pos = Vector2.ZERO
			var key = grid_manager.get_tile_key(target_pos.x, target_pos.y)
			if grid_manager.tiles.has(key):
				world_pos = grid_manager.tiles[key].global_position
			else:
				# Fallback if tile not found (e.g. valid coord but no tile instance?)
				# Convert local grid pos to global assuming grid_manager is at (0,0) or transforming
				var local_pos = Vector2(target_pos.x * Constants.TILE_SIZE, target_pos.y * Constants.TILE_SIZE)
				world_pos = grid_manager.to_global(local_pos)

			var dmg = 15.0
			if Constants.UNIT_TYPES.has("phoenix"):
				dmg = Constants.UNIT_TYPES["phoenix"].get("damage", 30.0) * 0.5

			if combat_manager:
				combat_manager.start_meteor_shower(world_pos, dmg)
			return true
	return false
