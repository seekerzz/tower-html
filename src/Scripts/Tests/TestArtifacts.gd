extends Node

func _ready():
	print("TestArtifacts starting...")
	# Wait for GameManager to be ready
	await get_tree().create_timer(1.0).timeout

	test_biomass_armor()
	await get_tree().create_timer(1.0).timeout
	test_scrap_recycling()
	await get_tree().create_timer(1.0).timeout
	print("All tests finished.")

func test_biomass_armor():
	print("Testing Biomass Armor...")
	# 1. Add reward
	if not GameManager.reward_manager:
		push_error("RewardManager missing!")
		return

	GameManager.reward_manager.add_reward("biomass_armor")

	# 2. Set HP
	GameManager.max_core_health = 1000.0
	GameManager.core_health = 1000.0

	# 3. Damage
	var dmg = 500.0
	GameManager.damage_core(dmg)

	# 4. Assert
	# Expected: 1000 - min(500, 1000*0.05) = 1000 - 50 = 950
	if is_equal_approx(GameManager.core_health, 950.0):
		print("PASS: Biomass Armor limited damage correctly. Health: ", GameManager.core_health)
	else:
		push_error("FAIL: Biomass Armor check failed. Expected 950, got " + str(GameManager.core_health))

func test_scrap_recycling():
	print("Testing Scrap Recycling...")

	if not GameManager.reward_manager: return

	# 1. Add reward
	if not "scrap_recycling" in GameManager.reward_manager.acquired_artifacts:
		GameManager.reward_manager.add_reward("scrap_recycling")

	var initial_gold = GameManager.gold
	var initial_hp = GameManager.core_health

	# 2. Instantiate Enemy
	# We need the GridManager to be present for Enemy to find core distance?
	# Enemy.die() checks GridManager distance.

	if not GameManager.grid_manager:
		# Create dummy GridManager if needed, or rely on existing scene
		var gm = Node2D.new()
		gm.name = "GridManager"
		GameManager.add_child(gm)
		GameManager.grid_manager = gm

	var enemy = load("res://src/Scripts/Enemy.gd").new()
	# Mock enemy data
	enemy.enemy_data = {"dmg": 10, "dropRate": 0.0}
	enemy.max_hp = 10
	enemy.hp = 10
	GameManager.add_child(enemy)
	enemy.global_position = GameManager.grid_manager.global_position # At core (dist 0)

	# 3. Die
	enemy.die()

	# 4. Assert
	# Gold: +1 base + 1 recycling = +2
	if GameManager.gold == initial_gold + 2:
		print("PASS: Scrap Recycling gold added.")
	else:
		push_error("FAIL: Scrap Recycling gold mismatch. Expected " + str(initial_gold+2) + ", got " + str(GameManager.gold))

	# HP: +5 healing (damage_core(-5))
	# Note: test_biomass_armor left HP at 950 (max 1500 because biomass adds 500).
	# biomass_armor adds 500 to max_core_health.
	# test_biomass_armor set max to 1000 explicitly?
	# Wait, `test_biomass_armor` set `GameManager.max_core_health = 1000.0`.
	# But `recalculate_max_health` might override it later?
	# Actually I set it manually.
	# `damage_core(-5)` -> `core_health += 5`.

	if GameManager.core_health == initial_hp + 5:
		print("PASS: Scrap Recycling heal applied.")
	else:
		push_error("FAIL: Scrap Recycling heal mismatch. Expected " + str(initial_hp+5) + ", got " + str(GameManager.core_health))
