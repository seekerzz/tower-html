extends Node2D

var tiger_unit
var enemy_scene = preload("res://src/Scenes/Game/Enemy.tscn")
var time_elapsed = 0.0
var test_finished = false
var unique_meteors = {}

func _ready():
	print("Starting TestTigerSkill...")
	_setup_test_environment()

	# Activating skill
	print("Activating skill...")
	tiger_unit.activate_skill()

func _process(delta):
	if test_finished: return

	time_elapsed += delta

	# Track meteors every frame
	if GameManager.combat_manager:
		for child in GameManager.combat_manager.get_children():
			if child.get("is_meteor_falling") == true:
				unique_meteors[child] = true

	if time_elapsed >= 1.0: # 1.0s is enough to spawn ~5. Checking accumulation.
		test_finished = true
		_verify_results()
		print("Test Completed.")
		get_tree().quit()

func _setup_test_environment():
	# Configure GameManager resources
	GameManager.mana = 9999
	GameManager.food = 9999
	GameManager.is_wave_active = true

	# Instantiate CombatManager if missing
	if !GameManager.combat_manager:
		var cm_script = load("res://src/Scripts/CombatManager.gd")
		var cm = cm_script.new()
		add_child(cm)

	# Create Tiger Unit
	var unit_scene = load("res://src/Scenes/Game/Unit.tscn")
	tiger_unit = unit_scene.instantiate()
	add_child(tiger_unit)
	tiger_unit.setup("tiger")
	tiger_unit.global_position = Vector2.ZERO

	# Spawn Enemies
	for i in range(3):
		var enemy = enemy_scene.instantiate()
		enemy.setup("slime", 1)
		add_child(enemy)
		enemy.add_to_group("enemies")
		enemy.global_position = Vector2(randf_range(100, 200), randf_range(-50, 50))

func _verify_results():
	# 1. Verify skill timer
	if tiger_unit.skill_active_timer > 0:
		print("PASS: Skill active timer is running (", tiger_unit.skill_active_timer, ")")
	else:
		print("FAIL: Skill active timer is 0")

	# 2. Verify projectiles
	var meteor_count = unique_meteors.size()
	print("Found unique meteors: ", meteor_count)

	if meteor_count >= 4:
		print("PASS: Created ", meteor_count, " meteors (Expected >= 4)")
	else:
		print("FAIL: Created ", meteor_count, " meteors (Expected >= 4)")
