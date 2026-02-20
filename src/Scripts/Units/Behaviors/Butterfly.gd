extends "res://src/Scripts/Units/Behaviors/DefaultBehavior.gd"
class_name Butterfly

func on_projectile_hit(target: Node2D, damage: float, projectile: Node2D):
	super.on_projectile_hit(target, damage, projectile)

	var mana_cost = GameManager.max_mana * 0.05
	if GameManager.mana >= mana_cost:
		GameManager.consume_resource("mana", mana_cost)

		var damage_multiplier = 1.0 if unit.level < 2 else 1.5
		var bonus_damage = mana_cost * damage_multiplier

		if target.has_method("take_damage"):
			target.take_damage(bonus_damage, unit, "magic")

		GameManager.spawn_floating_text(unit.global_position, "Radiance!", Color.MAGENTA)

func on_kill(victim: Node2D):
	if unit.level >= 3:
		var restore = GameManager.max_mana * 0.1
		GameManager.add_resource("mana", restore)
		GameManager.spawn_floating_text(unit.global_position, "+%d Mana" % int(restore), Color.BLUE)
