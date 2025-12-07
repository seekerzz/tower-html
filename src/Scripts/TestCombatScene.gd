extends Node2D

@onready var grid_manager = $GridManager
@onready var combat_manager = $CombatManager
const UNIT_SCENE = preload("res://src/Scenes/Game/Unit.tscn")
const ENEMY_SCENE = preload("res://src/Scenes/Game/Enemy.tscn")

func _ready():
	# 1. Place Ninja (Pierce Test) at (1,0) - Right Side
	grid_manager.place_unit("ninja", 1, 0)

	# 2. Place Ranger (Split Test) at (-1,0) - Left Side
	grid_manager.place_unit("ranger", -1, 0)
	var ranger_tile = grid_manager.tiles.get("-1,0")
	if ranger_tile and ranger_tile.unit:
		ranger_tile.unit.unit_data["split"] = 1
		ranger_tile.unit.unit_data["projCount"] = 1

	# 3. Place Tesla (Chain/Bounce Test) at (0,1) - Bottom Side
	grid_manager.place_unit("tesla", 0, 1)

	# --- Spawns ---

	# Ninja Targets (Right) - Line for Pierce
	# Ninja at 700. Targets at 840, 890.
	spawn_test_enemy(Vector2(840, 360), "slime")
	spawn_test_enemy(Vector2(890, 360), "slime")

	# Ranger Target (Left) - Single for Split
	# Ranger at 580. Target at 480.
	spawn_test_enemy(Vector2(480, 360), "slime")

	# Tesla Targets (Bottom) - Two close for Chain
	# Tesla at (640, 420). Range 200.
	# Enemy 1 at (640, 520) (Dist 100).
	# Enemy 2 at (700, 520) (Dist from E1: 60).
	spawn_test_enemy(Vector2(640, 520), "slime")
	spawn_test_enemy(Vector2(700, 520), "slime")

	# Start Wave manually
	GameManager.is_wave_active = true

	await get_tree().create_timer(2.0).timeout
	print("Test Finished")
	get_tree().quit()

func spawn_test_enemy(pos, type):
	var enemy = ENEMY_SCENE.instantiate()
	enemy.setup(type, 1)
	enemy.global_position = pos
	combat_manager.add_child(enemy)

func _process(delta):
	pass
