extends Node

signal resource_changed
signal wave_started
signal wave_ended
signal game_over
signal unit_purchased(unit_data)
signal unit_sold(amount)
signal damage_dealt(unit, amount)
signal ftext_spawn_requested(pos, value, color)

var core_type: String = "cornucopia"
var food: float = 100.0
var max_food: float = 200.0
var mana: float = 50.0
var max_mana: float = 100.0
var gold: int = 150
var wave: int = 1
var is_wave_active: bool = false
var core_health: float = 100.0
var max_core_health: float = 100.0

var base_food_rate: float = 5.0
var base_mana_rate: float = 1.0

var materials: Dictionary = {
	"mucus": 0, "poison": 0, "fang": 0,
	"wood": 0, "snow": 0, "stone": 0
}

var tile_cost: int = 50

# Global references
var grid_manager = null
var combat_manager = null
var ui_manager = null
var main_game = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

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
	wave += 1
	gold += 20 + (wave * 5)

	# Restore resources
	food = max_food
	mana = max_mana

	wave_ended.emit()
	resource_changed.emit()

func damage_core(amount: float):
	core_health -= amount
	resource_changed.emit()
	if core_health <= 0:
		core_health = 0
		game_over.emit()

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

func spawn_floating_text(pos: Vector2, value: String, color: Color):
	ftext_spawn_requested.emit(pos, value, color)
