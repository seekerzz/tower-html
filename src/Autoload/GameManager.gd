extends Node

signal resource_changed
signal wave_started
signal wave_ended
signal wave_reset
signal game_over
signal unit_purchased(unit_data)
signal unit_sold(amount)
signal skill_activated(unit)
signal damage_dealt(unit, amount)
signal ftext_spawn_requested(pos, value, color, direction)
signal show_tooltip(data, stats, buffs, pos)
signal hide_tooltip()

var core_type: String = "abundance"
var moonwell_pool: float = 0.0

var food: float = 1000.0
var max_food: float = 2000.0
var mana: float = 500.0
var max_mana: float = 1000.0
var gold: int = 150
var wave: int = 1
var is_wave_active: bool = false
var core_health: float = 1000.0
var max_core_health: float = 1000.0
var damage_multiplier: float = 1.0

var base_food_rate: float = 50.0
var base_mana_rate: float = 10.0

var materials: Dictionary = {
	"mucus": 0, "poison": 0, "fang": 0,
	"wood": 0, "snow": 0, "stone": 0
}

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


var permanent_health_bonus: float = 0.0

# Relic Logic
var indomitable_triggered: bool = false
var indomitable_timer: float = 0.0

# Cheat Flags
var cheat_god_mode: bool = false
var cheat_infinite_resources: bool = false
var cheat_fast_cooldown: bool = false

var _hit_stop_end_time: int = 0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

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

	# Connect damage_dealt for Moon Well
	damage_dealt.connect(_on_damage_dealt)

func _on_damage_dealt(_unit, amount):
	if core_type == "moon_well":
		moonwell_pool += amount * 0.1

func use_item(item_data: Dictionary) -> void:
	var item_id = item_data.get("item_id")
	if not item_id: return

	# Fetch effect from data_manager if possible, or just hardcode for now based on item_id
	var item_def = data_manager.get_data("ITEM_TYPES").get(item_id, {})
	var effect = item_def.get("effect")

	var consumed = false

	match effect:
		"restore_food_50pct":
			food = min(max_food, food + max_food * 0.5)
			resource_changed.emit()
			consumed = true
		"moon_well_heal":
			var heal_amount = min(moonwell_pool, max_core_health - core_health)
			if heal_amount > 0:
				core_health += heal_amount
				moonwell_pool -= heal_amount

			# Overflow to Mana
			if moonwell_pool > 0:
				var mana_gain = moonwell_pool * 0.01
				mana = min(max_mana, mana + mana_gain)
				moonwell_pool = 0

			resource_changed.emit()
			consumed = true
		"crit_buff_3":
			# Effect applied via ItemDropLayer drag-drop logic.
			# We just need to mark as consumed here.
			consumed = true
		_:
			# Potentially handled by drag drop, but if right clicked:
			print("Item used: ", item_id)

	if consumed:
		# Remove 1 from inventory
		# We need to find index in inventory manager... but inventory manager expects index.
		# Ideally InventoryManager should have remove_by_data or something, but we can iterate.
		# Or better, we should probably pass the index from the slot if possible.
		# But since we just have item_data here, let's find it.

		# NOTE: item_data passed here is a reference to the dict in the array?
		# If so, we can find it by reference or matching content.
		# But since InventoryManager.items is the source of truth, let's assume item_data is one of the elements.

		var items = inventory_manager.items
		var index = items.find(item_data)
		if index != -1:
			inventory_manager.remove_item(index)

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

	return modifier

func update_resources(delta):
	if food < max_food:
		food = min(max_food, food + base_food_rate * delta)
	if mana < max_mana:
		mana = min(max_mana, mana + base_mana_rate * delta)
	resource_changed.emit()

func start_wave():
	if is_wave_active: return
	is_wave_active = true
	indomitable_triggered = false

	distribute_wave_item()

	wave_started.emit()

func distribute_wave_item():
	if inventory_manager and data_manager:
		var core_def = data_manager.get_data("CORE_TYPES").get(core_type)
		if core_def and core_def.has("wave_item"):
			var item_id = core_def.wave_item
			# Check if we already have it
			var has_item = false
			for item in inventory_manager.items:
				if item.get("item_id") == item_id:
					has_item = true
					break

			if not has_item:
				inventory_manager.add_item({"item_id": item_id, "count": 1})

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
	gold += 20 + (wave * 5)

	# Restore resources
	food = max_food
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

func damage_core(amount: float):
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
	# Restore core health
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
	if !grid_manager: return

	var total_unit_hp = 0.0

	# Iterate all tiles to find units
	# grid_manager.tiles is Dictionary { key: Tile }
	# We can also keep a list of units in GridManager to be faster, but for now iterating tiles is safe.
	# Or better, GridManager should probably expose a way to get all units.
	# But since we are modifying GameManager, and GridManager is a child, we can access it.
	# However, GridManager.tiles is internal.

	# Let's rely on iterating tiles for now, or check if GridManager has a list.
	# Looking at GridManager.gd, it has `tiles`.

	var processed_units = {}
	for key in grid_manager.tiles:
		var tile = grid_manager.tiles[key]
		if tile.unit and not processed_units.has(tile.unit):
			total_unit_hp += tile.unit.max_hp
			processed_units[tile.unit] = true

	var old_max = max_core_health
	max_core_health = Constants.BASE_CORE_HP + total_unit_hp + permanent_health_bonus

	# Note: Biomass Armor (+500 HP) is applied in RewardManager._apply_immediate_effects.
	# If we add it here, we might need to ensure consistency.
	# Reviewer requested removal of explicit check here to match spec strictness.
	# if reward_manager and "biomass_armor" in reward_manager.acquired_artifacts:
	# 	max_core_health += 500.0

	if max_core_health != old_max:
		var diff = max_core_health - old_max
		# If max health increased, we heal the core by that amount (so current health % doesn't drop weirdly,
		# or rather, adding a unit adds its health to the pool immediately).
		# If max health decreased, we clamp current health.

		# Prompt says: "if current health exceeds max, clamp; if not injured, adjust proportionally or by difference.
		# To simplify, simply add the difference."

		core_health += diff
		if core_health > max_core_health:
			core_health = max_core_health
		if core_health <= 0:
			core_health = 0 # Should not happen unless removing unit kills us?
			# If removing a unit drops HP below 0, it means we die?
			game_over.emit()

		resource_changed.emit()

func _on_sacrifice_state_changed(is_active: bool):
	if is_active:
		damage_core(core_health * 0.1)
		damage_multiplier *= 2.0
	else:
		damage_multiplier /= 2.0
	resource_changed.emit()

func add_material(type: String, amount: int = 1):
	if materials.has(type):
		materials[type] += amount
		# signal material changed if needed

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
	food = max_food
	mana = max_mana

	for key in materials:
		materials[key] = 99

	resource_changed.emit()
func check_resource(type: String, amount: float) -> bool:
	if type == "food":
		return food >= amount
	elif type == "mana":
		return mana >= amount
	return true

func consume_resource(type: String, amount: float) -> bool:
	if cheat_infinite_resources:
		return true

	if !check_resource(type, amount): return false

	if type == "food":
		food -= amount
	elif type == "mana":
		mana -= amount

	resource_changed.emit()
	return true

func add_resource(type: String, amount: float):
	if type == "food":
		food = min(max_food, food + amount)
	elif type == "mana":
		mana = min(max_mana, mana + amount)
	elif type == "gold":
		gold += int(amount)

	resource_changed.emit()

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
