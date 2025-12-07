extends Node2D

func _ready():
	print("Starting TestBuildPanel...")

	# Load MainGame scene
	var game_scene = load("res://src/Scenes/Game/MainGame.tscn").instantiate()
	add_child(game_scene)

	# Allow _ready to run
	await get_tree().process_frame

	var main_gui = game_scene.get_node("CanvasLayer/MainGUI")
	var draw_manager = game_scene.get_node("DrawManager")

	if not main_gui:
		print("Error: MainGUI not found")
		get_tree().quit(1)
		return

	if not draw_manager:
		print("Error: DrawManager not found")
		get_tree().quit(1)
		return

	# Find BuildPanel
	var build_panel = null
	for child in main_gui.get_children():
		if child.name.begins_with("BuildPanel") or child.has_method("_on_material_clicked"):
			build_panel = child
			break

	if not build_panel:
		print("Error: BuildPanel not found in MainGUI")
		get_tree().quit(1)
		return

	print("BuildPanel found.")

	# Give some materials to test
	GameManager.materials["wood"] = 10

	# Find wood button
	var wood_btn = build_panel.buttons.get("wood")
	if not wood_btn:
		print("Error: Wood button not found")
		get_tree().quit(1)
		return

	print("Clicking wood button...")
	wood_btn.pressed.emit()

	if draw_manager.current_material == "wood":
		print("Success: DrawManager material set to wood")
	else:
		print("Failure: DrawManager material is ", draw_manager.current_material)
		get_tree().quit(1)
		return

	print("Clicking wood button again (toggle off)...")
	wood_btn.pressed.emit()

	if draw_manager.current_material == "":
		print("Success: DrawManager material cleared")
	else:
		print("Failure: DrawManager material is ", draw_manager.current_material)
		get_tree().quit(1)
		return

	print("All tests passed.")
	get_tree().quit(0)
