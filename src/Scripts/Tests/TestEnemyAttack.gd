extends Node2D

var enemy_script = load("res://src/Scripts/Enemy.gd")
var enemy: Area2D
var target: Node2D

func _ready():
	print("Running TestEnemyAttack...")

	# Mock GameManager and Constants because Enemy depends on them
	# Ideally we should use a proper test runner, but this is a manual test script per instructions.
	# We rely on the existing GameManager autoload if present, but since this is an isolated script,
	# we might need to be careful if it expects GameManager to be present in the tree.
	# The instructions say "run the game", so I assume this script is attached to a scene or run in a way that autoloads are present?
	# Or I should treat this as an integration test scene.

	# Create a dummy target
	target = Node2D.new()
	target.name = "Target"
	target.global_position = Vector2(0, 0)
	add_child(target)

	# Create Enemy
	enemy = enemy_script.new()
	add_child(enemy)
	enemy.global_position = Vector2(100, 0)

	# Setup enemy data (mocking Constants access if possible, or using "slime" which exists)
	# Enemy.gd accesses Constants.ENEMY_VARIANTS["slime"]
	enemy.setup("slime", 1)

	print("Enemy setup complete. Position: ", enemy.global_position)
	print("Target Position: ", target.global_position)

	# Wait a bit then attack
	await get_tree().create_timer(1.0).timeout

	print("Triggering attack animation...")
	enemy.play_attack_animation(target.global_position, Callable(self, "_on_attack_hit"))

func _on_attack_hit():
	print("Attack hit callback triggered!")
	print("Enemy Position at impact: ", enemy.global_position)
	print("Distance to center: ", enemy.global_position.distance_to(Vector2(0,0)))

	# Visual check helpers (if running in graphical mode)
	var circle = Line2D.new()
	circle.points = [Vector2.ZERO, Vector2(35, 0).rotated(0), Vector2(35, 0).rotated(PI/2), Vector2(35, 0).rotated(PI), Vector2(35, 0).rotated(3*PI/2), Vector2.ZERO] # rough circle
	circle.width = 2
	circle.default_color = Color.GREEN
	add_child(circle) # Mark the 35 radius
