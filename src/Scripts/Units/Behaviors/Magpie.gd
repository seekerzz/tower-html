extends "res://src/Scripts/Units/Behaviors/DefaultBehavior.gd"

# Magpie - 喜鹊
# 攻击概率偷取敌人属性
# Lv3偷取成功给核心回复HP或金币

enum StealType { ATTACK_SPEED, ATTACK }

func _init(target_unit: Node2D):
	super._init(target_unit)

func on_projectile_hit(target: Node2D, damage: float, projectile: Node2D):
	if not target.is_in_group("enemies"): return

	# Lv1: 15% probability. Lv2+: 25% probability.
	var chance = 0.15 if unit.level < 2 else 0.25
	if randf() >= chance:
		return

	# Randomly choose between Attack Speed and Attack
	var steal_type = randi() % 2
	var steal_amount = 0.0

	match steal_type:
		StealType.ATTACK_SPEED: steal_amount = 0.03 # 3% base
		StealType.ATTACK: steal_amount = 0.03 # 3% base

	# Lv2: Steal effect +50%
	if unit.level >= 2:
		steal_amount *= 1.5

	_apply_steal_effect(steal_type, steal_amount, target)

func _apply_steal_effect(type: int, amount: float, enemy_target: Node2D):
	# 1. Apply bonus to Unit (and neighbors if Lv3)
	var targets = [unit]
	if unit.level >= 3:
		targets.append_array(unit._get_neighbor_units())

	for t in targets:
		if not is_instance_valid(t): continue

		# Apply permanent stat bonus to unit
		if t.has_method("add_stat_bonus"):
			match type:
				StealType.ATTACK_SPEED:
					t.add_stat_bonus("attack_speed", amount)
				StealType.ATTACK:
					t.add_stat_bonus("damage", amount)

		# Visual feedback on unit
		var txt = ""
		match type:
			StealType.ATTACK_SPEED: txt = "+ASPD"
			StealType.ATTACK: txt = "+ATK"
		GameManager.spawn_floating_text(t.global_position, txt, Color.GREEN)

	# 2. Apply Debuff to Enemy
	if is_instance_valid(enemy_target) and enemy_target.has_method("apply_status"):
		var debuff_script = load("res://src/Scripts/Effects/StealDebuff.gd")
		var stat_key = ""
		match type:
			StealType.ATTACK_SPEED: stat_key = "attack_speed"
			StealType.ATTACK: stat_key = "attack"

		enemy_target.apply_status(debuff_script, {
			"duration": 5.0, # Temporary debuff
			"stat_type": stat_key,
			"amount": amount,
			"source": unit
		})

		GameManager.spawn_floating_text(enemy_target.global_position, "Stolen!", Color.RED)

	# 3. Lv3 Bonus Reward
	if unit.level >= 3:
		_apply_bonus_on_steal()

func _apply_bonus_on_steal():
	if randf() < 0.5:
		GameManager.heal_core(10)
		GameManager.spawn_floating_text(unit.global_position, "+10 HP", Color.GREEN)
	else:
		GameManager.add_gold(10)
		GameManager.spawn_floating_text(unit.global_position, "+10 G", Color.YELLOW)
