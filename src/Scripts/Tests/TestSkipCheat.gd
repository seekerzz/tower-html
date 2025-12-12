extends Node

func _ready():
	print("Starting TestSkipCheat...")

	# 1. Instantiate MainGUI
	var main_gui_scene = load("res://src/Scenes/UI/MainGUI.tscn")
	var main_gui = main_gui_scene.instantiate()
	add_child(main_gui)

	# Mock CombatManager
	var combat_manager = Node.new()
	var cm_script = GDScript.new()
	cm_script.source_code = """
extends Node
var enemies_to_spawn = 5
var total_enemies_for_wave = 10
"""
	cm_script.reload()
	combat_manager.set_script(cm_script)
	add_child(combat_manager)

	GameManager.combat_manager = combat_manager

	# 2. Set wave active
	GameManager.is_wave_active = true

	# 3. Simulate Enemy
	var enemy = Node.new()
	enemy.add_to_group("enemies")
	add_child(enemy)

	# Verify setup
	if not GameManager.is_wave_active:
		push_error("Setup failed: Wave should be active")
		return

	if get_tree().get_nodes_in_group("enemies").size() == 0:
		push_error("Setup failed: There should be enemies")
		return

	# 4. Action
	print("Pressing Skip Button...")
	main_gui._on_skip_button_pressed()

	# 5. Assertions
	# Wait a bit for processing
	var timer = get_tree().create_timer(0.1)
	await timer.timeout

	if GameManager.is_wave_active == false:
		print("PASS: Wave ended")
	else:
		push_error("FAIL: Wave did not end")

	if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
		print("PASS: Enemy cleared")
	else:
		push_error("FAIL: Enemy still exists")

	if combat_manager.enemies_to_spawn == 0:
		print("PASS: Spawning stopped")
	else:
		push_error("FAIL: Spawning not stopped (enemies_to_spawn = %d)" % combat_manager.enemies_to_spawn)

	print("Test Complete")

	# Cleanup
	main_gui.queue_free()
	combat_manager.queue_free()
	if is_instance_valid(enemy): enemy.queue_free()

	# Quit if running standalone (how to detect? Maybe just print done)
	if get_tree().root == self:
		get_tree().quit()
