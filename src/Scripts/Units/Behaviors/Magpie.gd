extends "res://src/Scripts/Units/Behaviors/DefaultBehavior.gd"

# Magpie - 喜鹊
# 攻击概率偷取敌人属性
# Lv3偷取成功给核心回复HP或金币

enum StealType { ATTACK_SPEED, ATTACK }

func _init(target_unit: Node2D):
	super._init(target_unit)

func on_projectile_hit(target: Node2D, damage: float, projectile: Node2D):
	if not target.is_in_group("enemies"): return

	var chance = 0.15
	if unit.level >= 2:
		chance = 0.25 # Lv2+ 25%

	if randf() >= chance:
		return

	var steal_type = randi() % 2
	var steal_amount = 0.0

	match steal_type:
		StealType.ATTACK_SPEED: steal_amount = 0.03
		StealType.ATTACK: steal_amount = 0.03 # 3% damage increase

	if unit.level >= 2:
		steal_amount *= 1.5

	_apply_steal_effect(steal_type, steal_amount)

	# Apply debuff to enemy
	if target.has_method("apply_status"):
		var stat_name = ""
		match steal_type:
			StealType.ATTACK_SPEED: stat_name = "attack_speed"
			StealType.ATTACK: stat_name = "attack"

		# Duration? Requirement says "temporarily". I'll say 5 seconds.
		target.apply_status(load("res://src/Scripts/Effects/StealDebuff.gd"), {
			"duration": 5.0,
			"stat_type": stat_name,
			"amount": steal_amount
		})

func _apply_steal_effect(type: int, amount: float):
	var targets = [unit]
	if unit.level >= 3:
		targets.append_array(unit._get_neighbor_units())

	for t in targets:
		if not is_instance_valid(t): continue
		match type:
			StealType.ATTACK_SPEED:
				if t.has_method("add_stat_bonus"):
					t.add_stat_bonus("attack_speed", amount)
			StealType.ATTACK:
				if t.has_method("add_stat_bonus"):
					t.add_stat_bonus("damage", amount)

		# Visual feedback
		var txt = ""
		match type:
			StealType.ATTACK_SPEED: txt = "+ASPD"
			StealType.ATTACK: txt = "+DMG"
		GameManager.spawn_floating_text(t.global_position, txt, Color.GREEN)

	if unit.level >= 3:
		_apply_bonus_on_steal()

func _apply_bonus_on_steal():
	if randf() < 0.5:
		GameManager.heal_core(10)
		GameManager.spawn_floating_text(unit.global_position, "+10 HP", Color.GREEN)
	else:
		GameManager.add_gold(10)
		GameManager.spawn_floating_text(unit.global_position, "+10 G", Color.YELLOW)
