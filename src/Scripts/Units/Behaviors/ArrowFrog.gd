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

	# 1. 获取当前攻击目标的 Poison Debuff总层数
	var debuff_stacks = 0
	for child in target.get_children():
		# 使用 type_key 判断类型，确保只计算 PoisonEffect
		if "type_key" in child and child.type_key == "poison":
			debuff_stacks += child.stacks

	# 2. 判断斩杀 / 引爆阈值
	# 阈值 = Debuff层数 * 200 (Lv1) / 250 (Lv2+)
	var multiplier = 200
	if unit.level >= 2:
		multiplier = 250

	var threshold = debuff_stacks * multiplier

	# 3. 检查生命值是否低于阈值
	# 注意：此时 damage 已经造成，target.hp 是扣除伤害后的值
	if target.hp < threshold:
		# Execute / Detonate!
		if GameManager.has_method("spawn_floating_text"):
			GameManager.spawn_floating_text(target.global_position, "Execute!", Color.RED)

		# 引爆：对周围敌人（包括自身）造成AOE伤害
		# 如果是目标自身，伤害 >= HP 确保斩杀
		var explosion_center = target.global_position
		var explosion_radius = 150.0 # 2.5 tiles radius
		var explosion_damage = threshold # Use threshold as explosion damage (consistent with requirements)

		var enemies = unit.get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if !is_instance_valid(enemy): continue

			var dist = enemy.global_position.distance_to(explosion_center)
			if dist <= explosion_radius:
				# Deal explosion damage
				if enemy.has_method("take_damage"):
					# Pass unit as source, "explosion" type
					enemy.take_damage(explosion_damage, unit, "magic")

				# Lv3: Spread Poison to surrounding enemies (exclude the dying target itself from new stacks?)
				# Task says: "传播给周围敌人" (Spread to surrounding enemies).
				# Usually execute kills target, so spreading to it is useless, but harmless.
				# We'll spread to all in radius except target (as it dies).
				if unit.level >= 3 and enemy != target:
					if enemy.has_method("apply_status"):
						var spread_params = {
							"duration": 5.0,
							"damage": damage, # Use original damage for poison base? Or consistent with normal attack?
							"stacks": 5,
							"source": unit
						}
						enemy.apply_status(PoisonEffect, spread_params)

		# Visual Effect for Explosion
		_spawn_explosion_effect(explosion_center)

		# Ensure target dies if not already dead from AOE (though threshold damage > hp should kill it)
		if is_instance_valid(target) and target.hp > 0:
			target.die(unit)

	else:
		# 4. 常规攻击：施加中毒
		# 如果未触发斩杀，则给目标施加1层中毒效果
		var poison_params = {
			"duration": 5.0,
			"damage": damage,
			"stacks": 1,
			"source": unit
		}
		target.apply_status(PoisonEffect, poison_params)

func _spawn_explosion_effect(pos: Vector2):
	# Simple visual effect reusing SlashEffect or creating one
	var SlashEffectScript = load("res://src/Scripts/Effects/SlashEffect.gd")
	if SlashEffectScript:
		var effect = SlashEffectScript.new()
		unit.get_parent().add_child(effect)
		effect.global_position = pos
		# Configure as "star" or "blob" to look like poison explosion
		if effect.has_method("configure"):
			effect.configure("blob", Color.GREEN)
		effect.scale = Vector2(2.0, 2.0)
		effect.play()
