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
signal ftext_spawn_requested(pos, value, color)
signal show_tooltip(data, stats, buffs, pos)
signal hide_tooltip()

var core_type: String = "cornucopia"
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

# Stub for inventory manager (Mock/Future implementation)
var inventory_manager = null

var permanent_health_bonus: float = 0.0
var inventory_manager = null

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

func _process(delta):
	if is_wave_active and core_health > 0:
		update_resources(delta)

func update_resources(delta):
	if food < max_food:
		food = min(max_food, food + base_food_rate * delta)
	if mana < max_mana:
		mana = min(max_mana, mana + base_mana_rate * delta)
	resource_changed.emit()

func start_wave():
	if is_wave_active: return
	is_wave_active = true
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
	if amount > 0 and reward_manager and "biomass_armor" in reward_manager.acquired_artifacts:
		amount = min(amount, max_core_health * 0.05)

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

func spawn_floating_text(pos: Vector2, value: String, type_or_color: Variant):
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

	ftext_spawn_requested.emit(pos, value, color)

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
			var firestorm_scene = load("res://src/Scenes/Game/FireStorm.tscn")
			if firestorm_scene:
				var storm = firestorm_scene.instantiate()
				storm.position = Vector2(target_pos.x * Constants.TILE_SIZE, target_pos.y * Constants.TILE_SIZE)

				# Default damage calculation or fixed value
				var dmg = 10.0
				if Constants.UNIT_TYPES.has("phoenix"):
					dmg = Constants.UNIT_TYPES["phoenix"].get("damage", 20.0) * 0.5

				if storm.has_method("init"):
					storm.init(dmg)

				grid_manager.add_child(storm)
				return true
	return false
