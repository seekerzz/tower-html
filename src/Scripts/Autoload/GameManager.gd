extends Node

var gold: int = 100
var grid_manager = null
var main_game = null
var combat_manager = null
var ui_manager = null

var is_wave_active: bool = false
var wave: int = 1

var core_health: float = 100.0
var max_core_health: float = 100.0

var food: float = 50.0
var max_food: float = 100.0
var base_food_rate: float = 5.0

var mana: float = 50.0
var max_mana: float = 100.0
var base_mana_rate: float = 2.0

var materials: Dictionary = {}

signal wave_started
signal wave_ended
signal resource_changed
signal damage_dealt(source, amount)
signal ftext_spawn_requested(pos, text, color)
signal show_tooltip(unit_data, stats, buffs, pos)
signal hide_tooltip
signal unit_purchased(unit)
signal unit_sold(unit)

func _ready():
	pass

func consume_resource(type: String, amount: float) -> bool:
	if type == "food":
		if food >= amount:
			food -= amount
			resource_changed.emit()
			return true
	elif type == "mana":
		if mana >= amount:
			mana -= amount
			resource_changed.emit()
			return true
	elif type == "gold":
		if gold >= amount:
			gold -= int(amount)
			resource_changed.emit()
			return true
	return false

func check_resource(type: String, amount: float) -> bool:
	if type == "food":
		return food >= amount
	elif type == "mana":
		return mana >= amount
	elif type == "gold":
		return gold >= amount
	return false

func add_resource(type: String, amount: float):
	if type == "food":
		food = min(food + amount, max_food)
	elif type == "mana":
		mana = min(mana + amount, max_mana)
	resource_changed.emit()

func add_gold(amount: int):
	gold += amount
	resource_changed.emit()

func spend_gold(amount: int):
	if gold >= amount:
		gold -= amount
		resource_changed.emit()

func spawn_floating_text(pos: Vector2, text: String, color: Color):
	ftext_spawn_requested.emit(pos, text, color)

func start_wave():
	is_wave_active = true
	wave_started.emit()

func end_wave():
	is_wave_active = false
	wave += 1
	wave_ended.emit()

func damage_core(amount: float):
	core_health = max(0, core_health - amount)
	resource_changed.emit()
	# TODO: Check game over

func add_material(type: String):
	if !materials.has(type):
		materials[type] = 0
	materials[type] += 1
	resource_changed.emit()

func activate_cheat():
	pass
