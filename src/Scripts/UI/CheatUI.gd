extends CanvasLayer

func _ready():
	# Setup Unit Spawning Buttons
	var grid_container = $Panel/VBoxContainer/ScrollContainer/GridContainer
	if grid_container:
		for unit_key in Constants.UNIT_TYPES:
			var btn = Button.new()
			btn.text = unit_key
			# Use a callable to bind the argument
			btn.pressed.connect(_on_unit_button_pressed.bind(unit_key))
			grid_container.add_child(btn)
	else:
		printerr("GridContainer not found in CheatUI")

	# Connect signals for static buttons
	var hbox = $Panel/VBoxContainer/HBoxContainer
	if hbox:
		var btn_add = hbox.get_node("BtnAddResources")
		if btn_add: btn_add.pressed.connect(_on_add_resources_pressed)

		var btn_skip = hbox.get_node("BtnSkipWave")
		if btn_skip: btn_skip.pressed.connect(_on_skip_wave_pressed)

		var btn_god = hbox.get_node("BtnGodMode")
		if btn_god: btn_god.pressed.connect(_on_god_mode_pressed)

		var btn_close = hbox.get_node("BtnClose")
		if btn_close: btn_close.pressed.connect(_on_close_pressed)

	# Automated Verification
	# We run this check immediately if we are in a debug build or always as requested.
	# The prompt asks to add code to simulate click and assert.
	call_deferred("_test_god_mode")

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_QUOTELEFT:
		_on_close_pressed()

func _on_add_resources_pressed():
	GameManager.activate_cheat()

func _on_skip_wave_pressed():
	if GameManager.is_wave_active:
		get_tree().call_group("enemies", "queue_free")
		GameManager.end_wave()

func _on_god_mode_pressed():
	GameManager.max_core_health = 999999
	GameManager.core_health = 999999
	GameManager.resource_changed.emit()

func _on_unit_button_pressed(unit_key):
	if GameManager.main_game:
		GameManager.main_game.add_to_bench(unit_key)
	else:
		print("MainGame not active. Cannot add unit: " + unit_key)

func _on_close_pressed():
	queue_free()

func _test_god_mode():
	# Simulate God Mode click
	_on_god_mode_pressed()

	if GameManager.core_health >= 999999:
		print("[TEST] God Mode Applied Successfully")
	else:
		printerr("[TEST] God Mode Failed. Core Health: ", GameManager.core_health)
