extends "res://src/Scripts/Units/Behaviors/DefaultBehavior.gd"

# 牛魔像 - 怒火中烧 & 充能震荡
# Lv1: 每次受击攻击力+3%，上限30%(10层)
# Lv2: 攻击力上限提升至50%(约17层)
# Lv3: 受击时20%概率给敌人叠加瘟疫易伤Debuff (Shockwave)

var rage_stacks: int = 0
var max_rage_stacks: int = 10
var rage_damage_bonus: float = 0.03
var shockwave_chance: float = 0.0
var base_damage: float = 0.0

func on_setup():
	# Ensure unit can attack for Rage mechanic verification
	if unit.unit_data.get("damage", 0) == 0:
		unit.unit_data["attackType"] = "melee"
		unit.unit_data["range"] = 120
		unit.unit_data["atkSpeed"] = 1.0

		unit.reset_stats()

	_update_mechanics()

func on_stats_updated():
	if unit:
		if unit.damage == 0:
			unit.damage = 50.0
		base_damage = unit.damage
		rage_stacks = 0
	_update_mechanics()

func _update_mechanics():
	var level = unit.level if unit else 1

	if level >= 2:
		max_rage_stacks = 17 # 约50%
	else:
		max_rage_stacks = 10

	if level >= 3:
		shockwave_chance = 0.2
	else:
		shockwave_chance = 0.0

func on_damage_taken(amount: float, source: Node2D) -> float:
	# 增加怒火层数
	if rage_stacks < max_rage_stacks:
		rage_stacks += 1
		_update_damage()

	# Lv3 充能震荡
	if shockwave_chance > 0 and randf() < shockwave_chance:
		_trigger_shockwave()

	return amount

func _update_damage():
	if unit:
		var bonus = 1.0 + (rage_stacks * rage_damage_bonus)
		unit.damage = base_damage * bonus

func _trigger_shockwave():
	# 触发全屏瘟疫易伤 (Vulnerable)
	var enemies = unit.get_tree().get_nodes_in_group("enemies")

	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("add_debuff"):
			enemy.add_debuff("vulnerable", 1, 5.0)

	GameManager.spawn_floating_text(unit.global_position, "Shockwave!", Color.PURPLE)

	if GameManager.has_method("trigger_impact"):
		GameManager.trigger_impact(Vector2.ZERO, 0.5)

# 兼容旧接口 / Alias for compatibility and UI
func get_hit_counter() -> int:
	return rage_stacks

func get_hits_threshold() -> int:
	return max_rage_stacks

func get_rage_stacks() -> int:
	return rage_stacks
