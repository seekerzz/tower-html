extends RefCounted
class_name UnitBehavior

var unit: Node2D

func _init(u: Node2D = null):
	unit = u

# Virtual Methods

func on_setup():
	pass

func on_placement_attempt(grid_pos: Vector2i):
	pass

func on_tick(delta: float):
	pass

func on_combat_tick(delta: float) -> bool:
	# Return true to fully takeover attack logic
	# Return false to use default attack logic
	return false

func on_skill_activated():
	pass

func on_skill_executed_at(grid_pos: Vector2i):
	pass

func on_damage_taken(amount: float, source: Node2D) -> float:
	# Pre-process damage (e.g. reduction, reflection)
	return amount

func on_projectile_hit(target: Node2D, damage: float, projectile: Node2D):
	pass

func on_cleanup():
	pass

# Extra hooks for full migration
func on_stats_updated():
	pass

func on_bullet_captured(bullet_snapshot: Dictionary):
	pass

func get_trap_type() -> String:
	return ""
