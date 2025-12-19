extends Control

@onready var unit_option = $PanelContainer/VBoxContainer/HBoxContainer/OptionButton

func _ready():
	visible = false
	# Ensure process mode is always so it works when paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	_populate_units()

func _populate_units():
	if not unit_option: return
	unit_option.clear()

	# Iterate over UNIT_TYPES from Constants
	for key in Constants.UNIT_TYPES:
		unit_option.add_item(key)

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_QUOTELEFT:
		visible = !visible
		get_tree().paused = visible
		print("[CheatMenu] Toggled visibility: ", visible)

func _on_add_gold_pressed():
	GameManager.add_gold(1000)

func _on_skip_wave_pressed():
	if GameManager.main_game and GameManager.main_game.has_method("skip_wave"):
		GameManager.main_game.skip_wave()

func _on_set_hp_pressed():
	GameManager.max_core_health = 999999
	GameManager.core_health = 999999
	GameManager.resource_changed.emit()

func _on_spawn_unit_pressed():
	if unit_option.selected == -1: return
	var unit_key = unit_option.get_item_text(unit_option.selected)

	if GameManager.main_game:
		# Try to add to bench
		var success = GameManager.main_game.add_to_bench(unit_key)
		if success:
			print("Spawned unit: ", unit_key)
		else:
			print("Failed to spawn unit (Bench full?)")
