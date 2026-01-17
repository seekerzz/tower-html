extends UnitBehavior

func on_setup():
	pass

func on_placement_attempt(grid_pos: Vector2i):
	pass

func on_tick(delta: float):
	pass

func on_combat_tick(delta: float) -> bool:
	return false

func on_skill_activated():
	pass

func on_skill_executed_at(grid_pos: Vector2i):
	pass

func on_damage_taken(amount: float, source: Node2D) -> float:
	return amount

func on_projectile_hit(target: Node2D, damage: float, projectile: Node2D):
	pass

func on_cleanup():
	pass

func on_stats_updated():
	pass

func on_bullet_captured(bullet_snapshot: Dictionary):
	pass

func get_trap_type() -> String:
	return ""
