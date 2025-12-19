extends CanvasLayer

@onready var unit_container = $Panel/VBoxContainer/ScrollContainer/GridContainer

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_signals()
	_populate_unit_buttons()

	# Automated Verification Logic
	call_deferred("_run_verification")

func _setup_signals():
	# These will be connected in the editor or via code if nodes are named predictably
	# For robustness, let's assume we connect them here if we can find them,
	# but since we are creating the scene later, we will rely on node paths.

	var btn_resources = $Panel/VBoxContainer/HBoxContainer/BtnResources
	var btn_skip = $Panel/VBoxContainer/HBoxContainer/BtnSkip
	var btn_god = $Panel/VBoxContainer/HBoxContainer/BtnGod
	var btn_close = $Panel/VBoxContainer/HBoxContainer/BtnClose

	btn_resources.pressed.connect(_on_add_resources_pressed)
	btn_skip.pressed.connect(_on_skip_wave_pressed)
	btn_god.pressed.connect(_on_god_mode_pressed)
	btn_close.pressed.connect(_on_close_pressed)

func _populate_unit_buttons():
	for unit_key in Constants.UNIT_TYPES:
		var btn = Button.new()
		btn.text = unit_key
		btn.custom_minimum_size = Vector2(80, 40)
		btn.pressed.connect(_on_unit_button_pressed.bind(unit_key))
		unit_container.add_child(btn)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_QUOTELEFT:
			_on_close_pressed()

func _on_add_resources_pressed():
	GameManager.activate_cheat()
	print("Resources added via CheatUI")

func _on_skip_wave_pressed():
	if GameManager.is_wave_active:
		get_tree().call_group("enemies", "queue_free")
		GameManager.end_wave()
		print("Wave skipped via CheatUI")
	else:
		print("No active wave to skip")

func _on_god_mode_pressed():
	GameManager.max_core_health = 999999
	GameManager.core_health = 999999
	GameManager.resource_changed.emit()
	print("God Mode activated via CheatUI")

func _on_unit_button_pressed(unit_key):
	if GameManager.main_game:
		var success = GameManager.main_game.add_to_bench(unit_key)
		if success:
			print("Added unit to bench: ", unit_key)
		else:
			print("Failed to add unit (Bench full?)")
	else:
		print("MainGame not found (Running standalone?)")

func _on_close_pressed():
	queue_free()

func _run_verification():
	# Verification: Simulate God Mode click and check health
	_on_god_mode_pressed()

	if GameManager.core_health >= 999999:
		print("[TEST] God Mode Applied Successfully")
	else:
		push_error("[TEST] God Mode Failed! Health: " + str(GameManager.core_health))
