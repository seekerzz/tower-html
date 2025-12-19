extends CanvasLayer

@onready var container = $Control/PanelContainer/VBoxContainer
@onready var unit_option = $Control/PanelContainer/VBoxContainer/HBoxContainer/OptionButton

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS # Ensure it runs when paused

	# Populate units
	if not Constants.UNIT_TYPES.is_empty():
		for unit_id in Constants.UNIT_TYPES.keys():
			unit_option.add_item(unit_id)
	else:
		print("[CheatMenu] Warning: Constants.UNIT_TYPES is empty.")

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_QUOTELEFT:
		visible = !visible
		get_tree().paused = visible
		print("[CheatMenu] Toggled visibility: ", visible)

		# If we just became visible, maybe refresh unit list if it was empty?
		if visible and unit_option.item_count == 0 and not Constants.UNIT_TYPES.is_empty():
			for unit_id in Constants.UNIT_TYPES.keys():
				unit_option.add_item(unit_id)

func _on_add_gold_pressed():
	GameManager.add_gold(1000)

func _on_skip_wave_pressed():
	if GameManager.is_wave_active:
		# Kill all enemies
		get_tree().call_group("enemies", "queue_free")

		# Reset spawn counter
		if GameManager.combat_manager:
			GameManager.combat_manager.enemies_to_spawn = 0

		# End wave
		GameManager.end_wave()

func _on_set_hp_pressed():
	var new_hp = 999999.0
	GameManager.max_core_health = new_hp
	GameManager.core_health = new_hp
	GameManager.resource_changed.emit()

func _on_spawn_unit_pressed():
	var idx = unit_option.selected
	if idx == -1: return
	var unit_id = unit_option.get_item_text(idx)

	if GameManager.main_game:
		GameManager.main_game.add_to_bench(unit_id)
