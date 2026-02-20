extends "res://src/Scripts/Units/UnitBehavior.gd"

func on_projectile_hit(target: Node2D, damage: float, projectile: Node2D):
	if !is_instance_valid(target) or !target.get("hp") or !target.get("max_hp"):
		return

	var hp_percent = target.hp / target.max_hp
	var mechanics = _get_mechanics()
	var threshold = mechanics.get("execute_threshold", 0.3)

	if hp_percent < threshold:
		var bonus = mechanics.get("execute_damage_bonus", 0.2)
		var count = mechanics.get("execute_count", 1)
		var execute_damage = damage * bonus

		# Execute extra damage attacks
		for i in range(count):
			if is_instance_valid(target) and target.hp > 0:
				target.take_damage(execute_damage, unit, "execute")
				GameManager.spawn_floating_text(target.global_position, "Execute!", Color.RED)

func _get_mechanics() -> Dictionary:
	if unit and unit.unit_data and unit.unit_data.has("levels"):
		var lvl_data = unit.unit_data["levels"].get(str(unit.level), {})
		if lvl_data.has("mechanics"):
			return lvl_data["mechanics"]
	return {}
