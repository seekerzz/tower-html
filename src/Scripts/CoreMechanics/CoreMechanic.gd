extends Node
class_name CoreMechanic

func on_wave_started():
	pass

func on_core_damaged(amount: float):
	pass

func on_damage_dealt_by_unit(unit, amount: float):
	pass

func get_stat_modifier(stat_type: String, context: Dictionary) -> float:
	return 1.0

func on_projectile_crit(projectile, target):
	pass
