extends SceneTree

func _init():
	print("Running Tests...")
	test_game_manager()
	test_grid_manager()
	test_unit_logic()
	print("All tests passed!")
	quit()

func test_game_manager():
	var gm = load("res://scripts/game_manager.gd").new()
	gm.reset_game()
	assert(gm.gold == 150, "Initial gold should be 150")
	gm.spend_gold(50)
	assert(gm.gold == 100, "Gold spend failed")
	gm.add_gold(20)
	assert(gm.gold == 120, "Gold add failed")

	gm.damage_core(10)
	assert(gm.core_health == 90, "Core damage failed")

	print("GameManager tests passed.")
	gm.free()

func test_grid_manager():
	var grid = load("res://scripts/grid_manager.gd").new()
	grid._ready()
	assert(grid.tiles.has(Vector2i(0,0)), "Core tile missing")
	assert(grid.get_tile_at_position(Vector2(64, 0)) == Vector2i(1, 0), "Coordinate conversion failed")
	print("GridManager tests passed.")
	grid.free()

func test_unit_logic():
	# This requires a scene tree for nodes, skipping complex interaction tests here
	# but can test basic calculations if refactored.
	pass
