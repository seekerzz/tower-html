extends Node

signal resource_changed
signal wave_started
signal wave_ended
signal game_over
signal core_health_changed

var gold: int = 150
var food: float = 100.0
var max_food: float = 200.0
var mana: float = 50.0
var max_mana: float = 100.0
var wave: int = 1
var is_wave_active: bool = false
var core_health: float = 100.0
var max_core_health: float = 100.0
var base_food_rate: float = 5.0
var base_mana_rate: float = 1.0

var materials = {
	"mucus": 0,
	"poison": 0,
	"fang": 0,
	"wood": 0,
	"snow": 0,
	"stone": 0
}

var core_type: String = "cornucopia" # Default

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta):
	if core_health <= 0:
		return

	# Resource regeneration
	if food < max_food:
		food = min(max_food, food + base_food_rate * delta)
		emit_signal("resource_changed")

	if mana < max_mana:
		mana = min(max_mana, mana + base_mana_rate * delta)
		emit_signal("resource_changed")

func start_wave():
	if is_wave_active:
		return
	is_wave_active = true
	emit_signal("wave_started")

func end_wave():
	is_wave_active = false
	wave += 1
	gold += 20 + (wave * 5)

	# Restore resources
	food = max_food
	mana = max_mana

	emit_signal("wave_ended")
	emit_signal("resource_changed")

func damage_core(amount: float):
	core_health -= amount
	emit_signal("core_health_changed")
	if core_health <= 0:
		emit_signal("game_over")

func add_gold(amount: int):
	gold += amount
	emit_signal("resource_changed")

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		emit_signal("resource_changed")
		return true
	return false

func add_material(type: String, amount: int = 1):
	if type in materials:
		materials[type] += amount
		emit_signal("resource_changed")

func spend_material(type: String, amount: int) -> bool:
	if type in materials and materials[type] >= amount:
		materials[type] -= amount
		emit_signal("resource_changed")
		return true
	return false

func spend_food(amount: float) -> bool:
	if food >= amount:
		food -= amount
		emit_signal("resource_changed")
		return true
	return false

func spend_mana(amount: float) -> bool:
	if mana >= amount:
		mana -= amount
		emit_signal("resource_changed")
		return true
	return false

func reset_game():
	gold = 150
	food = 100
	max_food = 200
	mana = 50
	max_mana = 100
	wave = 1
	is_wave_active = false
	core_health = 100
	materials = {
		"mucus": 0, "poison": 0, "fang": 0, "wood": 0, "snow": 0, "stone": 0
	}
	emit_signal("resource_changed")
	emit_signal("core_health_changed")
