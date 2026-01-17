extends Node

const DefaultBehaviorScript = preload("res://src/Scripts/Enemies/Behaviors/DefaultBehavior.gd")
const MutantSlimeBehaviorScript = preload("res://src/Scripts/Enemies/Behaviors/MutantSlimeBehavior.gd")
const BossBehaviorScript = preload("res://src/Scripts/Enemies/Behaviors/BossBehavior.gd")
const SuicideBehaviorScript = preload("res://src/Scripts/Enemies/Behaviors/SuicideBehavior.gd")

func _ready():
	print("Starting TestEnemyRefactor...")
	test_behavior_assignment()
	print("TestEnemyRefactor Completed.")
	get_tree().quit()

func test_behavior_assignment():
	# Ensure data is loaded
	if Constants.ENEMY_VARIANTS.is_empty():
		print("Loading data manually...")
		var dm = DataManager.new()
		dm.load_data()

	var script = load("res://src/Scripts/Enemy.gd")

	var checks = [
		{"key": "slime", "expected": DefaultBehaviorScript},
		{"key": "mutant_slime", "expected": MutantSlimeBehaviorScript},
		{"key": "boss", "expected": BossBehaviorScript},
		{"key": "tank", "expected": BossBehaviorScript},
		{"key": "summoner", "expected": BossBehaviorScript},
		{"key": "bullet_entity", "expected": SuicideBehaviorScript},
		{"key": "minion", "expected": DefaultBehaviorScript}
	]

	for check in checks:
		var enemy = CharacterBody2D.new()
		enemy.set_script(script)

		enemy.setup(check.key, 1)

		var b_class = null
		if enemy.behavior:
			# Get script from object
			var sc = enemy.behavior.get_script()
			b_class = sc

		if b_class == check.expected:
			print("PASS: %s -> %s" % [check.key, b_class.resource_path.get_file()])
		else:
			print("FAIL: %s -> Expected %s, Got %s" % [check.key, check.expected.resource_path.get_file(), b_class.resource_path.get_file() if b_class else "None"])

		enemy.free()
