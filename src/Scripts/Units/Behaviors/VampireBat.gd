extends "res://src/Scripts/Units/Behaviors/DefaultBehavior.gd"

# 吸血蝠 - 鲜血狂噬机制
# 生命值越低，吸血比例越高
# Lv3: 对流血敌人伤害增加

func get_current_lifesteal() -> float:
	if not is_instance_valid(unit): return 0.0

	var hp_percent = 1.0
	if unit.max_hp > 0:
		hp_percent = unit.current_hp / unit.max_hp

	# Default values based on level
	var base_lifesteal = 0.0
	var low_hp_bonus = 0.5 # +50% at 0 HP

	if unit.level >= 2:
		base_lifesteal = 0.2 # +20% base

	# Calculate lifesteal percentage: Base + Bonus * (1 - HP%)
	var lifesteal_pct = base_lifesteal + (low_hp_bonus * (1.0 - hp_percent))

	return lifesteal_pct

func on_projectile_hit(target: Node2D, damage: float, projectile: Node2D):
	if not is_instance_valid(target): return

	var total_damage_dealt = damage

	# 1. Bleed Damage Bonus (Lv3)
	if unit.level >= 3:
		# Check if target has bleed stacks
		# Using dynamic access to avoid errors if property missing
		var stacks = 0
		if "bleed_stacks" in target:
			stacks = target.bleed_stacks

		if stacks > 0:
			# 10% bonus damage per stack
			var extra_damage = damage * stacks * 0.1
			if extra_damage > 0:
				target.take_damage(extra_damage, unit, "physical")
				total_damage_dealt += extra_damage

	# 2. Lifesteal Logic
	var lifesteal_pct = get_current_lifesteal()
	var heal_amt = total_damage_dealt * lifesteal_pct

	# Cap lifesteal at 100% of damage dealt
	if heal_amt > total_damage_dealt:
		heal_amt = total_damage_dealt

	if heal_amt > 0:
		unit.heal(heal_amt)
