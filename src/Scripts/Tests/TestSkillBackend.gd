extends Node2D

var passed = true

func _ready():
	print("Starting Backend Logic Verification...")
	test_unit_interface()
	test_trap_logic()
	test_firestorm()

	if passed:
		print("Backend Logic Verification Passed")
	else:
		print("Backend Logic Verification Failed")

var _signal_emitted_check = false

func test_unit_interface():
	print("  Testing Unit Interface...")
	var unit = load("res://src/Scripts/Unit.gd").new()
	# Mock data
	unit.unit_data = {
		"skill": "firestorm",
		"targetType": "ground",
		"skillCost": 0.0 # Free for test
	}
	unit.skill_mana_cost = 0.0

	# Spy on signal
	_signal_emitted_check = false
	unit.request_targeting.connect(func(_u): _signal_emitted_check = true)

	unit.activate_skill()

	if _signal_emitted_check:
		print("    [PASS] request_targeting emitted.")
	else:
		print("    [FAIL] request_targeting NOT emitted.")
		passed = false

func test_trap_logic():
	print("  Testing Trap Logic...")
	# GridManager is singleton in GameManager, but here we might need to mock or use the one in scene.
	# Since this test script will be run in a scene, we should ideally setup a minimal environment.
	# But GridManager relies on Tiles being created.

	# Let's create a temporary GridManager
	var gm = load("res://src/Scripts/GridManager.gd").new()
	# We need to add it to tree so it can create tiles etc.
	add_child(gm)

	# Wait a frame for _ready?
	# _ready is called when added to tree.

	# GridManager creates initial grid centered at 0,0.
	# Let's try to spawn a trap at 1,1 (which should be valid normal tile).
	var pos = Vector2i(1, 1)

	var success = gm.try_spawn_trap(pos, "poison")

	if success:
		print("    [PASS] Trap spawned successfully.")
	else:
		print("    [FAIL] Trap failed to spawn.")
		passed = false

	# Verify obstruction
	if gm.obstacles.has(pos):
		print("    [PASS] Grid is occupied.")
	else:
		print("    [FAIL] Grid NOT occupied.")
		passed = false

	gm.queue_free()

func test_firestorm():
	print("  Testing Firestorm...")
	var fc = load("res://src/Scripts/Skills/FirestormController.gd").new()
	# FirestormController adds projectiles to get_parent().
	# So we need a container.
	var container = Node2D.new()
	add_child(container)
	container.add_child(fc)
	fc.global_position = Vector2.ZERO

	# Run for 0.5 seconds
	await get_tree().create_timer(0.5).timeout

	# Check children count in container.
	# Should be fc + projectiles.
	var projectile_count = 0
	for child in container.get_children():
		if child == fc: continue
		# Assuming other children are projectiles
		projectile_count += 1

	if projectile_count > 0:
		print("    [PASS] Projectiles spawned: %d" % projectile_count)
	else:
		print("    [FAIL] No projectiles spawned.")
		passed = false

	container.queue_free()
