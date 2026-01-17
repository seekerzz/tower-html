extends DefaultBehavior
func on_projectile_hit(target: Node2D, damage: float, projectile: Node2D):
	var lifesteal_pct = unit.unit_data.get("lifesteal_percent", 0.0)
	var heal_amt = damage * lifesteal_pct
	if heal_amt > 0:
		GameManager.damage_core(-heal_amt)
		GameManager.spawn_floating_text(unit.global_position, "+%d" % int(heal_amt), Color.GREEN)
