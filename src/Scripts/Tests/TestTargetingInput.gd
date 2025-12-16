extends Node2D

var passed = true

func _ready():
	print("Starting Interaction Logic Verification...")
	test_targeting_flow()

	if passed:
		print("Interaction Logic Verification Passed")
	else:
		print("Interaction Logic Verification Failed")

func test_targeting_flow():
	print("  Testing Targeting Flow...")

	# Instantiate MainGame
	var main_game_script = load("res://src/Scripts/MainGame.gd")
	var main_game = main_game_script.new()
	main_game.name = "MainGame"

	# Mock dependencies as children for @onready
	var gm_mock = Node2D.new()
	gm_mock.name = "GridManager"
	gm_mock.set_script(load("res://src/Scripts/GridManager.gd"))
	main_game.add_child(gm_mock)

	var cm_mock = Node2D.new()
	cm_mock.name = "CombatManager"
	main_game.add_child(cm_mock)

	# Mock Camera
	var camera = Camera2D.new()
	camera.name = "Camera2D"
	main_game.add_child(camera)

	# Mock CanvasLayer/MainGUI/Shop
	var canvas = CanvasLayer.new()
	canvas.name = "CanvasLayer"
	main_game.add_child(canvas)

	var gui = Control.new()
	gui.name = "MainGUI"
	canvas.add_child(gui)

	var shop = Control.new()
	shop.name = "Shop"
	canvas.add_child(shop)

	var bg = Sprite2D.new()
	bg.name = "Background"
	# Create dummy texture
	var img = Image.create(100, 100, false, Image.FORMAT_RGBA8)
	bg.texture = ImageTexture.create_from_image(img)
	main_game.add_child(bg)

	# Set GameManager.main_game manually
	GameManager.main_game = main_game

	add_child(main_game)

	# Create a mock Unit
	var unit = load("res://src/Scripts/Unit.gd").new()
	unit.unit_data = {
		"skill": "firestorm",
		"targetType": "ground",
		"size": Vector2(1,1),
		"icon": "T"
	}
	main_game.add_child(unit) # Add to tree so _ready runs and connects signals

	# Wait for ready
	await get_tree().process_frame

	# 1. Simulate Request
	print("    Simulating request_targeting...")
	unit.request_targeting.emit(unit)

	if main_game.is_targeting == true:
		print("    [PASS] Entered targeting mode.")
	else:
		print("    [FAIL] Did not enter targeting mode.")
		passed = false

	if main_game.target_indicator.visible == true:
		print("    [PASS] Target indicator visible.")
	else:
		print("    [FAIL] Target indicator NOT visible.")
		passed = false

	# 2. Simulate Input (Left Click)
	print("    Simulating Left Click...")

	# We can't easily emit InputEvent to MainGame._unhandled_input directly via code unless we call it.
	var click_event = InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	click_event.position = Vector2(100, 100) # Grid ~ (2, 2) roughly

	# Mock unit.cast_target_skill to verify call
	# Since we can't easily mock methods on existing instance in GDScript without libraries,
	# we will check if targeting mode exited, which happens after cast.
	# But cast_target_skill in Unit is real. It will try to spawn Firestorm.
	# That's fine, we just check if state reset.

	main_game._unhandled_input(click_event)

	if main_game.is_targeting == false:
		print("    [PASS] Exited targeting mode after click.")
	else:
		print("    [FAIL] Did not exit targeting mode.")
		passed = false

	# 3. Simulate Request & Cancel (Right Click)
	print("    Simulating Right Click Cancel...")
	unit.request_targeting.emit(unit)

	if main_game.is_targeting:
		var cancel_event = InputEventMouseButton.new()
		cancel_event.button_index = MOUSE_BUTTON_RIGHT
		cancel_event.pressed = true

		main_game._unhandled_input(cancel_event)

		if main_game.is_targeting == false:
			print("    [PASS] Cancelled targeting mode.")
		else:
			print("    [FAIL] Failed to cancel targeting.")
			passed = false
	else:
		print("    [FAIL] Failed to re-enter targeting.")
		passed = false

	main_game.queue_free()
