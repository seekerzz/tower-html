extends Control

@onready var hp_bar = $Panel/VBoxContainer/HPBar
@onready var food_bar = $Panel/VBoxContainer/FoodBar
@onready var mana_bar = $Panel/VBoxContainer/ManaBar
@onready var wave_label = $Panel/WaveLabel

func _ready():
	GameManager.resource_changed.connect(update_ui)
	GameManager.wave_started.connect(update_ui)
	GameManager.wave_ended.connect(update_ui)
	update_ui()

func update_ui():
	hp_bar.value = (GameManager.core_health / GameManager.max_core_health) * 100
	food_bar.value = (GameManager.food / GameManager.max_food) * 100
	mana_bar.value = (GameManager.mana / GameManager.max_mana) * 100

	wave_label.text = "Wave %d" % GameManager.wave
