extends Node

signal resource_changed
signal wave_started
signal wave_ended
signal game_over
signal unit_purchased(unit_data)
signal unit_sold(amount)
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
var extra_max_health: float = 0.0

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
var combat_manager = null
var ui_manager = null
var main_game = null
var reward_manager = null
var gold_multiplier: float = 1.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	var rm_script = load("res://src/Scripts/Managers/RewardManager.gd")
	if rm_script:
		reward_manager = rm_script.new()
		add_child(reward_manager)

func connect_sacrifice_signal(gui_node):
	if gui_node.has_signal("sacrifice_requested"):
		if !gui_node.sacrifice_requested.is_connected(_on_sacrifice_requested):
			gui_node.sacrifice_requested.connect(_on_sacrifice_requested)

func _on_sacrifice_requested():
	# Deduct 10% HP
	var damage = core_health * 0.1
	damage_core(damage)

	# Increase damage multiplier
	damage_multiplier *= 2.0

	# Start timer to revert
	var timer = get_tree().create_timer(10.0)
	timer.timeout.connect(func(): damage_multiplier /= 2.0)

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
	var final_amount = amount
	if reward_manager and reward_manager.has_artifact("biomass"):
		var cap = max_core_health * 0.05
		if final_amount > cap:
			final_amount = cap

	core_health -= final_amount
	resource_changed.emit()
	if core_health <= 0:
		core_health = 0
		game_over.emit()

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
	# We need to preserve bonus health.
	# Current implementation logic in `recalculate_max_health` resets max_core_health to BASE + Units.
	# If we want to support `bonus` from Rapid Expansion, we need to store it.
	# But I haven't added a `bonus_health` variable.
	# A workaround is to check the difference and see if it's from expansion? No.
	# Proper way: Add `bonus_max_health` variable.
	# However, since I am in `recalculate_max_health`, I can try to infer or just add a variable now.
	# Let's add `bonus_max_health` variable at top of file, but this is a diff.
	# I will just rely on `max_core_health` being correct *until* this function runs.
	# If this function runs, it resets it.
	# So I MUST add `var extra_max_health = 0.0` to GameManager.
	# But I can't add a variable easily in the middle of a file with search/replace unless I target the top.
	# I'll just change the calculation to:
	# max_core_health = Constants.BASE_CORE_HP + total_unit_hp + extra_max_health
	# But `extra_max_health` needs to be defined.
	# I will add the variable and the calculation in one go if I can target the top again?
	# Or I can just abuse `max_core_health` itself?
	# `max_core_health = max_core_health - (old_base + old_unit) + (new_base + new_unit)`?
	# Too risky.
	# I'll assume for this task that unit placement won't happen immediately during the test, OR I'll add the variable properly.
	# Let's add the variable properly.

	max_core_health = Constants.BASE_CORE_HP + total_unit_hp
	if self.get("extra_max_health"):
		max_core_health += self.extra_max_health

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
	# War Bonds
	if reward_manager and reward_manager.has_artifact("war_bonds"):
		# Assuming gold_multiplier is already handled or we apply it here?
		# The task says: "Increase gold_multiplier variable, affect gold acquisition"
		# I added gold_multiplier variable. I should apply it here.
		# Note: The artifact might increase the multiplier itself, or I check artifact here?
		# Task says: "Implement mechanism - War Bonds: Increase gold_multiplier variable".
		# This could mean the artifact *sets* the multiplier, or simply having it enables the multiplier?
		# "Increase gold_multiplier variable" usually means `gold_multiplier += X`.
		# Let's assume if we have the artifact, we increase the multiplier (maybe in _ready or when acquired).
		# BUT, since artifact acquisition is dynamic, checking it here is safer if it's a static bonus.
		# "Increase gold_multiplier variable, affect gold acquisition".
		# Let's assume the base multiplier is 1.0. If we have War Bonds, maybe it's higher?
		# Or maybe I should just check the variable `gold_multiplier`.
		# And *somewhere* I should increase `gold_multiplier` if I have the artifact?
		# Or maybe checking the artifact *is* the condition to apply a boost?
		# Let's assume the standard way: `amount * gold_multiplier`.
		# And if we have "war_bonds", `gold_multiplier` should be higher.
		# I will simply apply `gold_multiplier` here.
		# And I will ensure `gold_multiplier` reflects the artifact state or just apply logic here.
		# Task: "Increase gold_multiplier variable".
		# I'll check the artifact in `add_gold` or `_process`?
		# Let's just apply `gold_multiplier` in `add_gold`.
		# And I'll add logic to set `gold_multiplier`?
		# Actually, maybe the task means "Add `gold_multiplier` variable. Modifiy `add_gold` to use it. And War Bonds increases it."
		# I'll modify `add_gold` to use `gold_multiplier`.
		# And I'll add a check: if has "war_bonds", `gold_multiplier` should be higher?
		# Let's simply: `gold += int(amount * gold_multiplier)`.
		# And I will update `gold_multiplier` if `war_bonds` is present (maybe in `_process` or just check here).
		# To be safe and stateless:
		pass

	var multiplier = gold_multiplier
	if reward_manager and reward_manager.has_artifact("war_bonds"):
		multiplier += 0.5

	gold += int(amount * multiplier)
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
