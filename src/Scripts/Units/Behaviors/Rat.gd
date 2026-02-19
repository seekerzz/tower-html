extends DefaultBehavior

# Rat Unit Behavior
# Buff Unit: Applies plague to enemies poisoned by it.
# When plagued enemy dies, spreads poison.
# L2: More stacks spread.
# L3: Additional random debuff.

var plague_duration: float = 4.0

func on_setup():
	if not EventBus.debuff_applied.is_connected(_on_debuff_applied):
		EventBus.debuff_applied.connect(_on_debuff_applied)

func on_cleanup():
	if EventBus.debuff_applied.is_connected(_on_debuff_applied):
		EventBus.debuff_applied.disconnect(_on_debuff_applied)

func _on_debuff_applied(enemy, debuff_type: String, stacks: int, source):
	if debuff_type == "poison":
		enemy.set_meta("plague_infected", true)
		enemy.set_meta("plague_duration", plague_duration)
		if enemy.has_signal("died") and not enemy.is_connected("died", _on_plagued_enemy_died):
			enemy.died.connect(_on_plagued_enemy_died.bind(enemy))

func _on_plagued_enemy_died(enemy):
	if not enemy.has_meta("plague_infected"):
		return

	var spread_stacks = 2 if unit.level < 2 else 4
	var nearby = _get_enemies_in_radius(enemy.global_position, 120.0)

	for e in nearby:
		if e == enemy: continue
		if e.has_method("add_poison_stacks"):
			e.add_poison_stacks(spread_stacks)

		if unit.level >= 3:
			_spread_additional_debuff(e)

func _get_enemies_in_radius(pos: Vector2, radius: float) -> Array:
	var enemies = unit.get_tree().get_nodes_in_group("enemies")
	var result = []
	var r_sq = radius * radius
	for e in enemies:
		if e.global_position.distance_squared_to(pos) <= r_sq:
			result.append(e)
	return result

func _spread_additional_debuff(enemy):
	var debuffs = ["burn", "bleed", "slow"]
	var random_debuff = debuffs[randi() % debuffs.size()]
	if enemy.has_method("apply_debuff"):
		enemy.apply_debuff(random_debuff, 1)
