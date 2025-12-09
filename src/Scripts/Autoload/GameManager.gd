extends Node

var gold: int = 100
var core_health: int = 100
var max_core_health: int = 100
var wave: int = 1
var materials: Dictionary = {"wood": 0, "stone": 0}
var food: int = 0
var max_food: int = 10
var mana: int = 0
var max_mana: int = 10

var base_food_rate: int = 1
var base_mana_rate: int = 1

var grid_manager = null
var main_game = null
var combat_manager = null
var is_wave_active: bool = false
var ui_manager = null

signal wave_started
signal wave_ended
signal resource_changed
signal unit_purchased
signal unit_sold
signal damage_dealt
signal ftext_spawn_requested
signal show_tooltip
signal hide_tooltip

func _ready():
	pass

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		resource_changed.emit()
		return true
	return false

func add_gold(amount: int):
	gold += amount
	resource_changed.emit()
