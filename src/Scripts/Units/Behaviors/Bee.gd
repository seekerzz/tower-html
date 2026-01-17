extends DefaultBehavior

func on_combat_tick(delta: float) -> bool:
	if unit.cooldown > 0: return true
	var target = GameManager.combat_manager.find_nearest_enemy(unit.global_position, unit.range_val)
	if target:
		unit._do_bow_attack(target)
		return true
	return true
