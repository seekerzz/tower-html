extends "res://src/Scripts/Units/DefaultBehavior.gd"

func on_combat_tick(delta: float) -> bool:
	if unit.cooldown > 0:
		unit.cooldown -= delta
		return true

	var combat_manager = GameManager.combat_manager
	if !combat_manager: return true

	var target = combat_manager.find_nearest_enemy(unit.global_position, unit.range_val)
	if !target: return true

	unit._do_bow_attack(target)
	return true
