extends RefCounted
class_name UnitBehavior

var unit: Node2D

func _init(u: Node2D):
	unit = u

# Virtual Methods

func on_setup():
	pass

func on_tick(delta: float):
	pass

func on_combat_tick(delta: float) -> bool:
	# Return true to completely takeover combat logic, false to use default
	return false

func on_skill_activated():
	pass

func on_damage_taken(amount: float, source: Node2D) -> float:
	# Return modified damage amount
	return amount

func on_projectile_hit(target: Node2D, damage: float, projectile: Node2D):
	pass

func on_cleanup():
	pass

func get_placement_trap_type() -> String:
	return ""
