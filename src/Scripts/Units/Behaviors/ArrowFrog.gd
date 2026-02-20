extends "res://src/Scripts/Units/Behaviors/DefaultBehavior.gd"

const PoisonEffect = preload("res://src/Scripts/Effects/PoisonEffect.gd")
const StatusEffect = preload("res://src/Scripts/Effects/StatusEffect.gd")

func on_projectile_hit(target: Node2D, damage: float, projectile: Node2D):
	# 检查目标是否有效
	if !is_instance_valid(target) or target.is_queued_for_deletion():
		return

	# 确保目标有必要的接口
	if not target.has_method("die") or not target.has_method("apply_status"):
		return

	# 1. 获取当前攻击目标的 Poison Debuff层数
	var poison_stacks = 0
	for child in target.get_children():
		# 检查是否为 StatusEffect 且类型为 poison
		if child is StatusEffect and child.type_key == "poison":
			poison_stacks = child.stacks
			break

	# 2. 判断斩杀
	# 阈值计算: Stacks * (200 for Lv1, 250 for Lv2+)
	var multiplier = 200.0
	if unit.level >= 2:
		multiplier = 250.0

	var threshold = poison_stacks * multiplier

	# 检查生命值是否低于阈值
	if target.hp < threshold:
		# Execute!
		if GameManager.has_method("spawn_floating_text"):
			GameManager.spawn_floating_text(target.global_position, "Execute!", Color.RED)

		# Explode: Deal threshold damage to nearby enemies (AOE)
		# Radius: 150.0 (covering adjacent tiles)
		var explosion_radius = 150.0
		var enemies = unit.get_tree().get_nodes_in_group("enemies")

		# Lv3: Spread poison to surrounding enemies
		var spread_poison = (unit.level >= 3)
		var spread_stacks = 5

		for enemy in enemies:
			if !is_instance_valid(enemy): continue

			if enemy.global_position.distance_to(target.global_position) <= explosion_radius:
				# Deal damage (Explosion)
				enemy.take_damage(threshold, unit, "explosion")

				# Apply spread poison if applicable and enemy is NOT the target
				if spread_poison and enemy != target:
					var poison_params = {
						"duration": 5.0,
						"damage": damage,
						"stacks": spread_stacks,
						"source": unit
					}
					enemy.apply_status(PoisonEffect, poison_params)

		# Ensure target dies if it somehow survived the explosion damage
		if is_instance_valid(target) and not target.is_queued_for_deletion() and not target.is_dying:
			target.die(unit)

	else:
		# 3. 常规攻击：施加中毒 (1 stack)
		var poison_params = {
			"duration": 5.0,
			"damage": damage,
			"stacks": 1,
			"source": unit
		}
		target.apply_status(PoisonEffect, poison_params)
