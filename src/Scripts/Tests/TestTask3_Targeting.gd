extends SceneTree

var passed = false
var GameManager
var main_game

func _init():
	# Manually load GameManager since running with -s doesn't autoload it
	var gm_script = load("res://src/Autoload/GameManager.gd")
	GameManager = gm_script.new()
	root.add_child(GameManager)

	# Need to initialize MainGame scene to have GridManager
	var main_game_scene = load("res://src/Scenes/Game/MainGame.tscn")
	main_game = main_game_scene.instantiate()
	root.add_child(main_game)

	# Wait for ready
	var timer = create_timer(1.0)
	timer.timeout.connect(_run_tests)

func _run_tests():
	print("Starting Task 3 Verification: Targeting System")

	# Mock mana for skills
	GameManager.mana = 1000

	var phoenix_passed = await verify_phoenix_firestorm()

	await create_timer(1.0).timeout

	var viper_passed = await verify_viper_trap()

	if phoenix_passed and viper_passed:
		print("Task 3 Verification Passed")
		passed = true
	else:
		print("Task 3 Verification Failed")

	quit()

func verify_phoenix_firestorm():
	print("Verifying Phoenix Firestorm...")

	# Place Phoenix
	# Ensure GridManager is ready
	await process_frame

	var gm = GameManager.grid_manager
	if !gm:
		print("Error: GridManager not found")
		return false

	if not gm.is_inside_tree():
		print("GridManager not in tree yet")
		return false

	gm.place_unit("phoenix", 0, 1)

	var tile_key = gm.get_tile_key(0, 1)
	if not gm.tiles.has(tile_key):
		print("Tile not found: ", tile_key)
		return false

	var phoenix_tile = gm.tiles[tile_key]
	var phoenix = phoenix_tile.unit

	if !phoenix:
		print("Error: Phoenix not placed")
		return false

	# Call cast_target_skill directly
	phoenix.cast_target_skill(Vector2i(2, 2))

	await create_timer(0.5).timeout

	# Check for projectiles of type "fire"

	var found_projectile = false
	# Firestorm attaches to gm
	# Firestorm spawns projectiles into its parent (gm) or root.
	# Firestorm.gd: if unit.get_parent(): unit.get_parent().add_child(proj)
	# Unit is child of GridManager. So projectiles are children of GridManager.

	for child in gm.get_children():
		if child.get("type") == "fire":
			found_projectile = true
			print("Found Fire Projectile at ", child.position)
			break

	if found_projectile:
		print("Phoenix Firestorm: PASS")
		return true
	else:
		print("Phoenix Firestorm: FAIL (No projectile found)")
		return false

func verify_viper_trap():
	print("Verifying Viper Trap...")

	var gm = GameManager.grid_manager

	# Ensure GridManager is ready
	await process_frame

	if !gm:
		print("Error: GridManager not found")
		return false

	if not gm.is_inside_tree():
		print("GridManager not in tree yet")
		return false

	gm.place_unit("viper", -2, 1)

	var tile_key = gm.get_tile_key(-2, 1)
	if not gm.tiles.has(tile_key):
		print("Tile not found: ", tile_key)
		return false

	var viper_tile = gm.tiles[tile_key]
	var viper = viper_tile.unit

	if !viper:
		print("Error: Viper not placed")
		return false

	# Call cast_target_skill
	var target_pos = Vector2i(3, 3)
	viper.cast_target_skill(target_pos)

	await create_timer(0.1).timeout

	# Check GridManager obstacles at 3,3
	# Ensure obstacle list is updated

	# Ensure obstacle list is updated
	if gm.obstacles.has(target_pos):
		var obs = gm.obstacles[target_pos]
		if obs.name.begins_with("Obstacle_poison"):
			print("Viper Trap: PASS")
			return true
		else:
			print("Viper Trap: FAIL (Obstacle found but wrong type: " + obs.name + ")")
			return false
	else:
		# Check children directly if obstacles dict is not updated properly (though it should be)
		for child in gm.get_children():
			if child.name.begins_with("Obstacle_poison"):
				var grid_pos = Vector2i(round(child.position.x / 60), round(child.position.y / 60))
				if grid_pos == target_pos:
					print("Viper Trap: PASS (Found in children)")
					return true

		print("Viper Trap: FAIL (No obstacle at target: " + str(target_pos) + ")")
		return false
