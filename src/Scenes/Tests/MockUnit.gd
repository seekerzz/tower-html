extends Node

var type_key = "viper"
var production_timer
var production_progress = 0.0

func _init(key):
	type_key = key
	production_timer = Timer.new()
	production_timer.wait_time = 2.0
	production_timer.one_shot = false
	add_child(production_timer)

func _ready():
	if production_timer.is_stopped():
		production_timer.start()

func get_production_progress():
	if production_timer.wait_time > 0:
		return 1.0 - (production_timer.time_left / production_timer.wait_time)
	return 0.0
