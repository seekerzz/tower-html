extends "res://src/Scripts/TestBenchScene.gd"

const UNIT_SCRIPT = preload("res://src/Scripts/Unit.gd")
const PROJECTILE_SCRIPT = preload("res://src/Scripts/Projectile.gd")
const ENEMY_SCRIPT = preload("res://src/Scripts/Enemy.gd")

func _ready():
	print("Starting Melee Refactor Test...")
	test_bear_swipe_setup()
	test_projectile_hiding()
	print("Melee Refactor Test Completed")

func test_bear_swipe_setup():
	var unit = Node2D.new()
	unit.set_script(UNIT_SCRIPT)
	unit.setup("bear")

	# Verify initial state
	assert(unit.get("swipe_right_next") == false, "Bear should start with left swipe (false)")

	# Simulate toggling (this logic is in CombatManager, but we can check variable exists)
	unit.swipe_right_next = true
	assert(unit.swipe_right_next == true, "swipe_right_next should be toggleable")

	unit.queue_free()
	print("test_bear_swipe_setup passed")

func test_projectile_hiding():
	var proj = Node2D.new()
	proj.set_script(PROJECTILE_SCRIPT)

	# Add some visual children
	var sprite = Sprite2D.new()
	proj.add_child(sprite)
	var poly = Polygon2D.new()
	proj.add_child(poly)

	# Call setup with melee_invisible
	proj.setup(Vector2.ZERO, null, 10, 100, "melee_invisible", {})

	# Verify visuals are hidden
	# Note: setup() is deferred? No, it's immediate in the script provided.
	# But it checks "if visual_node".

	# Wait for a frame if necessary, but setup is synchronous in the provided code.

	# Check children
	for child in proj.get_children():
		if child is Node2D:
			assert(child.visible == false, "All visual children should be hidden for melee_invisible")

	proj.queue_free()
	print("test_projectile_hiding passed")
