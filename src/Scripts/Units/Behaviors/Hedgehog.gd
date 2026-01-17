extends "res://src/Scripts/Units/DefaultBehavior.gd"

func on_damage_taken(amount: float, source_enemy: Node2D) -> float:
	var reflect_pct = unit.unit_data.get("reflect_percent", 0.3)
	var reflect_dmg = amount * reflect_pct
	if source_enemy and is_instance_valid(source_enemy):
		source_enemy.take_damage(reflect_dmg, unit, "physical")
		GameManager.spawn_floating_text(unit.global_position, "Reflect!", Color.RED)
	return amount
