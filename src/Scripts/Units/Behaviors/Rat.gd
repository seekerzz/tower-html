extends "res://src/Scripts/Units/Behaviors/DefaultBehavior.gd"

# Rat - 老鼠
# 机制: 瘟疫传播 - 攻击命中的敌人若在4秒内死亡，传播毒素
# L1: 传播2层中毒
# L2: 传播4层中毒
# L3: 额外传播其他Debuff (burn, bleed, slow)

const PLAGUE_DURATION_MSEC = 4000

func on_projectile_hit(target: Node2D, damage: float, projectile: Node2D):
	if target and is_instance_valid(target) and target.is_in_group("enemies"):
		target.set_meta("rat_plague_mark_time", Time.get_ticks_msec())

		# Connect to death signal if not already connected
		if not target.is_connected("died", _on_marked_enemy_died):
			target.died.connect(_on_marked_enemy_died.bind(target))

func _on_marked_enemy_died(enemy):
	if not is_instance_valid(enemy):
		return

	if not enemy.has_meta("rat_plague_mark_time"):
		return

	var mark_time = enemy.get_meta("rat_plague_mark_time")
	# Check if within 4 seconds (4000 msec)
	if Time.get_ticks_msec() - mark_time > PLAGUE_DURATION_MSEC:
		return

	var level = unit.level
	var mechanics = {}
	if unit.unit_data.has("levels") and unit.unit_data["levels"].has(str(level)):
		mechanics = unit.unit_data["levels"][str(level)].get("mechanics", {})

	var spread_stacks = mechanics.get("plague_stacks", 2)
	var radius = mechanics.get("spread_radius", 120.0)
	var multi_debuff = mechanics.get("multi_debuff_spread", false)

	var nearby = _get_enemies_in_radius(enemy.global_position, radius)

	for e in nearby:
		if e == enemy: continue

		if e.has_method("add_poison_stacks"):
			e.add_poison_stacks(spread_stacks)
		else:
			# Fallback if no method, use apply_status
			e.apply_status(load("res://src/Scripts/Effects/PoisonEffect.gd"), {"duration": 5.0, "damage": 5.0, "stacks": spread_stacks})

		if multi_debuff:
			_spread_additional_debuff(e)

func _spread_additional_debuff(enemy):
	var debuffs = ["burn", "bleed", "slow"]
	var random_debuff = debuffs.pick_random()

	if random_debuff == "burn":
		enemy.apply_status(load("res://src/Scripts/Effects/BurnEffect.gd"), {"duration": 5.0, "damage": 10.0, "stacks": 1})
	elif random_debuff == "bleed":
		if enemy.has_method("add_bleed_stacks"):
			enemy.add_bleed_stacks(1, unit)
		else:
			enemy.apply_status(load("res://src/Scripts/Effects/BleedEffect.gd"), {"duration": 5.0, "stack_count": 1, "source": unit})
	elif random_debuff == "slow":
		enemy.apply_status(load("res://src/Scripts/Effects/SlowEffect.gd"), {"duration": 3.0, "slow_factor": 0.5})

func _get_enemies_in_radius(pos: Vector2, radius: float) -> Array:
	var result = []
	var enemies = unit.get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and pos.distance_to(enemy.global_position) <= radius:
			result.append(enemy)
	return result
