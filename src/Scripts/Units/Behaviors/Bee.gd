extends "res://src/Scripts/Units/UnitBehavior.gd"

func on_combat_tick(delta: float) -> bool:
	var combat_manager = GameManager.combat_manager
	if !combat_manager: return false

	var target = combat_manager.find_nearest_enemy(unit.global_position, unit.range_val)
	if target:
		unit.call("_do_bow_attack", target)
		return true
	return false
