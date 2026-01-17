extends Node
class_name UnitBehavior

var unit: Node2D

func on_setup():
	pass

func on_tick(delta: float):
	pass

func on_combat_tick(delta: float) -> bool:
	# Returns true if behavior handled the attack, false to use default
	return false

func on_skill_activated():
	pass

func on_skill_execute_at(grid_pos: Vector2i):
	pass

func on_damage_taken(amount: float, source: Node2D) -> float:
	# Returns the modified damage amount
	return amount

func on_cleanup():
	pass

func on_skill_ended():
	pass
