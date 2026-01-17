extends "res://src/Scripts/Units/DefaultBehavior.gd"

func on_combat_tick(delta: float) -> bool:
	if unit.cooldown > 0:
		unit.cooldown -= delta
		return true

	var combat_manager = GameManager.combat_manager
	if !combat_manager: return true

	var target = combat_manager.find_nearest_enemy(unit.global_position, unit.range_val)
	if !target: return true

	if unit.attack_cost_mana > 0:
		GameManager.consume_resource("mana", unit.attack_cost_mana)

	unit.cooldown = unit.atk_speed * GameManager.get_stat_modifier("attack_interval")

	unit.play_attack_anim("lightning", target.global_position)
	combat_manager.perform_lightning_attack(unit, unit.global_position, target, unit.unit_data.get("chain", 0))
	return true
