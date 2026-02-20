extends "res://src/Scripts/Units/Behaviors/DefaultBehavior.gd"

func on_projectile_hit(target: Node2D, damage: float, projectile: Node2D):
	if randf() < 0.25:
		if GameManager.grid_manager:
			GameManager.grid_manager.try_spawn_trap(target.global_position, "mucus")

func on_kill(victim):
	if unit.level >= 3:
		if victim and victim.has_method("has_status") and victim.has_status("slow"):
			_summon_spiderling(victim.global_position)

func _summon_spiderling(pos: Vector2):
	if GameManager.summon_manager:
		var data = {
			"unit_id": "spiderling",
			"position": pos,
			"source": unit,
			"level": 1,
			"lifetime": 25.0
		}
		GameManager.summon_manager.create_summon(data)
