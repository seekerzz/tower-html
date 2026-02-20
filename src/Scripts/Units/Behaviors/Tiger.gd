extends "res://src/Scripts/Units/Behaviors/DefaultBehavior.gd"

var skill_active_timer: float = 0.0
var _skill_interval_timer: float = 0.0

func on_skill_activated():
	skill_active_timer = unit.unit_data.get("skillDuration", 5.0)
	_skill_interval_timer = 0.0
	unit.set_highlight(true, Color.ORANGE)

func on_tick(delta: float):
	if skill_active_timer > 0:
		skill_active_timer -= delta
		_skill_interval_timer -= delta
		if _skill_interval_timer <= 0:
			_skill_interval_timer = 0.2
			_spawn_meteor_at_random_enemy()

		if skill_active_timer <= 0:
			unit.set_highlight(false)

func on_skill_executed_at(grid_pos: Vector2i):
	print("[Tiger] Skill executed at ", grid_pos)
	var gm = GameManager.grid_manager
	if !gm: return

	var key = gm.get_tile_key(grid_pos.x, grid_pos.y)
	if gm.tiles.has(key):
		var tile = gm.tiles[key]
		var target_unit = tile.unit

		if target_unit and target_unit != unit:
			print("[Tiger] Target found: ", target_unit.type_key)
			# 1. Devour: Gain stats
			var bonus_damage = target_unit.damage * 0.25
			unit.damage += bonus_damage
			print("[Tiger] Devoured! New damage: ", unit.damage)

			# Check faction for Lv3 bonus
			var is_wolf_totem = target_unit.unit_data.get("faction") == "wolf_totem"

			# 2. Remove victim
			print("[Tiger] Removing target unit...")
			gm.remove_unit_from_grid(target_unit)
			print("[Tiger] Target unit removed.")

			# 3. Trigger Meteors
			var meteor_count = 6 # Base
			if unit.level >= 3:
				meteor_count += 2
				if is_wolf_totem:
					meteor_count += 2

			print("[Tiger] Spawning ", meteor_count, " meteors.")
			_spawn_instant_meteor_shower(meteor_count)

func _spawn_instant_meteor_shower(count: int):
	for i in range(count):
		_spawn_meteor_at_random_enemy()
	print("[Tiger] Meteor shower spawned.")

func _spawn_meteor_at_random_enemy():
	var combat_manager = GameManager.combat_manager
	if !combat_manager: return
	var enemies = unit.get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty(): return

	var target = enemies.pick_random()
	if !is_instance_valid(target): return

	var ground_pos = target.global_position
	var spawn_pos = ground_pos + Vector2(randf_range(-100, 100), -600)

	var stats = {
		"is_meteor": true,
		"ground_pos": ground_pos,
		"damageType": "physical",
		"life": 3.0,
		"source": unit
	}

	combat_manager.spawn_projectile(unit, spawn_pos, target, stats)
