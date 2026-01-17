extends DefaultBehavior

var skill_active_timer: float = 0.0
var meteor_interval_timer: float = 0.0

func on_skill_activated():
	skill_active_timer = unit.unit_data.get("skillDuration", 5.0)
	meteor_interval_timer = 0.0
	unit.set_highlight(true, Color.ORANGE)

func on_tick(delta: float):
	if skill_active_timer > 0:
		skill_active_timer -= delta
		meteor_interval_timer -= delta
		if meteor_interval_timer <= 0:
			meteor_interval_timer = 0.2
			_spawn_meteor()

		if skill_active_timer <= 0:
			unit.set_highlight(false)

func _spawn_meteor():
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
